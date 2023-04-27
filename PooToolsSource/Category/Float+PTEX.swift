//
//  Float+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/21.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

extension Float: PTProtocolCompatible {}

public extension Float {
    //MARK: 单精度的随机数
    ///单精度的随机数
    static func randomFloatNumber(lower: Float = 0, upper: Float = 100) -> Float {
        return (Float(arc4random()) / Float(UInt32.max)) * (upper - lower) + lower
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
        return (self.base * divisor).rounded() / divisor
    }
    
    //MARK: 一个数字四舍五入返回(建议使用这个)
    ///一个数字四舍五入返回(建议使用这个)
    /// - Parameters:
    ///   - value: 值
    ///   - scale: 保留小数的位数
    /// - Returns: 四舍五入返回结果
    func rounding(scale: Int16 = 1) -> Float {
        let value = NSDecimalNumberHandler.pt.rounding(value: self.base, scale: scale)
        return value.floatValue
    }
}
