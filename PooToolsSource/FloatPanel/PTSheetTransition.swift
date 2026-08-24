//
//  PTSheetTransition.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

/// 保存 Presenter 在面板转场前的状态，关闭时按原值恢复。
@MainActor
private final class PTPresenterSnapshot {
    weak var controller: UIViewController?
    let transform: CATransform3D
    let cornerRadius: CGFloat
    let masksToBounds: Bool

    init(controller: UIViewController) {
        self.controller = controller
        self.transform = controller.view.layer.transform
        self.cornerRadius = controller.view.layer.cornerRadius
        self.masksToBounds = controller.view.layer.masksToBounds
    }
}

@MainActor
public class PTSheetTransition: NSObject, UIViewControllerAnimatedTransitioning {

    var presenting = true
    weak var presenter: UIViewController?
    let options: PTSheetOptions
    private var presenterSnapshot: PTPresenterSnapshot?

    /// 嵌套面板只保存弱引用，避免转场缓存延长控制器生命周期。
    private static var currentPresenters: [PTPresenterSnapshot] = []

    init(options: PTSheetOptions) {
        self.options = options.normalized()
        super.init()
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        let duration = self.options.transitionDuration
        if UIAccessibility.isReduceMotionEnabled {
            return min(max(duration, 0), 0.15)
        }
        return min(max(duration, 0), 2)
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if self.presenting {
            self.animatePresentation(using: transitionContext)
        } else {
            self.animateDismissal(using: transitionContext)
        }
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let presenter = transitionContext.viewController(forKey: .from),
              let sheet = transitionContext.viewController(forKey: .to) as? PTSheetViewController else {
            transitionContext.completeTransition(false)
            return
        }

        self.presenter = presenter
        let snapshot = PTPresenterSnapshot(controller: presenter)
        self.presenterSnapshot = snapshot

        if PTSheetOptions.shrinkingNestedPresentingViewControllers {
            Self.currentPresenters.removeAll { $0.controller == nil }
            Self.currentPresenters.append(snapshot)
        }

        if sheet.view.superview !== containerView {
            containerView.addSubview(sheet.view)
        }
        sheet.view.frame = containerView.bounds
        sheet.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sheet.view.layoutIfNeeded()
        sheet.contentViewController.updatePreferredHeight()
        sheet.resize(to: sheet.currentSize, animated: false)

        let contentView = sheet.contentViewController.contentView
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        contentView.transform = reduceMotion ? .identity : CGAffineTransform(translationX: 0, y: contentView.bounds.height)
        contentView.alpha = reduceMotion ? 0 : 1
        sheet.overlayView.alpha = 0

        let containerHeight = max(containerView.bounds.height, 1)
        let heightPercent = min(max(contentView.bounds.height / containerHeight, 0), 1)
        let duration = self.transitionDuration(using: transitionContext)
        let damping = self.normalizedDamping(for: heightPercent)
        let velocity = self.options.transitionVelocity * heightPercent

        UIView.animate(
            withDuration: duration * 0.6,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                if self.options.shrinkPresentingViewController || PTSheetOptions.shrinkingNestedPresentingViewControllers {
                    self.setPresenter(percentComplete: 0)
                }
                sheet.overlayView.alpha = 1
            }
        )

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: self.options.transitionAnimationOptions,
            animations: {
                if UIAccessibility.isReduceMotionEnabled {
                    contentView.alpha = 1
                } else {
                    contentView.transform = .identity
                }
            },
            completion: { _ in
                let completed = !transitionContext.transitionWasCancelled
                if !completed {
                    contentView.transform = .identity
                    contentView.alpha = 1
                    sheet.overlayView.alpha = 1
                    self.restorePresenterImmediately()
                    if PTSheetOptions.shrinkingNestedPresentingViewControllers {
                        self.setPresenter(percentComplete: 0)
                    }
                    self.removePresenterSnapshot(for: presenter)
                }
                transitionContext.completeTransition(completed)
                if completed {
                    UIAccessibility.post(notification: .screenChanged, argument: sheet.contentViewController.view)
                }
            }
        )
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let presenter = transitionContext.viewController(forKey: .to),
              let sheet = transitionContext.viewController(forKey: .from) as? PTSheetViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let contentView = sheet.contentViewController.contentView
        let animations: @MainActor () -> Void = {
            if UIAccessibility.isReduceMotionEnabled {
                contentView.alpha = 0
            } else {
                contentView.transform = CGAffineTransform(translationX: 0, y: max(contentView.bounds.height, containerView.bounds.height))
            }
            sheet.overlayView.alpha = 0
        }

        let finish: @MainActor (Bool) -> Void = { [weak self, weak presenter] animationCompleted in
            guard let self = self else { return }
            let completed = animationCompleted && !transitionContext.transitionWasCancelled
            if completed {
                self.removePresenterSnapshot(for: presenter)
            } else {
                contentView.transform = .identity
                contentView.alpha = 1
                sheet.overlayView.alpha = 1
                self.setPresenter(percentComplete: 0)
            }
            transitionContext.completeTransition(completed)
            sheet.transitionDidFinishDismissal(completed: completed)
        }

        if self.options.shrinkPresentingViewController || PTSheetOptions.shrinkingNestedPresentingViewControllers {
            self.restorePresenter(presenter, animated: true, animations: animations, completion: finish)
        } else {
            UIView.animate(
                withDuration: self.transitionDuration(using: transitionContext),
                delay: 0,
                options: self.options.transitionAnimationOptions,
                animations: animations,
                completion: finish
            )
        }
    }

    private func normalizedDamping(for heightPercent: CGFloat) -> CGFloat {
        let adjustment = (heightPercent - 0.2) * 1.25 * 0.17
        return min(max(self.options.transitionDampening + adjustment, 0.01), 1)
    }

    private func snapshot(for presenter: UIViewController) -> PTPresenterSnapshot? {
        if let presenterSnapshot, presenterSnapshot.controller === presenter {
            return presenterSnapshot
        }
        return Self.currentPresenters.first { $0.controller === presenter }
    }

    private func removePresenterSnapshot(for presenter: UIViewController?) {
        guard let presenter else { return }
        Self.currentPresenters.removeAll { $0.controller === presenter || $0.controller == nil }
        if self.presenterSnapshot?.controller === presenter {
            self.presenterSnapshot = nil
        }
    }

    private func restorePresenterImmediately() {
        guard let presenter = self.presenter,
              let snapshot = self.snapshot(for: presenter) else { return }
        presenter.view.layer.transform = snapshot.transform
        presenter.view.layer.cornerRadius = snapshot.cornerRadius
        presenter.view.layer.masksToBounds = snapshot.masksToBounds
    }

    /// 恢复 Presenter 的视图状态。
    func restorePresenter(_ presenter: UIViewController, animated: Bool = true, animations: (@MainActor () -> Void)? = nil, completion: (@MainActor (Bool) -> Void)? = nil) {
        let apply: @MainActor () -> Void = {
            if let snapshot = self.snapshot(for: presenter) {
                presenter.view.layer.transform = snapshot.transform
                presenter.view.layer.cornerRadius = snapshot.cornerRadius
                presenter.view.layer.masksToBounds = snapshot.masksToBounds
            }

            if PTSheetOptions.shrinkingNestedPresentingViewControllers {
                let scene = presenter.view.window?.windowScene
                var scale: CGFloat = 1
                let lowerPresenters = Self.currentPresenters.reversed().compactMap { snapshot -> PTPresenterSnapshot? in
                    guard let controller = snapshot.controller, controller !== presenter else { return nil }
                    guard scene == nil || controller.view.window?.windowScene === scene else { return nil }
                    return snapshot
                }
                for snapshot in lowerPresenters {
                    guard let controller = snapshot.controller else { continue }
                    scale *= 0.92
                    let transform = CATransform3DConcat(
                        snapshot.transform,
                        CATransform3DConcat(
                            CATransform3DMakeTranslation(0, controller.view.safeAreaInsets.top / 2, 0),
                            CATransform3DMakeScale(scale, scale, 1)
                        )
                    )
                    controller.view.layer.transform = transform
                    controller.view.layer.cornerRadius = snapshot.cornerRadius
                    controller.view.layer.masksToBounds = snapshot.masksToBounds
                }
            }
            animations?()
        }

        if animated, self.transitionDuration(using: nil) > 0 {
            UIView.animate(
                withDuration: self.transitionDuration(using: nil),
                animations: apply,
                completion: { completed in
                    if completed {
                        self.removePresenterSnapshot(for: presenter)
                    }
                    completion?(completed)
                }
            )
        } else {
            apply()
            self.removePresenterSnapshot(for: presenter)
            completion?(true)
        }
    }

    /// 设置 Presenter 缩放状态。
    func setPresenter(percentComplete: CGFloat) {
        guard self.options.shrinkPresentingViewController || PTSheetOptions.shrinkingNestedPresentingViewControllers,
              let presenter = self.presenter,
              let snapshot = self.snapshot(for: presenter) else { return }

        let percent = min(max(percentComplete, 0), 1)
        let topSafeArea = presenter.view.safeAreaInsets.top
        let scale = 0.92 + (0.08 * percent)
        let transform = CATransform3DConcat(
            snapshot.transform,
            CATransform3DConcat(
                CATransform3DMakeTranslation(0, (1 - percent) * topSafeArea / 2, 0),
                CATransform3DMakeScale(scale, scale, 1)
            )
        )
        presenter.view.layer.transform = transform
        presenter.view.layer.cornerRadius = max(snapshot.cornerRadius, self.options.presentingViewCornerRadius * (1 - percent))
        presenter.view.layer.masksToBounds = true

        if PTSheetOptions.shrinkingNestedPresentingViewControllers {
            var nestedScale = scale
            let scene = presenter.view.window?.windowScene
            let lowerPresenters = Self.currentPresenters.reversed().compactMap { snapshot -> PTPresenterSnapshot? in
                guard let controller = snapshot.controller, controller !== presenter else { return nil }
                guard scene == nil || controller.view.window?.windowScene === scene else { return nil }
                return snapshot
            }
            for snapshot in lowerPresenters {
                guard let controller = snapshot.controller else { continue }
                nestedScale *= 0.92
                let transform = CATransform3DConcat(
                    snapshot.transform,
                    CATransform3DConcat(
                        CATransform3DMakeTranslation(0, (1 - percent) * controller.view.safeAreaInsets.top / 2, 0),
                        CATransform3DMakeScale(nestedScale, nestedScale, 1)
                    )
                )
                controller.view.layer.transform = transform
                controller.view.layer.cornerRadius = snapshot.cornerRadius
                controller.view.layer.masksToBounds = snapshot.masksToBounds
            }
        }
    }
}
#endif // os(iOS) || os(tvOS) || os(watchOS)
