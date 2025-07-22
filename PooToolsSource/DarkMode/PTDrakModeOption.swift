//
//  PTDrakModeOption.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

// MARK: - 方法的调用
extension PTDarkModeOption: PTThemeable {
    public func apply() {}
}

@objcMembers
public class PTDarkModeOption {
    /// 智能换肤的时间区间的key
    private static let PTSmartPeelingTimeIntervalKey = "PTSmartPeelingTimeIntervalKey"
    /// 跟随系统的key
    private static let PTDarkToSystemKey = "PTDarkToSystemKey"
    /// 是否浅色模式的key
    private static let PTLightDarkKey = "PTLightDarkKey"
    /// 智能换肤的key
    private static let PTSmartPeelingKey = "PTSmartPeelingKey"
    
    /// 是否浅色
    public static var isLight: Bool {
        if isSmartPeeling {
            return isSmartPeelingTime() ? false : true
        }
        
        if let value = UserDefaults.pt.userDefaultsGetValue(key: PTLightDarkKey) as? Bool {
            return value
        }
        return true
    }
    
    ///默认不是智能
    public static var isSmartPeeling: Bool {
        if let value = UserDefaults.pt.userDefaultsGetValue(key: PTSmartPeelingKey) as? Bool {
            return value
        }
        return false
    }
    
    /// 智能模式的时间段：默认是：21:00~8:00
    public static var smartPeelingTimeIntervalValue: String {
        get {
            if let value = UserDefaults.pt.userDefaultsGetValue(key: PTSmartPeelingTimeIntervalKey) as? String {
                return value
            }
            return "22:00~9:00"
        }
        set {
            UserDefaults.pt.userDefaultsSetValue(value: newValue, key: PTSmartPeelingTimeIntervalKey)
        }
    }
    
    /// 是否跟随系统
    public static var isFollowSystem: Bool {
        if let value = UserDefaults.pt.userDefaultsGetValue(key: PTDarkToSystemKey) as? Bool {
            return value
        }
        return true
    }
    
    public static var smartDescAccessory:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
    public static var backImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20))
    public static var switchTintColor:DynamicColor = .white
    public static var switchThumbTintColor:DynamicColor = .white
    public static var switchOnTinColor:DynamicColor = .lightGray
    
    ///选中
    public static var tradeValidperiodSelected = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_cycle_selected@3x")
    /// 没有选中
    public static var tradeValidperiod = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_cycle_unselected@3x")

    public static var smartCellName = "PT Theme smart".localized()
    public static var followSystemCellName = "PT Theme follow system".localized()
    public static var timeSetErrorMsg = "PT Theme time set error".localized()
    public static var titleSting = "PT Theme title".localized()
    public static var cellFont:UIFont = .appfont(size: 16)
    public static var footerDesc:String = "PT Theme system info".localized()
    public static var mtTitle:String = "PT Theme mt".localized()
    public static var mtTitleFont:UIFont = .appfont(size: 16)
    public static var whiteThemeString:String = "PT Theme white".localized()
    public static var blackThemeString:String = "PT Theme black".localized()
    public static var themeSelectFont:UIFont = .appfont(size: 13)
    public static var pickerCancel:String = "PT Button cancel".localized()
    public static var pickerDone:String = "PT Button comfirm".localized()
    public static var pickerFont:UIFont = .appfont(size: 16)
    public static var pickerLabelFont:UIFont = .appfont(size: 18)
    public static var themeSmartInfo:String = "PT Theme smart info".localized()
    public static var themeSubNightTitle:String = "PT Theme night".localized()
    public static var themeSubTimeTitle:String = "PT Theme time".localized()
    public static var themeSubFont:UIFont = .appfont(size: 16)
    public static var themeSubDescFont:UIFont = .appfont(size: 16)
    public static var themeSubTimeArrow:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
}

public extension PTDarkModeOption {
    
    // MARK: 初始化的调用
    /// 默认设置
    static func defaultDark() {
        // 默认跟随系统暗黑模式开启监听
        if (PTDarkModeOption.isFollowSystem) {
            PTDarkModeOption.setDarkModeFollowSystem(isFollowSystem: true)
        } else {
            AppWindows?.overrideUserInterfaceStyle = PTDarkModeOption.isLight ? .light : .dark
        }
    }
    
    // MARK: 设置系统是否跟随
    static func setDarkModeFollowSystem(isFollowSystem: Bool) {
        // 1.1、设置是否跟随系统
        UserDefaults.pt.userDefaultsSetValue(value: isFollowSystem, key: PTDarkToSystemKey)
        let result = UITraitCollection.current.userInterfaceStyle == .light ? true : false
        UserDefaults.pt.userDefaultsSetValue(value: result, key: PTLightDarkKey)
        UserDefaults.pt.userDefaultsSetValue(value: false, key: PTSmartPeelingKey)
        // 1.2、设置模式的保存
        if isFollowSystem {
            AppWindows?.overrideUserInterfaceStyle = .unspecified
        } else {
            AppWindows?.overrideUserInterfaceStyle = UITraitCollection.current.userInterfaceStyle
        }
    }
    
