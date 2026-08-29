//
//  PTAnimationFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public let PTAnimationDuration = 0.35

// Native completion callback for UIKit animations.
// Callback de finalización nativo para las animaciones de UIKit.
// UIKit 原生动画完成回调。
public typealias PTNativeAnimationCompletion = @MainActor @Sendable (_ finished: Bool) -> Void

public class PTAnimationFunction: NSObject {
    // English: Normalize caller-provided durations before handing them to UIKit.
    // Español: Normaliza las duraciones recibidas antes de pasarlas a UIKit.
    // 中文：在交给 UIKit 前统一规范调用方传入的动画时长。
    @MainActor private class func safeDuration(_ value: CGFloat) -> TimeInterval {
        guard value.isFinite else { return 0 }
        return max(0, TimeInterval(value))
    }

    @MainActor public class func animationIn(animationView:UIView,
                                  animationType:PTAlertAnimationType,
                                  transformValue:CGFloat,
                                  completion: PTNativeAnimationCompletion? = nil) {
        var transform = CGAffineTransform.identity
        
        switch animationType {
        case .Top:
            transform = CGAffineTransform(translationX: 0, y: -abs(transformValue))
        case .Bottom:
            transform = CGAffineTransform(translationX: 0, y: transformValue)
        case .Left:
            transform = CGAffineTransform(translationX: -abs(transformValue), y: 0)
        case .Right:
            transform = CGAffineTransform(translationX: transformValue, y: 0)
        default: break
        }

        if UIAccessibility.isReduceMotionEnabled {
            animationView.transform = .identity
            completion?(true)
            return
        }

        // Use one UIKit spring animation so transform state stays on the view and is easy to cancel.
        // Usa una sola animación de resorte de UIKit para que el estado quede en la vista y sea fácil de cancelar.
        // 使用单个 UIKit 弹簧动画，让位移状态保留在 View 上并便于取消。
        animationView.transform = transform
        UIView.animate(withDuration: PTAnimationDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.8,
                       options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                       animations: {
            animationView.transform = .identity
        }, completion: { finished in
            completion?(finished)
        })
    }
    
    @MainActor public class func animationOut(animationView:UIView,
                                              animationType:PTAlertAnimationType,
                                              toValue:CGFloat = 0,
                                              duration:CGFloat = PTAnimationDuration,
                                              animation: @escaping PTActionTask,
                                              completion: @escaping PTBoolTask) {
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        switch animationType {
        case .Top:
            offsetY = toValue > 0 ? toValue : -animationView.layer.position.y
        case .Bottom:
            offsetY = toValue > 0 ? toValue : animationView.layer.position.y + animationView.frame.size.height
        case .Left:
            offsetX = toValue > 0 ? toValue : -animationView.layer.position.x - animationView.frame.size.width / 2
        case .Right:
            offsetX = toValue > 0 ? toValue : animationView.layer.position.x + animationView.frame.size.width / 2
        default:
            offsetX = -animationView.layer.position.x
        }

        let targetTransform = CGAffineTransform(translationX: offsetX, y: offsetY)
        let resolvedDuration = PTAnimationFunction.safeDuration(duration)

        if UIAccessibility.isReduceMotionEnabled || resolvedDuration == 0 {
            animationView.transform = targetTransform
            animation()
            completion(true)
            return
        }

        // Keep the two-stage behavior: move off-screen first, then run the caller's cleanup animation.
        // Mantén el comportamiento en dos etapas: salir de pantalla y después ejecutar la limpieza del llamador.
        // 保留两阶段行为：先移出屏幕，再执行调用方的清理动画。
        UIView.animate(withDuration: resolvedDuration,
                       delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction, .layoutSubviews],
                       animations: {
            animationView.transform = targetTransform
                       }, completion: { finished in
            guard finished else {
                completion(false)
                return
            }
            UIView.animate(withDuration: resolvedDuration,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: 0.7,
                           options: [.curveEaseOut, .beginFromCurrentState, .layoutSubviews],
                           animations: {
                animation()
            }, completion: { finished in
                completion(finished)
            })
        })
    }
}
