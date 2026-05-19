//
//  KeyboardAnimatable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

private final class PTWeakSelfBox<T: AnyObject>: @unchecked Sendable {
    weak var value: T?
    init(_ value: T?) { self.value = value }
}

// 用于安全传递带有 Any 类型的 Notification
private final class PTNotificationBox: @unchecked Sendable {
    let notification: Notification
    init(_ notification: Notification) { self.notification = notification }
}

// 用于安全传递外部的动画闭包
private final class PTKeyboardActionBox<Anim, Comp>: @unchecked Sendable {
    let animations: Anim
    let completion: Comp
    init(_ animations: Anim, _ completion: Comp) {
        self.animations = animations
        self.completion = completion
    }
}

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
    @MainActor static var keyboardTokens:UInt8 = 0
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
    
    func animateWhenKeyboard(_ notificationName: KeyboardNotificationName,
                                 animations: @escaping KeyboardAnimations,
                                 completion: KeyboardCompletion? = nil) {
            
        // 添加前先尝试移除旧的，防止多次注册导致动画错乱
        stopAnimatingWhenKeyboard(notificationName)
        
        let weakSelfBox = PTWeakSelfBox(self)
        let actionBox = PTKeyboardActionBox(animations, completion)

        _ = notificationCenter.addObserver(
            forName: notificationName.rawValue,
            object: nil,
            queue: .main // 运行时仍然保证投递到主队列
        ) { notification in
            let notifBox = PTNotificationBox(notification)
            // 🌟 4. 开启 Task 回到主线程，安全拆箱并执行
            Task { @MainActor in
                // 拆箱 self，如果对象已经被销毁则直接返回，安全可靠
                guard weakSelfBox.value != nil else { return }
                
                let keyboardAnimation = KeyboardAnimation(
                    animation: actionBox.animations,
                    completion: actionBox.completion
                )
                
                // 执行你的自定义动画扩展，使用拆箱后的 notification
                UIView.animate(
                    withKeyboardNotification: notifBox.notification,
                    animations: keyboardAnimation.animation,
                    completion: keyboardAnimation.completion
                )
            }
        }
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
