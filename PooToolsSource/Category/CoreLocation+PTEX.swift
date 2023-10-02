//
//  CoreLocation+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import CoreLocation

extension CLLocation: PTProtocolCompatible {}

public extension PTPOP where Base == CLLocation {
    //MARK: 地理信息反编码
    ///地理信息反编码
    /// - Parameters:
    ///   - latitude: 精度
    ///   - longitude: 纬度
    ///   - completionHandler: 回调函数
    static func reverseGeocode(latitude: CLLocationDegrees,
                               longitude: CLLocationDegrees,
                               completionHandler: @escaping CLGeocodeCompletionHandler) {
        let geocoder = CLGeocoder()
        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        geocoder.reverseGeocodeLocation(currentLocation, completionHandler: completionHandler)
    }
    
    //MARK: 地理信息编码
    ///地理信息编码
    /// - Parameters:
    ///   - address: 地址信息
    ///   - completionHandler: 回调函数
    static func locationEncode(address: String,
                               completionHandler: @escaping CLGeocodeCompletionHandler) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, completionHandler: completionHandler)
    }
    
    //MARK: 点与点之间的距离
    ///点与点之间的距离
    /// - Parameters:
    ///   - currentLocationCoordinate2D: 起点
    ///   - targetLocationCoordinate2D: 终点
    /// - Returns: 之间的距离
    static func distanePointToPoint(startLocationCoordinate2D: CLLocationCoordinate2D,
                                    endLocationCoordinate2D: CLLocationCoordinate2D) -> Double {
        // 地球半径
        let earthRadius: Double = 6378137.0
        
        let radLat1 = startLocationCoordinate2D.latitude.degreesToRadians()
        let radLng1 = startLocationCoordinate2D.longitude.degreesToRadians()
        
        let radLat2 = endLocationCoordinate2D.latitude.degreesToRadians()
        let radLng2 = endLocationCoordinate2D.longitude.degreesToRadians()
        
        let a = radLat1 - radLat2
        let b = radLng1 - radLng2
        
        let distance: Double = 2 * asin(sqrt(pow(sin(a / 2), 2) + cos(radLat1) * cos(radLat2) * pow(sin(b / 2), 2)))
        return distance * earthRadius
    }
}
