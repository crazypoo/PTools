//
//  PTAlertTipsViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTAlertTipsViewController: PTAlertController {

    fileprivate var tipsViewLow: PTAlertTipsLow?
    fileprivate var tipsViewHight: PTAlertTipsHight?
    
    private let presentDismissDuration: TimeInterval = 0.2
    private let presentDismissScale: CGFloat = 0.8
    private var style: PTAlertTipsStyle = .Normal
    private var dismissByTap:Bool = true
    
    public var dismissCallback:PTActionTask? = nil
    
    public static func tipsAlertShow(title: String? = nil,
                                     subtitle: String? = nil,
                                     icon: PTAlertTipsIcon?,
                                     style: PTAlertTipsStyle = .Normal,
                                     haptic: PTAlertTipsHaptic? = nil,
                                     dismissByTap:Bool = true,
                                     dismissInTime:Bool = true,
                                     dismissDuration:TimeInterval = 1.5,
                                     showCallback:PTActionTask? = nil
                                     ,dismissCallback:PTActionTask? = nil) {
        let alert = PTAlertTipsViewController(title: title, subtitle: subtitle, icon: icon,style: style,haptic: haptic,dismissByTap: dismissByTap,dismissInTime: dismissInTime,dismissDuration: dismissDuration)
        alert.dismissCallback = dismissCallback
        PTAlertManager.show(alert, completion: showCallback)
    }
    
    public init(title: String? = nil, subtitle: String? = nil, icon: PTAlertTipsIcon?, style: PTAlertTipsStyle = .Normal,haptic: PTAlertTipsHaptic? = nil,dismissByTap:Bool = true,dismissInTime:Bool = true,dismissDuration:TimeInterval = 1.5) {
        self.style = style
        self.dismissByTap = dismissByTap
        // 因为声明为了可选类型，未赋值的那个会自动变为 nil，满足 Swift 的初始化安全规则
        switch style {
        case .Normal:
            self.tipsViewLow = PTAlertTipsLow(title: title, subtitle: subtitle, icon: icon)
            self.tipsViewLow?.haptic = haptic
            self.tipsViewLow?.dismissByTap = dismissByTap
            self.tipsViewLow?.dismissInTime = dismissInTime
            self.tipsViewLow?.duration = dismissDuration
        case .SupportVisionOS:
            self.tipsViewHight = PTAlertTipsHight(title: title, subtitle: subtitle, icon: icon)
            self.tipsViewHight?.haptic = haptic
            self.tipsViewHight?.dismissByTap = dismissByTap
            self.tipsViewHight?.dismissInTime = dismissInTime
            self.tipsViewHight?.duration = dismissDuration
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. 将 tipsView 添加到控制器的 view 中
        switch self.style {
        case .Normal:
            if let viewLow = tipsViewLow {
                view.addSubview(viewLow)
                viewLow.alpha = 0 // 初始状态隐藏
            }
        case .SupportVisionOS:
            if let viewHight = tipsViewHight {
                view.addSubview(viewHight)
                viewHight.alpha = 0 // 初始状态隐藏
            }
        }
        
        if dismissByTap {
            let tapGesterRecognizer = UITapGestureRecognizer { sender in
                self.dismissAnimation(completion: {
                    self.dismissCallback?()
                })
            }
            view.addGestureRecognizer(tapGesterRecognizer)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 2. 居中布局
        switch self.style {
        case .Normal:
            tipsViewLow?.sizeToFit()
            tipsViewLow?.center = view.center
        case .SupportVisionOS:
            tipsViewHight?.sizeToFit()
#if os(visionOS)
            tipsViewHight?.center = CGPointMake(view.frame.midX, CGFloat.kNavBarHeight_Total + 24)
#elseif os(iOS)
            tipsViewHight?.center = CGPointMake(view.frame.midX, CGFloat.kSCREEN_HEIGHT - (tipsViewHight?.height ?? 0) - CGFloat.kTabbarSaveAreaHeight - CGFloat.kTabbarHeight_Total)
#endif
        }
    }
    
    // MARK: - PTAlertProtocol 动画实现
    
    public override func showAnimation(completion: PTActionTask? = nil) {
        switch self.style {
        case .Normal:
            tipsViewLow?.transform = CGAffineTransform(scaleX: presentDismissScale, y: presentDismissScale)
            tipsViewLow?.alpha = 0
            tipsViewLow?.haptic?.impact()
        case .SupportVisionOS:
            tipsViewHight?.transform = CGAffineTransform(scaleX: presentDismissScale, y: presentDismissScale)
            tipsViewHight?.alpha = 0
            tipsViewHight?.haptic?.impact()
        }
        
        UIView.animate(withDuration: presentDismissDuration, delay: 0, options: .curveEaseOut) {
            switch self.style {
            case .Normal:
                self.tipsViewLow?.alpha = 1
                self.tipsViewLow?.transform = .identity
            case .SupportVisionOS:
                self.tipsViewHight?.alpha = 1
                self.tipsViewHight?.transform = .identity
            }
        } completion: { [weak self] _ in // 🛠️ 修复2：添加 [weak self] 防止闭包引起内存泄漏
            guard let self = self else { return }
            
            switch self.style {
            case .Normal:
                guard let viewLow = self.tipsViewLow else { break }
                if let iconView = viewLow.iconView as? PTAlertTipsAnimation {
                    iconView.animation()
                }
                
                if viewLow.dismissInTime {
                    // 🛠️ 修复3：定时器内部也需要 [weak self]
                    PTGCDManager.gcdAfter(time: viewLow.duration) { [weak self] in
                        guard let self = self else { return }
                        if self.tipsViewLow?.alpha != 0 {
                            self.dismissAnimation(completion: {
                                self.dismissCallback?()
                            })
                        }
                    }
                }
                
            case .SupportVisionOS:
                guard let viewHight = self.tipsViewHight else { break }
                if let iconView = viewHight.iconView as? PTAlertTipsAnimation {
                    iconView.animation()
                }
                
                if viewHight.dismissInTime {
                    // 🛠️ 修复3：定时器内部也需要 [weak self]
                    PTGCDManager.gcdAfter(time: viewHight.duration) { [weak self] in
                        guard let self = self else { return }
                        if self.tipsViewHight?.alpha != 0 {
                            self.dismissAnimation(completion: {
                                self.dismissCallback?()
                            })
                        }
                    }
                }
            }
            completion?()
        }
    }
    
    public override func dismissAnimation(completion: PTActionTask? = nil) {
        UIView.animate(withDuration: presentDismissDuration, delay: 0, options: .curveEaseIn) {
            switch self.style {
            case .Normal:
                self.tipsViewLow?.alpha = 0
                self.tipsViewLow?.transform = CGAffineTransform(scaleX: self.presentDismissScale, y: self.presentDismissScale)
            case .SupportVisionOS:
                self.tipsViewHight?.alpha = 0
                self.tipsViewHight?.transform = CGAffineTransform(scaleX: self.presentDismissScale, y: self.presentDismissScale)
            }
        } completion: { _ in
            PTAlertManager.dismissAll()
            completion?()
        }
    }
}
