//
//  PTMediaSaveService.swift
//  PooTools
//
//  Shared PhotoKit media saving boundary used by PhotoPicker, MediaViewer and
//  VideoEditor targets.
//

@preconcurrency import Photos
import UIKit
import os.lock
import ImageIO
import UniformTypeIdentifiers

// English: Preserve the captured UIImage orientation when ImageIO writes the detached image data.
// Español: Conserva la orientación capturada de UIImage cuando ImageIO escribe los datos separados.
// 中文：使用 ImageIO 写入后台图片数据时保留 UIImage 捕获时的方向。
private extension UIImage.Orientation {
    var ptImageIOOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

public enum PTMediaSaveError: Error, LocalizedError, Sendable {
    case invalidInput
    case permissionDenied
    case imageEncodingFailed
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput: return "必须提供一张图片或一个视频文件"
        case .permissionDenied: return "没有相册写入权限"
        case .imageEncodingFailed: return "图片编码失败"
        case .saveFailed(let message): return message
        }
    }
}

@MainActor
public enum PTMediaSaveResult {
    case success(PHAsset)
    case failure(PTMediaSaveError)
}

@MainActor
public enum PTMediaSaveService {
    public static func save(image: UIImage?,
                            completion: @escaping @MainActor @Sendable (PTMediaSaveResult) -> Void) {
        save(image: image, videoURL: nil, completion: completion)
    }

    public static func save(videoURL: URL,
                            completion: @escaping @MainActor @Sendable (PTMediaSaveResult) -> Void) {
        save(image: nil, videoURL: videoURL, completion: completion)
    }

    public static func save(image: UIImage? = nil,
                            videoURL: URL? = nil,
                            completion: @escaping @MainActor @Sendable (PTMediaSaveResult) -> Void) {
        let hasImage = image != nil
        let hasVideo = videoURL != nil
        guard hasImage != hasVideo else {
            completion(.failure(.invalidInput))
            return
        }

        if let image {
            // English: Snapshot immutable image metadata before moving only the encoder off MainActor.
            // Español: Captura metadata inmutable antes de mover solo el codificador fuera de MainActor.
            // 中文：先在 MainActor 快照不可变图片元数据，只把编码工作移出 MainActor。
            Task { @MainActor in
                guard let data = await encodeImageData(image) else {
                    completion(.failure(.imageEncodingFailed))
                    return
                }
                requestAuthorizationAndSave(changeRequest: .image(data), completion: completion)
            }
            return
        }

        guard let videoURL, FileManager.default.fileExists(atPath: videoURL.path) else {
            completion(.failure(.saveFailed("视频资源不可用")))
            return
        }
        requestAuthorizationAndSave(changeRequest: .video(videoURL), completion: completion)
    }

