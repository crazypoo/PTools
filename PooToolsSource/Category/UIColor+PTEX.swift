//
//  UIColor+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/21.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import FluentDarkModeKit

public extension UIColor {
        
    @objc class func lightDarkColor(light:UIColor,dark:UIColor) -> UIColor {
        UIColor(.dm, light: light, dark: dark)
    }
    
    /**
        Convert HEX to RGB channels.
     
     - parameter hex: HEX of color.
     - parameter alpha: Opacity.
     */
    private static func parseHex(hex: String, alpha: CGFloat?) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var newAlpha: CGFloat = alpha ?? 1.0
        var hex:   String = hex
        
        if hex.hasPrefix("#") {
            let index = hex.index(hex.startIndex, offsetBy: 1)
            hex = String(hex[index...])
        }
        
        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch (hex.count) {
            case 3:
                red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                blue  = CGFloat(hexValue & 0x00F)              / 15.0
            case 4:
                red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                if alpha == nil {
                    newAlpha = CGFloat(hexValue & 0x000F)      / 15.0
                }
            case 6:
                red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
            case 8:
                red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                if alpha == nil {
                    newAlpha = CGFloat(hexValue & 0x000000FF)  / 255.0
                }
            default:
                PTNSLogConsole("UIColorExtension - Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8",levelType: .Error,loggerType: .Color)
            }
        } else {
            PTNSLogConsole("UIColorExtension - Scan hex error",levelType: .Error,loggerType: .Color)
        }
        return (red, green, blue, newAlpha)
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
