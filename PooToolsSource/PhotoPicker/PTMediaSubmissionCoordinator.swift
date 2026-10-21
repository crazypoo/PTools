//
//  PTMediaSubmissionCoordinator.swift
//  PooTools
//
//  English: Owns the cancellable PhotoKit submission bridge for one picker session.
//  Español: Posee el puente cancelable de PhotoKit para una sesión del selector.
//  中文：负责当前 Picker 会话的可取消 PhotoKit 提交桥接。
//

import Photos
import UIKit

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
#endif

@MainActor
final class PTMediaSubmissionCoordinator {
    private final class RequestState {
        var requestID = PHInvalidImageRequestID
        var didFinish = false
        var fallbackAsset: PHAsset?
        var finish: (@MainActor @Sendable (UIImage?, PHAsset?) -> Void)?
    }

    private var requests: [String: RequestState] = [:]
    private var activeRequestCount = 0

    // English: Keep at most three PhotoKit submission requests active to bound memory and iCloud pressure.
    // Español: Mantiene como máximo tres solicitudes activas para limitar memoria y presión de iCloud.
    // 中文：最多同时处理三个 PhotoKit 提交请求，限制内存和 iCloud 压力。
    private func acquireRequestSlot() async -> Bool {
        while activeRequestCount >= 3 {
            guard !Task.isCancelled else { return false }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        guard !Task.isCancelled else { return false }
        activeRequestCount += 1
        return true
    }

    private func releaseRequestSlot() {
        activeRequestCount = max(0, activeRequestCount - 1)
    }

    // English: Submit one asset through a single exactly-once continuation.
    // Español: Envía un recurso mediante una única continuación que termina exactamente una vez.
    // 中文：每个资源只通过一个 continuation 完成一次提交。
    func fetch(model: PTMediaModel,
               isOriginal: Bool,
               selectionOptions: PTMediaLibSelectionOptions,
               previewBounds: CGRect,
               previewScale: CGFloat) async -> (UIImage?, PHAsset?) {
        guard await acquireRequestSlot() else { return (nil, model.asset) }
        defer { releaseRequestSlot() }

        let key = UUID().uuidString
        let asset = model.asset

        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { (continuation: CheckedContinuation<(UIImage?, PHAsset?), Never>) in
                let state = RequestState()
                state.fallbackAsset = asset
                state.finish = { [weak self, weak state] image, fallbackAsset in
                    guard let state, !state.didFinish else { return }
                    state.didFinish = true
                    state.finish = nil
                    self?.requests.removeValue(forKey: key)
                    continuation.resume(returning: (image, fallbackAsset))
                }
                requests[key] = state

                guard !Task.isCancelled else {
                    state.finish?(nil, asset)
                    return
                }

                if let editImage = model.editImage {
                    if selectionOptions.saveNewImageAfterEdit {
                        PTMediaSaveService.save(image: editImage) { [weak self, weak state] result in
                            guard let state, !state.didFinish else { return }
                            switch result {
                            case .success(let savedAsset):
                                state.finish?(editImage, savedAsset)
                            case .failure:
                                state.finish?(editImage, nil)
                            }
                            self?.requests.removeValue(forKey: key)
                        }
                    } else {
                        state.finish?(editImage, nil)
                    }
                    return
                }

                if selectionOptions.allowSelectGif, model.type == .gif {
                    state.requestID = PTMediaLibManager.requestImageData(for: asset) { [weak state] result in
                        guard let state, !state.didFinish else { return }
                        guard !result.isCancelled, result.error == nil else {
                            state.finish?(nil, asset)
                            return
                        }
                        guard !result.isDegraded else { return }
                        let image = result.data.flatMap { UIImage.pt.animateGifImage(data: $0) }
                        state.finish?(image, image == nil ? asset : nil)
                    }
                } else {
                    let targetSize = isOriginal
                        ? PHImageManagerMaximumSize
                        : model.previewSize(in: previewBounds, scale: previewScale)
                    state.requestID = PTMediaLibManager.requestImage(for: asset,
                                                                      targetSize: targetSize,
                                                                      resizeMode: .fast,
                                                                      deliveryMode: .highQualityFormat) { [weak state] result in
                        guard let state, !state.didFinish else { return }
                        guard !result.isCancelled, result.error == nil else {
                            state.finish?(nil, asset)
                            return
                        }
                        guard !result.isDegraded else { return }
                        let image = result.image?.pt.fixOrientation()
                        state.finish?(image, image == nil ? asset : nil)
                    }
                }

                if state.requestID == PHInvalidImageRequestID {
                    state.finish?(nil, asset)
                } else if Task.isCancelled {
                    cancel(key: key)
                }
            }
        }, onCancel: { [weak self] in
            Task { @MainActor [weak self] in
                self?.cancel(key: key)
            }
        })
    }

    // English: Cancel the PhotoKit request and finish its continuation immediately.
    // Español: Cancela la solicitud de PhotoKit y finaliza inmediatamente su continuación.
    // 中文：取消 PhotoKit 请求，并立即结束对应 continuation。
    func cancel(key: String) {
        guard let state = requests[key] else { return }
        let requestID = state.requestID
        state.requestID = PHInvalidImageRequestID
        if requestID != PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        state.finish?(nil, state.fallbackAsset)
    }

    // English: Closing the picker cancels every active request before the view can receive a late callback.
    // Español: Al cerrar el selector se cancelan todas las solicitudes antes de cualquier callback tardío.
    // 中文：关闭 Picker 前取消全部请求，避免关闭后仍有回调更新界面。
    func cancelAll() {
        let keys = Array(requests.keys)
        keys.forEach { cancel(key: $0) }
    }
}
