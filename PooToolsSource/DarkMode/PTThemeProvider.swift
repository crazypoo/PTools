//
//  JKThemeProvider.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import Foundation
import UIKit

// English: Keep visual style selection as one enum instead of growing legacy Boolean flags.
// Español: Mantiene la selección visual en un enum en lugar de aumentar las banderas heredadas.
// 中文：使用统一枚举表达视觉样式，避免继续增加历史布尔开关。
public enum PTTabBarVisualStyle: Sendable {
    case classic
    case material
    case glass
    case automatic
}

// English: Immutable appearance snapshots keep frequently used UI components independent from the mutable legacy config.
// Español: Las instantáneas inmutables de apariencia desacoplan los componentes UI frecuentes de la configuración heredada mutable.
// 中文：不可变外观快照让高频 UI 组件不再直接依赖可变的旧配置。
@MainActor
public struct PTNavigationAppearance {
    public var backgroundColor: UIColor
    public var titleColor: UIColor
    public var titleFont: UIFont
    public var largeTitleFont: UIFont

    public init(backgroundColor: UIColor = .clear,
                titleColor: UIColor = .label,
                titleFont: UIFont = .preferredFont(forTextStyle: .headline),
                largeTitleFont: UIFont = .preferredFont(forTextStyle: .largeTitle)) {
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.largeTitleFont = largeTitleFont
    }
}

@MainActor
public struct PTTabBarAppearance {
    public var normalColor: UIColor
    public var selectedColor: UIColor
    public var normalFont: UIFont
    public var selectedFont: UIFont
    public var visualStyle: PTTabBarVisualStyle

    public init(normalColor: UIColor = .secondaryLabel,
                selectedColor: UIColor = .tintColor,
                normalFont: UIFont = .systemFont(ofSize: 11),
                selectedFont: UIFont = .systemFont(ofSize: 11, weight: .semibold),
                visualStyle: PTTabBarVisualStyle = .automatic) {
        self.normalColor = normalColor
        self.selectedColor = selectedColor
        self.normalFont = normalFont
        self.selectedFont = selectedFont
        self.visualStyle = visualStyle
    }

    // English: Read a single immutable tab-bar appearance snapshot from the legacy configuration.
    // Español: Lee una única instantánea inmutable del TabBar desde la configuración heredada.
    // 中文：从旧配置读取一份不可变的 TabBar 外观快照。
    public static var legacyDefault: PTTabBarAppearance {
        let config = PTAppBaseConfig.share
        return PTTabBarAppearance(normalColor: config.tabNormalColor,
                                  selectedColor: config.tabSelectedColor,
                                  normalFont: config.tabNormalFont,
                                  selectedFont: config.tabSelectedFont,
                                  visualStyle: config.tab26Mode ? .automatic : .classic)
    }
}

@MainActor
public struct PTPermissionAppearance {
    public var titleColor: UIColor
    public var subtitleColor: UIColor
    public var deniedColor: UIColor

    public init(titleColor: UIColor = .label,
                subtitleColor: UIColor = .secondaryLabel,
                deniedColor: UIColor = .systemRed) {
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.deniedColor = deniedColor
    }
}

@MainActor
public struct PTMediaAppearance {
    public var placeholder: UIImage?
    public var backgroundColor: UIColor

    public init(placeholder: UIImage? = nil, backgroundColor: UIColor = .systemBackground) {
        self.placeholder = placeholder
        self.backgroundColor = backgroundColor
    }
}

@MainActor
public struct PTListAppearance {
    public var backgroundColor: UIColor
    public var cellBackgroundColor: UIColor

    public init(backgroundColor: UIColor = .systemBackground,
                cellBackgroundColor: UIColor = .secondarySystemBackground) {
        self.backgroundColor = backgroundColor
        self.cellBackgroundColor = cellBackgroundColor
    }
}

@MainActor
public struct PTAlertAppearance {
    public var backgroundColor: UIColor
    public var cornerRadius: CGFloat

