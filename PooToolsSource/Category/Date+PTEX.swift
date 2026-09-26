//
//  Date+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

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
    /// English: Reports whether the date belongs to the current calendar week.
    /// Español: Indica si la fecha pertenece a la semana calendario actual.
    /// 中文：判断日期是否属于当前日历周。
    var isInCurrentWeek: Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.component(.weekOfYear, from: self) == calendar.component(.weekOfYear, from: now)
            && calendar.component(.yearForWeekOfYear, from: self) == calendar.component(.yearForWeekOfYear, from: now)
    }

    /// English: Reports whether the date belongs to the current calendar year.
    /// Español: Indica si la fecha pertenece al año calendario actual.
    /// 中文：判断日期是否属于当前日历年。
    var isInCurrentYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    //MARK: 获取到今天是周几 1(星期天) 2(星期一) 3(星期二) 4(星期三) 5(星期四) 6(星期五) 7(星期六)
    ///获取到今天是周几 1(星期天) 2(星期一) 3(星期二) 4(星期三) 5(星期四) 6(星期五) 7(星期六)
    func getWeekDayType() -> Int? {
        let calendar = Calendar.autoupdatingCurrent
        let dateComponets = calendar.dateComponents([Calendar.Component.year,Calendar.Component.month,Calendar.Component.weekday,Calendar.Component.day], from: self)
        return dateComponets.weekday
    }
    
    @MainActor func getWeekDayFromeDate() -> String {
        zoned(in: .autoupdatingCurrent).weekdayName(.full)
    }
    
    //MARK: 根據時間格式來獲取時間
    ///根據時間格式來獲取時間
    func getTimeStr(dateFormat:String = "yyyy-MM-dd") -> String {
        zoned(in: .autoupdatingCurrent).formatted(pattern: dateFormat)
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
        timeIntervalSince1970
    }

    //MARK: Date格式化
    /// English: Formats the instant in the current display context.
    /// Español: Formatea el instante en el contexto de visualización actual.
    /// 中文：使用当前显示语境格式化绝对时间点。
    func dateFormat(formatString:String = "yyyy-MM-dd") -> String {
        zoned(in: .autoupdatingCurrent).formatted(pattern: formatString)
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
        guard let begainTimeDate = try? PTDateParser.parse(begainTime,
                                                           strategy: .pattern("yyyy-MM-dd"),
                                                           context: .current),
              let endTimeDate = try? PTDateParser.parse(endTime,
                                                        strategy: .pattern("yyyy-MM-dd"),
                                                        context: .current) else {
            return .Error
        }
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
        Date.checkContractTimeType(begainTime: Date().dateFormat(formatString: "yyyy-MM-dd"), endTime: endTime, readyExpTime: readyExpTime)
    }
    
    /// 将「已知为柬埔寨时区的时间戳（秒或毫秒）」格式化为字符串
    /// - Parameters:
    ///   - timestamp: 传入时间戳（可能是秒或毫秒）
    ///   - dateFormat: 输出格式
    /// - Returns: 显示字符串（按设备时区显示，不重复修正 Unix 时间戳）
    static func formattedCambodiaTimestampSafe(_ timestamp: TimeInterval,
                                               timeStamplocation:TimeZone = TimeZone(identifier: "Asia/Phnom_Penh") ?? .current,
                                               timeStampOffset:TimeInterval = 0,
                                               dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> String {
        // English: Unix timestamps already represent an absolute instant; never add a regional offset again.
        // Español: Las marcas Unix ya representan un instante absoluto; nunca vuelvas a sumar un desplazamiento regional.
        // 中文：Unix 时间戳已经表示绝对时间点，不再重复叠加地域时区偏移。
        let seconds = timestamp.asSecondsSafe
        let instant = Date(timeIntervalSince1970: seconds + timeStampOffset)
        // English: Keep the legacy location parameter source-compatible; the display context is the device context.
        // Español: Conserva el parámetro heredado para compatibilidad; el contexto de pantalla es el del dispositivo.
        // 中文：保留旧时区参数以兼容源码，实际显示使用设备当前语境。
        _ = timeStamplocation
        return instant.zoned(in: .autoupdatingCurrent).formatted(pattern: dateFormat)
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
            PTNSLogConsole("时间戳位数不是 10 或 13：\(timestamp)",
                           levelType: .error,
                           loggerType: .other)
            return Date()
        }
        guard let timestampInt = timestamp.int else {
            PTNSLogConsole("时间戳无法解析：\(timestamp)",
                           levelType: .error,
                           loggerType: .other)
            return Date()
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
        // English: Keep the legacy formatter public, but use a call-local formatter to avoid shared mutable state.
        // Español: Conserva público el formateador heredado, pero usa uno local para evitar estado mutable compartido.
        // 中文：保留旧的公开格式化器，但每次调用使用局部实例，避免共享可变状态。
        return date.zoned(in: .autoupdatingCurrent).formatted(pattern: format)
    }

    // MARK: Date 转换为相应格式的时间字符串，如 Date 转为 2020-10-28
    /// Date 转换为相应格式的字符串，如 Date 转为 2020-10-28
    /// - Parameter format: 转换的格式
    /// - Returns: 返回具体的字符串
    func toformatterTimeString(formatter: String = "yyyy-MM-dd HH:mm:ss") -> String {
        return base.zoned(in: .autoupdatingCurrent).formatted(pattern: formatter)
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
        guard let date = try? PTDateParser.parse(timesString,
                                                 strategy: .pattern(formatter),
                                                 context: .autoupdatingCurrent) else {
            PTNSLogConsole("时间字符串无法解析：\(timesString)",
                           levelType: .error,
                           loggerType: .other)
            return ""
        }
        if timestampType == .second {
            return "\(Int(date.timeIntervalSince1970))"
        }
        return "\(Int((date.timeIntervalSince1970) * 1000))"
    }
}
