//
//  PTVideoThumbnailService.swift
//  PooTools
//
//  Canonical video thumbnail generation boundary.
//  Límite canónico para generar miniaturas de vídeo.
//  视频缩略图生成的统一边界。
//

import AVFoundation
import UIKit
import os

public enum PTVideoThumbnailService {
    public static let defaultMaximumSize = CGSize(width: 1000, height: 1000)

    /// Generates the requested one-based video frame without blocking the caller.
    /// Genera el fotograma de vídeo solicitado, empezando en uno, sin bloquear al llamador.
    /// 生成从 1 开始计数的指定视频帧，不阻塞调用方。
    @MainActor
    public static func image(for asset: AVAsset,
                             frameNumber: Int,
                             maximumSize: CGSize? = defaultMaximumSize,
                             appliesPreferredTrackTransform: Bool = true) async -> UIImage? {
        guard !Task.isCancelled else { return nil }

        do {
            let time = try await time(for: asset, frameNumber: frameNumber)
            return try await generateImage(for: asset,
                                           at: time,
                                           maximumSize: maximumSize,
                                           appliesPreferredTrackTransform: appliesPreferredTrackTransform,
                                           requiresExactTime: true)
        } catch is CancellationError {
            return nil
        } catch {
            guard !Task.isCancelled else { return nil }
            return try? await generateImage(for: asset,
                                            at: CMTime(value: 0, timescale: 600),
                                            maximumSize: maximumSize,
                                            appliesPreferredTrackTransform: appliesPreferredTrackTransform,
                                            requiresExactTime: false)
        }
    }

