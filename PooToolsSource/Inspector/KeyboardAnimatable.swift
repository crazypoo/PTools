//
//  KeyboardAnimatable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

// English: Keep only Sendable keyboard values across the notification task boundary.
// Español: Solo cruza el límite de la tarea un valor de teclado que sea Sendable.
// 中文：通知任务边界只传递符合 Sendable 的键盘值。
private struct PTKeyboardAnimationSnapshot: Sendable {
    let duration: TimeInterval
    let keyboardFrame: CGRect
    let curveRawValue: Int

    init?(notification: Notification) {
        guard
            notification.userInfo?[.keyboardIsLocalKey] as? Bool == true,
            let duration = notification.userInfo?[.durationKey] as? Double,
            let keyboardFrame = notification.userInfo?[.frameKey] as? CGRect,
            let curveRawValue = notification.userInfo?[.curveKey] as? Int,
            UIView.AnimationCurve(rawValue: curveRawValue) != nil
        else {
            return nil
        }

        self.duration = duration
        self.keyboardFrame = keyboardFrame
        self.curveRawValue = curveRawValue
    }

    @MainActor
    var info: KeyboardAnimationInfo {
        KeyboardAnimationInfo(
            duration: duration,
            keyboardFrame: keyboardFrame,
            curve: UIView.AnimationCurve(rawValue: curveRawValue) ?? .easeInOut
        )
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

// English: Keep UIKit's completion-handler call in a synchronous MainActor helper.
// Español: Mantén la llamada de finalización de UIKit en un auxiliar síncrono de MainActor.
// 中文：将 UIKit 的完成回调调用放在同步的 MainActor 辅助方法中。
@MainActor
private func pt_startKeyboardAnimation(
    info: KeyboardAnimationInfo,
    animations: @escaping KeyboardAnimations,
    completion: KeyboardCompletion?
) {
    let animator = UIViewPropertyAnimator(duration: info.duration, curve: info.curve)
    animator.addAnimations {
        animations(info)
    }
    if let completion {
        animator.addCompletion(completion)
    }
    animator.startAnimation()
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
        
        _ = notificationCenter.addObserver(
            forName: notificationName.rawValue,
            object: nil,
            queue: .main // 运行时仍然保证投递到主队列
        ) { notification in
            guard let snapshot = PTKeyboardAnimationSnapshot(notification: notification) else { return }

            Task { @MainActor in
                let info = snapshot.info
                pt_startKeyboardAnimation(
                    info: info,
                    animations: animations,
                    completion: completion
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
