//
//  PTTimeUtils.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Foundation

class PTTimeUtils {
    // 缓存 DateFormatter，避免重复创建造成的性能消耗
    // 这是一个只在第一次调用时实例化的静态属性
    private static let sharedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // 【关键修复 2】强制设置为 en_US_POSIX，避免受用户本地日历（如佛教历）和 12/24 小时制设置的影响
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// 获取当前时间字符串
    /// - Parameters:
    ///   - formatString: 日期格式，默认为 "yyyy-MM-dd"
    ///   - timeZoneIdentifier: 时区标识符，默认为亚洲/上海 (东八区)
    /// - Returns: 格式化后的时间字符串
    static func currentDate(formatString: String = "yyyy-MM-dd", timeZoneIdentifier: String = "Asia/Shanghai") -> String {
        
        // 1. 设置日期格式
        sharedFormatter.dateFormat = formatString
        
        // 2. 【关键修复 1】使用 identifier 而不是 abbreviation 来安全地获取时区
        // 如果传入的 identifier 无效，安全起见回退到当前系统时区（或你可以指定回退到 GMT）
        if let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            sharedFormatter.timeZone = timeZone
        } else {
            // 备选方案：通过秒数硬编码东八区 TimeZone(secondsFromGMT: 8 * 3600)
            sharedFormatter.timeZone = TimeZone.current
            PTNSLogConsole("警告: 无效的时区标识符 \(timeZoneIdentifier)，已回退到当前时区")
        }
        
        // 3. 返回当前格式化后的字符串
        return sharedFormatter.string(from: Date())
    }
}
