//
//  PTPermissionSiri.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import Intents

public extension PTPermission {

    static var siri: PTPermissionSiri {
        return PTPermissionSiri()
    }
}

public class PTPermissionSiri: PTPermission {
    
    open override var kind: PTPermission.Kind { .siri }
    open var usageDescriptionKey: String? { "NSSiriUsageDescription" }
    
    public override var status: PTPermission.Status {
        switch INPreferences.siriAuthorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping () -> Void) {
        INPreferences.requestSiriAuthorization { _ in
            PTGCDManager.gcdMain {
                completion()
            }
        }
    }
}
