//
//  PTLoginInterceptor.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/5/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

class PTTestGlobalFunction:NSObject {
    static let shared = PTTestGlobalFunction()
    var isLogin = false
}

class PTLoginInterceptor: PTRouterAsyncInterceptor {
    public var priority: UInt = 100 // 设置一个高优先级
    
    // 登录页、注册页、首页等通常在白名单内
    public var whiteList: [String] = [
        "ptools://login",
    ]

    public func handle(queries: [String: Any]) async throws -> Bool {
        // 1. 检查本地登录状态 (假设你有 UserManager)
        if PTTestGlobalFunction.shared.isLogin {
            return true // 已登录，放行
        }
        
        // 2. 未登录，通过 Router 跳转到登录页
        // 这里使用 try? await 等待登录流程结束
        // 假设登录成功会返回具体的 VC 实例，失败返回 nil
        let loginResult = try? await PTRouter.openURL("ptools://login")
        
        // 3. 根据登录结果决定是否继续原来的跳转
        if loginResult != nil {
            return true  // 用户登录成功了，放行
        } else {
            return false // 用户取消了登录，中断跳转
        }
    }
}
