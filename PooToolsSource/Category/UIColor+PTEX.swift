//
//  UIColor+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/21.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

@objc public enum ColorDistanceType:Int
{
    case CIE76
    case CIE94
    case CIE2000
}

public extension UIColor {
        
    //MARK: hex 色值
    /// - Parameters:
    ///   - hex:string that looks like @"#FF0000" or @"FF0000"
    ///   - alpha:0~1
    /// - Returns: UIColor
    class func hex(_ hex: String, alpha: CGFloat? = 1.0) -> UIColor{
        let tempStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexint = intFromHexString_64(tempStr)
        let color = UIColor(red: ((CGFloat) ((hexint & 0xFF0000) >> 16))/255, green: ((CGFloat) ((hexint & 0xFF00) >> 8))/255, blue: ((CGFloat) (hexint & 0xFF))/255, alpha: alpha!)
        return color
    }
    
    func cielabColorArray()->[NSNumber]
    {
        var R = self.colorRValue
        var G = self.colorGValue
        var B = self.colorBValue
        
        let deltaRGB: (CGFloat) -> CGFloat = {
            return ($0 > 0.04045) ? pow(($0 + 0.055) / 1.055, 2.4) : ($0 / 12.92)
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
            return ($0 > pow((6.0 / 29.0), 3.0)) ? pow($0, 1.0 / 3.0) : (sideA * pow((29.0 / 6.0), 2.0) * $0 + sideB)
        }
        X = deltaF(X)
        Y = deltaF(Y)
        Z = deltaF(Z)
        
        let L:NSNumber = NSNumber(floatLiteral: (116 * Y - 16))
        let A:NSNumber = NSNumber(floatLiteral: (500 * (X - Y)))
        let b:NSNumber = NSNumber(floatLiteral: (200 * (Y - Z)))
        return [L,A,b,NSNumber(floatLiteral: self.colorAValue)]
    }
    
    //MARK: Color from LAB Array
    ///Color from LAB Array
    class func cielabColor(cielabData:[CGFloat])->UIColor
    {
        if cielabData.count < 4
        {
            return .clear
        }
        
        let L:CGFloat = cielabData[0]
        let A:CGFloat = cielabData[1]
        let B:CGFloat = cielabData[2]
        var Y:CGFloat = (L + 16) / 116
        var X:CGFloat = A / 500 + Y
        var Z:CGFloat = Y - B / 200
        
        let deltaXYZ: (CGFloat) -> CGFloat = {
            return ($0 > 0.008856) ? pow($0, 3.0) : ($0 - 4/29.0)/7.787
        }
        
        X = deltaXYZ(X) * 0.95047
        Y = deltaXYZ(Y) * 1.00000
        Z = deltaXYZ(Z) * 1.08883
        
        var R:CGFloat = X * 3.2406 + Y * (-1.5372) + Z * (-0.4986)
        var G:CGFloat = X * (-0.9689) + Y * 1.8758 + Z * 0.0415
        var _B:CGFloat = X * 0.0557 + Y * (-0.2040) + Z * 1.0570
        
        let deltaRGB: (CGFloat) -> CGFloat = {
            return ($0 > 0.0031308) ? 1.055 * (pow($0, (1/2.4))) - 0.055 : $0 * 12.92
        }
        
        R = deltaRGB(R)
        G = deltaRGB(G)
        _B = deltaRGB(_B)
        return self.colorBase(R: R, G: G, B: B, A: cielabData[3])
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
    
    func RAD(degree:CGFloat)->CGFloat
    {
        return degree * .pi / 180
    }
    
