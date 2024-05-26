//
//  Color+PTlabEX.swift
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

// MARK: CIE L*a*b* Color Space

public extension DynamicColor {
    /**
     Initializes and returns a color object using CIE XYZ color space component values with an observer at 2° and a D65 illuminant.

     Notes that values out of range are clipped.

     - parameter L: The lightness, specified as a value from 0 to 100.0.
     - parameter a: The red-green axis, specified as a value from -128.0 to 127.0.
     - parameter b: The yellow-blue axis, specified as a value from -128.0 to 127.0.
     - parameter alpha: The opacity value of the color object, specified as a value from 0.0 to 1.0. Default to 1.0.
     */
    convenience init(L: CGFloat, a: CGFloat, b: CGFloat, alpha: CGFloat = 1) {
        let clippedL = clip(L, 0.0, 100.0)
        let clippedA = clip(a, -128.0, 127.0)
        let clippedB = clip(b, -128.0, 127.0)

        let normalized = { (c: CGFloat) -> CGFloat in
            pow(c, 3) > 0.008856 ? pow(c, 3) : (c - (16 / 116)) / 7.787
        }

        let preY = (clippedL + 16.0) / 116.0
        let preX = (clippedA / 500.0) + preY
        let preZ = preY - (clippedB / 200.0)

        let X = 95.05 * normalized(preX)
        let Y = 100.0 * normalized(preY)
        let Z = 108.9 * normalized(preZ)

        self.init(X: X, Y: Y, Z: Z, alpha: alpha)
    }

    // MARK: - Getting the L*a*b* Components

    /**
     Returns the Lab (lightness, red-green axis, yellow-blue axis) components.
     It is based on the CIE XYZ color space with an observer at 2° and a D65 illuminant.

     Notes that L values are between 0 to 100.0, a values are between -128 to 127.0 and b values are between -128 to 127.0.

     - returns: The L*a*b* components as a tuple (L, a, b).
     */
    final func toLabComponents() -> (L: CGFloat, a: CGFloat, b: CGFloat) {
        let normalized = { (c: CGFloat) -> CGFloat in
            c > 0.008856 ? pow(c, 1.0 / 3.0) : (7.787 * c) + (16.0 / 116.0)
        }

        let xyz         = colorToXYZ()
        let normalizedX = normalized(xyz.X / 95.05)
        let normalizedY = normalized(xyz.Y / 100.0)
        let normalizedZ = normalized(xyz.Z / 108.9)

        let L = roundDecimal((116.0 * normalizedY) - 16.0, precision: 1000)
        let a = roundDecimal(500.0 * (normalizedX - normalizedY), precision: 1000)
        let b = roundDecimal(200.0 * (normalizedY - normalizedZ), precision: 1000)

        return (L: L, a: a, b: b)
    }
}

