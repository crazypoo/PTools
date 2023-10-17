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

public let kAccount = "kAccount"
public let kPassword = "kPassword"

public typealias PTKeyChainBlock = (_ success:Bool) -> Void

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
                               handle:PTKeyChainBlock?) {
        let accountData = account.data(using: String.Encoding.utf8.rawValue)!
        let passwordData = password.data(using: String.Encoding.utf8.rawValue)!
        
        let queryDic:[String:Any] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrAccount as String : accountData,
            kSecValueData as String : passwordData,
            kSecAttrService as String : service
        ]
        let status = SecItemAdd(queryDic as CFDictionary, nil)
        if status == errSecSuccess {
            if handle != nil {
                handle!(true)
            }
        } else {
            if handle != nil {
                handle!(false)
            }
        }
    }
    
    //MARK: 根據帳號查詢密碼
    ///根據帳號查詢密碼
    /// - Parameters:
    ///   - service: 保存到哪個域
    ///   - account: 帳號
    /// - Returns: 字符串
    class func getPassword(service:NSString,
                           account:NSString)->NSString {
        let accountData = account.data(using: String.Encoding.utf8.rawValue)!
        let queryDic:[String:Any] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrAccount as String : accountData,
            kSecReturnData as String : kCFBooleanTrue!,
            kSecMatchLimit as String : kSecMatchLimitOne,
            kSecAttrService as String : service
        ]
        var result : AnyObject?
        let _ = SecItemCopyMatching(queryDic as CFDictionary, &result)
        let retrievedPassword = String(data: result as! Data, encoding: String.Encoding.utf8)!.nsString
        return retrievedPassword
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
                                 handle:PTKeyChainBlock?) {
        let newAccount = String(format: "%@", account ?? "")
        var query = [String:Any]()
        if !newAccount.stringIsEmpty() {
            query = [
                kSecClass as String : kSecClassGenericPassword,
                kSecAttrAccount as String : account!.data(using: String.Encoding.utf8.rawValue)!,
                kSecAttrService as String : service
            ]
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecSuccess {
                if handle != nil {
                    handle!(true)
                }
            } else {
                if handle != nil {
                    handle!(false)
                }
            }
        } else {
            query = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecMatchLimit as String: kSecMatchLimitAll,
                kSecReturnAttributes as String : kCFBooleanTrue!
            ]
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status == errSecSuccess {
                let accounts = result as! [[String: Any]]
                for account in accounts {
                    let query: [String: Any] = [
                            kSecClass as String: kSecClassGenericPassword,
                            kSecAttrAccount as String: account[kSecAttrAccount as String] as! Data,
                            kSecAttrService as String: service
                        ]

                    let _ = SecItemDelete(query as CFDictionary)
                }
                if PTKeyChain.getAccountInfo(service: service).count == 0 {
                    if handle != nil {
                        handle!(true)
                    }
                } else {
                    if handle != nil {
                        handle!(false)
                    }
                }
            }
        }
    }
}
