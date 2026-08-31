//
//  PTImagePicker.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
@preconcurrency import PhotosUI
import ObjectiveC

#if SWIFT_PACKAGE
import ptools
import PTCameraPermission
#endif

// English: The system picker exposes one explicit media policy instead of dynamic picker settings.
// Español: El selector del sistema expone una política multimedia explícita en lugar de ajustes dinámicos.
// 中文：系统选择器通过明确的媒体策略替代动态类型配置。
public enum PTSystemMediaPickerKind: Sendable {
    case image
    case video
    case imageOrVideo
}

// English: Sendable results cross the async boundary as immutable data or a caller-owned file URL.
// Español: Los resultados Sendable cruzan el límite async como datos inmutables o una URL de archivo propiedad del llamador.
// 中文：Sendable 结果以不可变数据或由调用方持有的文件 URL 跨越异步边界。
public enum PTSystemMediaPickerResult: Sendable {
    case image(data: Data, assetIdentifier: String?)
    case video(fileURL: URL, assetIdentifier: String?)

    public var assetIdentifier: String? {
        switch self {
        case .image(_, let assetIdentifier), .video(_, let assetIdentifier):
            return assetIdentifier
        }
    }

    public var imageData: Data? {
        guard case .image(let data, _) = self else { return nil }
        return data
    }

    public var videoURL: URL? {
        guard case .video(let url, _) = self else { return nil }
        return url
    }
}

// English: Typed failures distinguish cancellation, permissions, presentation, and provider errors.
// Español: Los fallos tipados distinguen cancelación, permisos, presentación y errores del proveedor.
// 中文：类型化错误明确区分取消、权限、展示和 provider 读取失败。
public enum PTSystemMediaPickerError: Error, LocalizedError, Sendable {
    case cameraUnavailable
    case presentationUnavailable
    case permissionDenied
    case cancelled
    case unsupportedResult
    case invalidConfiguration
    case loadFailed(String)
    case temporaryFileCopyFailed(String)

    public var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "当前设备不支持相机"
        case .presentationUnavailable:
            return "找不到可用于展示选择器的页面"
        case .permissionDenied:
            return "相机权限未开启"
        case .cancelled:
            return "用户取消了媒体选择"
        case .unsupportedResult:
            return "选择的媒体类型不受支持"
        case .invalidConfiguration:
            return "媒体选择器配置无效"
        case .loadFailed(let message):
            return message
        case .temporaryFileCopyFailed(let message):
            return "媒体临时文件复制失败：\(message)"
        }
    }
}

// English: This MainActor-only payload keeps UIKit camera metadata at the delegate boundary.
// Español: Este contenido restringido a MainActor mantiene los metadatos UIKit en el límite del delegate.
// 中文：这个仅限 MainActor 的结果载体把 UIKit 相机 metadata 限制在 delegate 边界内。
@MainActor
public enum PTCameraCapturePayload {
    case image(UIImage)
    case video(URL)

    public static func parse(_ info: [UIImagePickerController.InfoKey: Any]) throws -> Self {
        let mediaType = info[.mediaType] as? String
        let image = info[.originalImage] as? UIImage
        let imageURL = info[.imageURL] as? URL
        let videoURL = info[.mediaURL] as? URL

        if let videoURL,
           mediaType != UTType.image.identifier,
           mediaType != UTType.livePhoto.identifier {
            return .video(videoURL)
        }

        if let image {
            return .image(image)
        }

        if let imageURL,
           let image = UIImage(contentsOfFile: imageURL.path) {
            return .image(image)
        }

        if let videoURL {
            return .video(videoURL)
        }

        throw PTSystemMediaPickerError.unsupportedResult
    }
}

