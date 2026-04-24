//
//  PTListAnimation.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

// 优化：协议名称改为单数，符合 Swift API 设计规范
public protocol PTListAnimationProtocol {
    var initialTransform: CGAffineTransform { get }
}

// 优化：将 class 改为无 case 的 enum，作为纯命名空间，防止被意外实例化
public enum PTListAnimationConfig {
    /// 移动的距离（点数）
    public static var offset: CGFloat = 30.0
    /// 动画持续时间
    public static var duration: Double = 0.3
    /// 多视图连续动画的时间间隔
    public static var interval: Double = 0.075
    /// 随机缩放动画的最大缩放比例
    public static var maxZoomScale: Double = 2.0
    /// 随机旋转动画的最大旋转角度 (左右)
    public static var maxRotationAngle: CGFloat = CGFloat.pi / 4
    /// 弹簧动画的阻尼系数
    public static var springDampingRatio: CGFloat = 1
    /// 弹簧动画的初始速度
    public static var initialSpringVelocity: CGFloat = 0
}

public enum PTListAnimationDirection: Int, CaseIterable {
    case top
    case left
    case right
    case bottom
    
    var isVertical: Bool {
        switch self {
        case .top, .bottom: return true
        default: return false
        }
    }
    
    var sign: CGFloat {
        switch self {
        case .top, .left: return -1
        default: return 1
        }
    }
    
    static func random() -> PTListAnimationDirection {
        return allCases.randomElement()!
    }
}

public enum PTListAnimationType: PTListAnimationProtocol {
    // 优化：修复了 direction 的拼写错误 (原为 direcation)
    case from(direction: PTListAnimationDirection, offset: CGFloat)
    case vector(CGVector)
    case zoom(scale: CGFloat)
    case rotate(angle: CGFloat)
    case identity
    // 补充：自定义 3D 翻转等高级动画可以通过这里扩展，这里以简单的透明度标识为例（配合外部 alpha 控制）
    case fade
    
    public var initialTransform: CGAffineTransform {
        switch self {
        case .from(let direction, let offset):
            let sign = direction.sign
            if direction.isVertical {
                return CGAffineTransform(translationX: 0, y: offset * sign)
            }
            return CGAffineTransform(translationX: offset * sign, y: 0)
        case .vector(let vector):
            return CGAffineTransform(translationX: vector.dx, y: vector.dy)
        case .zoom(let scale):
            return CGAffineTransform(scaleX: scale, y: scale)
        case .rotate(let angle):
            return CGAffineTransform(rotationAngle: angle)
        case .identity, .fade:
            return .identity
        }
    }
    
    public static func random() -> PTListAnimationType {
        let index = Int.random(in: 0..<3)
        switch index {
        case 0:
            let angle = CGFloat.random(in: -PTListAnimationConfig.maxRotationAngle...PTListAnimationConfig.maxRotationAngle)
            return .rotate(angle: angle)
        case 1:
            return .vector(CGVector(dx: .random(in: -10...10), dy: .random(in: -30...30)))
        default:
            let scale = Double.random(in: 0...PTListAnimationConfig.maxZoomScale)
            return .zoom(scale: CGFloat(scale))
        }
    }
}

// MARK: - UICollectionView / UITableView Extensions
public extension UICollectionView {
    var orderedVisibleCells: [UICollectionViewCell] {
        indexPathsForVisibleItems.sorted().compactMap { cellForItem(at: $0) }
    }
    
    func visibleCells(in section: Int) -> [UICollectionViewCell] {
        visibleCells.filter { indexPath(for: $0)?.section == section }
    }
}

public extension UITableView {
    func visibleCells(in section: Int) -> [UITableViewCell] {
        visibleCells.filter { indexPath(for: $0)?.section == section }
    }
}

// MARK: - UIView Extensions
public extension UIView {
    
