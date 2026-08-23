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
    @MainActor static let BaiduMap = "PT Map baidu".localized()
    @MainActor static let AMap = "PT Map avi".localized()
    @MainActor static let QQMap = "PT Map qq".localized()
    @MainActor static let GoogleMap = "PT Map google".localized()
}

private enum PTMapOption: Hashable {
    case baidu
    case amap
    case google
    case qq
}

/*
 需要在 Info.plist 的 Queried URL Schemes 中添加对应的地图 scheme。
 */
@objcMembers
open class PTMapActionSheet: NSObject {

    @MainActor
    open class func mapNavAlert(currentAppScheme: String,
                                currentAppName: String? = nil,
                                qqKey: String = "",
                                formLocation: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                location: CLLocationCoordinate2D,
                                sheetTitle: String? = nil,
                                cancelButtonName: String? = nil,
                                baiduName: String? = nil,
                                aMapName: String? = nil,
                                gMapName: String? = nil,
                                qMapName: String? = nil,
                                dismissTask: PTActionTask? = nil) {
        guard CLLocationCoordinate2DIsValid(location) else {
            dismissTask?()
            return
        }

        let title = sheetTitle ?? "PT Select nav".localized()
        let cancel = cancelButtonName ?? "PT Button cancel".localized()
        let appName = currentAppName ?? kAppDisplayName ?? ""
        let origin = formLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)

        let names: [PTMapOption: String] = [
            .baidu: baiduName ?? String.BaiduMap,
            .amap: aMapName ?? String.AMap,
            .google: gMapName ?? String.GoogleMap,
            .qq: qMapName ?? String.QQMap
        ]
        var options: [(option: PTMapOption, title: String)] = []

        if canOpen("baidumap://") {
            options.append((.baidu, names[.baidu] ?? String.BaiduMap))
        }
        if canOpen("iosamap://") {
            options.append((.amap, names[.amap] ?? String.AMap))
        }
        if canOpen("comgooglemaps://") {
            options.append((.google, names[.google] ?? String.GoogleMap))
        }
        if canOpen("qqmap://"),
           !qqKey.stringIsEmpty(),
           origin.latitude != 0 || origin.longitude != 0 {
            options.append((.qq, names[.qq] ?? String.QQMap))
        }

        let optionTitles = options.map(\.title)
        UIAlertController.baseActionSheet(
            title: title,
            cancelButtonName: cancel,
            destructiveButtons: ["Apple Map"],
            titles: optionTitles
        ) { _, _, _ in
            let currentLocation = MKMapItem.forCurrentLocation()
            let destination = MKMapItem(placemark: MKPlacemark(coordinate: location))
            MKMapItem.openMaps(
                with: [currentLocation, destination],
                launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                    MKLaunchOptionsShowsTrafficKey: true
                ]
            )
            dismissTask?()
        } cancelBlock: { _ in
            dismissTask?()
        } otherBlock: { _, index, _ in
            guard options.indices.contains(index) else {
                dismissTask?()
                return
            }

            let option = options[index].option
            let urlString: String
            switch option {
            case .baidu:
                urlString = String(format: "baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=gcj02", location.latitude, location.longitude)
            case .amap:
                urlString = String(format: "iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2", appName, currentAppScheme, location.latitude, location.longitude)
            case .google:
                urlString = String(format: "comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving", appName, currentAppScheme, location.latitude, location.longitude)
            case .qq:
                urlString = String(format: "qqmap://map/routeplan?type=drive&fromcoord=%f,%f&tocoord=%f,%f&referer=%@", origin.longitude, origin.latitude, location.longitude, location.latitude, qqKey)
            }

            if let url = URL(string: urlString.urlToUnicodeURLString() ?? urlString) {
                PTAppStoreFunction.jumpLink(url: url)
            }
            dismissTask?()
        } tapBackgroundBlock: { _ in
            dismissTask?()
        }
    }

    @MainActor
    private class func canOpen(_ scheme: String) -> Bool {
        guard let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
