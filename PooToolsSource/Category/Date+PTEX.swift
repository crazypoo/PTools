//
//  Date+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SwiftDate

extension Date: PTProtocolCompatible {}
//MARK: 时间戳的类型
/// 时间戳的类型
public enum PTTimestampType: Int {
    /// 秒
    case second
    /// 毫秒
    case millisecond
}

//MARK: 時間對比狀態
///時間對比狀態
@objc public enum CheckContractTimeRelationships: Int {
    ///過期
    case Expire
    ///準備過期
    case ReadyExpire
    ///正常
    case Normal
    ///未知錯誤
    case Error
}

public extension Date {
    //MARK: 获取到今天是周几 1(星期天) 2(星期一) 3(星期二) 4(星期三) 5(星期四) 6(星期五) 7(星期六)
    ///获取到今天是周几 1(星期天) 2(星期一) 3(星期二) 4(星期三) 5(星期四) 6(星期五) 7(星期六)
    func getWeekDayType() -> Int? {
        let calendar = Calendar.current
        let dateComponets = calendar.dateComponents([Calendar.Component.year,Calendar.Component.month,Calendar.Component.weekday,Calendar.Component.day], from: self)
        return dateComponets.weekday
    }
    
    func getWeekDayFromeDate() -> String {
        let weekDay = self.getWeekDayType()
        var weekDayStr = ""
        switch weekDay {
        case 1:
            weekDayStr = "PT Date sunday".localized()
            break
        case 2:
            weekDayStr =  "PT Date monday".localized()
            break
        case 3:
            weekDayStr = "PT Date tuesday".localized()
            break
        case 4:
            weekDayStr = "PT Date wednesday".localized()
            break
        case 5:
            weekDayStr = "PT Date thursday".localized()
            break
        case 6:
            weekDayStr = "PT Date friday".localized()
            break
        case 7:
            weekDayStr = "PT Date saturday".localized()
            break
        default:
            weekDayStr = ""
            break
        }
        return weekDayStr
    }
    
    //MARK: 根據時間格式來獲取時間
    ///根據時間格式來獲取時間
    func getTimeStr(dateFormat:String = "yyyy-MM-dd") -> String {
        let dformatter = DateFormatter()
        dformatter.dateFormat = dateFormat
        return dformatter.string(from: self)
    }
    
    //MARK: 根據時間格式來獲取當前時間戳
    ///根據時間格式來獲取當前時間戳
    func getCurrentDate(dateFormatterString:String) -> TimeInterval {
        let dformatter = DateFormatter()
        dformatter.dateFormat = dateFormatterString
        if let timeDate = dformatter.date(from: String.currentDate(dateFormatterString: dateFormatterString)) {
            let timeInterval = timeDate.timeIntervalSince1970
            return timeInterval
        } else {
            return 0
        }
    }
    
    //MARK: 獲取時區的當前時間戳
    ///獲取時區的當前時間戳
    func getTimeStamp() -> String {
        return String(format: "%.0f", self.getTimeInterval())
    }
    
    func getTimeInterval() -> TimeInterval {
        return Date().timeIntervalSince1970
    }

    //MARK: Date格式化
    ///Date格式化
    func dateFormat(formatString:String = "yyyy-MM-dd") -> String {
        self.toFormat(formatString)
    }
    
    //MARK: 合同时间状态检测
    ///合同时间状态检测
    /// - Parameters:
    ///   - begainTime: 開始時間
    ///   - endTime: 結束時間
    ///   - readyExpTime: 多久過期
    /// - Returns : 狀態
    static func checkContractTimeType(begainTime:String,
                                      endTime:String,
                                      readyExpTime:Int) -> CheckContractTimeRelationships {
        let begainTimeDate = begainTime.toDate("yyyy-MM-dd")!
        let endTimeDate = endTime.toDate("yyyy-MM-dd")!
        let timeDifference = endTimeDate.timeIntervalSince(begainTimeDate)
        let thirty = NSNumber(integerLiteral: readyExpTime).floatValue
        let result = timeDifference.float - thirty
        if result > (-thirty) && result < thirty {
            return .ReadyExpire
        } else if result < (-thirty) {
            return .Expire
        } else if result > 0 {
            return .Normal
        } else {
            return .Error
        }
    }
    
    //MARK: 合同时间状态检测
    ///合同时间状态检测
    /// - Parameters:
    ///   - endTime: 結束時間
    ///   - readyExpTime: 多久過期
    /// - Returns : 狀態
    static func checkContractTimeType_now(endTime:String,
                                          readyExpTime:Int) -> CheckContractTimeRelationships {
        Date.checkContractTimeType(begainTime: Date().toFormat("yyyy-MM-dd"), endTime: endTime, readyExpTime: readyExpTime)
    }
}

public extension PTPOP where Base == Date {
    // MARK: Date 转 时间戳
    /// Date 转 时间戳
    /// - Parameter timestampType: 返回的时间戳类型，默认是秒 10 为的时间戳字符串
    /// - Returns: 时间戳
    func dateToTimeStamp(timestampType: PTTimestampType = .second) -> String {
        // 10位数时间戳 和 13位数时间戳
        let interval = timestampType == .second ? CLongLong(Int(base.timeIntervalSince1970)) : CLongLong(round(base.timeIntervalSince1970 * 1000))
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
    static func timestampToFormatterTimeString(timestamp: String,
                                               format: String = "yyyy-MM-dd HH:mm:ss") -> String {
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
        return jx_formatter.string(from: base)
    }
    
    // MARK: 带格式的时间转 时间戳，支持返回 13位 和 10位的时间戳，时间字符串和时间格式必须保持一致
    /// 带格式的时间转 时间戳，支持返回 13位 和 10位的时间戳，时间字符串和时间格式必须保持一致
    /// - Parameters:
    ///   - timeString: 时间字符串，如：2020-10-26 16:52:41
    ///   - timesString:
    ///   - formatter: 时间格式，如：yyyy-MM-dd HH:mm:ss
    ///   - timestampType: 返回的时间戳类型，默认是秒 10 为的时间戳字符串
    /// - Returns: 返回转化后的时间戳
    static func formatterTimeStringToTimestamp(timesString: String, 
                                               formatter: String,
                                               timestampType: PTTimestampType = .second) -> String {
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
