//
//  PTPermissionLocationWhenInUseHandler.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import MapKit

class PTPermissionLocationWhenInUseHandler: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Location Manager
    
    lazy var locationManager = CLLocationManager()
    
#if !os(visionOS)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined {
            return
        }
        completionHandler()
    }
#endif

    @available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, visionOS 1.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .notDetermined {
            return
        }
        completionHandler()
    }
    
    // MARK: - Process
    
    var completionHandler: () -> Void = {}
    
    func requestPermission(_ completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
        
        let status: CLAuthorizationStatus = {
            #if os(visionOS)
            locationManager.authorizationStatus
            #elseif os(macOS)
            locationManager.authorizationStatus
            #else
            CLLocationManager.authorizationStatus()
            #endif
        }()

        switch status {
        case .notDetermined:
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        default:
            self.completionHandler()
        }
    }
    
    // MARK: - Init
    
    static var shared: PTPermissionLocationWhenInUseHandler?
    
    override init() {
        super.init()
    }
    
    deinit {
        locationManager.delegate = nil
    }
}
