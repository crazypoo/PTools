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

// MARK: HSL Color Space

extension DynamicColor {
    /**
     Initializes and returns a color object using the specified opacity and HSL component values.

     - parameter hue: The hue component of the color object, specified as a value from 0.0 to 360.0 degree.
     - parameter saturation: The saturation component of the color object, specified as a value from 0.0 to 1.0.
     - parameter lightness: The lightness component of the color object, specified as a value from 0.0 to 1.0.
     - parameter alpha: The opacity value of the color object, specified as a value from 0.0 to 1.0. Default to 1.0.
     */
    public convenience init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat = 1) {
        let color      = HSL(hue: hue, saturation: saturation, lightness: lightness, alpha: alpha).toDynamicColor()
        let components = color.colorToRGBA()

        self.init(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }

    // MARK: - Getting the HSL Components

    /**
     Returns the HSL (hue, saturation, lightness) components.

     Notes that the hue value is between 0.0 and 360.0 degree.

     - returns: The HSL components as a tuple (h, s, l).
     */
    public final func toHSLComponents() -> (h: CGFloat, s: CGFloat, l: CGFloat) {
        let hsl = HSL(color: self)

        return (hsl.h * 360.0, hsl.s, hsl.l)
    }
}
