//
//  PTLocalConsoleFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/1.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import CocoaLumberjack
import SwifterSwift

public func PTNSLogConsole(_ any:Any...,error:Bool = false) {
    var currentAppStatus = ""
    
    switch UIApplication.applicationEnvironment() {
    case .appStore:
        currentAppStatus = "<<<生产环境>>>"
    case .testFlight:
        currentAppStatus = "<<<测试环境>>>"
    default:
        currentAppStatus = "<<<DEBUG环境>>>"
    }

    let loginfo = "\(currentAppStatus)\(any)"
    
    if UIApplication.shared.inferredEnvironment != .appStore {
        DDLog.add(DDOSLogger.sharedInstance)
        if error {
            DDLogError(loginfo)
        } else {
            switch UIApplication.applicationEnvironment() {
            case .debug:
                PTNSLog(loginfo)
            default:
                DDLogVerbose(loginfo)
            }
        }
    } else {
        DDLog.add(DDOSLogger.sharedInstance)
        if error {
            DDLogError(loginfo)
        } else {
            DDLogVerbose(loginfo)
        }
    }
}

public class PTLocalConsoleFunction: NSObject {
    static public let share = PTLocalConsoleFunction()
    
    public var localconsole : LocalConsole = {
        let local = LocalConsole.shared
        return local
    }()
}
