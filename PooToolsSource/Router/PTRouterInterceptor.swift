//
//  PTRouterInterceptor.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

/// 异步拦截器协议
public protocol PTRouterAsyncInterceptor {
    /// 优先级：数字越大越先执行
    var priority: UInt { get }
    /// 白名单：哪些路径不需要拦截
    var whiteList: [String] { get }
    
    /// 拦截逻辑：返回 true 继续，返回 false 或抛出错误则中断
    func handle(queries: [String: Any]) async throws -> Bool
}
