//
//  UITabBarItem+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UITabBarItem:PTBadgeProtocol {
    
    // MARK: - Private View Finder
    
    /// 获取真正用于承载角标的底层 UIView
    private var actualBadgeSuperView: UIView? {
        // 1. 通过 KVC 获取内部真实的 View (通常是 UITabBarButton)
        guard let bottomView = self.value(forKey: "_view") as? UIView else {
            return nil
        }
        
        // 2. 寻找内部的图片视图 UITabBarSwappableImageView
        if let swappableClass = NSClassFromString("UITabBarSwappableImageView") {
            // 使用 Swift 高阶函数优雅地查找
            let targetView = bottomView.subviews.first { $0.isKind(of: swappableClass) }
            // 如果找到了就返回图片视图，找不到就退而求其次，返回整个 Item 的底层 View
            return targetView ?? bottomView
        }
        
        return bottomView
    }
    
    // MARK: - Protocol Properties Forwarding
    
    public var badge: UILabel? {
        get { actualBadgeSuperView?.badge }
        set { actualBadgeSuperView?.badge = newValue }
    }
    
    /// 直接转发整个配置对象！
    public var badgeConfig: PTBadgeConfiguration {
        get { actualBadgeSuperView?.badgeConfig ?? PTBadgeConfiguration() }
        set { actualBadgeSuperView?.badgeConfig = newValue }
    }
    
    public var badgeRemoveCallback: (() -> Void)? {
        get { actualBadgeSuperView?.badgeRemoveCallback }
        set { actualBadgeSuperView?.badgeRemoveCallback = newValue }
    }
    
    // MARK: - Protocol Methods Forwarding
    
    public func showBadge() {
        actualBadgeSuperView?.showBadge()
    }
    
    public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) {
        actualBadgeSuperView?.showBadge(style: style, value: value, aniType: aniType)
    }
    
    public func clearBadge() {
        actualBadgeSuperView?.clearBadge()
    }
    
    public func resumeBadge() {
        actualBadgeSuperView?.resumeBadge()
    }
}
