//
//  UIBarButtonItem+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIBarButtonItem:PTBadgeProtocol {
    
    // MARK: - Private View Finder
    
    /// 获取真正用于承载角标的底层 UIView
    private var actualBadgeSuperView: UIView? {
        // 使用 as? 替代 as!，彻底杜绝潜在的崩溃风险
        return self.value(forKey: "_view") as? UIView
    }
    
    // MARK: - Protocol Properties Forwarding
    
    public var badge: UILabel? {
        get { actualBadgeSuperView?.badge }
        set { actualBadgeSuperView?.badge = newValue }
    }
    
    /// 统一转发配置对象
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