// English: Use this facade for single-image, single-video, and camera selection on iOS 17+.
// Español: Usa esta fachada para seleccionar una imagen, un vídeo o la cámara en iOS 17+.
// 中文：iOS 17+ 的单图、单视频和相机选择统一使用这个门面。
@MainActor
public enum PTSystemMediaPicker {
    public static func pick(
        _ kind: PTSystemMediaPickerKind,
        from presenter: UIViewController? = nil
    ) async throws -> PTSystemMediaPickerResult {
        guard let presenter = presenter ?? PTSceneContext.currentViewController() else {
            throw PTSystemMediaPickerError.presentationUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = PTSystemMediaPickerCoordinator(
                kind: kind,
                continuation: continuation
            )
            coordinator.start(from: presenter, source: .library)
        }
    }

    public static func capture(
        _ kind: PTSystemMediaPickerKind,
        from presenter: UIViewController? = nil
    ) async throws -> PTSystemMediaPickerResult {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            throw PTSystemMediaPickerError.cameraUnavailable
        }

        guard await requestCameraAccess() else {
            throw PTSystemMediaPickerError.permissionDenied
        }

        guard let presenter = presenter ?? PTSceneContext.currentViewController() else {
            throw PTSystemMediaPickerError.presentationUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = PTSystemMediaPickerCoordinator(
                kind: kind,
                continuation: continuation
            )
            coordinator.start(from: presenter, source: .camera)
        }
    }

    // English: Share one camera authorization path with embedded PhotoPicker camera flows.
    // Español: Comparte una única ruta de autorización de cámara con los flujos de cámara embebidos de PhotoPicker.
    // 中文：让嵌入式 PhotoPicker 相机流程共用同一套相机授权路径。
    public static func requestCameraAccess() async -> Bool {
        switch PTPermission.camera.status {
        case .authorized:
            return true
        case .denied, .notSupported:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                PTPermission.camera.request {
                    Task { @MainActor in
                        continuation.resume(returning: PTPermission.camera.status == .authorized)
                    }
                }
            }
        }
    }
}

