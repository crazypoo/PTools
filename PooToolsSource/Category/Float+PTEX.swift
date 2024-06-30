//
//  Float+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/21.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import Foundation

extension Float: PTProtocolCompatible {}

public extension Float {
    //MARK: 单精度的随机数
    ///单精度的随机数
    static func randomFloatNumber(lower: Float = 0,
                                  upper: Float = 100) -> Float {
        (Float(arc4random()) / Float(UInt32.max)) * (upper - lower) + lower
    }
    
    func floatToPlayTimeString() ->String {
        var returnValue = "0:00"
        if self < 60 {
          returnValue = String(format: "0:%.02d", Int(self.rounded(.up)))
        } else if self < 3600 {
          returnValue = String(format: "%.02d:%.02d", Int(self / 60), Int(self) % 60)
        } else if self.isFinite {
          let hours = Int(self / 3600)
          let remainingMinutesInSeconds = Int(self) - hours * 3600
          returnValue = String(format: "%.02d:%.02d:%.02d", hours, Int(remainingMinutesInSeconds / 60), Int(remainingMinutesInSeconds) % 60)
        }
        return returnValue
    }
}

public extension PTPOP where Base == Float {

    //MARK:  浮点数四舍五入
    ///浮点数四舍五入
    /// - Parameters:
    ///   - places: 小数保留的位数
    /// - Returns: 保留后的小数
    func roundTo(places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (base * divisor).rounded() / divisor
    }
    
    //MARK: 一个数字四舍五入返回(建议使用这个)
    ///一个数字四舍五入返回(建议使用这个)
    /// - Parameters:
    ///   - value: 值
    ///   - scale: 保留小数的位数
    /// - Returns: 四舍五入返回结果
    func rounding(scale: Int16 = 1) -> Float {
        let value = NSDecimalNumberHandler.pt.rounding(value: base, scale: scale)
        return value.floatValue
    }
}

// MARK: - BinaryFloatingPoint扩展
public extension BinaryFloatingPoint {
    
    ///    截取二进制浮点数
    ///
    ///    let num = 3.1415927
    ///    num.rounded(3, rule: .up) -> 3.142
    ///    num.rounded(3, rule: .down) -> 3.141
    ///    num.rounded(2, rule: .awayFromZero) -> 3.15
    ///    num.rounded(4, rule: .towardZero) -> 3.1415
    ///    num.rounded(-1, rule: .toNearestOrEven) -> 3
    ///
    /// - Parameters:
    ///   - places: The expected number of decimal places.
    ///   - rule: The rounding rule to use.
    /// - Returns: The rounded value.
    func rounded(_ places: Int, rule: FloatingPointRoundingRule = .up) -> Self {
        let factor = Self(pow(10.0, Double(max(0, places))))
        return (self * factor).rounded(rule) / factor
    }
}

extension Float: PTNumberValueAdapterable {
    public typealias PTNumberValueAdapterType = Float
    public var adapter: Float {
        let scale = adapterScale()
        let value = self * Float(scale)
        return value
    }
}
