//
//  PTSideMenuBasicTransitionAnimator.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

// 一个简单的过渡动画器可以配置动画选项。
public class PTSideMenuBasicTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let animationOptions: UIView.AnimationOptions
    let duration: TimeInterval

    /// 用动画选项和持续时间初始化一个新的动画。
    /// - Parameters:
    ///   - options: 动画选项
    ///   - duration: 动画持续时间
    public init(options: UIView.AnimationOptions = .transitionCrossDissolve, duration: TimeInterval = 0.4) {
        self.animationOptions = options
        self.duration = duration
    }

    // MARK: UIViewControllerAnimatedTransitioning
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
            let toViewController = transitionContext.viewController(forKey: .to) else {
                return
        }

        transitionContext.containerView.addSubview(toViewController.view)

        let duration = transitionDuration(using: transitionContext)

        UIView.transition(from: fromViewController.view,
                          to: toViewController.view,
                          duration: duration,
                          options: animationOptions,
                          completion: { (_) in
                            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
