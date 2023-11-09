//
//  PTDebugFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTDebugFunction: NSObject {
    //MARK: App測試模式的檢測
    ///App測試模式的檢測
    class open func registerDefaultsFromSettingsBundle() {
        if let settingsBundle = Bundle.main.path(forResource: "Settings", ofType: "bundle") {
            let settings = NSDictionary.init(contentsOfFile: settingsBundle.nsString.appendingPathComponent("Root.plist"))
            let prefernces = settings!["PreferenceSpecifiers"] as! [NSDictionary]
            let defaultsToRegister = NSMutableDictionary.init(capacity: prefernces.count)
            for prefSpecification in prefernces {
                if let key :String = prefSpecification["Key"] as? String {
                    defaultsToRegister[key] = prefSpecification["DefaultValue"]
                }
            }
            UserDefaults.standard.register(defaults: defaultsToRegister as! [String : Any])
        } else {
            PTCoreUserDefultsWrapper.AppServiceIdentifier = nil
            PTNSLogConsole("没有发现Settings.bundle")
        }
    }

}
