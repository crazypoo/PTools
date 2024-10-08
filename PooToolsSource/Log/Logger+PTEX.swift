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

public enum LoggerEXType:String,CaseIterable {
    case ViewCycle = "ViewCycle"
    case Network = "Network"
    case Other = "Other"
    case Router = "Router"
    case CleanCache = "CleanCache"
    case Button = "Button"
    case Filter = "Filter"
    case AnyClass = "AnyClass"
    case Array = "Array"
    case AVCaptureDevice = "AVCaptureDevice"
    case Data = "Data"
    case Device = "Device"
    case Dictionary = "Dictionary"
    case FileManager = "FileManager"
    case String = "String"
    case UIApplication = "UIApplication"
    case Color = "Color"
    case Font = "Font"
    case TextView = "TextView"
    case URL = "URL"
    case UserDefaults = "UserDefaults"
    case Web = "Web"
    case FWord = "FWord"
    case CheckUpdate = "CheckUpdate"
    case Contract = "Contract"
    case Utils = "Utils"
    case Settings = "Settings"
    case File = "File"
    case Alert = "Alert"
    case Health = "Health"
    case Media = "Media"
    case Json = "Json"
    case Log = "Log"
    case Location = "Location"
    case Speech = "Speech"
    case QRCode = "QRCode"
    case Segment = "Segment"
    case SideMenu = "SideMenu"
    case StatusBar = "StatusBar"
    case Vision = "Vision"
    case Debug = "Debug"
}

@objc public enum LoggerEXLevelType:Int,CaseIterable {
    case Debug
    case Error
    case Info
    case Warning
    case Trace
    case Notice
    case Critical
    case Fault
}

public let PTLogMode:LoggerEXLevelType = {
    if UIApplication.shared.inferredEnvironment != .appStore {
        return .Notice
    } else {
        return .Debug
    }
}()

public extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
        
    static func loger(categoryName:String) ->Logger {
        Logger(subsystem: subsystem, category: categoryName)
    }
}
