//
//  Device+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import DeviceKit

extension UIDevice: PTProtocolCompatible { }

public enum UIDeviceApplePencilSupportType
{
    case First
    case Second
    case Both
    case BothNot
}

public extension PTProtocol where Base: UIDevice
{
    //MARK: 判断机型
    ///小
    static func oneOfSmallDevice()->Bool
    {
        return Gobal_device_info.isOneOf(Gobal_group_of_all_small_device)
    }
    
    ///大
    static func oneOfPlusDevice()->Bool
    {
        return Gobal_device_info.isOneOf(Gobal_group_of_all_plus_device)
    }

    ///X
    static func oneOfXDevice()->Bool
    {
        return Gobal_device_info.isOneOf(Gobal_group_of_all_X_device)
    }
    
    static func oneOfPadDevice()->Bool
    {
        return Gobal_device_info.isOneOf(Gobal_group_of_all_iPad)
    }

    static var currentDeviceName:String
    {
        get
        {
            return UIDevice.current.name
        }
    }
    
    // MARK: 设备的UUID
    /// UUID
    static func stringWithUUID() -> String? {
        let uuid = CFUUIDCreate(kCFAllocatorDefault)
        let cfString = CFUUIDCreateString(kCFAllocatorDefault, uuid)
        return cfString as String?
    }
    
    //MARK: 越狱检测
    ///越狱检测
    static var isJailBroken:Bool
    {
        let apps = ["/Applications/Cydia.app",
                  "/Applications/limera1n.app",
                  "/Applications/greenpois0n.app",
                  "/Applications/blackra1n.app",
                  "/Applications/blacksn0w.app",
                  "/Applications/redsn0w.app",
                  "/Applications/Absinthe.app",
                    "/private/var/lib/apt"]
        for app in apps
        {
            if FileManager.default.fileExists(atPath: app)
            {
                return true
            }
        }
        
        let bash = fopen("/bin/bash", "r")
        if bash != nil {
            fclose(bash)
            return true
        }
        let path = String(format: "/private/%@", UIDevice.pt.stringWithUUID() ?? "")
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            PTNSLog(error.localizedDescription)
        }
        return false
    }
    
    // MARK: 当前硬盘的空间
    /// 当前硬盘的空间
    static var hardDiskSpace: Int64 {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            if let space: NSNumber = attrs[FileAttributeKey.systemSize] as? NSNumber {
                if space.int64Value > 0 {
                    return space.int64Value
                }
            }
        }
        return -1
    }
    
    @available(iOS 11.0,*)
    static var volumes: String {
        return String.init(format: "%d", Device.volumes!)
    }
    
    // MARK: 当前硬盘可用空间
    /// 当前硬盘可用空间
    static var hardDiskSpaceFree: Int64 {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            if let space: NSNumber = attrs[FileAttributeKey.systemFreeSize] as? NSNumber {
                if space.int64Value > 0 {
                    return space.int64Value
                }
            }
        }
        return -1
    }
    
    // MARK: 当前硬盘已经使用的空间
    /// 当前硬盘已经使用的空间
    static var hardDiskSpaceUsed: Int64 {
        let total = self.hardDiskSpace
        let free = self.hardDiskSpaceFree
        guard total > 0 && free > 0 else { return -1 }
        let used = total - free
        guard used > 0 else { return -1 }
        
        return used
    }
    
    @available(iOS 11.0,*)
    static var volumeAvailableCapacityForImportantUsage: String {
        return String.init(format: "%d", Device.volumeAvailableCapacityForImportantUsage!)
    }
    
    @available(iOS 11.0,*)
    static var volumeAvailableCapacityForOpportunisticUsage: String {
        return String.init(format: "%d", Device.volumeAvailableCapacityForOpportunisticUsage!)
    }

    // MARK: 获取总内存大小
    /// 获取总内存大小GB
    static var memoryTotal: Double {
        return round(100 * Double(ProcessInfo.processInfo.physicalMemory) * pow(10, -9)) / 100
    }
    
    // MARK: 获取屏幕亮度
    /// 获取屏幕亮度比例
    static var brightness: CGFloat {
        return UIScreen.main.brightness
    }
    
    // MARK: 获取设备是否省电模式
    /// 获取设备是否省电模式
    static var lowPowerMode: Bool {
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    // MARK: 获取设备CPU数量
    /// 获取设备CPU数量
    static var processorCount: Int {
        return ProcessInfo.processInfo.processorCount
    }
    
    // MARK: 当前系统更新时间
    /// 当前系统更新时间
    static var systemUptime: String {
        let time = ProcessInfo.processInfo.systemUptime.formattedString!
        return time
    }
    
    // MARK: 是否支持ApplePencil
    /// 是否支持ApplePencil
    static var supportApplePencil: UIDeviceApplePencilSupportType {
        
        if Device.ApplePencilSupport.secondGeneration == Device.ApplePencilSupport.init(rawValue: Device.ApplePencilSupport.secondGeneration.rawValue) && Device.ApplePencilSupport.firstGeneration == Device.ApplePencilSupport.init(rawValue: Device.ApplePencilSupport.firstGeneration.rawValue)
        {
            return .Both
        }
        else if Device.ApplePencilSupport.secondGeneration == Device.ApplePencilSupport.init(rawValue: Device.ApplePencilSupport.secondGeneration.rawValue) && Device.ApplePencilSupport.firstGeneration != Device.ApplePencilSupport.init(rawValue: Device.ApplePencilSupport.firstGeneration.rawValue)
        {
            return .Second
        }
        else if Device.ApplePencilSupport.secondGeneration != Device.ApplePencilSupport.init(rawValue: Device.ApplePencilSupport.secondGeneration.rawValue) && Device.ApplePencilSupport.firstGeneration == Device.ApplePencilSupport.init(rawValue: Device.ApplePencilSupport.firstGeneration.rawValue)
        {
            return .First
        }
        else
        {
            return .BothNot
        }
    }
    
    // MARK: 获取最高刷新率
    /// 获取最高刷新率
    @available(iOS 10.3,*)
    static var maximumFramesPerSecond:Int
    {
        return UIScreen.main.maximumFramesPerSecond
    }
    
    //MARK: 获取手机的第一个语言
    static var currentDeviceLanguageInIos:String
    {
        return Bundle.main.preferredLocalizations.first!
    }
    
    //MARK: 获取手机的第一个语言字典
    static var currentDeviceLanguageInIosWithDic:[String:String]
    {
        var dic:[String:String] = [String:String]()
        let arr = NSLocale.preferredLanguages
        let language = arr.first!
        dic["LANGUAGEENGLISH"] = language
        dic["LANGUAGEANDCHINESE"] = NSLocale.canonicalLocaleIdentifier(from: language)
        dic["LANGUAGECHINESE"] = NSLocale(localeIdentifier: language).displayName(forKey: NSLocale.Key.identifier, value: language)

        return dic
    }
}
