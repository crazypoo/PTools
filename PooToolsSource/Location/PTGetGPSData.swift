//
//  PTGetGPSData.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import CoreLocation
#if SWIFT_PACKAGE
import PToolsStorage
#endif

@MainActor
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
    public private(set) var currentSnapshot: PTLocationSnapshot?
    private var isInvalidated = false
    private let storage = PTStorage(namespace: PTStorageNamespace(module: "PooTools", feature: "location"),
                                     backend: PTUserDefaultsStorage())
    private let storageKey = PTStorageKey<PTLocationSnapshot>("current")
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000
        currentSnapshot = Self.legacySnapshot()
        lat = currentSnapshot?.latitude ?? 0
        lon = currentSnapshot?.longitude ?? 0
    }

    // English: Start one location session and keep its delegate on MainActor.
    // Español: Inicia una sesión de ubicación y mantiene su delegado en MainActor.
    // 中文：启动一次定位会话，并让代理始终受 MainActor 管理。
    public func start() {
        guard !isInvalidated else { return }
        locationManager.delegate = self
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            errorBlock?()
        }
    }

    public func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
    }

    public func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        stop()
        errorBlock = nil
        selectCurrentBlock = nil
        selectNewBlock = nil
    }
    
    public func getUserLocation(block: ((_ lat:String,_ lon:String,_ cityName:String) -> Void)?) {
        let snapshot = currentSnapshot ?? Self.legacySnapshot()
        let latitude = snapshot?.latitude ?? 0
        let longitude = snapshot?.longitude ?? 0
        let city = snapshot?.city ?? "Unnkow city"
        block?(String(latitude), String(longitude), city)

        // English: Migrate the legacy keys once without changing the synchronous callback contract.
        // Español: Migra las claves heredadas una vez sin cambiar el contrato síncrono del callback.
        // 中文：在不改变同步回调契约的前提下，一次性迁移旧键值。
        if let snapshot {
            persist(snapshot)
        }
    }
    
    func setObjectFunction(city:String) {
        let snapshot = PTLocationSnapshot(latitude: lat, longitude: lon, city: city)
        currentSnapshot = snapshot
        persist(snapshot)
    }

    private func persist(_ snapshot: PTLocationSnapshot) {
        Task { [storage, storageKey] in
            try? await storage.set(snapshot, for: storageKey)
        }
        // Keep the legacy values for one migration window for existing consumers.
        UserDefaults.standard.set(String(snapshot.longitude), forKey: "lon")
        UserDefaults.standard.set(String(snapshot.latitude), forKey: "lat")
        UserDefaults.standard.set(snapshot.city, forKey: "locCity")
    }

    private static func legacySnapshot() -> PTLocationSnapshot? {
        guard let latitudeString = UserDefaults.standard.string(forKey: "lat"),
              let longitudeString = UserDefaults.standard.string(forKey: "lon"),
              let latitude = Double(latitudeString),
              let longitude = Double(longitudeString) else {
            return nil
        }
        let city = UserDefaults.standard.string(forKey: "locCity") ?? "Unnkow city"
        return PTLocationSnapshot(latitude: latitude, longitude: longitude, city: city)
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
            Task { @MainActor in
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
                            Task { @MainActor in
                                self.selectNewBlock?()
                            }
                        }
                    } else {
                        self.setObjectFunction(city: cityStr)
                        Task { @MainActor in
                            self.selectNewBlock?()
                        }
                    }
                }
                
                if distance > 1000 {
                    Task { @MainActor in
                        self.selectNewBlock?()
                    }
                }
            }
        }
    }
    
    @MainActor public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else if status != .notDetermined {
            errorBlock?()
        }
    }
    
    private func showChangeCityAlert(newCity: String, oldCity: String) {
        if isShow < 2 {
            isShow += 1
            let cancelStr = "\("PT Location continue select".localized())\(oldCity)"
            let doneStr = "\("PT Location change to".localized())\(newCity)"
            
            UIAlertController.base_alertVC(title: "PT Alert Opps".localized(),msg: "PT Location change".localized(),okBtns: [doneStr],cancelBtn: cancelStr,cancelBtnColor: .black,doneBtnColors: [.black]) {
                Task { @MainActor in
                    self.selectCurrentBlock?()
                    self.isShow = 0
                }
            } moreBtn: { _, _ in
                self.setObjectFunction(city: newCity)
                self.isShow = 0
                Task { @MainActor in
                    self.selectNewBlock?()
                }
            }
        }
    }
}
