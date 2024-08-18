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

@objcMembers
public class PTLoadImageFunction: NSObject {
    
    public static func loadImage(contentData: Any,
                                 iCloudDocumentName: String = "",
                                 progressHandle: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)? = nil) async -> ([UIImage]?, UIImage?) {
        
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
                                           _ progressHandle: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)?) async -> ([UIImage]?, UIImage?) {
        
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
                                        _ progressHandle: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)?) async -> ([UIImage]?, UIImage?) {
        
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
                                     _ progressHandle: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)?) async -> ([UIImage]?, UIImage?) {
        return await withCheckedContinuation { continuation in
            ImageDownloader.default.downloadImage(with: url, options: PTAppBaseConfig.share.gobalWebImageLoadOption(), progressBlock: { receivedSize, totalSize in
                progressHandle?(receivedSize, totalSize)
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
}
