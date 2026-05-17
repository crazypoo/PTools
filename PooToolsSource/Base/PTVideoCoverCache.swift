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

/// 统一的视频缓存数据对象
/// 符合 Sendable 协议，确保可在多线程间安全传递
public struct PTVideoCacheItem: Sendable {
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
                             coverReady: @escaping @Sendable (PTVideoCacheItem) -> Void,
                             videoReady: (@Sendable (PTVideoCacheItem) -> Void)? = nil) {
        
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
            DispatchQueue.main.async {
                coverReady(frozenItemAfterCover)
            }
            
            // 检查是否需要下载
            if autoCacheVideo && frozenItemAfterCover.localVideoURL == nil {
                PTVideoFileCache.shared.prepareVideo(url: url, progress: progress) { localURL in
                    // 步骤 4：在内层闭包中，基于刚才冻结的 let 常量，再创建一个 var 用于最终修改
                    var finalItem = frozenItemAfterCover
                    if let localURL = localURL {
                        finalItem.localVideoURL = localURL
                    }
                    
                    // 最后一次回调
                    DispatchQueue.main.async {
                        videoReady?(finalItem)
                    }
                }
            } else {
                // 如果不需要下载，直接返回冻结的状态
                DispatchQueue.main.async {
                    videoReady?(frozenItemAfterCover)
                }
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
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
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
                             completion: @escaping @Sendable (URL?) -> Void) { // 🌟 Swift 6: 异步回调标记 @Sendable
        // 本地文件直接返回
        if let cached = cachedFileURL(for: url) {
            completion(cached)
            return
        }

        let localURL = cacheURL(for: url)
        // 确保您的 urlToUnicodeURLString 方法是线程安全的扩展
        let downloadURL = url.absoluteString.urlToUnicodeURLString() ?? ""

        // 假定 Network.share.download 的成功和失败回调在 Swift 6 环境下也支持并发安全
        Network.share.download(fileUrl: downloadURL, saveFilePath: localURL.path, progress: progress) { _ in
            completion(localURL)
        } fail: { _ in
            completion(nil)
        }
    }
}

/// 视频封面图缓存与生成工具
/// 🌟 Swift 6 改进：改为 case-less enum，作为纯静态命名空间，天生具备线程安全性
public enum PTVideoCoverCache {

    private static let workQueue = DispatchQueue(label: "com.pt.video.cover.cache", qos: .userInitiated)
    
    // MARK: - Memory Cache (NSCache 本身是线程安全的)
    @MainActor private static let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()

    // MARK: - Disk Cache Path
    private static let diskCacheURL: URL = {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PTVideoCoverCache", isDirectory: true)

        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }()

    // MARK: - Public API
    
    /// 获取视频第一帧图片（支持内存、磁盘缓存及异步生成）
    @MainActor public static func getVideoFirstImage(videoUrl: String,
                                          maximumSize: CGSize = CGSize(width: 1000, height: 1000),
                                          closure: @escaping @Sendable (UIImage?) -> Void) { // 🌟 Swift 6: 标记 @Sendable
        let cacheKey = cacheKeyForVideo(videoUrl)

        // 1️⃣ 内存缓存（直接返回）
        if let image = memoryCache.object(forKey: cacheKey as NSString) {
            closure(image)
            return
        }

        // 2️⃣ 后台队列处理磁盘 & 异步生成
        workQueue.async {
            let diskPath = diskCacheURL.appendingPathComponent(cacheKey)

            // 2️⃣ 磁盘缓存读取与解码
            if let data = try? Data(contentsOf: diskPath),
               let image = UIImage(data: data)?.ptDecodedImage() {

                Task { @MainActor in
                    memoryCache.setObject(image, forKey: cacheKey as NSString)
                }
                closure(image)
                return
            }

            // 3️⃣ 生成首帧
            generateFirstFrame(videoUrl: videoUrl, maximumSize: maximumSize) { image in
                guard let image else {
                    closure(nil)
                    return
                }

                Task { @MainActor in
                    let decoded = image.ptDecodedImage()
                    memoryCache.setObject(decoded, forKey: cacheKey as NSString)
                    saveImageToDisk(decoded, key: cacheKey)
                    closure(decoded)
                }
            }
        }
    }
    
    /// 异步生成视频首帧
    static func generateFirstFrame(videoUrl: String,
                                   maximumSize: CGSize,
                                   completion: @escaping @Sendable (UIImage?) -> Void) { // 🌟 Swift 6: 标记 @Sendable
        guard let url = URL(string: videoUrl) else {
            completion(nil)
            return
        }

        let opts = [AVURLAssetPreferPreciseDurationAndTimingKey: false]
        let asset = AVURLAsset(url: url, options: opts)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = maximumSize

        let time = CMTime(seconds: 0, preferredTimescale: 600)

        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, _ in
            if let cgImage, result == .succeeded {
                completion(UIImage(cgImage: cgImage))
            } else {
                completion(nil)
            }
        }
    }
    
    /// 基于 SHA256 的唯一 Key 生成
    static func cacheKeyForVideo(_ url: String) -> String {
        let data = Data(url.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// 将图片原子性写入磁盘缓存
    static func saveImageToDisk(_ image: UIImage, key: String) {
        DispatchQueue.global(qos: .utility).async {
            let fileURL = diskCacheURL.appendingPathComponent(key)
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

// MARK: - 图片解压扩展
private extension UIImage {
    /// 在后台强制对图片进行位图解码，避免主线程渲染卡顿
    func ptDecodedImage() -> UIImage {
        guard let cgImage else { return self }

        let width = cgImage.width
        let height = cgImage.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let decoded = context?.makeImage() else { return self }
        return UIImage(cgImage: decoded)
    }
}
