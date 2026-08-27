//
//  Color+PTDynamicEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import SwiftUI

/**
 Defines the supported color spaces.
 */
public enum DynamicColorSpace: Sendable {
  /// The RGB color space
  case rgb
  /// The HSL color space
  case hsl
  /// The HSB color space
  case hsb
  /// The Cie L*a*b* color space
  case lab
}

@objc public enum ColorDistanceType:Int {
    case CIE76
    case CIE94
    case CIE2000
}

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

  /**
   Extension to manipulate colours easily.

   It allows you to work hexadecimal strings and value, HSV and RGB components, derivating colours, and many more...
   */
  public typealias DynamicColor = UIColor
#elseif os(OSX)
import AppKit

  /**
   Extension to manipulate colours easily.

   It allows you to work hexadecimal strings and value, HSV and RGB components, derivating colours, and many more...
   */
  public typealias DynamicColor = NSColor
#endif

public extension DynamicColor {
    // MARK: - Manipulating Hexa-decimal Values and Strings

    /**
     Creates a color from an hex string (e.g. "#3498db"). The RGBA string are also supported (e.g. "#3498dbff").

     If the given hex string is invalid the initialiser will create a black color.

     - parameter hexString: A hexa-decimal color string representation.
     */
    convenience init?(hexString: String) {
        guard let value = PTHexColorParser.parse(hexString) else {
            self.init(hex: 0x000000)
            return
        }

        self.init(red: value.components.red,
                  green: value.components.green,
                  blue: value.components.blue,
                  alpha: value.components.alpha)
    }

