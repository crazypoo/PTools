//
//  Device+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import DeviceKit
import CoreTelephony
import Foundation
import AudioToolbox

extension UIDevice: PTProtocolCompatible { }

public enum UIDeviceApplePencilSupportType {
    case First
    case Second
    case Both
    case BothNot
}

public extension UIDeviceApplePencilSupportType {
    var description: String {
        switch self {
        case .Both: return "Support All"
        case .First: return "Only First"
        case .Second: return "Only Second"
        case .BothNot: return "Not Supported"
        }
    }
}

public extension PTPOP where Base: UIDevice {
    
    //MARK: 判断是否Mac
    @MainActor var isMac: Bool {
        if UIDevice.current.userInterfaceIdiom == .mac {
            return true
        }
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }
    
    //MARK: 判断机型
    ///小
    static func oneOfSmallDevice() -> Bool {
        Gobal_device_info.isOneOf(Gobal_group_of_all_small_device)
    }
    
    ///大
    static func oneOfPlusDevice() -> Bool {
        Gobal_device_info.isOneOf(Gobal_group_of_all_plus_device)
    }

    ///X
    static func oneOfXDevice() -> Bool {
        Gobal_device_info.isOneOf(Gobal_group_of_all_X_device)
    }
    
    ///Pad
    static func oneOfPadDevice() -> Bool {
        Gobal_device_info.isOneOf(Gobal_group_of_all_iPad)
    }
    
    //Pro
    static func oneOfProDevice() -> Bool {
        Gobal_device_info.isOneOf(Gobal_group_of_all_pro_device)
    }

    //MARK: 獲取當前設備的名稱
    ///獲取當前設備的名稱
    @MainActor static var currentDeviceName : String {
        get {
            UIDevice.current.name
        }
    }
    
    //MARK: 设备的UUID
    /// UUID
    static func stringWithUUID() -> String? {
        let uuid = CFUUIDCreate(kCFAllocatorDefault)
        let cfString = CFUUIDCreateString(kCFAllocatorDefault, uuid)
        return cfString as String?
    }
    
