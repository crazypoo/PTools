//
//  NSDictionary+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/21.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public extension NSDictionary
{
    @objc func jsonDataToString()->String
    {
        var jsonData : Data? = nil
                
        let dic = NSMutableDictionary()
        self.enumerateKeysAndObjects { keys, obj, stop in
            var keyString = ""
            var valueString = ""
            if keys is NSString || keys is String
            {
                keyString = keys as! String
            }
            else
            {
                keyString = String(format: "%@", keys as! CVarArg)
            }
            
            if obj is NSString || obj is String
            {
                valueString = obj as! String
            }
            else
            {
                valueString = String(format: "%@", obj as! CVarArg)
            }
            dic.setObject(valueString as NSCopying, forKey: keyString as NSCopying)
        }
        
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            let jsonString : NSString = String(data: jsonData!, encoding: .utf8)! as NSString
            let mutableString = NSMutableString.init(string: jsonString)
            let range : NSRange = NSRange.init(location: 0, length: jsonString.length)
            mutableString.replaceOccurrences(of: " ", with: "", options: .literal, range: range)
            let range2 : NSRange = NSRange.init(location: 0, length: mutableString.length)
            mutableString.replaceOccurrences(of: "\n", with: "", options: .literal, range: range2)
            return mutableString as String
        } catch {
            return ""
        }
    }
}
