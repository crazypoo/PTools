//
//  Color+PTxyzEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

// MARK: - CIE XYZ Color Space

public extension DynamicColor {
    
    /**
     Initializes and returns a color object using CIE XYZ color space component values with an observer at 2° and a D65 illuminant.
     
     Notes that values out of range are clipped.

     - parameter X: The mix of cone response curves, specified as a value from 0 to 95.047.
     - parameter Y: The luminance, specified as a value from 0 to 100.0.
     - parameter Z: The quasi-equal to blue stimulation, specified as a value from 0 to 108.883.
     - parameter alpha: The opacity value of the color object, specified as a value from 0.0 to 1.0. Default to 1.0.
     */
    convenience init(X: CGFloat, Y: CGFloat, Z: CGFloat, alpha: CGFloat = 1.0) {
        // 🚀 优化：统一高精度 D65 常量
        let clippedX = clip(X, 0.0, 95.047) / 100.0
        let clippedY = clip(Y, 0.0, 100.0) / 100.0
        let clippedZ = clip(Z, 0.0, 108.883) / 100.0
        
        let toRGB = { (c: CGFloat) -> CGFloat in
            let rgb = c > 0.0031308 ? 1.055 * pow(c, 1.0 / 2.4) - 0.055 : c * 12.92
            
            // 🚨 致命修复：不能用 abs()，必须使用 clip() 将颜色限制在合法显示范围内
            return clip(rgb, 0.0, 1.0)
        }

        // 标准 XYZ to RGB 转换矩阵
        let red   = toRGB((clippedX * 3.2406) + (clippedY * -1.5372) + (clippedZ * -0.4986))
        let green = toRGB((clippedX * -0.9689) + (clippedY * 1.8758) + (clippedZ * 0.0415))
        let blue  = toRGB((clippedX * 0.0557) + (clippedY * -0.2040) + (clippedZ * 1.0570))

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    // MARK: - Getting the XYZ Components

    /**
     Returns the XYZ (mix of cone response curves, luminance, quasi-equal to blue stimulation) and alpha components.
     It uses an observer at 2° and a D65 illuminant.

     Notes that X values are between 0 to 95.047, Y values are between 0 to 100.0 and Z values are between 0 to 108.883.

     - returns: The XYZ components as a tuple (X, Y, Z, alpha).
     */
    func colorToXYZ() -> (X: CGFloat, Y: CGFloat, Z: CGFloat, alpha: CGFloat) {
        
        // 🚀 优化：改名为 toLinear，因为这里做的是解 Gamma 操作 (sRGB -> Linear RGB)
        let toLinear = { (c: CGFloat) -> CGFloat in
            return c > 0.04045 ? pow((c + 0.055) / 1.055, 2.4) : c / 12.92
        }

        let rgba  = colorToRGBA()
        let red   = toLinear(rgba.r)
        let green = toLinear(rgba.g)
        let blue  = toLinear(rgba.b)

        // 🚀 优化：统一高精度 D65 常量，并保留精度
        let X = roundDecimal(((red * 0.4124) + (green * 0.3576) + (blue * 0.1805)) * 100.0, precision: 1000.0)
        let Y = roundDecimal(((red * 0.2126) + (green * 0.7152) + (blue * 0.0722)) * 100.0, precision: 1000.0)
        let Z = roundDecimal(((red * 0.0193) + (green * 0.1192) + (blue * 0.9505)) * 100.0, precision: 1000.0)

        // 🚀 优化：补齐缺失的 alpha，移除多余的 final
        return (X: X, Y: Y, Z: Z, alpha: rgba.a)
    }
}
