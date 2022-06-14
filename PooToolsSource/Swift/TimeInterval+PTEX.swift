//
//  TimeInterval+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension TimeInterval {
    func timeToDate() -> Date {
        return Date.init(timeIntervalSince1970: self)
    }
    func msTimeToDate() -> Date {
        let timeSta:TimeInterval = TimeInterval(self / 1000)
        return Date.init(timeIntervalSince1970: timeSta)
    }
}