@MainActor
private final class PTSystemMediaPickerCoordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    fileprivate enum Source {
        case library
        case camera
    }

    private let kind: PTSystemMediaPickerKind
    private let continuation: CheckedContinuation<PTSystemMediaPickerResult, Error>
    private weak var presenter: UIViewController?
    private var presentedController: UIViewController?
    private var didFinish = false

    init(kind: PTSystemMediaPickerKind,
         continuation: CheckedContinuation<PTSystemMediaPickerResult, Error>) {
        self.kind = kind
        self.continuation = continuation
        super.init()
    }

    fileprivate func start(from presenter: UIViewController, source: Source) {
        self.presenter = presenter
        let targetPresenter = topPresenter(from: presenter)

        guard targetPresenter.viewIfLoaded?.window != nil,
              !targetPresenter.isBeingDismissed,
              !targetPresenter.isBeingPresented else {
            finish(.failure(.presentationUnavailable))
            return
        }

        switch source {
        case .library:
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.selectionLimit = 1
            configuration.filter = filter(for: kind)
            configuration.preferredAssetRepresentationMode = .current

            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            presentedController = picker
            objc_setAssociatedObject(
                picker,
                &PTSystemMediaPickerAssociation.key,
                self,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            targetPresenter.present(picker, animated: true)

        case .camera:
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = mediaTypes(for: kind)
            picker.videoQuality = .typeHigh
            picker.delegate = self
            presentedController = picker
            objc_setAssociatedObject(
                picker,
                &PTSystemMediaPickerAssociation.key,
                self,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            targetPresenter.present(picker, animated: true)
        }
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            finish(.failure(.cancelled))
            return
        }

        let provider = result.itemProvider
        switch kind {
        case .image:
            loadImage(from: provider, assetIdentifier: result.assetIdentifier)
        case .video:
            loadVideo(from: provider, assetIdentifier: result.assetIdentifier)
        case .imageOrVideo:
            if hasImageRepresentation(provider) {
                loadImage(from: provider, assetIdentifier: result.assetIdentifier)
            } else {
                loadVideo(from: provider, assetIdentifier: result.assetIdentifier)
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        do {
            switch try PTCameraCapturePayload.parse(info) {
            case .image(let image):
                guard let data = image.pngData() ?? image.jpegData(compressionQuality: 1) else {
                    finish(.failure(.loadFailed("相机图片编码失败")))
                    return
                }
                finish(.success(.image(data: data, assetIdentifier: nil)))

            case .video(let url):
                let copiedURL = try ptCopyVideoToTemporaryURL(url)
                finish(.success(.video(fileURL: copiedURL, assetIdentifier: nil)))
            }
        } catch let error as PTSystemMediaPickerError {
            finish(.failure(error))
        } catch {
            finish(.failure(.loadFailed(String(describing: error))))
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        finish(.failure(.cancelled))
    }

    private func filter(for kind: PTSystemMediaPickerKind) -> PHPickerFilter {
        switch kind {
        case .image:
            return .images
        case .video:
            return .videos
        case .imageOrVideo:
            return .any(of: [.images, .videos])
        }
    }

    private func mediaTypes(for kind: PTSystemMediaPickerKind) -> [String] {
        switch kind {
        case .image:
            return [UTType.image.identifier]
        case .video:
            return [UTType.movie.identifier]
        case .imageOrVideo:
            return [UTType.image.identifier, UTType.movie.identifier]
        }
    }

    private func hasImageRepresentation(_ provider: NSItemProvider) -> Bool {
        provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) ||
        provider.hasItemConformingToTypeIdentifier(UTType.livePhoto.identifier)
    }

    private func imageTypeIdentifier(for provider: NSItemProvider) -> String? {
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return UTType.image.identifier
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.livePhoto.identifier) {
            return UTType.livePhoto.identifier
        }
        return nil
    }

    private func videoTypeIdentifier(for provider: NSItemProvider) -> String? {
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            return UTType.movie.identifier
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.video.identifier) {
            return UTType.video.identifier
        }
        return nil
    }

    private func loadImage(from provider: NSItemProvider, assetIdentifier: String?) {
        guard let typeIdentifier = imageTypeIdentifier(for: provider) else {
            finish(.failure(.unsupportedResult))
            return
        }

        // English: Keep the MainActor delivery closure separate from the provider callback.
        // Español: Mantén separado el cierre de entrega en MainActor del callback del proveedor.
        // 中文：将 MainActor 投递闭包与 provider 回调分离，避免捕获非 Sendable provider。
        let deliver: @MainActor @Sendable (Result<PTSystemMediaPickerResult, PTSystemMediaPickerError>) -> Void = { [weak self] result in
            self?.finish(result)
        }

        provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
            guard let data, !data.isEmpty else {
                let message = error?.localizedDescription ?? "图片数据读取失败"
                PTMainActorBridge.perform {
                    deliver(.failure(.loadFailed(message)))
                }
                return
            }

            PTMainActorBridge.perform {
                deliver(.success(.image(data: data, assetIdentifier: assetIdentifier)))
            }
        }
    }

    private func loadVideo(from provider: NSItemProvider, assetIdentifier: String?) {
        guard let typeIdentifier = videoTypeIdentifier(for: provider) else {
            finish(.failure(.unsupportedResult))
            return
        }

        // English: Deliver provider results through a Sendable MainActor closure.
        // Español: Entrega los resultados del proveedor mediante un cierre Sendable en MainActor.
        // 中文：通过 Sendable 的 MainActor 闭包投递 provider 结果。
        let deliver: @MainActor @Sendable (Result<PTSystemMediaPickerResult, PTSystemMediaPickerError>) -> Void = { [weak self] result in
            self?.finish(result)
        }

        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
            guard let url else {
                let message = error?.localizedDescription ?? "视频文件读取失败"
                PTMainActorBridge.perform {
                    deliver(.failure(.loadFailed(message)))
                }
                return
            }

            do {
                let copiedURL = try ptCopyVideoToTemporaryURL(url)
                PTMainActorBridge.perform {
                    deliver(.success(.video(fileURL: copiedURL, assetIdentifier: assetIdentifier)))
                }
            } catch let error as PTSystemMediaPickerError {
                PTMainActorBridge.perform {
                    deliver(.failure(error))
                }
            } catch {
                let message = String(describing: error)
                PTMainActorBridge.perform {
                    deliver(.failure(.temporaryFileCopyFailed(message)))
                }
            }
        }
    }

    private func topPresenter(from presenter: UIViewController) -> UIViewController {
        var current = presenter
        while let presented = current.presentedViewController,
              !presented.isBeingDismissed {
            current = presented
        }
        return current
    }

    private func finish(_ result: Result<PTSystemMediaPickerResult, PTSystemMediaPickerError>) {
        guard !didFinish else { return }
        didFinish = true

        let controller = presentedController
        let complete = { [weak self] in
            guard let self else { return }
            if let controller {
                objc_setAssociatedObject(
                    controller,
                    &PTSystemMediaPickerAssociation.key,
                    nil,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
            self.presentedController = nil
            self.presenter = nil

            switch result {
            case .success(let value):
                self.continuation.resume(returning: value)
            case .failure(let error):
                self.continuation.resume(throwing: error)
            }
        }

        if controller?.presentingViewController != nil {
            controller?.dismiss(animated: true, completion: complete)
        } else {
            complete()
        }
    }
}

@MainActor
private enum PTSystemMediaPickerAssociation {
    static var key: UInt8 = 0
}

// English: Copy provider-owned video files before the provider callback returns.
// Español: Copia los vídeos propiedad del proveedor antes de que termine su callback.
// 中文：在 provider 回调结束前复制视频文件，避免继续使用失效的临时 URL。
private func ptCopyVideoToTemporaryURL(_ sourceURL: URL) throws -> URL {
    let fileExtension = UTType(filenameExtension: sourceURL.pathExtension)?.preferredFilenameExtension ?? "mov"
    let destinationURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("PToolsImagePicker-\(UUID().uuidString)")
        .appendingPathExtension(fileExtension)

    do {
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    } catch {
        throw PTSystemMediaPickerError.temporaryFileCopyFailed(String(describing: error))
    }
}

public enum PTImagePicker {
    
    public enum PickerType: Sendable {
        ///圖片
        case Photo
        ///視頻
        case Video
        ///選擇全部
        case All
        
        public var types:[String]{
            switch self{
            case .Photo:
                return [UTType.image.identifier,UTType.livePhoto.identifier]
            case .Video:
                return [UTType.movie.identifier,UTType.video.identifier]
            case .All:
                return [UTType.image.identifier,UTType.livePhoto.identifier,UTType.movie.identifier,UTType.video.identifier]
            }
        }
    }
    
    //MARK: Error
    public enum PickerError:Error{
        ///沒有Controller
        case NullParentViewController
        ///找不到對象
        case ObjFetchFaild
        ///對象轉換失敗
        case ObjConvertFaild(_ error:Error?)
        ///其他錯誤
        case Other(_ error:Error?)
        ///取消
        case UserCancel
        
        public func outPutLog(){
            switch self {
            case .NullParentViewController:
                PTNSLogConsole("沒有Controller",levelType: .error,loggerType: .media)
            case .ObjFetchFaild:
                PTNSLogConsole("找不到對象",levelType: .error,loggerType: .media)
            case let .ObjConvertFaild(error):
                PTNSLogConsole("對象轉換失敗:\(String(describing: error))",levelType: .error,loggerType: .media)
            case let .Other(error):
                PTNSLogConsole("其他錯誤:\(String(describing: error))",levelType: .error,loggerType: .media)
            case .UserCancel:
                PTNSLogConsole("用戶取消了",levelType: .error,loggerType: .media)
            }
        }
    }
    
    //MARK: PickerCompletion
    public typealias Completion<T: PTImagePickerObject> = @MainActor @Sendable (_ result: Result<T, PTImagePicker.PickerError>) -> Void
}

//MARK: 控制器
extension PTImagePicker {
    @MainActor
    // English: Legacy generic controller kept for source compatibility until 6.0.0.
    // Español: Controlador genérico heredado conservado por compatibilidad de código hasta 6.0.0.
    // 中文：保留旧泛型控制器以兼容现有代码，计划至少保留到 6.0.0。
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker；泛型 Controller 将在 6.0.0 后移除")
    public class Controller<T:PTImagePickerObject>:UIImagePickerController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
        //MARK: Block
        private var completion:PTImagePicker.Completion<T>? = nil
        
        deinit {
            PTNSLogConsole("PTImagePicker.controller deinit",levelType: PTLogMode,loggerType: .viewCycle)
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let result:Result<T,PTImagePicker.PickerError>
            do {
                result = .success(try T.fetchFromPicker(info))
            } catch let pickerError as PTImagePicker.PickerError{
                result = .failure(pickerError)
            } catch {
                result = .failure(.Other(error))
            }
            
            finish(result)
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            finish(.failure(.UserCancel))
        }

        private func finish(_ result: Result<T, PTImagePicker.PickerError>) {
            let completion = self.completion
            self.completion = nil

            guard presentingViewController != nil else {
                completion?(result)
                return
            }

            dismiss(animated: true) {
                completion?(result)
            }
        }
    }
}

