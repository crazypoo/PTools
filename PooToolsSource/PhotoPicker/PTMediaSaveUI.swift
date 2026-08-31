//
//  PTMediaSaveUI.swift
//  PooTools
//
//  Shared UI feedback for PhotoPicker media saves.
//

import Photos
import UIKit

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
#endif

#if SWIFT_PACKAGE
// English: Preserve legacy picker symbols for clients that only import PhotoPicker.
// Español: Conserva los símbolos heredados del selector para clientes que solo importan PhotoPicker.
// 中文：为只导入 PhotoPicker 的旧客户端保留选择器符号。
public typealias PTImagePicker = PooToolsImagePicker.PTImagePicker
public typealias PTImagePickerObject = PooToolsImagePicker.PTImagePickerObject
public typealias PTAlbumObject = PooToolsImagePicker.PTAlbumObject
public typealias PTPhotoObject = PooToolsImagePicker.PTPhotoObject
#endif

@MainActor
enum PTMediaSaveUI {
    // English: Keep user feedback and the typed save failure on the MainActor.
    // Español: Mantén la retroalimentación y el fallo tipado del guardado en MainActor.
    // 中文：让用户提示和类型化保存错误始终在 MainActor 执行。
    static func save(image: UIImage?,
                     videoURL: URL?,
                     onSuccess: @escaping @MainActor @Sendable (PHAsset) -> Void,
                     onFailure: @escaping @MainActor @Sendable (PTMediaSaveError) -> Void = { _ in }) {
        let isImageSave = image != nil
        PTAlertTipsViewController.tipsAlertShow(title: "",
                                                subtitle: PTMediaLibUIConfig.share.alertDoingTitle,
                                                icon: .Heart)

        PTMediaSaveService.save(image: image, videoURL: videoURL) { result in
            switch result {
            case .success(let asset):
                onSuccess(asset)
            case .failure(let error):
                let errorMessage = isImageSave
                    ? PTMediaLibUIConfig.share.saveImageError
                    : PTMediaLibUIConfig.share.saveVideoError
                PTAlertTipsViewController.tipsAlertShow(title: "Error",
                                                        subtitle: errorMessage,
                                                        icon: .Error)
                onFailure(error)
            }
        }
    }
}
