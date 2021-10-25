//
//  PTAppDeviceInfo.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/1/10.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit

struct PTAppDeviceInfo {
    static func deviceIsiPhone() -> Bool
    {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { (identifier, element) in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.contains("iPhone")
    }
    
    static func deviceIsiPad() -> Bool
    {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.contains("iPad")
    }
}