private struct SendableBox<T>: @unchecked Sendable {
    let value: T
}

// MARK: - 控制器囘調
@available(*, deprecated, message: "请使用 PTSystemMediaPicker；旧泛型 Controller 将在 6.0.0 后移除")
private extension PTImagePicker.Controller {
    
    @MainActor
    func pickObject(completion: @escaping PTImagePicker.Completion<T>) {
        self.completion = completion
    }
    
    // 🚀 终极修复 2：改造 async 桥接方法，使用 Box 进行装箱和拆箱
    @MainActor
    func pickObject() async throws -> T {
        // 让 continuation 传递我们的安全盒子 (SendableBox)
        let box = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SendableBox<T>, Error>) in
            
            self.pickObject { result in
                switch result {
                case .success(let obj):
                    // 成功时：把非 Sendable 的 T (如 UIImage) 装进盒子里传递
                    continuation.resume(returning: SendableBox(value: obj))
                case .failure(let error):
                    // 失败时：错误类型通常天然是 Sendable 的，直接抛出
                    continuation.resume(throwing: error)
                }
            }
        }
        // 拆开盒子，返回真实的图片或数据对象
        return box.value
    }
}

// MARK: - 打開相冊
@available(*, deprecated, message: "请使用 PTSystemMediaPicker；旧泛型 Controller 将在 6.0.0 后移除")
private extension PTImagePicker.Controller {
    @MainActor
    static func showAlbumPicker<U>(mediaType: PTImagePicker.PickerType) throws -> PTImagePicker.Controller<U> {
        guard let parentVC = PTSceneContext.currentViewController() else {
            throw PTImagePicker.PickerError.NullParentViewController
        }
        let picker = PTImagePicker.Controller<U>()
        picker.modalPresentationStyle = .overFullScreen
        picker.mediaTypes = mediaType.types
        picker.videoQuality = .typeHigh
        picker.delegate = picker
        parentVC.present(picker, animated: true)
        return picker
    }
    
