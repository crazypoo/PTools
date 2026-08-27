//
//  UIImage+PTColorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(OSX)
import AppKit
public typealias UIImage = NSImage
public typealias UIColor = NSColor
#else
import UIKit
#endif
import Foundation

public struct UIImageColors: Sendable {
    public let background: UIColor
    public let primary: UIColor
    public let secondary: UIColor
    public let detail: UIColor
    
    public init(background: UIColor, primary: UIColor, secondary: UIColor, detail: UIColor) {
        self.background = background
        self.primary = primary
        self.secondary = secondary
        self.detail = detail
    }
}

public enum UIImageColorsQuality: CGFloat, Sendable {
    case lowest = 50 // 50 像素
    case low = 100 // 100 像素
    case high = 250 // 250 像素
    case highest = 0 // 保留最高可用尺寸
}

fileprivate struct UIImageColorsCounter {
    let color: UInt32 // 🚀 改为 UInt32
    let count: Int
}

fileprivate extension UInt32 {
    
    var r: Double { return Double((self >> 16) & 0xFF) }
    var g: Double { return Double((self >> 8) & 0xFF) }
    var b: Double { return Double(self & 0xFF) }
    
    var isDarkColor: Bool {
        return (r * 0.2126) + (g * 0.7152) + (b * 0.0722) < 127.5
    }
    
    var isBlackOrWhite: Bool {
        return (r > 232 && g > 232 && b > 232) || (r < 23 && g < 23 && b < 23)
    }
    
    func isDistinct(_ other: UInt32) -> Bool {
        let _r = self.r, _g = self.g, _b = self.b
        let o_r = other.r, o_g = other.g, o_b = other.b

        return (fabs(_r - o_r) > 63.75 || fabs(_g - o_g) > 63.75 || fabs(_b - o_b) > 63.75)
            && !(fabs(_r - _g) < 7.65 && fabs(_r - _b) < 7.65 && fabs(o_r - o_g) < 7.65 && fabs(o_r - o_b) < 7.65)
    }
    
    func with(minSaturation: Double) -> UInt32 {
        let _r = r / 255.0
        let _g = g / 255.0
        let _b = b / 255.0
        var H: Double = 0
        var S: Double = 0
        let V = fmax(_r, fmax(_g, _b))
        var C = V - fmin(_r, fmin(_g, _b))
        
        S = V == 0 ? 0 : C / V
        
        if minSaturation <= S { return self }
        
        if C == 0 {
            H = 0
        } else if _r == V {
            H = fmod((_g - _b) / C, 6.0)
        } else if _g == V {
            H = 2.0 + ((_b - _r) / C)
        } else {
            H = 4.0 + ((_r - _g) / C)
        }
        
        if H < 0 { H += 6.0 }
        
        C = V * minSaturation
        let X = C * (1.0 - fabs(fmod(H, 2.0) - 1.0))
        var R: Double = 0, G: Double = 0, B: Double = 0
        
        switch H {
        case 0...1: R = C; G = X; B = 0
        case 1...2: R = X; G = C; B = 0
        case 2...3: R = 0; G = C; B = X
        case 3...4: R = 0; G = X; B = C
        case 4...5: R = X; G = 0; B = C
        case 5..<6: R = C; G = 0; B = X
        default: break
        }
        
        let m = V - C
        let finalR = UInt32((R + m) * 255.0)
        let finalG = UInt32((G + m) * 255.0)
        let finalB = UInt32((B + m) * 255.0)
        
        return (finalR << 16) | (finalG << 8) | finalB
    }
    
    func isContrasting(_ color: UInt32) -> Bool {
        let bgLum = (0.2126 * r) + (0.7152 * g) + (0.0722 * b) + 12.75
        let fgLum = (0.2126 * color.r) + (0.7152 * color.g) + (0.0722 * color.b) + 12.75
        if bgLum > fgLum {
            return 1.6 < bgLum / fgLum
        } else {
            return 1.6 < fgLum / bgLum
        }
    }
    
    var uicolor: UIColor {
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1)
    }
}

extension UIImage {
    
