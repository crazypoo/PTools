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

@objc public enum PTBiologyStatus:Int {
    case None
    case TouchID
    case FaceID
}

@objc public enum PTBiologyVerifyStatus:Int {
    case Success
    case DuplicateItem
    case ItemNotFound
    case KeyboardIDNotFound
    case TouchIDNotFound
    case AlertCancel
    case PasswordKilled
    case UnKnow
    case KeyboardCancel
    case KeyboardTouchID
    case TouchIDNotOpen
    case Failed
    case SystemCancel
}

@objcMembers
public class PTBiologyID: NSObject {
    public static let shared = PTBiologyID()

    private var security = LAContext()
        
    public var biologyStatusBlock:((_ status:PTBiologyStatus)->Void)?
    public var biologyVerifyStatusBlock:((_ status:PTBiologyVerifyStatus)->Void)?

    private override init()
    {
        super.init()
        PTUtils.gcdMain {
            self.verifyBiologyIDAction()
        }
    }
    
    private func verifyBiologyIDAction()
    {
        if #available(iOS 8.0,*)
        {
            var error : NSError? = nil
            let isCanEvaluatePolicy : Bool = self.security.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            if error != nil
            {
                if biologyStatusBlock != nil
                {
                    biologyStatusBlock!(.None)
                }
            }
            else
            {
                if isCanEvaluatePolicy
                {
                    if #available(iOS 11.0, *)
                    {
                        switch security.biometryType {
                        case .none:
                            if biologyStatusBlock != nil
                            {
                                biologyStatusBlock!(.None)
                            }
                        case .faceID:
                            if biologyStatusBlock != nil
                            {
                                biologyStatusBlock!(.FaceID)
                            }
                        case .touchID:
                            if biologyStatusBlock != nil
                            {
                                biologyStatusBlock!(.TouchID)
                            }
                        default:
                            if biologyStatusBlock != nil
                            {
                                biologyStatusBlock!(.None)
                            }
                        }
                    }
                    else
                    {
                        if biologyStatusBlock != nil
                        {
                            biologyStatusBlock!(.TouchID)
                        }
                    }
                }
                else
                {
                    if biologyStatusBlock != nil
                    {
                        biologyStatusBlock!(.None)
                    }
                }
            }
        }
        else
        {
            if biologyStatusBlock != nil
            {
                biologyStatusBlock!(.None)
            }
        }
    }
    
    public func biologyStart(alertTitle:String? = "生物技术验证")
    {        
        var evaluatePolicyType : LAPolicy?
        if #available(iOS 9.0, *)
        {
            evaluatePolicyType = .deviceOwnerAuthentication
        }
        else
        {
            evaluatePolicyType = .deviceOwnerAuthenticationWithBiometrics
        }
        
        security.evaluatePolicy(evaluatePolicyType!, localizedReason: alertTitle!) { success, error in
            if success
            {
                if self.biologyVerifyStatusBlock != nil
                {
                    self.biologyVerifyStatusBlock!(.Success)
                }
            }
            else
            {
                if let newError = error as NSError?
                {
                    var type : PTBiologyVerifyStatus = .UnKnow
                    switch newError.code {
                    case LAError.systemCancel.rawValue:
                        type = .SystemCancel
                    case LAError.userCancel.rawValue:
                        type = .AlertCancel
                    case LAError.authenticationFailed.rawValue:
                        type = .Failed
                    case LAError.passcodeNotSet.rawValue:
                        type = .KeyboardIDNotFound
                    case LAError.biometryNotAvailable.rawValue:
                        type = .TouchIDNotOpen
                    case LAError.biometryNotEnrolled.rawValue:
                        type = .TouchIDNotFound
                    case LAError.userFallback.rawValue:
                        type = .KeyboardTouchID
                    default:
                        type = .UnKnow
                    }
                    if self.biologyVerifyStatusBlock != nil
                    {
                        self.biologyVerifyStatusBlock!(type)
                    }
                }
            }
        }
    }
    
    func deleteBiologyID()
    {
        let query = [kSecClass:kSecClassGenericPassword,kSecAttrService:"PTouchIDService"] as [CFString : Any]
        let status : OSStatus = SecItemDelete(query as CFDictionary)
        var type : PTBiologyVerifyStatus = .UnKnow
        switch status {
        case 0:
            type = .PasswordKilled
        case -25299:
            type = .DuplicateItem
        case -25300:
            type = .ItemNotFound
        case -26276:
            type = .AlertCancel
        default:break
        }
        if self.biologyVerifyStatusBlock != nil
        {
            self.biologyVerifyStatusBlock!(type)
        }
    }
}
