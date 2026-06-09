//
//  PTAudioCache.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 27/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation
import Alamofire

@MainActor
public final class PTAudioCacheFileManager {

    public static let shared = PTAudioCacheFileManager()

    private let directoryName = "PTAudio"

    private init() {}

    // Cache 目录
    private var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory,in: .userDomainMask).first!
        let dir = base.appendingPathComponent(directoryName)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }
        return dir
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
    public func prepareLocalFile(for url: URL,progress:FileDownloadProgress? = nil,completion: @escaping (URL?) -> Void) {
        // 本地文件直接返回
        if url.isFileURL {
            completion(url)
            return
        }

        let localURL = cacheFileURL(for: url)

        let finalM4AURL = localURL.deletingPathExtension().appendingPathExtension("m4a")
        if FileManager.default.fileExists(atPath: finalM4AURL.path) {
            completion(finalM4AURL)
            return
        }

        let downloadURL = url.absoluteString.urlToUnicodeURLString() ?? ""
        
        Network.share.download(fileUrl: downloadURL, saveFilePath: localURL.path, progress:progress, success: { data in
            DispatchQueue.main.async {
                // 需要转码
                if PTAudioTranscoder.needTranscode(localURL) {
                    Task {
                        let resultURL = await PTAudioTranscoder.transcodeToM4A(from: localURL, to: finalM4AURL)
                        try? FileManager.default.removeItem(at: localURL)
                        completion(resultURL)
                    }
                } else {
                    completion(localURL)
                }
            }}, fail: { error in
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        )
    }
}

@MainActor
public final class PTAudioService {

    public static let shared = PTAudioService()

    private let durationCache = NSCache<NSString, NSNumber>()

    private init() {}

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
                    self.durationCache.setObject(NSNumber(value: seconds), forKey: key)
                    
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

        exporter.outputURL = targetURL
        exporter.outputFileType = .m4a
        exporter.shouldOptimizeForNetworkUse = true

        // 🚀 核心逻辑：使用原生的 async export() 方法。
        // 代码会在这里挂起等待，直到导出完成或失败，完全消除了闭包和多线程抢占的风险
        await exporter.export()

        // 导出结束后，直接在当前上下文中读取 status
        if exporter.status == .completed {
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
