//
//  Timer+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public extension Timer {
    // MARK: 类方法创建定时器
    ///  创建定时器
    /// - Parameters:
    ///   - timeInterval: 时间间隔
    ///   - repeats: 是否重复执行
    ///   - block: 执行代码的block
    /// - Returns: 返回 Timer
    @discardableResult
    static func scheduledTimer(timeInterval: TimeInterval,
                               repeats: Bool,
                               block: @escaping ((Timer) -> Void)) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: repeats, block: block)
    }
}