    @MainActor
    static func showPhotographPicker() throws -> PTImagePicker.Controller<UIImage> {
        guard let parentVC = PTSceneContext.currentViewController() else {
            throw PTImagePicker.PickerError.NullParentViewController
        }
        let picker = PTImagePicker.Controller<UIImage>()
        picker.modalPresentationStyle = .overFullScreen
        picker.sourceType = .camera
        picker.delegate = picker
        parentVC.present(picker, animated: true)
        return picker
    }
}

//MARK: 打開相冊
@available(*, deprecated, message: "请使用 PTSystemMediaPicker；旧泛型 Controller 将在 6.0.0 后移除")
extension PTImagePicker.Controller {
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(_:from:)，泛型兼容入口将在 6.0.0 后移除")
    @MainActor public static func openAlbum<U:PTImagePickerObject>(_ mediaType:PTImagePicker.PickerType) async throws -> U {
        let picker:PTImagePicker.Controller<U> = try showAlbumPicker(mediaType: mediaType)
        return try await picker.pickObject()
    }
    
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(_:from:)，泛型兼容入口将在 6.0.0 后移除")
    @MainActor public static func openAlbum<F: PTImagePickerObject>(_ mediaType: PTImagePicker.PickerType, completion: @escaping PTImagePicker.Completion<F>) {
        do {
            let picker: PTImagePicker.Controller<F> = try showAlbumPicker(mediaType: mediaType)
            picker.pickObject(completion: completion)
        } catch let pickerError as PTImagePicker.PickerError {
            completion(.failure(pickerError))
        } catch {
            completion(.failure(.Other(error)))
        }
    }
}

