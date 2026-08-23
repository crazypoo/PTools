//
//  PTAlertTipsViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

@MainActor
@objcMembers
public class PTAlertTipsViewController: PTAlertController {

    fileprivate var tipsViewLow: PTAlertTipsLow?
    fileprivate var tipsViewHight: PTAlertTipsHight?

    private let presentDismissDuration: TimeInterval = 0.2
    private let presentDismissScale: CGFloat = 0.8
    private var style: PTAlertTipsStyle = .Normal
    private var dismissByTap = true
    private let autoDismiss = PTAlertTipsAutoDismiss()
    private var didCallDismissCallback = false

    public var dismissCallback: PTActionTask?

    public static func tipsAlertShow(title: String? = nil,
                                     subtitle: String? = nil,
                                     icon: PTAlertTipsIcon?,
                                     style: PTAlertTipsStyle = .Normal,
                                     haptic: PTAlertTipsHaptic? = nil,
                                     dismissByTap: Bool = true,
                                     dismissInTime: Bool = true,
                                     dismissDuration: TimeInterval = 1.5,
                                     showCallback: PTActionTask? = nil,
                                     dismissCallback: PTActionTask? = nil) {
        let alert = PTAlertTipsViewController(
            title: title,
            subtitle: subtitle,
            icon: icon,
            style: style,
            haptic: haptic,
            dismissByTap: dismissByTap,
            dismissInTime: dismissInTime,
            dismissDuration: dismissDuration
        )
        alert.dismissCallback = dismissCallback
        PTAlertManager.show(alert, completion: showCallback)
    }

    public init(title: String? = nil,
                subtitle: String? = nil,
                icon: PTAlertTipsIcon?,
                style: PTAlertTipsStyle = .Normal,
                haptic: PTAlertTipsHaptic? = nil,
                dismissByTap: Bool = true,
                dismissInTime: Bool = true,
                dismissDuration: TimeInterval = 1.5) {
        self.style = style
        self.dismissByTap = dismissByTap
        switch style {
        case .Normal:
            let tipsView = PTAlertTipsLow(title: title, subtitle: subtitle, icon: icon)
            tipsView.haptic = haptic
            tipsView.dismissByTap = dismissByTap
            tipsView.dismissInTime = dismissInTime
            tipsView.duration = dismissDuration
            tipsViewLow = tipsView
        case .SupportVisionOS:
            let tipsView = PTAlertTipsHight(title: title, subtitle: subtitle, icon: icon)
            tipsView.haptic = haptic
            tipsView.dismissByTap = dismissByTap
            tipsView.dismissInTime = dismissInTime
            tipsView.duration = dismissDuration
            tipsViewHight = tipsView
        }
        super.init(nibName: nil, bundle: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        activeTipsView?.alpha = 0
        if let activeTipsView, activeTipsView.superview !== view {
            view.addSubview(activeTipsView)
        }

        if dismissByTap {
            let tap = UITapGestureRecognizer { [weak self] _ in
                self?.dismissSelf()
            }
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let activeTipsView else { return }
        activeTipsView.sizeToFit()

        switch style {
        case .Normal:
            let safeFrame = view.safeAreaLayoutGuide.layoutFrame
            activeTipsView.center = CGPoint(x: safeFrame.midX, y: safeFrame.midY)
        case .SupportVisionOS:
#if os(visionOS)
            activeTipsView.center = CGPoint(x: view.bounds.midX,
                                            y: CGFloat.kNavBarHeight_Total + 24)
#else
            let y = view.bounds.height - view.safeAreaInsets.bottom - activeTipsView.bounds.height - 64
            activeTipsView.center = CGPoint(x: view.bounds.midX,
                                            y: y + activeTipsView.bounds.height / 2)
#endif
        }
    }

    public override func showAnimation(completion: PTActionTask? = nil) {
        autoDismiss.beginPresentation()
        didCallDismissCallback = false
        activeTipsView?.transform = CGAffineTransform(scaleX: presentDismissScale,
                                                       y: presentDismissScale)
        activeTipsView?.alpha = 0

        switch style {
        case .Normal:
            tipsViewLow?.haptic?.impact()
        case .SupportVisionOS:
            tipsViewHight?.haptic?.impact()
        }

        UIView.animate(withDuration: presentDismissDuration,
                       delay: 0,
                       options: .curveEaseOut) {
            self.activeTipsView?.alpha = 1
            self.activeTipsView?.transform = .identity
        } completion: { [weak self] _ in
            guard let self else { return }
            if let iconView = self.activeIconView as? PTAlertTipsAnimation {
                iconView.animation()
            }
            if self.activeDismissInTime {
                self.autoDismiss.schedule(after: self.activeDuration) { [weak self] in
                    self?.dismissSelf()
                }
            }
            completion?()
        }
    }

    public override func dismissAnimation(completion: PTActionTask? = nil) {
        let _ = autoDismiss.beginDismiss()
        UIView.animate(withDuration: presentDismissDuration,
                       delay: 0,
                       options: .curveEaseIn) {
            self.activeTipsView?.alpha = 0
            self.activeTipsView?.transform = CGAffineTransform(
                scaleX: self.presentDismissScale,
                y: self.presentDismissScale
            )
        } completion: { [weak self] _ in
            self?.callDismissCallback()
            completion?()
        }
    }

    private var activeTipsView: UIView? {
        switch style {
        case .Normal: tipsViewLow
        case .SupportVisionOS: tipsViewHight
        }
    }

    private var activeIconView: UIView? {
        switch style {
        case .Normal: tipsViewLow?.iconView
        case .SupportVisionOS: tipsViewHight?.iconView
        }
    }

    private var activeDismissInTime: Bool {
        switch style {
        case .Normal: tipsViewLow?.dismissInTime ?? false
        case .SupportVisionOS: tipsViewHight?.dismissInTime ?? false
        }
    }

    private var activeDuration: TimeInterval {
        switch style {
        case .Normal: tipsViewLow?.duration ?? 0
        case .SupportVisionOS: tipsViewHight?.duration ?? 0
        }
    }

    private func callDismissCallback() {
        guard !didCallDismissCallback else { return }
        didCallDismissCallback = true
        dismissCallback?()
    }
}
