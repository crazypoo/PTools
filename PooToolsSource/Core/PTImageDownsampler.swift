//
//  PTImageDownsampler.swift
//  PooTools
//

import Foundation
import ImageIO
import UIKit

// English: The memory budget converts a view size into a bounded decode size.
// Español: El presupuesto de memoria convierte el tamaño de una vista en un tamaño de decodificación limitado.
// 中文：内存预算把视图尺寸转换为受限的解码尺寸。
public struct PTImageMemoryBudget: Sendable {
    public let maximumPixelSize: Int

    public init(maximumPixelSize: Int = PTImageDownsampler.defaultMaximumPixelSize) {
        self.maximumPixelSize = max(1, maximumPixelSize)
    }

    public static let `default` = PTImageMemoryBudget()
}

// English: Decode large still images at the requested pixel budget before UIKit creates a bitmap.
// Español: Decodifica las imágenes grandes dentro del presupuesto de píxeles antes de crear el bitmap de UIKit.
// 中文：在 UIKit 创建位图前，先按目标像素预算解码大图，降低峰值内存。
public enum PTImageDownsampler {
    public static let defaultMaximumPixelSize = 4096

    public nonisolated static func decode(data: Data,
                                          targetSize: CGSize?,
                                          scale: CGFloat = 1) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return decode(source: source, targetSize: targetSize, scale: scale, budget: .default)
    }

    public nonisolated static func decode(url: URL,
                                          targetSize: CGSize?,
                                          scale: CGFloat = 1) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return decode(source: source, targetSize: targetSize, scale: scale, budget: .default)
    }

    private nonisolated static func decode(source: CGImageSource,
                                           targetSize: CGSize?,
                                           scale: CGFloat,
                                           budget: PTImageMemoryBudget) -> UIImage? {
        let maximumPixelSize = maximumPixelSize(for: targetSize, scale: scale, budget: budget)
        let options: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways as String: true,
            kCGImageSourceCreateThumbnailWithTransform as String: true,
            kCGImageSourceShouldCache as String: false,
            kCGImageSourceShouldCacheImmediately as String: false,
            kCGImageSourceThumbnailMaxPixelSize as String: maximumPixelSize
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return nil
        }
        return UIImage(cgImage: image)
    }

    private nonisolated static func maximumPixelSize(for targetSize: CGSize?,
                                                     scale: CGFloat,
                                                     budget: PTImageMemoryBudget) -> Int {
        let safeScale = scale.isFinite && scale > 0 ? scale : 1
        guard let targetSize,
              targetSize.width.isFinite,
              targetSize.height.isFinite,
              targetSize.width > 0,
              targetSize.height > 0 else {
            return budget.maximumPixelSize
        }

        let size = max(targetSize.width, targetSize.height) * safeScale
        guard size.isFinite else { return budget.maximumPixelSize }
        return max(1, min(budget.maximumPixelSize, Int(ceil(size))))
    }
}
