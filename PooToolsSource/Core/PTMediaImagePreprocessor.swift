//
//  PTMediaImagePreprocessor.swift
//  PooTools
//
// English: Prepare upload images with explicit pixel and encoded-byte budgets.
// Español: Prepara imágenes para subida con presupuestos explícitos de píxeles y bytes codificados.
// 中文：用明确的像素预算和编码字节预算准备上传图片。
//

#if canImport(UIKit) && canImport(ImageIO)
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

public enum PTMediaImageEncoding: String, Sendable {
    case jpeg
    case heic
    case png
}

public struct PTMediaImagePreprocessingConfiguration: Sendable, Equatable {
    public let maxPixelDimension: Int
    public let maxEncodedBytes: Int?
    public let encoding: PTMediaImageEncoding
    public let initialQuality: CGFloat
    public let qualityFloor: CGFloat
    public let preservesMetadata: Bool

    public init(maxPixelDimension: Int = 4096,
                maxEncodedBytes: Int? = nil,
                encoding: PTMediaImageEncoding = .jpeg,
                initialQuality: CGFloat = 0.9,
                qualityFloor: CGFloat = 0.35,
                preservesMetadata: Bool = false) {
        let initial = min(1, max(0.01, initialQuality))
        self.maxPixelDimension = max(1, maxPixelDimension)
        self.maxEncodedBytes = maxEncodedBytes.flatMap { $0 > 0 ? $0 : nil }
        self.encoding = encoding
        self.initialQuality = initial
        self.qualityFloor = min(initial, max(0.01, qualityFloor))
        self.preservesMetadata = preservesMetadata
    }
}

public struct PTPreparedMediaImage: Sendable {
    public let data: Data
    public let pixelSize: CGSize
    public let encoding: PTMediaImageEncoding
    public let quality: CGFloat
    public let didDownsample: Bool

    public init(data: Data,
                pixelSize: CGSize,
                encoding: PTMediaImageEncoding,
                quality: CGFloat,
                didDownsample: Bool) {
        self.data = data
        self.pixelSize = pixelSize
        self.encoding = encoding
        self.quality = quality
        self.didDownsample = didDownsample
    }
}

public enum PTMediaImagePreprocessorError: Error, LocalizedError, Sendable, Equatable {
    case invalidImage
    case unsupportedEncoding
    case byteBudgetExceeded
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "图片数据无效"
        case .unsupportedEncoding:
            return "当前系统不支持目标图片编码"
        case .byteBudgetExceeded:
            return "图片在达到最低质量后仍超过字节预算"
        case .cancelled:
            return "图片预处理已取消"
        }
    }
}

// English: The public boundary is value-only; UIKit image conversion stays on the main actor.
// Español: El límite público solo transporta valores; la conversión de imágenes UIKit permanece en MainActor.
// 中文：公开边界只传递值类型，UIKit 图片转换固定在 MainActor 上执行。
public enum PTMediaImagePreprocessor {
    // English: Run ImageIO and encoding work away from the main actor.
    // Español: Ejecuta ImageIO y la codificación fuera de MainActor.
    // 中文：将 ImageIO 和编码工作放到主线程之外执行。
    public nonisolated static func prepare(data: Data,
                                           configuration: PTMediaImagePreprocessingConfiguration = .init()) async throws -> PTPreparedMediaImage {
        do {
            return try await Task.detached(priority: .userInitiated) {
                try Task.checkCancellation()
                let result = try PTMediaImagePreprocessorWorker.prepare(data: data,
                                                                         configuration: configuration)
                try Task.checkCancellation()
                return result
            }.value
        } catch is CancellationError {
            throw PTMediaImagePreprocessorError.cancelled
        }
    }

    // English: Convert a UIKit image to immutable bytes before entering the background pipeline.
    // Español: Convierte una imagen UIKit en bytes inmutables antes de entrar en la canalización de fondo.
    // 中文：进入后台流水线前，先把 UIKit 图片转换成不可变数据。
    @MainActor
    public static func prepare(image: UIImage,
                               configuration: PTMediaImagePreprocessingConfiguration = .init()) async throws -> PTPreparedMediaImage {
        let sourceData: Data?
        if image.cgImage?.alphaInfo == .none,
           let jpegData = image.jpegData(compressionQuality: 1) {
            sourceData = jpegData
        } else {
            sourceData = image.pngData() ?? image.jpegData(compressionQuality: 1)
        }
        guard let sourceData else {
            throw PTMediaImagePreprocessorError.invalidImage
        }
        return try await prepare(data: sourceData, configuration: configuration)
    }
}

