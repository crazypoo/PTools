//
//  PTBiologyID.swift
//  Diou
//
//  Created by ken lam on 2021/10/21.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import LocalAuthentication
import Security

@objc public enum PTBiologyStatus: Int {
    case none
    case touchID
    case faceID
    case opticID
}

@objc public enum PTBiologyVerifyStatus: Int {
    case success
    case duplicateItem
    case itemNotFound
    case keyboardIDNotFound
    case touchIDNotFound
    case alertCancel
    case passwordKilled
    case unknown
    case keyboardCancel
    case keyboardTouchID
    case touchIDNotOpen
    case failed
    case systemCancel
}

@objcMembers
public class PTBiologyID: NSObject {
    public static let shared = PTBiologyID()
    
    open var biologyStatusBlock: ((_ status: PTBiologyStatus) -> Void)?
    open var biologyVerifyStatusBlock: ((_ status: PTBiologyVerifyStatus) -> Void)?
    
    private override init() {
        super.init()
        PTGCDManager.gcdMain { [weak self] in
            self?.verifyBiologyIDAction()
        }
    }
    
    private func verifyBiologyIDAction() {
        let security = LAContext()  // 每次创建一个新的 LAContext 实例
        var error: NSError?
        guard security.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biologyStatusBlock?(.none)
            return
        }
        
        switch security.biometryType {
        case .none:
            biologyStatusBlock?(.none)
        case .faceID:
            biologyStatusBlock?(.faceID)
        case .touchID:
            biologyStatusBlock?(.touchID)
        case .opticID:
            biologyStatusBlock?(.opticID)
        @unknown default:
            biologyStatusBlock?(.none)
        }
    }
    
    public func biologyStart(alertTitle: String = "生物技术验证") {
        let security = LAContext()  // 每次创建一个新的 LAContext 实例
        security.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: alertTitle) { success, error in
            if success {
                self.biologyVerifyStatusBlock?(.success)
            } else {
                let status: PTBiologyVerifyStatus
                if let newError = error as NSError? {
                    switch newError.code {
                    case LAError.systemCancel.rawValue:
                        status = .systemCancel
                    case LAError.userCancel.rawValue:
                        status = .alertCancel
                    case LAError.authenticationFailed.rawValue:
                        status = .failed
                    case LAError.passcodeNotSet.rawValue:
                        status = .keyboardIDNotFound
                    case LAError.biometryNotAvailable.rawValue:
                        status = .touchIDNotOpen
                    case LAError.biometryNotEnrolled.rawValue:
                        status = .touchIDNotFound
                    case LAError.userFallback.rawValue:
                        status = .keyboardTouchID
                    default:
                        status = .unknown
                    }
                } else {
                    status = .unknown
                }
                self.biologyVerifyStatusBlock?(status)
            }
        }
    }
    
    func deleteBiologyID() {
        let query = [kSecClass: kSecClassGenericPassword, kSecAttrService: "PTouchIDService"] as [CFString: Any]
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        let verifyStatus: PTBiologyVerifyStatus
        switch status {
        case errSecSuccess:
            verifyStatus = .passwordKilled
        case errSecDuplicateItem:
            verifyStatus = .duplicateItem
        case errSecItemNotFound:
            verifyStatus = .itemNotFound
        default:
            verifyStatus = .unknown
        }
        
        biologyVerifyStatusBlock?(verifyStatus)
    }
}