    //MARK: 越狱检测
    ///越狱检测
    static var isJailBroken : Bool {
        let apps = ["/Applications/Cydia.app",
                  "/Applications/limera1n.app",
                  "/Applications/greenpois0n.app",
                  "/Applications/blackra1n.app",
                  "/Applications/blacksn0w.app",
                  "/Applications/redsn0w.app",
                  "/Applications/Absinthe.app",
                    "/private/var/lib/apt"]
        for app in apps {
            if FileManager.default.fileExists(atPath: app) {
                return true
            }
        }
        
        let bash = fopen("/bin/bash", "r")
        if bash != nil {
            fclose(bash)
            return true
        }
        
        let uuid = self.stringWithUUID() ?? ""
        let path = String(format: "/private/%@", uuid)
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            PTNSLogConsole(error.localizedDescription,levelType: .error,loggerType: .device)
        }
        return false
    }
    
    //MARK: 当前硬盘的空间
    ///当前硬盘的空间
    static var hardDiskSpace : Int64 {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            if let space: NSNumber = attrs[FileAttributeKey.systemSize] as? NSNumber {
                if space.int64Value > 0 {
                    return space.int64Value
                }
            }
        }
        return -1
    }
    
    static var volumes : String {
        String(format: "%d", Device.volumes!)
    }
    
    //MARK: 当前硬盘可用空间
    ///当前硬盘可用空间
    static var hardDiskSpaceFree : Int64 {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            if let space: NSNumber = attrs[FileAttributeKey.systemFreeSize] as? NSNumber {
                if space.int64Value > 0 {
                    return space.int64Value
                }
            }
        }
        return -1
    }
    
    //MARK: 当前硬盘已经使用的空间
    ///当前硬盘已经使用的空间
    static var hardDiskSpaceUsed : Int64 {
        let total = self.hardDiskSpace
        let free = self.hardDiskSpaceFree
        guard total > 0 && free > 0 else { return -1 }
        let used = total - free
        guard used > 0 else { return -1 }
        
        return used
    }
    
    //MARK: 獲取可用的儲存用量(字節為單位)
    ///獲取可用的儲存用量(字節為單位)
    static var volumeAvailableCapacityForImportantUsage : String {
        String(format: "%d", Device.volumeAvailableCapacityForImportantUsage!)
    }
    
    //MARK: 獲取不能用的儲存用量(字節為單位)
    ///獲取不能用的儲存用量(字節為單位)
    static var volumeAvailableCapacityForOpportunisticUsage : String {
        String(format: "%d", Device.volumeAvailableCapacityForOpportunisticUsage!)
    }

    //MARK: 获取总内存大小
    ///获取总内存大小GB
    @MainActor static var memoryTotal: Double {
        // 1. 获取物理内存的字节数
        let bytes = Double(ProcessInfo.processInfo.physicalMemory)
        
        // 2. 将字节转换为 GB (除以 10 的 9 次方，替代耗时的 pow 函数)
        let gigabytes = bytes / 1_000_000_000.0
        
        // 3. 四舍五入保留两位小数并返回
        return round(gigabytes * 100) / 100
    }
    
    @MainActor private static var activeScreen: UIScreen? {
        return (UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene)?.screen
    }
    //MARK: 获取屏幕亮度
    ///获取屏幕亮度比例
    @MainActor static var brightness: CGFloat {
        return activeScreen?.brightness ?? 0.5
    }
    
    //MARK: 获取设备是否省电模式
    ///获取设备是否省电模式
    static var lowPowerMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    //MARK: 获取设备CPU数量
    ///获取设备CPU数量
    static var processorCount: Int {
        ProcessInfo.processInfo.processorCount
    }
    
    //MARK: 当前系统更新时间
    ///当前系统更新时间
    static var systemUptime: String {
        let time = ProcessInfo.processInfo.systemUptime.formattedString!
        return time
    }
    
    //MARK: 是否支持ApplePencil
    ///是否支持ApplePencil
    static var supportApplePencil: UIDeviceApplePencilSupportType {
        
        if Device.ApplePencilSupport.secondGeneration == Device.ApplePencilSupport(rawValue: Device.ApplePencilSupport.secondGeneration.rawValue) && Device.ApplePencilSupport.firstGeneration == Device.ApplePencilSupport(rawValue: Device.ApplePencilSupport.firstGeneration.rawValue) {
            return .Both
        } else if Device.ApplePencilSupport.secondGeneration == Device.ApplePencilSupport(rawValue: Device.ApplePencilSupport.secondGeneration.rawValue) && Device.ApplePencilSupport.firstGeneration != Device.ApplePencilSupport(rawValue: Device.ApplePencilSupport.firstGeneration.rawValue) {
            return .Second
        } else if Device.ApplePencilSupport.secondGeneration != Device.ApplePencilSupport(rawValue: Device.ApplePencilSupport.secondGeneration.rawValue) && Device.ApplePencilSupport.firstGeneration == Device.ApplePencilSupport(rawValue: Device.ApplePencilSupport.firstGeneration.rawValue) {
            return .First
        } else {
            return .BothNot
        }
    }
    
    //MARK: 获取最高刷新率
    ///获取最高刷新率
    @MainActor static var maximumFramesPerSecond: Int {
        return activeScreen?.maximumFramesPerSecond ?? 60
    }
    
    //MARK: 获取手机的第一个语言
    ///获取手机的第一个语言
    static var currentDeviceLanguageInIos: String {
        Bundle.main.preferredLocalizations.first!
    }
    
    //MARK: 获取手机的第一个语言字典
    ///获取手机的第一个语言字典
    static var currentDeviceLanguageInIosWithDic: [String:String] {
        var dic:[String:String] = [String:String]()
        let arr = NSLocale.preferredLanguages
        let language = arr.first!
        dic["LANGUAGEENGLISH"] = language
        dic["LANGUAGEANDCHINESE"] = NSLocale.canonicalLocaleIdentifier(from: language)
        dic["LANGUAGECHINESE"] = NSLocale(localeIdentifier: language).displayName(forKey: NSLocale.Key.identifier, value: language)

        return dic
    }
    
    //MARK: 當前設備能否打電話
    ///當前設備能否打電話
    /// - Returns: 結果
    @MainActor static func isCanCallTel() -> Bool {
        if let url = URL(string: "tel://") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
}

public extension PTPOP where Base: UIDevice {
    //MARK: 檢測當前系統是否小於某個版本系統
    ///檢測當前系統是否小於某個版本系統
    /// - Returns: Bool
    @MainActor static func lessThanSysVersion(version:NSString,
                                   equal:Bool) -> Bool {
        UIDevice.current.systemVersion.compare("\(version)", options: .numeric) != (equal ? .orderedDescending : .orderedAscending)
    }
}

public extension PTPOP where Base: UIDevice {
    
