//
//  PTKeyChain.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 16/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Security
import SwifterSwift
import LocalAuthentication

public let kAccount = "kAccount"
public let kPassword = "kPassword"

@objc public enum PTBiologyVerifyStatus: Int {
    case success, duplicateItem, itemNotFound, keyboardIDNotFound
    case touchIDNotFound, alertCancel, passwordKilled, unknown
    case keyboardCancel, keyboardTouchID, touchIDNotOpen, failed, systemCancel
}

public typealias PTKeyChainBlock = (_ success:Bool) -> Void
public typealias PTKeyChainStatusBlock = (_ success:Bool,_ status : PTBiologyVerifyStatus) -> Void

@objcMembers
public class PTKeyChain: NSObject {
    
    //MARK: 保存帳號密碼到Keychain中
    ///保存帳號密碼到Keychain中
    /// - Parameters:
    ///   - service: 保存到哪個域
    ///   - account: 帳號
    ///   - password: 密碼
    ///   - handle: 回調是否成功
    class func saveAccountInfo(service:NSString,
                               account:NSString,
                               password:NSString,
                               context:LAContext? = nil,
                               accessControl:SecAccessControl? = nil) -> Bool {
        let accountData = account.data(using: String.Encoding.utf8.rawValue)!
        let passwordData = password.data(using: String.Encoding.utf8.rawValue)!
        
        
        var queryDic:[CFString:Any] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrAccount : accountData,
            kSecValueData : passwordData,
            kSecAttrService : service
        ]
        if let content = context,let accessControl = accessControl {
            queryDic[kSecUseAuthenticationContext] = content
            queryDic[kSecAttrAccessControl] = accessControl
        }
        
        // 先刪除已存在的（避免 duplicate）
        SecItemDelete(queryDic as CFDictionary)

        let status = SecItemAdd(queryDic as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    class func saveAccountInfoCallback(service:NSString,
                                       account:NSString,
                                       password:NSString,
                                       handle:PTKeyChainBlock?) {
        let status = PTKeyChain.saveAccountInfo(service: service, account: account, password: password)
        handle?(status)
    }
    
    //MARK: 根據帳號查詢密碼
    ///根據帳號查詢密碼
    /// - Parameters:
    ///   - service: 保存到哪個域
    ///   - account: 帳號
    /// - Returns: 字符串
    class func getPassword(service:NSString,
                           account:NSString,
                           context:LAContext? = nil) -> String? {
        let accountData = account.data(using: String.Encoding.utf8.rawValue)!
        var queryDic:[CFString:Any] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrAccount : accountData,
            kSecReturnData : kCFBooleanTrue!,
            kSecMatchLimit : kSecMatchLimitOne,
            kSecAttrService : service
        ]
        
        if let context = context {
            queryDic[kSecUseAuthenticationContext] = context
        }
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(queryDic as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data, let password = String(data: data, encoding: .utf8) {
            return password
        } else {
            return nil
        }
    }
    
    //MARK: 獲取儲存域的多個帳號密碼
    ///獲取儲存域的多個帳號密碼
    /// - Parameters:
    ///   - service: 保存到哪個域
    /// - Returns: 數組類型的帳號密碼字典
    class func getAccountInfo(service:NSString)->[NSMutableDictionary] {
        let queryDic:[String:Any] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecReturnAttributes as String : kCFBooleanTrue!,
            kSecReturnData as String : kCFBooleanTrue!,
            kSecMatchLimit as String : kSecMatchLimitAll,
            kSecAttrService as String : service
        ]
        var result : AnyObject?
        let status = SecItemCopyMatching(queryDic as CFDictionary, &result)
        if status == errSecSuccess {
            var accountArr = [NSMutableDictionary]()
            let dic = NSMutableDictionary()
            let accounts = result as! [[String:Any]]
            for account in accounts {
                let findAccount = String(data: account[kSecAttrAccount as String] as! Data, encoding: String.Encoding.utf8)!.nsString
                let findPassword = String(data: account[kSecValueData as String] as! Data, encoding: String.Encoding.utf8)!.nsString
                dic.setValue(findAccount, forKey: kAccount)
                dic.setValue(findPassword, forKey: kPassword)
                accountArr.append(dic)
            }
            return accountArr
        }
        return [NSMutableDictionary]()
    }
    
    //MARK: 刪除域的帳號密碼
    ///刪除域的帳號密碼
    /// - Parameters:
    ///   - service: 保存到哪個域
    ///   - account: 帳號
    ///   - handle: 回調是否成功
    class func deleteAccountInfo(service:NSString,
                                 account:NSString?,
                                 handle:PTKeyChainStatusBlock?) {
        let newAccount = String(format: "%@", account ?? "")
        var query = [CFString:Any]()
        if !newAccount.stringIsEmpty() {
            query = [
                kSecClass : kSecClassGenericPassword,
                kSecAttrAccount : account!.data(using: String.Encoding.utf8.rawValue)!,
                kSecAttrService : service
            ]
            let status = SecItemDelete(query as CFDictionary)
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
            handle?(status == errSecSuccess,verifyStatus)
        } else {
            query = [
                kSecClass : kSecClassGenericPassword,
                kSecAttrService : service,
                kSecMatchLimit : kSecMatchLimitAll,
                kSecReturnAttributes : kCFBooleanTrue!
            ]
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status == errSecSuccess {
                let accounts = result as! [[CFString: Any]]
                for account in accounts {
                    let query: [CFString: Any] = [
                            kSecClass : kSecClassGenericPassword,
                            kSecAttrAccount : account[kSecAttrAccount] as! Data,
                            kSecAttrService : service
                        ]

                    let _ = SecItemDelete(query as CFDictionary)
                }
                if PTKeyChain.getAccountInfo(service: service).count == 0 {
                    handle?(true,.passwordKilled)
                } else {
                    handle?(false,.unknown)
                }
            } else {
                handle?(false,.failed)
            }
        }
    }
}
