//
//  PTColorHSL.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import SwiftUI

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

/// Hue-saturation-lightness structure to make the color manipulation easier.
internal struct HSL {
    /// Hue value between 0.0 and 1.0 (0.0 = 0 degree, 1.0 = 360 degree).
    var h: CGFloat = 0.0
    /// Saturation value between 0.0 and 1.0.
    var s: CGFloat = 0.0
    /// Lightness value between 0.0 and 1.0.
    var l: CGFloat = 0.0
    /// Alpha value between 0.0 and 1.0.
    var a: CGFloat = 1.0

    // MARK: - Initializing HSL Colors

    /**
    Initializes and creates a HSL color from the hue, saturation, lightness and alpha components.

    - parameter h: The hue component of the color object, specified as a value between 0.0 and 360.0 degree.
    - parameter s: The saturation component of the color object, specified as a value between 0.0 and 1.0.
    - parameter l: The lightness component of the color object, specified as a value between 0.0 and 1.0.
    - parameter a: The opacity component of the color object, specified as a value between 0.0 and 1.0.
    */
    init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat = 1.0) {
        h = hue.truncatingRemainder(dividingBy: 360.0) / 360.0
        s = clip(saturation, 0.0, 1.0)
        l = clip(lightness, 0.0, 1.0)
        a = clip(alpha, 0.0, 1.0)
    }

    /**
    Initializes and creates a HSL (hue, saturation, lightness) color from a DynamicColor object.
    
    - parameter color: A DynamicColor object.
    */
    init(color: DynamicColor) {
        let rgba = color.colorToRGBA()

        let maximum   = max(rgba.r, max(rgba.g, rgba.b))
        let minimum = min(rgba.r, min(rgba.g, rgba.b))

        let delta = maximum - minimum

        h = 0.0
        s = 0.0
        l = (maximum + minimum) / 2.0

        if delta != 0.0 {
          if l < 0.5 {
            s = delta / (maximum + minimum)
          }
          else {
            s = delta / (2.0 - maximum - minimum)
          }

          if rgba.r == maximum {
            h = ((rgba.g - rgba.b) / delta) + (rgba.g < rgba.b ? 6.0 : 0.0)
          }
          else if rgba.g == maximum {
            h = ((rgba.b - rgba.r) / delta) + 2.0
          }
          else if rgba.b == maximum {
            h = ((rgba.r - rgba.g) / delta) + 4.0
          }
        }

        h /= 6.0
        a = rgba.a
    }

    // MARK: - Transforming HSL Color

    /**
    Returns the DynamicColor representation from the current HSV color.
    
    - returns: A DynamicColor object corresponding to the current HSV color.
    */
    func toDynamicColor() -> DynamicColor {
        let  (r, g, b, a) = rgbaComponents()

        return DynamicColor(red: r, green: g, blue: b, alpha: a)
    }

    /// Returns the RGBA components  from the current HSV color.
    func rgbaComponents() -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let m2 = l <= 0.5 ? l * (s + 1.0) : (l + s) - (l * s)
        let m1 = (l * 2.0) - m2

        let r = hueToRGB(m1: m1, m2: m2, h: h + (1.0 / 3.0))
        let g = hueToRGB(m1: m1, m2: m2, h: h)
        let b = hueToRGB(m1: m1, m2: m2, h: h - (1.0 / 3.0))
        
        return (r, g, b, CGFloat(a))
    }

    /// Hue to RGB helper function
    private func hueToRGB(m1: CGFloat, m2: CGFloat, h: CGFloat) -> CGFloat {
        let hue = moda(h, m: 1)

        if hue * 6 < 1.0 {
            return m1 + ((m2 - m1) * hue * 6.0)
        }
        else if hue * 2.0 < 1.0 {
            return m2
        }
        else if hue * 3.0 < 1.9999 {
            return m1 + ((m2 - m1) * ((2.0 / 3.0) - hue) * 6.0)
        }

        return m1
    }

    // MARK: - Deriving the Color

    /**
    Returns a color with the hue rotated along the color wheel by the given amount.

    - parameter amount: A float representing the number of degrees as ratio (usually between -360.0 degree and 360.0 degree).
    - returns: A HSL color with the hue changed.
    */
    func adjustedHue(@PTClampedProperyWrapper(range:-360...360) amount: CGFloat) -> HSL {
        return HSL(hue: (h * 360.0) + amount, saturation: s, lightness: l, alpha: a)
    }

    /**
    Returns a color with the lightness increased by the given amount.

    - parameter amount: CGFloat between 0.0 and 1.0.
    - returns: A lighter HSL color.
    */
    func lighter(@PTClampedProperyWrapper(range:0...1) amount: CGFloat) -> HSL {
        return HSL(hue: h * 360.0, saturation: s, lightness: l + amount, alpha: a)
    }

    /**
    Returns a color with the lightness decreased by the given amount.

    - parameter amount: CGFloat between 0.0 and 1.0.
    - returns: A darker HSL color.
    */
    func darkened(@PTClampedProperyWrapper(range:0...1) amount: CGFloat) -> HSL {
        return lighter(amount: amount * -1.0)
    }

    /**
    Returns a color with the saturation increased by the given amount.

    - parameter amount: CGFloat between 0.0 and 1.0.
    - returns: A HSL color more saturated.
    */
    func saturated(@PTClampedProperyWrapper(range:0...1) amount: CGFloat) -> HSL {
        return HSL(hue: h * 360.0, saturation: s + amount, lightness: l, alpha: a)
    }

    /**
    Returns a color with the saturation decreased by the given amount.

    - parameter amount: CGFloat between 0.0 and 1.0.
    - returns: A HSL color less saturated.
    */
    func desaturated(@PTClampedProperyWrapper(range:0...1) amount: CGFloat) -> HSL {
        return saturated(amount: amount * -1.0)
    }
}

extension HSL {
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    func toColor() -> Color {
        let (r, g, b, a) = rgbaComponents()
        return SwiftUI.Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}
