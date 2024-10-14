//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

private extension ElementInspectorSlidingPanelAnimator {
    final class BackgroundGestureView: BaseView {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let result = super.hitTest(point, with: event)

            guard result === self else { return result }

            guard let rootView = window?.rootViewController?.view else { return nil }

            let localPoint = convert(point, to: rootView)

            let rootResult = rootView.hitTest(localPoint, with: event)

            return rootResult
        }
    }

    final class DropShadowView: BaseView {
        override func setup() {
            layer.shadowRadius = elementInspectorAppearance.elementInspectorCornerRadius
            layer.shadowColor = UIColor(white: 0, alpha: 0.5).cgColor
        }

        override func layoutSubviews() {
            super.layoutSubviews()
        }
    }
}

final class ElementInspectorSlidingPanelAnimator: NSObject, ElementInspectorAppearanceProviding, UIViewControllerAnimatedTransitioning {
    let duration: TimeInterval = .veryLong

    var isPresenting: Bool = true

    private var isObservingSize = false

    private lazy var backgroundGestureView = BackgroundGestureView().then {
        $0.addObserver(self, forKeyPath: .bounds, options: .new, context: nil)
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let containerView = shadowView.superview else { return }

        shadowView.frame = topLeftMargins(of: containerView)
    }

    deinit {
        backgroundGestureView.removeObserver(self, forKeyPath: .bounds, context: nil)
    }

    private lazy var shadowView = DropShadowView()

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)
        -> TimeInterval
    {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            pushTransition(using: transitionContext)
        }
        else {
            popTransition(using: transitionContext)
        }
    }

    private func frameToTheRight(of containerView: UIView) -> CGRect {
        var frame = containerView.bounds.inset(by: elementInspectorAppearance.directionalInsets.edgeInsets())
        frame.size.width = Inspector.sharedInstance.configuration.elementInspectorConfiguration.panelPreferredCompressedSize.width
        frame.size.height = min(frame.size.height, Inspector.sharedInstance.configuration.elementInspectorConfiguration.panelSidePresentationMinimumContainerSize.height)
        frame.origin.x = containerView.bounds.maxX

        return frame
    }

    private func topLeftMargins(of containerView: UIView) -> CGRect {
        var frame = containerView.bounds.inset(by: elementInspectorAppearance.directionalInsets.edgeInsets())
        frame.size.width = Inspector.sharedInstance.configuration.elementInspectorConfiguration.panelPreferredCompressedSize.width
        frame.size.height = min(frame.size.height, Inspector.sharedInstance.configuration.elementInspectorConfiguration.panelSidePresentationMinimumContainerSize.height)
        frame.origin.x = containerView.bounds.maxX - frame.width
        frame = frame.inset(by: elementInspectorAppearance.directionalInsets.edgeInsets())

        return frame
    }

    private func pushTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let toView = transitionContext.view(forKey: .to) else { return }

        let toStartFrame = frameToTheRight(of: containerView)

        shadowView.installView(toView, priority: .required)
        containerView.addSubview(shadowView)
        shadowView.frame = toStartFrame
        shadowView.layer.shadowOpacity = 0

        let toFinalFrame = topLeftMargins(of: containerView)

        toView.layer.cornerRadius = elementInspectorAppearance.elementInspectorCornerRadius
        toView.layer.cornerCurve = .continuous

        backgroundGestureView.alpha = 0
        containerView.installView(backgroundGestureView, position: .behind)

        animate(withDuration: duration) {
            self.shadowView.frame = toFinalFrame
            self.shadowView.layer.shadowOpacity = 1
            self.backgroundGestureView.alpha = 1
        } completion: { finish in
            transitionContext.completeTransition(finish)
        }
    }

    private func popTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }

        fromView.layer.cornerRadius = .zero

        var fromFinalFrame = shadowView.frame
        fromFinalFrame.origin.x = transitionContext.containerView.bounds.maxX

        animate(withDuration: duration) {
            self.shadowView.frame = fromFinalFrame
            self.shadowView.layer.shadowOpacity = 0
            self.backgroundGestureView.alpha = 0
        } completion: { finish in
            if finish {
                self.backgroundGestureView.removeFromSuperview()
            }
            else {
                self.backgroundGestureView.alpha = 1
            }
            transitionContext.completeTransition(finish)
        }
    }
}

private extension String {
    static let bounds = "bounds"
}
