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

/// 自定义 Keychain 错误类型，方便外部捕获和处理
public enum PTKeychainError: Error {
    case invalidData                // 字符串转 Data 失败
    case itemNotFound               // 找不到对应的数据
    case unhandledError(OSStatus)   // 其他系统级 Keychain 错误
}

public class PTiCloudKeychainService {
    
    // MARK: - 基础辅助方法
    
    /// 构建基础的查询字典，减少重复代码
    private static func baseQuery(service: String, account: String? = nil) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrSynchronizable as String: kCFBooleanTrue! // ✅ 启用 iCloud Keychain 同步
        ]
        if let account = account {
            query[kSecAttrAccount as String] = account
        }
        return query
    }
    
    // MARK: - 核心功能 (存、取、删)
    
    /// 保存或更新密码
    /// - Parameters:
    ///   - service: 服务标识（如 Bundle ID）
    ///   - account: 账号名
    ///   - password: 密码
    public static func save(service: String, account: String, password: String) throws {
        guard let data = password.data(using: .utf8) else {
            throw PTKeychainError.invalidData
        }
        
        var query = baseQuery(service: service, account: account)
        
        // 1. 检查是否存在
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // 2. 如果存在，则更新数据
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus != errSecSuccess {
                throw PTKeychainError.unhandledError(updateStatus)
            }
        } else if status == errSecItemNotFound {
            // 3. 如果不存在，则新增数据
            query[kSecValueData as String] = data
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw PTKeychainError.unhandledError(addStatus)
            }
        } else {
            // 其他错误
            throw PTKeychainError.unhandledError(status)
        }
    }
    
    /// 获取密码
    public static func get(service: String, account: String) throws -> String {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData as String] = kCFBooleanTrue!
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw PTKeychainError.itemNotFound
            }
            throw PTKeychainError.unhandledError(status)
        }
        
        guard let retrievedData = dataTypeRef as? Data,
              let password = String(data: retrievedData, encoding: .utf8) else {
            throw PTKeychainError.invalidData
        }
        
        return password
    }
    
    /// 删除单个账号的密码
    public static func delete(service: String, account: String) throws {
        let query = baseQuery(service: service, account: account)
        let status = SecItemDelete(query as CFDictionary)
        
        // 如果删除成功或者本来就不存在，都算成功。否则抛出异常。
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PTKeychainError.unhandledError(status)
        }
    }
    
    // MARK: - 扩展功能
    
    /// 检查是否存在某个账号的密码
    public static func exists(service: String, account: String) -> Bool {
        var query = baseQuery(service: service, account: account)
        // 只需要知道是否存在，不需要返回数据，提高性能
        query[kSecReturnData as String] = kCFBooleanFalse!
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 删除该服务下的所有密码（适用于用户注销登录，清空所有历史记录）
    public static func deleteAll(service: String) throws {
        let query = baseQuery(service: service) // 不传入 account，匹配该 service 下所有数据
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PTKeychainError.unhandledError(status)
        }
    }
    
    // MARK: - 自动填充凭据 (AutoFill)
    
    /// 保存凭据以供 iOS 键盘自动填充使用
    public static func saveCredential(username: String, serviceIdentifier: String) {
        // 注意：ASPasswordCredentialIdentity 只需要提供账号名和域名，不需要明文密码。
        // 密码本身存储在 Keychain 中（上面我们封装的方法）。
        let credentialIdentity = ASPasswordCredentialIdentity(
            serviceIdentifier: ASCredentialServiceIdentifier(identifier: serviceIdentifier, type: .domain),
            user: username,
            recordIdentifier: nil
        )

        let store = ASCredentialIdentityStore.shared

        store.getState { state in
            guard state.isEnabled else {
                // TODO: 替换为你的 PTNSLogConsole
                PTNSLogConsole("AutoFill Credential Provider is not enabled.")
                return
            }

            store.saveCredentialIdentities([credentialIdentity]) { success, error in
                if success {
                    PTNSLogConsole("Credential saved successfully to Identity Store!")
                } else {
                    PTNSLogConsole("Error saving credential: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}
