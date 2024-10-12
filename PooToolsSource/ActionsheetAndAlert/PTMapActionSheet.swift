//
//  PTMapActionSheet.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import MapKit

fileprivate extension String {
    static let BaiduMap = "PT Map baidu".localized()
    static let AMap = "PT Map avi".localized()
    static let QQMap = "PT Map qq".localized()
    static let GoogleMap = "PT Map google".localized()
}

/*
 须要在info.plist中的Queried URL Scheme中添加以下对应的scheme
 */
@objcMembers
open class PTMapActionSheet: NSObject {
    //MARK: 地图跳转ActionSheet
    ///地图跳转ActionSheet
    /// - Parameters:
    ///   - currentAppScheme: 当前App的Scheme
    ///   - currentAppName: 当前App的名字
    ///   - qqKey: 腾讯地图的Key
    ///   - formLocation:
    ///   - location: 跳转坐标
    ///   - dismissTask: 关闭回调
    open class func mapNavAlert(currentAppScheme:String,
                                currentAppName:String? = kAppDisplayName!,
                                qqKey:String? = "",
                                formLocation:CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                location:CLLocationCoordinate2D,
                                dismissTask:PTActionTask? = nil) {
        let appScheme = currentAppScheme
        let locations = location
        var navAppName = [String]()
        let appName = currentAppName!
        if UIApplication.shared.canOpenURL(URL.init(string: "baidumap://")!) {
            navAppName.append(.BaiduMap)
        }
        
        if UIApplication.shared.canOpenURL(URL.init(string: "iosamap://")!) {
            navAppName.append(.AMap)
        }
        
        if UIApplication.shared.canOpenURL(URL.init(string: "comgooglemaps://")!) {
            navAppName.append(.GoogleMap)
        }
        
        if UIApplication.shared.canOpenURL(URL.init(string: "qqmap://")!) && !qqKey!.stringIsEmpty() && (formLocation?.latitude != 0 && formLocation?.longitude != 0) {
            navAppName.append(.QQMap)
        }
        
        UIAlertController.baseActionSheet(title: "PT Select nav".localized(),destructiveButtons:["Apple Map"], titles: navAppName) { sheet,index,title  in
            let currentLocation = MKMapItem.forCurrentLocation()
            let toLocation = MKMapItem.init(placemark: MKPlacemark.init(coordinate: locations))
            MKMapItem.openMaps(with: [currentLocation,toLocation], launchOptions: [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey:1])
            
        } cancelBlock: { sheet in
            dismissTask?()
        } otherBlock: { sheet, index,title in
            var urlString :NSString = ""
            if navAppName[index] == .BaiduMap {
                urlString = NSString.init(format: "baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=gcj02", locations.latitude,locations.longitude).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
            } else if navAppName[index] == .AMap {
                urlString = NSString.init(format: "iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2", appName,appScheme,locations.latitude,locations.longitude).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
            } else if navAppName[index] == .GoogleMap {
                urlString = NSString.init(format: "comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving", appName,appScheme,locations.latitude,locations.longitude).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
            } else if navAppName[index] == .QQMap {
                urlString = NSString.init(format: "qqmap://map/routeplan?type=drive&fromcoord=%f,%f&tocoord=%f,%f&referer=%@", formLocation!.longitude,formLocation!.latitude,locations.latitude,locations.longitude,qqKey!).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
            }
            PTAppStoreFunction.jumpLink(url: URL.init(string: urlString as String)!)
        } tapBackgroundBlock: { sheet in
            dismissTask?()
        }
    }
}