    /**
     Creates a color from an hex integer (e.g. 0x3498db).

     - parameter hex: A hexa-decimal UInt64 that represents a color.
     - parameter alphaChannel: If true the given hex-decimal UInt64 includes the alpha channel (e.g. 0xFF0000FF).
     */
    convenience init(hex: UInt64, useAlpha alphaChannel: Bool = false) {
        let mask      = UInt64(0xFF)
        let cappedHex = !alphaChannel && hex > 0xffffff ? 0xffffff : hex

        let r = cappedHex >> (alphaChannel ? 24 : 16) & mask
        let g = cappedHex >> (alphaChannel ? 16 : 8) & mask
        let b = cappedHex >> (alphaChannel ? 8 : 0) & mask
        let a = alphaChannel ? cappedHex & mask : 255

        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        let alpha = CGFloat(a) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /**
     Returns the color representation as an integer (without the alpha channel).

     - returns: A UInt32 that represents the hexa-decimal color.
     */
    final func toHex() -> UInt32 {
        let rgba = colorToRGBA()
      
        return roundToHex(rgba.r) << 16 | roundToHex(rgba.g) << 8 | roundToHex(rgba.b)
    }
    
    /**
     Returns the RGBA color representation.
     
     - returns: A UInt32 that represents the color as an RGBA value.
     */
    func toRGBA() -> UInt32 {
        let rgba = colorToRGBA()

        return roundToHex(rgba.r) << 24 | roundToHex(rgba.g) << 16 | roundToHex(rgba.b) << 8 | roundToHex(rgba.a)
    }
    
    /**
     Returns the AGBR color representation.
     
     - returns: A UInt32 that represents the color as an AGBR value.
     */
    func toAGBR() -> UInt32 {
        let rgba = colorToRGBA()
      
        return roundToHex(rgba.a) << 24 | roundToHex(rgba.b) << 16 | roundToHex(rgba.g) << 8 | roundToHex(rgba.r)
    }

    // MARK: - Identifying and Comparing Colors

    /**
     Returns a boolean value that indicates whether the receiver is equal to the given hexa-decimal string.

     - parameter hexString: A hexa-decimal color number representation to be compared to the receiver.
     - returns: true if the receiver and the string are equals, otherwise false.
     */
    func isEqual(toHexString hexString: String) -> Bool {
        guard let value = PTHexColorParser.parse(hexString) else { return false }
        let current = colorToRGBA()
        let currentComponents = PTRGBAComponents(red: current.r,
                                                  green: current.g,
                                                  blue: current.b,
                                                  alpha: current.a)
        guard currentComponents.red == value.components.red,
              currentComponents.green == value.components.green,
              currentComponents.blue == value.components.blue else {
            return false
        }
        return !value.includesAlpha || currentComponents.alpha == value.components.alpha
    }

    /**
     Returns a boolean value that indicates whether the receiver is equal to the given hexa-decimal integer.

     - parameter hex: A UInt32 that represents the hexa-decimal color.
     - returns: true if the receiver and the integer are equals, otherwise false.
     */
    func isEqual(toHex hex: UInt32) -> Bool {
        return self.toHex() == hex
    }

    // MARK: - Querying Colors

    /**
     Determines if the color object is dark or light.

     It is useful when you need to know whether you should display the text in black or white.

     - returns: A boolean value to know whether the color is light. If true the color is light, dark otherwise.
     */
    func isLight() -> Bool {
        let components = colorToRGBA()
        let brightness = ((components.r * 299.0) + (components.g * 587.0) + (components.b * 114.0)) / 1000.0

        return brightness >= 0.5
    }

    /**
     A float value representing the luminance of the current color. May vary from 0 to 1.0.
     
     We use the formula described by W3C in WCAG 2.0. You can read more here: https://www.w3.org/TR/WCAG20/#relativeluminancedef.
    */
    var luminance: CGFloat {
        let components = colorToRGBA()
        func linearize(_ value: CGFloat) -> CGFloat {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        return (0.2126 * linearize(components.r))
            + (0.7152 * linearize(components.g))
            + (0.0722 * linearize(components.b))
    }

    /**
       Returns a float value representing the contrast ratio between 2 colors.
       
       We use the formula described by W3C in WCAG 2.0. You can read more here: https://www.w3.org/TR/WCAG20-TECHS/G18.html
       NB: the contrast ratio is a relative value. So the contrast between Color1 and Color2 is exactly the same between Color2 and Color1.
       
       - returns: A CGFloat representing contrast value.
       */
    func contrastRatio(with otherColor: DynamicColor) -> CGFloat {
        let otherLuminance = otherColor.luminance

        let l1 = max(luminance, otherLuminance)
        let l2 = min(luminance, otherLuminance)

        return (l1 + 0.05) / (l2 + 0.05)
    }

    /**
     Indicates if two colors are contrasting, regarding W3C's WCAG 2.0 recommendations.
     
     You can read it here: https://www.w3.org/TR/2008/REC-WCAG20-20081211/#visual-audio-contrast-contrast
     
     The acceptable contrast ratio depends on the context of display. Most of the time, the default context (.Standard) is enough.
     
     You can look at ContrastDisplayContext for more options.
     
     - parameter otherColor: The other color to compare with.
     - parameter context: An optional context to determine the minimum acceptable contrast ratio. Default value is .Standard.
     
     - returns: true is the contrast ratio between 2 colors exceed the minimum acceptable ratio.
     */
    func isContrasting(with otherColor: DynamicColor, inContext context: ContrastDisplayContext = .standard) -> Bool {
        return self.contrastRatio(with: otherColor) >= context.minimumContrastRatio
    }
    
    /**
      Using like secondary color usually for background of colorful element.
     
     - parameter background: Pass color of background of element.
     - important: In design for tint color get 6% alpha.
     Also color depended of background, so it reason why it requerid.
     */
    var secondary:DynamicColor {
        withAlphaComponent(0.06)
    }
    
#if !os(watchOS)
    /**
      Wrapper of destructive actions color.
     */
    static var destructiveColor: DynamicColor { .systemRed }
#endif

#if !os(watchOS)
    /**
      Wrapper of warning actions color.
     */
    static var warningColor: DynamicColor { .systemOrange }
#endif

#if os(iOS)
    /**
      New color to system stack.
     Its color for empty areas and it usually downed of main background color.
     */
    static var systemDownedBackground: DynamicColor {
        let lightTrait = UITraitCollection(userInterfaceStyle: .light)
        let darkTrait = UITraitCollection(userInterfaceStyle: .dark)
        let lightBackground = UIColor.secondarySystemBackground.resolvedColor(with: lightTrait)
        let darkBackground = UIColor.secondarySystemBackground.resolvedColor(with: darkTrait)
        let lightColor = lightBackground.mixed(withColor: .darkGray, weight: 0.09)
            .mixed(withColor: .systemBlue, weight: 0.01)
        let darkColor = darkBackground
        return DynamicColor(light: lightColor, dark: darkColor)
    }
#endif

    // MARK: 深色模式和浅色模式颜色设置，非layer颜色设置
    /// 深色模式和浅色模式颜色设置，非layer颜色设置
    /// - Parameters:
    ///   - lightColor: 浅色模式的颜色
    ///   - darkColor: 深色模式的颜色
    /// - Returns: 返回一个颜色（UIColor）
#if !os(watchOS)
    static func darkModeColor(lightColor: DynamicColor,
                              darkColor: DynamicColor) -> DynamicColor {
        return DynamicColor { (traitCollection) -> DynamicColor in
             if traitCollection.userInterfaceStyle == .dark {
                 return darkColor
             } else {
                 return lightColor
             }
         }
   }
#endif

#if !os(watchOS) && !os(tvOS)
    convenience init(baseInterfaceLevel: DynamicColor, elevatedInterfaceLevel: DynamicColor ) {
        self.init { traitCollection in
            switch traitCollection.userInterfaceLevel {
            case .base:
                return baseInterfaceLevel
            case .elevated:
                return elevatedInterfaceLevel
            case .unspecified:
                return baseInterfaceLevel
            @unknown default:
                return baseInterfaceLevel
            }
        }
    }
#endif

#if !os(watchOS)
    static var systemColorfulColors: [DynamicColor] {
        return [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemTeal, .systemBlue, .systemIndigo, .systemPink, .systemPurple]
    }
#endif

    func cielabColorArray() -> (l: CGFloat, a: CGFloat, b: CGFloat, alpha: CGFloat) {
        let lab = toLabComponents()
        return (l: lab.L, a: lab.a, b: lab.b, alpha: lab.alpha)
    }
    
    //MARK: Color from LAB Array
    ///Color from LAB Array
    class func cielabColor(cielabData:[CGFloat])->DynamicColor {
        guard cielabData.count >= 4 else { return .clear }
        return DynamicColor(L: cielabData[0],
                            a: cielabData[1],
                            b: cielabData[2],
                            alpha: cielabData[3])
    }
    
    /**
     *
     *  Detecting a difference in two colors is not as trivial as it sounds.
     *  One's first instinct is to go for a difference in RGB values, leaving
     *  you with a sum of the differences of each point. It looks great! Until
     *  you actually start comparing colors. Why do these two reds have a different
     *  distance than these two blues *in real life* vs computationally?
     *  Human visual perception is next in the line of things between a color
     *  and your brain. Some colors are just perceived to have larger variants inside
     *  of their respective areas than others, so we need a way to model this
     *  human variable to colors. Enter CIELAB. This color formulation is supposed to be
     *  this model. So now we need to standardize a unit of distance between any two
     *  colors that works independent of how humans visually perceive that distance.
     *  Enter CIE76,94,2000. These are methods that use user-tested data and other
     *  mathematically and statistically significant correlations to output this info.
     *  You can read the wiki articles below to get a better understanding historically
     *  of how we moved to newer and better color distance formulas, and what
     *  their respective pros/cons are.
     *
     *  References:
     *
     *  http://en.wikipedia.org/wiki/Color_difference
     *  http://en.wikipedia.org/wiki/Just_noticeable_difference
     *  http://en.wikipedia.org/wiki/CIELAB
     *
     */
    
    func RAD(degree:CGFloat) -> CGFloat {
        degree * .pi / 180
    }
    
    func colorDistance(color:UIColor,
                       type:ColorDistanceType) -> CGFloat {
        let lab1 = toLabComponents()
        let lab2 = color.toLabComponents()
        let L1 = lab1.L
        let A1 = lab1.a
        let B1 = lab1.b
        let L2 = lab2.L
        let A2 = lab2.a
        let B2 = lab2.b

        let deltaL = L1 - L2
        let deltaA = A1 - A2
        let deltaB = B1 - B2
        let chroma1 = sqrt((A1 * A1) + (B1 * B1))
        let chroma2 = sqrt((A2 * A2) + (B2 * B2))
        let deltaChroma = chroma1 - chroma2

        if type == .CIE76 {
            let squaredDistance = (deltaL * deltaL) + (deltaA * deltaA) + (deltaB * deltaB)
            return sqrt(max(0, squaredDistance))
        }

        let deltaHueSquared = max(0, (deltaA * deltaA) + (deltaB * deltaB) - (deltaChroma * deltaChroma))
        let deltaHue = sqrt(deltaHueSquared)
        let lightnessWeight: CGFloat = 1
        let chromaWeight: CGFloat = 1
        let hueWeight: CGFloat = 1

        if type == .CIE94 {
            let lightnessScale: CGFloat = 1
            let chromaScale = 1 + 0.045 * chroma1
            let hueScale = 1 + 0.015 * chroma1
            let squaredDistance = pow(deltaL / (lightnessWeight * lightnessScale), 2)
                + pow(deltaChroma / (chromaWeight * chromaScale), 2)
                + pow(deltaHue / (hueWeight * hueScale), 2)
            return sqrt(max(0, squaredDistance))
        }

        let twoPi = 2 * CGFloat.pi
        let pi = CGFloat.pi
        let meanChroma = (chroma1 + chroma2) / 2
        let meanChromaPower = pow(meanChroma, 7)
        let twentyFivePower = pow(CGFloat(25), 7)
        let compensation = 0.5 * (1 - sqrt(meanChromaPower / (meanChromaPower + twentyFivePower)))
        let aPrime1 = (1 + compensation) * A1
        let aPrime2 = (1 + compensation) * A2
        let chromaPrime1 = sqrt((aPrime1 * aPrime1) + (B1 * B1))
        let chromaPrime2 = sqrt((aPrime2 * aPrime2) + (B2 * B2))

        func hue(_ blue: CGFloat, _ redGreen: CGFloat) -> CGFloat {
            let angle = atan2(blue, redGreen)
            return angle >= 0 ? angle : angle + twoPi
        }

        let huePrime1 = chromaPrime1 == 0 ? 0 : hue(B1, aPrime1)
        let huePrime2 = chromaPrime2 == 0 ? 0 : hue(B2, aPrime2)
        let deltaHuePrime: CGFloat
        if chromaPrime1 == 0 || chromaPrime2 == 0 {
            deltaHuePrime = 0
        } else if abs(huePrime2 - huePrime1) <= pi {
            deltaHuePrime = huePrime2 - huePrime1
        } else if huePrime2 <= huePrime1 {
            deltaHuePrime = huePrime2 - huePrime1 + twoPi
        } else {
            deltaHuePrime = huePrime2 - huePrime1 - twoPi
        }

        let deltaLightnessPrime = L2 - L1
        let deltaChromaPrime = chromaPrime2 - chromaPrime1
        let deltaHueComponent = 2 * sqrt(chromaPrime1 * chromaPrime2) * sin(deltaHuePrime / 2)
        let meanLightness = (L1 + L2) / 2
        let meanChromaPrime = (chromaPrime1 + chromaPrime2) / 2
        let meanHuePrime: CGFloat
        if chromaPrime1 == 0 || chromaPrime2 == 0 {
            meanHuePrime = huePrime1 + huePrime2
        } else if abs(huePrime1 - huePrime2) <= pi {
            meanHuePrime = (huePrime1 + huePrime2) / 2
        } else if huePrime1 + huePrime2 < twoPi {
            meanHuePrime = (huePrime1 + huePrime2 + twoPi) / 2
        } else {
            meanHuePrime = (huePrime1 + huePrime2 - twoPi) / 2
        }

        let meanHueDegrees = meanHuePrime * 180 / pi
        let hueTerm = 1
            - 0.17 * cos(meanHuePrime - RAD(degree: 30))
            + 0.24 * cos(2 * meanHuePrime)
            + 0.32 * cos(3 * meanHuePrime + RAD(degree: 6))
            - 0.20 * cos(4 * meanHuePrime - RAD(degree: 63))
        let lightnessScale = 1 + 0.015 * pow(meanLightness - 50, 2)
            / sqrt(20 + pow(meanLightness - 50, 2))
        let chromaScale = 1 + 0.045 * meanChromaPrime
        let hueScale = 1 + 0.015 * meanChromaPrime * hueTerm
        let deltaTheta = 30 * exp(-pow((meanHueDegrees - 275) / 25, 2))
        let chromaRotation = 2 * sqrt(pow(meanChromaPrime, 7)
            / (pow(meanChromaPrime, 7) + twentyFivePower))
        let rotation = -chromaRotation * sin(RAD(degree: 2 * deltaTheta))

        let lightnessTerm = deltaLightnessPrime / (lightnessWeight * lightnessScale)
        let chromaTerm = deltaChromaPrime / (chromaWeight * chromaScale)
        let hueTermValue = deltaHueComponent / (hueWeight * hueScale)
        let squaredDistance = (lightnessTerm * lightnessTerm)
            + (chromaTerm * chromaTerm)
            + (hueTermValue * hueTermValue)
            + rotation * chromaTerm * hueTermValue
        return sqrt(max(0, squaredDistance))
    }
    
    //MARK: 返回随机颜色
    ///返回随机颜色
    @objc class var randomColor:DynamicColor {
        get {
            DynamicColor.randomColorWithAlpha(alpha: 1)
        }
    }
    
    @objc class func randomColorWithAlpha(alpha:CGFloat) -> DynamicColor {
        return DynamicColor(red: CGFloat.random(in: 0...1),
                            green: CGFloat.random(in: 0...1),
                            blue: CGFloat.random(in: 0...1),
                            alpha: alpha
        )
    }
    
    @objc class var DevMaskColor:DynamicColor {
        DynamicColor(r: 0, g: 0, b: 0, a: 0.15)
    }
    
#if os(iOS)
    //MARK: 顏色轉圖片
    ///顏色轉圖片
    @objc func createImageWithColor() -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { context in
            context.cgContext.setFillColor(self.cgColor)
            context.cgContext.fill(rect)
        }
    }
#endif
}

/**
 Convenient extension for color array to work as a DynamicGradient.
 */
public extension Array where Element: DynamicColor {
    /**
     Gradient representation of the array.
     */
    var gradient: PTDynamicGradient {
        return PTDynamicGradient(colors: self)
    }
}

/// Convert a DynamicColor to a  SwiftUI color
extension DynamicColor {
    /**
    Returns the Color from  an Dynamic Color.
    
    - returns: A Color (SwiftUI).
    */
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    func toColor() -> Color {
        return Color(self)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension Color {
    // MARK: - Manipulating Hexa-decimal Values and Strings

    /**
     Creates a color from an hex string (e.g. "#3498db"). The RGBA string are also supported (e.g. "#3498dbff").

     If the given hex string is invalid the initialiser will create a black color.

     - parameter hexString: A hexa-decimal color string representation.
     */
    init(hexString: String) {
        guard let value = PTHexColorParser.parse(hexString) else {
            self.init(red: 0, green: 0, blue: 0, opacity: 1)
            return
        }

        self.init(red: Double(value.components.red),
                  green: Double(value.components.green),
                  blue: Double(value.components.blue),
                  opacity: Double(value.components.alpha))
    }

    /**
     Creates a color from an hex integer (e.g. 0x3498db).

     - parameter hex: A hexa-decimal UInt64 that represents a color.
     - parameter opacityChannel: If true the given hex-decimal UInt64 includes the opacity channel (e.g. 0xFF0000FF).
     */
    init(hex: UInt64, useOpacity opacityChannel: Bool = false) {
        let mask      = UInt64(0xFF)
        let cappedHex = !opacityChannel && hex > 0xffffff ? 0xffffff : hex

        let r = cappedHex >> (opacityChannel ? 24 : 16) & mask
        let g = cappedHex >> (opacityChannel ? 16 : 8) & mask
        let b = cappedHex >> (opacityChannel ? 8 : 0) & mask
        let o = opacityChannel ? cappedHex & mask : 255

        let red     = Double(r) / 255.0
        let green   = Double(g) / 255.0
        let blue    = Double(b) / 255.0
        let opacity = Double(o) / 255.0

        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
}
