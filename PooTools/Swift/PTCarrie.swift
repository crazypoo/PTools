//
//  PTCarrie.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/26.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit
import CoreTelephony

@objcMembers
class PTCarrie: NSObject {
    /*! @brief 获取手机当前运营商
     */
    public class func currentRadioAccessTechnology()->String
    {
        let current = CTTelephonyNetworkInfo()
        return current.currentRadioAccessTechnology ?? ""
    }
    
    
    /*! @brief 获取手机当前运营商其他信息
     */
    public class func getSiminfo()->NSMutableDictionary
    {
        let dic = NSMutableDictionary()
        
        let info = CTTelephonyNetworkInfo()
        let carrier = info.subscriberCellularProvider
        let mcc = carrier?.mobileCountryCode
        let mnc = carrier?.mobileNetworkCode
        let ccode = carrier?.isoCountryCode
        let name = carrier?.carrierName
        let allowVOIP = carrier!.allowsVOIP ? 1 : 0

        dic.setValue(mcc, forKey: "mobileCountryCode")
        dic.setValue(mnc, forKey: "mobileNetworkCode")
        dic.setValue(ccode, forKey: "isoCountryCode")
        dic.setValue(name, forKey: "carrierName")
        dic.setValue(allowVOIP, forKey: "allowsVOIP")

        return dic
    }
}
