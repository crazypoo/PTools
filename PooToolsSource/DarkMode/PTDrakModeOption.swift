//
//  PTDrakModeOption.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import Foundation
import UIKit

/// 智能换肤使用的时间区间。
/// 时间区间使用半开区间 `[开始, 结束)`，这样边界时刻只会属于一个状态。
private struct PTDarkTimeRange: Equatable {
    let startMinute: Int
    let endMinute: Int

    static let defaultRange = PTDarkTimeRange(startMinute: 22 * 60, endMinute: 9 * 60)

    private init(startMinute: Int, endMinute: Int) {
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    init?(startTime: String, endTime: String) {
        guard let startMinute = Self.minute(from: startTime),
              let endMinute = Self.minute(from: endTime),
              startMinute != endMinute else {
            return nil
        }
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    init?(serializedValue: String) {
        let values = serializedValue.split(separator: "~", omittingEmptySubsequences: false)
        guard values.count == 2 else { return nil }
        self.init(startTime: String(values[0]), endTime: String(values[1]))
    }

    var serializedValue: String {
        "\(Self.displayTime(for: startMinute))~\(Self.displayTime(for: endMinute))"
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let currentMinute = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        if startMinute < endMinute {
            return currentMinute >= startMinute && currentMinute < endMinute
        }
        return currentMinute >= startMinute || currentMinute < endMinute
    }

    func nextBoundary(after date: Date, calendar: Calendar = .current) -> Date? {
        let start = calendar.nextDate(
            after: date,
            matching: DateComponents(hour: startMinute / 60, minute: startMinute % 60),
            matchingPolicy: .nextTime,
            direction: .forward
        )
        let end = calendar.nextDate(
            after: date,
            matching: DateComponents(hour: endMinute / 60, minute: endMinute % 60),
            matchingPolicy: .nextTime,
            direction: .forward
        )

        switch (start, end) {
        case let (start?, end?):
            return min(start, end)
        case (let start?, nil):
            return start
        case (nil, let end?):
            return end
        default:
            return nil
        }
    }

    private static func minute(from value: String) -> Int? {
        let components = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ":", omittingEmptySubsequences: false)
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              minute >= 0,
              minute <= 59 else {
            return nil
        }

        // 24:00 是旧版本可能保存的结束边界，统一归一化为当天的 00:00。
        if hour == 24, minute == 0 { return 0 }
        guard hour >= 0, hour <= 23 else { return nil }
        return hour * 60 + minute
    }

    private static func displayTime(for minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }
}

/// 智能换肤的定时器和系统环境监听器。
/// 只在下一个时间边界触发，不按分钟轮询。
@MainActor
private final class PTDarkModeScheduleMonitor: NSObject {
    static let shared = PTDarkModeScheduleMonitor()

    private var boundaryTimer: Timer?
    private var didInstallObservers = false

    func modeDidChange() {
        installObserversIfNeeded()
        boundaryTimer?.invalidate()
        boundaryTimer = nil

        guard PTDarkModeOption.isSmartPeeling else { return }
        guard let boundary = PTDarkModeOption.nextScheduleBoundary(after: Date()) else { return }

        let interval = max(0.1, boundary.timeIntervalSinceNow)
        let timer = Timer(timeInterval: interval,
                          target: self,
                          selector: #selector(boundaryTimerFired),
                          userInfo: nil,
                          repeats: false)
        boundaryTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    @objc private func boundaryTimerFired() {
        boundaryTimer?.invalidate()
        boundaryTimer = nil
        PTDarkModeOption.refreshCurrentMode(notify: false)
        modeDidChange()
    }

    @objc private func environmentDidChange() {
        PTDarkModeOption.refreshCurrentMode(notify: false)
        modeDidChange()
    }

    private func installObserversIfNeeded() {
        guard !didInstallObservers else { return }
        didInstallObservers = true

        let notifications: [Notification.Name] = [
            UIScene.didActivateNotification,
            UIApplication.didBecomeActiveNotification,
            UIWindow.didBecomeKeyNotification,
            UIApplication.significantTimeChangeNotification,
            Notification.Name.NSCalendarDayChanged,
            Notification.Name("NSSystemClockDidChangeNotification"),
            Notification.Name("NSSystemTimeZoneDidChangeNotification")
        ]
        for name in notifications {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(environmentDidChange),
                name: name,
                object: nil
            )
        }
    }

    // 监视器是进程级单例，随应用生命周期存在，不在非隔离 deinit 中访问 Timer。
}

// MARK: - 方法的调用
extension PTDarkModeOption: @MainActor PTThemeable {
    public func apply() {
        Self.refreshCurrentMode(notify: true)
    }
}

@MainActor
@objcMembers
public class PTDarkModeOption {
    /// 智能换肤的时间区间的 key。
    private static let PTSmartPeelingTimeIntervalKey = "PTSmartPeelingTimeIntervalKey"
    /// 跟随系统的 key。
    private static let PTDarkToSystemKey = "PTDarkToSystemKey"
    /// 是否浅色模式的 key。
    private static let PTLightDarkKey = "PTLightDarkKey"
    /// 智能换肤的 key。
    private static let PTSmartPeelingKey = "PTSmartPeelingKey"
    private static var lastEffectiveLightValue: Bool?
    private static var cachedTimeRangeValue: String?
    private static var cachedTimeRange: PTDarkTimeRange?

