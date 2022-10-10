//
//  UIColor+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/21.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

/// 颜色扩展
public extension UIColor {
    
    var toHexString: String {
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
    
    /// hex 色值
    class func hex(_ hex: String, alpha: CGFloat? = 1.0) -> UIColor{
        let tempStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexint = intFromHexString(tempStr)
        let color = UIColor(red: ((CGFloat) ((hexint & 0xFF0000) >> 16))/255, green: ((CGFloat) ((hexint & 0xFF00) >> 8))/255, blue: ((CGFloat) (hexint & 0xFF))/255, alpha: alpha!)
        return color
    }

    /// UIColor -> Hex String
    var hex: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255.999999)
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        }
        else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
    
    /// 从Hex装换int
    private class func intFromHexString(_ hexString:String)->UInt32{
        let scanner = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        var result : UInt32 = 0
        scanner.scanHexInt32(&result)
        return result
    }

    /// 返回随机颜色
    @objc class var randomColor:UIColor{
        get
        {
            return UIColor.randomColorWithAlpha(alpha: 1)
        }
    }
    
    @objc class func randomColorWithAlpha(alpha:CGFloat)->UIColor
    {
        let red = CGFloat(arc4random()%256)/255.0
        let green = CGFloat(arc4random()%256)/255.0
        let blue = CGFloat(arc4random()%256)/255.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)

    }
    
    @objc class var DevMaskColor:UIColor {
        return UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
    }
    
    @objc func createImageWithColor()->UIImage
    {
        let rect = CGRect.init(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let ccontext = UIGraphicsGetCurrentContext()
        ccontext?.setFillColor(self.cgColor)
        ccontext!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    @objc func inverseColor()->UIColor {
        let componentColors = self.cgColor.components
        return UIColor(red: 1 - componentColors![0], green: 1 - componentColors![1], blue: 1 - componentColors![2], alpha:componentColors![3])
    }
    
    internal func rgbaValueModel()->PTColorRBGModel
    {
        var redF:CGFloat = 0
        var greenF:CGFloat = 0
        var blueF:CGFloat = 0
        var alphaF:CGFloat = 0
        guard self.getRed(&redF, green: &greenF, blue: &blueF, alpha: &alphaF) else {
            return PTColorRBGModel()
        }
        
        let colorModel = PTColorRBGModel()
        colorModel.redFloat = redF
        colorModel.greenFloat = greenF
        colorModel.blueFloat = blueF
        colorModel.alphaFloat = alphaF
        return colorModel
    }

    internal func mixColor(otherColor:UIColor)->UIColor
    {
        let rgbaModel = self.rgbaValueModel()
        let otherRgbaModel = otherColor.rgbaValueModel()

        let newAlpha = 1 - (1 - (rgbaModel.alphaFloat)) * (1 - otherRgbaModel.alphaFloat)
        let newRed = (rgbaModel.redFloat) * (rgbaModel.alphaFloat) / newAlpha + (otherRgbaModel.redFloat) * (otherRgbaModel.alphaFloat) * (1 - (rgbaModel.alphaFloat)) / newAlpha
        let newGreen = (rgbaModel.greenFloat) * (rgbaModel.alphaFloat) / newAlpha + (otherRgbaModel.greenFloat) * (otherRgbaModel.alphaFloat) * (1 - (rgbaModel.alphaFloat)) / newAlpha
        let newBlue = (rgbaModel.blueFloat) * (rgbaModel.alphaFloat) / newAlpha + (otherRgbaModel.blueFloat) * (otherRgbaModel.alphaFloat) * (1 - (rgbaModel.alphaFloat)) / newAlpha
        return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: newAlpha)
    }
}
