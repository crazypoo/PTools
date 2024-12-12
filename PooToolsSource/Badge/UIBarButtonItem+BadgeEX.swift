//
//  UIBarButtonItem+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIBarButtonItem:PTBadgeProtocol {
    
    fileprivate func getActualBadgeSuperView() ->UIView {
        return self.value(forKey: "_view") as! UIView
    }
    
    public var badge: UILabel? {
        get {
            self.getActualBadgeSuperView().badge
        }
        set {
            self.getActualBadgeSuperView().badge = newValue
        }
    }
    
    public var badgeFont: UIFont {
        get {
            self.getActualBadgeSuperView().badgeFont
        }
        set {
            self.getActualBadgeSuperView().badgeFont = newValue
        }
    }
    
    public var badgeBgColor: UIColor {
        get {
            self.getActualBadgeSuperView().badgeBgColor
        }
        set {
            self.getActualBadgeSuperView().badgeBgColor = newValue
        }
    }
    
    public var badgeTextColor: UIColor {
        get {
            self.getActualBadgeSuperView().badgeTextColor
        }
        set {
            self.getActualBadgeSuperView().badgeTextColor = newValue
        }
    }
    
    public var badgeFrame: CGRect {
        get {
            self.getActualBadgeSuperView().badgeFrame
        }
        set {
            self.getActualBadgeSuperView().badgeFrame = newValue
        }
    }
    
    public var badgeCenterOffset: CGPoint {
        get {
            self.getActualBadgeSuperView().badgeCenterOffset
        }
        set {
            self.getActualBadgeSuperView().badgeCenterOffset = newValue
        }
    }
    
    public var aniType: PTBadgeAnimType {
        get {
            self.getActualBadgeSuperView().aniType
        }
        set {
            self.getActualBadgeSuperView().aniType = newValue
        }
    }
    
    public var badgeMaximumBadgeNumber: Int {
        get {
            self.getActualBadgeSuperView().badgeMaximumBadgeNumber
        }
        set {
            self.getActualBadgeSuperView().badgeMaximumBadgeNumber = newValue
        }
    }
    
    public var badgeRadius: CGFloat {
        get {
            self.getActualBadgeSuperView().badgeRadius
        }
        set {
            self.getActualBadgeSuperView().badgeRadius = newValue
        }
    }
    
    public var badgeBorderColor: UIColor {
        get {
            self.getActualBadgeSuperView().badgeBorderColor
        }
        set {
            self.getActualBadgeSuperView().badgeBorderColor = newValue
        }
    }
    
    public var badgeBorderLine: CGFloat {
        get {
            self.getActualBadgeSuperView().badgeBorderLine

        }
        set {
            self.getActualBadgeSuperView().badgeBorderLine = newValue
        }
    }

    public func showBadge() {
        self.getActualBadgeSuperView().showBadge()
    }
    
    public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) {
        self.getActualBadgeSuperView().showBadge(style: style, value: value, aniType: aniType)
    }
    
    public func clearBadge() {
        self.getActualBadgeSuperView().clearBadge()
    }
    
    public func resumeBadge() {
        self.getActualBadgeSuperView().resumeBadge()
    }
}
