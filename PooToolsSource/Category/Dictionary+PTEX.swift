//
//  Dictionary.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

extension Dictionary: PTProtocolCompatible { }

public extension [String: Any] {
    func formattedString() -> String {
        var formattedString = ""
        for (key, value) in self {
            formattedString += "\(key): \(value)\n"
        }
        return formattedString
    }
}

public extension [AnyHashable: Any] {
    func convertKeysToString() -> [String: Value] {
        var result: [String: Value] = [:]

        for (key, value) in self {
            if let keyString = key as? String {
                result[keyString] = value
            }
        }

        return result
    }
}

public extension Dictionary {
    /// English: Serializes a JSON-compatible dictionary without forcing a cast.
    /// Español: Serializa un diccionario compatible con JSON sin forzar conversiones.
    /// 中文：安全序列化 JSON 兼容字典，不进行强制转换。
    func jsonData(options: JSONSerialization.WritingOptions = []) -> Data? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        return try? JSONSerialization.data(withJSONObject: self, options: options)
    }

    /// English: Returns the UTF-8 JSON representation when serialization succeeds.
    /// Español: Devuelve la representación JSON UTF-8 cuando la serialización tiene éxito.
    /// 中文：序列化成功时返回 UTF-8 JSON 字符串。
    func jsonString(options: JSONSerialization.WritingOptions = []) -> String? {
        guard let data = jsonData(options: options) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func asJsonStr() -> String? {
        jsonString(options: [.sortedKeys])
    }
}

public extension Dictionary {
    /// English: Groups dictionary values by a key path.
    /// Español: Agrupa los valores del diccionario mediante una ruta de clave.
    /// 中文：按照值上的 KeyPath 对字典值进行分组。
    func grouping<Group: Hashable>(by keyPath: KeyPath<Value, Group>) -> [Group: [Value]] {
        var result: [Group: [Value]] = [:]
        for value in values {
            result[value[keyPath: keyPath], default: []].append(value)
        }
        return result
    }

    /// English: Removes all entries whose keys occur in the supplied sequence.
    /// Español: Elimina todas las entradas cuyas claves aparecen en la secuencia dada.
    /// 中文：移除给定序列中出现的所有键。
    mutating func removeAll<S: Sequence>(keys: S) where S.Element == Key {
        for key in keys { removeValue(forKey: key) }
    }

    /// English: Transforms keys and values together.
    /// Español: Transforma conjuntamente las claves y los valores.
    /// 中文：同时转换字典的键和值。
    func mapKeysAndValues<NewKey: Hashable, NewValue>(
        _ transform: (Key, Value) throws -> (NewKey, NewValue)
    ) rethrows -> [NewKey: NewValue] {
        try Dictionary<NewKey, NewValue>(uniqueKeysWithValues: map(transform))
    }

    /// English: Transforms keys and values while allowing entries to be dropped.
    /// Español: Transforma claves y valores permitiendo descartar entradas.
    /// 中文：转换键和值，并允许过滤掉部分条目。
    func compactMapKeysAndValues<NewKey: Hashable, NewValue>(
        _ transform: (Key, Value) throws -> (NewKey, NewValue)?
    ) rethrows -> [NewKey: NewValue] {
        try Dictionary<NewKey, NewValue>(uniqueKeysWithValues: compactMap(transform))
    }

    /// English: Returns a dictionary containing only the requested keys.
    /// Español: Devuelve un diccionario que contiene solo las claves solicitadas.
    /// 中文：返回只包含指定键的字典。
    func pick<S: Sequence>(keys: S) -> [Key: Value] where S.Element == Key {
        var result: [Key: Value] = [:]
        for key in keys {
            if let value = self[key] { result[key] = value }
        }
        return result
    }

    /// English: Returns all keys whose values equal the supplied value.
    /// Español: Devuelve todas las claves cuyos valores son iguales al valor dado.
    /// 中文：返回值等于给定值的所有键。
    func keys(forValue value: Value) -> [Key] where Value: Equatable {
        compactMap { $0.value == value ? $0.key : nil }
    }

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
        guard let jsonData = json.data(using: .utf8),
              let data = (try? JSONSerialization.jsonObject(
                with: jsonData,
                options: .mutableContainers)) as? Dictionary<String, Any> else {
            return nil
        }
        return data
    }
    
    //MARK: 字典转JSON字符串
    ///字典转JSONString
    func toJSON(options:JSONSerialization.WritingOptions = JSONSerialization.WritingOptions.prettyPrinted) -> String? {
        jsonString(options: options)
    }
    
    //MARK: 字典里面所有的key
    ///字典里面所有的key
    /// - Returns: key 数组
    func allKeys() -> [Key] {
        Array(keys)
    }
    
    //MARK: 字典里面所有的value
    ///字典里面所有的value
    /// - Returns: value 数组
    func allValues() -> [Value] {
        Array(values)
    }

    /// English: Explicitly returns keys in random order.
    /// Español: Devuelve explícitamente las claves en orden aleatorio.
    /// 中文：显式返回随机顺序的键。
    func shuffledKeys() -> [Key] { keys.shuffled() }

    /// English: Explicitly returns values in random order.
    /// Español: Devuelve explícitamente los valores en orden aleatorio。
    /// 中文：显式返回随机顺序的值。
    func shuffledValues() -> [Value] { values.shuffled() }
    
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
        guard let keyString = keys.first,
              let key = keyString as? Key,
              let typedValue = newValue as? Value else { return false }
        if keys.count == 1 {
            self[key] = typedValue
            return true
        }
        guard var nested = self[key] as? [String: Any] else { return false }
        let result = nested.setValue(newValue, at: Array(keys.dropFirst()))
        guard let converted = nested as? Value else { return false }
        self[key] = converted
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

/// English: Typed-looking deep-path access for the legacy string/Any dictionary shape.
/// Español: Acceso tipado por rutas profundas para la forma heredada de diccionario String/Any.
/// 中文：为历史 String/Any 字典提供结构清晰的深层路径读写入口。
public extension Dictionary where Key == String, Value == Any {
    func value(at path: [String]) -> Any? {
        guard !path.isEmpty else { return nil }
        var current: Any = self
        for key in path {
            guard let dictionary = current as? [String: Any], let next = dictionary[key] else { return nil }
            current = next
        }
        return current
    }

    @discardableResult
    mutating func setValue(_ value: Any, at path: [String]) -> Bool {
        guard let first = path.first else { return false }
        if path.count == 1 {
            self[first] = value
            return true
        }
        guard var nested = self[first] as? [String: Any] else { return false }
        guard nested.setValue(value, at: Array(path.dropFirst())) else { return false }
        self[first] = nested
        return true
    }
}

// MARK: 其他基本扩展
public extension PTPOP where Base == Dictionary<String, Any> {
    
    //MARK: 字典转JSON
    ///字典转JSON
    @discardableResult
    func dictionaryToJson() -> String? {
        if (!JSONSerialization.isValidJSONObject(base)) {
            PTNSLogConsole("无法解析出JSONString",levelType: .error,loggerType: .dictionary)
            return nil
        }
        if let data = try? JSONSerialization.data(withJSONObject: base) {
            return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
        } else {
            PTNSLogConsole("无法解析出JSONString",levelType: .error,loggerType: .dictionary)
            return nil
        }
    }
}
