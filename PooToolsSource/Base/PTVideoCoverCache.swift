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

public final class PTVideoCoverCache {

    // MARK: - Memory Cache
    private static let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100        // 可自行调
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()

    // MARK: - Disk Cache Path
    private static let diskCacheURL: URL = {
        let url = FileManager.default.urls(for: .cachesDirectory,
                                           in: .userDomainMask)[0]
            .appendingPathComponent("PTVideoCoverCache", isDirectory: true)

        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        }
        return url
    }()

    // MARK: - Public API
    public static func getVideoFirstImage(videoUrl: String,
                                          maximumSize: CGSize = CGSize(width: 1000, height: 1000),
                                          closure: @escaping (UIImage?) -> Void) {
        let cacheKey = cacheKeyForVideo(videoUrl)

        // 1️⃣ 内存缓存
        if let image = memoryCache.object(forKey: cacheKey as NSString) {
            closure(image)
            return
        }

        // 2️⃣ 磁盘缓存
        let diskPath = diskCacheURL.appendingPathComponent(cacheKey)
        if let data = try? Data(contentsOf: diskPath),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: cacheKey as NSString)
            closure(image)
            return
        }

        // 3️⃣ 真正生成首帧
        generateFirstFrame(videoUrl: videoUrl,
                           maximumSize: maximumSize) { image in
            guard let image else {
                closure(nil)
                return
            }

            // 写缓存
            memoryCache.setObject(image, forKey: cacheKey as NSString)
            saveImageToDisk(image, key: cacheKey)

            closure(image)
        }
    }
    
    static func generateFirstFrame(videoUrl: String,
                                   maximumSize: CGSize,
                                   completion: @escaping (UIImage?) -> Void) {
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
            DispatchQueue.main.async {
                if let cgImage, result == .succeeded {
                    completion(UIImage(cgImage: cgImage))
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    static func cacheKeyForVideo(_ url: String) -> String {
        let data = Data(url.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func saveImageToDisk(_ image: UIImage, key: String) {
        DispatchQueue.global(qos: .utility).async {
            let fileURL = diskCacheURL.appendingPathComponent(key)
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

