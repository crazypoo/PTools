//
//  PTGetGPSData.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import CoreLocation

public typealias PTGPSBlock = () -> Void

@objcMembers
public class PTGetGPSData: NSObject {
    static let share = PTGetGPSData()
    public var errorBlock:PTGPSBlock?
    public var selectCurrentBlock:PTGPSBlock?
    public var selectNewBlock:PTGPSBlock?
    public var showChangeAlert:Bool = false
    
    var locationManager = CLLocationManager()
    var lat:Double = 0
    var lon:Double = 0
    var isShow:NSInteger = 0
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000
    }
    
    public func getUserLocation(block: ((_ lat:String,_ lon:String,_ cityName:String)->Void)?) {
        let lon:String = UserDefaults.standard.value(forKey: "lon") as! String
        let lat:String = UserDefaults.standard.value(forKey: "lat") as! String
        let city:String = UserDefaults.standard.value(forKey: "locCity") as! String

        if block != nil {
            block!(lat,lon,city)
        }
    }
    
    func setObjectFunction(city:String) {
        let lon = "\(lon)"
        let lat = "\(lat)"
        UserDefaults.standard.set(lon, forKey: "lon")
        UserDefaults.standard.set(lat, forKey: "lat")
        UserDefaults.standard.set(city, forKey: "locCity")
    }
}

extension PTGetGPSData:CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        UIAlertController.base_alertVC(title:"提示",msg: "您还未开启定位服务，是否需要开启？",okBtns: ["确定"],cancelBtn: "取消") {
            
        } moreBtn: { index, title in
            let settingUrl = URL(string: UIApplication.openSettingsURLString)
            UIApplication.shared.open(settingUrl!)
        }
        
        if errorBlock != nil {
            errorBlock!()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        
        let currentLocation = locations.last
        let geoCoder = CLGeocoder()
        let userDefaultLanguages = UserDefaults.standard.value(forKey: "AppleLanguages")
        UserDefaults.standard.set(["zh-hans"], forKey: "AppleLanguages")
        geoCoder.reverseGeocodeLocation(currentLocation!) { placemarks, error in
            var distance:CLLocationDistance = 0
            var cityStr = "⟳定位失败"
            if placemarks?.count ?? 0 > 0 {
                let placeMark:CLPlacemark = placemarks![0]
                let city = placeMark.locality
                PTNSLogConsole("city:>>>>>>>>>>>>>>>>>>>>\(city ?? "")")

                if !(city ?? "").stringIsEmpty() {
                    let loc1 = CLLocation(latitude: self.lat, longitude: self.lon)
                    let loc2 = placeMark.location
                    self.lat = placeMark.location?.coordinate.latitude ?? 0
                    self.lon = placeMark.location?.coordinate.longitude ?? 0
                    cityStr = placeMark.locality ?? ""
                    distance = loc1.distance(from: loc2!)
                    
                    let getUserLocCtiy:String? = UserDefaults.standard.value(forKey: "locCity") as? String
                    PTNSLogConsole("getUserLocCtiy:>>>>>>>>>>>>>>>>>>>>\(getUserLocCtiy ?? "")")
                    if !(getUserLocCtiy ?? "").stringIsEmpty() {
                        if self.showChangeAlert {
                            if getUserLocCtiy != cityStr {
                                self.isShow += 1
                                if self.isShow < 2 {
                                    let cancelStr = "继续选择\(getUserLocCtiy!)"
                                    let doneStr = "切换到\(cityStr)"
                                    UIAlertController.base_alertVC(title: "提示",msg: "系统检测到你当前地区与您所选的地区不相符是否切换",okBtns: [doneStr],cancelBtn: cancelStr,cancelBtnColor: .black,doneBtnColors: [.black]) {
                                        
                                        if self.selectCurrentBlock != nil {
                                            self.selectCurrentBlock!()
                                        }
                                        self.isShow = 0
                                    } moreBtn: { index, title in
                                        self.setObjectFunction(city: cityStr)
                                        if self.selectNewBlock != nil {
                                            self.selectNewBlock!()
                                        }
                                        self.isShow = 0
                                    }
                                }
                            } else {
                                self.setObjectFunction(city: cityStr)
                                if self.selectNewBlock != nil {
                                    self.selectNewBlock!()
                                }
                            }
                        } else {
                            self.setObjectFunction(city: cityStr)
                            if self.selectNewBlock != nil {
                                self.selectNewBlock!()
                            }
                        }
                    } else {
                        self.setObjectFunction(city: cityStr)
                        if self.selectNewBlock != nil {
                            self.selectNewBlock!()
                        }
                    }
                }
            }
            
            UserDefaults.standard.set(userDefaultLanguages, forKey: "AppleLanguages")
            if distance > 1000 {
                if self.selectNewBlock != nil {
                    self.selectNewBlock!()
                }
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            PTGCDManager.gcdMain {
                // 在主线程上更新UI或执行其他操作
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.requestAlwaysAuthorization()
            }
        } else {
            if errorBlock != nil {
                errorBlock!()
            }
        }
    }
}
