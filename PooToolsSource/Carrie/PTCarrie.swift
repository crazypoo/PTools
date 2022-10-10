//
//  PTCarrie.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/26.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit
import CoreTelephony
import DeviceKit
import Foundation

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
    
    //MARK: 获取并输出运营商信息
    /// - Returns: 运营商信息
    private static func getCarriers() -> [CTCarrier]? {
        guard !Device.current.isSimulator else {
            return nil
        }
        // 获取并输出运营商信息
        let info = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            guard let providers = info.serviceSubscriberCellularProviders else {
                return []
            }
            return providers.filter { $0.value.carrierName != nil }.values.shuffled()
        } else {
            guard let carrier = info.subscriberCellularProvider, carrier.carrierName != nil else {
                return []
            }
            return [carrier]
        }
    }

    //MARK: 根据数据业务信息获取对应的网络类型
    /// - Parameter currentRadioTech: 当前的无线电接入技术信息
    /// - Returns: 网络类型
    private static func getNetworkType(currentRadioTech: String) -> String {
        /**
         手机的数据业务对应的通信技术
         CTRadioAccessTechnologyGPRS：2G（有时又叫2.5G，介于2G和3G之间的过度技术）
         CTRadioAccessTechnologyEdge：2G （有时又叫2.75G，是GPRS到第三代移动通信的过渡)
         CTRadioAccessTechnologyWCDMA：3G
         CTRadioAccessTechnologyHSDPA：3G (有时又叫 3.5G)
         CTRadioAccessTechnologyHSUPA：3G (有时又叫 3.75G)
         CTRadioAccessTechnologyCDMA1x ：2G
         CTRadioAccessTechnologyCDMAEVDORev0：3G
         CTRadioAccessTechnologyCDMAEVDORevA：3G
         CTRadioAccessTechnologyCDMAEVDORevB：3G
         CTRadioAccessTechnologyeHRPD：3G (有时又叫 3.75G，是电信使用的一种3G到4G的演进技术)
         CTRadioAccessTechnologyLTE：4G (或者说接近4G)
         // 5G：NR是New Radio的缩写，新无线(5G)的意思，NRNSA表示5G NR的非独立组网（NSA）模式。
         CTRadioAccessTechnologyNRNSA：5G NSA
         CTRadioAccessTechnologyNR：5G
         */
        if #available(iOS 14.1, *), currentRadioTech == CTRadioAccessTechnologyNRNSA || currentRadioTech == CTRadioAccessTechnologyNR {
            return "5G"
        }
    
        var networkType = ""
        switch currentRadioTech {
        case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
            networkType = "2G"
        case CTRadioAccessTechnologyeHRPD, CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB, CTRadioAccessTechnologyHSUPA:
            networkType = "3G"
        case CTRadioAccessTechnologyLTE:
            networkType = "4G"
        default:
            break
        }
        return networkType
    }
    
    // MARK: 是否允许VoIP
    /// 是否允许VoIP
    /// - Returns: 是否允许VoIP
    public class func isAllowsVOIPs() -> [Bool]? {
        // 获取并输出运营商信息
        guard let carriers = getCarriers(), carriers.count > 0 else {
            return nil
        }
        return carriers.map{ $0.allowsVOIP}
    }
    
    // MARK: ISO国家代码
    /// ISO国家代码
    /// - Returns: ISO国家代码
    public class func isoCountryCodes() -> [String]? {
        // 获取并输出运营商信息
        guard  let carriers = getCarriers(), carriers.count > 0 else {
            return nil
        }
        return carriers.map{ $0.isoCountryCode!}
    }
    
    // MARK: 移动网络码(MNC)
    /// 移动网络码(MNC)
    /// - Returns: 移动网络码(MNC)
    public class func mobileNetworkCodes() -> [String]? {
        // 获取并输出运营商信息
        guard  let carriers = getCarriers(), carriers.count > 0 else {
            return nil
        }
        return carriers.map{ $0.mobileNetworkCode!}
    }
    
    // MARK: 移动国家码(MCC)
    /// 移动国家码(MCC)
    /// - Returns: 移动国家码(MCC)
    public class func mobileCountryCodes() -> [String]? {
        // 获取并输出运营商信息
        guard  let carriers = getCarriers(), carriers.count > 0 else {
            return nil
        }
        return carriers.map{ $0.mobileCountryCode!}
    }
    
    // MARK: 运营商名字
    /// 运营商名字
    /// - Returns: 运营商名字
    public class func carrierNames() -> [String]? {
        // 获取并输出运营商信息
        guard  let carriers = getCarriers(), carriers.count > 0 else {
            return nil
        }
        return carriers.map{ $0.carrierName!}
    }
    
    
    // MARK: 数据业务对应的通信技术
    /// 数据业务对应的通信技术
    /// - Returns: 通信技术
    public class func currentRadioAccessTechnologys() -> [String]? {
        guard !Device.current.isSimulator else {
            return nil
        }
        // 获取并输出运营商信息
        let info = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            guard let currentRadioTechs = info.serviceCurrentRadioAccessTechnology else {
                return nil
            }
            return currentRadioTechs.values.shuffled()
        } else {
            guard let currentRadioTech = info.currentRadioAccessTechnology else {
                return nil
            }
            return [currentRadioTech]
        }
    }

    // MARK: 设备网络制式
    /// 设备网络制式
    /// - Returns: 网络
    public class func networkTypes() -> [String]? {
        // 获取并输出运营商信息
        guard let currentRadioTechs = currentRadioAccessTechnologys() else {
            return nil
        }
        return currentRadioTechs.compactMap { getNetworkType(currentRadioTech: $0) }
    }
    
    // MARK: sim卡信息
    public class func simCardInfos() -> [CTCarrier]? {
        return getCarriers()
    }
}
