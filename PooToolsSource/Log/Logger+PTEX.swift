//
//  Logger+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/2.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import OSLog

@objc public enum LoggerEXType:Int,CaseIterable {
    case ViewCycle
    case Network
    case Other
    case Router
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

@available(iOS 14.0, *)
public extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let ViewCycle = Logger(subsystem: subsystem, category: "ViewCycle")
    static let Network = Logger(subsystem: subsystem, category: "Nerwork")
    static let Other = Logger(subsystem: subsystem, category: "Other")
    static let Router = Logger(subsystem: subsystem, category: "Router")
}
