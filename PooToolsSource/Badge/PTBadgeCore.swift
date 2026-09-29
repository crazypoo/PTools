import UIKit
import QuartzCore

// English: Shared badge metrics, animation, and drag behavior for every badge renderer.
// Español: Métricas, animación y arrastre compartidos para todos los renderizadores de insignias.
// 中文：为所有角标渲染器提供统一的尺寸、动画和拖拽行为。

@MainActor
public enum PTBadgeLayoutMetrics {
    public static func displayText(for content: PTBadgeContent,
                                   configuration: PTBadgeConfiguration) -> String? {
        PTBadgeMetrics.displayText(for: content, configuration: configuration)
    }

    public static func size(for content: PTBadgeContent,
                            configuration: PTBadgeConfiguration) -> CGSize {
        PTBadgeMetrics.size(for: content, configuration: configuration)
    }

    public static func cornerRadius(for size: CGSize,
                                    configuration: PTBadgeConfiguration) -> CGFloat {
        PTBadgeMetrics.cornerRadius(for: size, configuration: configuration)
    }
}

@MainActor
public enum PTBadgeAnimationDriver {
    public static func remove(from layer: CALayer?) {
        guard let layer else { return }
        for animationType in [PTBadgeAnimType.scale, .shake, .bounce, .breathe] {
            layer.removeAnimation(forKey: animationType.animationKey)
        }
    }

    public static func apply(to layer: CALayer?,
                             animation: PTBadgeAnimType,
                             isVisible: Bool,
                             isAttachedToWindow: Bool) {
        guard let layer, isVisible, isAttachedToWindow, !UIAccessibility.isReduceMotionEnabled else {
            remove(from: layer)
            return
        }

        remove(from: layer)
        switch animation {
        case .none:
            break
        case .scale:
            layer.add(CAAnimation.scale(fromScale: 1.4, toScale: 0.6, duration: 1, repeatCount: .infinity),
                      forKey: animation.animationKey)
        case .shake:
            layer.add(CAAnimation.shakeAnimation(repeatTimes: .infinity, duration: 1, offset: 5),
                      forKey: animation.animationKey)
        case .bounce:
            layer.add(CAAnimation.bounceAnimation(repeatTimes: .infinity, duration: 1, offset: 5),
                      forKey: animation.animationKey)
        case .breathe:
            layer.add(CAAnimation.opacityForeverAnimation(time: 1), forKey: animation.animationKey)
        }
    }
}

@MainActor
public final class PTBadgeInteractionController: NSObject {
    private weak var hostView: UIView?
    private weak var draggableView: UIView?
    private var gesture: UILongPressGestureRecognizer?
    private var disabledScrollViews: [UIScrollView: Bool] = [:]
    private var dragOriginCenter = CGPoint.zero
    private var dragOriginTouch = CGPoint.zero
    private var dragOriginTransform = CGAffineTransform.identity
    private let usesTransform: Bool
    private let removesViewOnDelete: Bool

    public var onRemove: (() -> Void)?

    public init(hostView: UIView?,
                draggableView: UIView,
                usesTransform: Bool = false,
                removesViewOnDelete: Bool = false) {
        self.hostView = hostView
        self.draggableView = draggableView
        self.usesTransform = usesTransform
        self.removesViewOnDelete = removesViewOnDelete
        super.init()
    }

    public func update(hostView: UIView?,
                       isEnabled: Bool,
                       longPressTime: TimeInterval) {
        self.hostView = hostView
        if let gesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }
        gesture = nil
        guard isEnabled, let draggableView else {
            self.draggableView?.isUserInteractionEnabled = false
            return
        }

        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handle(_:)))
        let duration = longPressTime.isFinite ? longPressTime : 0.5
        recognizer.minimumPressDuration = min(max(0.1, duration), 10)
        // English: Cancel the underlying cell touch after drag ownership begins.
        // Español: Cancela el toque subyacente de la celda cuando comienza el arrastre.
        // 中文：拖拽获得交互所有权后取消底层 Cell 的触摸，避免误触选择。
        recognizer.cancelsTouchesInView = true
        draggableView.isUserInteractionEnabled = true
        draggableView.addGestureRecognizer(recognizer)
        gesture = recognizer
    }

    public func invalidate() {
        if let gesture {
            gesture.view?.removeGestureRecognizer(gesture)
        }
        gesture = nil
        restoreScrollViews()
    }

    @objc private func handle(_ gesture: UILongPressGestureRecognizer) {
        guard let draggableView,
              let hostView = hostView ?? draggableView.superview else { return }

        switch gesture.state {
        case .began:
            dragOriginTouch = gesture.location(in: hostView)
            dragOriginCenter = draggableView.center
            dragOriginTransform = draggableView.transform
            disableAncestorScrollViews(from: hostView)
            PTBadgeAnimationDriver.remove(from: draggableView.layer)
        case .changed:
            let location = gesture.location(in: hostView)
            let delta = CGPoint(x: location.x - dragOriginTouch.x,
                                y: location.y - dragOriginTouch.y)
            if usesTransform {
                draggableView.transform = dragOriginTransform.concatenating(
                    CGAffineTransform(translationX: delta.x, y: delta.y)
                )
            } else {
                draggableView.center = CGPoint(x: dragOriginCenter.x + delta.x,
                                                y: dragOriginCenter.y + delta.y)
            }
        case .ended:
            let frame = draggableView.convert(draggableView.bounds, to: hostView)
            if hostView.bounds.intersects(frame) {
                restoreAfterDrag()
            } else {
                deleteAfterDrag()
            }
        case .cancelled, .failed:
            restoreAfterDrag()
        default:
            break
        }
    }

    private func disableAncestorScrollViews(from hostView: UIView) {
        disabledScrollViews.removeAll(keepingCapacity: true)
        var current: UIView? = hostView
        while let view = current {
            if let scrollView = view as? UIScrollView {
                disabledScrollViews[scrollView] = scrollView.isScrollEnabled
                scrollView.isScrollEnabled = false
            }
            current = view.superview
        }
    }

    private func restoreScrollViews() {
        disabledScrollViews.forEach { $0.key.isScrollEnabled = $0.value }
        disabledScrollViews.removeAll(keepingCapacity: true)
    }

    private func restoreAfterDrag() {
        guard let draggableView else {
            restoreScrollViews()
            return
        }
        let animations = {
            if self.usesTransform {
                draggableView.transform = self.dragOriginTransform
            } else {
                draggableView.center = self.dragOriginCenter
            }
        }
        if UIAccessibility.isReduceMotionEnabled {
            animations()
        } else {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 0.5,
                           options: [.beginFromCurrentState, .allowUserInteraction],
                           animations: animations)
        }
        restoreScrollViews()
    }

    private func deleteAfterDrag() {
        guard let draggableView else {
            restoreScrollViews()
            return
        }

        let finish = {
            draggableView.transform = self.usesTransform
                ? self.dragOriginTransform.concatenating(CGAffineTransform(scaleX: 0.1, y: 0.1))
                : CGAffineTransform(scaleX: 0.1, y: 0.1)
            draggableView.alpha = 0
        }
        let completed = {
            if self.removesViewOnDelete {
                draggableView.removeFromSuperview()
            } else {
                draggableView.isHidden = true
            }
            self.restoreScrollViews()
            self.onRemove?()
        }
        if UIAccessibility.isReduceMotionEnabled {
            finish()
            completed()
        } else {
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: [.beginFromCurrentState, .allowUserInteraction],
                           animations: finish) { _ in
                completed()
            }
        }
    }
}
