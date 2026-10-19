//
//  PTAudioCache.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 27/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation
#if canImport(PToolsCore)
import PToolsCore
#endif
#if canImport(PToolsTransferCore)
import PToolsTransferCore
#endif

// Progress callback shared by Core media caches.
// Callback de progreso compartido por las cachés multimedia de Core.
// Core 媒体缓存共用的进度回调类型。
public typealias FileDownloadProgress = @MainActor @Sendable (Int64, Int64, Double) -> Void

@MainActor
public final class PTAudioCacheFileManager {

    public static let shared = PTAudioCacheFileManager()

    // English: The audio file policy documents the bounded disk contract for this adapter.
    // Español: La política de audio documenta el contrato de disco acotado de este adaptador.
    // 中文：音频文件策略明确该适配器使用的有界磁盘契约。
    fileprivate let cachePolicy = PTCachePolicy(namespace: "media.audio-file",
                                                 diskLimit: 256 * 1024 * 1024,
                                                 diskTarget: 192 * 1024 * 1024)
    private let cacheDirectory: URL

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = base.appendingPathComponent("PTAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        cacheDirectory = directory
    }


    // 同一个 URL → 同一个文件
    public func cacheFileURL(for url: URL) -> URL {
        let originalExt = url.pathExtension.lowercased()
        let ext = originalExt.isEmpty ? "m4a" : originalExt

        let fileName =
            (url.absoluteString.urlToUnicodeURLString() ?? url.absoluteString)
            .md5

        return cacheDirectory.appendingPathComponent("\(fileName).\(ext)")
    }

    /// 核心方法：拿到“可用的本地音频文件”
    public func prepareLocalFile(for url: URL, progress: FileDownloadProgress? = nil, completion: @escaping @MainActor (URL?) -> Void) {
        // 本地文件直接返回
        if url.isFileURL {
            completion(url)
            return
        }

        let localURL = cacheFileURL(for: url)

        let finalM4AURL = localURL.deletingPathExtension().appendingPathExtension("m4a")
        if let attributes = try? FileManager.default.attributesOfItem(atPath: finalM4AURL.path),
           let size = attributes[.size] as? NSNumber,
           size.int64Value > 0 {
            completion(finalM4AURL)
            return
        }

        Task { @MainActor in
            do {
                let progressHandler: PTTransferProgressHandler?
                if let progress {
                    progressHandler = { snapshot in
                        await progress(snapshot.completed,
                                       snapshot.total ?? 0,
                                       snapshot.fraction)
                    }
                } else {
                    progressHandler = nil
                }
                _ = try await PTTransferFileDownloadService.shared.download(from: url,
                                                                            to: localURL,
                                                                            allowsResume: false,
                                                                            progress: progressHandler)

                guard PTAudioTranscoder.needTranscode(localURL) else {
                    self.trimCacheIfNeeded()
                    completion(localURL)
                    return
                }

                try? FileManager.default.removeItem(at: finalM4AURL)
                let resultURL = await PTAudioTranscoder.transcodeToM4A(from: localURL, to: finalM4AURL)
                try? FileManager.default.removeItem(at: localURL)
                self.trimCacheIfNeeded()
                completion(resultURL)
            } catch {
                completion(nil)
            }
        }
    }

    // English: Trim the audio directory after a successful download without scanning it on every read.
    // Español: Recorta el directorio de audio después de una descarga correcta sin escanearlo en cada lectura.
    // 中文：仅在下载成功后整理音频目录，读取缓存时不重复扫描。
    private func trimCacheIfNeeded() {
        guard let maximumSize = cachePolicy.diskLimit,
              let directoryTarget = cachePolicy.diskTarget else { return }
        let files = (try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        var entries = files.compactMap { url -> (url: URL, size: Int64, date: Date)? in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let size = values.fileSize,
                  let date = values.contentModificationDate else { return nil }
            return (url, Int64(size), date)
        }
        var totalSize = entries.reduce(Int64.zero) { $0 + $1.size }
        guard totalSize > maximumSize else { return }
        entries.sort { $0.date < $1.date }
        for entry in entries where totalSize > directoryTarget {
            try? FileManager.default.removeItem(at: entry.url)
            totalSize = max(0, totalSize - entry.size)
        }
    }
}

@MainActor
public final class PTAudioService {

    public static let shared = PTAudioService()

