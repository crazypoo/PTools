//
//  PTMediaSaveUI.swift
//  PooTools
//
//  English: Shared UI feedback for PhotoPicker media saves.
//  Español: Retroalimentación de UI compartida para los guardados del selector de medios.
//  中文：PhotoPicker 媒体保存流程共用的 UI 反馈。
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
final class PTMediaSaveCancellation {
    private let operation: PTMediaPickerFeedbackOperation
    private let feedbackHandler: PTMediaPickerFeedbackHandler?
    private let onFailure: @MainActor @Sendable (PTMediaSaveError) -> Void

    init(operation: PTMediaPickerFeedbackOperation,
         feedbackHandler: PTMediaPickerFeedbackHandler?,
         onFailure: @escaping @MainActor @Sendable (PTMediaSaveError) -> Void) {
        self.operation = operation
        self.feedbackHandler = feedbackHandler
        self.onFailure = onFailure
    }

    // English: End the UI-side save operation once; PhotoKit may still finish its non-cancellable transaction later.
    // Español: Termina una vez la operación de guardado de UI; PhotoKit aún puede completar después su transacción no cancelable.
    // 中文：只结束一次 UI 侧保存流程；PhotoKit 的不可取消事务稍后仍可能完成。
    func cancel() {
        guard operation.canEmitTerminal() else { return }
        PTMediaPickerFeedbackRouter.route(PTMediaPickerFeedback(kind: .saveCancelled,
                                                                title: "",
                                                                message: "保存已取消",
                                                                operationID: operation.id),
                                          handler: feedbackHandler)
        onFailure(.saveFailed("保存已取消"))
    }
}

@MainActor
enum PTMediaSaveUI {
    // English: Keep user feedback and the typed save failure on the MainActor.
    // Español: Mantén la retroalimentación y el fallo tipado del guardado en MainActor.
    // 中文：让用户提示和类型化保存错误始终在 MainActor 执行。
    static func save(image: UIImage?,
                     videoURL: URL?,
                     feedbackHandler: PTMediaPickerFeedbackHandler? = nil,
                     onSuccess: @escaping @MainActor @Sendable (PHAsset) -> Void,
                     onFailure: @escaping @MainActor @Sendable (PTMediaSaveError) -> Void = { _ in }) -> PTMediaSaveCancellation {
        let isImageSave = image != nil
        let operation = PTMediaPickerFeedbackOperation()
        let cancellation = PTMediaSaveCancellation(operation: operation,
                                                    feedbackHandler: feedbackHandler,
                                                    onFailure: onFailure)
        let startFeedback = PTMediaPickerFeedback(kind: .saveStarted,
                                                   title: "",
                                                   message: PTMediaLibUIConfig.share.alertDoingTitle,
                                                   operationID: operation.id)
        PTMediaPickerFeedbackRouter.route(startFeedback, handler: feedbackHandler) {
            PTAlertTipsViewController.tipsAlertShow(title: "",
                                                    subtitle: PTMediaLibUIConfig.share.alertDoingTitle,
                                                    icon: .Heart)
        }

        PTMediaSaveService.save(image: image, videoURL: videoURL) { result in
            switch result {
            case .success(let asset):
                guard operation.canEmitTerminal() else { return }
                PTMediaPickerFeedbackRouter.route(PTMediaPickerFeedback(kind: .saveSucceeded,
                                                                        title: "",
                                                                        message: "",
                                                                        operationID: operation.id),
                                                  handler: feedbackHandler)
                onSuccess(asset)
            case .failure(let error):
                guard operation.canEmitTerminal() else { return }
                let errorMessage = isImageSave
                    ? PTMediaLibUIConfig.share.saveImageError
                    : PTMediaLibUIConfig.share.saveVideoError
                PTMediaPickerFeedbackRouter.route(PTMediaPickerFeedback(kind: .saveFailed,
                                                                        title: "Error",
                                                                        message: errorMessage,
                                                                        operationID: operation.id),
                                                  handler: feedbackHandler) {
                    PTAlertTipsViewController.tipsAlertShow(title: "Error", subtitle: errorMessage, icon: .Error)
                }
                onFailure(error)
            }
        }
        return cancellation
    }
}
