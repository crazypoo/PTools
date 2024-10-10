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
public enum DynamicColorSpace {
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
        let hexString                 = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner                   = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")

        var color: UInt64 = 0

        if scanner.scanHexInt64(&color) {
            self.init(hex: color, useAlpha: hexString.count > 7)
        } else {
            self.init(hex: 0x000000)
        }
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
        return self.toHexString == hexString
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

        let componentsArray = [components.r, components.g, components.b].map { (val) -> CGFloat in
            guard val <= 0.03928 else { return pow((val + 0.055) / 1.055, 2.4) }

            return val / 12.92
        }

        return (0.2126 * componentsArray[0]) + (0.7152 * componentsArray[1]) + (0.0722 * componentsArray[2])
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
        return self.contrastRatio(with: otherColor) > context.minimumContrastRatio
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
    @available(iOS 13.0, *)
    static var systemDownedBackground: DynamicColor {
        let lightColor = UIColor.secondarySystemBackground.mixed(withColor: .darkGray,weight: 0.09).mixed(withColor: .systemBlue, weight: 0.01)
        let darkColor = UIColor.secondarySystemBackground
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
        if #available(iOS 13.0,tvOS 13.0, *) {
          return DynamicColor { (traitCollection) -> DynamicColor in
               if traitCollection.userInterfaceStyle == .dark {
                   return darkColor
               } else {
                   return lightColor
               }
           }
       } else {
          return lightColor
       }
   }
#endif

#if !os(watchOS) && !os(tvOS)
    convenience init(baseInterfaceLevel: DynamicColor, elevatedInterfaceLevel: DynamicColor ) {
        if #available(iOS 13.0, tvOS 13.0, *) {
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
        else {
            self.init(cgColor: baseInterfaceLevel.cgColor)
        }
    }
#endif

#if !os(watchOS)
    static var systemColorfulColors: [DynamicColor] {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemTeal, .systemBlue, .systemIndigo, .systemPink, .systemPurple]
        } else {
            return [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemTeal, .systemBlue, .systemPink, .systemPurple]
        }
    }
