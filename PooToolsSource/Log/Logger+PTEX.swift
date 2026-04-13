//
//  Logger+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/2.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import OSLog
import SwifterSwift

// 优化 1：使用 String 作为 RawValue 时，如果不赋值，默认就是 case 的字符串名称
// 优化 2：将 case 改为小驼峰命名 (lowerCamelCase)，符合 Swift API 设计规范
public enum LoggerEXType: String, CaseIterable {
    case viewCycle = "ViewCycle"
    case network = "Network"
    case other = "Other"
    case router = "Router"
    case cleanCache = "CleanCache"
    case button = "Button"
    case filter = "Filter"
    case anyClass = "AnyClass"
    case array = "Array"
    case avCaptureDevice = "AVCaptureDevice"
    case data = "Data"
    case device = "Device"
    case dictionary = "Dictionary"
    case fileManager = "FileManager"
    case string = "String"
    case uiApplication = "UIApplication"
    case color = "Color"
    case font = "Font"
    case textView = "TextView"
    case url = "URL"
    case userDefaults = "UserDefaults"
    case web = "Web"
    case fWord = "FWord"
    case checkUpdate = "CheckUpdate"
    case contract = "Contract"
    case utils = "Utils"
    case settings = "Settings"
    case file = "File"
    case alert = "Alert"
    case health = "Health"
    case media = "Media"
    case json = "Json"
    case log = "Log"
    case location = "Location"
    case speech = "Speech"
    case qrCode = "QRCode"
    case segment = "Segment"
    case sideMenu = "SideMenu"
    case statusBar = "StatusBar"
    case vision = "Vision"
    case debug = "Debug"
}

// 优化 1：case 改为小驼峰命名
@objc public enum LoggerEXLevelType: Int, CaseIterable {
    case debug
    case error
    case info
    case warning
    case trace
    case notice
    case critical
    case fault
}

public let PTLogMode: LoggerEXLevelType = {
    // 优化 3：探讨这里的逻辑。这里我先假设你需要开发环境用 debug，正式环境用 error。
    // 如果你原本的逻辑是刻意为之，可以改回你的版本。
    if UIApplication.shared.inferredEnvironment_PT != .appStore {
        return .debug
    } else {
        return .error
    }
}()

public extension Logger {
    // 优化 4：去掉强制解包 `!`，提供一个安全的默认值 ("com.unknown.app") 防止极端情况崩溃
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.ptools.unknown"
        
    // 优化 5：修正单词拼写 loger -> logger
    static func logger(categoryName: String) -> Logger {
        return Logger(subsystem: subsystem, category: categoryName)
    }
}
