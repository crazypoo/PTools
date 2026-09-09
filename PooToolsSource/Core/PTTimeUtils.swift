//
//  PTTimeUtils.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Foundation

public class PTTimeUtils {
    
    /// 获取当前时间字符串
    /// - Parameters:
    ///   - formatString: 日期格式，默认为 "yyyy-MM-dd"
    ///   - timeZoneIdentifier: 时区标识符，默认为亚洲/上海 (东八区)
    /// - Returns: 格式化后的时间字符串
    // English: Use a formatter local to the call so concurrent requests never mutate shared DateFormatter state.
    // Español: Usa un formateador local a cada llamada para que las solicitudes concurrentes no muten un estado compartido.
    // 中文：每次调用使用独立的格式化器，避免并发请求修改共享的 DateFormatter 状态。
    public static func currentDate(formatString: String = "yyyy-MM-dd", timeZoneIdentifier: String = "Asia/Shanghai") -> String {
        let formatter = DateFormatter()
        // English: POSIX locale keeps formatting stable across user calendar and 12/24-hour preferences.
        // Español: La configuración regional POSIX mantiene estable el formato frente al calendario y al reloj del usuario.
        // 中文：POSIX 区域设置避免用户日历和 12/24 小时制影响格式化结果。
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // 1. 设置日期格式
        formatter.dateFormat = formatString
        
        // 2. 【关键修复 1】使用 identifier 而不是 abbreviation 来安全地获取时区
        // 如果传入的 identifier 无效，安全起见回退到当前系统时区（或你可以指定回退到 GMT）
        if let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            formatter.timeZone = timeZone
        } else {
            // 备选方案：通过秒数硬编码东八区 TimeZone(secondsFromGMT: 8 * 3600)
            formatter.timeZone = TimeZone.current
            PTNSLogConsole("警告: 无效的时区标识符 \(timeZoneIdentifier)，已回退到当前时区")
        }
        
        // 3. 返回当前格式化后的字符串
        return formatter.string(from: Date())
    }
}
