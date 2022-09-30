//
//  Date+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

extension Date: PTProtocolCompatible {}
/// 时间戳的类型
public enum PTTimestampType: Int {
    /// 秒
    case second
    /// 毫秒
    case millisecond
}

public extension Date {
    func getWeedayFromeDate() -> String {
        let calendar = Calendar.current
        let dateComponets = calendar.dateComponents([Calendar.Component.year,Calendar.Component.month,Calendar.Component.weekday,Calendar.Component.day], from: self)
        //获取到今天是周几 1(星期天) 2(星期一) 3(星期二) 4(星期三) 5(星期四) 6(星期五) 7(星期六)
        let weekDay = dateComponets.weekday
        var weekDayStr = ""
        switch weekDay {
        case 1:
            weekDayStr = "星期天"
            break
        case 2:
            weekDayStr =  "星期一"
            break
        case 3:
            weekDayStr = "星期二"
            break
        case 4:
            weekDayStr = "星期三"
            break
        case 5:
            weekDayStr = "星期四"
            break
        case 6:
            weekDayStr = "星期五"
            break
        case 7:
            weekDayStr = "星期六"
            break
        default:
            weekDayStr = ""
            break
        }
        return weekDayStr
    }
    
    func getTimeStr(dateFormat:String = "yyyy-MM-dd") -> String {
        let dformatter = DateFormatter()
        dformatter.dateFormat = dateFormat
        return dformatter.string(from: self)
    }
    
    func getCurrentDate(dateFormatterString:String)->TimeInterval
    {
        let dformatter = DateFormatter()
        dformatter.dateFormat = dateFormatterString
        let timeDate = dformatter.date(from: String.currentDate(dateFormatterString: dateFormatterString))
        let timeInterval = timeDate!.timeIntervalSince1970
        return timeInterval
    }
}

public extension PTProtocol where Base == Date {
    // MARK: Date 转 时间戳
    /// Date 转 时间戳
    /// - Parameter timestampType: 返回的时间戳类型，默认是秒 10 为的时间戳字符串
    /// - Returns: 时间戳
    func dateToTimeStamp(timestampType: PTTimestampType = .second) -> String {
        // 10位数时间戳 和 13位数时间戳
        let interval = timestampType == .second ? CLongLong(Int(self.base.timeIntervalSince1970)) : CLongLong(round(self.base.timeIntervalSince1970 * 1000))
        return "\(interval)"
    }
    
    // MARK: 时间戳(支持 10 位 和 13 位) 转 Date
    /// 时间戳(支持 10 位 和 13 位) 转 Date
    /// - Parameter timestamp: 时间戳
    /// - Returns: 返回 Date
    static func timestampToFormatterDate(timestamp: String) -> Date {
        guard timestamp.count == 10 ||  timestamp.count == 13 else {
            #if DEBUG
            fatalError("时间戳位数不是 10 也不是 13")
            #else
            return Date()
            #endif
        }
        guard let timestampInt = timestamp.int else {
            #if DEBUG
            fatalError("时间戳位有问题")
            #else
            return Date()
            #endif
        }
        let timestampValue = timestamp.count == 10 ? timestampInt : timestampInt / 1000
        // 时间戳转为Date
        let date = Date(timeIntervalSince1970: TimeInterval(timestampValue))
        return date
    }
    
    // MARK: 时间戳(支持10位和13位)按照对应的格式 转化为 对应时间的字符串
    /// 时间戳(支持10位和13位)按照对应的格式 转化为 对应时间的字符串 如：1603849053 按照 "yyyy-MM-dd HH:mm:ss" 转化后为：2020-10-28 09:37:33
    /// - Parameters:
    ///   - timestamp: 时间戳
    ///   - format: 格式
    /// - Returns: 对应时间的字符串
    static func timestampToFormatterTimeString(timestamp: String, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        // 时间戳转为Date
        let date = timestampToFormatterDate(timestamp: timestamp)
        // let dateFormatter = DateFormatter()
        // 设置 dateFormat
        jx_formatter.dateFormat = format
        // 按照dateFormat把Date转化为String
        return jx_formatter.string(from: date)
    }

    // MARK: Date 转换为相应格式的时间字符串，如 Date 转为 2020-10-28
    /// Date 转换为相应格式的字符串，如 Date 转为 2020-10-28
    /// - Parameter format: 转换的格式
    /// - Returns: 返回具体的字符串
    func toformatterTimeString(formatter: String = "yyyy-MM-dd HH:mm:ss") -> String {
        // let dateFormatter = DateFormatter()
        jx_formatter.timeZone = TimeZone.autoupdatingCurrent
        jx_formatter.dateFormat = formatter
        return jx_formatter.string(from: self.base)
    }
    
    // MARK: 带格式的时间转 时间戳，支持返回 13位 和 10位的时间戳，时间字符串和时间格式必须保持一致
    /// 带格式的时间转 时间戳，支持返回 13位 和 10位的时间戳，时间字符串和时间格式必须保持一致
    /// - Parameters:
    ///   - timeString: 时间字符串，如：2020-10-26 16:52:41
    ///   - formatter: 时间格式，如：yyyy-MM-dd HH:mm:ss
    ///   - timestampType: 返回的时间戳类型，默认是秒 10 为的时间戳字符串
    /// - Returns: 返回转化后的时间戳
    static func formatterTimeStringToTimestamp(timesString: String, formatter: String, timestampType: PTTimestampType = .second) -> String {
        jx_formatter.dateFormat = formatter
        guard let date = jx_formatter.date(from: timesString) else {
            #if DEBUG
            fatalError("时间有问题")
            #else
            return ""
            #endif
        }
        if timestampType == .second {
            return "\(Int(date.timeIntervalSince1970))"
        }
        return "\(Int((date.timeIntervalSince1970) * 1000))"
    }

}
