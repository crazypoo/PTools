//
//  PTVideoCoverCache.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 26/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import CryptoKit

// Serializes thumbnail file I/O so image decoding and disk access never block MainActor.
// Serializa el acceso a los archivos para que la decodificación y el disco no bloqueen MainActor.
// 串行化缩略图文件 I/O，避免图片解码和磁盘访问阻塞 MainActor。
private actor PTVideoCoverDiskStore {
    private let directory: URL

    init() {
        let baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = baseURL.appendingPathComponent("PTVideoCoverCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.directory = directory
    }

    func readData(for key: String) -> Data? {
        try? Data(contentsOf: fileURL(for: key), options: .mappedIfSafe)
    }

    func writeData(_ data: Data, for key: String) {
        try? data.write(to: fileURL(for: key), options: .atomic)
    }

    private func fileURL(for key: String) -> URL {
        directory.appendingPathComponent(key, isDirectory: false)
    }
}

/// 统一的视频缓存数据对象
/// 符合 Sendable 协议，确保可在多线程间安全传递
@MainActor
public struct PTVideoCacheItem {
    /// 原始的远程视频 URL
    public let originalURLString: String
    
    /// 缓存的封面图
    public var coverImage: UIImage?
    
    /// 缓存的本地视频路径（如果还没有下载完，则为 nil）
    public var localVideoURL: URL?
    
    /// 便利属性：是否视频和封面都已经准备好了
    public var isFullyCached: Bool {
        return coverImage != nil && localVideoURL != nil
    }
}

/// 视频管理核心类
/// 标记为 Sendable，因为它是不可变的纯功能单例
public final class PTVideoManager: Sendable {
    
    public static let shared = PTVideoManager()
    private init() {}
    
    /// 核心方法：通过 URL 获取视频缓存对象
    /// - Parameters:
    ///   - urlString: 视频的原始 URL 字符串
    ///   - autoCacheVideo: 是否在获取封面的同时，顺便在后台下载视频？
    ///   - progress: 下载进度回调（需符合 @Sendable）
    ///   - coverReady: 封面就绪回调（主线程执行，需符合 @Sendable）
    ///   - videoReady: 视频就绪回调（主线程执行，可选，需符合 @Sendable）
    @MainActor public func getVideoItem(for urlString: String,
                             autoCacheVideo: Bool = false,
                             progress: FileDownloadProgress? = nil,
                             coverReady: @escaping @MainActor @Sendable (PTVideoCacheItem) -> Void,
                             videoReady: (@MainActor @Sendable (PTVideoCacheItem) -> Void)? = nil) {
        
        guard let url = URL(string: urlString) else { return }
        
        // 步骤 1：在最外层准备初始状态，并冻结为 let 常量
        var tempInitialItem = PTVideoCacheItem(originalURLString: urlString)
        tempInitialItem.localVideoURL = PTVideoFileCache.shared.cachedFileURL(for: url)
        let initialItem = tempInitialItem // 冻结为常量
        
        // 开始异步获取封面
        PTVideoCoverCache.getVideoFirstImage(videoUrl: urlString) { image in
            // 步骤 2：在外层闭包中创建一个局部的 var 进行修改
            var currentItem = initialItem
            currentItem.coverImage = image
            
            // 步骤 3：🌟 关键修复点 🌟
            // 在进入下一个并发闭包（prepareVideo）或返回主线程之前，
            // 将修改好的 currentItem 再次“冻结”成一个局部的 let 常量！
            let frozenItemAfterCover = currentItem
            
            // 现在捕获 frozenItemAfterCover 是绝对安全的
            coverReady(frozenItemAfterCover)
            
            // 检查是否需要下载
            if autoCacheVideo && frozenItemAfterCover.localVideoURL == nil {
                PTVideoFileCache.shared.prepareVideo(url: url, progress: progress) { localURL in
                    // 步骤 4：在内层闭包中，基于刚才冻结的 let 常量，再创建一个 var 用于最终修改
                    var finalItem = frozenItemAfterCover
                    if let localURL = localURL {
                        finalItem.localVideoURL = localURL
                    }
                    
                    // 最后一次回调
                    videoReady?(finalItem)
                }
            } else {
                // 如果不需要下载，直接返回冻结的状态
                videoReady?(frozenItemAfterCover)
            }
        }
    }
}

/// 视频文件沙盒缓存管理类
public final class PTVideoFileCache: Sendable {

    public static let shared = PTVideoFileCache()
    
    private let directoryName = "PTVideoFileCache"
    
    // 🌟 Swift 6 改进：摒弃 lazy var，改为通过 init 初始化的 let 常量，彻底消除并发读写隐患
    private let cacheDirectory: URL

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.cacheDirectory = dir
    }

    /// 同一个 URL → 同一个文件路径
    public func cacheURL(for videoURL: URL) -> URL {
        let key = PTVideoCoverCache.cacheKeyForVideo(videoURL.absoluteString)
        let ext = videoURL.pathExtension.isEmpty ? "mp4" : videoURL.pathExtension
        return cacheDirectory.appendingPathComponent("\(key).\(ext)")
    }

    /// 获取已缓存的本地文件 URL（若文件不存在或损坏则返回 nil）
    public func cachedFileURL(for url: URL) -> URL? {
        guard !url.isFileURL else {
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }

        let localURL = cacheURL(for: url)

        guard FileManager.default.fileExists(atPath: localURL.path) else {
            return nil
        }

        // 防止 0 字节 / 下载未完成的脏文件
        if let attr = try? FileManager.default.attributesOfItem(atPath: localURL.path),
           let fileSize = attr[.size] as? NSNumber,
           fileSize.int64Value > 0 {
            return localURL
        }
        return nil
    }
    
    /// 核心：获取可用的视频文件（本地已有则直接返回，没有则调用网络库下载）
    public func prepareVideo(url: URL,
                             progress: FileDownloadProgress? = nil,
                             completion: @escaping @MainActor @Sendable (URL?) -> Void) {
        Task { @MainActor in
            // 本地文件直接返回
            if let cached = cachedFileURL(for: url) {
                completion(cached)
                return
            }

            let localURL = cacheURL(for: url)
            do {
                _ = try await PTCoreFileDownloadService.download(from: url,
                                                                 to: localURL,
                                                                 progress: progress)
                completion(localURL)
            } catch {
                completion(nil)
            }
        }
    }
}

