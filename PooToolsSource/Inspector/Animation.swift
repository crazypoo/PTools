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
        completion: ((Bool) -> Void)? = nil) {
        transform = fromAnimation.transform

        animate(toAnimation, duration: duration, delay: delay, completion: completion)
    }

    func animate(
        _ animation: Animation,
        duration: TimeInterval = .average,
        delay: TimeInterval = .zero,
        completion: ((Bool) -> Void)? = nil) {
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
    func animate(withDuration duration: TimeInterval = .average,
                 delay: TimeInterval = .zero,
                 damping: CGFloat = Animation.defaultDamping,
                 options: UIView.AnimationOptions = Animation.defaultOptions,
                 animations: @escaping PTActionTask,
                 completion: ((Bool) -> Void)? = nil) {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: damping,
            initialSpringVelocity: Animation.defaultVelocity,
            options: options,
            animations: animations,
            completion: completion
        )
    }
}
