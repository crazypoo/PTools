//
//  Number+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

//MARK: 阿拉伯数字转中文
public extension BinaryInteger {
    var chinese: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .spellOut
        return formatter.string(from: NSDecimalNumber(string: "\(self)")) ?? ""
    }
}

//MARK: 阿拉伯数字转中文
public extension BinaryFloatingPoint {
    var chinese: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .spellOut
        return formatter.string(from: NSDecimalNumber(string: "\(self)")) ?? ""
    }
}
