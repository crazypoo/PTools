//
//  NSDate+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 3/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension NSDate {
    //MARK: 判斷當前時間是否在某時間段內
    /// 判斷當前時間是否在某時間段內
    static func nowTimeInTimePeriod(start:Int,end:Int)->Bool
    {
        if start > end && start > 23 && end > 23
        {
            return false
        }
        
        let date = NSDate()
        let cal :NSCalendar = NSCalendar.current as NSCalendar
        let components : NSDateComponents = cal.components(.hour, from: date as Date) as NSDateComponents
        if components.hour >= end || components.hour < start
        {
            return false
        }
        else
        {
            return true
        }
    }
        
    //MARK: 判斷當前時間是否屬於白天
    /// 判斷當前時間是否屬於白天
    static func nowIsDayTime()->Bool
    {
        return NSDate.nowTimeInTimePeriod(start: 6, end: 19)
    }
    
    //MARK: 判斷當前時間是否屬於凌晨
    /// 判斷當前時間是否屬於凌晨
    static func nowIsEarlyMorning()->Bool
    {
        return NSDate.nowTimeInTimePeriod(start: 0, end: 6)
    }
    
    //MARK: 判斷當前時間是否屬於晚上
    /// 判斷當前時間是否屬於晚上
    static func nowIsNightTime()->Bool
    {
        return NSDate.nowTimeInTimePeriod(start: 19, end: 23)
    }
}
