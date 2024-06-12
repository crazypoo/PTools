//
//  UIColor+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/21.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public extension UIColor {
            
    /**
        Convert HEX to RGB channels.
     
     - parameter hex: HEX of color.
     - parameter alpha: Opacity.
     */
    private static func parseHex(hex: String, alpha: CGFloat? = nil) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let hexString = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let length = hexString.count
        var hexValue: UInt64 = 0
        
        guard Scanner(string: hexString).scanHexInt64(&hexValue), [3, 4, 6, 8].contains(length) else {
            PTNSLogConsole("UIColorExtension - Invalid RGB string or scan error", levelType: .Error, loggerType: .Color)
            return (0, 0, 0, alpha ?? 1.0)
        }
        
        let divisor: CGFloat = length == 3 || length == 4 ? 15.0 : 255.0
        
        switch length {
        case 3: // RGB (12-bit)
            return (
                red:   CGFloat((hexValue & 0xF00) >> 8) / divisor,
                green: CGFloat((hexValue & 0x0F0) >> 4) / divisor,
                blue:  CGFloat(hexValue & 0x00F) / divisor,
                alpha: alpha ?? 1.0
            )
        case 4: // RGBA (16-bit)
            return (
                red:   CGFloat((hexValue & 0xF000) >> 12) / divisor,
                green: CGFloat((hexValue & 0x0F00) >> 8) / divisor,
                blue:  CGFloat((hexValue & 0x00F0) >> 4) / divisor,
                alpha: alpha ?? CGFloat(hexValue & 0x000F) / divisor
            )
        case 6: // RGB (24-bit)
            return (
                red:   CGFloat((hexValue & 0xFF0000) >> 16) / divisor,
                green: CGFloat((hexValue & 0x00FF00) >> 8) / divisor,
                blue:  CGFloat(hexValue & 0x0000FF) / divisor,
                alpha: alpha ?? 1.0
            )
        case 8: // RGBA (32-bit)
            return (
                red:   CGFloat((hexValue & 0xFF000000) >> 24) / divisor,
                green: CGFloat((hexValue & 0x00FF0000) >> 16) / divisor,
                blue:  CGFloat((hexValue & 0x0000FF00) >> 8) / divisor,
                alpha: alpha ?? CGFloat(hexValue & 0x000000FF) / divisor
            )
        default:
            PTNSLogConsole("UIColorExtension - Invalid RGB string length", levelType: .Error, loggerType: .Color)
            return (0, 0, 0, alpha ?? 1.0)
        }
    }

    //MARK: hex 色值
    /// - Parameters:
    ///   - hex:string that looks like @"#FF0000" or @"FF0000"
    ///   - alpha:0~1
    /// - Returns: UIColor
    class func hex(_ hex: String, 
                   alpha: CGFloat? = 1.0) -> UIColor {
        let tempStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexint = intFromHexString_64(tempStr)
        let color = UIColor(red: ((CGFloat) ((hexint & 0xFF0000) >> 16))/255, green: ((CGFloat) ((hexint & 0xFF00) >> 8))/255, blue: ((CGFloat) (hexint & 0xFF))/255, alpha: alpha!)
        return color
    }
            
    //MARK: 颜色转Hex字符串
    ///颜色转Hex字符串
    @objc var hex: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255)
        
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        } else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
    
    @objc var toHexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(
            format: "%02X%02X%02X",
            Int(r * 0xff),
            Int(g * 0xff),
            Int(b * 0xff)
        )
    }

    //MARK: 从Hex装换int
    ///从Hex装换int
    @available(iOS, introduced: 2.0, deprecated: 13.0)
    private class func intFromHexString(_ hexString:String)->UInt32{
        let scanner = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        var result : UInt32 = 0
        scanner.scanHexInt32(&result)
        return result
    }
    
    private class func intFromHexString_64(_ hexString:String)->UInt64{
        let scanner = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        var result : UInt64 = 0
        scanner.scanHexInt64(&result)
        return result
    }
                
    internal func hsbaValueModel()->PTColorHSBAModel {
        var hueF:CGFloat = 0
        var saturationF:CGFloat = 0
        var brightnessF:CGFloat = 0
        var alphaF:CGFloat = 0
        guard getHue(&hueF, saturation: &saturationF, brightness: &brightnessF, alpha: &alphaF) else {
            return PTColorHSBAModel()
        }
        
        let colorModel = PTColorHSBAModel()
        colorModel.hueFloat = hueF
        colorModel.saturationFloat = saturationF
        colorModel.brightnessFloat = brightnessF
        colorModel.alphaFloat = alphaF
        return colorModel
    }
    
    internal func rgbaValueModel()->PTColorRBGModel {
        var redF:CGFloat = 0
        var greenF:CGFloat = 0
        var blueF:CGFloat = 0
        var alphaF:CGFloat = 0
        guard getRed(&redF, green: &greenF, blue: &blueF, alpha: &alphaF) else {
            return PTColorRBGModel()
        }
        
        let colorModel = PTColorRBGModel()
        colorModel.redFloat = redF
        colorModel.greenFloat = greenF
        colorModel.blueFloat = blueF
        colorModel.alphaFloat = alphaF
        return colorModel
    }
    
    //MARK: 分别获取颜色的RGBA值
    ///分别获取颜色的RGBA值
    @objc var colorRValue:CGFloat {
        rgbaValueModel().redFloat
    }
    
    @objc var colorGValue:CGFloat {
        rgbaValueModel().greenFloat
    }
    
    @objc var colorBValue:CGFloat {
        rgbaValueModel().blueFloat
    }
    
    @objc var colorAValue:CGFloat {
        rgbaValueModel().alphaFloat
    }
    
    //MARK: 分别获取颜色的HSBA值
    ///分别获取颜色的HSBA值
    @objc var hsbaColorHValue:CGFloat {
        hsbaValueModel().hueFloat
    }
    
    @objc var hsbaColorSValue:CGFloat {
        hsbaValueModel().saturationFloat
    }
    
    @objc var hsbaColorBValue:CGFloat {
        hsbaValueModel().brightnessFloat
    }
    
    @objc var hsbaColorAValue:CGFloat {
        hsbaValueModel().alphaFloat
    }
}
