//
//  TimeInterval+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension TimeInterval {
    var formattedString: String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: self)
    }

    //MARK: 時間戳轉換成Date
    /// English: Converts a Unix timestamp to an absolute Date; the time zone only affects later formatting.
    /// Español: Convierte una marca Unix en un Date absoluto; la zona solo afecta al formato posterior.
    /// 中文：将 Unix 时间戳转换为绝对 Date，时区只影响后续格式化。
    func timeToDate(timeZone:TimeZone = TimeZone.current) -> Date {
        _ = timeZone
        return Date(timeIntervalSince1970: self)
    }

    func timeToDateWithFormatter(timeZone: TimeZone = TimeZone.current) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: Date(timeIntervalSince1970: self))
        return dateFormatter.date(from: dateString) ?? Date(timeIntervalSince1970: self)
    }
    
    //MARK: 時間戳轉換成Date
    ///時間戳轉換成Date
    func msTimeToDate() -> Date {
        let timeSta:TimeInterval = TimeInterval(self / 1000)
        return Date(timeIntervalSince1970: timeSta)
    }
    
    func toTimeString(dateFormat:String) -> String {
        msTimeToDate().getTimeStr(dateFormat: dateFormat)
    }
    
    //MARK: 獲取播放時長(分:秒)
    ///獲取播放時長(分:秒)
    func getFormatPlayTime() -> String {
        if self.isNaN{
            return "00:00"
        }
        var Min = Int(self / 60)
        let Sec = Int(self.truncatingRemainder(dividingBy: 60))
        var Hour = 0
        if Min>=60 {
            Hour = Int(Min / 60)
            Min = Min - Hour*60
            return String(format: "%02d:%02d:%02d", Hour, Min, Sec)
        }
        return String(format: "00:%02d:%02d", Min, Sec)
    }
    
    //MARK: 獲取播放時長(時:分:秒)
    ///獲取播放時長(時:分:秒)
    func getFormatPlayTime(callBack:((_ h:String,_ m:String,_ s:String) -> Void)?) {
        if self.isNaN{
            callBack?("00","00","00")
            return
        }
        var Min = Int(self / 60)
        let Sec = Int(self.truncatingRemainder(dividingBy: 60))
        var Hour = 0
        if Min>=60 {
            Hour = Int(Min / 60)
            Min = Min - Hour*60
            callBack?(String(format: "%02d", Hour),String(format: "%02d", Min),String(format: "%02d", Sec))
            return
        }
        callBack?("00",String(format: "%02d", Min),String(format: "%02d", Sec))
    }
    
    /// 获取播放时长（天:时:分:秒）
    /// - Parameter callBack: 返回格式化的天、时、分、秒字符串
    func getFormatPlayTimeDHMS(callBack: ((_ d: String, _ h: String, _ m: String, _ s: String) -> Void)?) {
        guard !self.isNaN, self > 0 else {
            callBack?("00", "00", "00", "00")
            return
        }

        var seconds = Int(self)
        let days = seconds / 86400
        seconds %= 86400

        let hours = seconds / 3600
        seconds %= 3600

        let minutes = seconds / 60
        let secs = seconds % 60

        callBack?(
            String(format: "%02d", days),
            String(format: "%02d", hours),
            String(format: "%02d", minutes),
            String(format: "%02d", secs)
        )
    }

    func conversationTimeSet(yesterdayString:String = "昨天") -> String? {
        var timeInterval = self;
        if(self > 140000000000) {
            timeInterval = self / 1000;
        }
        let ret = timeInterval.timeToDate()

        let zonedDate = ret.zoned(in: .autoupdatingCurrent)
        if zonedDate.isToday {
            return zonedDate.formatted(pattern: "HH:mm")
        } else if zonedDate.context.calendar.isDate(ret, equalTo: Date(), toGranularity: .weekOfYear) {
            if zonedDate.isYesterday {
                return yesterdayString + " " + zonedDate.formatted(pattern: "HH:mm")
            } else {
                return zonedDate.weekdayName(.abbreviated)
            }
        } else if zonedDate.context.calendar.isDate(ret, equalTo: Date(), toGranularity: .year) {
            return zonedDate.formatted(pattern: "MM-dd")
        } else {
            return zonedDate.formatted(pattern: "yyyy-MM-dd HH:mm:ss")
        }
    }
    
    /// 返回以秒为单位的时间（如果是毫秒则自动 /1000）
    var asSecondsSafe: TimeInterval {
        // 如果看起来像毫秒（大于 10^11 ~ 2004 年），就除以 1000
        if self > 1_000_000_000_000 { // > ~2001-09-09 in ms
            return self / 1000.0
        } else {
            return self
        }
    }
}