    #if os(OSX)
    private func resizeForUIImageColors(newSize: CGSize) -> UIImage? {
        let frame = CGRect(origin: .zero, size: newSize)
        guard let representation = bestRepresentation(for: frame, context: nil, hints: nil) else { return nil }
        return NSImage(size: newSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })
    }
    #else
    private func resizeForUIImageColors(newSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #endif

    public func getColors(quality: UIImageColorsQuality = .high, _ completion: @escaping @MainActor @Sendable (UIImageColors?) -> Void) {
        let image = self
        Task.detached(priority: .userInitiated) {
            let result = image.getColors(quality: quality)
            await MainActor.run {
                completion(result)
            }
        }
    }

    public func getColors(quality: UIImageColorsQuality = .high) -> UIImageColors? {
        #if os(OSX)
        let sourcePixelSize = self.size
        #else
        let sourcePixelSize = self.cgImage.map {
            CGSize(width: $0.width, height: $0.height)
        } ?? CGSize(width: self.size.width * max(self.scale, 1),
                    height: self.size.height * max(self.scale, 1))
        #endif

        guard sourcePixelSize.width.isFinite,
              sourcePixelSize.height.isFinite,
              sourcePixelSize.width > 0,
              sourcePixelSize.height > 0 else {
            return nil
        }

        let sourcePixelCount = sourcePixelSize.width * sourcePixelSize.height
        guard sourcePixelCount.isFinite else { return nil }

        let maxLongEdge: CGFloat = quality == .highest ? 4096 : quality.rawValue
        var scale = min(1, maxLongEdge / max(sourcePixelSize.width, sourcePixelSize.height))
        if quality == .highest, sourcePixelCount > 16_000_000 {
            scale = min(scale, sqrt(16_000_000 / sourcePixelCount))
        }

        let targetSize = CGSize(width: max(1, (sourcePixelSize.width * scale).rounded()),
                                height: max(1, (sourcePixelSize.height * scale).rounded()))
        guard targetSize.width.isFinite, targetSize.height.isFinite,
              let resizedImage = self.resizeForUIImageColors(newSize: targetSize) else {
            return nil
        }

        #if os(OSX)
        guard let cgImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #else
        guard let cgImage = resizedImage.cgImage else { return nil }
        #endif
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRowResult = width.multipliedReportingOverflow(by: bytesPerPixel)
        let bufferCountResult = height.multipliedReportingOverflow(by: bytesPerRowResult.partialValue)
        guard width > 0, height > 0,
              !bytesPerRowResult.overflow,
              !bufferCountResult.overflow,
              bufferCountResult.partialValue <= 64_000_000 else {
            return nil
        }

        let bytesPerRow = bytesPerRowResult.partialValue
        let bitsPerComponent = 8
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: bufferCountResult.partialValue)
        
        guard let context = CGContext(data: &rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let pixelCount = bufferCountResult.partialValue / bytesPerPixel
        let sampleStride = max(1, Int(ceil(sqrt(Double(pixelCount) / 1_000_000))))
        var imageColors = [UInt32: Int]()
        imageColors.reserveCapacity(min(pixelCount, 4_096))
        var acceptedPixelCount = 0
        
        for y in stride(from: 0, to: height, by: sampleStride) {
            for x in stride(from: 0, to: width, by: sampleStride) {
                let pixelIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                let alpha = rawData[pixelIndex + 3]
                
                if alpha >= 127 {
                    let alphaValue = Int(alpha)
                    let r = UInt32(min(255, (Int(rawData[pixelIndex]) * 255 + alphaValue / 2) / alphaValue))
                    let g = UInt32(min(255, (Int(rawData[pixelIndex + 1]) * 255 + alphaValue / 2) / alphaValue))
                    let b = UInt32(min(255, (Int(rawData[pixelIndex + 2]) * 255 + alphaValue / 2) / alphaValue))
                    let colorKey = (r << 16) | (g << 8) | b
                    
                    imageColors[colorKey, default: 0] += 1
                    acceptedPixelCount += 1
                }
            }
        }

        guard !imageColors.isEmpty, acceptedPixelCount > 0 else { return nil }

        let threshold = Int(CGFloat(height) * 0.01)
        
        var sortedColors = imageColors
            .filter { $0.value > threshold }
            .map { UIImageColorsCounter(color: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        
        let proposedEdgeColor: UIImageColorsCounter
        if let firstColor = sortedColors.first {
            proposedEdgeColor = firstColor
        } else if let mostCommonColor = imageColors.max(by: { $0.value < $1.value }) {
            proposedEdgeColor = UIImageColorsCounter(color: mostCommonColor.key,
                                                     count: mostCommonColor.value)
        } else {
            return nil
        }

        var backgroundColor = proposedEdgeColor
        
        if backgroundColor.color.isBlackOrWhite && sortedColors.count > 0 {
            for i in 1..<sortedColors.count {
                let nextColor = sortedColors[i]
                if Double(nextColor.count) / Double(backgroundColor.count) > 0.3 {
                    if !nextColor.color.isBlackOrWhite {
                        backgroundColor = nextColor
                        break
                    }
                } else {
                    break
                }
            }
        }
        
        let background = backgroundColor.color
        let findDarkTextColor = !background.isDarkColor
        var primary: UInt32?
        var secondary: UInt32?
        var detail: UInt32?
        
        sortedColors = imageColors
            .map { UIImageColorsCounter(color: $0.key.with(minSaturation: 0.15), count: $0.value) }
            .filter { $0.color.isDarkColor == findDarkTextColor }
            .sorted { $0.count > $1.count }
        
        for counter in sortedColors {
            let color = counter.color
            
            if primary == nil {
                if color.isContrasting(background) {
                    primary = color
                }
            } else if secondary == nil {
                guard let primary else { continue }
                if !color.isContrasting(background) || !primary.isDistinct(color) { continue }
                secondary = color
            } else if detail == nil {
                guard let primary, let secondary else { continue }
                if !color.isContrasting(background)
                    || !secondary.isDistinct(color)
                    || !primary.isDistinct(color) { continue }
                detail = color
                break
            }
        }
        
        let isDarkBackground = background.isDarkColor
        let fallbackColor: UInt32 = isDarkBackground ? 0xFFFFFF : 0x000000 // 白或黑
        let primaryColor = primary ?? fallbackColor
        let secondaryColor = secondary ?? fallbackColor
        let detailColor = detail ?? fallbackColor
        
        return UIImageColors(
            background: background.uicolor,
            primary: primaryColor.uicolor,
            secondary: secondaryColor.uicolor,
            detail: detailColor.uicolor
        )
    }
}
