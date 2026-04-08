//
//  Color+PThslEX.swift
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

// MARK: - HSL Color Space

public extension DynamicColor {
    
    /**
     Initializes and returns a color object using the specified opacity and HSL component values.

     - parameter hue: The hue component of the color object, specified as a value from 0.0 to 360.0 degree.
     - parameter saturation: The saturation component of the color object, specified as a value from 0.0 to 1.0.
     - parameter lightness: The lightness component of the color object, specified as a value from 0.0 to 1.0.
     - parameter alpha: The opacity value of the color object, specified as a value from 0.0 to 1.0. Default to 1.0.
     */
    convenience init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat = 1.0) {
        // ⚠️ 助手提醒：请确保你的 HSL 结构体 init 接收的 hue 是 0~360 的角度值，而不是 0~1 的比例值。
        // 如果 HSL 接收 0~1，这里需要改成 hue: hue / 360.0
        let tempColor = HSL(hue: hue, saturation: saturation, lightness: lightness, alpha: alpha).toDynamicColor()
        let components = tempColor.colorToRGBA()

        self.init(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }

    // MARK: - Getting the HSL Components

    /**
     Returns the HSL (hue, saturation, lightness) and alpha components.

     Note that the hue value is between 0.0 and 360.0 degree.

     - returns: The HSLA components as a tuple (h, s, l, a).
     */
    func toHSLComponents() -> (h: CGFloat, s: CGFloat, l: CGFloat, a: CGFloat) {
        let hsl = HSL(color: self)
        
        // 🚀 优化点 1：补齐了缺失的 alpha 通道
        // 🚀 优化点 2：移除了多余的 final
        return (hsl.h * 360.0, hsl.s, hsl.l, hsl.a)
    }
}
