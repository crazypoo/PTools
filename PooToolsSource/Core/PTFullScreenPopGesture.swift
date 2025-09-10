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
    public static func configure() {
        UINavigationController.enableFullscreenPop()
        UIViewController.enableSwizzling()
    }
}

// MARK: - UINavigationController Extension
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {

    private struct AssociatedKeys {
        static var fullscreenPopGesture = "fullscreenPopGesture"
        static var viewControllerBasedNavBar = "viewControllerBasedNavBar"
    }
    
    // Fullscreen pan gesture
    public var fullscreenPopGesture: UIPanGestureRecognizer {
        if let pan = objc_getAssociatedObject(self, &AssociatedKeys.fullscreenPopGesture) as? UIPanGestureRecognizer {
            return pan
        }
        let pan = UIPanGestureRecognizer()
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        objc_setAssociatedObject(self, &AssociatedKeys.fullscreenPopGesture, pan, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return pan
    }
    
    // Enable per-VC nav bar control
    public var viewControllerBasedNavBarAppearanceEnabled: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.viewControllerBasedNavBar) as? Bool) ?? true }
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewControllerBasedNavBar, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    // Swizzle pushViewController
    static func enableFullscreenPop() {
        DispatchQueue.once(token: "com.pt.fullscreenPop") {
            let original = class_getInstanceMethod(self, #selector(pushViewController(_:animated:)))
            let swizzled = class_getInstanceMethod(self, #selector(swizzled_pushViewController(_:animated:)))
            method_exchangeImplementations(original!, swizzled!)
        }
    }
    
    @objc private func swizzled_pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        // Add fullscreen gesture if needed
        if fullscreenPopGesture.view == nil {
            interactivePopGestureRecognizer?.view?.addGestureRecognizer(fullscreenPopGesture)
            if let targets = interactivePopGestureRecognizer?.value(forKey: "targets") as? [NSObject],
               let target = targets.first?.value(forKey: "target") {
                fullscreenPopGesture.addTarget(target, action: NSSelectorFromString("handleNavigationTransition:"))
                interactivePopGestureRecognizer?.isEnabled = false
            }
        }
        
        setupNavBarAppearance(for: viewController)
        
        // Call original push
        swizzled_pushViewController(viewController, animated: animated)
    }
    
    private func setupNavBarAppearance(for vc: UIViewController) {
        guard viewControllerBasedNavBarAppearanceEnabled else { return }
        let container = vc.willAppearBlockContainer
        container?.block(vc, true)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let top = viewControllers.last, viewControllers.count > 1 else { return false }
        guard !top.interactivePopDisabled else { return false }
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let location = pan.location(in: pan.view)
        if top.interactivePopMaxAllowedInitialDistanceToLeftEdge > 0,
           Double(location.x) > top.interactivePopMaxAllowedInitialDistanceToLeftEdge {
            return false
        }
        let translation = pan.translation(in: pan.view)
        return translation.x > 0
    }
}

// MARK: - UIViewController Extension
extension UIViewController {

    private struct AssociatedKeys {
        static var interactivePopDisabled = "interactivePopDisabled"
        static var prefersNavigationBarHidden = "prefersNavigationBarHidden"
        static var maxInitialDistance = "maxInitialDistance"
        static var willAppearBlockContainer = "willAppearBlockContainer"
    }
    
    public var interactivePopDisabled: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.interactivePopDisabled) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.interactivePopDisabled, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    public var prefersNavigationBarHidden: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.prefersNavigationBarHidden) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.prefersNavigationBarHidden, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    public var interactivePopMaxAllowedInitialDistanceToLeftEdge: Double {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.maxInitialDistance) as? Double) ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.maxInitialDistance, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    fileprivate var willAppearBlockContainer: WillAppearBlockContainer? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.willAppearBlockContainer) as? WillAppearBlockContainer }
        set { objc_setAssociatedObject(self, &AssociatedKeys.willAppearBlockContainer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    static func enableSwizzling() {
        DispatchQueue.once(token: "com.pt.vcSwizzle") {
            let original = class_getInstanceMethod(self, #selector(viewWillAppear(_:)))
            let swizzled = class_getInstanceMethod(self, #selector(swizzled_viewWillAppear(_:)))
            method_exchangeImplementations(original!, swizzled!)
        }
    }
    
    @objc private func swizzled_viewWillAppear(_ animated: Bool) {
        swizzled_viewWillAppear(animated)
        willAppearBlockContainer?.block(self, animated)
    }
}

// MARK: - Helper Container
fileprivate class WillAppearBlockContainer {
    let block: (_ vc: UIViewController, _ animated: Bool) -> Void
    init(_ block: @escaping (_ vc: UIViewController, _ animated: Bool) -> Void) {
        self.block = block
    }
}

// MARK: - DispatchQueue Once
fileprivate extension DispatchQueue {
    private static var _onceTracker = [String]()
    class func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if _onceTracker.contains(token) { return }
        _onceTracker.append(token)
        block()
    }
}
