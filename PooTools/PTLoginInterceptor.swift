//
//  PTLoginInterceptor.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/5/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

@MainActor
class PTTestGlobalFunction:NSObject {
    static let shared = PTTestGlobalFunction()
    var isLogin = false
}

final class PTLoginInterceptor: PTRouterAsyncInterceptor, @unchecked Sendable {
    public let priority: UInt = 100
    
    private var _whiteList: [String] = [
        "ptools://login"
    ]
    
    // 🌟 优化 3：声明一把互斥锁，保护数组的读写
    private let lock = NSLock()

    // 🌟 优化 4：对外暴露的只读属性，满足 PTRouterAsyncInterceptor 协议
    public var whiteList: [String] {
        lock.lock() // 读之前上锁
        defer { lock.unlock() } // 读完自动解锁
        return _whiteList
    }
    
    // 🌟 新增：专门暴露给外部使用的安全添加方法
    public func addWhiteListPaths(_ paths: [String]) {
        lock.lock() // 写之前上锁
        defer { lock.unlock() } // 写完自动解锁
        
        for path in paths {
            if !_whiteList.contains(path) {
                _whiteList.append(path)
            }
        }
    }

    @MainActor
    public func handle(queries: [String: Sendable]) async throws -> Bool {
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
