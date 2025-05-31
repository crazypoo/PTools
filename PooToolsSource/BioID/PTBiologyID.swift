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
    case none, touchID, faceID, opticID
}

private let kBiologyService = "PTouchIDService"
private let errSecUserInteractionNotAllowed: OSStatus = -25308

@objcMembers
public class PTBiologyID: NSObject {
    public static let shared = PTBiologyID()

    public var biologyStatusBlock: ((_ status: PTBiologyStatus) -> Void)?
    public var biologyVerifyStatusBlock: ((_ status: PTBiologyVerifyStatus) -> Void)?

    private override init() {
        super.init()
        PTGCDManager.gcdMain { [weak self] in
            self?.verifyBiologyIDAction()
        }
    }

    private func verifyBiologyIDAction() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biologyStatusBlock?(.none)
            return
        }

        switch context.biometryType {
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

    public func biologyStart(alertTitle: String = "生物技術驗證") {
        let context = LAContext()
        context.localizedReason = alertTitle

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: alertTitle) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.biologyVerifyStatusBlock?(.success)
                } else if let nsError = error as NSError? {
                    let status = self.mapLAErrorToStatus(nsError, context: context, reason: alertTitle)
                    self.biologyVerifyStatusBlock?(status)
                } else {
                    self.biologyVerifyStatusBlock?(.unknown)
                }
            }
        }
    }

    /// 儲存帳號密碼（使用生物辨識保護）
    public func saveAccount(_ reason:String = "儲存帳號密碼需要驗證",_ account: String, password: String) -> Bool {
        guard let _ = password.data(using: .utf8) else { return false }

        let context = LAContext()
        context.localizedReason = reason

        let accessControl = SecAccessControlCreateWithFlags(nil,
                                                            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                            .userPresence,
                                                            nil)
        return PTKeyChain.saveAccountInfo(service: kBiologyService.nsString, account: account.nsString, password: password.nsString,context: context,accessControl: accessControl)
    }

    /// 讀取帳號密碼（需要生物辨識驗證）
    public func readPassword(for account: String, reason: String = "需要驗證才能讀取密碼", completion: @escaping (String?) -> Void) {
        let context = LAContext()
        context.localizedReason = reason

        let result = PTKeyChain.getPassword(service: kBiologyService.nsString, account: account.nsString, context: context)
        completion(result)
    }

    /// 刪除帳號密碼
    public func deleteBiologyID(account: String? = nil) {
        PTKeyChain.deleteAccountInfo(service: kBiologyService.nsString, account: (account ?? "").nsString) { success, status in
            self.biologyVerifyStatusBlock?(status)
        }
    }
    
    private func mapLAErrorToStatus(_ error: NSError, context: LAContext, reason: String) -> PTBiologyVerifyStatus {
        switch error.code {
        case LAError.systemCancel.rawValue:
            return .systemCancel
        case LAError.userCancel.rawValue:
            return .alertCancel
        case LAError.authenticationFailed.rawValue:
            return .failed
        case LAError.passcodeNotSet.rawValue:
            return .keyboardIDNotFound
        case LAError.biometryNotAvailable.rawValue:
            return .touchIDNotOpen
        case LAError.biometryNotEnrolled.rawValue:
            return .touchIDNotFound
        case LAError.userFallback.rawValue:
            // 用戶選擇了輸入密碼，執行 fallback
            fallbackToPassword(context: context, reason: reason)
            return .keyboardTouchID // 或自定義 fallback 狀態
        case Int(errSecUserInteractionNotAllowed):
            return .keyboardCancel
        default:
            return .unknown
        }
    }
    
    private func fallbackToPassword(context: LAContext, reason: String) {
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.biologyVerifyStatusBlock?(.success)
                } else {
                    self.biologyVerifyStatusBlock?(.keyboardCancel)
                }
            }
        }
    }
}
