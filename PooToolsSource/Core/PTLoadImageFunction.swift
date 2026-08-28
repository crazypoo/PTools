//
//  PTLoadImageFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import Kingfisher
import SwifterSwift
@preconcurrency import Photos
import ImageIO
import os

public enum PTImageType : Sendable {
    case jpeg
    case png
    case gif
    case other
    case unknown
}

public typealias PTLoadImageProgressBlock = (@MainActor @Sendable (_ receivedSize: Int64, _ totalSize: Int64) -> Void)

@MainActor
public enum PTImageSource {
    case image(UIImage)
    case data(Data)
    case asset(PHAsset)
    case color(UIColor)
    case url(URL)
    case named(String)
    /// Generates the requested one-based frame from a video URL.
    /// Genera el fotograma solicitado, empezando en uno, desde una URL de vídeo.
    /// 从视频 URL 生成指定的帧，帧号从 1 开始。
    case videoURL(URL, frameNumber: Int = 10, maximumSize: CGSize? = PTVideoThumbnailService.defaultMaximumSize)
    /// Generates the requested one-based frame from an AVAsset.
    /// Genera el fotograma solicitado, empezando en uno, desde un AVAsset.
    /// 从 AVAsset 生成指定的帧，帧号从 1 开始。
    case avAsset(AVAsset, frameNumber: Int = 10, maximumSize: CGSize? = PTVideoThumbnailService.defaultMaximumSize)
}

/// Shared rendering options used by image views and the image-loading core.
/// Opciones compartidas de renderizado para vistas de imagen y el núcleo de carga.
/// 图片视图和图片加载核心共用的渲染配置。
public struct PTImageLoadConfiguration {
    public var iCloudDocumentName: String
    public var radius: CGFloat
    public var topLeft: CGFloat
    public var topRight: CGFloat
    public var bottomLeft: CGFloat
    public var bottomRight: CGFloat
    public var corner: UIRectCorner
    public var capsule: Bool
    public var borderWidth: CGFloat?
    public var borderColor: UIColor?
    public var showValueLabel: Bool?
    public var valueLabelFont: UIFont?
    public var valueLabelColor: UIColor?
    public var uniCount: Int?
    public var emptyImage: UIImage?

    public init(iCloudDocumentName: String = "",
                radius: CGFloat = 0,
                topLeft: CGFloat = 0,
                topRight: CGFloat = 0,
                bottomLeft: CGFloat = 0,
                bottomRight: CGFloat = 0,
                corner: UIRectCorner = .allCorners,
                capsule: Bool = false,
                borderWidth: CGFloat? = nil,
                borderColor: UIColor? = nil,
                showValueLabel: Bool? = nil,
                valueLabelFont: UIFont? = nil,
                valueLabelColor: UIColor? = nil,
                uniCount: Int? = nil,
                emptyImage: UIImage? = nil) {
        self.iCloudDocumentName = iCloudDocumentName
        self.radius = radius
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.corner = corner
        self.capsule = capsule
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.showValueLabel = showValueLabel
        self.valueLabelFont = valueLabelFont
        self.valueLabelColor = valueLabelColor
        self.uniCount = uniCount
        self.emptyImage = emptyImage
    }
}

@MainActor
public struct PTLoadImageResult {
    public let allImages: [UIImage]?
    public let firstImage: UIImage?
    public let loadTime: TimeInterval
    public let imageType: PTImageType

    public init(allImages: [UIImage]?, firstImage: UIImage?, loadTime: TimeInterval, imageType: PTImageType = .unknown) {
        self.allImages = allImages
        self.firstImage = firstImage
        self.loadTime = loadTime
        self.imageType = imageType
    }
}

private struct PTLoadImageRequestState: Sendable {
    var requestID: PHImageRequestID = PHInvalidImageRequestID
    var continuation: CheckedContinuation<PTLoadImageResult, Never>?
    var cancellationRequested = false
    var finished = false
}

@MainActor
@objcMembers
public class PTLoadImageFunction: NSObject {

    nonisolated private static func detectImageType(from data: Data) -> PTImageType {
        let imageType = data.detectImageType()
        switch imageType {
        case .GIF: return .gif
        case .PNG: return .png
        case .JPEG: return .jpeg
        default: return .other
        }
    }

