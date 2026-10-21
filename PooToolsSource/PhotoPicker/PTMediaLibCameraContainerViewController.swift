//
//  PTMediaLibCameraContainerViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 31/5/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Photos
import SnapKit
import UniformTypeIdentifiers

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
import PTCameraPermission
#endif

public class PTMediaLibCameraContainerViewController: PTBaseViewController {

    open override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }

    public let picker = UIImagePickerController()
    // English: Optional camera policy; nil preserves the legacy singleton fallback for direct callers.
    // Español: Política de cámara opcional; nil conserva el respaldo del singleton heredado para llamadas directas.
    // 中文：可选的相机策略；为 nil 时保留直接调用者的旧单例兼容行为。
    public var cameraOptions: PTMediaLibCameraOptions?
    public var handleNewAssetCallback:((_ asset: PHAsset) -> Void)?
    public var handleCameraFailureCallback: (@MainActor @Sendable (PTSystemMediaPickerError) -> Void)?

    // English: Serialize capture completion so save, cancel, and failure cannot finish twice.
    // Español: Serializa la finalización de captura para que guardar, cancelar y fallar no terminen dos veces.
    // 中文：串行化拍摄完成流程，避免保存、取消和失败路径重复结束。
    private var isFinishingCapture = false
    private var didDeliverAsset = false
    private var didReportFailure = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupPicker()
    }
    
    private func setupPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            handleCameraFailure(.cameraUnavailable)
            return
        }

        guard PTPermission.camera.status == .authorized else {
            handleCameraFailure(.permissionDenied)
            return
        }

        let mediaTypes = calculateMediaTypes()
        guard !mediaTypes.isEmpty else {
            handleCameraFailure(.invalidConfiguration)
            return
        }

        picker.delegate = self
        picker.sourceType = .camera
        picker.videoQuality = .typeHigh
        picker.mediaTypes = mediaTypes
        let options = cameraOptions ?? PTMediaLibSelectionOptions.current().cameraOptions
        picker.videoMaximumDuration = TimeInterval(options.maxRecordDuration)

        addChild(picker)
        view.addSubview(picker.view)

        picker.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        picker.didMove(toParent: self)
    }
    
    private func calculateMediaTypes() -> [String] {
        let options = cameraOptions ?? PTMediaLibSelectionOptions.current().cameraOptions
        var types: [String] = []
        if options.allowTakePhoto { types.append(UTType.image.identifier) }
        if options.allowRecordVideo { types.append(UTType.movie.identifier) }
        return types
    }

    private func handleCameraFailure(_ error: PTSystemMediaPickerError) {
        guard !didReportFailure else { return }
        didReportFailure = true
        isFinishingCapture = true
        // English: Report a typed failure before dismissing the embedded camera.
        // Español: Informa del fallo tipado antes de cerrar la cámara integrada.
        // 中文：关闭嵌入式相机前先回传类型化错误。
        handleCameraFailureCallback?(error)
        if presentingViewController != nil {
            dismiss(animated: true)
        }
    }
}

extension PTMediaLibCameraContainerViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    // MARK: - ImagePicker Delegate
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard !isFinishingCapture else { return }
        isFinishingCapture = true

        do {
            switch try PTCameraCapturePayload.parse(info) {
            case .image(let image):
                saveMediaToAlbum(image: image, videoUrl: nil)
            case .video(let url):
                let copiedURL = try PTMediaTemporaryFile.copyVideoToTemporaryURL(url)
                saveMediaToAlbum(image: nil, videoUrl: copiedURL, ownedTemporaryURL: copiedURL)
            }
        } catch let error as PTSystemMediaPickerError {
            handleCameraFailure(error)
        } catch {
            handleCameraFailure(.loadFailed(String(describing: error)))
        }
    }

    // English: Route both camera media kinds through the shared save service and reset on failure.
    // Español: Envía ambos tipos de medios de cámara al servicio de guardado común y restablece el estado si falla.
    // 中文：图片和视频都走统一保存服务，失败时恢复拍摄状态。
    /// 统一保存逻辑
    @MainActor
    fileprivate func saveMediaToAlbum(image: UIImage?,
                                      videoUrl: URL?,
                                      ownedTemporaryURL: URL? = nil) {
        PTMediaSaveUI.save(image: image,
                           videoURL: videoUrl,
                           onSuccess: { [weak self] asset in
                               guard let self else { return }
                               self.removeTemporaryFile(ownedTemporaryURL)
                               let deliver = {
                                   guard !self.didDeliverAsset else { return }
                                   self.didDeliverAsset = true
                                   self.handleNewAsset(asset)
                               }
                               if self.presentingViewController != nil {
                                   self.dismiss(animated: true, completion: deliver)
                               } else {
                                   deliver()
                               }
                           },
                           onFailure: { [weak self] _ in
                               self?.removeTemporaryFile(ownedTemporaryURL)
                               self?.isFinishingCapture = false
                           })
    }

    // English: Remove only the temporary copy owned by this capture flow.
    // Español: Elimina únicamente la copia temporal propiedad de este flujo de captura.
    // 中文：只清理当前拍摄流程自己持有的临时副本。
    private func removeTemporaryFile(_ url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// 处理新生成的资源并插入到当前列表
    private func handleNewAsset(_ asset: PHAsset) {
        handleNewAssetCallback?(asset)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // English: Cancellation is terminal for this presentation and must not trigger a save.
        // Español: La cancelación termina esta presentación y no debe iniciar un guardado.
        // 中文：取消是本次展示的终态，不能再触发保存。
        guard !isFinishingCapture else { return }
        isFinishingCapture = true
        dismiss(animated: true)
    }
}
