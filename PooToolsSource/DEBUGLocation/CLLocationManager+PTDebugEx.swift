//
//  CLLocationManager+PTDebugEx.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/31.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocationManager {
    static func swizzleMethods() {
        Swizzle(CLLocationManager.self) {
            #selector(CLLocationManager.startUpdatingLocation) <-> #selector(swizzledStartLocation)
            #selector(CLLocationManager.requestLocation) <-> #selector(swizzedRequestLocation)
        }
    }
    
    private var simulatedLocation: CLLocation? { PTDebugLocationKit.shared.simulatedLocation }

    @objc func swizzledStartLocation() {}
    @objc func swizzedRequestLocation() {
        if let simulatedLocation {
            delegate?.locationManager?(self, didUpdateLocations: [simulatedLocation])
        } else {
            swizzedRequestLocation()
        }
    }
}
