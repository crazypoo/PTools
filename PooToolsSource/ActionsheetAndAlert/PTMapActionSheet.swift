//
//  PTMapActionSheet.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import MapKit

public extension String {
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
    @MainActor open class func mapNavAlert(currentAppScheme:String,
                                           currentAppName:String = kAppDisplayName!,
                                           qqKey:String = "",
                                           formLocation:CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                           location:CLLocationCoordinate2D,
                                           sheetTitle:String = "PT Select nav".localized(),
                                           cancelButtonName:String = "PT Button cancel".localized(),
                                           baiduName:String = String.BaiduMap,
                                           aMapName:String = String.AMap,
                                           gMapName:String = String.GoogleMap,
                                           qMapName:String = String.QQMap,
                                           dismissTask:PTActionTask? = nil) {
        let appScheme = currentAppScheme
        let locations = location
        var navAppName = [String]()
        let appName = currentAppName
        if let baiduURL = URL(string: "baidumap://"),UIApplication.shared.canOpenURL(baiduURL) {
            navAppName.append(baiduName)
        }
        
        if let aMapURL = URL(string: "iosamap://"),UIApplication.shared.canOpenURL(aMapURL) {
            navAppName.append(aMapName)
        }
        
        if let gMapURL = URL(string: "comgooglemaps://"),UIApplication.shared.canOpenURL(gMapURL) {
            navAppName.append(gMapName)
        }
        
        if let qMapURL = URL(string: "qqmap://"),UIApplication.shared.canOpenURL(qMapURL) && !qqKey.stringIsEmpty() && (formLocation?.latitude != 0 && formLocation?.longitude != 0) {
            navAppName.append(qMapName)
        }
        
        UIAlertController.baseActionSheet(title: sheetTitle,cancelButtonName:cancelButtonName, destructiveButtons:["Apple Map"], titles: navAppName) { sheet,index,title  in
            let currentLocation = MKMapItem.forCurrentLocation()
            let toLocation = MKMapItem(placemark: MKPlacemark(coordinate: locations))
            MKMapItem.openMaps(with: [currentLocation,toLocation], launchOptions: [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey:1])
            
        } cancelBlock: { sheet in
            dismissTask?()
        } otherBlock: { sheet, index,title in
            var urlString :String = ""
            if navAppName[index] == baiduName {
                urlString = String(format: "baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=gcj02", locations.latitude,locations.longitude).urlToUnicodeURLString() ?? ""
            } else if navAppName[index] == aMapName {
                urlString = String(format: "iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2", appName,appScheme,locations.latitude,locations.longitude).urlToUnicodeURLString() ?? ""
            } else if navAppName[index] == gMapName {
                urlString = String(format: "comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving", appName,appScheme,locations.latitude,locations.longitude).urlToUnicodeURLString() ?? ""
            } else if navAppName[index] == qMapName {
                urlString = String(format: "qqmap://map/routeplan?type=drive&fromcoord=%f,%f&tocoord=%f,%f&referer=%@", formLocation!.longitude,formLocation!.latitude,locations.latitude,locations.longitude,qqKey).urlToUnicodeURLString() ?? ""
            }
            if let url = URL(string: urlString) {
                PTAppStoreFunction.jumpLink(url: url)
            }
        } tapBackgroundBlock: { sheet in
            dismissTask?()
        }
    }
}
