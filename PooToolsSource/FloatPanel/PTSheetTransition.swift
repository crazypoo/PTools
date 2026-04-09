//
//  PTSheetTransition.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
import SnapKit

/// 用于包装弱引用的 UIViewController，防止静态数组引发内存泄漏
struct PTWeakPresenter {
    weak var controller: UIViewController?
}

public class PTSheetTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var presenting = true
    weak var presenter: UIViewController?
    var options: PTSheetOptions
    
    /// Cache of presenters so we can do the experimental shrinkingNestedPresentingViewControllers behavior
    /// [优化] 改为弱引用数组，避免强持有 ViewController 导致内存泄漏
    static var currentPresenters: [PTWeakPresenter] = []
    
    init(options: PTSheetOptions) {
        self.options = options
        super.init()
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.options.transitionDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        if self.presenting {
            guard let presenter = transitionContext.viewController(forKey: .from),
                  let sheet = transitionContext.viewController(forKey: .to) as? PTSheetViewController else {
                transitionContext.completeTransition(true)
                return
            }
            self.presenter = presenter
            
            if PTSheetOptions.shrinkingNestedPresentingViewControllers {
                // 清理已经释放的 controller，并追加新的
                PTSheetTransition.currentPresenters.removeAll { $0.controller == nil }
                PTSheetTransition.currentPresenters.append(PTWeakPresenter(controller: presenter))
            }
            
            sheet.contentViewController.view.transform = .identity
            containerView.addSubview(sheet.view)
            
            sheet.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            // 强制刷新布局以获取正确的 bounds
            UIView.performWithoutAnimation {
                sheet.view.layoutIfNeeded()
            }
            
            sheet.contentViewController.updatePreferredHeight()
            sheet.resize(to: sheet.currentSize, animated: false)
            
            let contentView = sheet.contentViewController.contentView
            contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)
            sheet.overlayView.alpha = 0
            
            // 安全限制：防止除以 0 的情况出现（极小概率）
            let screenHeight = UIScreen.main.bounds.height
            let heightPercent = screenHeight > 0 ? (contentView.bounds.height / screenHeight) : 0
            
            // [优化] 移除了一次多余的 sheet.view.layoutIfNeeded()
            
            // 1. 基础动画：处理阴影和背景 Overlay
            UIView.animate(withDuration: self.options.transitionDuration * 0.6, delay: 0, options: [.curveEaseOut], animations: {
                if self.options.shrinkPresentingViewController {
                    self.setPresenter(percentComplete: 0)
                }
                sheet.overlayView.alpha = 1
            }, completion: nil)

            // 2. 弹簧动画：处理面板本身的上移
            UIView.animate(withDuration: self.options.transitionDuration,
                           delay: 0,
                           usingSpringWithDamping: self.options.transitionDampening + ((heightPercent - 0.2) * 1.25 * 0.17),
                           initialSpringVelocity: self.options.transitionVelocity * heightPercent,
                           options: self.options.transitionAnimationOptions,
                           animations: {
                contentView.transform = .identity
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
            
        } else {
            // Dismiss 逻辑
            guard let presenter = transitionContext.viewController(forKey: .to),
                  let sheet = transitionContext.viewController(forKey: .from) as? PTSheetViewController else {
                transitionContext.completeTransition(true)
                return
            }

            containerView.addSubview(sheet.view)
            let contentView = sheet.contentViewController.contentView

            self.restorePresenter(
                presenter,
                animations: {
                    contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)
                    sheet.overlayView.alpha = 0
                }, completion: { _ in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            )
        }
    }

    // MARK: - Helper Methods
    
    /// 恢复 Presenter 的视图状态
    func restorePresenter(_ presenter: UIViewController, animated: Bool = true, animations: PTActionTask? = nil, completion: PTBoolTask? = nil) {
        // [优化] 同时清理匹配的 presenter 和已经变为 nil 的悬空指针
        PTSheetTransition.currentPresenters.removeAll(where: { $0.controller == presenter || $0.controller == nil })
        
        let topSafeArea = AppWindows?.compatibleSafeAreaInsets.top ?? 0
        
        UIView.animate(
            withDuration: self.options.transitionDuration,
            animations: {
                if self.options.shrinkPresentingViewController {
                    presenter.view.layer.transform = CATransform3DMakeScale(1, 1, 1)
                    presenter.view.layer.cornerRadius = 0
                }
                
                if PTSheetOptions.shrinkingNestedPresentingViewControllers {
                    var scale: CGFloat = 1.0
                    // [优化] 解包弱引用
                    let validPresenters = PTSheetTransition.currentPresenters.compactMap { $0.controller }.reversed()
                    for lowerPresenter in validPresenters {
                        scale *= 0.92
                        lowerPresenter.view.layer.transform = CATransform3DConcat(CATransform3DMakeTranslation(0, topSafeArea/2, 0), CATransform3DMakeScale(scale, scale, 1))
                    }
                }
                animations?()
            },
            completion: {
                completion?($0)
            }
        )
    }

    /// 设置 Presenter 缩放状态
    func setPresenter(percentComplete: CGFloat) {
        guard self.options.shrinkPresentingViewController, let presenter = self.presenter else { return }
        
        var scale: CGFloat = min(1, 0.92 + (0.08 * percentComplete))
        let topSafeArea = AppWindows?.compatibleSafeAreaInsets.top ?? 0

        presenter.view.layer.transform = CATransform3DConcat(CATransform3DMakeTranslation(0, (1 - percentComplete) * topSafeArea/2, 0), CATransform3DMakeScale(scale, scale, 1))
        presenter.view.layer.cornerRadius = self.options.presentingViewCornerRadius * (1 - percentComplete)
        
        if PTSheetOptions.shrinkingNestedPresentingViewControllers {
            // [优化] 解包弱引用并丢弃第一个
            let validPresenters = PTSheetTransition.currentPresenters.compactMap { $0.controller }.reversed().dropFirst()
            for lowerPresenter in validPresenters {
                scale *= 0.92
                lowerPresenter.view.layer.transform = CATransform3DConcat(CATransform3DMakeTranslation(0, (1 - percentComplete) * topSafeArea/2, 0), CATransform3DMakeScale(scale, scale, 1))
            }
        }
    }
}
#endif // os(iOS) || os(tvOS) || os(watchOS)
