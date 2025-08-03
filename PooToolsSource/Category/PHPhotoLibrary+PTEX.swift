//
//  PHPhotoLibrary+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Photos

extension PHPhotoLibrary: PTProtocolCompatible { }
public extension PTPOP where Base: PHPhotoLibrary {

    static func saveVideoToAlbum(fileURL:URL,result: @escaping (_ finish:Bool, _ error:NSError?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { success, error in
            if success {
                result(true,nil)
            } else {
                result(false,NSError(domain: "Video save error：\(error?.localizedDescription ?? "")", code: 0))
            }
        }
    }
    
    static func saveImageUrlToAlbum(fileUrl:URL,result: @escaping (_ finish:Bool, _ error:NSError?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileUrl)
        }) { success, error in
            if success {
                result(true,nil)
            } else {
                result(false,NSError(domain: "Image url save error：\(error?.localizedDescription ?? "")", code: 0))
            }
        }
    }
    
    /// Save image to album.
    static func saveImageToAlbum(image: UIImage, completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        var placeholderAsset: PHObjectPlaceholder?
        let completionHandler: (Bool, Error?) -> Void = { suc, _ in
            if suc {
                let asset = getAsset(from: placeholderAsset?.localIdentifier)
                completion?(suc, asset)
            } else {
                completion?(false, nil)
            }
        }

        if image.pt.hasAlphaChannel(), let data = image.pngData() {
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetCreationRequest.forAsset()
                newAssetRequest.addResource(with: .photo, data: data, options: nil)
                placeholderAsset = newAssetRequest.placeholderForCreatedAsset
            }, completionHandler: completionHandler)
        } else {
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeholderAsset = newAssetRequest.placeholderForCreatedAsset
            }, completionHandler: completionHandler)
        }
    }
    
    static func getAsset(from localIdentifier: String?) -> PHAsset? {
        guard let id = localIdentifier else {
            return nil
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        return result.firstObject
    }
}
