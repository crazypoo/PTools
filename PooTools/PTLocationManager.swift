//
//  PTLocationManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import CoreLocation

class PTLocationManager: NSObject,CLLocationManagerDelegate {
    static var shared = PTLocationManager()
    private var locationManager = CLLocationManager()

    var didUpdate: ((String) -> Void)?

    func requestLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                if error != nil {
                    PTNSLogConsole("Error: " + error!.localizedDescription)
                    return
                }

                if let placemark = placemarks?.first {
                    self.displayLocationInfo(placemark)
                } else {
                    PTNSLogConsole("Error with the data. Missing placemark for location info.")
                }
            }
        }
    }

    func displayLocationInfo(_ placemark: CLPlacemark) {
        locationManager.stopUpdatingLocation()

        let value = """
        \(placemark.locality ?? "")
        \(placemark.postalCode ?? "")
        \(placemark.administrativeArea ?? "")
        \(placemark.country ?? "")
        """
        PTNSLogConsole(value)

        didUpdate?(value)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PTNSLogConsole("8️⃣Error: " + error.localizedDescription)
    }

}