    // English: Encode a captured CGImage away from MainActor; UIImage itself never crosses the boundary.
    // Español: Codifica el CGImage capturado fuera de MainActor; UIImage nunca cruza el límite.
    // 中文：在 MainActor 之外编码已捕获的 CGImage，UIImage 本身不跨并发边界。
    public static func encodeImageData(_ image: UIImage) async -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        let hasAlpha: Bool
        switch cgImage.alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast:
            hasAlpha = true
        default:
            hasAlpha = false
        }
        let input = PTImageEncodingInput(cgImage: PTSystemCGImageBox(cgImage),
                                         orientation: image.imageOrientation.ptImageIOOrientation,
                                         hasAlpha: hasAlpha)
        return await Task.detached(priority: .userInitiated) {
            encode(input)
        }.value
    }

    // Ask for permission before starting the Photos transaction, and finish on MainActor exactly once.
    // Solicita permiso antes de iniciar la transacción de Photos y finaliza exactamente una vez en MainActor.
    // 在开始 Photos 事务前先请求权限，并保证只在 MainActor 上完成一次回调。
    private nonisolated static func requestAuthorizationAndSave(
        changeRequest: ChangeRequest,
        completion: @escaping @MainActor @Sendable (PTMediaSaveResult) -> Void
    ) {
        let authorization = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch authorization {
        case .authorized, .limited:
            performSave(changeRequest: changeRequest, completion: completion)
        case .notDetermined:
            // English: Start the Photos authorization bridge on MainActor; Photos may invoke its legacy callback elsewhere.
            // Español: Inicia el puente de autorización de Photos en MainActor; Photos puede ejecutar el callback antiguo en otra cola.
            // 中文：在 MainActor 启动 Photos 授权桥接，避免 Photos 的旧式回调队列不确定。
            Task { @MainActor in
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    completePermissionDenied(completion)
                    return
                }
                performSave(changeRequest: changeRequest, completion: completion)
            }
        case .denied, .restricted:
            completePermissionDenied(completion)
        @unknown default:
            completePermissionDenied(completion)
        }
    }

    private nonisolated static func performSave(
        changeRequest: ChangeRequest,
        completion: @escaping @MainActor @Sendable (PTMediaSaveResult) -> Void
    ) {
        let identifierStorage = OSAllocatedUnfairLock<String?>(initialState: nil)
        let changeBlock = makeChangeBlock(changeRequest: changeRequest,
                                          identifierStorage: identifierStorage)
        let completionBlock = makeCompletionBlock(identifierStorage: identifierStorage,
                                                  completion: completion)
        PHPhotoLibrary.shared().performChanges(changeBlock,
                                                completionHandler: completionBlock)
    }

    private nonisolated static func completePermissionDenied(
        _ completion: @escaping @MainActor @Sendable (PTMediaSaveResult) -> Void
    ) {
        PTMainActorBridge.perform {
            completion(.failure(.permissionDenied))
        }
    }

    /// 在非隔离上下文创建 Photos 事务闭包，避免闭包继承 MainActor。
    private nonisolated static func makeChangeBlock(changeRequest: ChangeRequest,
                                                    identifierStorage: OSAllocatedUnfairLock<String?>) -> @Sendable () -> Void {
        {
            changeRequest.request(identifierStorage: identifierStorage)
        }
    }

    /// 在非隔离上下文创建 Photos 完成闭包，完成后再切回 MainActor。
    private nonisolated static func makeCompletionBlock(identifierStorage: OSAllocatedUnfairLock<String?>,
                                                        completion: @escaping @MainActor @Sendable (PTMediaSaveResult) -> Void) -> @Sendable (Bool, Error?) -> Void {
        { success, error in
            let failureMessage = error?.localizedDescription ?? "保存媒体失败"
            let localIdentifier = identifierStorage.withLock { $0 }
            finishSave(success: success,
                       failureMessage: failureMessage,
                       localIdentifier: localIdentifier,
                       completion: completion)
        }
    }

    /// Photos 可能在自己的队列执行完成回调，这里不能直接触发主 actor 闭包。
    private nonisolated static func finishSave(success: Bool,
                                               failureMessage: String,
                                               localIdentifier: String?,
                                               completion: @escaping @MainActor @Sendable (PTMediaSaveResult) -> Void) {
        PTMainActorBridge.perform {
            guard success else {
                completion(.failure(.saveFailed(failureMessage)))
                return
            }
            guard let localIdentifier else {
                completion(.failure(.saveFailed("保存成功但无法获取资源标识")))
                return
            }
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            guard let asset = assets.firstObject else {
                completion(.failure(.saveFailed("保存成功但无法读取资源")))
                return
            }
            completion(.success(asset))
        }
    }

    private enum ChangeRequest: Sendable {
        case image(Data)
        case video(URL)

        func request(identifierStorage: OSAllocatedUnfairLock<String?>) {
            switch self {
            case .image(let data):
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
                identifierStorage.withLock { $0 = request.placeholderForCreatedAsset?.localIdentifier }
            case .video(let url):
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                identifierStorage.withLock { $0 = request?.placeholderForCreatedAsset?.localIdentifier }
            }
        }
    }

    private struct PTSystemCGImageBox: @unchecked Sendable {
        // English: CGImage is an immutable Core Graphics snapshot and is only read by ImageIO below.
        // Español: CGImage es una instantánea inmutable de Core Graphics y ImageIO solo la lee abajo.
        // 中文：CGImage 是不可变的 Core Graphics 快照，下面只由 ImageIO 读取。
        let value: CGImage

        init(_ value: CGImage) {
            self.value = value
        }
    }

    private struct PTImageEncodingInput: Sendable {
        let cgImage: PTSystemCGImageBox
        let orientation: CGImagePropertyOrientation
        let hasAlpha: Bool
    }

    private nonisolated static func encode(_ input: PTImageEncodingInput) -> Data? {
        let data = NSMutableData()
        let type: CFString = input.hasAlpha ? UTType.png.identifier as CFString : UTType.jpeg.identifier as CFString
        guard let destination = CGImageDestinationCreateWithData(data, type, 1, nil) else { return nil }
        let properties: [CFString: Any] = [kCGImagePropertyOrientation: input.orientation.rawValue]
        CGImageDestinationAddImage(destination, input.cgImage.value, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data.copy() as? Data
    }
}
