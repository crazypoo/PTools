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
