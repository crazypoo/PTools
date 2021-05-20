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

struct UI {
    static let screenSize: CGSize = UIScreen.main.bounds.size
    static let screenWidth: CGFloat = screenSize.width
    static let screenHeigth: CGFloat = screenSize.height
    
     static var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            let statusManager = UIApplication.shared.windows.first?.windowScene?.statusBarManager
            return statusManager?.statusBarFrame.height ?? 20.0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }

    static var navigationBarHeight: CGFloat {
        return 44.0
    }
    
    static var navigationBarMaxY: CGFloat {
        return 44 + statusBarHeight;
    }
    
    static var homeBarHeight: CGFloat {
        var height: CGFloat
        if PTAppDeviceInfo.deviceIsiPhone() {
            if statusBarHeight >= 44 { //刘海屏幕手机，有homeBar
                height = 34
            }else {
                height = 0
            }
            return height
        }
        if PTAppDeviceInfo.deviceIsiPad() {
            if tabBarHeight > 48 {
                return 15.0
            }else {
               return 0.0
            }
        }
        return 0.0
    }

    static var tabBarHeight: CGFloat { // include homeBar
        let tabVC = UITabBarController()
        return tabVC.tabBar.frame.size.height
    }
}
