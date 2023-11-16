//
//  PTAppStoreFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/8.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTAppStoreFunction: NSObject {
    
    //MARK: 評分App
    ///評分App
    /// - Parameters:
    ///   - appid: App的App id
    class open func rateApp(appid:String = PTAppBaseConfig.share.appID) {
        let openAppStore = "itms-apps://itunes.apple.com/app/id\(appid)?action=write-review"
        PTAppStoreFunction.jumpLink(url: URL(string: openAppStore)!)
    }
    
    //MARK: 跳转到AppStore
    ///跳转到AppStore
    /// - Parameters:
    ///   - appid: App的App id
    class open func appStoreURL(appid:String = PTAppBaseConfig.share.appID) -> String {
        let urlString = String(format: "itms-apps://itunes.apple.com/app/id%@",appid)
        return urlString
    }
    
    class open func jumpToAppStore(appid:String = PTAppBaseConfig.share.appID) {
        PTAppStoreFunction.jumpLink(url: URL(string: PTAppStoreFunction.appStoreURL(appid: appid))!)
    }

    class open func jumpLink(url:URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}
