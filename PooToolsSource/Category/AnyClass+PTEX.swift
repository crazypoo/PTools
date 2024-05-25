//
//  AnyClass+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 17/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension NSObject {
    //MARK: 獲取一個Class中的Keys
    ///獲取一個Class中的Keys
    class func getClassName() {
        var count:UInt32 = 0
        let ivars = class_copyIvarList((self as AnyClass), &count)
        
        for i in 0..<count {
            let ivar = ivars![Int(i)]
            let cName = ivar_getName(ivar)!
            let keysName = String(utf8String: cName)
            PTNSLogConsole(keysName!,levelType: PTLogMode,loggerType: .AnyClass)
        }
        free(ivars)
    }
    
    var className: String {
        String(describing: type(of: self))
    }
    
    //MARK: 檢測Obj是否為空
    ///檢測Obj是否為空
    class func checkObject(_ obj: NSObject?) -> Bool {
        if obj == nil || obj is NSNull {
            return true
        }
        if let data = obj as? Data, data.count == 0 {
            return true
        }
        if let array = obj as? NSArray, array.count == 0 {
            return true
        }
        return false
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
