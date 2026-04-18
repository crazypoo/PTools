//
//  PTRouteServiceProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

@objc
public protocol PTRouterServiceProtocol: NSObjectProtocol {
    init()
    
    static var seriverName:String { get }
}

public protocol PTRoutableController {
    /// 规范化的路由参数初始化方法
    init(routerParams: [String: Any])
}

public protocol PTServiceProtocol: AnyObject {}
