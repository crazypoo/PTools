//
//  PTSwiftMethodSwizzle.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

infix operator <->

public struct SwizzlePair{
    let original:Selector
    let swizzled:Selector
}

extension Selector
{
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
public struct Swizzle{
    @resultBuilder
    public struct SwizzleFunctionBuilder{
        public static func buildBlock(_ swizzlePairs:SwizzlePair...) -> [SwizzlePair]{
            Array(swizzlePairs)
        }
    }
    
    @discardableResult
    public init(_ type:AnyObject.Type,@SwizzleFunctionBuilder _ makeSwizzlePairs:()->[SwizzlePair]){
        let swizzlePairs = makeSwizzlePairs()
        swizzle(type: type, pairs: swizzlePairs)
    }
    
    @discardableResult
    public init(_ type:AnyObject.Type,@SwizzleFunctionBuilder _ makeSwizzlePairs:()->SwizzlePair){
        let swizzlePairs = makeSwizzlePairs()
        swizzle(type: type, pairs: [swizzlePairs])
    }
    
    private func swizzle(type:AnyObject.Type,pairs:[SwizzlePair]){
        pairs.forEach { swizzlePair in
            guard let originalMethod = class_getInstanceMethod(type, swizzlePair.original),let swizzledMethod = class_getInstanceMethod(type, swizzlePair.swizzled) else { return }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}