    /// Creates a video asset and generates the requested one-based frame.
    /// Crea un recurso de vídeo y genera el fotograma solicitado, empezando en uno.
    /// 创建视频资源并生成从 1 开始计数的指定帧。
    @MainActor
    public static func image(for url: URL,
                             frameNumber: Int,
                             maximumSize: CGSize? = defaultMaximumSize,
                             appliesPreferredTrackTransform: Bool = true) async -> UIImage? {
        let asset = AVURLAsset(url: url,
                               options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        return await image(for: asset,
                           frameNumber: frameNumber,
                           maximumSize: maximumSize,
                           appliesPreferredTrackTransform: appliesPreferredTrackTransform)
    }

    /// English: Generates a thumbnail at a time offset without blocking a cooperative task thread.
    /// Español: Genera una miniatura en un instante concreto sin bloquear un hilo de tareas cooperativas.
    /// 中文：按时间点异步生成缩略图，不阻塞协作式任务线程。
    @MainActor
    public static func imageAsync(for url: URL,
                                  at seconds: Double = 1,
                                  preferredTimescale: CMTimeScale = 10,
                                  maximumSize: CGSize? = nil,
                                  appliesPreferredTrackTransform: Bool = true) async -> UIImage? {
        guard seconds.isFinite, seconds >= 0 else { return nil }

        let safeTimescale = preferredTimescale > 0 ? preferredTimescale : 600
        let time = CMTime(seconds: seconds, preferredTimescale: safeTimescale)
        let asset = AVURLAsset(url: url,
                               options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        do {
            return try await generateImage(for: asset,
                                           at: time,
                                           maximumSize: maximumSize,
                                           appliesPreferredTrackTransform: appliesPreferredTrackTransform,
                                           requiresExactTime: false)
        } catch is CancellationError {
            return nil
        } catch {
            return nil
        }
    }

    /// Preserves the legacy synchronous seconds-based API for compatibility.
    /// Conserva la API síncrona heredada basada en segundos para mantener la compatibilidad.
    /// 保留旧的按秒同步 API 以维持兼容性。
    public static func image(for url: URL,
                             at seconds: Double = 1,
                             preferredTimescale: CMTimeScale = 10,
                             maximumSize: CGSize? = nil,
                             appliesPreferredTrackTransform: Bool = true) -> UIImage? {
        guard seconds.isFinite, seconds >= 0 else { return nil }

        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = appliesPreferredTrackTransform
        if let maximumSize,
           maximumSize.width.isFinite,
           maximumSize.height.isFinite,
           maximumSize.width > 0,
           maximumSize.height > 0 {
            generator.maximumSize = maximumSize
        }

        let safeTimescale = preferredTimescale > 0 ? preferredTimescale : 600
        let time = CMTime(seconds: seconds, preferredTimescale: safeTimescale)
        let imageStorage = OSAllocatedUnfairLock<UIImage?>(initialState: nil)
        let semaphore = DispatchSemaphore(value: 0)

        generator.generateCGImageAsynchronously(for: time) { image, _, _ in
            if let image {
                imageStorage.withLock { $0 = UIImage(cgImage: image) }
            }
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + 15) == .success else {
            generator.cancelAllCGImageGeneration()
            return nil
        }

        return imageStorage.withLock { $0 }
    }

    /// Preserves the legacy callback API, which returns the first frame.
    /// Conserva la API heredada de callback, que devuelve el primer fotograma.
    /// 保留返回首帧的旧回调 API。
    public static func image(for asset: AVAsset,
                             maximumSize: CGSize = defaultMaximumSize,
                             completion: @escaping @MainActor @Sendable (UIImage?) -> Void) {
        generateFirstImage(for: asset, maximumSize: maximumSize) { image in
            Task { @MainActor in
                completion(image)
            }
        }
    }

    /// Preserves the legacy URL callback API, which returns the first frame.
    /// Conserva la API heredada de callback para URL, que devuelve el primer fotograma.
    /// 保留返回首帧的旧 URL 回调 API。
    public static func image(for url: URL,
                             maximumSize: CGSize = defaultMaximumSize,
                             completion: @escaping @MainActor @Sendable (UIImage?) -> Void) {
        generateFirstImage(for: AVURLAsset(url: url), maximumSize: maximumSize) { image in
            Task { @MainActor in
                completion(image)
            }
        }
    }
}

private extension PTVideoThumbnailService {
    @MainActor
    static func time(for asset: AVAsset, frameNumber: Int) async throws -> CMTime {
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw PTVideoThumbnailError.videoTrackUnavailable
        }

        let nominalFrameRate = try await track.load(.nominalFrameRate)
        let minimumFrameDuration = try await track.load(.minFrameDuration)
        let duration = try? await asset.load(.duration)

        let frameRate: Double
        if nominalFrameRate.isFinite, nominalFrameRate > 0 {
            frameRate = Double(nominalFrameRate)
        } else if minimumFrameDuration.isNumeric,
                  minimumFrameDuration.seconds.isFinite,
                  minimumFrameDuration.seconds > 0 {
            frameRate = 1 / minimumFrameDuration.seconds
        } else {
            frameRate = 30
        }

        let safeFrameNumber = max(frameNumber, 1)
        let requestedSeconds = Double(safeFrameNumber - 1) / frameRate
        let frameDuration = 1 / frameRate
        let durationSeconds = duration?.seconds ?? .nan
        let maximumSeconds: Double
        if durationSeconds.isFinite, durationSeconds > 0 {
            maximumSeconds = max(durationSeconds - frameDuration, 0)
        } else {
            maximumSeconds = requestedSeconds
        }

        let seconds = min(max(requestedSeconds, 0), maximumSeconds)
        return CMTime(seconds: seconds, preferredTimescale: 600)
    }

    @MainActor
    static func generateImage(for asset: AVAsset,
                              at time: CMTime,
                              maximumSize: CGSize?,
                              appliesPreferredTrackTransform: Bool,
                              requiresExactTime: Bool) async throws -> UIImage {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = appliesPreferredTrackTransform
        if let maximumSize,
           maximumSize.width.isFinite,
           maximumSize.height.isFinite,
           maximumSize.width > 0,
           maximumSize.height > 0 {
            generator.maximumSize = maximumSize
        }
        if requiresExactTime {
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
        }

        return try await withTaskCancellationHandler {
            let result = try await generator.image(at: time)
            try Task.checkCancellation()
            return UIImage(cgImage: result.image)
        } onCancel: {
            generator.cancelAllCGImageGeneration()
        }
    }

    static func generateFirstImage(for asset: AVAsset,
                                   maximumSize: CGSize,
                                   completion: @escaping @Sendable (UIImage?) -> Void) {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if maximumSize.width.isFinite,
           maximumSize.height.isFinite,
           maximumSize.width > 0,
           maximumSize.height > 0 {
            generator.maximumSize = maximumSize
        }

        generator.generateCGImageAsynchronously(for: .zero) { image, _, _ in
            completion(image.map(UIImage.init(cgImage:)))
        }
    }
}

private enum PTVideoThumbnailError: Error {
    case videoTrackUnavailable
}
