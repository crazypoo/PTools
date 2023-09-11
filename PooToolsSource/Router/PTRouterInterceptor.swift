//
//  PTRouterInterceptor.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public class PTRouterInterceptor: NSObject {
    
    public typealias InterceptorHandleBlock = ([String: Any]) -> Bool
    
    var priority: uint
    var whiteList: [String]
    var handle: InterceptorHandleBlock
    
    init(_ whiteList: [String],
         priority: uint,
         handle: @escaping InterceptorHandleBlock) {
        
        self.whiteList = whiteList
        self.priority = priority
        self.handle = handle
    }
}
