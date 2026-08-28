//
//  PTAppUserdefault.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public let DevNetWorkKey = "UI_test_url"
public let DevSocketKey = "UI_test_socket_url"
public let PTDevMaskTouchBubbleKey = "PTDevMaskTouchBubbleKey"
public let PTDevMaskKey = "PTDevMaskKey"
public let ConsoleDebug = "UI_debug"
public let TouchInspectorDebug = "TS_debug"
public let TouchInspectorHitsDebug = "TS_Hit_debug"

// UserDefaults is the single source of truth; the wrapper has no mutable instance state.
// UserDefaults es la única fuente de verdad; el envoltorio no tiene estado mutable de instancia.
// UserDefaults 是唯一数据源；这个包装器不持有可变实例状态。
public final class PTCoreUserDefultsWrapper: Sendable {

    public static let shared = PTCoreUserDefultsWrapper()
    private init() {}

    private static func value<T>(_ key: String, default defaultValue: T) -> T {
        UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
    }

    private static func optionalValue<T>(_ key: String) -> T? {
        UserDefaults.standard.object(forKey: key) as? T
    }

    private static func set(_ value: Any?, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    //MARK: 是否再显示更新框(0继续显示1不再显示)
    ///是否再显示更新框(0继续显示1不再显示)
    public var AppNoMoreShowUpdate: Bool {
        get { Self.value("AppNoMoreShowUpdate", default: false) }
        set { Self.set(newValue, forKey: "AppNoMoreShowUpdate") }
    }

    //MARK: App的全局URL环境配置设置(1生产2测试3自定义)
    ///App的全局URL环境配置设置(1生产2测试3自定义)
    public var AppServiceIdentifier: String? {
        get { Self.optionalValue("AppServiceIdentifier") }
        set { Self.set(newValue, forKey: "AppServiceIdentifier") }
    }

    ///App的全局URL环境配置设置(1生产2测试3自定义)
    public var AppSocketServiceIdentifier: String? {
        get { Self.optionalValue("AppSocketServiceIdentifier") }
        set { Self.set(newValue, forKey: "AppSocketServiceIdentifier") }
    }

    //MARK: App的自定义URL环境请求连接
    ///App的自定义SocketURL环境请求连接
    public var AppSocketUrl: String {
        get { Self.value(DevSocketKey, default: "") }
        set { Self.set(newValue, forKey: DevSocketKey) }
    }

    ///App的自定义URL环境请求连接
    public var AppRequestUrl: String {
        get { Self.value(DevNetWorkKey, default: "") }
        set { Self.set(newValue, forKey: DevNetWorkKey) }
    }

    //MARK: App测试环境(YES是)
    ///App测试环境(YES是)
    public var AppDebugMode: Bool {
        get { Self.value(ConsoleDebug, default: false) }
        set { Self.set(newValue, forKey: ConsoleDebug) }
    }

    //MARK: App测试环境图片选项(YES是)
    ///App测试环境图片选项(YES是)
    public var WebImageOption: Bool {
        get { Self.value("WebImageOption", default: false) }
        set { Self.set(newValue, forKey: "WebImageOption") }
    }

    //MARK: App测试环境点击泡泡(YES是)
    ///App测试环境点击泡泡(YES是)
    public var AppDebbugTouchBubble: Bool {
        get { Self.value(PTDevMaskTouchBubbleKey, default: true) }
        set { Self.set(newValue, forKey: PTDevMaskTouchBubbleKey) }
    }

    //MARK: App测试环境标识(YES是)
    ///App测试环境标识(YES是)
    public var AppDebbugMark: Bool {
        get { Self.value(PTDevMaskKey, default: true) }
        set { Self.set(newValue, forKey: PTDevMaskKey) }
    }

    //MARK: App测试环境点击信息(YES是)
    ///App测试环境点击信息(YES是)
    public var AppTouchInspectShow: Bool {
        get { Self.value(TouchInspectorDebug, default: true) }
        set { Self.set(newValue, forKey: TouchInspectorDebug) }
    }

    //MARK: App测试环境点击信息Hits(YES是)
    ///App测试环境点击信息Hits(YES是)
    public var AppTouchInspectShowHits: Bool {
        get { Self.value(TouchInspectorHitsDebug, default: true) }
        set { Self.set(newValue, forKey: TouchInspectorHitsDebug) }
    }

    public var LocalConsoleCurrentFontSize: CGFloat {
        get { Self.value("LocalConsoleFontSize", default: 7.5) }
        set { Self.set(newValue, forKey: "LocalConsoleFontSize") }
    }

    public var LocalConsoleCurrentFontColor: String {
        get { Self.value("LocalConsoleFontColor", default: "#FFFFFF") }
        set { Self.set(newValue, forKey: "LocalConsoleFontColor") }
    }

    //MARK: App语言环境(默认中文zh-Hans)
    ///App语言环境(默认中文zh-Hans)
    public var AppLanguage: String {
        get { Self.value("MyAppLanguage", default: PTDefaultLanguage) }
        set { Self.set(newValue, forKey: "MyAppLanguage") }
    }

    //MARK: App网络测速记录
    ///App网络测速记录
    public var NetworkSpeedTestFunctionHistoria: String {
        get { Self.value("AppNetworkSpeedTestFunctionHistoria", default: "") }
        set { Self.set(newValue, forKey: "AppNetworkSpeedTestFunctionHistoria") }
    }

    //MARK: App权限检测
    ///权限检测
    public var AppFirstPermissionShowed: Bool {
        get { Self.value("AppFirstPermission", default: false) }
        set { Self.set(newValue, forKey: "AppFirstPermission") }
    }

    //MARK: PTWhatsNews记录版本
    ///PTWhatsNews记录版本
    public var PTWhatNewsLatestAppVersionPresented: String {
        get { Self.value("PTWhatNewsLatestAppVersionPresented", default: "") }
        set { Self.set(newValue, forKey: "PTWhatNewsLatestAppVersionPresented") }
    }

    //MARK: LocalConsole
    public var PTLocalConsoleWidth: CGFloat? {
        get { Self.optionalValue("LocalConsole.Width") }
        set { Self.set(newValue, forKey: "LocalConsole.Width") }
    }

    public var PTLocalConsoleHeight: CGFloat? {
        get { Self.optionalValue("LocalConsole.Height") }
        set { Self.set(newValue, forKey: "LocalConsole.Height") }
    }

    public var PTLocalConsoleX: CGFloat? {
        get { Self.optionalValue("LocalConsole.X") }
        set { Self.set(newValue, forKey: "LocalConsole.X") }
    }

    public var PTLocalConsoleY: CGFloat? {
        get { Self.optionalValue("LocalConsole.Y") }
        set { Self.set(newValue, forKey: "LocalConsole.Y") }
    }

    public var PTMockLocationLat: CGFloat {
        get { Self.value("MockLocationLat", default: 0) }
        set { Self.set(newValue, forKey: "MockLocationLat") }
    }

    public var PTMockLocationLng: CGFloat {
        get { Self.value("MockLocationLng", default: 0) }
        set { Self.set(newValue, forKey: "MockLocationLng") }
    }

    public var PTMockLocationOpen: Bool {
        get { Self.value("MockLocationOpen", default: false) }
        set { Self.set(newValue, forKey: "MockLocationOpen") }
    }

#if DEBUG
    public var PTLogWrite: Bool {
        get { Self.value("LogWriteToTextFile", default: true) }
        set { Self.set(newValue, forKey: "LogWriteToTextFile") }
    }
#else
    public var PTLogWrite: Bool {
        get { Self.value("LogWriteToTextFile", default: false) }
        set { Self.set(newValue, forKey: "LogWriteToTextFile") }
    }
#endif
}
