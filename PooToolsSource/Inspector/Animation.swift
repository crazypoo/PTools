//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension TimeInterval {
    static let veryShort: TimeInterval = average / 4
    static let short: TimeInterval = average / 2
    static let average: TimeInterval = CATransaction.animationDuration()
    static let long: TimeInterval = average * 2
    static let veryLong: TimeInterval = average * 3
}

enum Animation {
    static let defaultDamping: CGFloat = 0.825
    static let defaultOptions: UIView.AnimationOptions = [.allowUserInteraction, .beginFromCurrentState]
    static let defaultVelocity: CGFloat = .zero

    case `in`, out

    var damping: CGFloat { Self.defaultDamping }

    var velocity: CGFloat { Self.defaultVelocity }

    var options: UIView.AnimationOptions { [.allowUserInteraction, .beginFromCurrentState] }

    var transform: CGAffineTransform {
        switch self {
        case .in:
            return CGAffineTransform(scaleX: 0.9, y: 0.96)

        case .out:
            return .identity
        }
    }
}

extension UIView {
    func animate(
        from fromAnimation: Animation,
        to toAnimation: Animation,
        duration: TimeInterval = .average,
        delay: TimeInterval = .zero,
        completion: PTBoolTask? = nil) {
        transform = fromAnimation.transform

        animate(toAnimation, duration: duration, delay: delay, completion: completion)
    }

    func animate(
        _ animation: Animation,
        duration: TimeInterval = .average,
        delay: TimeInterval = .zero,
        completion: PTBoolTask? = nil) {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: animation.damping,
            initialSpringVelocity: animation.velocity,
            options: animation.options,
            animations: { self.transform = animation.transform },
            completion: completion
        )
    }
}

extension NSObject {
    
    /// 封装的便捷 UI 动画方法 (Swift 6 并发安全版)
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - damping: 弹簧阻尼
    ///   - options: 动画选项
    ///   - animations: 具体的 UI 更新闭包（已约束在主线程）
    ///   - completion: 动画结束后的回调（已约束在主线程）
    @MainActor
    func animate(withDuration duration: TimeInterval = /* Animation.average 替换回你的默认值 */ 0.25,
                 delay: TimeInterval = .zero,
                 damping: CGFloat = /* Animation.defaultDamping 替换回你的默认值 */ 0.7,
                 options: UIView.AnimationOptions = /* Animation.defaultOptions 替换回你的默认值 */ [],
                 animations: @escaping @MainActor () -> Void,
                 completion: PTBoolTask? = nil) {
        
        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: damping,
            initialSpringVelocity: /* Animation.defaultVelocity 替换回你的默认值 */ 0.0,
            options: options,
            animations: animations,
            completion: completion
        )
    }
    
    // MARK: - 🚀 现代 Swift 专属升级方案 (可选)
    
    /// 支持 async/await 的现代化动画封装
    /// 优势：消除回调嵌套，代码阅读如同同步执行般流畅
    @MainActor
    func animateAsync(withDuration duration: TimeInterval = 0.25,
                      delay: TimeInterval = .zero,
                      damping: CGFloat = 0.7,
                      options: UIView.AnimationOptions = []) async -> Bool {
        
        // 使用 withCheckedContinuation 将基于回调的旧 API 转换为 async/await
        return await withCheckedContinuation { continuation in
            UIView.animate(
                withDuration: duration,
                delay: delay,
                usingSpringWithDamping: damping,
                initialSpringVelocity: 0.0,
                options: options,
                animations: {
                    // 这里留空，因为 async/await 模式下，状态修改通常在调用前后直接进行
                    // 或者是你可以将 animations 作为一个非逃逸闭包传进来
                },
                completion: { finished in
                    continuation.resume(returning: finished)
                }
            )
        }
    }
}
