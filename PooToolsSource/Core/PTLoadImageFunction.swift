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

@objcMembers
public class PTLoadImageFunction: NSObject {

    public static func loadImage(contentData: Any,
                                 iCloudDocumentName: String = "",
                                 progressHandle: PTLoadImageProgressBlock? = nil) async -> ([UIImage]?, UIImage?) {

        if let image = contentData as? UIImage {
            return ([image], image)
        } else if let dataUrlString = contentData as? String {
            return await handleStringContent(dataUrlString, iCloudDocumentName, progressHandle)
        } else if let data = contentData as? Data, let image = UIImage(data: data) {
            return ([image], image)
        } else if let asset = contentData as? PHAsset {
            return await handleAssetContent(asset: asset)
        } else {
            return (nil, nil)
        }
    }

    public static func handleAssetContent(asset: PHAsset) async -> ([UIImage]?, UIImage?) {
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
                        continuation.resume(returning: ([img], img))
                    } else {
                        continuation.resume(returning: (nil, nil))
                    }
                }
            }
        }
    }

    public static func handleStringContent(_ dataUrlString: String,
                                           _ iCloudDocumentName: String,
                                           _ progressHandle: PTLoadImageProgressBlock? = nil) async -> ([UIImage]?, UIImage?) {

        if FileManager.pt.judgeFileOrFolderExists(filePath: dataUrlString) {
            return await loadFromLocalFileAsync(path: dataUrlString)
        } else if dataUrlString.isURL() {
            return await handleURLContent(dataUrlString, iCloudDocumentName, progressHandle)
        } else if dataUrlString.isSingleEmoji {
            let emojiImage = dataUrlString.emojiToImage()
            return ([emojiImage], emojiImage)
        } else if let image = UIImage(named: dataUrlString) ?? UIImage(systemName: dataUrlString) {
            return ([image], image)
        } else {
            return (nil, nil)
        }
    }

    private static func loadFromLocalFileAsync(path: String) async -> ([UIImage]?, UIImage?) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                if let image = UIImage(contentsOfFile: path) {
                    DispatchQueue.main.async {
                        continuation.resume(returning: ([image], image))
                    }
                } else {
                    DispatchQueue.main.async {
                        continuation.resume(returning: (nil, nil))
                    }
                }
            }
        }
    }

    public static func handleURLContent(_ dataUrlString: String,
                                        _ iCloudDocumentName: String,
                                        _ progressHandle: PTLoadImageProgressBlock? = nil) async -> ([UIImage]?, UIImage?) {

        if dataUrlString.contains("file://") {
            return await handleFileURLAsync(dataUrlString, iCloudDocumentName)
        } else if let imageURL = URL(string: dataUrlString) {
            return await downloadImage(from: imageURL, progressHandle)
        } else {
            return (nil, nil)
        }
    }

    private static func handleFileURLAsync(_ dataUrlString: String,
                                           _ iCloudDocumentName: String) async -> ([UIImage]?, UIImage?) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                var image: UIImage?
                if iCloudDocumentName.isEmpty {
                    image = UIImage(contentsOfFile: dataUrlString)
                } else if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(iCloudDocumentName) {
                    let imageURL = icloudURL.appendingPathComponent(dataUrlString.lastPathComponent)
                    if let imageData = try? Data(contentsOf: imageURL) {
                        image = UIImage(data: imageData)
                    }
                }

                DispatchQueue.main.async {
                    if let img = image {
                        continuation.resume(returning: ([img], img))
                    } else {
                        continuation.resume(returning: (nil, nil))
                    }
                }
            }
        }
    }

    public static func downloadImage(from url: URL,
                                     _ progressHandle: PTLoadImageProgressBlock? = nil) async -> ([UIImage]?, UIImage?) {
        let options = PTAppBaseConfig.share.gobalWebImageLoadOption()
        let cacheKey = url.cacheKey

        // 如果有快取就直接取出
        if ImageCache.default.isCached(forKey: cacheKey) {
            do {
                let result = try await ImageCache.default.retrieveImage(forKey: cacheKey, options: options)
                if let image = result.image {
                    if let frames = image.images, !frames.isEmpty {
                        return (frames, frames.first)
                    } else {
                        return ([image], image)
                    }
                } else {
                    return (nil, nil)
                }
            } catch {
                return (nil, nil)
            }
        }

        // 沒有快取，下載圖片
        return await withCheckedContinuation { continuation in
            ImageDownloader.default.downloadImage(
                with: url,
                options: options,
                progressBlock: { receivedSize, totalSize in
                    DispatchQueue.main.async {
                        progressHandle?(receivedSize, totalSize)
                    }
                },
                completionHandler: { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let value):
                            ImageCache.default.store(value.image, forKey: url.absoluteString)
                            let data = value.originalData
                            if data.detectImageType() == .GIF {
                                let frames = handleGIFData(data)
                                continuation.resume(returning: (frames, frames.first))
                            } else {
                                continuation.resume(returning: ([value.image], value.image))
                            }
                        case .failure(let error):
                            continuation.resume(returning: (nil, nil))
                        }
                    }
                }
            )
        }
    }

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