    // MARK: - Single View Standard Animation
    func animate(animations: [PTListAnimationProtocol],
                 reversed: Bool = false,
                 initialAlpha: CGFloat = 0,
                 finalAlpha: CGFloat = 1,
                 delay: Double = 0,
                 duration: TimeInterval = PTListAnimationConfig.duration,
                 options: UIView.AnimationOptions = [],
                 completion: PTActionTask? = nil) {
        
        let transformFrom = transform
        var transformTo = transform
        animations.forEach { transformTo = transformTo.concatenating($0.initialTransform) }
        
        if !reversed { transform = transformTo }
        alpha = initialAlpha
        
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: {
            self.transform = reversed ? transformTo : transformFrom
            self.alpha = finalAlpha
        }) { _ in
            completion?()
        }
    }
    
    // MARK: - Single View Spring Animation
    func animate(animations: [PTListAnimationProtocol],
                 reversed: Bool = false,
                 initialAlpha: CGFloat = 0.0,
                 finalAlpha: CGFloat = 1.0,
                 delay: Double = 0,
                 duration: TimeInterval = PTListAnimationConfig.duration,
                 usingSpringWithDamping dampingRatio: CGFloat,
                 initialSpringVelocity velocity: CGFloat,
                 options: UIView.AnimationOptions = [],
                 completion: PTActionTask? = nil) {
        
        let transformFrom = transform
        var transformTo = transform
        animations.forEach { transformTo = transformTo.concatenating($0.initialTransform) }
        
        if !reversed { transform = transformTo }
        alpha = initialAlpha
        
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: dampingRatio, initialSpringVelocity: velocity, options: options, animations: {
            self.transform = reversed ? transformTo : transformFrom
            self.alpha = finalAlpha
        }) { _ in
            completion?()
        }
    }
    
    // MARK: - KeyFrame Animation
    func animateKeyFrames(animations: [PTListAnimationProtocol],
                          initialAlpha: CGFloat = 0.0,
                          finalAlpha: CGFloat = 1.0,
                          delay: Double = 0,
                          duration: TimeInterval = PTListAnimationConfig.duration,
                          options: UIView.KeyframeAnimationOptions = [],
                          completion: PTActionTask? = nil) {
        
        let numberOfFrames: Int = animations.count
        guard numberOfFrames > 0 else {
            completion?()
            return
        }
        
        let singleFrameDuration = 1.0 / Double(numberOfFrames)
        alpha = initialAlpha
        
        UIView.animateKeyframes(withDuration: duration, delay: delay, options: options, animations: {
            for (index, animation) in animations.enumerated() {
                let frameDurationStartTime = index == 0 ? 0.0 : singleFrameDuration * Double(index)
                let frameAlphaValue = initialAlpha + ((finalAlpha - initialAlpha) * CGFloat(frameDurationStartTime))
                
                UIView.addKeyframe(withRelativeStartTime: frameDurationStartTime, relativeDuration: singleFrameDuration) {
                    self.transform = animation.initialTransform
                    self.alpha = frameAlphaValue
                }
            }
            // 回归初始状态
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0) {
                self.transform = .identity
                self.alpha = finalAlpha
            }
        }) { _ in
            // 确保在主线程回调，移除 Task 包装，因为 UIView 动画回调天然在主线程
            PTGCDManager.gcdMain(block: {
                completion?()
            })
        }
    }
    
    // MARK: - Multi-View Cascade Animations
    static func animate(views: [UIView],
                        animations: [PTListAnimationProtocol],
                        reversed: Bool = false,
                        initialAlpha: CGFloat = 0.0,
                        finalAlpha: CGFloat = 1.0,
                        delay: Double = 0,
                        animationInterval: TimeInterval = 0.05,
                        duration: TimeInterval = PTListAnimationConfig.duration,
                        options: UIView.AnimationOptions = [],
                        completion: PTActionTask? = nil) {
        
        performAnimation(views: views, animations: animations, reversed: reversed, initialAlpha: initialAlpha, delay: delay) { view, index, dispatchGroup in
            view.animate(animations: animations,
                         reversed: reversed,
                         initialAlpha: initialAlpha,
                         finalAlpha: finalAlpha,
                         delay: Double(index) * animationInterval,
                         duration: duration,
                         options: options,
                         completion: { dispatchGroup.leave() })
        } completion: {
            completion?()
        }
    }
    
    static func animate(views: [UIView],
                        animations: [PTListAnimationProtocol],
                        reversed: Bool = false,
                        initialAlpha: CGFloat = 0.0,
                        finalAlpha: CGFloat = 1.0,
                        delay: Double = 0,
                        animationInterval: TimeInterval = 0.05,
                        duration: TimeInterval = PTListAnimationConfig.duration,
                        usingSpringWithDamping dampingRatio: CGFloat,
                        initialSpringVelocity velocity: CGFloat,
                        options: UIView.AnimationOptions = [],
                        completion: PTActionTask? = nil) {
        
        performAnimation(views: views, animations: animations, reversed: reversed, initialAlpha: initialAlpha, delay: delay) { view, index, dispatchGroup in
            view.animate(animations: animations,
                         reversed: reversed,
                         initialAlpha: initialAlpha,
                         finalAlpha: finalAlpha,
                         delay: Double(index) * animationInterval,
                         duration: duration,
                         usingSpringWithDamping: dampingRatio,
                         initialSpringVelocity: velocity,
                         options: options,
                         completion: { dispatchGroup.leave() })
        } completion: {
            completion?()
        }
    }
    
    static private func performAnimation(views: [UIView],
                                         animations: [PTListAnimationProtocol],
                                         reversed: Bool = false,
                                         initialAlpha: CGFloat = 0.0,
                                         delay: Double = 0,
                                         animationBlock: @escaping ((UIView, Int, DispatchGroup) -> Void),
                                         completion: PTActionTask? = nil) {
        guard !views.isEmpty else {
            completion?()
            return
        }
        
        views.forEach { $0.alpha = initialAlpha }
        let dispatchGroup = DispatchGroup()
        
        for _ in views { dispatchGroup.enter() }
        
        // 优化：替换自定义的 PTGCDManager 为原生的 GCD，降低模块耦合
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            for (index, view) in views.enumerated() {
                animationBlock(view, index, dispatchGroup)
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion?()
        }
    }
}

