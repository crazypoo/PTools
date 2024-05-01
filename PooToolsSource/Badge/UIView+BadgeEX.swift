//
//  UIView+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import QuartzCore

extension UIView: PTBadgeProtocol {
    
    fileprivate func badgeLabelInit() {
        if self.badge == nil {
            let redotWidth = kPTBAdgeDefaultRedDotRadius * 2
            let newLabel = UILabel(frame: CGRectMake(CGRectGetWidth(self.frame), -redotWidth, redotWidth, redotWidth))
            newLabel.textAlignment = .center
            newLabel.center = CGPoint(x: CGRectGetWidth(self.frame) + 2 + self.badgeCenterOffset.x, y: self.badgeCenterOffset.y)
            newLabel.backgroundColor = self.badgeBgColor
            newLabel.textColor = self.badgeTextColor
            newLabel.text = ""
            newLabel.tag = PTBadgeStyle.RedDot.rawValue
            newLabel.layer.cornerRadius = CGRectGetWidth(newLabel.frame) / 2
            newLabel.layer.masksToBounds = true
            newLabel.isHidden = false
            self.addSubview(newLabel)
            self.bringSubviewToFront(newLabel)
            self.badge = newLabel
        }
    }
    
    public var badge: UILabel? {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeLabelKey)
            guard let label = obj as? UILabel else {
                return nil
            }
            return label
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var badgeFont: UIFont {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeFontKey)
            guard let font = obj as? UIFont else {
                return .appfont(size: 9)
            }
            return font
        }
        set {
            if self.badge == nil {
                self.badgeLabelInit()
            }
            self.badge!.font = newValue
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var badgeBgColor: UIColor {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeBgColorKey)
            guard let color = obj as? UIColor else {
                return .systemRed
            }
            return color
        }
        set {
            if self.badge == nil {
                self.badgeLabelInit()
            }
            self.badge!.backgroundColor = newValue
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeBgColorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var badgeTextColor: UIColor {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeTextColorKey)
            guard let color = obj as? UIColor else {
                return .white
            }
            return color
        }
        set {
            if self.badge == nil {
                self.badgeLabelInit()
            }
            self.badge!.textColor = newValue
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeTextColorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var aniType: PTBadgeAnimType {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeAniTypeKey)
            guard let type = obj as? PTBadgeAnimType else {
                return .None
            }
            return type
        }
        set {
            if self.badge == nil {
                self.badgeLabelInit()
            }
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeAniTypeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            removeAnimation()
            beginAnimation()
        }
    }
    
    public var badgeFrame:CGRect {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeFrameKey)
            guard let frame = obj as? CGRect else {
                return .zero
            }
            return frame
        }
        set {
            if self.badge == nil {
                self.badgeLabelInit()
            }
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeFrameKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.badge!.frame = newValue
        }
    }
    
    public var badgeCenterOffset:CGPoint {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCenterOffsetKey)
            guard let point = obj as? CGPoint else {
                return .zero
            }
            return point
        }
        set {
            if self.badge == nil {
                self.badgeLabelInit()
            }
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCenterOffsetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.badge!.center = CGPoint(x: CGRectGetWidth(self.frame) + 2 + newValue.x, y: newValue.y)
        }
    }
    
    public var badgeRadius:CGFloat {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeRadiusKey)
            guard let radius = obj as? CGFloat else {
                return 0
            }
            return radius
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeRadiusKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if self.badge == nil {
                self.badgeLabelInit()
            }
        }
    }
    
    public var badgeMaximumBadgeNumber:Int {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeMaximumBadgeNumberKey)
            guard let radius = obj as? Int else {
                return kPTBAdgeDefaultMaximumBadgeNumber
            }
            return radius
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeMaximumBadgeNumberKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if self.badge == nil {
                self.badgeLabelInit()
            }
        }
    }
    
    public func showBadge() {
        self.showBadge(style: .RedDot, value: 0, aniType: .None)
    }
    
    public func showNumberBadge(value:Int,animationType:PTBadgeAnimType) {
        self.aniType = animationType
        self.showNumberBadge(value: value)
        if animationType != .None {
            self.beginAnimation()
        }
    }
    
    public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) {
        self.aniType = aniType
        switch style {
        case .RedDot:
            self.showRedDotBadge()
        case .Number:
            var newValue = 0
            if value is Int {
                newValue = value as! Int
            } else {
                newValue = 0
            }
            self.showNumberBadge(value: newValue)
        case .New:
            var newValue = ""
            if value is String {
                newValue = value as! String
            } else {
                newValue = "new"
            }
            self.showNewBadge(newValue: newValue)
        }
    }
    
    public func showRedDotBadge() {
        if self.badge!.tag != PTBadgeStyle.RedDot.rawValue {
            self.badge!.text = ""
            self.badge!.tag = PTBadgeStyle.RedDot.rawValue
            self.resetBadgeForRedDot()
            self.badge!.layer.cornerRadius = CGRectGetHeight(self.badge!.frame) / 2
        }
        self.badge!.isHidden = false
    }
    
    public func resetBadgeForRedDot() {
        if self.badgeRadius > 0 {
            self.badge!.frame = CGRectMake(self.badge!.center.x - self.badgeRadius, self.badge!.center.y + self.badgeRadius, self.badgeRadius * 2, self.badgeRadius * 2)
        }
    }
    
    public func showNewBadge(newValue:String = "new") {
        if self.badge!.tag != PTBadgeStyle.New.rawValue {
            self.badge!.text = newValue
            self.badge!.tag = PTBadgeStyle.New.rawValue
            self.adjustLabelWidth(label: self.badge!)
            var frame = self.badge!.frame
            frame.size.width += 0
            frame.size.height += 4
            self.badge!.frame = frame
            self.badge!.center = CGPoint(x: CGRectGetWidth(self.frame) + 2 + self.badgeCenterOffset.x, y: self.badgeCenterOffset.y)
            self.badge!.font = .appfont(size: 9)
            self.badge!.layer.cornerRadius = CGRectGetHeight(self.badge!.frame) / 3
        }
        self.badge!.isHidden = false
    }
    
    public func showNumberBadge(value:Int) {
        if value < 0 {
            return
        }
        
        self.badge!.isHidden = value == 0
        self.badge!.tag = PTBadgeStyle.Number.rawValue
        self.badge!.font = self.badgeFont
        self.badge!.text = value > self.badgeMaximumBadgeNumber ? "\(self.badgeMaximumBadgeNumber)+" : "\(value)"
        self.adjustLabelWidth(label: self.badge!)
        var frame = self.badge!.frame
        frame.size.width += 4
        frame.size.height += 4
        if CGRectGetWidth(frame) < CGRectGetHeight(frame) {
            frame.size.width = CGRectGetHeight(frame)
        }
        self.badge!.frame = frame
        self.badge!.center = CGPoint(x: CGRectGetWidth(self.frame) + 2 + self.badgeCenterOffset.x, y: self.badgeCenterOffset.y)
        self.badge!.layer.cornerRadius = CGRectGetHeight(self.badge!.frame) / 2
    }
    
    public func clearBadge() {
        if self.badge != nil {
            self.badge!.isHidden = true
        }
    }
    
    public func resumeBadge() {
        if self.badge!.isHidden && self.badge != nil {
            self.badge!.isHidden = false
        }
    }
    
    func adjustLabelWidth(label:UILabel) {
        label.numberOfLines = 0
        var frame = label.frame
        frame.size.width = label.sizeFor(height: CGRectGetHeight(label.frame)).width
        label.frame = frame
    }
    
    func removeAnimation() {
        self.badge!.layer.removeAllAnimations()
    }
    
    func beginAnimation() {
        switch aniType {
        case .None:
            break
        case .Scale:
            badge!.layer.add(CAAnimation.scale(fromScale: 1.4, toScale: 0.6, duration: 1, repeatCount: MAXFLOAT), forKey: kBadgeScaleAniKey)
        case .Shake:
            badge!.layer.add(CAAnimation.shakeAnimation(repeatTimes: MAXFLOAT, duration: 1, forObj: self.badge!.layer), forKey: kBadgeShakeAniKey)
        case .Bounce:
            badge!.layer.add(CAAnimation.bounceAnimation(repeatTimes: MAXFLOAT, duration: 1, forObj: self.badge!.layer), forKey: kBadgeBounceAniKey)
        case .Breathe:
            badge!.layer.add(CAAnimation.bounceAnimation(repeatTimes: MAXFLOAT, duration: 1, forObj: self.badge!.layer), forKey: kBadgeBounceAniKey)
        }
    }
}
