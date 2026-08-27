//
//  UIColor+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/21.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public enum PTColorTone {
    case light   // 接近白
    case dark    // 接近黑
    case normal  // 中间
    case clear   // ✅ 新增
}

public extension UIColor {

    // 统一使用颜色模块的 Hex 解析器，避免同一颜色在不同入口产生不同结果。

    //MARK: hex 色值
    /// - Parameters:
    ///   - hex:string that looks like @"#FF0000" or @"FF0000"
    ///   - alpha:0~1
    /// - Returns: UIColor
    class func hex(_ hex: String, 
                   alpha: CGFloat = 1.0) -> UIColor {
        let components = PTHexColorParser.parse(hex,
                                                embeddedAlpha: false,
                                                overridingAlpha: alpha)?.components
            ?? PTRGBAComponents(red: 0, green: 0, blue: 0, alpha: alpha)
        return UIColor(red: components.red,
                       green: components.green,
                       blue: components.blue,
                       alpha: components.alpha)
    }
            
    //MARK: 颜色转Hex字符串
    ///颜色转Hex字符串
    @objc var hex: String? {
        guard let components = ptRGBAComponents() else { return nil }
        if components.alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(roundToHex(components.red)),
                Int(roundToHex(components.green)),
                Int(roundToHex(components.blue))
            )
        } else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(roundToHex(components.red)),
                Int(roundToHex(components.green)),
                Int(roundToHex(components.blue)),
                Int(roundToHex(components.alpha))
            )
        }
    }
    
    @objc var toHexString: String {
        let components = colorToRGBA()
        
        return String(
            format: "%02X%02X%02X",
            Int(roundToHex(components.r)),
            Int(roundToHex(components.g)),
            Int(roundToHex(components.b))
        )
    }

    internal func hsbaValueModel() -> PTColorHSBAModel {
        let hsba = colorToHSBA()
        
        let colorModel = PTColorHSBAModel()
        colorModel.hueFloat = hsba.h
        colorModel.saturationFloat = hsba.s
        colorModel.brightnessFloat = hsba.b
        colorModel.alphaFloat = hsba.a
        return colorModel
    }
    
    internal func rgbaValueModel() -> PTColorRBGModel {
        let rgba = colorToRGBA()
        
        let colorModel = PTColorRBGModel()
        colorModel.redFloat = rgba.r
        colorModel.greenFloat = rgba.g
        colorModel.blueFloat = rgba.b
        colorModel.alphaFloat = rgba.a
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
    
    func pt_colorTone(threshold: CGFloat = 0.8) -> PTColorTone {
        let rgba = colorToRGBA()
        let r = rgba.r
        let g = rgba.g
        let b = rgba.b
        let a = rgba.a
        
        // ✅ 先判断透明（优先级最高）
        if a <= 0.01 {
            return .clear
        }
        
        // 亮度计算
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        
        if luminance >= threshold {
            return .light
        } else if luminance <= (1 - threshold) {
            return .dark
        } else {
            return .normal
        }
    }
}
