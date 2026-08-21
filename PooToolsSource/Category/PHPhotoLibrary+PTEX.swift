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

    @available(*, deprecated, message: "Use PTMediaSaveService.save(videoURL:completion:) instead")
    static func saveVideoToAlbum(fileURL:URL,result: @escaping @Sendable (_ finish:Bool, _ error:NSError?) -> Void) {
        Task { @MainActor in
            PTMediaSaveService.save(videoURL: fileURL) { saveResult in
                switch saveResult {
                case .success:
                    result(true, nil)
                case .failure(let error):
                    result(false, NSError(domain: "PTools.MediaSave",
                                          code: 1,
                                          userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
                }
            }
        }
    }
    
    @available(*, deprecated, message: "Use PTMediaSaveService.save(image:completion:) or save(videoURL:completion:) instead")
    static func saveImageUrlToAlbum(fileUrl:URL,result: @escaping @Sendable (_ finish:Bool, _ error:NSError?) -> Void) {
        // The canonical service accepts UIImage/video URLs. Keep this legacy
        // URL API as a compatibility shim and encode the image before saving.
        Task { @MainActor in
            guard let image = UIImage(contentsOfFile: fileUrl.path) else {
                result(false, NSError(domain: "PTools.MediaSave",
                                      code: 2,
                                      userInfo: [NSLocalizedDescriptionKey: "无法读取图片文件"]))
                return
            }
            PTMediaSaveService.save(image: image) { saveResult in
                switch saveResult {
                case .success:
                    result(true, nil)
                case .failure(let error):
                    result(false, NSError(domain: "PTools.MediaSave",
                                          code: 3,
                                          userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
                }
            }
        }
    }
    
    /// Save image to album.
    @available(*, deprecated, message: "Use PTMediaSaveService.save(image:completion:) instead")
    static func saveImageToAlbum(image: UIImage, completion: (@Sendable (Bool, PHAsset?) -> Void)?) {
        Task { @MainActor in
            PTMediaSaveService.save(image: image) { saveResult in
                switch saveResult {
                case .success(let asset):
                    completion?(true, asset)
                case .failure:
                    completion?(false, nil)
                }
            }
        }
    }
    
    @available(*, deprecated, message: "Use PHAsset.fetchAssets(withLocalIdentifiers:options:) directly")
    static func getAsset(from localIdentifier: String?) -> PHAsset? {
        guard let id = localIdentifier else {
            return nil
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        return result.firstObject
    }
}
