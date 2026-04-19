//
//  PTFullScreenPopGesture.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/9/10.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

// MARK: - Fullscreen Pop Gesture Configurator
open class PTFullscreenPopGesture {
    /// 只需要在 App 启动时（例如 AppDelegate 的 didFinishLaunchingWithOptions）调用一次此方法
    public static func configure() {
        UINavigationController.enableFullscreenPop()
        UIViewController.enableSwizzling()
    }
}

// MARK: - UINavigationController Extension
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {

    // 使用标准、安全的 Key 定义关联对象
    private struct AssociatedKeys {
        static var fullscreenPopGesture: UInt8 = 0
        static var viewControllerBasedNavBar: UInt8 = 0
    }
    
    // 全屏滑动返回手势
    public var fullscreenPopGesture: UIPanGestureRecognizer {
        if let pan = objc_getAssociatedObject(self, &AssociatedKeys.fullscreenPopGesture) as? UIPanGestureRecognizer {
            return pan
        }
        let pan = UIPanGestureRecognizer()
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        // 将手势绑定到导航栏的 view 上
        objc_setAssociatedObject(self, &AssociatedKeys.fullscreenPopGesture, pan, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return pan
    }
    
    // 是否开启基于单个 VC 的导航栏外观控制 (默认为 true)
    public var viewControllerBasedNavBarAppearanceEnabled: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.viewControllerBasedNavBar) as? Bool) ?? true }
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewControllerBasedNavBar, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // 现代 Swift 的 Method Swizzling (利用 static let 保证只执行一次)
    private static let swizzlePushViewControllerOnce: Void = {
        Swizzle(UINavigationController.self) {
            #selector(pushViewController(_:animated:)) <-> #selector(swizzled_pushViewController(_:animated:))
        }
    }()
    
    static func enableFullscreenPop() {
        _ = swizzlePushViewControllerOnce
    }
    
    @objc private func swizzled_pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        // 1. 设置系统手势 target 到我们的全屏手势上 (懒加载绑定)
        if fullscreenPopGesture.view == nil {
            interactivePopGestureRecognizer?.view?.addGestureRecognizer(fullscreenPopGesture)
            
            if let targets = interactivePopGestureRecognizer?.value(forKey: "targets") as? [NSObject],
               let targetObj = targets.first?.value(forKey: "target") {
                // 借用系统的私有 API 处理滑动过渡动画
                fullscreenPopGesture.addTarget(targetObj, action: NSSelectorFromString("handleNavigationTransition:"))
                // 禁用系统自带的边缘返回手势，防止冲突
                interactivePopGestureRecognizer?.isEnabled = false
            }
        }
        
        // 2. 调用原生的 push 逻辑 (注意：这里已经去掉了之前有 Bug 的 Block 注入逻辑)
        swizzled_pushViewController(viewController, animated: animated)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 1. 如果是根视图，不响应手势
        guard viewControllers.count > 1, let top = viewControllers.last else { return false }
        
        // 2. 如果当前 VC 禁用了手势，不响应
        guard !top.interactivePopDisabled else { return false }
        
        // 3. 修复动画过渡期间的崩溃：如果导航栏正在做转场动画，不响应手势
        if let isTransitioning = value(forKey: "_isTransitioning") as? NSNumber, isTransitioning.boolValue {
            return false
        }
        
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        
        let location = pan.location(in: pan.view)
        let translation = pan.translation(in: pan.view)
        
        // 4. 如果设置了最大触发距离，并且触摸起始点超过了该距离，不响应
        if top.interactivePopMaxAllowedInitialDistanceToLeftEdge > 0,
           Double(location.x) > top.interactivePopMaxAllowedInitialDistanceToLeftEdge {
            return false
        }
        
        // 5. 只有向右滑动时才响应 (防止向左滑动也触发 pop 动画)
        if translation.x <= 0 {
            return false
        }
        
        return true
    }
}

// MARK: - UIViewController Extension
extension UIViewController {

    private struct AssociatedKeys {
        static var interactivePopDisabled: UInt8 = 0
        static var prefersNavigationBarHidden: UInt8 = 0
        static var maxInitialDistance: UInt8 = 0
        static var willAppearBlockContainer: UInt8 = 0
    }
    
    /// 是否禁用当前控制器的滑动返回手势 (默认 false)
    public var interactivePopDisabled: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.interactivePopDisabled) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.interactivePopDisabled, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 当前控制器是否需要隐藏导航栏 (默认 false)
    public var prefersNavigationBarHidden: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.prefersNavigationBarHidden) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.prefersNavigationBarHidden, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 手势距离左边缘的最大有效初始距离 (0 表示全屏任意位置有效)
    public var interactivePopMaxAllowedInitialDistanceToLeftEdge: Double {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.maxInitialDistance) as? Double) ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.maxInitialDistance, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
        
    private static let swizzleViewWillAppearOnce: Void = {
        Swizzle(UIViewController.self) {
            #selector(viewWillAppear(_:)) <-> #selector(swizzled_viewWillAppear(_:))
        }
    }()
    
    static func enableSwizzling() {
        _ = swizzleViewWillAppearOnce
    }
    
    @objc private func swizzled_viewWillAppear(_ animated: Bool) {
        // 调用原生逻辑
        swizzled_viewWillAppear(animated)
        
        // 2. 直接在这里控制导航栏的外观！
        // 这样不仅去掉了复杂的 Block 注入，而且完美解决了 Root VC pop 回来时不触发的问题。
        if let nav = self.navigationController, nav.viewControllerBasedNavBarAppearanceEnabled {
            nav.setNavigationBarHidden(self.prefersNavigationBarHidden, animated: animated)
        }
    }
}
