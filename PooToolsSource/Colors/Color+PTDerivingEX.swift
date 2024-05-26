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

     - parameter amount: A float representing the number of degrees as ratio (usually between -360.0 degree and 360.0 degree).
     - returns: A DynamicColor object with the hue changed.
     */
    final func adjustedHue(@PTClampedProperyWrapper(range:-360...360) amount: CGFloat) -> DynamicColor {
        return HSL(color: self).adjustedHue(amount: amount).toDynamicColor()
    }

    /**
     Creates and returns the complement of the color object.

     This is identical to adjustedHue(180).

     - returns: The complement DynamicColor.
     - seealso: adjustedHueColor:
     */
    final func complemented() -> DynamicColor {
        return adjustedHue(amount: 180.0)
    }

    /**
     Creates and returns a color object with the lightness increased by the given amount.

     - parameter amount: CGFloat between 0.0 and 1.0. Default value is 0.2.
     - returns: A lighter DynamicColor.
     */
    final func lighter(@PTClampedProperyWrapper(range:0...1) amount: CGFloat = 0.2) -> DynamicColor {
        return HSL(color: self).lighter(amount: amount).toDynamicColor()
    }

    /**
     Creates and returns a color object with the lightness decreased by the given amount.

     - parameter amount: Float between 0.0 and 1.0. Default value is 0.2.
     - returns: A darker DynamicColor.
     */
    final func darkened(@PTClampedProperyWrapper(range:0...1) amount: CGFloat = 0.2) -> DynamicColor {
        return HSL(color: self).darkened(amount: amount).toDynamicColor()
    }

    /**
     Creates and returns a color object with the saturation increased by the given amount.

     - parameter amount: CGFloat between 0.0 and 1.0. Default value is 0.2.

     - returns: A DynamicColor more saturated.
     */
    final func saturated(@PTClampedProperyWrapper(range:0...1) amount: CGFloat = 0.2) -> DynamicColor {
        return HSL(color: self).saturated(amount: amount).toDynamicColor()
    }

    /**
     Creates and returns a color object with the saturation decreased by the given amount.

     - parameter amount: CGFloat between 0.0 and 1.0. Default value is 0.2.
     - returns: A DynamicColor less saturated.
     */
    final func desaturated(@PTClampedProperyWrapper(range:0...1) amount: CGFloat = 0.2) -> DynamicColor {
        return HSL(color: self).desaturated(amount: amount).toDynamicColor()
    }

    /**
     Creates and returns a color object converted to grayscale.

     - returns: A grayscale DynamicColor.
     - seealso: desaturated:
     */
    final func grayscaled(mode: GrayscalingMode = .lightness) -> DynamicColor {
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

        return HSL(hue: 0.0, saturation: 0.0, lightness: l, alpha: a).toDynamicColor()
    }

    /**
     Creates and return a color object where the red, green, and blue values are inverted, while the alpha channel is left alone.

     - returns: An inverse (negative) of the original color.
     */
    final func inverted() -> DynamicColor {
        let rgba = colorToRGBA()

        let invertedRed   = 1.0 - rgba.r
        let invertedGreen = 1.0 - rgba.g
        let invertedBlue  = 1.0 - rgba.b

        return DynamicColor(red: invertedRed, green: invertedGreen, blue: invertedBlue, alpha: rgba.a)
    }
}