    /// 是否浅色。
    public static var isLight: Bool {
        switch currentMode {
        case .system:
            return systemIsLight
        case .manual(let value):
            return value
        case .smart:
            return !isSmartPeelingTime()
        }
    }

    /// 默认不是智能模式。
    public static var isSmartPeeling: Bool {
        storedBool(forKey: PTSmartPeelingKey, defaultValue: false)
    }

    /// 智能模式的时间段，默认是 22:00~09:00。
    public static var smartPeelingTimeIntervalValue: String {
        get {
            storedTimeRange.serializedValue
        }
        set {
            guard let range = PTDarkTimeRange(serializedValue: newValue) else { return }
            storeTimeRange(range)
            if isSmartPeeling {
                refreshCurrentMode(notify: true)
                PTDarkModeScheduleMonitor.shared.modeDidChange()
            }
        }
    }

    /// 是否跟随系统。
    public static var isFollowSystem: Bool {
        storedBool(forKey: PTDarkToSystemKey, defaultValue: true)
    }

    public static var smartDescAccessory: UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
    public static var backImage: UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20))
    public static var switchTintColor: DynamicColor = .white
    public static var switchThumbTintColor: DynamicColor = .white
    public static var switchOnTinColor: DynamicColor = .lightGray
    public static var timeRangePickerCornerRadius: CGFloat = 0

    /// 选中。
    public static var tradeValidperiodSelected = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_cycle_selected@3x")
    /// 没有选中。
    public static var tradeValidperiod = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_cycle_unselected@3x")

    public static var smartCellName = "PT Theme smart".localized()
    public static var followSystemCellName = "PT Theme follow system".localized()
    public static var timeSetErrorMsg = "PT Theme time set error".localized()
    public static var titleSting = "PT Theme title".localized()
    public static var cellFont: UIFont = .appfont(size: 16)
    public static var footerDesc: String = "PT Theme system info".localized()
    public static var mtTitle: String = "PT Theme mt".localized()
    public static var mtTitleFont: UIFont = .appfont(size: 16)
    public static var whiteThemeString: String = "PT Theme white".localized()
    public static var blackThemeString: String = "PT Theme black".localized()
    public static var themeSelectFont: UIFont = .appfont(size: 13)
    public static var pickerCancel: String = "PT Button cancel".localized()
    public static var pickerDone: String = "PT Button comfirm".localized()
    public static var pickerFont: UIFont = .appfont(size: 16)
    public static var pickerLabelFont: UIFont = .appfont(size: 18)
    public static var themeSmartInfo: String = "PT Theme smart info".localized()
    public static var themeSubNightTitle: String = "PT Theme night".localized()
    public static var themeSubTimeTitle: String = "PT Theme time".localized()
    public static var themeSubFont: UIFont = .appfont(size: 16)
    public static var themeSubDescFont: UIFont = .appfont(size: 16)
    public static var themeSubTimeArrow: UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))

    private enum Mode {
        case system
        case manual(Bool)
        case smart
    }

    private static var currentMode: Mode {
        if isFollowSystem {
            // 旧版本异常数据可能同时打开两个开关，跟随系统优先并清理智能标记。
            if isSmartPeeling {
                UserDefaults.standard.set(false, forKey: PTSmartPeelingKey)
            }
            return .system
        }
        if isSmartPeeling { return .smart }
        return .manual(storedBool(forKey: PTLightDarkKey, defaultValue: true))
    }

    private static var systemIsLight: Bool {
        // English: Prefer the active window trait so multi-scene apps use the visible interface style.
        // Español: Prefiere el trait de la ventana activa para que las aplicaciones multi-escena usen el estilo visible.
        // 中文：优先读取活动窗口的 trait，确保多场景应用使用当前可见界面样式。
        let activeWindowStyle = PTSceneContext.activeWindow()?.traitCollection.userInterfaceStyle
        let style = activeWindowStyle.flatMap { $0 == .unspecified ? nil : $0 }
            ?? UITraitCollection.current.userInterfaceStyle
        return style != .dark
    }

    private static func storedBool(forKey key: String, defaultValue: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? defaultValue
    }

    private static func storeTimeRange(_ range: PTDarkTimeRange) {
        UserDefaults.standard.set(range.serializedValue, forKey: PTSmartPeelingTimeIntervalKey)
        cachedTimeRangeValue = range.serializedValue
        cachedTimeRange = range
    }

    private static var storedTimeRange: PTDarkTimeRange {
        let rawValue = UserDefaults.standard.string(forKey: PTSmartPeelingTimeIntervalKey)
        if let rawValue,
           rawValue == cachedTimeRangeValue,
           let cachedTimeRange {
            return cachedTimeRange
        }

        let range = rawValue.flatMap(PTDarkTimeRange.init(serializedValue:)) ?? PTDarkTimeRange.defaultRange
        let normalized = range.serializedValue
        if rawValue != normalized {
            UserDefaults.standard.set(normalized, forKey: PTSmartPeelingTimeIntervalKey)
        }
        cachedTimeRangeValue = normalized
        cachedTimeRange = range
        return range
    }

    private static func storeMode(followSystem: Bool, smart: Bool, light: Bool) {
        UserDefaults.standard.set(followSystem, forKey: PTDarkToSystemKey)
        UserDefaults.standard.set(smart, forKey: PTSmartPeelingKey)
        UserDefaults.standard.set(light, forKey: PTLightDarkKey)
    }

    private static func applyMode(followSystem: Bool, smart: Bool, light: Bool) {
        storeMode(followSystem: followSystem, smart: smart, light: light)
        refreshCurrentMode(notify: true)
        PTDarkModeScheduleMonitor.shared.modeDidChange()
    }

    private static func windows() -> [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
    }

    private static func interfaceStyle(for mode: Mode, isLight: Bool) -> UIUserInterfaceStyle {
        switch mode {
        case .system:
            return .unspecified
        case .manual:
            return isLight ? .light : .dark
        case .smart:
            return isLight ? .light : .dark
        }
    }

    private static func updateStatusBar() {
        StatusBarManager.shared.style = isLight ? .darkContent : .lightContent
        for window in windows() {
            window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        }
    }

    fileprivate static func refreshCurrentMode(notify: Bool) {
        let mode = currentMode
        let light = isLight
        let shouldNotify = notify || lastEffectiveLightValue != light

        for window in windows() {
            window.overrideUserInterfaceStyle = interfaceStyle(for: mode, isLight: light)
        }
        lastEffectiveLightValue = light
        updateStatusBar()

        if shouldNotify {
            LegacyThemeProvider.shared.updateTheme()
        }
    }

    fileprivate static func nextScheduleBoundary(after date: Date) -> Date? {
        storedTimeRange.nextBoundary(after: date)
    }
}

