// The MIT License (MIT)
// Copyright © 2022 Sparrow Code LTD (https://sparrowcode.io, hello@sparrowcode.io)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#if PERMISSIONSKIT_SPM
import PermissionsKit
import LocationExtension
#endif

#if PERMISSIONSKIT_LOCATION_WHENINUSE
import Foundation
import MapKit

class LocationWhenInUseHandler: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Location Manager
    
    lazy var locationManager = CLLocationManager()
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined {
            return
        }
        completionHandler()
    }
    
    // MARK: - Process
    
    var completionHandler: () -> Void = {}
    
    func requestPermission(_ completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
        
        let status = CLLocationManager.authorizationStatus()
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
    
    static var shared: LocationWhenInUseHandler?
    
    override init() {
        super.init()
    }
    
    deinit {
        locationManager.delegate = nil
    }
}
#endif
