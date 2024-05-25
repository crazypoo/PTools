//
//  PTObject2Json.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 18/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public class PTObject2Json: NSObject {
    class func getObjectData(obj:NSObject) ->NSDictionary {
        let dic = NSMutableDictionary()
        var propsCount:UInt32 = 0
        let props = class_copyPropertyList((obj.self as! AnyClass), &propsCount)
        for i in 0...propsCount {
            let prop = props![Int(i)]
            let propName = NSString(utf8String: property_getName(prop))
            var value = obj.value(forKey: propName! as String)
            if value == nil {
                value = NSNull()
            } else {
                value = PTObject2Json.getObjectInternal(obj: value as! NSObject)
            }
            dic .setObject(value!, forKey: propName!)
        }
        return dic
    }
    
    class func getObjectInternal(obj:NSObject)->NSObject {
        if obj is NSString || obj is NSNumber || obj is NSNull {
            return obj
        }
        
        if obj is NSArray {
            let objArr = obj as! NSArray
            let arr = NSMutableArray(capacity: objArr.count)
            for i in 0...objArr.count {
                arr[i] = PTObject2Json.getObjectInternal(obj: objArr[i] as! NSObject)
            }
            return arr
        }
        
        if obj is NSDictionary {
            let objDic = obj as! NSDictionary
            let dic = NSMutableDictionary(capacity: objDic.count)
            for key in objDic.allKeys {
                dic[key] = PTObject2Json.getObjectInternal(obj: objDic[key] as! NSObject)
            }
            return dic
        }
        return PTObject2Json.getObjectData(obj: obj)
    }
    
    class func getJson(obj:NSObject,options:JSONSerialization.WritingOptions) ->NSData {
        do {
            return try JSONSerialization.data(withJSONObject: PTObject2Json.getObjectData(obj: obj) ,options: options) as NSData
        } catch {
            PTNSLogConsole(error.localizedDescription,levelType: .Error,loggerType: .Json)
        }
        return NSData()
    }
}
