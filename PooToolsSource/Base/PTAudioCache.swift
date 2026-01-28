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
                    PTAudioTranscoder.transcodeToM4A(
                        from: localURL,
                        to: finalM4AURL
                    ) { m4aURL in
                        // 删除原始文件
                        try? FileManager.default.removeItem(at: localURL)
                        completion(m4aURL)
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
            let seconds = Float(CMTimeGetSeconds(asset.duration))

            self.durationCache.setObject(
                NSNumber(value: seconds),
                forKey: key
            )

            completion(seconds, localURL)
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

    /// 转成 m4a（系统方案）
    public static func transcodeToM4A(from sourceURL: URL,to targetURL: URL,completion: @escaping (URL?) -> Void) {
        let asset = AVURLAsset(url: sourceURL)

        guard AVAssetExportSession.exportPresets(compatibleWith: asset).contains(AVAssetExportPresetAppleM4A) else {
            completion(nil)
            return
        }

        let exporter = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        )

        exporter?.outputURL = targetURL
        exporter?.outputFileType = .m4a
        exporter?.shouldOptimizeForNetworkUse = true

        exporter?.exportAsynchronously {
            DispatchQueue.main.async {
                if exporter?.status == .completed {
                    completion(targetURL)
                } else {
                    completion(nil)
                }
            }
        }
    }
}
