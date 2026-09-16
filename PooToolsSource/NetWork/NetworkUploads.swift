// English: Keep multipart preparation and upload lifecycle separate from request parsing.
// Español: Mantiene la preparación multipart y el ciclo de carga separados del análisis de solicitudes.
// 中文：将 multipart 准备和上传生命周期从请求解析中独立出来。

import UIKit
@preconcurrency import Alamofire
import Photos
import SwifterSwift

extension Network {
    // English: Convert legacy dynamic upload inputs into immutable Sendable snapshots before starting asynchronous work.
    // Español: Convierte las entradas dinámicas heredadas en instantáneas Sendable inmutables antes del trabajo asíncrono.
    // 中文：在启动异步工作前，将旧版动态上传参数转换为不可变的 Sendable 快照。
    private enum PTUploadMediaInput: Sendable {
        case photoAsset(identifier: String)
        case data(Data, mimeType: String, fileName: String)
        case fileURL(URL)
    }

    private struct PTUploadRequestInput: Sendable {
        let media: PTUploadMediaInput
        let path: String
    }

    private static func makeUploadRequestInput(media: Any,
                                               path: URLConvertible) throws -> PTUploadRequestInput {
        let pathString = try path.asURL().absoluteString

        if let asset = media as? PHAsset {
            guard !asset.localIdentifier.isEmpty else {
                throw PTNetworkError.uploadDataError("Photo asset identifier is empty")
            }
            return PTUploadRequestInput(media: .photoAsset(identifier: asset.localIdentifier),
                                        path: pathString)
        }

        if let image = media as? UIImage {
            if let data = image.pngData() {
                return PTUploadRequestInput(media: .data(data,
                                                         mimeType: "image/png",
                                                         fileName: "image_\(Int(Date().timeIntervalSince1970)).png"),
                                            path: pathString)
            }
            guard let data = image.jpegData(compressionQuality: 0.6) else {
                throw PTNetworkError.uploadDataError("Image data error")
            }
            return PTUploadRequestInput(media: .data(data,
                                                     mimeType: "image/jpeg",
                                                     fileName: "image_\(Int(Date().timeIntervalSince1970)).jpg"),
                                        path: pathString)
        }

        if let url = media as? URL {
            return PTUploadRequestInput(media: .fileURL(url), path: pathString)
        }

        if let string = media as? String, let url = URL(string: string) {
            return PTUploadRequestInput(media: .fileURL(url), path: pathString)
        }

        throw PTNetworkError.uploadDataError("Unsupported media type")
    }

    private static func failedUploadStream(_ error: Error) -> AsyncThrowingStream<PTNetworkUploadEvent, Error> {
        return AsyncThrowingStream<PTNetworkUploadEvent, Error> { continuation in
            continuation.finish(throwing: error)
        }
    }

