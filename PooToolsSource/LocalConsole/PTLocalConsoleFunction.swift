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
        
    var msgStr = ""
    for element in any {
        
        let result = "\(element)"
        var newString = result
        if element is String {
            if let jsonString = (element as! String).jsonStringToDic() {
                let string = jsonString.convertToJsonString()
                if !string.stringIsEmpty() {
                    newString = string
                }
            }
        } else if element is NSDictionary {
            let dic = (element as! NSDictionary)
            let string = dic.convertToJsonString()
            if !string.stringIsEmpty() {
                newString = string
            }
        } else if element is NSArray {
            let arr = (element as! NSArray)
            let string = arr.convertToJsonString()
            if !string.stringIsEmpty() {
                newString = string
            }
        }
        
        msgStr += "\(newString)\n"
    }

    if UIApplication.shared.inferredEnvironment != .appStore {
        DDLog.add(DDOSLogger.sharedInstance)
        if error {
            DDLogError(msgStr)
        } else {
            PTNSLog(msgStr)
        }
    } else {
        DDLog.add(DDOSLogger.sharedInstance)
        if error {
            DDLogError(msgStr)
        } else {
            DDLogVerbose(msgStr)
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
