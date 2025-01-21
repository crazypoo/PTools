//
//  PTPermissionFaceID.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import LocalAuthentication

public extension PTPermission {
    
    static var faceID: PTPermissionFaceID {
        PTPermissionFaceID()
    }
}

public class PTPermissionFaceID: PTPermission {
    
    open override var kind: PTPermission.Kind { .faceID }
    open var usageDescriptionKey: String? { "NSFaceIDUsageDescription" }
    
    public override var status: PTPermission.Status {
        let context = LAContext()
        
        var error: NSError?
        let isReady = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        guard context.biometryType == .faceID else {
            return .notSupported
        }
        
        switch error?.code {
        case nil where isReady:
            return .notDetermined
        case LAError.biometryNotAvailable.rawValue:
            return .denied
        case LAError.biometryNotEnrolled.rawValue:
            return .notSupported
        default:
            return .notSupported
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: " ") { _, _ in
            PTGCDManager.gcdMain {
                completion()
            }
        }
    }
}