    func colorDistance(color:UIColor,type:ColorDistanceType)->CGFloat
    {
        let lab1 = self.cielabColorArray()
        let lab2 = color.cielabColorArray()
        
        let L1:CGFloat = CGFloat(lab1[0].floatValue)
        let A1:CGFloat = CGFloat(lab1[1].floatValue)
        let B1:CGFloat = CGFloat(lab1[2].floatValue)

        let L2:CGFloat = CGFloat(lab2[0].floatValue)
        let A2:CGFloat = CGFloat(lab2[1].floatValue)
        let B2:CGFloat = CGFloat(lab2[2].floatValue)

        if type == .CIE76
        {
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
        
        if type == .CIE94
        {
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
        hPrime1 = CGFloat(fmodf(Float(hPrime1), Float(self.RAD(degree: 360))))
        hPrime2 = CGFloat(fmodf(Float(hPrime2), Float(self.RAD(degree: 360))))
        var deltahPrime:CGFloat = 0
        if abs(hPrime1 - hPrime2) <= self.RAD(degree: 180)
        {
            deltahPrime = hPrime2 - hPrime1
        }
        else
        {
            deltahPrime = hPrime2 <= hPrime1 ? (hPrime2 - hPrime1 + self.RAD(degree: 360)) : (hPrime2 - hPrime1 - self.RAD(degree: 360))
        }
        let deltaHPrime:CGFloat = 2 * sqrt(cPrime1 * cPrime2) * sin(deltahPrime / 2)
        let meanHPrime = (abs(hPrime1 - hPrime2) <= self.RAD(degree: 180)) ? ((hPrime1 + hPrime2) / 2) : (hPrime1 + hPrime2 + self.RAD(degree: 360) / 2)
        let T:CGFloat = 1 - 0.17 * cos(meanHPrime - self.RAD(degree: 30)) + 0.24 * cos(2 * meanHPrime) + 0.32 * cos(3 * meanHPrime + self.RAD(degree: 6)) - 0.2 * cos(4 * meanHPrime - self.RAD(degree: 63))
        sL = 1 + 0.015 * pow(meanL - 50, 2) / sqrt(20 + pow(meanL - 50, 2))
        sC = 1 + 0.045 * cMeanPrime
        sH = 1 + 0.015 * cMeanPrime * T
        let Rt = -2 * sqrt(pow(cMeanPrime, 7) / (pow(cMeanPrime, 7) + pow(25.0, 7))) * sin(self.RAD(degree:60.0) * exp(-1 * pow((meanHPrime - self.RAD(degree:275.0)) / self.RAD(degree:25.0), 2)))
        return sqrt(pow((deltaLPrime / (kL * sL)), 2) + pow((deltaCPrime / (kC * sC)), 2) + pow((deltaHPrime / (kH * sH)), 2) + Rt * (deltaC / (kC * sC)) * (deltaHPrime / (kH * sH)))
    }
    
    
    //MARK: Color from CMYK Array
    ///Color from CMYK Array
    class func cmykColor(cmykData:[CGFloat])->UIColor
    {
        if cmykData.count < 4
        {
            return .clear
        }
        
        var C:CGFloat = cmykData[0]
        var M:CGFloat = cmykData[1]
        var Y:CGFloat = cmykData[2]
        let K:CGFloat = cmykData[3]

        let cmyTransform = { (x: inout CGFloat) -> Void in
                x = x * (1 - K) + K
        }
        cmyTransform(&C)
        cmyTransform(&M)
        cmyTransform(&Y)
        
        let R = 1 - C
        let G = 1 - M
        let B = 1 - Y
        return self.colorBase(R: R, G: G, B: B, A: 1)
    }
        
    //MARK: 颜色转Hex字符串
    ///颜色转Hex字符串
    @objc var hex: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255)
        
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

    //MARK: 返回随机颜色
    ///返回随机颜色
    @objc class var randomColor:UIColor{
        get
        {
            return UIColor.randomColorWithAlpha(alpha: 1)
        }
    }
    
    @objc class func randomColorWithAlpha(alpha:CGFloat)->UIColor
    {
        return UIColor.colorBase(R: CGFloat(arc4random()%256), G: CGFloat(arc4random()%256), B: CGFloat(arc4random()%256), A: alpha)
    }
    
    //MARK: 颜色基础方法
    ///颜色基础方法
    @objc class func colorBase(R:CGFloat,G:CGFloat,B:CGFloat,A:CGFloat)->UIColor
    {
        let red = R/255.0
        let green = G/255.0
        let blue = B/255.0
        return UIColor(red: red, green: green, blue: blue, alpha: A)
    }
    
    @objc class var DevMaskColor:UIColor {
        return UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
    }
    
    //MARK: 顏色轉圖片
    ///顏色轉圖片
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
    
    //MARK: 顏色的反色
    ///顏色的反色
    @objc func inverseColor()->UIColor {
        let componentColors = self.cgColor.components
        return UIColor(red: 1 - componentColors![0], green: 1 - componentColors![1], blue: 1 - componentColors![2], alpha:componentColors![3])
    }
    
    internal func hsbaValueModel()->PTColorHSBAModel
    {
        var hueF:CGFloat = 0
        var saturationF:CGFloat = 0
        var brightnessF:CGFloat = 0
        var alphaF:CGFloat = 0
        guard self.getHue(&hueF, saturation: &saturationF, lightness: &brightnessF, alpha: &alphaF) else {
            return PTColorHSBAModel()
        }
        
        let colorModel = PTColorHSBAModel()
        colorModel.hueFloat = hueF
        colorModel.saturationFloat = saturationF
        colorModel.brightnessFloat = brightnessF
        colorModel.alphaFloat = alphaF
        return colorModel
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

    //MARK: 混色
    ///混色
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
    
    //MARK: 分别获取颜色的RGBA值
    ///分别获取颜色的RGBA值
    @objc var colorRValue:CGFloat {
        return self.rgbaValueModel().redFloat
    }
    
    @objc var colorGValue:CGFloat {
        return self.rgbaValueModel().greenFloat
    }
    
    @objc var colorBValue:CGFloat {
        return self.rgbaValueModel().blueFloat
    }
    
    @objc var colorAValue:CGFloat {
        return self.rgbaValueModel().alphaFloat
    }
    
    //MARK: 分别获取颜色的HSBA值
    ///分别获取颜色的HSBA值
    @objc var hsbaColorHValue:CGFloat {
        return self.hsbaValueModel().hueFloat
    }
    
    @objc var hsbaColorSValue:CGFloat {
        return self.hsbaValueModel().saturationFloat
    }
    
    @objc var hsbaColorBValue:CGFloat {
        return self.hsbaValueModel().brightnessFloat
    }
    
    @objc var hsbaColorAValue:CGFloat {
        return self.hsbaValueModel().alphaFloat
    }
    
    //MARK: 常规颜色配置
    //MARK: Whites
    @objc class var AntiqueWhiteColor:UIColor {
        return UIColor.colorBase(R: 250, G: 235, B: 215, A: 1)
    }
    @objc class var OldLaceColor:UIColor {
        return UIColor.colorBase(R: 253, G: 245, B: 230, A: 1)
    }
    @objc class var IvoryColor:UIColor {
        return UIColor.colorBase(R: 255, G: 255, B: 240, A: 1)
    }
    @objc class var SeashellColor:UIColor {
        return UIColor.colorBase(R: 255, G: 245, B: 238, A: 1)
    }
    @objc class var GhostWhiteColor:UIColor {
        return UIColor.colorBase(R: 248, G: 248, B: 255, A: 1)
    }
    @objc class var SnowColor:UIColor {
        return UIColor.colorBase(R: 255, G: 250, B: 250, A: 1)
    }
    @objc class var LinenColor:UIColor {
        return UIColor.colorBase(R: 250, G: 240, B: 230, A: 1)
    }
    //MARK: Grays
    @objc class var Black25PercentColor:UIColor {
        return UIColor(white: 0.25, alpha: 1)
    }
    @objc class var Black50PercentColor:UIColor {
        return UIColor(white: 0.5, alpha: 1)
    }
    @objc class var Black75PercentColor:UIColor {
        return UIColor(white: 0.75, alpha: 1)
    }
    @objc class var WarmGrayColor:UIColor {
        return UIColor.colorBase(R: 133, G: 117, B: 112, A: 1)
    }
    @objc class var CoolGrayColor:UIColor {
        return UIColor.colorBase(R: 118, G: 122, B: 133, A: 1)
    }
    @objc class var CharcoalColor:UIColor {
        return UIColor.colorBase(R: 34, G: 34, B: 34, A: 1)
    }
    //MARK: Blues
    @objc class var TealColor:UIColor {
        return UIColor.colorBase(R: 28, G: 160, B: 170, A: 1)
    }
    @objc class var SteelBlueColor:UIColor {
        return UIColor.colorBase(R: 103, G: 153, B: 170, A: 1)
    }
    @objc class var RobinEggColor:UIColor {
        return UIColor.colorBase(R: 141, G: 218, B: 247, A: 1)
    }
    @objc class var PastelBlueColor:UIColor {
        return UIColor.colorBase(R: 99, G: 161, B: 247, A: 1)
    }
    @objc class var TurquoiseColor:UIColor {
        return UIColor.colorBase(R: 112, G: 219, B: 219, A: 1)
    }
    @objc class var SkyBlueColor:UIColor {
        return UIColor.colorBase(R: 0, G: 178, B: 238, A: 1)
    }
    @objc class var IndigoColor:UIColor {
        return UIColor.colorBase(R: 13, G: 79, B: 139, A: 1)
    }
    @objc class var DenimColor:UIColor {
        return UIColor.colorBase(R: 67, G: 114, B: 170, A: 1)
    }
    @objc class var BlueberryColor:UIColor {
        return UIColor.colorBase(R: 89, G: 113, B: 173, A: 1)
    }
    @objc class var CornflowerColor:UIColor {
        return UIColor.colorBase(R: 100, G: 149, B: 237, A: 1)
    }
    @objc class var BabyBlueColor:UIColor {
        return UIColor.colorBase(R: 190, G: 220, B: 230, A: 1)
    }
    @objc class var MidnightBlueColor:UIColor {
        return UIColor.colorBase(R: 13, G: 26, B: 35, A: 1)
    }
    @objc class var FadedBlueColor:UIColor {
        return UIColor.colorBase(R: 23, G: 137, B: 155, A: 1)
    }
    @objc class var IcebergColor:UIColor {
        return UIColor.colorBase(R: 200, G: 213, B: 219, A: 1)
    }
    @objc class var WaveColor:UIColor {
        return UIColor.colorBase(R: 102, G: 169, B: 251, A: 1)
    }
    //MARK: Greens
    @objc class var EmeraldColor:UIColor {
        return UIColor.colorBase(R: 1, G: 152, B: 117, A: 1)
    }
    @objc class var GrassColor:UIColor {
        return UIColor.colorBase(R: 99, G: 214, B: 74, A: 1)
    }
    @objc class var PastelGreenColor:UIColor {
        return UIColor.colorBase(R: 126, G: 242, B: 124, A: 1)
    }
    @objc class var SeafoamColor:UIColor {
        return UIColor.colorBase(R: 77, G: 226, B: 140, A: 1)
    }
    @objc class var PaleGreenColor:UIColor {
        return UIColor.colorBase(R: 176, G: 226, B: 172, A: 1)
    }
    @objc class var CactusGreenColor:UIColor {
        return UIColor.colorBase(R: 99, G: 111, B: 87, A: 1)
    }
    @objc class var ChartreuseColor:UIColor {
        return UIColor.colorBase(R: 69, G: 139, B: 0, A: 1)
    }
    @objc class var HollyGreenColor:UIColor {
        return UIColor.colorBase(R: 32, G: 87, B: 14, A: 1)
    }
    @objc class var OliveColor:UIColor {
        return UIColor.colorBase(R: 91, G: 114, B: 34, A: 1)
    }
    @objc class var OliveDrabColor:UIColor {
        return UIColor.colorBase(R: 107, G: 142, B: 35, A: 1)
    }
    @objc class var MoneyGreenColor:UIColor {
        return UIColor.colorBase(R: 134, G: 198, B: 124, A: 1)
    }
    @objc class var HoneydewColor:UIColor {
        return UIColor.colorBase(R: 216, G: 255, B: 231, A: 1)
    }
    @objc class var LimeColor:UIColor {
        return UIColor.colorBase(R: 56, G: 237, B: 56, A: 1)
    }
    @objc class var CardTableColor:UIColor {
        return UIColor.colorBase(R: 87, G: 121, B: 107, A: 1)
    }
    //MARK: Reds
    @objc class var SalmonColor:UIColor {
        return UIColor.colorBase(R: 233, G: 87, B: 95, A: 1)
    }
    @objc class var BrickRedColor:UIColor {
        return UIColor.colorBase(R: 151, G: 27, B: 16, A: 1)
    }
    @objc class var EasterPinkColor:UIColor {
        return UIColor.colorBase(R: 241, G: 167, B: 162, A: 1)
    }
    @objc class var GrapefruitColor:UIColor {
        return UIColor.colorBase(R: 228, G: 31, B: 54, A: 1)
    }
    @objc class var PinkColor:UIColor {
        return UIColor.colorBase(R: 255, G: 95, B: 154, A: 1)
    }
    @objc class var IndianRedColor:UIColor {
        return UIColor.colorBase(R: 205, G: 92, B: 92, A: 1)
    }
    @objc class var StrawberryColor:UIColor {
        return UIColor.colorBase(R: 190, G: 38, B: 37, A: 1)
    }
    @objc class var CoralColor:UIColor {
        return UIColor.colorBase(R: 240, G: 128, B: 128, A: 1)
    }
    @objc class var MaroonColor:UIColor {
        return UIColor.colorBase(R: 80, G: 4, B: 28, A: 1)
    }
    @objc class var WatermelonColor:UIColor {
        return UIColor.colorBase(R: 242, G: 71, B: 63, A: 1)
    }
    @objc class var TomatoColor:UIColor {
        return UIColor.colorBase(R: 255, G: 99, B: 71, A: 1)
    }
    @objc class var PinkLipstickColor:UIColor {
        return UIColor.colorBase(R: 255, G: 105, B: 180, A: 1)
    }
    @objc class var PaleRoseColor:UIColor {
        return UIColor.colorBase(R: 255, G: 228, B: 225, A: 1)
    }
    @objc class var CrimsonColor:UIColor {
        return UIColor.colorBase(R: 187, G: 18, B: 36, A: 1)
    }
    //MARK: Purples
    @objc class var EggplantColor:UIColor {
        return UIColor.colorBase(R: 105, G: 5, B: 98, A: 1)
    }
    @objc class var PastelPurpleColor:UIColor {
        return UIColor.colorBase(R: 207, G: 100, B: 235, A: 1)
    }
    @objc class var PalePurpleColor:UIColor {
        return UIColor.colorBase(R: 229, G: 180, B: 235, A: 1)
    }
    @objc class var CoolPurpleColor:UIColor {
        return UIColor.colorBase(R: 140, G: 93, B: 228, A: 1)
    }
    @objc class var VioletColor:UIColor {
        return UIColor.colorBase(R: 191, G: 95, B: 255, A: 1)
    }
    @objc class var PlumColor:UIColor {
        return UIColor.colorBase(R: 139, G: 102, B: 139, A: 1)
    }
    @objc class var LavenderColor:UIColor {
        return UIColor.colorBase(R: 204, G: 153, B: 204, A: 1)
    }
    @objc class var RaspberryColor:UIColor {
        return UIColor.colorBase(R: 135, G: 38, B: 87, A: 1)
    }
    @objc class var FuschiaColor:UIColor {
        return UIColor.colorBase(R: 255, G: 20, B: 147, A: 1)
    }
    @objc class var GrapeColor:UIColor {
        return UIColor.colorBase(R: 54, G: 11, B: 88, A: 1)
    }
    @objc class var PeriwinkleColor:UIColor {
        return UIColor.colorBase(R: 135, G: 159, B: 237, A: 1)
    }
    @objc class var OrchidColor:UIColor {
        return UIColor.colorBase(R: 218, G: 112, B: 214, A: 1)
    }
    //MARK: Yellows
    @objc class var GoldenrodColor:UIColor {
        return UIColor.colorBase(R: 215, G: 170, B: 51, A: 1)
    }
    @objc class var YellowGreenColor:UIColor {
        return UIColor.colorBase(R: 192, G: 242, B: 39, A: 1)
    }
    @objc class var BananaColor:UIColor {
        return UIColor.colorBase(R: 229, G: 227, B: 58, A: 1)
    }
    @objc class var MustardColor:UIColor {
        return UIColor.colorBase(R: 205, G: 171, B: 45, A: 1)
    }
    @objc class var ButtermilkColor:UIColor {
        return UIColor.colorBase(R: 254, G: 241, B: 181, A: 1)
    }
    @objc class var GoldColor:UIColor {
        return UIColor.colorBase(R: 139, G: 117, B: 18, A: 1)
    }
    @objc class var CreamColor:UIColor {
        return UIColor.colorBase(R: 240, G: 226, B: 187, A: 1)
    }
    @objc class var LightCreamColor:UIColor {
        return UIColor.colorBase(R: 240, G: 238, B: 215, A: 1)
    }
    @objc class var WheatColor:UIColor {
        return UIColor.colorBase(R: 240, G: 238, B: 215, A: 1)
    }
    @objc class var BeigeColor:UIColor {
        return UIColor.colorBase(R: 245, G: 245, B: 220, A: 1)
    }
    //MARK: Oranges
    @objc class var PeachColor:UIColor {
        return UIColor.colorBase(R: 242, G: 187, B: 97, A: 1)
    }
    @objc class var BurntOrangeColor:UIColor {
        return UIColor.colorBase(R: 184, G: 102, B: 37, A: 1)
    }
    @objc class var PastelOrangeColor:UIColor {
        return UIColor.colorBase(R: 248, G: 197, B: 143, A: 1)
    }
    @objc class var CantaloupeColor:UIColor {
        return UIColor.colorBase(R: 250, G: 154, B: 79, A: 1)
    }
    @objc class var CarrotColor:UIColor {
        return UIColor.colorBase(R: 237, G: 145, B: 33, A: 1)
    }
    @objc class var MandarinColor:UIColor {
        return UIColor.colorBase(R: 247, G: 145, B: 55, A: 1)
    }
    //MARK: Browns
    @objc class var ChiliPowderColor:UIColor {
        return UIColor.colorBase(R: 199, G: 63, B: 23, A: 1)
    }
    @objc class var BurntSiennaColor:UIColor {
        return UIColor.colorBase(R: 138, G: 54, B: 15, A: 1)
    }
    @objc class var ChocolateColor:UIColor {
        return UIColor.colorBase(R: 94, G: 38, B: 5, A: 1)
    }
    @objc class var CoffeeColor:UIColor {
        return UIColor.colorBase(R: 141, G: 60, B: 15, A: 1)
    }
    @objc class var CinnamonColor:UIColor {
        return UIColor.colorBase(R: 123, G: 63, B: 9, A: 1)
    }
    @objc class var AlmondColor:UIColor {
        return UIColor.colorBase(R: 196, G: 142, B: 72, A: 1)
    }
    @objc class var EggshellColor:UIColor {
        return UIColor.colorBase(R: 252, G: 230, B: 201, A: 1)
    }
    @objc class var SandColor:UIColor {
        return UIColor.colorBase(R: 222, G: 182, B: 151, A: 1)
    }
    @objc class var MudColor:UIColor {
        return UIColor.colorBase(R: 70, G: 45, B: 29, A: 1)
    }
    @objc class var SiennaColor:UIColor {
        return UIColor.colorBase(R: 160, G: 82, B: 45, A: 1)
    }
    @objc class var DustColor:UIColor {
        return UIColor.colorBase(R: 236, G: 214, B: 197, A: 1)
    }
}
