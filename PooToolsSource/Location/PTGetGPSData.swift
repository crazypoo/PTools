//
//  PTGetGPSData.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import CoreLocation

@objcMembers
public class PTGetGPSData: NSObject {
    public static let share = PTGetGPSData()
    open var errorBlock:PTActionTask?
    open var selectCurrentBlock:PTActionTask?
    open var selectNewBlock:PTActionTask?
    open var showChangeAlert:Bool = false
    
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
        let lon:String = (UserDefaults.standard.value(forKey: "lon") as? String) ?? "0.0"
        let lat:String = (UserDefaults.standard.value(forKey: "lat") as? String) ?? "0.0"
        let city:String = (UserDefaults.standard.value(forKey: "locCity") as? String) ?? "Unnkow city"

        block?(lat,lon,city)
    }
    
    func setObjectFunction(city:String) {
        let lon = "\(lon)"
        let lat = "\(lat)"
        UserDefaults.standard.set(lon, forKey: "lon")
        UserDefaults.standard.set(lat, forKey: "lat")
        UserDefaults.standard.set(city, forKey: "locCity")
    }
}

extension PTGetGPSData:@preconcurrency CLLocationManagerDelegate {
    @MainActor public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        UIAlertController.base_alertVC(title:String.LocationAuthorizationFail,msg:  String.authorizationSet(type: PTPermission.Kind.location(access: .always)),okBtns: ["PT Setting".localized()],cancelBtn: "PT Button cancel".localized(),moreBtn: { _, _ in
            PTOpenSystemFunction.openSystemFunction(config:  PTOpenSystemConfig())
        })
        
        errorBlock?()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        locationManager.stopUpdatingLocation()
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
            guard let placeMark = placemarks?.first, let placeLocation = placeMark.location else {
                return
            }
            var distance:CLLocationDistance = 0
            var cityStr = "PT Location fail".localized()
            if let city = placeMark.locality, !city.isEmpty {
                self.lat = placeLocation.coordinate.latitude
                self.lon = placeLocation.coordinate.longitude
                cityStr = city
                let loc1 = CLLocation(latitude: self.lat, longitude: self.lon)
                distance = loc1.distance(from: placeLocation)
                
                if self.showChangeAlert {
                    let savedCity = UserDefaults.standard.string(forKey: "locCity") ?? ""
                    if savedCity != cityStr {
                        self.showChangeCityAlert(newCity: cityStr, oldCity: savedCity)
                    } else {
                        self.setObjectFunction(city: cityStr)
                        self.selectNewBlock?()
                    }
                } else {
                    self.setObjectFunction(city: cityStr)
                    self.selectNewBlock?()
                }
            }
            
            if distance > 1000 {
                self.selectNewBlock?()
            }
        }
    }
    
    @MainActor public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            PTGCDManager.gcdMain {
                // 在主线程上更新UI或执行其他操作
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.requestAlwaysAuthorization()
            }
        } else {
            errorBlock?()
        }
    }
    
    private func showChangeCityAlert(newCity: String, oldCity: String) {
        if isShow < 2 {
            isShow += 1
            let cancelStr = "\("PT Location continue select".localized())\(oldCity)"
            let doneStr = "\("PT Location change to".localized())\(newCity)"
            
            UIAlertController.base_alertVC(title: "PT Alert Opps".localized(),msg: "PT Location change".localized(),okBtns: [doneStr],cancelBtn: cancelStr,cancelBtnColor: .black,doneBtnColors: [.black]) {
                
                self.selectCurrentBlock?()
                self.isShow = 0
            } moreBtn: { _, _ in
                self.setObjectFunction(city: newCity)
                self.selectNewBlock?()
                self.isShow = 0
            }
        }
    }
}
