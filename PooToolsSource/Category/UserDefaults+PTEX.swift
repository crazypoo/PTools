//
//  UserDefaults+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

extension UserDefaults: PTProtocolCompatible {}

public extension UserDefaults {
    var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        get {
            UIUserInterfaceStyle(rawValue: integer(forKey: #function)) ?? .unspecified
        }
        set {
            set(newValue.rawValue, forKey: #function)
        }
    }
}

public extension PTPOP where Base: UserDefaults {

    // English: Legacy dynamic UserDefaults access remains source-compatible but new code should use PTStorage or PTCoreUserDefaultsWrapper.
    // Español: El acceso dinámico heredado a UserDefaults conserva compatibilidad, pero el código nuevo debe usar PTStorage o PTCoreUserDefaultsWrapper.
    // 中文：保留旧的动态 UserDefaults 访问以兼容现有代码，新代码应使用 PTStorage 或 PTCoreUserDefaultsWrapper。
  
    //MARK: 存值
    ///存值
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    @available(*, deprecated, message: "Use PTStorage or PTCoreUserDefaultsWrapper for typed persistence.")
    @discardableResult
    static func userDefaultsSetValue(value: Any?,
                                     key: String?) -> Bool {
        guard let value, let key, !key.isEmpty else {
            return false
        }
        Base.standard.set(value, forKey: key)
        return true
    }
    
    //MARK: 取值
    ///取值
    /// - Parameters:
    ///  - key: 键
    /// - Returns: 返回值
    @available(*, deprecated, message: "Use PTStorage or PTCoreUserDefaultsWrapper for typed persistence.")
    static func userDefaultsGetValue(key: String?) -> Any? {
        guard let key, !key.isEmpty else {
            return nil
        }
        return Base.standard.object(forKey: key)
    }
    
    //MARK: 移除单个值
    ///移除单个值
    /// - Parameter key: 键名
    static func remove(_ key: String) {
        guard let _ = Base.standard.value(forKey: key) else {
            return
        }
        Base.standard.removeObject(forKey: key)
    }
    
    //MARK: 移除所有值
    ///移除所有值
    @available(*, deprecated, message: "Use a scoped PTStorage migration instead of removing the entire domain.")
    static func removeAllKeyValue() {
        if let bundleID = Bundle.main.bundleIdentifier {
            Base.standard.removePersistentDomain(forName: bundleID)
        }
    }
}

// MARK: 模型持久化
public extension PTPOP where Base: UserDefaults {
    
    //MARK: 存储模型
    ///存储模型
    /// - Parameters:
    ///   - object: 模型
    ///   - key: 对应的key
    @available(*, deprecated, message: "Use PTStorage for typed Codable persistence.")
    static func setItem<T: Decodable & Encodable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(object) else {
            return
        }
        Base.standard.set(encoded, forKey: key)
    }
    
    //MARK: 取出模型
    ///取出模型
    /// - Parameters:
    ///   - type: 当时存储的类型
    ///   - key: 对应的key
    /// - Returns: 对应类型的模型
    @available(*, deprecated, message: "Use PTStorage for typed Codable persistence.")
    static func getItem<T: Decodable & Encodable>(_ type: T.Type, forKey key: String) -> T? {
        
        guard let data = Base.standard.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let object = try? decoder.decode(type, from: data) else {
            PTNSLogConsole("Couldnt find key",levelType: .error,loggerType: .userDefaults)
            return nil
        }
        return object
    }
    
    //MARK: 保存模型数组
    ///保存模型数组
    /// - Returns: 返回保存的结果
    @available(*, deprecated, message: "Use PTStorage for typed Codable persistence.")
    @discardableResult
    static func setModelArray<T: Decodable & Encodable>(modelArrry object: [T], key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            Base.standard.set(data, forKey: key)
            return true
        } catch {
            PTNSLogConsole(error,levelType: .error,loggerType: .userDefaults)
        }
        return false
    }
    
    //MARK: 读取模型数组
    ///读取模型数组
    /// - Returns: 返回读取的模型数组
    @available(*, deprecated, message: "Use PTStorage for typed Codable persistence.")
    static func getModelArray<T: Decodable & Encodable>(forKey key : String) -> [T] {
        guard let data = Base.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            PTNSLogConsole(error,levelType: .error,loggerType: .userDefaults)
        }
        return []
    }
}
