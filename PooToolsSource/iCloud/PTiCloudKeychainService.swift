//
//  PTiCloudKeychainService.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/9/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Security
import Foundation
import AuthenticationServices

public class PTiCloudKeychainService {
    public static func save(service: String, account: String, password: String) {
        let data = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: kCFBooleanTrue! // ✅ 啟用 iCloud Keychain 同步
        ]
        
        // 先刪除舊的數據，防止重複存儲
        SecItemDelete(query as CFDictionary)
        
        // 存儲到 iCloud Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        assert(status == errSecSuccess, "Failed to save password to iCloud Keychain")
    }
    
    public static func get(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kCFBooleanTrue! // ✅ 啟用同步
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                return String(data: retrievedData, encoding: .utf8)
            }
        }
        return nil
    }
    
    public static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kCFBooleanTrue! // ✅ 確保刪除 iCloud Keychain 數據
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        assert(status == errSecSuccess || status == errSecItemNotFound, "Failed to delete password")
    }
    
    public static func saveCredential(username: String, password: String, serviceIdentifier: String) {
        let credentialIdentity = ASPasswordCredentialIdentity(
            serviceIdentifier: ASCredentialServiceIdentifier(identifier: serviceIdentifier, type: .domain),
            user: username,
            recordIdentifier: nil
        )

        let store = ASCredentialIdentityStore.shared

        store.getState { state in
            guard state.isEnabled else {
                PTNSLogConsole("AutoFill Credential Provider is not enabled.")
                return
            }

            store.saveCredentialIdentities([credentialIdentity]) { success, error in
                if success {
                    PTNSLogConsole("Credential saved successfully!")
                } else {
                    PTNSLogConsole("Error saving credential: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
//    class LoginViewController: UIViewController, ASCredentialProviderViewControllerDelegate {
//        func fetchCredentials() {
//            let credentialProvider = ASCredentialIdentityStore.shared
//            credentialProvider.getCredentialIdentityMatches(for: ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "yourdomain.com", type: .domain), user: "", recordIdentifier: nil)) { credentials, error in
//                guard let credential = credentials.first else {
//                    print("No credentials found.")
//                    return
//                }
//
//                DispatchQueue.main.async {
//                    print("AutoFill selected: \(credential.user)")
//                }
//            }
//        }
//    }
}
