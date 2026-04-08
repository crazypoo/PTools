//
//  CAAnimation+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

// MARK: - Enums

/// 旋转轴类型
public enum PTAxisType {
    case x, y, z
    
    // 直接绑定 keyPath，避免数组越界的风险
    var keyPath: String {
        switch self {
        case .x: return "transform.rotation.x"
        case .y: return "transform.rotation.y"
        case .z: return "transform.rotation.z"
        }
    }
}

// MARK: - CAAnimation Extension

extension CAAnimation {
    
    /// 永久透明度动画 (呼吸/闪烁)
    public class func opacityForeverAnimation(time: CFTimeInterval) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.1
        animation.autoreverses = true
        animation.duration = time
        animation.repeatCount = .infinity // 使用更语义化的 .infinity
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .forwards
        return animation
    }
    
    /// 指定次数的透明度动画
    public class func opacityTimesAnimation(repeatTimes: Float, time: CFTimeInterval) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.4
        animation.repeatCount = repeatTimes
        animation.duration = time
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animation.fillMode = .forwards
        animation.autoreverses = true
        return animation
    }
    
    /// 旋转动画
    public class func rotation(duration: CFTimeInterval, degree: Float, direction: PTAxisType, repeatCount: Float) -> CABasicAnimation {
        // 直接使用枚举的 keyPath
        let animation = CABasicAnimation(keyPath: direction.keyPath)
        animation.fromValue = 0
        animation.toValue = degree
        animation.duration = duration
        animation.autoreverses = false
        animation.isCumulative = true
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.repeatCount = repeatCount
        return animation
    }
    
    /// 缩放动画
    public class func scale(fromScale: Float, toScale: Float, duration: CFTimeInterval, repeatCount: Float) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = fromScale
        animation.toValue = toScale
        animation.duration = duration
        animation.autoreverses = true
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.repeatCount = repeatCount
        return animation
    }
    
    /// 左右抖动动画 (优化版：不再依赖 CALayer 的绝对位置)
    /// - Parameters:
    ///   - offset: 抖动的偏移量(像素)
    public class func shakeAnimation(repeatTimes: Float, duration: CFTimeInterval, offset: CGFloat = 5.0) -> CAKeyframeAnimation {
        // 使用 transform.translation.x 进行相对位移，兼容 AutoLayout
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [0, -offset, 0, offset, 0]
        anim.repeatCount = repeatTimes
        anim.duration = duration
        anim.isRemovedOnCompletion = false
        anim.fillMode = .forwards
        return anim
    }
    
    /// 上下跳动动画 (优化版：不再依赖 CALayer 的绝对位置)
    /// - Parameters:
    ///   - offset: 跳动的偏移高度(像素)
    public class func bounceAnimation(repeatTimes: Float, duration: CFTimeInterval, offset: CGFloat = 5.0) -> CAKeyframeAnimation {
        // 使用 transform.translation.y 进行相对位移，兼容 AutoLayout
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.y")
        anim.values = [0, -offset, 0, offset, 0]
        anim.repeatCount = repeatTimes
        anim.duration = duration
        anim.isRemovedOnCompletion = false
        anim.fillMode = .forwards
        return anim
    }
}
