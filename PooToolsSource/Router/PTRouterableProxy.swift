//
//  PTRouterableProxy.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/21/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation

// 定义枚举
struct PTRouterPriorityType: OptionSet {
    let rawValue: UInt

    static let low = PTRouterPriorityType(rawValue: 1000)
    static let `default` = PTRouterPriorityType(rawValue: 1001)
    static let high = PTRouterPriorityType(rawValue: 1002)
}

// 定义协议
protocol PTRouterableProxy: AnyObject {
    // 使用类方法替代静态属性
    static func patternString() -> [String]

    // 可选方法
    static var priority: UInt { get }
}
