//
//  Color+PTMixingEX.swift
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

// MARK: - Mixing Colors

public extension DynamicColor {
    
    /**
     Mixes the given color object with the receiver.
     */
    func mixed(withColor color: DynamicColor, @PTClampedPropertyWrapper(range: 0...1) weight: CGFloat = 0.5, inColorSpace colorspace: DynamicColorSpace = .rgb) -> DynamicColor {
        // 🚀 优化：信任你的 PropertyWrapper，移除多余的 clip()
        
        switch colorspace {
        case .lab:
            return mixedLab(withColor: color, weight: weight)
        case .hsl:
            return mixedHSL(withColor: color, weight: weight)
        case .hsb:
            return mixedHSB(withColor: color, weight: weight)
        case .rgb:
            return mixedRGB(withColor: color, weight: weight)
        }
    }

    /**
     Creates and returns a color object corresponding to the mix of the receiver and an amount of white color.
     */
    func tinted(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat = 0.2) -> DynamicColor {
        return mixed(withColor: .white, weight: amount)
    }

    /**
     Creates and returns a color object corresponding to the mix of the receiver and an amount of black color.
     */
    func shaded(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat = 0.2) -> DynamicColor {
        // 🚀 优化：直接使用 .black，代码更清晰
        return mixed(withColor: .black, weight: amount)
    }

    // MARK: - Convenient Internal Methods

    internal func mixedLab(withColor color: DynamicColor, weight: CGFloat) -> DynamicColor {
        let c1 = toLabComponents()
        let c2 = color.toLabComponents()

        let L = c1.L + (weight * (c2.L - c1.L))
        let a = c1.a + (weight * (c2.a - c1.a))
        let b = c1.b + (weight * (c2.b - c1.b))
        // 🚀 优化：直接使用元组中提取好的 alpha
        let alpha = c1.alpha + (weight * (c2.alpha - c1.alpha))

        return DynamicColor(L: L, a: a, b: b, alpha: alpha)
    }

    internal func mixedHSL(withColor color: DynamicColor, weight: CGFloat) -> DynamicColor {
        let c1 = toHSLComponents()
        let c2 = color.toHSLComponents()

        // HSL 的色相范围是 0...360
        let h = c1.h + (weight * mixedHue(source: c1.h, target: c2.h, maxValue: 360.0))
        let s = c1.s + (weight * (c2.s - c1.s))
        let l = c1.l + (weight * (c2.l - c1.l))
        let alpha = c1.a + (weight * (c2.a - c1.a))

        return DynamicColor(hue: h, saturation: s, lightness: l, alpha: alpha)
    }

    internal func mixedHSB(withColor color: DynamicColor, weight: CGFloat) -> DynamicColor {
        let c1 = colorToHSBA()
        let c2 = color.colorToHSBA()

        // 🚨 修复 Bug：HSB 的色相范围是 0...1.0，传入 1.0 作为最大值
        let h = c1.h + (weight * mixedHue(source: c1.h, target: c2.h, maxValue: 1.0))
        let s = c1.s + (weight * (c2.s - c1.s))
        let b = c1.b + (weight * (c2.b - c1.b))
        let alpha = c1.a + (weight * (c2.a - c1.a))

        // 注意：系统的 init(hue:saturation:brightness:alpha:) 接收的 hue 正好是 0...1.0
        return DynamicColor(hue: h, saturation: s, brightness: b, alpha: alpha)
    }

    internal func mixedRGB(withColor color: DynamicColor, weight: CGFloat) -> DynamicColor {
        let c1 = colorToRGBA()
        let c2 = color.colorToRGBA()

        let red   = c1.r + (weight * (c2.r - c1.r))
        let green = c1.g + (weight * (c2.g - c1.g))
        let blue  = c1.b + (weight * (c2.b - c1.b))
        let alpha = c1.a + (weight * (c2.a - c1.a))

        return DynamicColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    // 🚨 彻底重写修复的 Hue 混合算法
    internal func mixedHue(source: CGFloat, target: CGFloat, maxValue: CGFloat) -> CGFloat {
        let delta = target - source
        let halfValue = maxValue / 2.0
        
        if delta > halfValue {
            // 如果差值大于半圈，说明反向走更近
            return delta - maxValue
        } else if delta < -halfValue {
            // 同理，跨越 0 点反向走更近
            return delta + maxValue
        }
        
        return delta
    }
}