// MARK: 圖片
@available(*, deprecated, message: "请使用 PTSystemMediaPicker；旧泛型 Controller 将在 6.0.0 后移除")
extension PTImagePicker.Controller {
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.capture(_:from:)，兼容入口将在 6.0.0 后移除")
    @MainActor public static func photograph() async throws -> UIImage {
        let picker = try showPhotographPicker()
        return try await picker.pickObject()
    }
    
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.capture(_:from:)，兼容入口将在 6.0.0 后移除")
    @MainActor public static func photograph(completion: @escaping PTImagePicker.Completion<UIImage>) {
        do {
            let picker = try showPhotographPicker()
            picker.pickObject(completion: completion)
        } catch let pickerError as PTImagePicker.PickerError {
            completion(.failure(pickerError))
        } catch {
            completion(.failure(.Other(error)))
        }
    }
}

//MARK: 打開方式
extension PTImagePicker{
    private static func legacyError(from error: Error) -> PickerError {
        guard let pickerError = error as? PTSystemMediaPickerError else {
            return .Other(error)
        }

        switch pickerError {
        case .presentationUnavailable:
            return .NullParentViewController
        case .cancelled:
            return .UserCancel
        case .unsupportedResult:
            return .ObjFetchFaild
        case .cameraUnavailable, .permissionDenied, .invalidConfiguration, .loadFailed, .temporaryFileCopyFailed:
            return .Other(pickerError)
        }
    }

    private static func image(from result: PTSystemMediaPickerResult) throws -> UIImage {
        guard let data = result.imageData, let image = UIImage(data: data) else {
            throw PickerError.ObjConvertFaild(nil)
        }
        return image
    }

    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.image, from:)")
    /// Open album -> 圖片
    public static func openAlbum() async throws -> UIImage {
        do {
            return try image(from: await PTSystemMediaPicker.pick(.image))
        } catch let error as PickerError {
            throw error
        } catch {
            throw legacyError(from: error)
        }
    }
    
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.image, from:)")
    /// Open album -> 圖片/GIF數據
    public static func openAlbum() async throws -> Data {
        do {
            guard let data = try await PTSystemMediaPicker.pick(.image).imageData else {
                throw PickerError.ObjFetchFaild
            }
            return data
        } catch let error as PickerError {
            throw error
        } catch {
            throw legacyError(from: error)
        }
    }
    
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.video, from:)")
    /// Open album -> 視頻路徑
    public static func openAlbum() async throws -> URL {
        do {
            guard let url = try await PTSystemMediaPicker.pick(.video).videoURL else {
                throw PickerError.ObjFetchFaild
            }
            return url
        } catch let error as PickerError {
            throw error
        } catch {
            throw legacyError(from: error)
        }
    }
    
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.imageOrVideo, from:)")
    /// Open album -> 圖片/GIF數據 or 視頻路徑
    @MainActor public static func openAlbum() async throws -> PTAlbumObject {
        do {
            switch try await PTSystemMediaPicker.pick(.imageOrVideo) {
            case .image(let data, _):
                return PTAlbumObject(imageData: data, videoURL: nil)
            case .video(let url, _):
                return PTAlbumObject(imageData: nil, videoURL: url)
            }
        } catch let error as PickerError {
            throw error
        } catch {
            throw legacyError(from: error)
        }
    }
    
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.capture(.image, from:)")
    /// Photograph -> 相机
    public static func photograph() async throws -> UIImage {
        do {
            return try image(from: await PTSystemMediaPicker.capture(.image))
        } catch let error as PickerError {
            throw error
        } catch {
            throw legacyError(from: error)
        }
    }
    
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.image, from:)")
    /// 圖片 圖片URL
    @MainActor public static func openAlbum() async throws -> PTPhotoObject {
        do {
            let result = try await PTSystemMediaPicker.pick(.image)
            guard let data = result.imageData, let image = UIImage(data: data) else {
                throw PickerError.ObjConvertFaild(nil)
            }
            return PTPhotoObject(image: image, url: nil)
        } catch let error as PickerError {
            throw error
        } catch {
            throw legacyError(from: error)
        }
    }
}

