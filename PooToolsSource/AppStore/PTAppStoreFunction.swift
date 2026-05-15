//
//  PTAppStoreFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/8.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@MainActor
@objcMembers
public class PTAppStoreFunction: NSObject {
    
    //MARK: 評分App
    ///評分App
    /// - Parameters:
    ///   - appid: App的App id
    static public func rateApp(appid:String? = nil) {
        let aID = appid ?? PTAppBaseConfig.share.appID
        let openAppStore = "itms-apps://itunes.apple.com/app/id\(aID)?action=write-review"
        PTAppStoreFunction.jumpLink(url: URL(string: openAppStore)!)
    }
    
    //MARK: 跳转到AppStore
    ///跳转到AppStore
    /// - Parameters:
    ///   - appid: App的App id
    static public func appStoreURL(appid:String? = nil) -> String {
        let aID = appid ?? PTAppBaseConfig.share.appID
        let urlString = String(format: "itms-apps://itunes.apple.com/app/id%@",aID)
        return urlString
    }
    
    static public func jumpToAppStore(appid:String? = nil) {
        let aID = appid ?? PTAppBaseConfig.share.appID
        PTAppStoreFunction.jumpLink(url: URL(string: PTAppStoreFunction.appStoreURL(appid: aID))!)
    }

    static public func jumpLink(url:URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    static public func checkUpdateURL(bundleId:String) ->String {
        return "https://itunes.apple.com/br/lookup?bundleId=\(bundleId)"
    }
}