    class func _internalFileUpload(needGobal: Bool,
                                            media: Any,
                                            path: URLConvertible,
                                            method: HTTPMethod,
                                            fileKey: String,
                                            params: [String: String]?,
                                            header: HTTPHeaders?,
                                            jsonRequest: Bool
    ) -> AsyncThrowingStream<PTNetworkUploadEvent, Error> {
        let input: PTUploadRequestInput
        do {
            input = try makeUploadRequestInput(media: media, path: path)
        } catch {
            return failedUploadStream(error)
        }
        
        return AsyncThrowingStream { continuation in
            let cancellation = PTNetworkUploadCancellation()
            let preparationTask = Task {
                do {
                    // 1️⃣ 数据准备阶段
                    let preparedMedia = try await prepareMediaResource(media: input.media)
                    let pathUrl = try await createURLRequest(urlStr: input.path, needGobal: needGobal)
                    let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
                    
                    // 2️⃣ 手动构建 MultipartFormData 对象，取代闭包构建法！
                    // 这将消除闭包内捕获局部变量带来的并发安全隐患
                    let multipartData = MultipartFormData()
                    
                    // 填充主文件
                    switch preparedMedia {
                    case .data(let data, let mimeType, let fileName):
                        multipartData.append(data, withName: fileKey, fileName: fileName, mimeType: mimeType)
                    case .fileURL(let url, let mimeType, let fileName):
                        multipartData.append(url, withName: fileKey, fileName: fileName, mimeType: mimeType)
                    }
                    
                    // 填充附加参数
                    params?.forEach { key, value in
                        if let data = value.data(using: .utf8) {
                            multipartData.append(data, withName: key)
                        }
                    }
                    
                    let session = Network.share.session
                    
                    // 3️⃣ 发起请求，并将进度和响应转换为值类型快照。
                    guard !Task.isCancelled else {
                        continuation.finish(throwing: CancellationError())
                        return
                    }

                    let uploadRequest = session.upload(multipartFormData: multipartData, to: pathUrl, method: method, headers: apiHeader)
                        .uploadProgress { @Sendable progress in
                            let snapshot = PTProgressSnapshot(completedUnitCount: progress.completedUnitCount,
                                                               totalUnitCount: progress.totalUnitCount,
                                                               fractionCompleted: progress.fractionCompleted)
                            continuation.yield(PTNetworkUploadEvent(progress: snapshot, response: nil))
                        }
                        .response { @Sendable resp in
                            switch resp.result {
                            case .success(_):
                                let response = responseSnapshot(url: pathUrl,
                                                                 response: resp.response,
                                                                 data: resp.data)
                                let progress = PTProgressSnapshot(completedUnitCount: 1,
                                                                   totalUnitCount: 1,
                                                                   fractionCompleted: 1)
                                continuation.yield(PTNetworkUploadEvent(progress: progress, response: response))
                                continuation.finish()
                            case .failure(let error):
                                logRequestFailure(url: pathUrl, error: error)
                                continuation.finish(throwing: error)
                            }
                        }
                    cancellation.install(request: uploadRequest)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            cancellation.install(preparationTask: preparationTask)
            continuation.onTermination = { @Sendable _ in
                cancellation.cancel()
            }
        }
    }
    
    // 🌟 步骤 3：将媒体处理逻辑提取为一个独立的 async 方法
    private class func prepareMediaResource(media: PTUploadMediaInput) async throws -> PreparedUploadMedia {
        if case .photoAsset(let identifier) = media {
            guard let phasset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
                throw PTNetworkError.uploadDataError("Photo asset is unavailable")
            }
            switch phasset.mediaType {
            case .image:
                let image = await phasset.asyncImage()
                guard let findImage = image else { throw PTNetworkError.uploadDataError("Image data error") }
                let canPNG = findImage.pngData() != nil
                guard let imageData = findImage.pngData() ?? findImage.jpegData(compressionQuality: 0.6) else {
                    throw PTNetworkError.uploadDataError("Image data error")
                }
                let ext = canPNG ? "png" : "jpg"
                let fileName = "image_\(Int(Date().timeIntervalSince1970)).\(ext)"
                return .data(imageData, mimeType: MimeTypeHelper.mimeType(for: ext), fileName: fileName)
                
            case .video, .audio:
                // 使用 withCheckedThrowingContinuation 将基于闭包的回调转换为 Swift 的 async/await
                let urlAsset: AVURLAsset = try await withCheckedThrowingContinuation { cont in
                    phasset.converPHAssetToAVURLAsset { asset in
                        if let asset = asset {
                            cont.resume(returning: asset)
                        } else {
                            cont.resume(throwing: PTNetworkError.uploadDataError("Video/Audio data error"))
                        }
                    }
                }
                
                let url = urlAsset.url
                let ext = url.pathExtension.lowercased()
                let prefix = phasset.mediaType == .video ? "video" : "audio"
                let fileName = "\(prefix)_\(Int(Date().timeIntervalSince1970)).\(ext)"
                return .fileURL(url, mimeType: MimeTypeHelper.mimeType(for: ext), fileName: fileName)
                
            default:
                throw PTNetworkError.uploadDataError("Unknown data error")
            }
            
        } else {
            switch media {
            case .data(let data, let mimeType, let fileName):
                return .data(data, mimeType: mimeType, fileName: fileName)
            case .photoAsset:
                throw PTNetworkError.uploadDataError("Photo asset is unavailable")
            case .fileURL(let url):
                return try processUploadFileURL(url)
            }
        }
    }
    
    // 🌟 步骤 4：独立处理 FileProvider 沙盒文件的拷贝逻辑
    private class func processUploadFileURL(_ findUrl: URL) throws -> PreparedUploadMedia {
        guard findUrl.isFileURL else {
            throw PTNetworkError.uploadDataError("Need to download first")
        }
        
        let uploadURL: URL
        if findUrl.path.contains("File Provider Storage") || findUrl.path.contains("com.apple.FileProvider") {
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(findUrl.lastPathComponent)
            try? FileManager.default.removeItem(at: tmpURL)
            try? FileManager.default.copyItem(at: findUrl, to: tmpURL)
            uploadURL = tmpURL
        } else {
            uploadURL = findUrl
        }
        
        let ext = uploadURL.pathExtension.lowercased()
        let fileName = uploadURL.lastPathComponent
        return .fileURL(uploadURL, mimeType: MimeTypeHelper.mimeType(for: ext), fileName: fileName)
    }
    
    /// 核心：通用多图并发上传引擎 (TaskGroup 高性能版)
    class func _internalImageUpload(
        needGobal: Bool, images: [UIImage]?, path: URLConvertible, method: HTTPMethod, fileKey: [String], params: [String: String]?,
        header: HTTPHeaders?, jsonRequest: Bool, pngData: Bool
    ) -> AsyncThrowingStream<PTNetworkUploadEvent, Error> {
        let pathString: String
        do {
            pathString = try path.asURL().absoluteString
        } catch {
            return failedUploadStream(error)
        }

        let imageResults: [PreparedImageResult] = (images ?? []).enumerated().compactMap { index, image in
            autoreleasepool {
                let data = pngData ? image.pngData() : image.jpegData(compressionQuality: 0.6)
                guard let imageData = data else { return nil }
                let key = fileKey[safe: index] ?? "image"
                let ext = pngData ? "png" : "jpg"
                return PreparedImageResult(key: key,
                                           fileName: "image_\(index).\(ext)",
                                           mimeType: pngData ? "image/png" : "image/jpeg",
                                           data: imageData)
            }
        }

        return AsyncThrowingStream<PTNetworkUploadEvent, Error> { continuation in
            let cancellation = PTNetworkUploadCancellation()
            let preparationTask = Task {
                do {
                    let pathUrl = try await createURLRequest(urlStr: pathString, needGobal: needGobal)
                    let apiHeader = prepareRequestHeaders(header: header, jsonRequest: jsonRequest)
                    
                    // English: Image data is already a Sendable snapshot; UIKit objects never cross this task boundary.
                    // Español: Los datos de imagen ya son una instantánea Sendable; los objetos UIKit no cruzan este límite.
                    // 中文：图片数据已经是 Sendable 快照，UIKit 对象不会跨越这个任务边界。
                    let session = Network.share.session
                    guard !Task.isCancelled else {
                        continuation.finish(throwing: CancellationError())
                        return
                    }

                    let uploadRequest = session.upload(multipartFormData: { multipartFormData in
                        
                        // 1. 追加已处理好的图片数据
                        for img in imageResults {
                            multipartFormData.append(img.data, withName: img.key, fileName: img.fileName, mimeType: img.mimeType)
                        }
                        
                        // 2. 追加普通文本参数
                        params?.forEach { key, value in
                            if let data = value.data(using: .utf8) {
                                multipartFormData.append(data, withName: key)
                            }
                        }
                        
                    }, to: pathUrl, method: method, headers: apiHeader)
                    .uploadProgress { @Sendable progress in
                        let snapshot = PTProgressSnapshot(completedUnitCount: progress.completedUnitCount,
                                                           totalUnitCount: progress.totalUnitCount,
                                                           fractionCompleted: progress.fractionCompleted)
                        continuation.yield(PTNetworkUploadEvent(progress: snapshot, response: nil))
                    }
                    .response { resp in
                        switch resp.result {
                        case .success(_):
                            let response = responseSnapshot(url: pathUrl,
                                                             response: resp.response,
                                                             data: resp.data)
                            let progress = PTProgressSnapshot(completedUnitCount: 1,
                                                               totalUnitCount: 1,
                                                               fractionCompleted: 1)
                            continuation.yield(PTNetworkUploadEvent(progress: progress, response: response))
                            continuation.finish()
                        case .failure(let error):
                            logRequestFailure(url: pathUrl, error: error)
                            continuation.finish(throwing: error)
                        }
                    }
                    cancellation.install(request: uploadRequest)
                } catch { continuation.finish(throwing: error) }
            }
            cancellation.install(preparationTask: preparationTask)
            continuation.onTermination = { @Sendable _ in
                cancellation.cancel()
            }
        }
    }
}
