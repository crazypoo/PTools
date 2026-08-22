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

        let authorization = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard authorization != .denied, authorization != .restricted else {
            completion(.failure(.permissionDenied))
            return
        }

        guard let changeRequest = prepareChangeRequest(image: image, videoURL: videoURL) else {
            completion(.failure(image != nil ? .imageEncodingFailed : .saveFailed("视频资源不可用")))
            return
        }

        let identifierStorage = OSAllocatedUnfairLock<String?>(initialState: nil)
        let changeBlock = makeChangeBlock(changeRequest: changeRequest,
                                          identifierStorage: identifierStorage)
        let completionBlock = makeCompletionBlock(identifierStorage: identifierStorage,
                                                  completion: completion)
        PHPhotoLibrary.shared().performChanges(changeBlock,
                                                completionHandler: completionBlock)
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
        Task { @MainActor in
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

    private static func prepareChangeRequest(image: UIImage?, videoURL: URL?) -> ChangeRequest? {
        if let image {
            let data = image.pt.hasAlphaChannel()
                ? image.pngData()
                : image.jpegData(compressionQuality: 1)
            guard let data else { return nil }
            return .image(data)
        }
        guard let videoURL, FileManager.default.fileExists(atPath: videoURL.path) else { return nil }
        return .video(videoURL)
    }
}
