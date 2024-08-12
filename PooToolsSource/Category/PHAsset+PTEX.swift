//
//  PHAsset+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Photos
import MobileCoreServices
import UIKit

extension PHAsset: PTProtocolCompatible {}
public extension PTPOP where Base: PHAsset {
    var isInCloud: Bool {
        guard let resource = resource else {
            return false
        }
        return !(resource.value(forKey: "locallyAvailable") as? Bool ?? true)
    }

    var isGif: Bool {
        guard let filename = filename else {
            return false
        }
        
        return filename.hasSuffix("GIF")
    }
    
    var filename: String? {
        base.value(forKey: "filename") as? String
    }
    
    var resource: PHAssetResource? {
        PHAssetResource.assetResources(for: base).first
    }
    
    func convertPHAssetToAVAsset() async throws -> AVAsset? {
        await withUnsafeContinuation { continuation in
            self.convertPHAssetToAVAsset { avAsset in
                if avAsset != nil {
                    continuation.resume(returning: avAsset!)
                }
            }
        }
    }
    
    func convertPHAssetToAVAsset(completion: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original

        PHImageManager.default().requestAVAsset(forVideo: base, options: options) { avAsset, _, _ in
            completion(avAsset)
        }
    }
    
    //MARK: 判斷是否為LivePhoto
    ///判斷是否為LivePhoto
    func isLivePhoto() -> Bool {
        return base.mediaSubtypes.contains(.photoLive)
    }
    
    //MARK: 根據如果是LivePhoto,可以獲取圖片真身
    ///根據如果是LivePhoto,可以獲取圖片真身
    func convertLivePhotoToImage(completion: @escaping (UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true

        imageManager.requestImage(for: base,
                                  targetSize: CGSize(width: base.pixelWidth, height: base.pixelHeight),
                                  contentMode: .aspectFit,
                                  options: options) { (image, info) in
            completion(image)
        }
    }
}
