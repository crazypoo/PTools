//
//  PTWeakProxy.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public final class PTWeakProxy: NSObject, @unchecked Sendable {
    
    /// 真正的目标对象，使用 weak 弱引用避免内存泄漏
    private weak var target: NSObjectProtocol?
    
    /// 初始化方法
    /// - Parameter target: 需要代理的真实目标对象
    public init(target: NSObjectProtocol) {
        self.target = target
        super.init()
    }
    
    /// 快速创建代理对象的类方法 (工厂方法)
    /// - Parameter target: 需要代理的真实目标对象
    /// - Returns: 弱引用代理实例
    public class func proxy(withTarget target: NSObjectProtocol) -> PTWeakProxy {
        return PTWeakProxy(target: target)
    }
    
    // MARK: - 消息转发机制 (Message Forwarding)
    
    /// 消息转发的第一步：重定向接收者
    /// 如果当前代理无法响应方法，将其转发给真正的 target
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
    
    /// 辅助方法：协助系统判断当前对象是否能响应特定的 Selector
    public override func responds(to aSelector: Selector!) -> Bool {
        // 如果 target 存在，询问 target 能否响应；如果 target 已释放，返回 false
        return target?.responds(to: aSelector) ?? false
    }
}
