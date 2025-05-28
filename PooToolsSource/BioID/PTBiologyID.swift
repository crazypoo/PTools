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

@objc public enum PTBiologyVerifyStatus: Int {
    case success, duplicateItem, itemNotFound, keyboardIDNotFound
    case touchIDNotFound, alertCancel, passwordKilled, unknown
    case keyboardCancel, keyboardTouchID, touchIDNotOpen, failed, systemCancel
}

private let kBiologyService = "PTouchIDService"
private let errSecUserInteractionNotAllowed: OSStatus = -25308

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
        context.interactionNotAllowed = false

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: alertTitle) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.biologyVerifyStatusBlock?(.success)
                } else {
                    let status: PTBiologyVerifyStatus
                    if let err = error as NSError? {
                        switch err.code {
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
                        case Int(errSecUserInteractionNotAllowed):
                            status = .keyboardCancel
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
    }

    /// 儲存帳號密碼（使用生物辨識保護）
    public func saveAccount(_ reason:String = "儲存帳號密碼需要驗證",_ account: String, password: String) -> Bool {
        guard let passwordData = password.data(using: .utf8) else { return false }

        let context = LAContext()
        context.localizedReason = reason

        let accessControl = SecAccessControlCreateWithFlags(nil,
                                                            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                            .userPresence,
                                                            nil)

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: kBiologyService,
            kSecAttrAccount: account,
            kSecUseAuthenticationContext: context,
            kSecAttrAccessControl: accessControl as Any,
            kSecValueData: passwordData
        ]

        // 先刪除已存在的（避免 duplicate）
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// 讀取帳號密碼（需要生物辨識驗證）
    public func readPassword(for account: String, reason: String = "需要驗證才能讀取密碼", completion: @escaping (String?) -> Void) {
        let context = LAContext()
        context.localizedReason = reason
        context.interactionNotAllowed = false

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: kBiologyService,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecUseAuthenticationContext: context
        ]

        DispatchQueue.global().async {
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)

            DispatchQueue.main.async {
                if status == errSecSuccess, let data = item as? Data, let password = String(data: data, encoding: .utf8) {
                    completion(password)
                } else {
                    completion(nil)
                }
            }
        }
    }

    /// 刪除帳號密碼
    public func deleteBiologyID(account: String? = nil) {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: kBiologyService
        ]

        if let account = account {
            query[kSecAttrAccount] = account
        }

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
