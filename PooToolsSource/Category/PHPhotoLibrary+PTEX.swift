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

    static func saveVideoToAlbum(fileURL:URL,result: @escaping (_ finish:Bool, _ error:NSError?)->Void) {
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
}
