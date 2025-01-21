//
//  PTPermissionTracking.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import AppTrackingTransparency

@available(iOS 14, tvOS 14, *)
public extension PTPermission {

    static var tracking: PTPermissionTracking {
        PTPermissionTracking()
    }
}

@available(iOS 14, tvOS 14, *)
public class PTPermissionTracking: PTPermission {
    
    open override var kind: PTPermission.Kind { .tracking }
    open var usageDescriptionKey: String? { "NSUserTrackingUsageDescription" }
    
    public override var status: PTPermission.Status {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted : return .denied
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        ATTrackingManager.requestTrackingAuthorization { _ in
            PTGCDManager.gcdMain {
                completion()
            }
        }
    }
}