private enum PTMediaImagePreprocessorWorker {
    static func prepare(data: Data,
                        configuration: PTMediaImagePreprocessingConfiguration) throws -> PTPreparedMediaImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0 else {
            throw PTMediaImagePreprocessorError.invalidImage
        }

        let sourceProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?
        let originalWidth = sourceProperties?.object(forKey: kCGImagePropertyPixelWidth) as? NSNumber
        let originalHeight = sourceProperties?.object(forKey: kCGImagePropertyPixelHeight) as? NSNumber
        let sourceMaximum = max(originalWidth?.intValue ?? 0,
                                originalHeight?.intValue ?? 0)
        let targetMaximum = max(1, min(configuration.maxPixelDimension,
                                      sourceMaximum > 0 ? sourceMaximum : configuration.maxPixelDimension))
        let didDownsample = sourceMaximum > targetMaximum

        // English: Reuse the canonical PTools downsampler before encoding the upload payload.
        // Español: Reutiliza el downsampler canónico de PTools antes de codificar el payload de subida.
        // 中文：编码上传数据前复用 PTools 的统一下采样器。
        guard let decodedImage = PTImageDownsampler.decode(
            data: data,
            targetSize: CGSize(width: targetMaximum, height: targetMaximum),
            scale: 1,
            budget: .init(maximumPixelSize: configuration.maxPixelDimension)),
              let image = decodedImage.cgImage else {
            throw PTMediaImagePreprocessorError.invalidImage
        }

        try Task.checkCancellation()
        let encoded = try encode(image: image,
                                 sourceProperties: sourceProperties,
                                 configuration: configuration)
        return PTPreparedMediaImage(data: encoded.data,
                                    pixelSize: CGSize(width: image.width, height: image.height),
                                    encoding: configuration.encoding,
                                    quality: encoded.quality,
                                    didDownsample: didDownsample)
    }

    private static func encode(image: CGImage,
                               sourceProperties: NSDictionary?,
                               configuration: PTMediaImagePreprocessingConfiguration) throws -> (data: Data, quality: CGFloat) {
        if configuration.encoding == .png {
            guard let data = encode(image: image,
                                    sourceProperties: sourceProperties,
                                    encoding: .png,
                                    quality: 1,
                                    preservesMetadata: configuration.preservesMetadata) else {
                throw PTMediaImagePreprocessorError.unsupportedEncoding
            }
            if let maximumBytes = configuration.maxEncodedBytes,
               data.count > maximumBytes {
                throw PTMediaImagePreprocessorError.byteBudgetExceeded
            }
            return (data, 1)
        }

        var quality = configuration.initialQuality
        let step = max(0.01, (configuration.initialQuality - configuration.qualityFloor) / 8)
        var lastData: Data?
        for _ in 0...8 {
            try Task.checkCancellation()
            guard let data = encode(image: image,
                                    sourceProperties: sourceProperties,
                                    encoding: configuration.encoding,
                                    quality: quality,
                                    preservesMetadata: configuration.preservesMetadata) else {
                throw PTMediaImagePreprocessorError.unsupportedEncoding
            }
            lastData = data
            if let maximumBytes = configuration.maxEncodedBytes,
               data.count > maximumBytes,
               quality > configuration.qualityFloor {
                quality = max(configuration.qualityFloor, quality - step)
                continue
            }
            if let maximumBytes = configuration.maxEncodedBytes,
               data.count > maximumBytes {
                throw PTMediaImagePreprocessorError.byteBudgetExceeded
            }
            return (data, quality)
        }

        guard let lastData else { throw PTMediaImagePreprocessorError.invalidImage }
        if let maximumBytes = configuration.maxEncodedBytes, lastData.count > maximumBytes {
            throw PTMediaImagePreprocessorError.byteBudgetExceeded
        }
        return (lastData, quality)
    }

    private static func encode(image: CGImage,
                               sourceProperties: NSDictionary?,
                               encoding: PTMediaImageEncoding,
                               quality: CGFloat,
                               preservesMetadata: Bool) -> Data? {
        let identifier: String
        switch encoding {
        case .jpeg:
            identifier = UTType.jpeg.identifier
        case .heic:
            identifier = UTType.heic.identifier
        case .png:
            identifier = UTType.png.identifier
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData,
                                                                 identifier as CFString,
                                                                 1,
                                                                 nil) else {
            return nil
        }

        let properties = NSMutableDictionary()
        if preservesMetadata, let sourceProperties {
            sourceProperties.enumerateKeysAndObjects { key, value, _ in
                properties[key] = value
            }
        }
        if encoding != .png {
            properties[kCGImageDestinationLossyCompressionQuality] = min(1, max(0.01, quality))
        }
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
#endif
