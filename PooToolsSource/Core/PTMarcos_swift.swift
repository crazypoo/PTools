//
//  PTMarcos_swift.swift
//  Diou
//
//  Created by ken lam on 2021/10/19.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
#if SWIFT_PACKAGE
import PToolsDevice
#endif

public let CorePodBundleName = "PooToolsResource"

// 2. 新增：专门用于后台/全局线程的 Task（不带 @MainActor，避免线程冲突警告）
public typealias PTBackgroundTask = @Sendable () -> Void

public typealias PTBoolTask = (@Sendable (Bool) -> Void)

@MainActor public var AppWindows: UIWindow? {
    // English: Use the raw scene resolver so the legacy global cannot participate in a window lookup cycle.
    // Español: Usa el resolvedor de escenas directo para que el global heredado no participe en un ciclo de búsqueda de ventanas.
    // 中文：使用底层场景解析器，避免旧的全局入口参与窗口查询循环。
    PTSceneContext._resolveActiveWindow()
}

// English: Expose canonical device names; the misspelled globals below remain source-compatible aliases.
// Español: Expone nombres canónicos de dispositivos; los globales con errores de escritura siguen como alias compatibles.
// 中文：提供规范的设备名称；下面的历史拼写全局变量继续作为兼容别名保留。
public let deviceInfo = PTDevice.current
public let deviceIsSimulator = deviceInfo.isSimulator
public let allIPadDevices: [PTDeviceModel] = PTDeviceCatalog.models(family: .iPad)
public let allPlusDevices: [PTDeviceModel] = [
    PTDeviceModel("iphone-6-plus"), PTDeviceModel("iphone-6s-plus"),
    PTDeviceModel("iphone-7-plus"), PTDeviceModel("iphone-8-plus"),
    PTDeviceModel("iphone-xr"), PTDeviceModel("iphone-xs-max"),
    PTDeviceModel("iphone-11"), PTDeviceModel("iphone-11-pro-max"),
    PTDeviceModel("iphone-12-pro-max"), PTDeviceModel("iphone-13-pro-max"),
    PTDeviceModel("iphone-14-plus"), PTDeviceModel("iphone-14-pro-max"),
    PTDeviceModel("iphone-15-plus"), PTDeviceModel("iphone-15-pro-max"),
    PTDeviceModel("iphone-16-plus"), PTDeviceModel("iphone-16-pro-max"),
    PTDeviceModel("iphone-17-pro-max")
]
public let allProDevices: [PTDeviceModel] = [
    PTDeviceModel("iphone-11-pro"), PTDeviceModel("iphone-11-pro-max"),
    PTDeviceModel("iphone-12-pro"), PTDeviceModel("iphone-12-pro-max"),
    PTDeviceModel("iphone-13-pro"), PTDeviceModel("iphone-13-pro-max"),
    PTDeviceModel("iphone-14-pro"), PTDeviceModel("iphone-14-pro-max"),
    PTDeviceModel("iphone-15-pro"), PTDeviceModel("iphone-15-pro-max"),
    PTDeviceModel("iphone-16-pro"), PTDeviceModel("iphone-16-pro-max"),
    PTDeviceModel("iphone-17-pro"), PTDeviceModel("iphone-17-pro-max")
]
public let allSensorHousingDevices: [PTDeviceModel] = PTDeviceCatalog.allSpecifications
    .filter { $0.traits.hasSensorHousing }
    .map(\.model)
public let allSmallDevices: [PTDeviceModel] = [
    "iphone-5", "iphone-5c", "iphone-5s", "ipod-touch-5", "ipod-touch-6", "ipod-touch-7",
    "iphone-6", "iphone-6s", "iphone-7", "iphone-8", "iphone-se-2", "iphone-se-3",
    "iphone-12-mini", "iphone-13-mini", "iphone-14", "iphone-15", "iphone-16", "iphone-17", "iphone-16e"
].map { PTDeviceModel($0) }

// English: Deprecated aliases preserve the 5.x migration window without duplicating storage.
// Español: Los alias obsoletos conservan la ventana de migración 5.x sin duplicar el almacenamiento.
// 中文：弃用别名保留 5.x 迁移窗口，同时不重复存储。
@available(*, deprecated, renamed: "deviceInfo")
public let Gobal_device_info = deviceInfo
@available(*, deprecated, renamed: "deviceIsSimulator")
public let Gobal_device_isSimulator = deviceIsSimulator
@available(*, deprecated, renamed: "allIPadDevices")
public let Gobal_group_of_all_iPad = allIPadDevices
@available(*, deprecated, renamed: "allPlusDevices")
public let Gobal_group_of_all_plus_device = allPlusDevices
@available(*, deprecated, renamed: "allProDevices")
public let Gobal_group_of_all_pro_device = allProDevices
@available(*, deprecated, renamed: "allSensorHousingDevices")
public let Gobal_group_of_all_X_device = allSensorHousingDevices
@available(*, deprecated, renamed: "allSmallDevices")
public let Gobal_group_of_all_small_device = allSmallDevices

public var isXModel: Bool {
    return deviceInfo.isFaceIDCapable
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
@MainActor public let kAppDisplayName: String?         = infoDictionary?["CFBundleDisplayName"] as? String
//MARK: App名称
///App名称
@MainActor public let kAppName: String?         = infoDictionary?["CFBundleName"] as? String
//MARK: App版本号
///App版本号
@MainActor public let kAppVersion: String?      = infoDictionary?["CFBundleShortVersionString"] as? String
//MARK: App Build版本号
///AppBuild版本号
@MainActor public let kAppBuildVersion: String? = infoDictionary?["CFBundleVersion"] as? String
//MARK: App Bundle Id
///App BundleId
@MainActor public let kAppBundleId: String?     = infoDictionary?["CFBundleIdentifier"] as? String
//MARK: 平台名称（iPhone Simulator 、 iPhone）
///平台名称（iPhone Simulator 、 iPhone）
@MainActor public let kPlatformName: String?    = infoDictionary?["DTPlatformName"] as? String
//MARK: iOS系统版本
///iOS系统版本
@MainActor public let kiOSVersion: String       = UIDevice.current.systemVersion
//MARK: 系统名称+版本，e.g. @"iOS 12.1"
///系统名称+版本，e.g. @"iOS 12.1"
@MainActor public let kOSType: String           = UIDevice.current.systemName + UIDevice.current.systemVersion
