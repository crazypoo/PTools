//
//  PTColorUtils.swift
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
 Clips the values in an interval.

 Given an interval, values outside the interval are clipped to the interval
 edges. For example, if an interval of [0, 1] is specified, values smaller than
 0 become 0, and values larger than 1 become 1.

 - Parameter v: The value to clipped.
 - Parameter minimum: The minimum edge value.
 - Parameter maximum: The maximum edgevalue.
 */
internal func clip<T: Comparable>(_ v: T, _ minimum: T, _ maximum: T) -> T {
    return max(min(v, maximum), minimum)
}

/// 统一的归一化 RGBA 分量。
/// Componentes RGBA normalizados y compartidos por todas las conversiones.
internal struct PTRGBAComponents: Sendable, Equatable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = clip(red.isFinite ? red : 0, 0, 1)
        self.green = clip(green.isFinite ? green : 0, 0, 1)
        self.blue = clip(blue.isFinite ? blue : 0, 0, 1)
        self.alpha = clip(alpha.isFinite ? alpha : 0, 0, 1)
    }
}

// English: Keep presentation surfaces on the native dynamic system palette.
// Español: Mantén las superficies de presentación en la paleta dinámica nativa del sistema.
// 中文：展示类组件统一使用系统原生动态颜色，避免浅色和深色模式出现不一致。
#if os(iOS) || os(tvOS) || os(watchOS)
internal extension UIColor {
    static var ptPresentationSurface: UIColor {
        .systemBackground
    }

    static var ptPresentationMaterialSurface: UIColor {
        UIColor.secondarySystemBackground.withAlphaComponent(0.82)
    }
}
#endif

/// Hex 解析后的值，保留是否包含透明度。
/// Valor hexadecimal analizado, conservando si incluye alfa.
internal struct PTHexColorValue: Sendable, Equatable {
    let components: PTRGBAComponents
    let includesAlpha: Bool
}

/// 所有颜色入口共用的 Hex 解析器。
/// Analizador hexadecimal único para todas las entradas de color.
internal enum PTHexColorParser {
    static func parse(_ value: String,
                      embeddedAlpha: Bool = true,
                      overridingAlpha: CGFloat? = nil) -> PTHexColorValue? {
        var normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasPrefix("#") {
            normalized.removeFirst()
        } else if normalized.hasPrefix("0x") || normalized.hasPrefix("0X") {
            normalized.removeFirst(2)
        }

        guard [3, 4, 6, 8].contains(normalized.count),
              let number = UInt64(normalized, radix: 16) else {
            return nil
        }

        let components: PTRGBAComponents
        let includesAlpha = normalized.count == 4 || normalized.count == 8

        switch normalized.count {
        case 3:
            let red = CGFloat((number >> 8) & 0xF) / 15
            let green = CGFloat((number >> 4) & 0xF) / 15
            let blue = CGFloat(number & 0xF) / 15
            components = PTRGBAComponents(red: red, green: green, blue: blue,
                                           alpha: overridingAlpha ?? 1)
        case 4:
            let red = CGFloat((number >> 12) & 0xF) / 15
            let green = CGFloat((number >> 8) & 0xF) / 15
            let blue = CGFloat((number >> 4) & 0xF) / 15
            let alpha = CGFloat(number & 0xF) / 15
            components = PTRGBAComponents(red: red, green: green, blue: blue,
                                           alpha: overridingAlpha ?? (embeddedAlpha ? alpha : 1))
        case 6:
            let red = CGFloat((number >> 16) & 0xFF) / 255
            let green = CGFloat((number >> 8) & 0xFF) / 255
            let blue = CGFloat(number & 0xFF) / 255
            components = PTRGBAComponents(red: red, green: green, blue: blue,
                                           alpha: overridingAlpha ?? 1)
        case 8:
            let red = CGFloat((number >> 24) & 0xFF) / 255
            let green = CGFloat((number >> 16) & 0xFF) / 255
            let blue = CGFloat((number >> 8) & 0xFF) / 255
            let alpha = CGFloat(number & 0xFF) / 255
            components = PTRGBAComponents(red: red, green: green, blue: blue,
                                           alpha: overridingAlpha ?? (embeddedAlpha ? alpha : 1))
        default:
            return nil
        }

        return PTHexColorValue(components: components, includesAlpha: includesAlpha)
    }
}

/**
 Returns the absolute value of the modulo operation.

 - Parameter x: The value to compute.
 - Parameter m: The modulo.
 */
internal func moda(_ x: CGFloat, m: CGFloat) -> CGFloat {
    return (x.truncatingRemainder(dividingBy: m) + m).truncatingRemainder(dividingBy: m)
}

/**
 Rounds the given float to a given decimal precision.
 
 - Parameter x: The value to round.
 - Parameter m: The precision. Default to 10000.
 */
internal func roundDecimal(_ x: CGFloat, precision: CGFloat = 10000.0) -> CGFloat {
    guard x.isFinite, precision.isFinite, precision > 0 else { return 0 }
    return (x * precision).rounded() / precision
}

internal func roundToHex(_ x: CGFloat) -> UInt32 {
    // 使用你的 clip 工具将输入安全地限制在 0.0...1.0 之间
    let safeX = clip(x, 0.0, 1.0)
    return UInt32(round(safeX * 255.0))
}
