// English: Shared property-animator transitions for overlay presentation.
// Español: Transiciones compartidas con property animator para overlays.
// 中文：浮层展示使用的统一 Property Animator 转场。

import UIKit

public enum PTOverlayTransition: Sendable {
    case fade
    case scale
    case slideFromTop
    case slideFromBottom
    case spring
    case none
}

@MainActor
public final class PTOverlayAnimator {
    public private(set) var animator: UIViewPropertyAnimator?

    public init() {}

    public func present(view: UIView,
                        transition: PTOverlayTransition,
                        completion: (@MainActor @Sendable () -> Void)? = nil) {
        animator?.stopAnimation(true)
        let resolvedTransition = UIAccessibility.isReduceMotionEnabled ? .fade : transition
        view.superview?.layoutIfNeeded()
        view.alpha = resolvedTransition == .fade ? 0 : 1
        switch resolvedTransition {
        case .scale:
            view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        case .slideFromTop:
            view.transform = CGAffineTransform(translationX: 0, y: -max(view.bounds.height, 44) - 12)
        case .slideFromBottom:
            view.transform = CGAffineTransform(translationX: 0, y: max(view.bounds.height, 44) + 12)
        default:
            view.transform = .identity
        }

        let timing: UITimingCurveProvider = resolvedTransition == .spring
            ? UISpringTimingParameters(dampingRatio: 0.86)
            : UICubicTimingParameters(animationCurve: .easeOut)
        let animator = UIViewPropertyAnimator(duration: resolvedTransition == .none ? 0 : 0.28,
                                              timingParameters: timing)
        animator.addAnimations {
            view.alpha = 1
            view.transform = .identity
        }
        animator.addCompletion { _ in completion?() }
        self.animator = animator
        animator.startAnimation()
    }

    public func dismiss(view: UIView,
                        transition: PTOverlayTransition,
                        completion: (@MainActor @Sendable () -> Void)? = nil) {
        animator?.stopAnimation(true)
        let resolvedTransition = UIAccessibility.isReduceMotionEnabled ? .fade : transition
        let timing = UICubicTimingParameters(animationCurve: .easeIn)
        let animator = UIViewPropertyAnimator(duration: resolvedTransition == .none ? 0 : 0.22,
                                              timingParameters: timing)
        animator.addAnimations {
            view.alpha = resolvedTransition == .fade ? 0 : 0.98
            switch resolvedTransition {
            case .slideFromTop:
                view.transform = CGAffineTransform(translationX: 0, y: -max(view.bounds.height, 44) - 12)
            case .slideFromBottom:
                view.transform = CGAffineTransform(translationX: 0, y: max(view.bounds.height, 44) + 12)
            case .scale:
                view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            default:
                break
            }
        }
        animator.addCompletion { _ in completion?() }
        self.animator = animator
        animator.startAnimation()
    }

    public func stop() {
        animator?.stopAnimation(true)
        animator = nil
    }
}
