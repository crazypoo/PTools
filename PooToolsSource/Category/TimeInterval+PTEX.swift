//
//  TimeInterval+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwiftDate

public extension TimeInterval {
    var formattedString: String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: self)
    }

    //MARK: 時間戳轉換成Date
    ///時間戳轉換成Date
    func timeToDate(timeZone:TimeZone = TimeZone.current) -> Date {
        Date(timeIntervalSince1970: self).addingTimeInterval(TimeInterval(timeZone.secondsFromGMT()))
    }

    func timeToDateWithFormatter(timeZone: TimeZone = TimeZone.current) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: Date(timeIntervalSince1970: self))
        return dateFormatter.date(from: dateString)!
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
        }
        var Min = Int(self / 60)
        let Sec = Int(self.truncatingRemainder(dividingBy: 60))
        var Hour = 0
        if Min>=60 {
            Hour = Int(Min / 60)
            Min = Min - Hour*60
            callBack?(String(format: "%02d", Hour),String(format: "%02d", Min),String(format: "%02d", Sec))
        }
        callBack?("00",String(format: "%02d", Min),String(format: "%02d", Sec))
    }
    
    func conversationTimeSet() -> String? {
        var timeInterval = self;
        if(self > 140000000000) {
            timeInterval = self / 1000;
        }
        let ret = timeInterval.timeToDate()

        if ret.isToday {
            return ret.dateFormat(formatString: "HH:mm")
        } else if ret.isInCurrentWeek {
            if ret.isYesterday {
                return "昨天" + " " + ret.dateFormat(formatString: "HH:mm")
            } else {
                return ret.weekdayName(.default,locale: Locales.chinese)
            }
        } else if ret.isInCurrentYear {
            return ret.dateFormat(formatString: "MM-dd")
        } else {
            return ret.dateFormat(formatString: "yyyy-MM-dd HH:mm:ss")
        }
    }
}
