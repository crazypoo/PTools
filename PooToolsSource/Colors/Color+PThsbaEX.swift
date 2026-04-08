//
//  Color+PThsbaEX.swift
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

// MARK: - HSB Color Space

public extension DynamicColor {
    // MARK: - Getting the HSB Components

    /**
     Returns the HSB (hue, saturation, brightness) components.

     - returns: The HSB components as a tuple (h, s, b, a).
     */
    func colorToHSBA() -> (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0

        #if os(iOS) || os(tvOS) || os(watchOS)
        // iOS/tvOS 底层会自动处理色彩空间转换，直接调用即可
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        #elseif os(OSX)
        // 🚀 macOS 优化：将颜色安全地转换到 RGB 空间，彻底杜绝 Exception 崩溃
        // 替代了原来的 isEqual(.black) 这种打补丁的做法
        if let rgbColor = self.usingColorSpace(.deviceRGB) {
            rgbColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        } else {
            // 如果存在极其特殊的颜色无法转换，返回安全的默认值
            return (0.0, 0.0, 0.0, self.alphaComponent)
        }
        #endif

        return (h: h, s: s, b: b, a: a)
    }

    #if os(iOS) || os(tvOS) || os(watchOS)
    /**
     The hue component as CGFloat between 0.0 to 1.0.
     */
    var hueComponent: CGFloat {
        return colorToHSBA().h
    }

    /**
     The saturation component as CGFloat between 0.0 to 1.0.
     */
    var saturationComponent: CGFloat {
        return colorToHSBA().s
    }

    /**
     The brightness component as CGFloat between 0.0 to 1.0.
     */
    var brightnessComponent: CGFloat {
        return colorToHSBA().b
    }
    #endif
}
