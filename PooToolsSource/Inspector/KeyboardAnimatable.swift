//
//  KeyboardAnimatable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public typealias KeyboardAnimationInfo = (duration: TimeInterval, keyboardFrame: CGRect, curve: UIView.AnimationCurve)

// 1. 将闭包别名移到外部，并加上 @MainActor 和 @Sendable 以符合 Swift 6 严格并发检查
public typealias KeyboardAnimations = @MainActor @Sendable (KeyboardAnimationInfo) -> Void
public typealias KeyboardCompletion = @MainActor @Sendable (UIViewAnimatingPosition) -> Void

// 2. 添加 @MainActor 隔离，因为协议处理的全是 UI 动画逻辑
@MainActor
@objc public protocol KeyboardAnimatable: AnyObject {
    // 保持协议整洁，具体实现在 extension 中
}

// 定义一个静态 Key 用于关联对象存储
private enum AssociatedKeys {
    @MainActor static var keyboardTokens = "keyboardTokens"
}

// MARK: - KeyboardAnimatable Extension
public extension KeyboardAnimatable {
    
    private var notificationCenter: NotificationCenter { NotificationCenter.default }
    
    // 3. 核心修复：使用关联对象在 Protocol Extension 中存储 Observer Token
    // 这解决了原生 Block 形式的通知无法通过 removeObserver(self) 移除的 Bug
    private var observerTokens: [String: NSObjectProtocol] {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.keyboardTokens) as? [String: NSObjectProtocol] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.keyboardTokens, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func animateWhenKeyboard(_ notificationName: KeyboardNotificationName, // 假设这是你自定义的枚举/通知名类型
                             animations: @escaping KeyboardAnimations,
                             completion: KeyboardCompletion? = nil) {
        
        // 添加前先尝试移除旧的，防止多次注册导致动画错乱
        stopAnimatingWhenKeyboard(notificationName)
        
        let token = notificationCenter.addObserver(
            forName: notificationName.rawValue,
            object: nil,
            queue: .main // 确保回调在主线程队列触发
        ) { @MainActor [weak self] notification in // 4. Swift 6: 指定闭包内的 MainActor 上下文并弱引用 self 避免循环引用
            guard self != nil else { return }
            
            let keyboardAnimation = KeyboardAnimation(
                animation: animations,
                completion: completion
            )
            
            // 执行你的自定义动画扩展
            UIView.animate(
                withKeyboardNotification: notification,
                animations: keyboardAnimation.animation,
                completion: keyboardAnimation.completion
            )
        }
        
        // 5. 保存这个 Token，以便未来可以注销它
        // 注意：这里假设 notificationName.rawValue 是 String 或 NSNotification.Name，如果报错可转为 String
        let key = String(describing: notificationName.rawValue)
        var currentTokens = self.observerTokens
        currentTokens[key] = token
        self.observerTokens = currentTokens
    }
    
    func stopAnimatingWhenKeyboard(_ notificationNames: KeyboardNotificationName...) {
        var currentTokens = self.observerTokens
        
        notificationNames.forEach { notificationName in
            let key = String(describing: notificationName.rawValue)
            
            // 6. 查找我们之前保存的 Token 并用它来正确移除监听
            if let token = currentTokens[key] {
                notificationCenter.removeObserver(token)
                currentTokens.removeValue(forKey: key)
            }
        }
        
        // 更新存储状态
        self.observerTokens = currentTokens
    }
}