    public init(backgroundColor: UIColor = .secondarySystemBackground,
                cornerRadius: CGFloat = 14) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
}

// English: PTTheme is a value snapshot; callers can customize it without mutating PTAppBaseConfig.share.
// Español: PTTheme es una instantánea de valor; los llamadores pueden personalizarla sin mutar PTAppBaseConfig.share.
// 中文：PTTheme 是值类型快照，调用方可以自定义而不修改 PTAppBaseConfig.share。
@MainActor
public struct PTTheme {
    public var navigation: PTNavigationAppearance
    public var tabBar: PTTabBarAppearance
    public var permission: PTPermissionAppearance
    public var media: PTMediaAppearance
    public var list: PTListAppearance
    public var alert: PTAlertAppearance

    public init(navigation: PTNavigationAppearance = .init(),
                tabBar: PTTabBarAppearance = .init(),
                permission: PTPermissionAppearance = .init(),
                media: PTMediaAppearance = .init(),
                list: PTListAppearance = .init(),
                alert: PTAlertAppearance = .init()) {
        self.navigation = navigation
        self.tabBar = tabBar
        self.permission = permission
        self.media = media
        self.list = list
        self.alert = alert
    }

    public static var legacyDefault: PTTheme {
        let config = PTAppBaseConfig.share
        return PTTheme(
            navigation: PTNavigationAppearance(backgroundColor: config.navBackgroundColor,
                                                titleColor: config.navTitleTextColor,
                                                titleFont: config.navTitleFont,
                                                largeTitleFont: config.navLargeTitleFont),
            tabBar: PTTabBarAppearance(normalColor: config.tabNormalColor,
                                       selectedColor: config.tabSelectedColor,
                                       normalFont: config.tabNormalFont,
                                       selectedFont: config.tabSelectedFont),
            permission: PTPermissionAppearance(titleColor: config.permissionTitleColor,
                                               subtitleColor: config.permissionSubtitleColor,
                                               deniedColor: config.permissionDeniedColor),
            media: PTMediaAppearance(placeholder: config.defaultPlaceholderImage,
                                     backgroundColor: config.viewControllerBaseBackgroundColor),
            list: PTListAppearance(backgroundColor: config.viewControllerBaseBackgroundColor,
                                   cellBackgroundColor: config.baseCellBackgroundColor),
            alert: PTAlertAppearance()
        )
    }
}

/*
 其他地方使用方法
 // 1. 注册成为主题观察者 (控制器生命周期中只注册一次)
        themeProvider.register(observer: self)
// 2. 主动调用一次，初始化当前界面的颜色
        apply()
 */
// MARK: - PTThemeProvider协议
public protocol PTThemeProvider: AnyObject {
    func register<Observer: PTThemeable>(observer: Observer)
    func updateTheme()
}

// MARK: - PTThemeable协议
public protocol PTThemeable: AnyObject {
    func apply()
}

// MARK: - 设置遵守UITraitEnvironment的可以使用协议PTThemeable
public extension PTThemeable where Self: UITraitEnvironment {
    @MainActor var themeProvider: PTThemeProvider {
        LegacyThemeProvider.shared
    }
}

// MARK: - LegacyThemeProvider
@MainActor
public class LegacyThemeProvider: @MainActor PTThemeProvider {
    
    /// 单粒
    static let shared = LegacyThemeProvider()
    /// 监听对象数组
    private var observers: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    /// 更新主题
    public func updateTheme() {
        notifyObservers()
    }
    
    // MARK: 注册监听
    /// 注册监听
    /// - Parameter observer: 监听对象
    public func register<Observer: PTThemeable>(observer: Observer) {
        observers.add(observer)
    }
    
    // MARK: 通知监听对象更新theme
    /// 通知监听对象更新theme
    private func notifyObservers() {
        // 当前类型已经隔离在主线程，直接通知可以避免嵌套任务造成的时序延迟。
        observers.allObjects
            .compactMap { $0 as? PTThemeable }
            .forEach { $0.apply() }
    }
}
