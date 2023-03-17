//
//  PTLocationFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import MapKit

fileprivate extension String
{
    static let BaiduMap = "百度地图"
    static let AMap = "高德地图"
    static let QQMap = "腾讯地图"
    static let GoogleMap = "谷歌地图"
}

@objcMembers
public class PTLocationFunction: NSObject {
    //MARK: 根據手機裝的地圖APP來選擇導航到哪一個APP(默認只有Apple map)
    ///根據手機裝的地圖APP來選擇導航到哪一個APP(默認只有Apple map)
    /// - Parameters:
    ///   - currentAppName: 當前APP名字
    ///   - currentAppScheme: 當前APP Scheme域名
    ///   - navLocation: 導航地址經緯度
    ///   - qqMapKey: 騰訊地圖Key(須要QQ地圖則須要)
    public class func showSelectMapApp(currentAppName:String,
                                       currentAppScheme:String,
                                       navLocation:CLLocationCoordinate2D,
                                       qqMapKey:String? = "")
    {
        let appScheme = currentAppScheme
        let locations = navLocation
        var navAppName = [String]()
        if UIApplication.shared.canOpenURL(URL.init(string: "baidumap://")!)
        {
            navAppName.append(.BaiduMap)
        }
        
        if UIApplication.shared.canOpenURL(URL.init(string: "iosamap://")!)
        {
            navAppName.append(.AMap)
        }
        
        if UIApplication.shared.canOpenURL(URL.init(string: "comgooglemaps://")!)
        {
            navAppName.append(.GoogleMap)
        }

        if UIApplication.shared.canOpenURL(URL.init(string: "qqmap://")!) && !qqMapKey!.stringIsEmpty()
        {
            navAppName.append(.QQMap)
        }
        
        UIAlertController.baseActionSheet(title: "选择导航软件", destructiveButtonName:"Apple Map", titles: navAppName) { sheet in
            let currentLocation = MKMapItem.forCurrentLocation()
            let toLocation = MKMapItem.init(placemark: MKPlacemark.init(coordinate: locations))
            MKMapItem.openMaps(with: [currentLocation,toLocation], launchOptions: [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey:1])
        } cancelBlock: { sheet in
            
        } otherBlock: { sheet, index in
            var urlString :NSString = ""
            if navAppName[index] == .BaiduMap
            {
                urlString = NSString.init(format: "baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=gcj02", locations.latitude,locations.longitude).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
            }
            else if navAppName[index] == .AMap
            {
                urlString = NSString.init(format: "iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2", currentAppName,appScheme,locations.latitude,locations.longitude).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
            }
            else if navAppName[index] == .GoogleMap
            {
                urlString = NSString.init(format: "comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving", currentAppName,appScheme,locations.latitude,locations.longitude).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
            }
            else if navAppName[index] == .QQMap
            {
                let lat : String? = UserDefaults.standard.value(forKey: "lat") as? String
                let lon : String? = UserDefaults.standard.value(forKey: "lon") as? String

                urlString = NSString.init(format: "qqmap://map/routeplan?type=drive&fromcoord=%f,%f&tocoord=%f,%f&referer=%@", lat!,lon!,locations.latitude,locations.longitude,qqMapKey!).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
            }
            UIApplication.shared.open(URL.init(string: urlString as String)!, options: [:], completionHandler: nil)
        } tapBackgroundBlock: { sheet in
            
        }
    }
}
