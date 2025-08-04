//
//  UITabBarItem+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UITabBarItem:PTBadgeProtocol {
    
    fileprivate func getActualBadgeSuperView() -> UIView? {
        var actualSuperView:UIView?
        if let bottomView = self.value(forKey: "_view") {
            actualSuperView = self.find(view: bottomView as! UIView, classs: NSClassFromString("UITabBarSwappableImageView"))
        }
        return actualSuperView
    }
    
    fileprivate func find(view:UIView,classs:AnyClass?) -> UIView? {
        var targetView:UIView?
        for (_,value) in view.subviews.enumerated() {
            if classs != nil {
                if value.isKind(of: classs!) {
                    targetView = value
                    break
                }
            }
        }
        return targetView
    }
    
    public var badge: UILabel? {
        get {
            self.getActualBadgeSuperView()?.badge
        }
        set {
            self.getActualBadgeSuperView()?.badge = newValue
        }
    }
    
    public var badgeFont: UIFont {
        get {
            self.getActualBadgeSuperView()?.badgeFont ?? .appfont(size: 9)
        }
        set {
            self.getActualBadgeSuperView()?.badgeFont = newValue
        }
    }
    
    public var badgeBgColor: UIColor {
        get {
            self.getActualBadgeSuperView()?.badgeBgColor ?? .systemRed
        }
        set {
            self.getActualBadgeSuperView()?.badgeBgColor = newValue
        }
    }
    
    public var badgeTextColor: UIColor {
        get {
            self.getActualBadgeSuperView()?.badgeTextColor ?? .white
        }
        set {
            self.getActualBadgeSuperView()?.badgeTextColor = newValue
        }
    }
    
    public var badgeFrame: CGRect {
        get {
            self.getActualBadgeSuperView()?.badgeFrame ?? .zero
        }
        set {
            self.getActualBadgeSuperView()?.badgeFrame = newValue
        }
    }
    
    public var badgeCenterOffset: CGPoint {
        get {
            self.getActualBadgeSuperView()?.badgeCenterOffset ?? .zero
        }
        set {
            self.getActualBadgeSuperView()?.badgeCenterOffset = newValue
        }
    }
    
    public var aniType: PTBadgeAnimType {
        get {
            self.getActualBadgeSuperView()?.aniType ?? .None
        }
        set {
            self.getActualBadgeSuperView()?.aniType = newValue
        }
    }
    
    public var badgeMaximumBadgeNumber: Int {
        get {
            self.getActualBadgeSuperView()?.badgeMaximumBadgeNumber ?? kPTBAdgeDefaultMaximumBadgeNumber
        }
        set {
            self.getActualBadgeSuperView()?.badgeMaximumBadgeNumber = newValue
        }
    }
    
    public var badgeRadius: CGFloat {
        get {
            self.getActualBadgeSuperView()?.badgeRadius ?? 0
        }
        set {
            self.getActualBadgeSuperView()?.badgeRadius = newValue
        }
    }
    
    public var badgeBorderColor: UIColor {
        get {
            self.getActualBadgeSuperView()?.badgeBorderColor ?? .clear
        }
        set {
            self.getActualBadgeSuperView()?.badgeBorderColor = newValue
        }
    }
    
    public var badgeBorderLine: CGFloat {
        get {
            self.getActualBadgeSuperView()?.badgeBorderLine ?? 0

        }
        set {
            self.getActualBadgeSuperView()?.badgeBorderLine = newValue
        }
    }

    public func showBadge() {
        self.getActualBadgeSuperView()?.showBadge()
    }
    
    public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) {
        self.getActualBadgeSuperView()?.showBadge(style: style, value: value, aniType: aniType)
    }
    
    public func clearBadge() {
        self.getActualBadgeSuperView()?.clearBadge()
    }
    
    public func resumeBadge() {
        self.getActualBadgeSuperView()?.resumeBadge()
    }
}
