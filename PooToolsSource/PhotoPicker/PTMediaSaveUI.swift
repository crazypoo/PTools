//
//  PTMediaSaveUI.swift
//  PooTools
//
//  Shared UI feedback for PhotoPicker media saves.
//

import Photos
import UIKit

@MainActor
enum PTMediaSaveUI {
    static func save(image: UIImage?,
                     videoURL: URL?,
                     onSuccess: @escaping @MainActor @Sendable (PHAsset) -> Void) {
        let isImageSave = image != nil
        PTAlertTipsViewController.tipsAlertShow(title: "",
                                                subtitle: PTMediaLibUIConfig.share.alertDoingTitle,
                                                icon: .Heart)

        PTMediaSaveService.save(image: image, videoURL: videoURL) { result in
            switch result {
            case .success(let asset):
                onSuccess(asset)
            case .failure:
                let errorMessage = isImageSave
                    ? PTMediaLibUIConfig.share.saveImageError
                    : PTMediaLibUIConfig.share.saveVideoError
                PTAlertTipsViewController.tipsAlertShow(title: "Error",
                                                        subtitle: errorMessage,
                                                        icon: .Error)
            }
        }
    }
}
