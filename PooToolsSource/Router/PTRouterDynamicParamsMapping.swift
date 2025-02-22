//
//  PTRouterDynamicParamsMapping.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/21/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation

// 定义结构体 ReturnStruct
struct ReturnStruct {
    unowned var instanceObject: AnyObject?
    unowned var returnValue: AnyObject?
}

// MARK: - PTRouterDynamicParamsMapping
class PTRouterDynamicParamsMapping {
    
    var filterKey: [String] = []
    
    static let shared: PTRouterDynamicParamsMapping = {
        let router = PTRouterDynamicParamsMapping()
        router.filterKey = ["requestURLKey", "jumpType", "tabBarSelecIndex"]
        return router
    }()
    
    /**
     初始化类。可直接通过 NSClassFromString 获取
     
     - Parameter className: 类字符串名字
     - Returns: 返回类对象
     */
    func routerClassName(_ className: String) -> AnyClass? {
        return NSClassFromString(className)
    }

    /**
     初始化类对象，获取类的初始化对象。
     
     - Parameter className: 类名
     - Returns: ReturnStruct 结构体，包含实例对象和返回值。
     */
    func routerGetInstance(with className: String) -> ReturnStruct {
        guard let cls = NSClassFromString(className) as? NSObject.Type else {
            return ReturnStruct(instanceObject: nil, returnValue: nil)
        }
        let instance = cls.init()
        return ReturnStruct(instanceObject: instance, returnValue: nil)
    }
}

// MARK: - NSObject Extension for PTRouterClass
extension NSObject {
    
    /**
     kvc模式执行实例对象f设置属性值
     
     - Parameter propertyParameter: 属性key-value
     - Returns: ReturnStruct
     */
    func setPropertyParameter(_ propertyParameter: [String: Any]) -> ReturnStruct {
        // 创建可变字典，以便进行修改
        var filteredDictionary = propertyParameter
        // 移除指定的键
        filteredDictionary.removeValues(forKeys: PTRouterDynamicParamsMapping.shared.filterKey)
        
        return NSObject.transferRouterObject(self, setPropertyParameter: filteredDictionary, methodSelect: nil, parameter: nil)
    }
    
    /**
     执行实例方法
     
     - Parameters:
       - selectString: 方法名
       - methodParaments: 属性key-value
     - Returns: ReturnStruct
     */
    func instanceMethodSelect(_ selectString: String, parameter methodParaments: UnsafeMutableRawPointer...) -> ReturnStruct {
        var parameters: [Any] = []
        
        if !methodParaments.isEmpty {
            // 将指针转换为可变数组，便于修改
            parameters.append(contentsOf: methodParaments.map { UnsafeRawPointer($0) })
        }
        
        return NSObject.transferRouterObject(self, setPropertyParameter: nil, methodSelect: selectString, parameter: parameters)
    }
    
    /**
     执行类方法
     
     - Parameters:
       - selectString: 方法名
       - methodParaments: 属性key-value
     - Returns: ReturnStruct
     */
    class func classMethodSelect(_ selectString: String, parameter methodParaments: UnsafeMutableRawPointer...) -> ReturnStruct {
        var parameters: [Any] = []
        
        if !methodParaments.isEmpty {
            parameters.append(contentsOf: methodParaments.map { UnsafeRawPointer($0) })
        }
        
        return NSObject.transferRouterObject(String(describing: self), setPropertyParameter: nil, methodSelect: selectString, parameter: parameters)
    }
    
    /**
     AOP kvc 对实例赋值以及进行方法签名，通过函数指针适配任意类型的值的传递 进行方法调用属性赋值等操作。
     
     - Parameters:
       - object: 类或实例对象
       - propertyParameter: 属性key-value
       - selectString: 方法名
       - Parameters: 方法参数
     - Returns: ReturnStruct
     */
    class func transferRouterObject(_ object: Any, setPropertyParameter propertyParameter: [String: Any]?, methodSelect selectString: String?, parameter parameters: [Any]?) -> ReturnStruct {
        
        var returnStruct = ReturnStruct(instanceObject: nil, returnValue: nil)
        
        if let className = object as? String {
            guard let cls = NSClassFromString(className) as? NSObject.Type else {
                return returnStruct
            }
            if let selectString = selectString {
                let methodSelector = Selector(selectString)
                if cls.responds(to: methodSelector) {
                    // 调用类方法
                    returnStruct = NSObject.getReturnResult(from: cls, methodSelector: methodSelector, parameters: parameters)
                }
            }
            
        } else if let instance = object as? NSObject {
            if let propertyParameter = propertyParameter {
                for (key, value) in propertyParameter {
                    let setterSelector = Selector("set\(key.prefix(1).uppercased())\(key.dropFirst()):")
                    if instance.responds(to: setterSelector) {
                        instance.setValue(value, forKey: key)
                    }
                }
            }
            
            if let selectString = selectString {
                let methodSelector = Selector(selectString)
                if instance.responds(to: methodSelector) {
                    returnStruct = NSObject.getReturnResult(from: instance, methodSelector: methodSelector, parameters: parameters)
                }
            }
        }
        
        return returnStruct
    }
    
    class func getReturnResult(from instance: Any, methodSelector: Selector, parameters: [Any]?) -> ReturnStruct {
        var returnValue: AnyObject?
        
        // 对参数进行处理和传递
        if let instance = instance as? NSObject {
            if instance.responds(to: methodSelector) {
                let invocation = instance.perform(methodSelector, with: parameters?.first)
                returnValue = invocation?.takeUnretainedValue()
            }
        }
        
        return ReturnStruct(instanceObject: instance as AnyObject, returnValue: returnValue)
    }
}

extension Dictionary {
    mutating func removeValues(forKeys keys: [Key]) {
        keys.forEach { removeValue(forKey: $0) }
    }
}