    // MARK: 设置：浅色 / 深色
    static func setDarkModeCustom(isLight: Bool) {
        // 1.1、只要设置了模式：就是黑或者白
        UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.overrideUserInterfaceStyle = isLight ? .light : .dark
        // 1.2、设置跟随系统和智能换肤：否
        UserDefaults.pt.userDefaultsSetValue(value: false, key: PTDarkToSystemKey)
        UserDefaults.pt.userDefaultsSetValue(value: false, key: PTSmartPeelingKey)
        // 1.3、黑白模式的设置
        UserDefaults.pt.userDefaultsSetValue(value: isLight, key: PTLightDarkKey)
    }
    
    // MARK: 设置：智能换肤
    /// 智能换肤
    /// - Parameter isSmartPeeling: 是否智能换肤
    static func setSmartPeelingDarkMode(isSmartPeeling: Bool) {
        // 1.1、设置智能换肤
        UserDefaults.pt.userDefaultsSetValue(value: isSmartPeeling, key: PTSmartPeelingKey)
        // 1.2、智能换肤根据时间段来设置：黑或者白
        AppWindows?.overrideUserInterfaceStyle = isLight ? .light : .dark
        // 1.3、设置跟随系统：否
        UserDefaults.pt.userDefaultsSetValue(value: false, key: PTDarkToSystemKey)
        UserDefaults.pt.userDefaultsSetValue(value: isLight, key: PTLightDarkKey)
    }
    
    // MARK: 智能换肤时间选择后
    /// 智能换肤时间选择后
    static func setSmartPeelingTimeChange(startTime: String,
                                          endTime: String) {
        /// 是否是浅色
        var light: Bool = false
        if PTDarkModeOption.isSmartPeelingTime(startTime: startTime, endTime: endTime), PTDarkModeOption.isLight {
            light = false
        } else {
            if !PTDarkModeOption.isLight {
                light = true
            } else {
                PTDarkModeOption.smartPeelingTimeIntervalValue = startTime + "~" + endTime
                return
            }
        }
        PTDarkModeOption.smartPeelingTimeIntervalValue = startTime + "~" + endTime
        
        // 1.1、只要设置了模式：就是黑或者白
        AppWindows?.overrideUserInterfaceStyle = light ? .light : .dark
        // 1.2、黑白模式的设置
        UserDefaults.pt.userDefaultsSetValue(value: light, key: PTLightDarkKey)
    }
}

// MARK: - 动态颜色的使用
public extension PTDarkModeOption {
    static func colorLightDark(lightColor: UIColor,
                               darkColor: UIColor) -> UIColor {
        UIColor { (traitCollection) -> UIColor in
            if PTDarkModeOption.isFollowSystem {
                if traitCollection.userInterfaceStyle == .light {
                    return lightColor
                } else {
                    return darkColor
                }
            } else if PTDarkModeOption.isSmartPeeling {
                return isSmartPeelingTime() ? darkColor : lightColor
            } else {
                return PTDarkModeOption.isLight ? lightColor : darkColor
            }
        }
    }
    
    // MARK: 是否为智能换肤的时间：黑色
    /// 是否为智能换肤的时间：黑色
    /// - Returns: 结果
    static func isSmartPeelingTime(startTime: String? = nil,
                                   endTime: String? = nil) -> Bool {
        // 获取暗黑模式时间的区间，转为两个时间戳，取出当前的时间戳，看是否在区间内，在的话：黑色，否则白色
        var timeIntervalValue: [String] = []
        if startTime != nil && endTime != nil {
            timeIntervalValue = [startTime!, endTime!]
        } else {
            timeIntervalValue = PTDarkModeOption.smartPeelingTimeIntervalValue.components(separatedBy: "~")
        }
        // 1、时间区间分隔为：开始时间 和 结束时间
        // 2、当前的时间转时间戳
        let currentDate = Date()
        let currentTimeStamp = Int(currentDate.pt.dateToTimeStamp())!
        let dateString = currentDate.pt.toformatterTimeString(formatter: "yyyy-MM-dd")
        let startTimeStamp = Int(Date.pt.formatterTimeStringToTimestamp(timesString: dateString + " " + timeIntervalValue[0], formatter: "yyyy-MM-dd HH:mm", timestampType: .second))!
        var endTimeStamp = Int(Date.pt.formatterTimeStringToTimestamp(timesString: dateString + " " + timeIntervalValue[1], formatter: "yyyy-MM-dd HH:mm", timestampType: .second))!
        if startTimeStamp > endTimeStamp {
            endTimeStamp = endTimeStamp + 884600
        }
        return currentTimeStamp >= startTimeStamp && currentTimeStamp <= endTimeStamp
    }
}

// MARK: - 动态图片的使用
public extension PTDarkModeOption {

    // MARK: 深色图片和浅色图片切换 （深色模式适配）
    /// 深色图片和浅色图片切换 （深色模式适配）
    /// - Parameters:
    ///   - light: 浅色图片
    ///   - dark: 深色图片
    /// - Returns: 最终图片
    static func image(light: UIImage?,
                      dark: UIImage?) -> UIImage? {
        guard let weakLight = light, let weakDark = dark, let config = weakLight.configuration else { return light }
        let lightImage = weakLight.withConfiguration(config.withTraitCollection(UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.light)))
        lightImage.imageAsset?.register(weakDark, with: config.withTraitCollection(UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.dark)))
        return lightImage.imageAsset?.image(with: UITraitCollection.current) ?? light
    }
}