/// Video cover cache and thumbnail request coordinator.
/// Caché de portadas de vídeo y coordinador de solicitudes de miniaturas.
/// 视频封面缓存与缩略图请求协调器。
public enum PTVideoCoverCache {
    @MainActor private static let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()

    @MainActor private static var pendingTasks: [String: Task<UIImage?, Never>] = [:]
    private static let diskStore = PTVideoCoverDiskStore()

    /// Loads a cached thumbnail or generates the requested one-based frame.
    /// Carga una miniatura en caché o genera el fotograma solicitado, empezando en uno.
    /// 读取缓存缩略图，或生成从 1 开始计数的指定帧。
    @MainActor
    public static func image(for videoURL: URL,
                             frameNumber: Int = 10,
                             maximumSize: CGSize = PTVideoThumbnailService.defaultMaximumSize,
                             appliesPreferredTrackTransform: Bool = true) async -> UIImage? {
        let key = thumbnailCacheKey(for: videoURL,
                                    frameNumber: frameNumber,
                                    maximumSize: maximumSize,
                                    appliesPreferredTrackTransform: appliesPreferredTrackTransform)

        if let image = memoryCache.object(forKey: key as NSString) {
            return image
        }

        let task: Task<UIImage?, Never>
        if let pendingTask = pendingTasks[key] {
            task = pendingTask
        } else {
            task = Task { @MainActor in
                if let data = await diskStore.readData(for: key),
                   let image = UIImage(data: data) {
                    return image
                }

                guard !Task.isCancelled else { return nil }
                let image = await PTVideoThumbnailService.image(for: videoURL,
                                                                frameNumber: frameNumber,
                                                                maximumSize: maximumSize,
                                                                appliesPreferredTrackTransform: appliesPreferredTrackTransform)
                guard !Task.isCancelled, let image else { return nil }
                guard let data = image.jpegData(compressionQuality: 0.8) else { return image }
                await diskStore.writeData(data, for: key)
                return image
            }
            pendingTasks[key] = task
        }

        let image = await task.value
        pendingTasks[key] = nil

        if let image {
            memoryCache.setObject(image,
                                  forKey: key as NSString,
                                  cost: imageMemoryCost(image))
        }
        return image
    }

