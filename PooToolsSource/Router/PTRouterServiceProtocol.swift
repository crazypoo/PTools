//
//  PTRouteServiceProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import UIKit

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

/// 路由参数契约
public protocol PTRoutableParams {
    /// 该参数对应的目标控制器类型
    associatedtype Target: UIViewController
    /// 将结构体转换为字典（用于底层兼容）
    func toDictionary() -> [String: Any]
}

/// 让支持强类型的 VC 遵循此协议
public protocol PTRoutableStaticController: PTRoutableController {
    associatedtype Params: PTRoutableParams
}
