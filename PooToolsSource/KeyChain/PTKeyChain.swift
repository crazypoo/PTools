//
//  PTKeyChain.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 16/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Security
import LocalAuthentication

public let kAccount = "kAccount"
public let kPassword = "kPassword"

@objc public enum PTBiologyVerifyStatus: Int {
    case success, duplicateItem, itemNotFound, keyboardIDNotFound
    case touchIDNotFound, alertCancel, passwordKilled, unknown
    case keyboardCancel, keyboardTouchID, touchIDNotOpen, failed, systemCancel
}

public typealias PTKeyChainBlock = (_ success: Bool) -> Void
public typealias PTKeyChainStatusBlock = (_ success: Bool, _ status: PTBiologyVerifyStatus) -> Void

@objcMembers
public class PTKeyChain: NSObject {
    
    // MARK: 1. 保存/更新帐号密碼到Keychain中
    /// - Parameters:
    ///   - service: 保存到哪個域
    ///   - account: 帳號
    ///   - password: 密碼
    class func saveAccountInfo(service: NSString,
                               account: NSString,
                               password: NSString,
                               context: LAContext? = nil,
                               accessControl: SecAccessControl? = nil) -> Bool {
        
        // 安全解包字符串转 Data
        guard let accountData = (account as String).data(using: .utf8),
              let passwordData = (password as String).data(using: .utf8) else {
            return false
        }
        
        var queryDic: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: accountData,
            kSecAttrService: service
        ]
        
        if let context = context, let accessControl = accessControl {
            queryDic[kSecUseAuthenticationContext] = context
            queryDic[kSecAttrAccessControl] = accessControl
        }
        
        // 查询是否存在，如果存在则 Update，不存在则 Add
        let status = SecItemCopyMatching(queryDic as CFDictionary, nil)
        
        if status == errSecSuccess {
            // 已存在，执行更新操作
            let attributesToUpdate: [CFString: Any] = [
                kSecValueData: passwordData
            ]
            let updateStatus = SecItemUpdate(queryDic as CFDictionary, attributesToUpdate as CFDictionary)
            return updateStatus == errSecSuccess
        } else {
            // 不存在，执行添加操作
            queryDic[kSecValueData] = passwordData
            let addStatus = SecItemAdd(queryDic as CFDictionary, nil)
            return addStatus == errSecSuccess
        }
    }
    
    class func saveAccountInfoCallback(service: NSString,
                                       account: NSString,
                                       password: NSString,
                                       handle: PTKeyChainBlock?) {
        let status = PTKeyChain.saveAccountInfo(service: service, account: account, password: password)
        handle?(status)
    }
    
    // MARK: 2. 根據帳號查詢密碼
    class func getPassword(service: NSString,
                           account: NSString,
                           context: LAContext? = nil) -> String? {
        
        guard let accountData = (account as String).data(using: .utf8) else { return nil }
        
        var queryDic: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: accountData,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecAttrService: service
        ]
        
        if let context = context {
            queryDic[kSecUseAuthenticationContext] = context
        }
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(queryDic as CFDictionary, &item)
        
        if status == errSecSuccess,
           let data = item as? Data,
           let password = String(data: data, encoding: .utf8) {
            return password
        }
        return nil
    }
    
    // MARK: 3. 獲取儲存域的多個帳號密碼
    /// 返回原生的 [ [String: String] ] 更加 Swift 友好，如果业务强依赖 NSMutableDictionary 可自行桥接转换。
    class func getAccountInfo(service: NSString) -> [[String: String]] {
        let queryDic: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecReturnAttributes: kCFBooleanTrue!,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecAttrService: service
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(queryDic as CFDictionary, &result)
        
        var accountArr = [[String: String]]()
        
        if status == errSecSuccess, let accounts = result as? [[String: Any]] {
            for accountInfo in accounts {
                // 修复：每次循环创建一个新的字典，并安全解包数据
                if let accountData = accountInfo[kSecAttrAccount as String] as? Data,
                   let passwordData = accountInfo[kSecValueData as String] as? Data,
                   let findAccount = String(data: accountData, encoding: .utf8),
                   let findPassword = String(data: passwordData, encoding: .utf8) {
                    
                    let dic: [String: String] = [
                        kAccount: findAccount,
                        kPassword: findPassword
                    ]
                    accountArr.append(dic)
                }
            }
        }
        return accountArr
    }
    
    // MARK: 4. 刪除域的帳號密碼 (性能优化)
    class func deleteAccountInfo(service: NSString,
                                 account: NSString?,
                                 handle: PTKeyChainStatusBlock?) {
        
        var queryDic: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service
        ]
        
        let accountString = account as String? ?? ""
        
        // 如果有指定账号，则追加账号条件；如果没有，则直接批量删除该 Service 下所有内容
        if !accountString.isEmpty, let accountData = accountString.data(using: .utf8) {
            queryDic[kSecAttrAccount] = accountData
        }
        
        let status = SecItemDelete(queryDic as CFDictionary)
        
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
        
        // 如果删除成功，或者要删除的本来就不存在，在业务上往往也视为成功
        let isSuccess = (status == errSecSuccess)
        handle?(isSuccess, verifyStatus)
    }
}