public extension PTDarkModeOption {
    // MARK: 初始化的调用
    /// 默认设置。应用启动时可能还没有窗口，因此由场景激活监听再次应用。
    @MainActor static func defaultDark() {
        refreshCurrentMode(notify: true)
        PTDarkModeScheduleMonitor.shared.modeDidChange()
    }

    // MARK: 设置系统是否跟随
    @MainActor static func setDarkModeFollowSystem(isFollowSystem: Bool) {
        let effectiveLight = isLight
        applyMode(followSystem: isFollowSystem, smart: false, light: effectiveLight)
    }

    // MARK: 设置：浅色 / 深色
    @MainActor static func setDarkModeCustom(isLight: Bool) {
        applyMode(followSystem: false, smart: false, light: isLight)
    }

    // MARK: 设置：智能换肤
    /// 智能换肤。
    /// - Parameter isSmartPeeling: 是否智能换肤。
    @MainActor static func setSmartPeelingDarkMode(isSmartPeeling: Bool) {
        let effectiveLight = isLight
        let targetLight = isSmartPeeling ? !isSmartPeelingTime() : effectiveLight
        applyMode(followSystem: false, smart: isSmartPeeling, light: targetLight)
    }

    // MARK: 智能换肤时间选择后
    /// 智能换肤时间选择后。
    @MainActor static func setSmartPeelingTimeChange(startTime: String,
                                                      endTime: String) {
        guard let range = PTDarkTimeRange(startTime: startTime, endTime: endTime) else { return }
        storeTimeRange(range)
        refreshCurrentMode(notify: true)
        PTDarkModeScheduleMonitor.shared.modeDidChange()
    }
}

// MARK: - 动态颜色的使用
public extension PTDarkModeOption {
    static func colorLightDark(lightColor: UIColor,
                               darkColor: UIColor) -> UIColor {
        UIColor { traitCollection in
            switch currentMode {
            case .system:
                return traitCollection.userInterfaceStyle == .dark ? darkColor : lightColor
            case .smart:
                return isSmartPeelingTime() ? darkColor : lightColor
            case .manual:
                return isLight ? lightColor : darkColor
            }
        }
    }

    // MARK: 是否为智能换肤的时间：黑色
    /// 返回当前时间是否处于深色时间区间。
    static func isSmartPeelingTime(startTime: String? = nil,
                                   endTime: String? = nil) -> Bool {
        let range: PTDarkTimeRange?
        if let startTime, let endTime {
            range = PTDarkTimeRange(startTime: startTime, endTime: endTime)
        } else {
            range = storedTimeRange
        }
        guard let range else { return false }
        return range.contains(Date())
    }
}

// MARK: - 动态图片的使用
public extension PTDarkModeOption {
    /// 使用 UIImageAsset 注册浅色和深色图片，避免依赖传入图片当前的配置。
    static func image(light: UIImage?,
                      dark: UIImage?) -> UIImage? {
        guard let light, let dark else { return light }
        let asset = UIImageAsset()
        asset.register(light, with: UITraitCollection(userInterfaceStyle: .light))
        asset.register(dark, with: UITraitCollection(userInterfaceStyle: .dark))
        return asset.image(with: UITraitCollection.current)
    }
}
