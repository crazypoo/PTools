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
    
    public static func handleAssetContent(asset:PHAsset) async -> ([UIImage]?, UIImage?) {
        return await withCheckedContinuation { continuation in
            let imageManager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            imageManager.requestImage(for: asset, targetSize: CGSizeMake(1024, 1024), contentMode: .aspectFill, options: options) { image, info in
                if image != nil {
                    continuation.resume(returning: ([image!], image!))
                } else {
                    continuation.resume(returning: (nil,nil))
                }
            }
        }
    }
    
    public static func handleStringContent(_ dataUrlString: String,
                                           _ iCloudDocumentName: String,
                                           _ progressHandle: PTLoadImageProgressBlock? = nil) async -> ([UIImage]?, UIImage?) {
        
        if FileManager.pt.judgeFileOrFolderExists(filePath: dataUrlString) {
            if let image = UIImage(contentsOfFile: dataUrlString) {
                return ([image], image)
            }
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
        
        return (nil, nil)
    }
    
    public static func handleURLContent(_ dataUrlString: String,
                                        _ iCloudDocumentName: String,
                                        _ progressHandle: PTLoadImageProgressBlock? = nil) async -> ([UIImage]?, UIImage?) {
        
        if dataUrlString.contains("file://") {
            return handleFileURL(dataUrlString, iCloudDocumentName)
        } else if let imageURL = URL(string: dataUrlString) {
            return await downloadImage(from: imageURL, progressHandle)
        } else {
            return (nil, nil)
        }
    }
    
    public static func handleFileURL(_ dataUrlString: String,
                                     _ iCloudDocumentName: String) -> ([UIImage]?, UIImage?) {
        
        if iCloudDocumentName.isEmpty {
            if let image = UIImage(contentsOfFile: dataUrlString) {
                return ([image], image)
            } else {
                return (nil, nil)
            }
        } else {
            if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(iCloudDocumentName) {
                let imageURL = icloudURL.appendingPathComponent(dataUrlString.lastPathComponent)
                if let imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: imageData) {
                    return ([image], image)
                } else {
                    return (nil, nil)
                }
            } else {
                return (nil, nil)
            }
        }
    }
    
    public static func downloadImage(from url: URL,
                                     _ progressHandle: PTLoadImageProgressBlock? = nil) async -> ([UIImage]?, UIImage?) {
        return await withCheckedContinuation { continuation in
            ImageDownloader.default.downloadImage(with: url, options: PTAppBaseConfig.share.gobalWebImageLoadOption(), progressBlock: { receivedSize, totalSize in
                PTGCDManager.gcdGobal {
                    progressHandle?(receivedSize, totalSize)
                }
            }) { result in
                switch result {
                case .success(let value):
                    if value.originalData.detectImageType() == .GIF {
                        let frames = handleGIFData(value.originalData)
                        continuation.resume(returning: (frames, frames.first))
                    } else {
                        continuation.resume(returning: ([value.image], value.image))
                    }
                case .failure(_):
                    continuation.resume(returning: (nil, nil))
                }
            }
        }
    }
    
    public static func handleGIFData(_ data: Data) -> [UIImage] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return []
        }
        
        let frameCount = CGImageSourceGetCount(source)
        var frames = [UIImage]()
        for i in 0..<frameCount {
            if let imageRef = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: imageRef)
                frames.append(image)
            } else {
                frames.append(UIColor.clear.createImageWithColor())
            }
        }
        return frames
    }
    
    /*
     let livePhotoView = PHLivePhotoView(frame: CGRect(x: 0,
                                                               y: 200,
                                                               width: UIScreen.main.bounds.width,
                                                               height: 300))
             livePhotoView.contentMode = .scaleAspectFit
             // 播放时是否静音
             livePhotoView.isMuted = false
             livePhotoView.delegate = self
     livePhotoView.startPlayback(with: .full)
     */
    public static func downloadLivePhoto(photoURL: URL, videoURL: URL,contentMode:PHImageContentMode = .aspectFit, completion: @escaping (PHLivePhoto?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var downloadedPhotoURL: URL?
        var downloadedVideoURL: URL?
        
        // 下载图片文件
        dispatchGroup.enter()
        downloadFile(from: photoURL) { localURL in
            downloadedPhotoURL = localURL
            dispatchGroup.leave()
        }
        
        // 下载视频文件
        dispatchGroup.enter()
        downloadFile(from: videoURL) { localURL in
            downloadedVideoURL = localURL
            dispatchGroup.leave()
        }
        
        // 所有文件下载完成后创建 PHLivePhoto
        dispatchGroup.notify(queue: .main) {
            guard let photo = downloadedPhotoURL, let video = downloadedVideoURL else {
                completion(nil)
                return
            }
            
            let placeholderImage = UIImage(contentsOfFile: photo.path)
            // 创建 PHLivePhoto
            PHLivePhoto.request(withResourceFileURLs: [photo, video], placeholderImage: placeholderImage, targetSize: placeholderImage?.size ?? .zero, contentMode: contentMode) { livePhoto, info in
                completion(livePhoto)
            }
        }
    }

    fileprivate static func downloadFile(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL else {
                completion(nil)
                return
            }
            
            // 将文件移动到临时目录
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileName = url.lastPathComponent
            let destinationURL = tempDirectory.appendingPathComponent(fileName)
            
            do {
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                completion(destinationURL)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
