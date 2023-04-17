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
    class open func rateApp(appid:String) {
        let openAppStore = "itms-apps://itunes.apple.com/app/id\(appid)?action=write-review"
        UIApplication.shared.open(URL(string: openAppStore)!)
    }
}