// MARK: 閉包方式
extension PTImagePicker {
    /// Open album -> 圖片
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.image, from:)")
    @MainActor public static func openAlbumForImage(completion: @escaping PTImagePicker.Completion<UIImage>) {
        Task { @MainActor in
            do {
                let image = try image(from: await PTSystemMediaPicker.pick(.image))
                completion(.success(image))
            } catch let error as PickerError {
                completion(.failure(error))
            } catch {
                completion(.failure(legacyError(from: error)))
            }
        }
    }
    
    /// Open album -> 圖片/GIF數據
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.image, from:)")
    @MainActor public static func openAlbumForImageData(completion: @escaping PTImagePicker.Completion<Data>) {
        Task { @MainActor in
            do {
                guard let data = try await PTSystemMediaPicker.pick(.image).imageData else {
                    throw PickerError.ObjFetchFaild
                }
                completion(.success(data))
            } catch let error as PickerError {
                completion(.failure(error))
            } catch {
                completion(.failure(legacyError(from: error)))
            }
        }
    }
    
    /// Open album -> 視頻路徑
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.video, from:)")
    @MainActor public static func openAlbumForVideoURL(completion: @escaping PTImagePicker.Completion<URL>) {
        Task { @MainActor in
            do {
                guard let url = try await PTSystemMediaPicker.pick(.video).videoURL else {
                    throw PickerError.ObjFetchFaild
                }
                completion(.success(url))
            } catch let error as PickerError {
                completion(.failure(error))
            } catch {
                completion(.failure(legacyError(from: error)))
            }
        }
    }
    
    /// Open album -> 圖片/GIF數據 or 視頻路徑
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.imageOrVideo, from:)")
    @MainActor public static func openAlbumForObject(completion: @escaping PTImagePicker.Completion<PTAlbumObject>) {
        Task { @MainActor in
            do {
                let object: PTAlbumObject
                switch try await PTSystemMediaPicker.pick(.imageOrVideo) {
                case .image(let data, _):
                    object = PTAlbumObject(imageData: data, videoURL: nil)
                case .video(let url, _):
                    object = PTAlbumObject(imageData: nil, videoURL: url)
                }
                completion(.success(object))
            } catch let error as PickerError {
                completion(.failure(error))
            } catch {
                completion(.failure(legacyError(from: error)))
            }
        }
    }
    
    /// Photograph -> 圖片
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.capture(.image, from:)")
    @MainActor public static func photograph(completion: @escaping PTImagePicker.Completion<UIImage>) {
        Task { @MainActor in
            do {
                let image = try image(from: await PTSystemMediaPicker.capture(.image))
                completion(.success(image))
            } catch let error as PickerError {
                completion(.failure(error))
            } catch {
                completion(.failure(legacyError(from: error)))
            }
        }
    }
    
    /// Open album -> 圖片/URL
    @available(*, deprecated, message: "请使用 PTSystemMediaPicker.pick(.image, from:)")
    @MainActor public static func openAlbumForImageObject(completion: @escaping PTImagePicker.Completion<PTPhotoObject>) {
        Task { @MainActor in
            do {
                let result = try await PTSystemMediaPicker.pick(.image)
                guard let data = result.imageData, let image = UIImage(data: data) else {
                    throw PickerError.ObjConvertFaild(nil)
                }
                let object = PTPhotoObject(image: image, url: nil)
                completion(.success(object))
            } catch let error as PickerError {
                completion(.failure(error))
            } catch {
                completion(.failure(legacyError(from: error)))
            }
        }
    }
}
