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
        let rgba = colorToRGBA()
        let maximum = max(rgba.r, max(rgba.g, rgba.b))
        let minimum = min(rgba.r, min(rgba.g, rgba.b))
        let delta = maximum - minimum
        let hue: CGFloat

        if delta == 0 {
            hue = 0
        } else if maximum == rgba.r {
            hue = moda((rgba.g - rgba.b) / delta / 6, m: 1)
        } else if maximum == rgba.g {
            hue = ((rgba.b - rgba.r) / delta + 2) / 6
        } else {
            hue = ((rgba.r - rgba.g) / delta + 4) / 6
        }

        let saturation = maximum == 0 ? 0 : delta / maximum
        return (h: moda(hue, m: 1),
                s: clip(saturation, 0, 1),
                b: clip(maximum, 0, 1),
                a: clip(rgba.a, 0, 1))
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
