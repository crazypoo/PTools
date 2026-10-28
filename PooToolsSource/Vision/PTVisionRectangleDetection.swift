//
//  PTVisionRectangleDetection.swift
//  PooTools
//
// English: Detect document-like rectangles and crop them with explicit orientation handling.
// Español: Detecta rectángulos parecidos a documentos y los recorta con orientación explícita.
// 中文：提供带明确方向处理的文档矩形检测与裁切能力。
//

#if canImport(UIKit) && canImport(Vision)
import ImageIO
import UIKit
import Vision

public enum PTVisionRectangleError: Error, LocalizedError, Sendable, Equatable {
    case invalidImage
    case noRectangles
    case detectionFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "图片没有可用于 Vision 的 CGImage"
        case .noRectangles:
            return "没有检测到矩形"
        case .detectionFailed(let message):
            return "矩形检测失败：\(message)"
        case .cancelled:
            return "矩形检测已取消"
        }
    }
}

public struct PTVisionRectangleObservation: Sendable, Equatable {
    public let boundingBox: CGRect
    public let topLeft: CGPoint
    public let topRight: CGPoint
    public let bottomLeft: CGPoint
    public let bottomRight: CGPoint
    public let confidence: Float

    public init(boundingBox: CGRect,
                topLeft: CGPoint,
                topRight: CGPoint,
                bottomLeft: CGPoint,
                bottomRight: CGPoint,
                confidence: Float) {
        self.boundingBox = boundingBox
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.confidence = confidence
    }
}

@MainActor
public enum PTVisionRectangleDetection {
    // English: Return immutable geometry values so Vision observations never cross an actor boundary.
    // Español: Devuelve geometría inmutable para que las observaciones de Vision no crucen límites de actor.
    // 中文：只返回不可变几何值，避免 Vision observation 跨 actor 传递。
    public static func detect(in image: UIImage,
                              orientation: CGImagePropertyOrientation = .up,
                              maximumObservations: Int = 4,
                              minimumConfidence: Float = 0.5) async throws -> [PTVisionRectangleObservation] {
        guard let cgImage = image.cgImage else {
            throw PTVisionRectangleError.invalidImage
        }

        let box = PTVisionCGImageBox(image: cgImage)
        do {
            return try await Task.detached(priority: .userInitiated) {
                try Task.checkCancellation()

                let request = VNDetectRectanglesRequest()
                request.maximumObservations = max(1, maximumObservations)
                request.minimumConfidence = min(1, max(0, minimumConfidence))
                let handler = VNImageRequestHandler(cgImage: box.image,
                                                    orientation: orientation,
                                                    options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    throw PTVisionRectangleError.detectionFailed(error.localizedDescription)
                }

                try Task.checkCancellation()
                let observations = (request.results as? [VNRectangleObservation] ?? [])
                    .map {
                        PTVisionRectangleObservation(boundingBox: $0.boundingBox,
                                                     topLeft: $0.topLeft,
                                                     topRight: $0.topRight,
                                                     bottomLeft: $0.bottomLeft,
                                                     bottomRight: $0.bottomRight,
                                                     confidence: $0.confidence)
                    }
                    .sorted { $0.confidence > $1.confidence }
                guard !observations.isEmpty else {
                    throw PTVisionRectangleError.noRectangles
                }
                return observations
            }.value
        } catch is CancellationError {
            throw PTVisionRectangleError.cancelled
        }
    }

    // English: Crop in pixel coordinates after normalizing UIImage orientation and clamping bounds.
    // Español: Recorta en coordenadas de píxel después de normalizar la orientación de UIImage y limitar los bordes.
    // 中文：先统一 UIImage 方向，再用像素坐标和边界夹取执行裁切。
    public static func crop(_ image: UIImage,
                            to observation: PTVisionRectangleObservation,
                            scale: CGFloat? = nil) -> UIImage? {
        let normalizedImage = normalized(image)
        guard let cgImage = normalizedImage.cgImage else { return nil }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        guard width > 0, height > 0 else { return nil }

        let box = observation.boundingBox.standardized
        let pixelRect = CGRect(x: box.minX * width,
                               y: (1 - box.maxY) * height,
                               width: box.width * width,
                               height: box.height * height)
            .intersection(CGRect(x: 0, y: 0, width: width, height: height))
            .integral
        guard pixelRect.width > 0, pixelRect.height > 0,
              let cropped = cgImage.cropping(to: pixelRect) else {
            return nil
        }

        let safeScale = scale.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
            ?? max(1, normalizedImage.scale)
        return UIImage(cgImage: cropped, scale: safeScale, orientation: .up)
    }

    public struct DetectionResult {
        public let observation: PTVisionRectangleObservation
        public let image: UIImage

        public init(observation: PTVisionRectangleObservation, image: UIImage) {
            self.observation = observation
            self.image = image
        }
    }

    public static func detectAndCrop(in image: UIImage,
                                     orientation: CGImagePropertyOrientation = .up,
                                     maximumObservations: Int = 4,
                                     minimumConfidence: Float = 0.5) async throws -> [DetectionResult] {
        let observations = try await detect(in: image,
                                            orientation: orientation,
                                            maximumObservations: maximumObservations,
                                            minimumConfidence: minimumConfidence)
        return observations.compactMap { observation in
            guard let cropped = crop(image, to: observation) else { return nil }
            return DetectionResult(observation: observation, image: cropped)
        }
    }

    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

// English: CGImage is a system-owned immutable snapshot used only inside the Vision worker.
// Español: CGImage es una instantánea inmutable del sistema usada solo dentro del worker de Vision.
// 中文：CGImage 是系统管理的不可变快照，只在 Vision 后台 worker 内使用。
private struct PTVisionCGImageBox: @unchecked Sendable {
    let image: CGImage
}
#endif
