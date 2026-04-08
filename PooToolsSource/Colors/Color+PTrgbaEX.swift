//
//  Color+PTrgbaEX.swift
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

public extension DynamicColor {
    
    /**
     Initializes and returns a color object using the specified opacity and RGB component values.

     Notes that values out of range are clipped.

     - Parameter r: The red component of the color object, specified as a value from 0.0 to 255.0.
     - Parameter g: The green component of the color object, specified as a value from 0.0 to 255.0.
     - Parameter b: The blue component of the color object, specified as a value from 0.0 to 255.0.
     - Parameter a: The opacity value of the color object, specified as a value from 0.0 to 1.0. The default value is 1.0.
     */
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        // 注意：这里除以 255.0 是非常正确的，因为系统 init(red:green:blue:alpha) 接受的是 0...1 的值
        self.init(red: clip(r, 0, 255.0) / 255.0,
                  green: clip(g, 0, 255.0) / 255.0,
                  blue: clip(b, 0, 255.0) / 255.0,
                  alpha: clip(a, 0, 1.0))
    }
    
    // MARK: - color 转 RGBA
    
    /// color 转 RGBA
    /// - Returns: 返回对应的 RGBA (范围 0.0 ... 1.0)
    func colorToRGBA() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        #if os(iOS) || os(tvOS) || os(watchOS)
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            // 🚀 优化：移除 fatalError，遇到异常颜色返回安全值，防止 App 崩溃
            return (0.0, 0.0, 0.0, self.alphaComponent)
        }
        return (red, green, blue, alpha)
        
        #elseif os(OSX)
        guard let rgbaColor = self.usingColorSpace(.deviceRGB) else {
            // 🚀 优化：移除 fatalError
            return (0.0, 0.0, 0.0, self.alphaComponent)
        }
        rgbaColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
        #endif
    }
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    /** The red component as CGFloat between 0.0 to 1.0. */
    var redComponent: CGFloat { return colorToRGBA().r }

    /** The green component as CGFloat between 0.0 to 1.0. */
    var greenComponent: CGFloat { return colorToRGBA().g }

    /** The blue component as CGFloat between 0.0 to 1.0. */
    var blueComponent: CGFloat { return colorToRGBA().b }

    /** The alpha component as CGFloat between 0.0 to 1.0. */
    var alphaComponent: CGFloat { return colorToRGBA().a }
    #endif

    // MARK: - Setting the RGBA Components

    /**
     Creates and returns a color object with the alpha increased by the given amount.
     */
    func adjustedAlpha(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat) -> DynamicColor {
        let components = colorToRGBA()
        // 🚀 优化：信任包装器，直接加 (或者如果你意图是加上 amount 后不超过 1，保留 clip 也可以)
        let normalizedAlpha = clip(components.a + amount, 0.0, 1.0)
        return DynamicColor(red: components.r, green: components.g, blue: components.b, alpha: normalizedAlpha)
    }
    
    // MARK: - 常规颜色配置
    
    // 🚀 优化：将老旧的 @objc class var 统一替换为现代的 public static var
    
    // MARK: Whites
    static var AntiqueWhiteColor: DynamicColor { DynamicColor(r: 250, g: 235, b: 215, a: 1) }
    static var OldLaceColor: DynamicColor      { DynamicColor(r: 253, g: 245, b: 230, a: 1) }
    static var IvoryColor: DynamicColor        { DynamicColor(r: 255, g: 255, b: 240, a: 1) }
    static var SeashellColor: DynamicColor     { DynamicColor(r: 255, g: 245, b: 238, a: 1) }
    static var GhostWhiteColor: DynamicColor   { DynamicColor(r: 248, g: 248, b: 255, a: 1) }
    static var SnowColor: DynamicColor         { DynamicColor(r: 255, g: 250, b: 250, a: 1) }
    static var LinenColor: DynamicColor        { DynamicColor(r: 250, g: 240, b: 230, a: 1) }
    
    // MARK: Grays
    static var Black25PercentColor: DynamicColor { DynamicColor(white: 0.25, alpha: 1) }
    static var Black50PercentColor: DynamicColor { DynamicColor(white: 0.50, alpha: 1) }
    static var Black75PercentColor: DynamicColor { DynamicColor(white: 0.75, alpha: 1) }
    static var WarmGrayColor: DynamicColor       { DynamicColor(r: 133, g: 117, b: 112, a: 1) }
    static var CoolGrayColor: DynamicColor       { DynamicColor(r: 118, g: 122, b: 133, a: 1) }
    static var CharcoalColor: DynamicColor       { DynamicColor(r: 34, g: 34, b: 34, a: 1) }
    
    // MARK: Blues
    static var TealColor: DynamicColor         { DynamicColor(r: 28, g: 160, b: 170, a: 1) }
    static var SteelBlueColor: DynamicColor    { DynamicColor(r: 103, g: 153, b: 170, a: 1) }
    static var RobinEggColor: DynamicColor     { DynamicColor(r: 141, g: 218, b: 247, a: 1) }
    static var PastelBlueColor: DynamicColor   { DynamicColor(r: 99, g: 161, b: 247, a: 1) }
    static var TurquoiseColor: DynamicColor    { DynamicColor(r: 112, g: 219, b: 219, a: 1) }
    static var SkyBlueColor: DynamicColor      { DynamicColor(r: 0, g: 178, b: 238, a: 1) }
    static var IndigoColor: DynamicColor       { DynamicColor(r: 13, g: 79, b: 139, a: 1) }
    static var DenimColor: DynamicColor        { DynamicColor(r: 67, g: 114, b: 170, a: 1) }
    static var BlueberryColor: DynamicColor    { DynamicColor(r: 89, g: 113, b: 173, a: 1) }
    static var CornflowerColor: DynamicColor   { DynamicColor(r: 100, g: 149, b: 237, a: 1) }
    static var BabyBlueColor: DynamicColor     { DynamicColor(r: 190, g: 220, b: 230, a: 1) }
    static var MidnightBlueColor: DynamicColor { DynamicColor(r: 13, g: 26, b: 35, a: 1) }
    static var FadedBlueColor: DynamicColor    { DynamicColor(r: 23, g: 137, b: 155, a: 1) }
    static var IcebergColor: DynamicColor      { DynamicColor(r: 200, g: 213, b: 219, a: 1) }
    static var WaveColor: DynamicColor         { DynamicColor(r: 102, g: 169, b: 251, a: 1) }
    
    // MARK: Greens
    static var EmeraldColor: DynamicColor      { DynamicColor(r: 1, g: 152, b: 117, a: 1) }
    static var GrassColor: DynamicColor        { DynamicColor(r: 99, g: 214, b: 74, a: 1) }
    static var PastelGreenColor: DynamicColor  { DynamicColor(r: 126, g: 242, b: 124, a: 1) }
    static var SeafoamColor: DynamicColor      { DynamicColor(r: 77, g: 226, b: 140, a: 1) }
    static var PaleGreenColor: DynamicColor    { DynamicColor(r: 176, g: 226, b: 172, a: 1) }
    static var CactusGreenColor: DynamicColor  { DynamicColor(r: 99, g: 111, b: 87, a: 1) }
    static var ChartreuseColor: DynamicColor   { DynamicColor(r: 69, g: 139, b: 0, a: 1) }
    static var HollyGreenColor: DynamicColor   { DynamicColor(r: 32, g: 87, b: 14, a: 1) }
    static var OliveColor: DynamicColor        { DynamicColor(r: 91, g: 114, b: 34, a: 1) }
    static var OliveDrabColor: DynamicColor    { DynamicColor(r: 107, g: 142, b: 35, a: 1) }
    static var MoneyGreenColor: DynamicColor   { DynamicColor(r: 134, g: 198, b: 124, a: 1) }
    static var HoneydewColor: DynamicColor     { DynamicColor(r: 216, g: 255, b: 231, a: 1) }
    static var LimeColor: DynamicColor         { DynamicColor(r: 56, g: 237, b: 56, a: 1) }
    static var CardTableColor: DynamicColor    { DynamicColor(r: 87, g: 121, b: 107, a: 1) }
    
    // MARK: Reds
    static var SalmonColor: DynamicColor       { DynamicColor(r: 233, g: 87, b: 95, a: 1) }
    static var BrickRedColor: DynamicColor     { DynamicColor(r: 151, g: 27, b: 16, a: 1) }
    static var EasterPinkColor: DynamicColor   { DynamicColor(r: 241, g: 167, b: 162, a: 1) }
    static var GrapefruitColor: DynamicColor   { DynamicColor(r: 228, g: 31, b: 54, a: 1) }
    static var PinkColor: DynamicColor         { DynamicColor(r: 255, g: 95, b: 154, a: 1) }
    static var IndianRedColor: DynamicColor    { DynamicColor(r: 205, g: 92, b: 92, a: 1) }
    static var StrawberryColor: DynamicColor   { DynamicColor(r: 190, g: 38, b: 37, a: 1) }
    static var CoralColor: DynamicColor        { DynamicColor(r: 240, g: 128, b: 128, a: 1) }
    static var MaroonColor: DynamicColor       { DynamicColor(r: 80, g: 4, b: 28, a: 1) }
    static var WatermelonColor: DynamicColor   { DynamicColor(r: 242, g: 71, b: 63, a: 1) }
    static var TomatoColor: DynamicColor       { DynamicColor(r: 255, g: 99, b: 71, a: 1) }
    static var PinkLipstickColor: DynamicColor { DynamicColor(r: 255, g: 105, b: 180, a: 1) }
    static var PaleRoseColor: DynamicColor     { DynamicColor(r: 255, g: 228, b: 225, a: 1) }
    static var CrimsonColor: DynamicColor      { DynamicColor(r: 187, g: 18, b: 36, a: 1) }
    
    // MARK: Purples
    static var EggplantColor: DynamicColor     { DynamicColor(r: 105, g: 5, b: 98, a: 1) }
    static var PastelPurpleColor: DynamicColor { DynamicColor(r: 207, g: 100, b: 235, a: 1) }
    static var PalePurpleColor: DynamicColor   { DynamicColor(r: 229, g: 180, b: 235, a: 1) }
    static var CoolPurpleColor: DynamicColor   { DynamicColor(r: 140, g: 93, b: 228, a: 1) }
    static var VioletColor: DynamicColor       { DynamicColor(r: 191, g: 95, b: 255, a: 1) }
    static var PlumColor: DynamicColor         { DynamicColor(r: 139, g: 102, b: 139, a: 1) }
    static var LavenderColor: DynamicColor     { DynamicColor(r: 204, g: 153, b: 204, a: 1) }
    static var RaspberryColor: DynamicColor    { DynamicColor(r: 135, g: 38, b: 87, a: 1) }
    static var FuschiaColor: DynamicColor      { DynamicColor(r: 255, g: 20, b: 147, a: 1) }
    static var GrapeColor: DynamicColor        { DynamicColor(r: 54, g: 11, b: 88, a: 1) }
    static var PeriwinkleColor: DynamicColor   { DynamicColor(r: 135, g: 159, b: 237, a: 1) }
    static var OrchidColor: DynamicColor       { DynamicColor(r: 218, g: 112, b: 214, a: 1) }
    
    // MARK: Yellows
    static var GoldenrodColor: DynamicColor    { DynamicColor(r: 215, g: 170, b: 51, a: 1) }
    static var YellowGreenColor: DynamicColor  { DynamicColor(r: 192, g: 242, b: 39, a: 1) }
    static var BananaColor: DynamicColor       { DynamicColor(r: 229, g: 227, b: 58, a: 1) }
    static var MustardColor: DynamicColor      { DynamicColor(r: 205, g: 171, b: 45, a: 1) }
    static var ButtermilkColor: DynamicColor   { DynamicColor(r: 254, g: 241, b: 181, a: 1) }
    static var GoldColor: DynamicColor         { DynamicColor(r: 139, g: 117, b: 18, a: 1) }
    static var CreamColor: DynamicColor        { DynamicColor(r: 240, g: 226, b: 187, a: 1) }
    static var LightCreamColor: DynamicColor   { DynamicColor(r: 240, g: 238, b: 215, a: 1) }
    static var WheatColor: DynamicColor        { DynamicColor(r: 240, g: 238, b: 215, a: 1) }
    static var BeigeColor: DynamicColor        { DynamicColor(r: 245, g: 245, b: 220, a: 1) }
    
    // MARK: Oranges
    static var PeachColor: DynamicColor        { DynamicColor(r: 242, g: 187, b: 97, a: 1) }
    static var BurntOrangeColor: DynamicColor  { DynamicColor(r: 184, g: 102, b: 37, a: 1) }
    static var PastelOrangeColor: DynamicColor { DynamicColor(r: 248, g: 197, b: 143, a: 1) }
    static var CantaloupeColor: DynamicColor   { DynamicColor(r: 250, g: 154, b: 79, a: 1) }
    static var CarrotColor: DynamicColor       { DynamicColor(r: 237, g: 145, b: 33, a: 1) }
    static var MandarinColor: DynamicColor     { DynamicColor(r: 247, g: 145, b: 55, a: 1) }
    
    // MARK: Browns
    static var ChiliPowderColor: DynamicColor  { DynamicColor(r: 199, g: 63, b: 23, a: 1) }
    static var BurntSiennaColor: DynamicColor  { DynamicColor(r: 138, g: 54, b: 15, a: 1) }
    static var ChocolateColor: DynamicColor    { DynamicColor(r: 94, g: 38, b: 5, a: 1) }
    static var CoffeeColor: DynamicColor       { DynamicColor(r: 141, g: 60, b: 15, a: 1) }
    static var CinnamonColor: DynamicColor     { DynamicColor(r: 123, g: 63, b: 9, a: 1) }
    static var AlmondColor: DynamicColor       { DynamicColor(r: 196, g: 142, b: 72, a: 1) }
    static var EggshellColor: DynamicColor     { DynamicColor(r: 252, g: 230, b: 201, a: 1) }
    static var SandColor: DynamicColor         { DynamicColor(r: 222, g: 182, b: 151, a: 1) }
    static var MudColor: DynamicColor          { DynamicColor(r: 70, g: 45, b: 29, a: 1) }
    static var SiennaColor: DynamicColor       { DynamicColor(r: 160, g: 82, b: 45, a: 1) }
    static var DustColor: DynamicColor         { DynamicColor(r: 236, g: 214, b: 197, a: 1) }
}
