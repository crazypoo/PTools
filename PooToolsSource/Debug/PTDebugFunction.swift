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
    class open func registerDefaultsFromSettingsBundle(pod:Bool = false) {
        var bundleSelected:Bundle!
        if pod {
            let bundle = PTUtils.cgBaseBundle()
            let podBundle = bundle.path(forResource: CorePodBundleName, ofType: "bundle")
            bundleSelected = Bundle(path: podBundle!)!
        } else {
            bundleSelected = Bundle.main
        }
        
        if let settingsBundle = bundleSelected.path(forResource: "Settings", ofType: "bundle") {
            let settings = NSDictionary.init(contentsOfFile: settingsBundle.nsString.appendingPathComponent("Root.plist"))
            let prefernces = settings!["PreferenceSpecifiers"] as! [NSDictionary]
            let defaultsToRegister = NSMutableDictionary.init(capacity: prefernces.count)
            for prefSpecification in prefernces {
                if let key :String = prefSpecification["Key"] as? String {
                    defaultsToRegister[key] = prefSpecification["DefaultValue"]
                }
            }
            UserDefaults.standard.register(defaults: defaultsToRegister as! [String : Any])
            UserDefaults.standard.synchronize()
        } else {
            PTCoreUserDefultsWrapper.AppServiceIdentifier = nil
            PTNSLogConsole("没有发现Settings.bundle")
        }
    }

}
