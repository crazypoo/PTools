//
//  PTPermissionLocation.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import EventKit

public extension PTPermission {
    
    static func location(access: LocationAccess) -> PTPermissionLocation {
        PTPermissionLocation(kind: .location(access: access))
    }
}

public class PTPermissionLocation: PTPermission {
    
    private var _kind: PTPermission.Kind
    
    // MARK: - Init
    
    init(kind: PTPermission.Kind) {
        _kind = kind
    }
    
    open override var kind: PTPermission.Kind { _kind }
    open var usageDescriptionKey: String? {
        switch _kind {
        case .location(let access):
            switch access {
            case .whenInUse:
                return "NSLocationWhenInUseUsageDescription"
            case .always:
                return "NSLocationAlwaysAndWhenInUseUsageDescription"
            }
        default:
            fatalError()
        }
    }
    
    public override var status: PTPermission.Status {
        let result: CLAuthorizationStatus
        let locationManager = CLLocationManager()
        result = locationManager.authorizationStatus
        let authorizationStatus: CLAuthorizationStatus = result

        switch authorizationStatus {
            #if os(iOS)
        case .authorized: return .authorized
            #endif
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .authorizedAlways:
            if case .location(let access) = _kind, access == .always {
                return .authorized
            }
            return .denied
        case .authorizedWhenInUse:
            if case .location(let access) = _kind, access == .whenInUse {
                return .authorized
            }
            return .denied
        @unknown default: return .denied
        }
    }
    
    public var isPrecise: Bool {
        #if os(iOS)
        switch CLLocationManager().accuracyAuthorization {
        case .fullAccuracy: return true
        case .reducedAccuracy: return false
        @unknown default: return false
        }
        #else
        return false
        #endif
    }
    
    public override func request(completion: @escaping PTActionTask) {
        switch _kind {
        case .location(let access):
            switch access {
            case .whenInUse:
                PTPermissionLocationWhenInUseHandler.shared = PTPermissionLocationWhenInUseHandler()
                PTGCDManager.gcdMain {
                    PTPermissionLocationWhenInUseHandler.shared?.requestPermission {
                        PTGCDManager.gcdMain {
                            completion()
                            PTPermissionLocationWhenInUseHandler.shared = nil
                        }
                    }
                }
            case .always:
                PTPermissionLocationAlwaysHandler.shared = PTPermissionLocationAlwaysHandler()
                PTGCDManager.gcdMain {
                    PTPermissionLocationAlwaysHandler.shared?.requestPermission {
                        PTGCDManager.gcdMain {
                            completion()
                            PTPermissionLocationAlwaysHandler.shared = nil
                        }
                    }
                }
            }
        default:
            fatalError()
        }
    }
}