#endif

    func cielabColorArray()->[NSNumber] {
        var R = colorToRGBA().r
        var G = colorToRGBA().g
        var B = colorToRGBA().b
        
        let deltaRGB: (CGFloat) -> CGFloat = {
            ($0 > 0.04045) ? pow(($0 + 0.055) / 1.055, 2.4) : ($0 / 12.92)
        }
        R = deltaRGB(R)
        G = deltaRGB(G)
        B = deltaRGB(B)

        var X = R * 41.24 + G * 35.76 + B * 18.05
        var Y = R * 21.26 + G * 71.52 + B * 7.22
        var Z = R * 1.93 + G * 11.92 + B * 95.05
        
        X = X / 95.047
        Y = Y / 100
        Z = Z / 108.883
        
        
        let sideA:CGFloat = (1.0 / 3.0)
        let sideB:CGFloat = (4.0 / 29.0)
        let deltaF: (CGFloat) -> CGFloat = {
            ($0 > pow((6.0 / 29.0), 3.0)) ? pow($0, 1.0 / 3.0) : (sideA * pow((29.0 / 6.0), 2.0) * $0 + sideB)
        }
        X = deltaF(X)
        Y = deltaF(Y)
        Z = deltaF(Z)
        
        let L:NSNumber = NSNumber(floatLiteral: (116 * Y - 16))
        let A:NSNumber = NSNumber(floatLiteral: (500 * (X - Y)))
        let b:NSNumber = NSNumber(floatLiteral: (200 * (Y - Z)))
        return [L,A,b,NSNumber(floatLiteral: colorAValue)]
    }
    
    //MARK: Color from LAB Array
    ///Color from LAB Array
    class func cielabColor(cielabData:[CGFloat])->DynamicColor {
        if cielabData.count < 4 {
            return .clear
        }
        
        let L:CGFloat = cielabData[0]
        let A:CGFloat = cielabData[1]
        let B:CGFloat = cielabData[2]
        var Y:CGFloat = (L + 16) / 116
        var X:CGFloat = A / 500 + Y
        var Z:CGFloat = Y - B / 200
        
        let deltaXYZ: (CGFloat) -> CGFloat = {
            ($0 > 0.008856) ? pow($0, 3.0) : ($0 - 4 / 29.0) / 7.787
        }
        
        X = deltaXYZ(X) * 0.95047
        Y = deltaXYZ(Y) * 1.00000
        Z = deltaXYZ(Z) * 1.08883
        
        var R:CGFloat = X * 3.2406 + Y * (-1.5372) + Z * (-0.4986)
        var G:CGFloat = X * (-0.9689) + Y * 1.8758 + Z * 0.0415
        var _B:CGFloat = X * 0.0557 + Y * (-0.2040) + Z * 1.0570
        
        let deltaRGB: (CGFloat) -> CGFloat = {
            ($0 > 0.0031308) ? 1.055 * (pow($0, (1 / 2.4))) - 0.055 : $0 * 12.92
        }
        
        R = deltaRGB(R)
        G = deltaRGB(G)
        _B = deltaRGB(_B)
        return DynamicColor(r: R, g: G, b: B, a: cielabData[3])
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
    
    func RAD(degree:CGFloat)->CGFloat {
        degree * .pi / 180
    }
    
    func colorDistance(color:UIColor,
                       type:ColorDistanceType)->CGFloat {
        let lab1 = cielabColorArray()
        let lab2 = color.cielabColorArray()
        
        let L1:CGFloat = CGFloat(lab1[0].floatValue)
        let A1:CGFloat = CGFloat(lab1[1].floatValue)
        let B1:CGFloat = CGFloat(lab1[2].floatValue)

        let L2:CGFloat = CGFloat(lab2[0].floatValue)
        let A2:CGFloat = CGFloat(lab2[1].floatValue)
        let B2:CGFloat = CGFloat(lab2[2].floatValue)

        if type == .CIE76 {
            let distance:CGFloat = CGFloat(sqrtf(Float(pow((L1 - L2), 2.0) + pow((A1 - A2), 2.0) + pow((B1 - B2), 2.0))))
            return distance
        }
        
        let kL:CGFloat = 1
        let kC:CGFloat = 1
        let kH:CGFloat = 1
        let k1:CGFloat = 0.045
        let k2:CGFloat = 0.015
        let deltaL = L1 - L2
        let C1 = sqrt((A1 * A1) + (B1 * B1))
        let C2 = sqrt((A2 * A2) + (B2 * B2))
        let deltaC = C1 - C2
        let deltaH = sqrt(pow((A1 - A2), 2) + pow((B1 - B2), 2.0) - pow(deltaC, 2.0))
        var sL:CGFloat = 1
        var sC:CGFloat = 1 + k1 * (sqrt((A1 * A1) + (B1 * B1)))
        var sH:CGFloat = 1 + k2 * (sqrt((A1 * A1) + (B1 * B1)))
        
        if type == .CIE94 {
            let distance:CGFloat = sqrt(pow((deltaL / (kL * sL)), 2.0) + pow((deltaC / (kC * sC)), 2.0) + pow((deltaH / (kH * sH)), 2.0))
            return distance
        }
        
        let deltaLPrime:CGFloat = L2 - L1
        let meanL:CGFloat = (L1 + L2) / 2
        let meanC:CGFloat = (C1 + C2) / 2
        let aPrime1:CGFloat = A1 + A1 / 2 * (1 - sqrt(pow(meanC, 7.0) / pow(meanC, 7.0) + pow(25.0, 7.0)))
        let aPrime2:CGFloat = A2 + A2 / 2 * (1 - sqrt(pow(meanC, 7.0) / pow(meanC, 7.0) + pow(25.0, 7.0)))
        let cPrime1:CGFloat = sqrt((aPrime1 * aPrime1) + (B1 * B1))
        let cPrime2:CGFloat = sqrt((aPrime2 * aPrime2) + (B2 * B2))
        let cMeanPrime:CGFloat = (cPrime1 + cPrime2) / 2
        let deltaCPrime:CGFloat = (cPrime1 - cPrime2)
        var hPrime1:CGFloat = atan2(B1, aPrime1)
        var hPrime2:CGFloat = atan2(B2, aPrime2)
        hPrime1 = CGFloat(fmodf(Float(hPrime1), Float(RAD(degree: 360))))
        hPrime2 = CGFloat(fmodf(Float(hPrime2), Float(RAD(degree: 360))))
        var deltahPrime:CGFloat = 0
        if abs(hPrime1 - hPrime2) <= RAD(degree: 180) {
            deltahPrime = hPrime2 - hPrime1
        } else {
            deltahPrime = hPrime2 <= hPrime1 ? (hPrime2 - hPrime1 + RAD(degree: 360)) : (hPrime2 - hPrime1 - RAD(degree: 360))
        }
        let deltaHPrime:CGFloat = 2 * sqrt(cPrime1 * cPrime2) * sin(deltahPrime / 2)
        let meanHPrime = (abs(hPrime1 - hPrime2) <= RAD(degree: 180)) ? ((hPrime1 + hPrime2) / 2) : (hPrime1 + hPrime2 + RAD(degree: 360) / 2)
        let T:CGFloat = 1 - 0.17 * cos(meanHPrime - RAD(degree: 30)) + 0.24 * cos(2 * meanHPrime) + 0.32 * cos(3 * meanHPrime + RAD(degree: 6)) - 0.2 * cos(4 * meanHPrime - RAD(degree: 63))
        sL = 1 + 0.015 * pow(meanL - 50, 2) / sqrt(20 + pow(meanL - 50, 2))
        sC = 1 + 0.045 * cMeanPrime
        sH = 1 + 0.015 * cMeanPrime * T
        let Rt = -2 * sqrt(pow(cMeanPrime, 7) / (pow(cMeanPrime, 7) + pow(25.0, 7))) * sin(RAD(degree:60.0) * exp(-1 * pow((meanHPrime - RAD(degree:275.0)) / RAD(degree:25.0), 2)))
        return sqrt(pow((deltaLPrime / (kL * sL)), 2) + pow((deltaCPrime / (kC * sC)), 2) + pow((deltaHPrime / (kH * sH)), 2) + Rt * (deltaC / (kC * sC)) * (deltaHPrime / (kH * sH)))
    }
    
    //MARK: 返回随机颜色
    ///返回随机颜色
    @objc class var randomColor:DynamicColor{
        get {
            DynamicColor.randomColorWithAlpha(alpha: 1)
        }
    }
    
    @objc class func randomColorWithAlpha(alpha:CGFloat)->DynamicColor {
        DynamicColor(r: CGFloat(arc4random() % 256), g: CGFloat(arc4random() % 256), b: CGFloat(arc4random() % 256), a: alpha)
    }
    
    @objc class var DevMaskColor:DynamicColor {
        DynamicColor(r: 0, g: 0, b: 0, a: 0.15)
    }
    
#if os(iOS)
    //MARK: 顏色轉圖片
    ///顏色轉圖片
    @objc func createImageWithColor()->UIImage {
        let rect = CGRect.init(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let ccontext = UIGraphicsGetCurrentContext()
        ccontext?.setFillColor(cgColor)
        ccontext!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
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
        let hexString                 = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner                   = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")

        var color: UInt64 = 0

        if scanner.scanHexInt64(&color) {
            self.init(hex: color, useOpacity: hexString.count > 7)
        }
        else {
            self.init(hex: 0x000000)
        }
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