    private static func imageResult(_ image: UIImage,
                                    imageType: PTImageType = .other) -> PTLoadImageResult {
        PTLoadImageResult(allImages: [image],
                          firstImage: image,
                          loadTime: 0,
                          imageType: imageType)
    }

    private static func emptyResult(imageType: PTImageType = .unknown) -> PTLoadImageResult {
        PTLoadImageResult(allImages: nil,
                          firstImage: nil,
                          loadTime: 0,
                          imageType: imageType)
    }

    @MainActor public static func loadImage(source: PTImageSource,
                                            iCloudDocumentName: String = "",
                                            progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {
        switch source {
        case .image(let image):
            return imageResult(image)
        case .data(let data):
            return await loadImageFromData(data)
        case .asset(let asset):
            return await handleAssetContent(asset: asset)
        case .color(let color):
            return imageResult(color.createImageWithColor())
        case .url(let url):
            return await handleURL(url, iCloudDocumentName, progressHandle)
        case .named(let name):
            return await handleStringContent(name, iCloudDocumentName, progressHandle)
        case .videoURL(let url, let frameNumber, let maximumSize):
            return await loadVideo(url: url,
                                   frameNumber: frameNumber,
                                   maximumSize: maximumSize)
        case .avAsset(let asset, let frameNumber, let maximumSize):
            return await loadVideo(asset: asset,
                                   frameNumber: frameNumber,
                                   maximumSize: maximumSize)
        }
    }

    /// Compatibility wrapper for dynamic callers; all supported values use the typed source pipeline.
    /// Adaptador de compatibilidad para llamadas dinámicas; todos los valores admitidos usan el canal tipado.
    /// 动态调用方的兼容包装器；所有支持的值统一进入类型化 source 管线。
    @MainActor public static func loadImage(contentData: Any,
                                            iCloudDocumentName: String = "",
                                            progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {
        let source: PTImageSource
        switch contentData {
        case let image as UIImage:
            source = .image(image)
        case let dataString as String:
            source = .named(dataString)
        case let data as Data:
            source = .data(data)
        case let asset as PHAsset:
            source = .asset(asset)
        case let asset as AVAsset:
            source = .avAsset(asset)
        case let color as UIColor:
            source = .color(color)
        case let url as URL:
            source = .url(url)
        default:
            return emptyResult()
        }
        return await loadImage(source: source,
                               iCloudDocumentName: iCloudDocumentName,
                               progressHandle: progressHandle)
    }

    public static func handleStringContent(_ dataUrlString: String,
                                           _ iCloudDocumentName: String,
                                           _ progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {

        if FileManager.pt.judgeFileOrFolderExists(filePath: dataUrlString) {
            return await loadLocal(url: URL(fileURLWithPath: dataUrlString),
                                   iCloudDocumentName: iCloudDocumentName)
        }

        if dataUrlString.isURL(), let url = URL(string: dataUrlString) {
            return await handleURL(url, iCloudDocumentName, progressHandle)
        }

        if dataUrlString.isSingleEmoji {
            let emojiImage = dataUrlString.emojiToImage()
            return imageResult(emojiImage)
        }

        if let image = UIImage(named: dataUrlString) ?? UIImage(systemName: dataUrlString) {
            return imageResult(image)
        }

        return emptyResult()
    }

    public static func handleAssetContent(asset: PHAsset) async -> PTLoadImageResult {
        guard !asset.localIdentifier.isEmpty else { return emptyResult() }

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        let requestState = OSAllocatedUnfairLock<PTLoadImageRequestState>(initialState: PTLoadImageRequestState())

        func finish(_ result: PTLoadImageResult) {
            let continuation = requestState.withLock { state -> CheckedContinuation<PTLoadImageResult, Never>? in
                guard !state.finished, let continuation = state.continuation else { return nil }
                state.finished = true
                state.continuation = nil
                return continuation
            }
            continuation?.resume(returning: result)
        }

        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { continuation in
                let shouldFinishImmediately = requestState.withLock { state -> Bool in
                    guard !state.cancellationRequested, !state.finished else { return true }
                    state.continuation = continuation
                    return false
                }
                if shouldFinishImmediately {
                    continuation.resume(returning: emptyResult())
                    return
                }

                let requestID = manager.requestImage(for: asset,
                                                      targetSize: CGSize(width: 1024, height: 1024),
                                                      contentMode: .aspectFill,
                                                      options: options) { image, info in
                    let isCancelled = info?[PHImageCancelledKey] as? Bool ?? false
                    let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                    guard !isDegraded || isCancelled else { return }

                    let imageSnapshot = image
                    Task { @MainActor in
                        finish(isCancelled ? emptyResult() : imageSnapshot.map { imageResult($0) } ?? emptyResult())
                    }
                }

                let shouldCancel = requestState.withLock { state -> Bool in
                    guard !state.cancellationRequested, !state.finished else { return true }
                    state.requestID = requestID
                    return false
                }
                if shouldCancel {
                    manager.cancelImageRequest(requestID)
                }
            }
        }, onCancel: {
            let (requestID, continuation) = requestState.withLock { state -> (PHImageRequestID, CheckedContinuation<PTLoadImageResult, Never>?) in
                state.cancellationRequested = true
                let continuation = state.continuation
                state.finished = true
                state.continuation = nil
                return (state.requestID, continuation)
            }
            if requestID != PHInvalidImageRequestID {
                manager.cancelImageRequest(requestID)
            }
            if let continuation {
                Task { @MainActor in
                    continuation.resume(returning: emptyResult())
                }
            }
        })
    }

    private static func loadImageFromData(_ data: Data) async -> PTLoadImageResult {
        let imageType = detectImageType(from: data)

        if imageType == .gif {
            let gifResult = await Task.detached(priority: .userInitiated) {
                PTLoadImageFunction.imagesAndDurationFromGif(data: data)
            }.value
            guard let gifResult, !gifResult.images.isEmpty else {
                return emptyResult(imageType: .gif)
            }
            return PTLoadImageResult(allImages: gifResult.images,
                                     firstImage: gifResult.images.first,
                                     loadTime: gifResult.duration,
                                     imageType: .gif)
        }

        let image = await Task.detached(priority: .userInitiated) {
            UIImage(data: data)
        }.value
        guard let image else { return emptyResult(imageType: .unknown) }
        return imageResult(image, imageType: imageType)
    }

    private static func loadFromLocalFileAsync(path: String) async -> PTLoadImageResult {
        let image = await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: path)
        }.value
        return image.map { imageResult($0) } ?? emptyResult()
    }

    public static func handleURLContent(_ dataUrlString: String,
                                        _ iCloudDocumentName: String,
                                        _ progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {

        guard let url = URL(string: dataUrlString), !url.absoluteString.isEmpty else {
            return emptyResult()
        }
        return await handleURL(url, iCloudDocumentName, progressHandle)
    }

    private static func handleURL(_ url: URL,
                                  _ iCloudDocumentName: String,
                                  _ progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {
        if url.isFileURL {
            return await handleFileURLAsync(url, iCloudDocumentName)
        }
        if url.pt_isVideoResource {
            return await loadVideo(url: url,
                                   frameNumber: 10,
                                   maximumSize: PTVideoThumbnailService.defaultMaximumSize)
        }
        return await downloadImage(from: url, progressHandle)
    }

    private static func loadLocal(url: URL,
                                  iCloudDocumentName: String) async -> PTLoadImageResult {
        if url.pt_isVideoResource {
            return await loadVideo(url: url,
                                   frameNumber: 10,
                                   maximumSize: PTVideoThumbnailService.defaultMaximumSize)
        }
        return await loadFromLocalFileAsync(path: url.path)
    }

    private static func handleFileURLAsync(_ url: URL,
                                           _ iCloudDocumentName: String) async -> PTLoadImageResult {
        guard !iCloudDocumentName.isEmpty else {
            return await loadLocal(url: url, iCloudDocumentName: "")
        }

        guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            return emptyResult()
        }
        let resolvedURL = ubiquityURL
            .appendingPathComponent(iCloudDocumentName, isDirectory: true)
            .appendingPathComponent(url.lastPathComponent)
        return await loadLocal(url: resolvedURL, iCloudDocumentName: "")
    }

    private static func loadVideo(url: URL,
                                  frameNumber: Int,
                                  maximumSize: CGSize?) async -> PTLoadImageResult {
        guard let image = await PTVideoCoverCache.image(for: url,
                                                        frameNumber: frameNumber,
                                                        maximumSize: maximumSize ?? PTVideoThumbnailService.defaultMaximumSize) else {
            return emptyResult()
        }
        return imageResult(image)
    }

    private static func loadVideo(asset: AVAsset,
                                  frameNumber: Int,
                                  maximumSize: CGSize?) async -> PTLoadImageResult {
        guard let image = await PTVideoThumbnailService.image(for: asset,
                                                              frameNumber: frameNumber,
                                                              maximumSize: maximumSize) else {
            return emptyResult()
        }
        return imageResult(image)
    }
    
    public static func cachedImage(from url:URL, options:KingfisherOptionsInfo = []) async -> PTLoadImageResult? {
        let cacheKey = url.cacheKey
        let cacheOptions = isGIFURL(url) ? options + [.preloadAllAnimationData] : options
        do {
            let result = try await ImageCache.default.retrieveImage(forKey: cacheKey, options: cacheOptions)
            guard let image = result.image else { return nil }
            if let frames = image.images, !frames.isEmpty {
                return PTLoadImageResult(allImages: frames,
                                         firstImage: frames.first,
                                         loadTime: image.duration,
                                         imageType: .gif)
            }
            return imageResult(image)
        } catch {
            return nil
        }
    }

    public static func downloadImage(from url: URL,
                                     _ progressHandle: PTLoadImageProgressBlock? = nil) async -> PTLoadImageResult {
        guard !Task.isCancelled else { return emptyResult() }

        do {
            let shouldPreloadAnimation = isGIFURL(url)
            let value = try await retrieveRemoteImage(from: url,
                                                      preloadAnimation: shouldPreloadAnimation,
                                                      progressHandle: progressHandle)
            try Task.checkCancellation()
            return await animatedResult(from: value,
                                        allowDataFallback: shouldPreloadAnimation || (value.image.kf.imageFrameCount ?? 0) > 1) ?? imageResult(value.image)
        } catch {
            return emptyResult()
        }
    }

    /// Restores animated GIF frames from Kingfisher's downloaded data only when needed.
    /// Recupera los fotogramas GIF animados desde los datos descargados de Kingfisher solo cuando hace falta.
    /// 仅在需要时从 Kingfisher 的下载数据恢复 GIF 动画帧。
    private static func animatedResult(from value: RetrieveImageResult,
                                       allowDataFallback: Bool) async -> PTLoadImageResult? {
        if let frames = value.image.images, !frames.isEmpty {
            return PTLoadImageResult(allImages: frames,
                                     firstImage: frames.first,
                                     loadTime: value.image.duration,
                                     imageType: .gif)
        }

        guard allowDataFallback else { return nil }
        // Prefer Kingfisher's embedded original bytes before asking the cache serializer for data.
        // Prefiere los bytes originales integrados de Kingfisher antes de pedir datos al serializador de caché.
        // 优先使用 Kingfisher 内嵌的原始数据，再向缓存序列化器请求数据。
        let embeddedData = value.image.kf.gifRepresentation()
        let dataProvider = value.data
        let data: Data?
        if let embeddedData {
            data = embeddedData
        } else {
            data = await Task.detached(priority: .userInitiated, operation: {
                dataProvider()
            }).value
        }
        guard let data,
              detectImageType(from: data) == .gif else {
            return nil
        }

        guard let gifResult = await Task.detached(priority: .userInitiated, operation: {
            PTLoadImageFunction.imagesAndDurationFromGif(data: data)
        }).value,
              !gifResult.images.isEmpty else {
            return nil
        }

        return PTLoadImageResult(allImages: gifResult.images,
                                 firstImage: gifResult.images.first,
                                 loadTime: gifResult.duration,
                                 imageType: .gif)
    }

    private nonisolated static func isGIFURL(_ url: URL) -> Bool {
        url.pathExtension.caseInsensitiveCompare("gif") == .orderedSame
    }

    private nonisolated static func retrieveRemoteImage(from url: URL,
                                                        preloadAnimation: Bool,
                                                        progressHandle: PTLoadImageProgressBlock?) async throws -> RetrieveImageResult {
        let options: KingfisherOptionsInfo = preloadAnimation ? [.preloadAllAnimationData] : []
        return try await KingfisherManager.shared.retrieveImage(
            with: url,
            options: options,
            progressBlock: { receivedSize, totalSize in
                Task { @MainActor in
                    progressHandle?(receivedSize, totalSize)
                }
            }
        )
    }

    /// Converts GIF data into frames without isolating the operation to MainActor.
    /// Convierte datos GIF en un conjunto de fotogramas sin aislarlo al MainActor.
    /// 将 GIF 数据转换为帧数组，并避免绑定到 MainActor。
    public nonisolated static func handleGIFData(_ data: Data) -> [UIImage] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return []
        }

        let frameCount = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        frames.reserveCapacity(frameCount)

        for i in 0..<frameCount {
            if let imageRef = CGImageSourceCreateImageAtIndex(source, i, nil) {
                frames.append(UIImage(cgImage: imageRef))
            }
        }

        return frames
    }
    
    /// Converts GIF data into images and duration without blocking MainActor.
    /// Convierte datos GIF en imágenes y duración sin bloquear el MainActor.
    /// 将 GIF 数据转换为图片和总时长，避免阻塞 MainActor。
    public nonisolated static func imagesAndDurationFromGif(data: Data) -> (images: [UIImage], duration: TimeInterval)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        images.reserveCapacity(count)
        var totalDuration: TimeInterval = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                continue
            }

            let frameDuration = PTLoadImageFunction.gifFrameDuration(source: source, index: i)
            totalDuration += frameDuration

            let image = UIImage(cgImage: cgImage)
            images.append(image)
        }

        return (images, totalDuration)
    }

    private nonisolated static func gifFrameDuration(source: CGImageSource, index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as NSDictionary?,
              let gifInfo = properties[kCGImagePropertyGIFDictionary] as? NSDictionary else {
            return 0.1
        }

        let unclampedDelay = (gifInfo[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber)?.doubleValue
        let clampedDelay = (gifInfo[kCGImagePropertyGIFDelayTime] as? NSNumber)?.doubleValue

        let delay = unclampedDelay ?? clampedDelay ?? 0.1
        guard delay.isFinite, delay > 0 else { return 0.1 }
        return delay < 0.011 ? 0.1 : delay
    }

    // 处理 Live Photo：保持静态方法
    public static func downloadLivePhoto(photoURL: URL,
                                         videoURL: URL,
                                         contentMode: PHImageContentMode = .aspectFit,
                                         completion: @escaping @Sendable (PHLivePhoto?) -> Void) {

        Task {
            // 1. 使用 async let 同时发起两个下载任务，它们将在后台并发执行
            async let photoTask = downloadFileAsync(from: photoURL)
            async let videoTask = downloadFileAsync(from: videoURL)
            
            // 2. 等待两个任务都完成，并安全地获取结果（无需使用外部的 var 变量）
            let downloadedPhotoURL = await photoTask
            let downloadedVideoURL = await videoTask
            
            // 3. 校验下载结果是否都成功
            guard let photo = downloadedPhotoURL, let video = downloadedVideoURL else {
                completion(nil)
                return
            }
            
            // 4. 获取占位图并请求 Live Photo
            let placeholderImage = UIImage(contentsOfFile: photo.path)
            PHLivePhoto.request(withResourceFileURLs: [photo, video],
                                placeholderImage: placeholderImage,
                                targetSize: placeholderImage?.size ?? .zero,
                                contentMode: contentMode) { livePhoto, _ in
                completion(livePhoto)
            }
        }
    }

    private static func downloadFileAsync(from url: URL) async -> URL? {
        // withCheckedContinuation 充当了回调和 async/await 之间的桥梁
        return await withCheckedContinuation { continuation in
            downloadFile(from: url) { localURL in
                // 当下载完成时，恢复挂起的任务并返回结果
                continuation.resume(returning: localURL)
            }
        }
    }
    
    // 下载文件：保持静态方法
    fileprivate static func downloadFile(from url: URL, completion: @escaping @Sendable (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, _ in
            guard let localURL = localURL else {
                completion(nil)
                return
            }

            let tempDirectory = FileManager.default.temporaryDirectory
            let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                completion(destinationURL)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
