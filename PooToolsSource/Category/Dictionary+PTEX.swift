//
//  Dictionary.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

extension Dictionary: PTProtocolCompatible { }

public extension Dictionary {
    //MARK: 检查字典里面是否有某个 key
    ///检查字典里面是否有某个 key
    func has(_ key: Key) -> Bool {
        index(forKey: key) != nil
    }
    
    //MARK: 字典的key或者value组成的数组
    ///字典的key或者value组成的数组
    /// - Parameters:
    ///  - map: map
    /// - Returns: 数组
    func toArray<V>(_ map: (Key, Value) -> V) -> [V] {
        self.map(map)
    }
    
    //MARK: JSON字符串转字典
    ///JsonString转为字典
    /// - Parameters:
    ///  - json: JSON字符串
    /// - Returns: 字典
    static func jsonToDictionary(json: String) -> Dictionary<String, Any>? {
        if let data = (try? JSONSerialization.jsonObject(
            with: json.data(using: String.Encoding.utf8,allowLossyConversion: true)!,
            options: JSONSerialization.ReadingOptions.mutableContainers)) as? Dictionary<String, Any> {
            return data
        } else {
            return nil
        }
    }
    
    //MARK: 字典转JSON字符串
    ///字典转JSONString
    func toJSON(options:JSONSerialization.WritingOptions = JSONSerialization.WritingOptions.prettyPrinted) -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted) {
            let jsonStr = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            return String(jsonStr ?? "")
        }
        return nil
    }
    
    //MARK: 字典里面所有的key
    ///字典里面所有的key
    /// - Returns: key 数组
    func allKeys() -> [Key] {
        /*
         shuffled：不会改变原数组，返回一个新的随机化的数组。  可以用于let 数组
         */
        keys.shuffled()
    }
    
    //MARK: 字典里面所有的value
    ///字典里面所有的value
    /// - Returns: value 数组
    func allValues() -> [Value] {
        values.shuffled()
    }
    
    //MARK: 设置value
    subscript<Result>(key: Key, as type: Result.Type) -> Result? {
        get {
            self[key] as? Result
        }
        set {
            // 如果传⼊ nil, 就删除现存的值。
            guard let value = newValue else {
                self[key] = nil
                return
            }
            // 如果类型不匹配，就忽略掉。
            guard let value2 = value as? Value else {
                return
            }
            self[key] = value2
        }
    }
    
    //MARK: 设置value
    ///设置value
    /// - Parameters:
    ///   - keys: key链
    ///   - newValue: 新的value
    @discardableResult
    mutating func setValue(keys: [String], newValue: Any) -> Bool {
        guard keys.count > 1 else {
            guard keys.count == 1, let key = keys[0] as? Dictionary<Key, Value>.Keys.Element else {
                return false
            }
            self[key] = (newValue as! Value)
            return true
        }
        guard let key = keys[0] as? Dictionary<Key, Value>.Keys.Element, self.keys.contains(key), var value1 = self[key] as? [String: Any] else {
            return false
        }
        let result = Dictionary<String, Any>.value(keys: Array(keys[1..<keys.count]), oldValue: &value1, newValue: newValue)
        self[key] = (value1 as! Value)
        return result
    }
    
    //MARK: 字典深层次设置value
    ///字典深层次设置value
    /// - Parameters:
    ///   - keys: key链
    ///   - oldValue: 字典
    ///   - newValue: 新的值
    @discardableResult
    private static func value(keys: [String], oldValue: inout [String: Any], newValue: Any) -> Bool {
        guard keys.count > 1 else {
            oldValue[keys[0]] = newValue
            return true
        }
        guard var value1 = oldValue[keys[0]] as? [String : Any] else { return false}
        let key = Array(keys[1..<keys.count])
        let result = value(keys: key, oldValue: &value1, newValue: newValue)
        oldValue[keys[0]] = value1
        return result
    }
    
    //MARK: 路由用到
    mutating func merge(dic:Dictionary) {
        self.merge(dic) { (parama1, parama2) -> Value in
            parama1
        }
    }
    
    mutating func routerCombine(_ dict: Dictionary) {
        var tem = self
        dict.forEach({ (key, value) in
            if let existValue = tem[key] {
                // combine same name query
                if let arrValue = existValue as? [Value] {
                    tem[key] = (arrValue + [value]) as? Value
                } else {
                    tem[key] = ([existValue, value]) as? Value
                }
            } else {
                tem[key] = value
            }
        })
        self = tem
    }
}

// MARK: 其他基本扩展
public extension PTPOP where Base == Dictionary<String, Any> {
    
    //MARK: 字典转JSON
    ///字典转JSON
    @discardableResult
    func dictionaryToJson() -> String? {
        if (!JSONSerialization.isValidJSONObject(base)) {
            PTNSLogConsole("无法解析出JSONString")
            return nil
        }
        if let data = try? JSONSerialization.data(withJSONObject: base) {
            let JSONString = NSString(data:data,encoding: String.Encoding.utf8.rawValue)
            return JSONString! as String
        } else {
            PTNSLogConsole("无法解析出JSONString")
            return nil
        }
    }
}