    /// Keeps the legacy first-frame callback API and delegates to the canonical service.
    /// Mantiene la API heredada de callback del primer fotograma y delega en el servicio canónico.
    /// 保留旧的首帧回调 API，并代理到统一服务。
    @MainActor
    public static func getVideoFirstImage(videoUrl: String,
                                          maximumSize: CGSize = PTVideoThumbnailService.defaultMaximumSize,
                                          closure: @escaping @MainActor (UIImage?) -> Void) {
        guard let url = URL(string: videoUrl) else {
            closure(nil)
            return
        }

        Task { @MainActor in
            let image = await image(for: url,
                                    frameNumber: 1,
                                    maximumSize: maximumSize)
            closure(image)
        }
    }

    /// Keeps the legacy first-frame generation callback API.
    /// Mantiene la API heredada de callback para generar el primer fotograma.
    /// 保留旧的首帧生成回调 API。
    @MainActor
    static func generateFirstFrame(videoUrl: String,
                                   maximumSize: CGSize,
                                   completion: @escaping @MainActor (UIImage?) -> Void) {
        guard let url = URL(string: videoUrl) else {
            completion(nil)
            return
        }
        PTVideoThumbnailService.image(for: url,
                                     maximumSize: maximumSize,
                                     completion: completion)
    }

    /// Preserves the URL-only key used by the video file cache.
    /// Conserva la clave basada únicamente en URL utilizada por la caché de archivos de vídeo.
    /// 保留视频文件缓存使用的 URL-only 键。
    static func cacheKeyForVideo(_ url: String) -> String {
        let data = Data(url.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Writes a JPEG cache entry atomically on a utility task.
    /// Escribe atómicamente una entrada JPEG de caché en una tarea de utilidad.
    /// 在 utility 任务中以原子方式写入 JPEG 缓存项。
    @MainActor
    static func saveImageToDisk(_ image: UIImage, key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        Task {
            await diskStore.writeData(data, for: key)
        }
    }
}

private extension PTVideoCoverCache {
    static func thumbnailCacheKey(for url: URL,
                                  frameNumber: Int,
                                  maximumSize: CGSize,
                                  appliesPreferredTrackTransform: Bool) -> String {
        let safeFrameNumber = max(frameNumber, 1)
        // Keep invalid dimensions out of integer conversion and make the cache key deterministic.
        // Evita convertir dimensiones inválidas a enteros y mantiene determinista la clave de caché.
        // 避免将非法尺寸转换为整数，并保证缓存键稳定。
        let size = "\(sizeComponent(maximumSize.width))x\(sizeComponent(maximumSize.height))"
        let localVersion: String
        if url.isFileURL,
           let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
            let byteCount = (attributes[.size] as? NSNumber)?.int64Value ?? 0
            let modified = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
            localVersion = "|bytes:\(byteCount)|modified:\(modified)"
        } else {
            localVersion = ""
        }

        let rawKey = "pt-video-cover-v2|url:\(url.absoluteString)|frame:\(safeFrameNumber)|size:\(size)|transform:\(appliesPreferredTrackTransform)\(localVersion)"
        return cacheKeyForVideo(rawKey)
    }

    static func sizeComponent(_ value: CGFloat) -> String {
        guard value.isFinite else { return "invalid" }
        return String(describing: max(value, 0).rounded(.up))
    }

    static func imageMemoryCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let (pixelCount, pixelOverflow) = cgImage.width.multipliedReportingOverflow(by: cgImage.height)
        guard !pixelOverflow else { return Int.max }
        let (byteCount, byteOverflow) = pixelCount.multipliedReportingOverflow(by: 4)
        return byteOverflow ? Int.max : byteCount
    }
}
