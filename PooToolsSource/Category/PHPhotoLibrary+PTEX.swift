//
//  PHPhotoLibrary+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Photos

private final class AssetIdentifierStorage: @unchecked Sendable {
    private var identifier: String?
    private let lock = NSLock()
    
    func setIdentifier(_ id: String?) {
        lock.lock()
        identifier = id
        lock.unlock()
    }
    
    func getIdentifier() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return identifier
    }
}

extension PHPhotoLibrary: PTProtocolCompatible { }
public extension PTPOP where Base: PHPhotoLibrary {

    static func saveVideoToAlbum(fileURL:URL,result: @escaping @Sendable (_ finish:Bool, _ error:NSError?) -> Void) {
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
    
    static func saveImageUrlToAlbum(fileUrl:URL,result: @escaping @Sendable (_ finish:Bool, _ error:NSError?) -> Void) {
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
    static func saveImageToAlbum(image: UIImage, completion: (@Sendable (Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        
        // 2. 实例化线程安全的包装类
        let assetStorage = AssetIdentifierStorage()
        
        // 3. 这里的 completionHandler 明确声明为 @Sendable
        let completionHandler: @Sendable (Bool, Error?) -> Void = { suc, _ in
            if suc {
                // 安全地读取 Identifier 并获取 Asset
                let asset = getAsset(from: assetStorage.getIdentifier())
                completion?(suc, asset)
            } else {
                completion?(false, nil)
            }
        }

        if image.pt.hasAlphaChannel(), let data = image.pngData() {
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetCreationRequest.forAsset()
                newAssetRequest.addResource(with: .photo, data: data, options: nil)
                // 4. 安全地存入 Identifier
                assetStorage.setIdentifier(newAssetRequest.placeholderForCreatedAsset?.localIdentifier)
            }, completionHandler: completionHandler)
        } else {
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                // 4. 安全地存入 Identifier
                assetStorage.setIdentifier(newAssetRequest.placeholderForCreatedAsset?.localIdentifier)
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
