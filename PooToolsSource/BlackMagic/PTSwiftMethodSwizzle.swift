//
//  PTSwiftMethodSwizzle.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

//MARK: 自定義運算符號
infix operator <->

public struct SwizzlePair {
    let original:Selector
    let swizzled:Selector
}

extension Selector {
    public static func <->(original:Selector,swizzled:Selector) -> SwizzlePair{
        SwizzlePair(original: original, swizzled: swizzled)
    }
}

/*
 @objc static func swizzle() -> Void {
     Swizzle(Class.self) {
         #selector(x) <-> #selector(y)
         #selector(x(_:)) <-> #selector(y(_:))
     }
 }
 */
public struct Swizzle {
    
    @resultBuilder
    public struct SwizzleFunctionBuilder {
        public static func buildBlock(_ swizzlePairs:SwizzlePair...) -> [SwizzlePair] {
            Array(swizzlePairs)
        }
    }
    
    /// 初始化并执行 Swizzling
    /// - Parameters:
    ///   - type: 要交换方法的类
    ///   - isClassMethod: 是否为类方法（默认为 false，即实例方法）
    ///   - makeSwizzlePairs: ResultBuilder 闭包
    @discardableResult
    public init(_ type: AnyClass, isClassMethod: Bool = false, @SwizzleFunctionBuilder _ makeSwizzlePairs: () -> [SwizzlePair]) {
        let swizzlePairs = makeSwizzlePairs()
        executeSwizzling(on: type, pairs: swizzlePairs, isClassMethod: isClassMethod)
    }
    
    @discardableResult
    public init(_ type: AnyClass, isClassMethod: Bool = false, @SwizzleFunctionBuilder _ makeSwizzlePairs: () -> SwizzlePair) {
        executeSwizzling(on: type, pairs: [makeSwizzlePairs()], isClassMethod: isClassMethod)
    }
    
    private func executeSwizzling(on targetClass: AnyClass, pairs: [SwizzlePair], isClassMethod: Bool) {
        // 如果是类方法，需要获取元类 (Meta Class)
        let cls: AnyClass = isClassMethod ? object_getClass(targetClass) ?? targetClass : targetClass
        
        for pair in pairs {
            guard let originalMethod = class_getInstanceMethod(cls, pair.original),
                  let swizzledMethod = class_getInstanceMethod(cls, pair.swizzled) else {
                PTNSLogConsole("⚠️ Swizzle 失败: 找不到方法 \(pair.original) 或 \(pair.swizzled)")
                continue
            }
            
            // 1. 尝试向类添加原方法名，但指向新方法的实现(IMP)
            // 这样做是为了防止直接修改父类的实现
            let didAddMethod = class_addMethod(cls,
                                               pair.original,
                                               method_getImplementation(swizzledMethod),
                                               method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod {
                // 2. 如果添加成功，说明原方法是在父类中。
                // 此时原方法名已经指向新实现，我们只需将新方法名指向原实现即可。
                class_replaceMethod(cls,
                                    pair.swizzled,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod))
            } else {
                // 3. 如果添加失败，说明当前类已经有了该方法的实现，直接交换即可
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
}
