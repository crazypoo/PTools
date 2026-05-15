//
//  PTMarcos_swift.swift
//  Diou
//
//  Created by ken lam on 2021/10/19.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
@preconcurrency import DeviceKit

public let CorePodBundleName = "PooToolsResource"

public typealias PTActionUncheckTask = () -> Void
public typealias PTActionTask = @Sendable () -> Void
public typealias PTActionAsyncTask = @Sendable () async -> Void
// 2. 新增：专门用于后台/全局线程的 Task（不带 @MainActor，避免线程冲突警告）
public typealias PTBackgroundTask = @Sendable () -> Void

public typealias PTBoolTask = (Bool) -> Void

@MainActor public var AppWindows: UIWindow? {
    UIApplication.shared.currentWindow
}

//MARK: 設備信息
///設備信息
public let Gobal_device_info = Device.current
//MARK: 是否模擬器模擬器
///是否模擬器模擬器
public let Gobal_device_isSimulator = Gobal_device_info.isSimulator
//MARK: 獲取所有屬於iPad的設備
///獲取所有屬於iPad的設備
public let Gobal_group_of_all_iPad:[Device] = Device.allPads
//MARK: 獲取所有屬於Plus的設備
///獲取所有屬於Plus的設備
public let Gobal_group_of_all_plus_device:[Device] = Device.allPlusSizedDevices
//MARK: 獲取所有屬於Pro的設備
///獲取所有屬於Pro的設備
public let Gobal_group_of_all_pro_device:[Device] = Device.allProDevices
//MARK: 獲取所有屬於X的設備
///獲取所有屬於X的設備
public let Gobal_group_of_all_X_device:[Device] = Device.allDevicesWithSensorHousing
//MARK: 獲取所有屬於小屏幕的設備
///獲取所有屬於小屏幕的設備
public let Gobal_group_of_all_small_device:[Device] = [.iPhone5,.iPhone5c,.iPhone5s,.iPodTouch5,.iPodTouch6,.iPodTouch7,.iPhone6,.iPhone6s,.iPhone7,.iPhone8,.iPhoneSE,.iPhoneSE2,.iPhone12Mini,.iPhone13Mini,.iPhone14,.simulator(.iPhone5),.simulator(.iPhone5c),.simulator(.iPhone5s),.simulator(.iPodTouch5),.simulator(.iPodTouch6),.simulator(.iPodTouch7),.simulator(.iPhone6),.simulator(.iPhone7),.simulator(.iPhone8),.simulator(.iPhoneSE),.simulator(.iPhoneSE2),.simulator(.iPhone12Mini),.simulator(.iPhone13Mini),.simulator(.iPhone14),.simulator(.iPhone15),.simulator(.iPhone16),.simulator(.iPhone17),.simulator(.iPhone16e),.iPhone17,.iPhone16e]

public var isXModel: Bool {
    return Gobal_device_info.isFaceIDCapable
}

//MARK: 当前屏幕Bounds
///当前屏幕Bounds
@MainActor public let kSCREEN_BOUNDS = UIScreen.main.bounds
//MARK: 当前屏幕Size
///当前屏幕Size
@MainActor public let kSCREEN_SIZE = kSCREEN_BOUNDS.size
//MARK: 当前屏幕比例
///当前屏幕比例
@MainActor public let kSCREEN_SCALE = UIScreen.main.scale

// MARK: App版本&设备系统版本
@MainActor public let infoDictionary            = Bundle.main.infoDictionary
//MARK: App显示名称
///App显示名称
@MainActor public let kAppDisplayName: String?         = infoDictionary!["CFBundleDisplayName"] as? String
//MARK: App名称
///App名称
@MainActor public let kAppName: String?         = infoDictionary!["CFBundleName"] as? String
//MARK: App版本号
///App版本号
@MainActor public let kAppVersion: String?      = infoDictionary!["CFBundleShortVersionString"] as? String
//MARK: App Build版本号
///AppBuild版本号
@MainActor public let kAppBuildVersion: String? = infoDictionary!["CFBundleVersion"] as? String
//MARK: App Bundle Id
///App BundleId
@MainActor public let kAppBundleId: String?     = infoDictionary!["CFBundleIdentifier"] as? String
//MARK: 平台名称（iPhone Simulator 、 iPhone）
///平台名称（iPhone Simulator 、 iPhone）
@MainActor public let kPlatformName: String?    = infoDictionary!["DTPlatformName"] as? String
//MARK: iOS系统版本
///iOS系统版本
@MainActor public let kiOSVersion: String       = UIDevice.current.systemVersion
//MARK: 系统名称+版本，e.g. @"iOS 12.1"
///系统名称+版本，e.g. @"iOS 12.1"
@MainActor public let kOSType: String           = UIDevice.current.systemName + UIDevice.current.systemVersion
