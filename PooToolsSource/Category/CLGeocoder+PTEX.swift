//
//  CLGeocoder+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/6.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import CoreLocation

public typealias InChinaMainlandCallback = (_ errMsg: String?, _ inChinaMainland: Bool) -> Void
public typealias InHMTCallback = (_ errMsg: String?, _ inHMT: Bool) -> Void
public typealias CLPlacemarkCallback = (_ errMsg: String?, _ placemark: CLPlacemark?) -> Void

public enum IsoCountryCode: String {
    case CN
    case HK
    case MO
    case TW
}

public extension CLGeocoder {
    
    /// 反编译GPS坐标点 判断坐标点位置是否在中国大陆
    ///
    /// - Parameters:
    ///   - location: GPS坐标点
    ///   - handler: errMsg: 出错 / inChina: 是否在中国大陆
    func reverseGeocodeWith(location: CLLocation, inChinaMainland handler: @escaping InChinaMainlandCallback) {
        self.reverseGeocodeLocation(location) { (placemarks, error) in
            if error != nil || placemarks?.count == 0 {
                handler(error?.localizedDescription, false)
            } else {
                if let placemark = placemarks?.first {
                    if let iso = IsoCountryCode(rawValue: placemark.isoCountryCode ?? "") {
                        handler(nil, (iso == .CN || placemark.country == "中国"))
                    } else {
                        handler(nil, false)
                    }
                } else {
                    handler(error?.localizedDescription, false)
                }
            }
        }
    }
    
    /// 反编译GPS坐标点 判断坐标点位置是否在港澳台
    ///
    /// - Parameters:
    ///   - location: GPS坐标点
    ///   - handler: errMsg: 出错 / inHMT: 是否在港澳台
    func reverseGeocodeWith(location: CLLocation, inHMT handler: @escaping InHMTCallback) {
        self.reverseGeocodeLocation(location) { (placemarks, error) in
            if error != nil || placemarks?.count == 0 {
                handler(error?.localizedDescription, false)
            } else {
                if let placemark = placemarks?.first {
                    let iso = IsoCountryCode(rawValue: placemark.isoCountryCode ?? "") ?? .CN
                    handler(nil, (iso == .HK || iso == .MO || iso == .TW))
                } else {
                    handler(error?.localizedDescription, false)
                }
            }
        }
    }
    
    /// 反编译GPS坐标点 判断坐标点位置所在地区
    ///
    /// - Parameters:
    ///   - location: GPS坐标点
    ///   - handler: errMsg: 出错 / placemark: 地标地区
    func reverseGeocodeWith(location: CLLocation, placemark handler: @escaping CLPlacemarkCallback) {
        self.reverseGeocodeLocation(location) { (placemarks, error) in
            if error != nil || placemarks?.count == 0 {
                handler(error?.localizedDescription, nil)
            } else {
                let placemark = placemarks?.first
                handler(nil, placemark)
            }
        }
    }
}
