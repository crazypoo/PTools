//
//  PTMarcos_swift.swift
//  Diou
//
//  Created by ken lam on 2021/10/19.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import DeviceKit

public let AppWindows = UIApplication.shared.delegate?.window!

public let Gobal_device_isSimulator = Device.current.isSimulator
public let Gobal_device_info = Device.current
public let Gobal_group_of_all_iPad:[Device] = Device.allPads
public let Gobal_group_of_all_plus_device:[Device] = Device.allPlusSizedDevices
public let Gobal_group_of_all_X_device:[Device] = Device.allDevicesWithSensorHousing
public let Gobal_group_of_all_small_device:[Device] = [.iPhone5,.iPhone5c,.iPhone5s,.iPodTouch5,.iPodTouch6,.iPodTouch7,.iPhone6,.iPhone7,.iPhone8,.iPhoneSE,.iPhoneSE2,.iPhone12Mini,.iPhone13Mini,.simulator(.iPhone5),.simulator(.iPhone5c),.simulator(.iPhone5s),.simulator(.iPodTouch5),.simulator(.iPodTouch6),.simulator(.iPodTouch7),.simulator(.iPhone6),.simulator(.iPhone7),.simulator(.iPhone8),.simulator(.iPhoneSE),.simulator(.iPhoneSE2),.simulator(.iPhone12Mini),.simulator(.iPhone13Mini)]

public var isXModel: Bool {
    if #available(iOS 11, *) {
        guard let w = UIApplication.shared.delegate?.window, let unwrapedWindow = w else {
            return false
        }
        if unwrapedWindow.safeAreaInsets.left > 0 || unwrapedWindow.safeAreaInsets.bottom > 0 {
            return true
        }
    }
    return false
}

/*! @brief 当前屏幕宽度
 */
public let kSCREEN_WIDTH = UIScreen.main.bounds.size.width
/*! @brief 当前屏幕高度
 */
public let kSCREEN_HEIGHT = UIScreen.main.bounds.size.height
/*! @brief 当前屏幕Bounds
 */
public let kSCREEN_BOUNDS = UIScreen.main.bounds
/*! @brief 当前屏幕Size
 */
public let kSCREEN_SIZE = kSCREEN_BOUNDS.size
/*! @brief 当前屏幕比例
 */
public let kSCREEN_SCALE = UIScreen.main.scale

public let kNavBarHeight : CGFloat = 44
/// 状态栏默认高度
public var kStatusBarHeight: CGFloat {
    if #available(iOS 14.0, *)
    {
        return isXModel ? 48 : 20
    }
    return isXModel ? 44 : 20
}

public let kNavBarHeight_Total : CGFloat = kNavBarHeight + kStatusBarHeight

public let kTabbarSaveAreaHeight : CGFloat = isXModel ? 34 : 0

public let kTabbarHeight : CGFloat = 49

public let kTabbarHeight_Total : CGFloat = kTabbarSaveAreaHeight + kTabbarHeight

// MARK: - app版本&设备系统版本
public let infoDictionary            = Bundle.main.infoDictionary
/* App显示名称 */
public let kAppDisplayName: String?         = infoDictionary!["CFBundleDisplayName"] as? String
/* App名称 */
public let kAppName: String?         = infoDictionary!["CFBundleName"] as? String
/* App版本号 */
public let kAppVersion: String?      = infoDictionary!["CFBundleShortVersionString"] as? String
/* Appbuild版本号 */
public let kAppBuildVersion: String? = infoDictionary!["CFBundleVersion"] as? String
/* app bundleId */
public let kAppBundleId: String?     = infoDictionary!["CFBundleIdentifier"] as? String
/* 平台名称（iphonesimulator 、 iphone）*/
public let kPlatformName: String?    = infoDictionary!["DTPlatformName"] as? String
/* iOS系统版本 */
public let kiOSVersion: String       = UIDevice.current.systemVersion
/* 系统名称+版本，e.g. @"iOS 12.1" */
public let kOSType: String           = UIDevice.current.systemName + UIDevice.current.systemVersion
