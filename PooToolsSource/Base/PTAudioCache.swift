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
        let name = (url.absoluteString.urlToUnicodeURLString() ?? "").md5 + ".m4a"
        return cacheDirectory.appendingPathComponent(name)
    }

    /// 核心方法：拿到“可用的本地音频文件”
    public func prepareLocalFile(for url: URL,progress:FileDownloadProgress? = nil,completion: @escaping (URL?) -> Void) {
        // 本地文件直接返回
        if url.isFileURL {
            completion(url)
            return
        }

        let localURL = cacheFileURL(for: url)

        // 已缓存
        if FileManager.default.fileExists(atPath: localURL.path) {
            completion(localURL)
            return
        }
        let downloadURL = url.absoluteString.urlToUnicodeURLString() ?? ""
        
        Network.share.download(fileUrl: downloadURL, saveFilePath: localURL.path, progress:progress, success: { data in
            DispatchQueue.main.async {
                completion(localURL)
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