// MARK: - Modern Concurrency (Async/Await) 支持 🌟
public extension UIView {
    /// 异步执行标准视图动画
    @MainActor
    func animateAsync(animations: [PTListAnimationProtocol],
                      reversed: Bool = false,
                      initialAlpha: CGFloat = 0,
                      finalAlpha: CGFloat = 1,
                      delay: Double = 0,
                      duration: TimeInterval = PTListAnimationConfig.duration,
                      options: UIView.AnimationOptions = []) async {
        await withCheckedContinuation { continuation in
            animate(animations: animations, reversed: reversed, initialAlpha: initialAlpha, finalAlpha: finalAlpha, delay: delay, duration: duration, options: options) {
                continuation.resume()
            }
        }
    }
    
    /// 异步执行多视图级联动画
    @MainActor
    static func animateAsync(views: [UIView],
                             animations: [PTListAnimationProtocol],
                             reversed: Bool = false,
                             initialAlpha: CGFloat = 0.0,
                             finalAlpha: CGFloat = 1.0,
                             delay: Double = 0,
                             animationInterval: TimeInterval = 0.05,
                             duration: TimeInterval = PTListAnimationConfig.duration,
                             options: UIView.AnimationOptions = []) async {
        await withCheckedContinuation { continuation in
            animate(views: views, animations: animations, reversed: reversed, initialAlpha: initialAlpha, finalAlpha: finalAlpha, delay: delay, animationInterval: animationInterval, duration: duration, options: options) {
                continuation.resume()
            }
        }
    }
}
