//
//  Color+PTDerivingEX.swift
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

public enum GrayscalingMode {
    /// XYZ luminance
    case luminance
    /// HSL lightness
    case lightness
    /// RGB average
    case average
    /// HSV value
    case value
}

// MARK: Deriving Colors

public extension DynamicColor {
    
    /**
     Creates and returns a color object with the hue rotated along the color wheel by the given amount.
     */
    func adjustedHue(@PTClampedPropertyWrapper(range: -360...360) amount: CGFloat) -> DynamicColor {
        return HSL(color: self).adjustedHue(amount: amount).toDynamicColor()
    }
    
    /**
     Creates and returns the complement of the color object.
     This is identical to adjustedHue(180).
     */
    func complemented() -> DynamicColor {
        return adjustedHue(amount: 180.0)
    }
    
    /**
     Creates and returns a color object with the lightness increased by the given amount.
     */
    func lightened(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat = 0.2) -> DynamicColor {
        return HSL(color: self).lighter(amount: amount).toDynamicColor()
    }
    
    /**
     Creates and returns a color object with the lightness decreased by the given amount.
     */
    func darkened(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat = 0.2) -> DynamicColor {
        return HSL(color: self).darkened(amount: amount).toDynamicColor()
    }
    
    /**
     Creates and returns a color object with the saturation increased by the given amount.
     */
    func saturated(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat = 0.2) -> DynamicColor {
        return HSL(color: self).saturated(amount: amount).toDynamicColor()
    }
    
    /**
     Creates and returns a color object with the saturation decreased by the given amount.
     */
    func desaturated(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat = 0.2) -> DynamicColor {
        return HSL(color: self).desaturated(amount: amount).toDynamicColor()
    }
    
    /**
     Creates and returns a color object converted to grayscale.
     */
    func grayscaled(mode: GrayscalingMode = .lightness) -> DynamicColor {
        let (r, g, b, a) = self.colorToRGBA()
        
        let l: CGFloat
        switch mode {
        case .luminance:
            l = (0.299 * r) + (0.587 * g) + (0.114 * b)
        case .lightness:
            l = 0.5 * (max(r, g, b) + min(r, g, b))
        case .average:
            l = (1.0 / 3.0) * (r + g + b)
        case .value:
            l = max(r, g, b)
        }
        
        // 🚀 优化点：直接通过 RGB 创建灰色，省去 HSL 转换的性能消耗
        return DynamicColor(red: l, green: l, blue: l, alpha: a)
    }
    
    /**
     Creates and return a color object where the red, green, and blue values are inverted.
     */
    func inverted() -> DynamicColor {
        let rgba = colorToRGBA()
        return DynamicColor(red: 1.0 - rgba.r, green: 1.0 - rgba.g, blue: 1.0 - rgba.b, alpha: rgba.a)
    }
}

