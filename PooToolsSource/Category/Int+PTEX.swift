//
//  Int+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/21.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public enum PTMontiStatusType:Int {
    case Feb
    case Big
    case Small
}

public extension Int {
    //MARK: 隨機數
    ///隨機數
    func random()->Int {
        Int(arc4random_uniform(UInt32(self)))
    }
    
    //MARK: 这是一个内置函数
    ///这是一个内置函数
    /// - Parameters:
    ///   - lower: 内置为 0，可根据自己要获取的随机数进行修改。
    ///   - upper: 内置为 UInt32.max 的最大值，这里防止转化越界，造成的崩溃。
    /// - Returns: [lower,upper) 之间的半开半闭区间的数。
    static func randomIntNumber(lower: Int = 0, 
                                upper: Int = Int(UInt32.max)) -> Int {
        lower + Int(arc4random_uniform(UInt32(upper - lower)))
    }
    
    //MARK: 生成某个区间的随机数
    ///生成某个区间的随机数
    static func randomIntNumber(range: Range<Int>) -> Int {
        randomIntNumber(lower: range.lowerBound, upper: range.upperBound)
    }
    
    //MARK: 是否是偶数
    ///是否是偶数
    /// - Returns: 结果
    func isEven() -> Bool {
        self % 2 == 0
    }
    
    //MARK: 检查月份状态(大,小,二月)
    ///检查月份状态(大,小,二月)
    func monthStatus() -> PTMontiStatusType {
        switch self {
        case 1,3,5,7,8,10,12:
            return .Big
        case 2:
            return .Feb
        default:
            return .Small
        }
    }
    
    func repetitions(task:(Int) -> Void) {
        for i in 0..<self {
            task(i)
        }
    }
    
    func toBool() -> Bool {
        if self <= 0 {
            return false
        } else {
            return true
        }
    }
    
    static func displaySmartText(for number: Int) -> String {
        if number < 1000 {
            if number <= 11 {
                return "\(number)"
            }
            let digits = Int(log10(Double(number)))
            let base = Int(pow(10.0, Double(digits)))
            let rounded = (number / base) * base
            return "\(rounded)+"
        } else if number < 1_000_000 {
            let formatted = Double(number) / 1000
            return formatNumber(formatted) + "k+"
        } else {
            let formatted = Double(number) / 1_000_000
            return formatNumber(formatted) + "M+"
        }
    }

    private static func formatNumber(_ num: Double) -> String {
        return num.truncatingRemainder(dividingBy: 1) == 0 ?
            String(format: "%.0f", num) :
            String(format: "%.1f", num)
    }
}

extension Int: PTNumberValueAdapterable {
    public typealias PTNumberValueAdapterType = Int
    public var adapter: Int {
        let scale = adapterScale()
        let value = Double(self) * scale
        return Int(value)
    }
}
