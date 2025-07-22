//
//  PTPermissionLocationAlwaysHandler.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import MapKit

class PTPermissionLocationAlwaysHandler: NSObject, @preconcurrency CLLocationManagerDelegate {
    
    // MARK: - Location Manager
    
    lazy var locationManager = CLLocationManager()
    
    @MainActor func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined {
            return
        }
        completionHandler()
    }
  
    @MainActor func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .notDetermined {
            return
        }
        completionHandler()
    }
    
    // MARK: - Process
    
    var completionHandler: PTActionTask = {}
    
    @MainActor func requestPermission(_ completionHandler: @escaping PTActionTask) {
        self.completionHandler = completionHandler
        
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
        default:
            self.completionHandler()
        }
    }
    
    // MARK: - Init
    
    static var shared: PTPermissionLocationAlwaysHandler?
    
    override init() {
        super.init()
    }
    
    deinit {
        locationManager.delegate = nil
    }
}
