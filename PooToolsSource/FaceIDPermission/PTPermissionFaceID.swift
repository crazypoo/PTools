//
//  PTPermissionFaceID.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import LocalAuthentication
#if POOTOOLS_SPLIT_PERMISSION_CORE
import PToolsPermissionCore
#endif

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

    // English: Keep biometric availability details separate from the legacy permission status.
    // Español: Mantén los detalles de disponibilidad biométrica separados del estado de permiso heredado.
    // 中文：将生物识别可用性详情与旧版权限状态分离。
    public var faceIDState: PTFaceIDPermissionState {
        let context = LAContext()
        var error: NSError?
        let isReady = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        guard context.biometryType == .faceID else { return .unavailable }
        if isReady { return .available }
        switch error?.code {
        case LAError.biometryNotEnrolled.rawValue:
            return .notEnrolled
        case LAError.biometryLockout.rawValue:
            return .lockedOut
        case LAError.passcodeNotSet.rawValue:
            return .passcodeFallback
        default:
            return .unknown
        }
    }

    public override var authorizationState: PTPermissionAuthorizationState {
        switch faceIDState {
        case .available: return .notDetermined
        case .notEnrolled, .lockedOut: return .restricted
        case .passcodeFallback, .unavailable, .unknown: return .unavailable
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        let finish = PTPermission.makeCompletionOnce(completion)
        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: " ") { _, _ in
            finish()
        }
    }

    // English: Offer an opt-in system fallback that allows the device passcode after biometric failure.
    // Español: Ofrece un fallback opcional del sistema que permite el código del dispositivo tras fallar la biometría.
    // 中文：提供可选的系统回退，在生物识别失败后允许使用设备密码。
    public func requestWithPasscodeFallback(completion: @escaping PTActionTask) {
        let finish = PTPermission.makeCompletionOnce(completion)
        LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: " ") { _, _ in
            finish()
        }
    }
}