    //MARK: 根据数据业务信息获取对应的网络类型
    /// - Parameters:
    ///  -  currentRadioTech: 当前的无线电接入技术信息
    /// - Returns: 网络类型
    private static func getNetworkType(currentRadioTech: String) -> String {
        /**
         手机的数据业务对应的通信技术
         CTRadioAccessTechnologyGPRS：2G（有时又叫2.5G，介于2G和3G之间的过度技术）
         CTRadioAccessTechnologyEdge：2G （有时又叫2.75G，是GPRS到第三代移动通信的过渡)
         CTRadioAccessTechnologyWCDMA：3G
         CTRadioAccessTechnologyHSDPA：3G (有时又叫 3.5G)
         CTRadioAccessTechnologyHSUPA：3G (有时又叫 3.75G)
         CTRadioAccessTechnologyCDMA1x ：2G
         CTRadioAccessTechnologyCDMAEVDORev0：3G
         CTRadioAccessTechnologyCDMAEVDORevA：3G
         CTRadioAccessTechnologyCDMAEVDORevB：3G
         CTRadioAccessTechnologyeHRPD：3G (有时又叫 3.75G，是电信使用的一种3G到4G的演进技术)
         CTRadioAccessTechnologyLTE：4G (或者说接近4G)
         // 5G：NR是New Radio的缩写，新无线(5G)的意思，NRNSA表示5G NR的非独立组网（NSA）模式。
         CTRadioAccessTechnologyNRNSA：5G NSA
         CTRadioAccessTechnologyNR：5G
         */
        if currentRadioTech == CTRadioAccessTechnologyNRNSA || currentRadioTech == CTRadioAccessTechnologyNR {
            return "5G"
        }
    
        var networkType = ""
        switch currentRadioTech {
        case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
            networkType = "2G"
        case CTRadioAccessTechnologyeHRPD, CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB, CTRadioAccessTechnologyHSUPA:
            networkType = "3G"
        case CTRadioAccessTechnologyLTE:
            networkType = "4G"
        default:
            break
        }
        return networkType
    }
        
    //MARK: 数据业务对应的通信技术
    ///数据业务对应的通信技术
    /// - Returns: 通信技术
    static func currentRadioAccessTechnologys() -> [String]? {
        guard !Device.current.isSimulator else {
            return nil
        }
        // 获取并输出运营商信息
        let info = CTTelephonyNetworkInfo()
        guard let currentRadioTechs = info.serviceCurrentRadioAccessTechnology else {
            return nil
        }
        return currentRadioTechs.values.shuffled()
    }

    //MARK: 设备网络制式
    ///设备网络制式
    /// - Returns: 网络
    static func networkTypes() -> [String]? {
        // 获取并输出运营商信息
        guard let currentRadioTechs = currentRadioAccessTechnologys() else {
            return nil
        }
        return currentRadioTechs.compactMap { getNetworkType(currentRadioTech: $0) }
    }
        
    //MARK: 检测时候热启动
    static func activePrewarm() -> Bool {
        let boolValue = ProcessInfo.processInfo.environment["ActivePrewarm"] == "1" ? true : false
        return boolValue
    }
}

//MARK: 设备的震动
public enum SystemSoundIDShockType: Int64 {
    ///短振动，普通短震，3D Touch 中 Peek 震动反馈
    case short3DTouchPeekVibration = 1519
    ///普通短震，3D Touch 中 Pop 震动反馈,home 键的振动
    case short3DPopHomeVibration = 1520
    ///连续三次短震
    case thereshortVibration = 1521
}

public extension PTPOP where Base: UIDevice {
    //MARK: 使用 SystemSoundID 产生的震动
    ///使用 SystemSoundID 产生的震动
    /// - Parameter type: 震动的类型
    static func systemSoundIDShock(type: SystemSoundIDShockType) {
        let soundShort = SystemSoundID(type.rawValue)
        AudioServicesPlaySystemSound(soundShort)
    }
    
    //MARK: UINotificationFeedbackGenerator 来设置的手机振动
    ///UINotificationFeedbackGenerator 来设置的手机振动
    @MainActor static func notificationFeedbackGeneratorSuccess(_ notificationType: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(notificationType)
    }
    
    //MARK: UIImpactFeedbackGenerator 来设置的手机振动
    ///UIImpactFeedbackGenerator 来设置的手机振动
    @MainActor static func impactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    //MARK: 模拟选择滚轮一类控件时的震动
    ///模拟选择滚轮一类控件时的震动
    ///UISelectionFeedbackGenerator中只有一个类型，是用来模拟选择滚轮一类控件时的震动，比如计时器中的picker滚动时就有这个效果。
    @MainActor static func selectionFeedbackGeneratorChanged() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
