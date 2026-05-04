//
//  UIView+PTEXShake.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 4/5/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

/// 抖动方向枚举
public enum PTShakeDirection {
    /// 水平左右抖动
    case horizontal
    /// 垂直上下抖动
    case vertical
}

public extension UIView {
    
    /// 为 View 添加抖动动画 (基于闭包回调)
    ///
    /// - Parameters:
    ///   - times: 抖动的次数 (默认 5 次)
    ///   - delta: 抖动的幅度，即偏移的像素值 (默认 5.0)
    ///   - speed: 单次抖动方向持续的时间 (默认 0.03 秒)
    ///   - direction: 抖动方向 (默认水平抖动)
    ///   - completion: 动画结束后的回调闭包
    func shake(times: Int = 5,
               delta: CGFloat = 5.0,
               speed: TimeInterval = 0.03,
               direction: PTShakeDirection = PTShakeDirection.horizontal,
               completion: (() -> Void)? = nil) {
        // 核心修复：记录 View 当前的 transform，避免动画覆盖掉已有的缩放或旋转
        let originalTransform = self.transform
        
        // 内部递归函数，用于控制动画的执行顺序和次数
        func performShake(current: Int, currentDirection: CGFloat) {
            UIView.animate(withDuration: speed, delay: 0, options: [.curveEaseInOut], animations: {
                // 使用 translatedBy 进行相对位移，而不是绝对赋值
                if direction == .horizontal {
                    self.transform = originalTransform.translatedBy(x: delta * currentDirection, y: 0)
                } else {
                    self.transform = originalTransform.translatedBy(x: 0, y: delta * currentDirection)
                }
            }) { _ in
                // 如果达到了指定次数，则恢复原始状态并执行回调
                if current >= times {
                    UIView.animate(withDuration: speed, animations: {
                        self.transform = originalTransform
                    }) { _ in
                        completion?()
                    }
                    return
                }
                
                // 递归调用，反转方向
                performShake(current: current + 1, currentDirection: currentDirection * -1)
            }
        }
        
        // 从第 0 次开始触发，初始方向因子为 1
        performShake(current: 0, currentDirection: 1)
    }
    
    /// 为 View 添加抖动动画 (基于 iOS 15+ async/await 现代并发模型)
    /// 提供与 Swift Actor 模型兼容的异步调用方式，避免在复杂业务逻辑中出现多层闭包嵌套 (Callback Hell)。
    @available(iOS 15.0, *)
    @MainActor
    func shakeAsync(times: Int = 5,
                    delta: CGFloat = 5.0,
                    speed: TimeInterval = 0.03,
                    direction: PTShakeDirection = PTShakeDirection.horizontal) async {
        // 使用 Continuation 将传统的回调转换为异步任务
        await withCheckedContinuation { continuation in
            self.shake(times: times, delta: delta, speed: speed, direction: direction) {
                continuation.resume()
            }
        }
    }
}
