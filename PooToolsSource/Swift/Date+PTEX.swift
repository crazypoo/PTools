//
//  Date+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

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
}
