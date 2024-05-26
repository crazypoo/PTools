//
//  PTDynamicGradient.swift
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
/**
 Object representing a gradient object. It allows you to manipulate colors inside different gradients and color spaces.
 */
final public class PTDynamicGradient {
    let colors: [DynamicColor]

    /**
     Initializes and creates a gradient from a color array.

     - Parameter colors: An array of colors.
     */
    public init(colors: [DynamicColor]) {
        self.colors = colors
    }

    /**
     Returns the color palette of `amount` elements by grabbing equidistant colors.

     - Parameter amount: An amount of colors to return. 2 by default.
     - Parameter colorspace: The color space used to mix the colors. By default it uses the RBG color space.
     - Returns: An array of DynamicColor objects with equi-distant space in the gradient.
     */
    public func colorPalette(@PTClampedProperyWrapper(range:2...UInt.max) amount: UInt = 2, inColorSpace colorspace: DynamicColorSpace = .rgb) -> [DynamicColor] {
        
        guard amount > 0 && colors.count > 0 else {
            return []
        }

        guard colors.count > 1 else {
            return (0 ..< amount).map { _ in colors[0] }
        }

        let increment = 1.0 / CGFloat(amount - 1)

        return (0 ..< amount).map { pickColorAt(scale: CGFloat($0) * increment, inColorSpace: colorspace) }
    }

    /**
     Picks up and returns the color at the given scale by interpolating the colors.

     For example, given this color array `[red, green, blue]` and a scale of `0.25` you will get a kaki color.

     - Parameter scale: A float value between 0.0 and 1.0.
     - Parameter colorspace: The color space used to mix the colors. By default it uses the RBG color space.
     - Returns: A DynamicColor object corresponding to the color at the given scale.
     */
    public func pickColorAt(@PTClampedProperyWrapper(range:0...1) scale: CGFloat, inColorSpace colorspace: DynamicColorSpace = .rgb) -> DynamicColor {
        guard colors.count > 1 else {
            return colors.first ?? .black
        }

        let clippedScale = clip(scale, 0.0, 1.0)
        let positions    = (0 ..< colors.count).map { CGFloat($0) / CGFloat(colors.count - 1) }

        var color: DynamicColor = .black

        for (index, position) in positions.enumerated() {
            guard clippedScale <= position else { continue }

            guard clippedScale != 0.0 && clippedScale != 1.0 else {
              return colors[index]
            }

            let previousPosition = positions[index - 1]
            let weight           = (clippedScale - previousPosition) / (position - previousPosition)

            color = colors[index - 1].mixed(withColor: colors[index], weight: weight, inColorSpace: colorspace)

            break
        }

        return color
    }
}
