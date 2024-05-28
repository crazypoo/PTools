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

// MARK: HSB Color Space

public extension DynamicColor {
  // MARK: - Getting the HSB Components

  /**
   Returns the HSB (hue, saturation, brightness) components.

   - returns: The HSB components as a tuple (h, s, b).
   */
    final func colorToHSBA() -> (h: CGFloat, s: CGFloat, b: CGFloat, a:CGFloat) {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0

#if os(iOS) || os(tvOS) || os(watchOS)
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        return (h: h, s: s, b: b, a:a)
#elseif os(OSX)
        if isEqual(DynamicColor.black) {
            return (0.0, 0.0, 0.0,1)
        } else if isEqual(DynamicColor.white) {
            return (0.0, 0.0, 1.0,1)
        }

        getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        return (h: h, s: s, b: b, a:a)
#endif
  }

  #if os(iOS) || os(tvOS) || os(watchOS)
    /**
     The hue component as CGFloat between 0.0 to 1.0.
     */
    final var hueComponent: CGFloat {
        return colorToHSBA().h
    }

    /**
     The saturation component as CGFloat between 0.0 to 1.0.
     */
    final var saturationComponent: CGFloat {
        return colorToHSBA().s
    }

    /**
     The brightness component as CGFloat between 0.0 to 1.0.
     */
    final var brightnessComponent: CGFloat {
        return colorToHSBA().b
    }
  #endif
}

