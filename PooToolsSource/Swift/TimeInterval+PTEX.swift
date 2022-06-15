//
//  TimeInterval+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension TimeInterval
{
    func timeToDate() -> Date {
        return Date.init(timeIntervalSince1970: self)
    }
    
    func msTimeToDate() -> Date {
        let timeSta:TimeInterval = TimeInterval(self / 1000)
        return Date.init(timeIntervalSince1970: timeSta)
    }
    
    func getFormatPlayTime()->String
    {
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
}
