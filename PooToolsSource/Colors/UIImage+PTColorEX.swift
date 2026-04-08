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

// 🚀 优化 1：移除强制解包，改为安全的常量 (let)
public struct UIImageColors {
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

public enum UIImageColorsQuality: CGFloat {
    case lowest = 50 // 50px
    case low = 100 // 100px
    case high = 250 // 250px
    case highest = 0 // No scale
}

fileprivate struct UIImageColorsCounter {
    let color: UInt32 // 🚀 改为 UInt32
    let count: Int
}

// 🚀 优化 2：彻底抛弃 Double 魔法，改为极速的 UInt32 位运算
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
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    #endif

    public func getColors(quality: UIImageColorsQuality = .high, _ completion: @escaping (UIImageColors?) -> Void) {
        // 使用标准的 GCD 全局队列替代自定义封装，如果有必要你可以换回你的 PTGCDManager
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.getColors(quality: quality)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    public func getColors(quality: UIImageColorsQuality = .high) -> UIImageColors? {
        var scaleDownSize: CGSize = self.size
        if quality != .highest {
            if self.size.width < self.size.height {
                let ratio = self.size.height / self.size.width
                scaleDownSize = CGSize(width: quality.rawValue / ratio, height: quality.rawValue)
            } else {
                let ratio = self.size.width / self.size.height
                scaleDownSize = CGSize(width: quality.rawValue, height: quality.rawValue / ratio)
            }
        }
        
        guard let resizedImage = self.resizeForUIImageColors(newSize: scaleDownSize) else { return nil }

        #if os(OSX)
        guard let cgImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #else
        guard let cgImage = resizedImage.cgImage else { return nil }
        #endif
        
        let width = cgImage.width
        let height = cgImage.height
        
        // 🚀 安全渲染：强行将图片绘制到标准的 32-bit RGBA 缓冲区中，避免因图片源格式不同导致的解析错乱崩溃
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        guard let context = CGContext(data: &rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 🚀 优化 3：原生 Swift 字典替代 NSCountedSet，性能呈指数级飞跃
        var imageColors = [UInt32: Int]()
        imageColors.reserveCapacity(width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                let alpha = rawData[pixelIndex + 3]
                
                // 忽略透明度过低的像素
                if alpha >= 127 {
                    let r = UInt32(rawData[pixelIndex])
                    let g = UInt32(rawData[pixelIndex + 1])
                    let b = UInt32(rawData[pixelIndex + 2])
                    let colorKey = (r << 16) | (g << 8) | b
                    
                    imageColors[colorKey, default: 0] += 1
                }
            }
        }

        let threshold = Int(CGFloat(height) * 0.01)
        
        // 过滤并排序
        var sortedColors = imageColors
            .filter { $0.value > threshold }
            .map { UIImageColorsCounter(color: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        
        var proposedEdgeColor: UIImageColorsCounter = sortedColors.first ?? UIImageColorsCounter(color: 0, count: 1)
        
        if proposedEdgeColor.color.isBlackOrWhite && sortedColors.count > 0 {
            for i in 1..<sortedColors.count {
                let nextColor = sortedColors[i]
                if Double(nextColor.count) / Double(proposedEdgeColor.count) > 0.3 {
                    if !nextColor.color.isBlackOrWhite {
                        proposedEdgeColor = nextColor
                        break
                    }
                } else {
                    break
                }
            }
        }
        
        var proposed: [UInt32?] = [proposedEdgeColor.color, nil, nil, nil]
        let findDarkTextColor = !proposed[0]!.isDarkColor
        
        // 重新过滤并排序颜色（应用饱和度调整）
        sortedColors = imageColors
            .map { UIImageColorsCounter(color: $0.key.with(minSaturation: 0.15), count: $0.value) }
            .filter { $0.color.isDarkColor == findDarkTextColor }
            .sorted { $0.count > $1.count }
        
        for counter in sortedColors {
            let color = counter.color
            
            if proposed[1] == nil {
                if color.isContrasting(proposed[0]!) {
                    proposed[1] = color
                }
            } else if proposed[2] == nil {
                if !color.isContrasting(proposed[0]!) || !proposed[1]!.isDistinct(color) { continue }
                proposed[2] = color
            } else if proposed[3] == nil {
                if !color.isContrasting(proposed[0]!) || !proposed[2]!.isDistinct(color) || !proposed[1]!.isDistinct(color) { continue }
                proposed[3] = color
                break
            }
        }
        
        let isDarkBackground = proposed[0]!.isDarkColor
        let fallbackColor: UInt32 = isDarkBackground ? 0xFFFFFF : 0x000000 // 白或黑
        
        for i in 1...3 {
            if proposed[i] == nil { proposed[i] = fallbackColor }
        }
        
        return UIImageColors(
            background: proposed[0]!.uicolor,
            primary: proposed[1]!.uicolor,
            secondary: proposed[2]!.uicolor,
            detail: proposed[3]!.uicolor
        )
    }
}