    // English: Derived durations use an explicit bounded cache policy.
    // Español: Las duraciones derivadas usan una política de caché acotada explícita.
    // 中文：派生时长使用明确的有界缓存策略。
    private let durationCachePolicy = PTCachePolicy(countLimit: 256,
                                                    costLimit: 256 * MemoryLayout<Float>.size,
                                                    namespace: "media.audio-duration")
    private let durationCache: NSCache<NSString, NSNumber> = {
        let cache = NSCache<NSString, NSNumber>()
        cache.countLimit = 256
        cache.totalCostLimit = 256 * MemoryLayout<Float>.size
        return cache
    }()

    private init() {
        durationCache.countLimit = durationCachePolicy.countLimit
        durationCache.totalCostLimit = durationCachePolicy.costLimit
        // English: Drop derived durations under memory pressure; disk media remains available for reuse.
        // Español: Libera las duraciones derivadas bajo presión de memoria; los medios en disco siguen disponibles.
        // 中文：内存紧张时释放派生的时长缓存，磁盘媒体仍可继续复用。
        _ = PTMemoryWarningCoordinator.shared.register { [weak self] in
            self?.durationCache.removeAllObjects()
        }
    }

    /// 获取音频时长（一定基于 cache 文件）
    public func fetchDuration(for url: URL,progress:FileDownloadProgress? = nil,completion: @escaping (Float, URL?) -> Void) {
        PTAudioCacheFileManager.shared.prepareLocalFile(for: url, progress: progress) { localURL in
            guard let localURL else {
                completion(0, nil)
                return
            }

            let key = NSString(string: localURL.path)

            // 内存缓存
            if let value = self.durationCache.object(forKey: key) {
                completion(value.floatValue, localURL)
                return
            }

            let asset = AVURLAsset(url: localURL)
            Task {
                do {
                    // 使用 iOS 16+ 推荐的异步加载方式获取 duration
                    let duration = try await asset.load(.duration)
                    let seconds = Float(CMTimeGetSeconds(duration))
                    
                    // 将结果存入缓存
                    self.durationCache.setObject(NSNumber(value: seconds),
                                                 forKey: key,
                                                 cost: MemoryLayout<Float>.size)
                    
                    // 返回计算好的秒数和本地 URL
                    completion(seconds, localURL)
                    
                } catch {
                    // 如果解析时长失败（比如文件损坏），可以在这里进行错误处理
                    PTNSLogConsole("获取音频时长失败: \(error.localizedDescription)")
                    completion(0, localURL) // 失败时默认返回 0
                }
            }
        }
    }

    /// 创建播放用 PlayerItem（只用 cache 文件）
    public func playerItem(for url: URL,progress:FileDownloadProgress? = nil,completion: @escaping (AVPlayerItem?) -> Void) {
        PTAudioCacheFileManager.shared.prepareLocalFile(for: url, progress: progress) { localURL in
            guard let localURL else {
                completion(nil)
                return
            }
            completion(AVPlayerItem(url: localURL))
        }
    }
}

public enum PTAudioTranscoder {

    /// 是否需要转码
    public static func needTranscode(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext != "m4a"
    }

    /// 转成 m4a（Swift 6 原生 async/await 方案）
    /// - Parameters:
    ///   - sourceURL: 源音频路径
    ///   - targetURL: 目标输出路径
    /// - Returns: 成功则返回 targetURL，失败则返回 nil
    public static func transcodeToM4A(from sourceURL: URL, to targetURL: URL) async -> URL? {
        let asset = AVURLAsset(url: sourceURL)

        // 🌟 核心适配改动：使用 iOS 16+ 的原生异步方法判断兼容性
        let isCompatible = await AVAssetExportSession.compatibility(
            ofExportPreset: AVAssetExportPresetAppleM4A,
            with: asset,
            outputFileType: .m4a
        )

        // 如果不兼容，或者无法创建 Exporter，则直接返回 nil
        guard isCompatible,
              let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            return nil
        }

        try? FileManager.default.removeItem(at: targetURL)
        exporter.outputURL = targetURL
        exporter.outputFileType = .m4a
        exporter.shouldOptimizeForNetworkUse = true

        // 🚀 核心逻辑：使用原生的 async export() 方法。
        // 代码会在这里挂起等待，直到导出完成或失败，完全消除了闭包和多线程抢占的风险
        await exporter.export()

        // 导出结束后，直接在当前上下文中读取 status
        if exporter.status == .completed,
           let attributes = try? FileManager.default.attributesOfItem(atPath: targetURL.path),
           let size = attributes[.size] as? NSNumber,
           size.int64Value > 0 {
            return targetURL
        } else {
            // 可选调试：如果出错，可以在这里打印 exporter.error 了解具体原因
            if let error = exporter.error {
                print("导出失败: \(error.localizedDescription)")
            }
            return nil
        }
    }
}
