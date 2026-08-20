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
    @MainActor class open func registerDefaultsFromSettingsBundle(pod:Bool = false) {
        let bundleSelected: Bundle
        if pod {
            let bundle = PTUtils.cgBaseBundle()
            let podBundle = bundle.path(forResource: CorePodBundleName, ofType: "bundle")
            guard let podBundle, let resolvedBundle = Bundle(path: podBundle) else {
                PTNSLogConsole("无法加载 PooTools 资源 Bundle", levelType: .error, loggerType: .settings)
                return
            }
            bundleSelected = resolvedBundle
        } else {
            bundleSelected = Bundle.main
        }
        
        if let settingsBundle = bundleSelected.path(forResource: "Settings", ofType: "bundle") {
            guard let settings = NSDictionary(contentsOfFile: settingsBundle.nsString.appendingPathComponent("Root.plist")),
                  let prefernces = settings["PreferenceSpecifiers"] as? [NSDictionary] else {
                PTNSLogConsole("Settings.bundle Root.plist 格式无效", levelType: .error, loggerType: .settings)
                return
            }
            var defaultsToRegister: [String: Any] = [:]
            for prefSpecification in prefernces {
                if let key :String = prefSpecification["Key"] as? String {
                    defaultsToRegister[key] = prefSpecification["DefaultValue"]
                }
            }
            UserDefaults.standard.register(defaults: defaultsToRegister)
            UserDefaults.standard.synchronize()
        } else {
            PTCoreUserDefultsWrapper.shared.AppServiceIdentifier = "1"
            PTNSLogConsole("没有发现Settings.bundle",levelType: PTLogMode,loggerType: .settings)
        }
    }

}
