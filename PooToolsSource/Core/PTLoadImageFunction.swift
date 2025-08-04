//
//  PTLoadImageFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Kingfisher
import SwifterSwift
import Photos
import ImageIO

public typealias PTLoadImageProgressBlock = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)

public struct PTLoadImageResult {
    public let allImages: [UIImage]?
    public let firstImage: UIImage?
    public let loadTime: TimeInterval

    public init(allImages: [UIImage]?, firstImage: UIImage?, loadTime: TimeInterval) {
        self.allImages = allImages
        self.firstImage = firstImage
        self.loadTime = loadTime
    }
}

@objcMembers
public class PTLoadImageFunction: NSObject {

    public static func loadImage(contentData: Any,
                                 iCloudDocumentName: String = "",
                                 progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {
        switch contentData {
        case let image as UIImage:
            return PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0)
        case let dataString as String:
            return await handleStringContent(dataString, iCloudDocumentName, progressHandle)
        case let data as Data:
            if data.detectImageType() == .GIF,let gifImage = imagesAndDurationFromGif(data: data) {
                return PTLoadImageResult(allImages: gifImage.images, firstImage: gifImage.images.first, loadTime: gifImage.duration)
            } else {
                if let image = UIImage(data: data) {
                    return PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0)
                } else {
                    return PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0)
                }
            }
        case let asset as PHAsset:
            return await handleAssetContent(asset: asset)
        default:
            return PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0)
        }
    }

    public static func handleAssetContent(asset: PHAsset) async -> PTLoadImageResult {
        await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact

            manager.requestImage(for: asset, targetSize: CGSize(width: 1024, height: 1024),
                                 contentMode: .aspectFill, options: options) { image, _ in
                DispatchQueue.main.async {
                    if let img = image {
                        continuation.resume(returning: PTLoadImageResult(allImages: [img], firstImage: img, loadTime: 0))
                    } else {
                        continuation.resume(returning: PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0))
                    }
                }
            }
        }
    }

    public static func handleStringContent(_ dataUrlString: String,
                                           _ iCloudDocumentName: String,
                                           _ progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {

        if FileManager.pt.judgeFileOrFolderExists(filePath: dataUrlString) {
            return await loadFromLocalFileAsync(path: dataUrlString)
        } else if dataUrlString.isURL() {
            return await handleURLContent(dataUrlString, iCloudDocumentName, progressHandle)
        } else if dataUrlString.isSingleEmoji {
            let emojiImage = dataUrlString.emojiToImage()
            return PTLoadImageResult(allImages: [emojiImage], firstImage: emojiImage, loadTime: 0)
        } else if let image = UIImage(named: dataUrlString) ?? UIImage(systemName: dataUrlString) {
            return PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0)
        } else {
            return PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0)
        }
    }

    private static func loadFromLocalFileAsync(path: String) async -> PTLoadImageResult {
        return await withCheckedContinuation { continuation in
            PTGCDManager.gcdGobalNormal {
                if let image = UIImage(contentsOfFile: path) {
                    PTGCDManager.gcdMain {
                        continuation.resume(returning: PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0))
                    }
                } else {
                    PTGCDManager.gcdMain {
                        continuation.resume(returning: PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0))
                    }
                }
            }
        }
    }

    public static func handleURLContent(_ dataUrlString: String,
                                        _ iCloudDocumentName: String,
                                        _ progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {

        if dataUrlString.contains("file://") {
            return await handleFileURLAsync(dataUrlString, iCloudDocumentName)
        } else if let imageURL = URL(string: dataUrlString) {
            return await downloadImage(from: imageURL, progressHandle)
        } else {
            return PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0)
        }
    }

    private static func handleFileURLAsync(_ dataUrlString: String,
                                           _ iCloudDocumentName: String) async -> PTLoadImageResult {
        return await withCheckedContinuation { continuation in
            PTGCDManager.gcdGobalNormal {
                var image: UIImage?
                if iCloudDocumentName.isEmpty {
                    image = UIImage(contentsOfFile: dataUrlString)
                } else if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(iCloudDocumentName) {
                    let imageURL = icloudURL.appendingPathComponent(dataUrlString.lastPathComponent)
                    if let imageData = try? Data(contentsOf: imageURL) {
                        image = UIImage(data: imageData)
                    }
                }

                PTGCDManager.gcdMain {
                    if let img = image {
                        continuation.resume(returning: PTLoadImageResult(allImages: [img], firstImage: img, loadTime: 0))
                    } else {
                        continuation.resume(returning: PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0))
                    }
                }
            }
        }
    }

    public static func downloadImage(from url: URL,
                                     _ progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {
        let options = PTAppBaseConfig.share.gobalWebImageLoadOption()
        let cacheKey = url.cacheKey

        // 如果有快取就直接取出
        if ImageCache.default.isCached(forKey: cacheKey) {
            do {
                // 优先从磁盘取原始数据
                if let data = try? ImageCache.default.diskStorage.value(forKey: cacheKey),
                   data.detectImageType() == .GIF {
                    if let frames = imagesAndDurationFromGif(data: data) {
                        return PTLoadImageResult(allImages: frames.images, firstImage: frames.images.first, loadTime: frames.duration)
                    }
                }

                // fallback: 从 Kingfisher 解码过的 UIImage 读取
                let result = try await ImageCache.default.retrieveImage(forKey: cacheKey, options: options)
                if let image = result.image {
                    if let frames = image.images, !frames.isEmpty {
                        return PTLoadImageResult(allImages: frames, firstImage: frames.first, loadTime: 0)
                    } else {
                        return PTLoadImageResult(allImages: [image], firstImage: image, loadTime: 0)
                    }
                } else {
                    return PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0)
                }
            } catch {
                return PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0)
            }
        }

        // 沒有快取，下載圖片
        return await withCheckedContinuation { continuation in
            ImageDownloader.default.downloadImage(
                with: url,
                options: options,
                progressBlock: { receivedSize, totalSize in
                    PTGCDManager.gcdMain {
                        progressHandle?(receivedSize, totalSize)
                    }
                },
                completionHandler: { result in
                    PTGCDManager.gcdMain {
                        switch result {
                        case .success(let value):
                            ImageCache.default.store(value.image,original: value.originalData, forKey: cacheKey)
                            let data = value.originalData
                            if data.detectImageType() == .GIF {
                                let frames = imagesAndDurationFromGif(data: data)
                                continuation.resume(returning: PTLoadImageResult(allImages: frames?.images ?? nil, firstImage: frames?.images.first ?? nil, loadTime: 0))
                            } else {
                                continuation.resume(returning: PTLoadImageResult(allImages: [value.image], firstImage: value.image, loadTime: 0))
                            }
                        case .failure( _):
                            continuation.resume(returning: PTLoadImageResult(allImages: nil, firstImage: nil, loadTime: 0))
                        }
                    }
                }
            )
        }
    }

    ///GIF data转GIF实体
    public static func handleGIFData(_ data: Data) -> [UIImage] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return []
        }

        let frameCount = CGImageSourceGetCount(source)
        var frames: [UIImage] = []

        for i in 0..<frameCount {
            if let imageRef = CGImageSourceCreateImageAtIndex(source, i, nil) {
                frames.append(UIImage(cgImage: imageRef))
            } else {
                frames.append(UIColor.clear.createImageWithColor())
            }
        }

        return frames
    }
    
    ///GIF data转GIF实体,带时间
    public static func imagesAndDurationFromGif(data: Data) -> (images: [UIImage], duration: TimeInterval)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                continue
            }

            // 获取每帧持续时间
            let frameDuration = PTLoadImageFunction.gifFrameDuration(source: source, index: i)
            totalDuration += frameDuration

            let image = UIImage(cgImage: cgImage)
            images.append(image)
        }

        return (images, totalDuration)
    }

    private static func gifFrameDuration(source: CGImageSource, index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifInfo = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }

        // 获取延迟时间
        let unclampedDelay = gifInfo[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let clampedDelay = gifInfo[kCGImagePropertyGIFDelayTime] as? TimeInterval

        let delay = unclampedDelay ?? clampedDelay ?? 0.1
        // 防止 0 延迟导致播放过快
        return delay < 0.011 ? 0.1 : delay
    }

    public static func downloadLivePhoto(photoURL: URL,
                                         videoURL: URL,
                                         contentMode: PHImageContentMode = .aspectFit,
                                         completion: @escaping (PHLivePhoto?) -> Void) {

        let dispatchGroup = DispatchGroup()
        var downloadedPhotoURL: URL?
        var downloadedVideoURL: URL?

        dispatchGroup.enter()
        downloadFile(from: photoURL) { localURL in
            downloadedPhotoURL = localURL
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        downloadFile(from: videoURL) { localURL in
            downloadedVideoURL = localURL
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            guard let photo = downloadedPhotoURL, let video = downloadedVideoURL else {
                completion(nil)
                return
            }

            let placeholderImage = UIImage(contentsOfFile: photo.path)
            PHLivePhoto.request(withResourceFileURLs: [photo, video],
                                placeholderImage: placeholderImage,
                                targetSize: placeholderImage?.size ?? .zero,
                                contentMode: contentMode) { livePhoto, _ in
                completion(livePhoto)
            }
        }
    }

    fileprivate static func downloadFile(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, _ in
            guard let localURL = localURL else {
                completion(nil)
                return
            }

            let tempDirectory = FileManager.default.temporaryDirectory
            let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                completion(destinationURL)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
