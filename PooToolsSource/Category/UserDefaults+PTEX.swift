//
//  UserDefaults+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

extension UserDefaults: PTProtocolCompatible {}
// MARK: - 一、基本的扩展
public extension PTProtocol where Base: UserDefaults {
  
    // MARK: 存值
    /// 存值
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    
    @discardableResult
    static func userDefaultsSetValue(value: Any?, key: String?) -> Bool {
        guard value != nil, key != nil else {
            return false
        }
        Base.standard.set(value, forKey: key!)
        Base.standard.synchronize()
        return true
    }
    
    // MARK: 取值
    /// 取值
    /// - Parameter key: 键
    /// - Returns: 返回值
    static func userDefaultsGetValue(key: String?) -> Any? {
        guard key != nil, let result = Base.standard.value(forKey: key!) else {
            return nil
        }
        return result
    }
    
    // MARK: 移除单个值
    /// 移除单个值
    /// - Parameter key: 键名
    static func remove(_ key: String) {
        guard let _ = Base.standard.value(forKey: key) else {
            return
        }
        Base.standard.removeObject(forKey: key)
    }
    
    // MARK: 移除所有值
    /// 移除所有值
    static func removeAllKeyValue() {
        if let bundleID = Bundle.main.bundleIdentifier {
            Base.standard.removePersistentDomain(forName: bundleID)
        }
    }
}

// MARK: - 二、模型持久化
public extension PTProtocol where Base: UserDefaults {
    
    // MARK: 存储模型
    /// 存储模型
    /// - Parameters:
    ///   - object: 模型
    ///   - key: 对应的key
    static func setItem<T: Decodable & Encodable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(object) else {
            return
        }
        Base.standard.set(encoded, forKey: key)
        Base.standard.synchronize()
    }
    
    // MARK: 取出模型
    /// 取出模型
    /// - Parameters:
    ///   - type: 当时存储的类型
    ///   - key: 对应的key
    /// - Returns: 对应类型的模型
    static func getItem<T: Decodable & Encodable>(_ type: T.Type, forKey key: String) -> T? {
        
        guard let data = Base.standard.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let object = try? decoder.decode(type, from: data) else {
            PTNSLog("Couldnt find key")
            return nil
        }
        return object
    }
}
