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

public final class PTVideoFileCache {

    public static let shared = PTVideoFileCache()
    private init() {}

    private let directoryName = "PTVideoFileCache"

    private lazy var cacheDirectory: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory,
                                           in: .userDomainMask)[0]
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }
        return dir
    }()

    // 同一个 URL → 同一个文件
    public func cacheURL(for videoURL: URL) -> URL {
        let key = PTVideoCoverCache.cacheKeyForVideo(videoURL.absoluteString)
        let ext = videoURL.pathExtension.isEmpty ? "mp4" : videoURL.pathExtension
        return cacheDirectory.appendingPathComponent("\(key).\(ext)")
    }

    public func cachedFileURL(for url: URL) -> URL? {
        guard !url.isFileURL else {
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }

        let localURL = cacheURL(for: url)

        guard FileManager.default.fileExists(atPath: localURL.path) else {
            return nil
        }

        // 可选：防止 0 字节 / 下载未完成的脏文件
        if let attr = try? FileManager.default.attributesOfItem(atPath: localURL.path),
           let fileSize = attr[.size] as? NSNumber,
           fileSize.int64Value > 0 {
            return localURL
        }
        return nil
    }
    
    /// 核心：获取可用的视频文件（本地 or 下载）
    public func prepareVideo( url: URL,progress:FileDownloadProgress? = nil, completion: @escaping (URL?) -> Void) {
        // 本地文件直接返回
        if let cached = cachedFileURL(for: url) {
            completion(cached)
            return
        }

        let localURL = cacheURL(for: url)
        let downloadURL = url.absoluteString.urlToUnicodeURLString() ?? ""

        Network.share.download(fileUrl: downloadURL, saveFilePath: localURL.path,progress: progress) { reponse in
            DispatchQueue.main.async {
                completion(localURL)
            }
        } fail: { error in
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}

public final class PTVideoCoverCache {

    private static let workQueue = DispatchQueue(label: "com.pt.video.cover.cache",
                                                 qos: .userInitiated)
    
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
                                           in: .userDomainMask)[0].appendingPathComponent("PTVideoCoverCache", isDirectory: true)

        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url,withIntermediateDirectories: true)
        }
        return url
    }()

    // MARK: - Public API
    public static func getVideoFirstImage(videoUrl: String,
                                          maximumSize: CGSize = CGSize(width: 1000, height: 1000),
                                          closure: @escaping (UIImage?) -> Void) {
        let cacheKey = cacheKeyForVideo(videoUrl)

        // 1️⃣ 内存缓存（主线程直接返回）
        if let image = memoryCache.object(forKey: cacheKey as NSString) {
            closure(image)
            return
        }

        // 2️⃣ 后台队列处理磁盘 & 生成
        workQueue.async {

            let diskPath = diskCacheURL.appendingPathComponent(cacheKey)

            // 2️⃣ 磁盘缓存（后台 IO + 解码）
            if let data = try? Data(contentsOf: diskPath),
               let image = UIImage(data: data)?.ptDecodedImage() {

                memoryCache.setObject(image,
                                      forKey: cacheKey as NSString)

                DispatchQueue.main.async {
                    closure(image)
                }
                return
            }

            // 3️⃣ 生成首帧（仍然在后台）
            generateFirstFrame(videoUrl: videoUrl,
                               maximumSize: maximumSize) { image in
                guard let image else {
                    DispatchQueue.main.async { closure(nil) }
                    return
                }

                let decoded = image.ptDecodedImage()
                memoryCache.setObject(decoded,
                                      forKey: cacheKey as NSString)
                saveImageToDisk(decoded, key: cacheKey)

                DispatchQueue.main.async {
                    closure(decoded)
                }
            }
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
            if let cgImage, result == .succeeded {
                completion(UIImage(cgImage: cgImage)) // ❗ 不切主线程
            } else {
                completion(nil)
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

private extension UIImage {

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

        context?.draw(cgImage, in: CGRect(x: 0,
                                          y: 0,
                                          width: width,
                                          height: height))

        guard let decoded = context?.makeImage() else { return self }
        return UIImage(cgImage: decoded)
    }
}
