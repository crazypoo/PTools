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

public class PTLocalConsoleFunction: NSObject {
    static public let share = PTLocalConsoleFunction()
    
    public var localconsole : LocalConsole = {
        let local = LocalConsole.shared
        return local
    }()
    
    public func pNSLog(_ any:Any,error:Bool? = false)
    {
        var currentAppStatus = ""
        #if DEBUG
        currentAppStatus = "<<<DEBUG环境>>>"
        #elseif Development
        currentAppStatus = "<<<开发环境>>>"
        #elseif Test
        currentAppStatus = "<<<测试环境>>>"
        #elseif Distribution
        currentAppStatus = "<<<生产环境>>>"
        #endif

        let loginfo = "\(currentAppStatus)\(any)"
        
        if UIApplication.shared.inferredEnvironment != .appStore
        {
            if PTLocalConsoleFunction.share.localconsole.terminal?.systemIsVisible ?? false && PTLocalConsoleFunction.share.localconsole.terminal != nil
            {
                PTLocalConsoleFunction.share.localconsole.print(loginfo)
            }
            DDLog.add(DDOSLogger.sharedInstance)
            if error!
            {
                DDLogError(loginfo)
            }
            else
            {
            #if DEBUG
                DDLogDebug(loginfo)
            #else
                DDLogVerbose(loginfo)
            #endif
            }
        }
        else
        {
            DDLog.add(DDOSLogger.sharedInstance)
            if error!
            {
                DDLogError(loginfo)
            }
            else
            {
                DDLogVerbose(loginfo)
            }
        }
    }
}
