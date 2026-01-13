//
//  AnyClass+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 17/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension NSObject {
    
    var className: String {
        String(describing: type(of: self))
    }
                
    func convertToJsonString() -> String {
        if !JSONSerialization.isValidJSONObject(self) {
            return ""
        }
        
        let jsonOptions:JSONSerialization.WritingOptions = [.prettyPrinted,.sortedKeys]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self,options: jsonOptions)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            return jsonString ?? ""
        } catch {
            return ""
        }
    }
    
    // MARK: - Public
    /// 转 Dictionary（可用于 JSON）
    func pt_toDictionary() -> [String: Any] {
        return Self.pt_objectToDictionary(self)
    }

    /// 转 JSON Data
    func pt_toJSONData(options: JSONSerialization.WritingOptions = []) -> Data? {
        let dict = pt_toDictionary()
        return try? JSONSerialization.data(withJSONObject: dict, options: options)
    }

    /// 转 JSON String
    func pt_toJSONString(options: JSONSerialization.WritingOptions = []) -> String? {
        guard let data = pt_toJSONData(options: options) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Core Convert

    private static func pt_objectToDictionary(_ obj: NSObject) -> [String: Any] {
        var result: [String: Any] = [:]

        var count: UInt32 = 0
        guard let properties = class_copyPropertyList(type(of: obj), &count) else {
            return result
        }
        defer { free(properties) }

        for i in 0..<Int(count) {
            let property = properties[i]
            let name = String(cString: property_getName(property))

            let value = obj.value(forKey: name)
            result[name] = pt_convertValue(value)
        }

        return result
    }

    private static func pt_convertValue(_ value: Any?) -> Any {
        guard let value = value else {
            return NSNull()
        }

        // Foundation 基础类型
        if value is NSString || value is NSNumber || value is NSNull {
            return value
        }

        // Swift String / Int / Double
        if let v = value as? String { return v }
        if let v = value as? Int { return v }
        if let v = value as? Double { return v }
        if let v = value as? Bool { return v }

        // Array
        if let array = value as? [Any] {
            return array.map { pt_convertValue($0) }
        }

        if let nsArray = value as? NSArray {
            return nsArray.map { pt_convertValue($0) }
        }

        // Dictionary
        if let dict = value as? [String: Any] {
            var result: [String: Any] = [:]
            dict.forEach { result[$0.key] = pt_convertValue($0.value) }
            return result
        }

        if let nsDict = value as? NSDictionary {
            var result: [AnyHashable: Any] = [:]
            nsDict.forEach {
                result[$0.key as! AnyHashable] = pt_convertValue($0.value)
            }
            return result
        }

        // 自定义 NSObject
        if let obj = value as? NSObject {
            return pt_objectToDictionary(obj)
        }

        return NSNull()
    }
}

public extension Optional where Wrapped: NSObject {
    /// 判断对象是否为 nil、NSNull 或空集合/字符串/数据
    func isNullOrEmpty() -> Bool {
        guard let obj = self else { return true }
        if obj is NSNull { return true }
        if let data = obj as? Data, data.isEmpty { return true }
        if let array = obj as? NSArray, array.count == 0 { return true }
        if let dict = obj as? NSDictionary, dict.count == 0 { return true }
        if let str = obj as? NSString, str.length == 0 { return true }
        return false
    }
}

public extension Optional {
    /// 通用判空：支持 Swift 和 Objective-C 常用类型
    func isNullOrEmpty() -> Bool {
        guard let value = self else { return true } // nil 直接返回 true

        switch value {
        // Swift 类型
        case let str as String:
            return str.isEmpty
        case let arr as [Any]:
            return arr.isEmpty
        case let dict as [AnyHashable: Any]:
            return dict.isEmpty

        // Objective-C 类型
        case is NSNull:
            return true
        case let str as NSString:
            return str.length == 0
        case let arr as NSArray:
            return arr.count == 0
        case let dict as NSDictionary:
            return dict.count == 0
        case let data as Data:
            return data.isEmpty
        case let data as NSData:
            return data.length == 0

        default:
            return false
        }
    }
}
