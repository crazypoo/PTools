//
//  UIView+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import QuartzCore
import SwifterSwift

extension UIView: PTBadgeProtocol {
    
    fileprivate var initialSubviewCenter: CGPoint! {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCenterKey)
            guard let label = obj as? CGPoint else {
                return CGPoint(x: CGRectGetWidth(self.frame) + 2 + self.badgeCenterOffset.x, y: self.badgeCenterOffset.y)
            }
            return label
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCenterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var initialChangeCenter: CGPoint? {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCenterChangeKey)
            guard let label = obj as? CGPoint else {
                return nil
            }
            return label
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCenterChangeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate func badgeLabelInit() {
        if self.badge == nil {
            self.badge = createBadgeLabel()
            badgeGestureSet()
        }
    }
    
    fileprivate func createBadgeLabel() -> UILabel {
        initialSubviewCenter = CGPoint(x: CGRectGetWidth(self.frame) + 2 + self.badgeCenterOffset.x, y: self.badgeCenterOffset.y)
        let redotWidth = kPTBAdgeDefaultRedDotRadius * 2
        let newLabel = UILabel(frame: CGRectMake(CGRectGetWidth(self.frame), -redotWidth, redotWidth, redotWidth))
        newLabel.textAlignment = .center
        newLabel.center = initialSubviewCenter
        newLabel.backgroundColor = self.badgeBgColor
        newLabel.textColor = self.badgeTextColor
        newLabel.text = ""
        newLabel.tag = PTBadgeStyle.RedDot.rawValue
        newLabel.isHidden = false
        newLabel.isUserInteractionEnabled = true
        self.addSubview(newLabel)
        self.bringSubviewToFront(newLabel)
        PTGCDManager.gcdMain {
            newLabel.viewCorner(radius: CGRectGetHeight(newLabel.frame) / 2,borderWidth: self.badgeBorderLine,borderColor: self.badgeBorderColor)
        }
        return newLabel
    }
    
    fileprivate func badgeGestureSet() {
        badge?.removeGestureRecognizers()
        if canDragToDelete {
            if badge != nil {
                let panGes = UIPanGestureRecognizer { sender in
                    let pan = sender as! UIPanGestureRecognizer
                    let location = pan.translation(in: self)
                    
                    switch pan.state {
                    case .began:
                        // 记录起始触摸点
                        self.initialChangeCenter = location
                    case .changed:
                        // 计算拖动偏移量
                        let offsetX = location.x - self.initialChangeCenter!.x
                        let offsetY = location.y - self.initialChangeCenter!.y
                        // 更新视图位置
                        self.badge!.center = CGPoint(x: self.badge!.center.x + offsetX, y: self.badge!.center.y + offsetY)
                        // 更新起始触摸点
                        self.initialChangeCenter = location
                    case .ended, .cancelled:
                        // 拖动结束，清除起始触摸点
                        self.initialChangeCenter = nil
                        // 检查视图位置是否超出父视图范围
                        let badgeFrameInSelf = self.badge!.convert(self.badge!.bounds, to: self)
                        if self.bounds.intersects(badgeFrameInSelf) {
                            self.badge!.center = self.initialSubviewCenter
                        } else {
                            self.badgeRemoveCallback?()
                            self.badge!.removeFromSuperview()
                        }
                    default:
                        break
                    }
                }
                self.badge!.addGestureRecognizer(panGes)
            }
        }
    }
    
    public var canDragToDeleteDuration: TimeInterval {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCanDragToDeleteLongPressTimeKey)
            guard let value = obj as? TimeInterval else {
                return 1
            }
            return value
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCanDragToDeleteLongPressTimeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var canDragToDelete: Bool {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCanDragToDeleteKey)
            guard let value = obj as? Bool else {
                return true
            }
            return value
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCanDragToDeleteKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            badgeGestureSet()
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
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeFontKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if self.badge == nil {
                self.badgeLabelInit()
            }
            self.badge!.font = newValue
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
    
    public var badgeFrame: CGRect {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeFrameKey)
            guard let frame = obj as? CGRect else {
                return .zero
            }
            return frame
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeFrameKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if self.badge == nil {
                self.badgeLabelInit()
            }
            self.badge!.frame = newValue
        }
    }
    
    public var badgeCenterOffset: CGPoint {
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
    
    public var badgeRadius: CGFloat {
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
            self.resetBadgeForRedDot()
        }
    }
    
    public var badgeMaximumBadgeNumber: Int {
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

    public var badgeRemoveCallback: PTActionTask? {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCanDragToDeleteCallbackKey)
            guard let callback = obj as? PTActionTask else {
                return nil
            }
            return callback
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeCanDragToDeleteCallbackKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var badgeBorderColor:UIColor {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeBorderLineColorKey)
            guard let callback = obj as? UIColor else {
                return .clear
            }
            return callback
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeBorderLineColorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if self.badge == nil {
                self.badgeLabelInit()
            } else {
                PTGCDManager.gcdMain {
                    self.badge!.viewCorner(radius: CGRectGetHeight(self.badge!.frame) / 2,borderWidth: self.badgeBorderLine, borderColor: self.badgeBorderColor)
                }
            }
        }
    }
    
    public var badgeBorderLine:CGFloat {
        get {
            let obj = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.badgeBorderLineKey)
            guard let callback = obj as? CGFloat else {
                return 0
            }
            return callback
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.badgeBorderLineKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if self.badge == nil {
                self.badgeLabelInit()
            } else {
                PTGCDManager.gcdMain {
                    self.badge!.viewCorner(radius: CGRectGetHeight(self.badge!.frame) / 2,borderWidth: self.badgeBorderLine, borderColor: self.badgeBorderColor)
                }
            }
        }
    }
    
    public func showBadge() {
        self.showBadge(style: .RedDot, value: 0, aniType: .None)
    }
    
    public func showNumberBadge(value: Int, animationType: PTBadgeAnimType) {
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
        if self.badge?.tag != PTBadgeStyle.RedDot.rawValue {
            self.badge?.text = ""
            self.badge?.tag = PTBadgeStyle.RedDot.rawValue
            self.resetBadgeForRedDot()
            PTGCDManager.gcdMain {
                self.badge?.viewCorner(radius: CGRectGetHeight(self.badge?.frame ?? .zero) / 2,borderWidth: self.badgeBorderLine,borderColor: self.badgeBorderColor)
            }
        }
        self.badge?.isHidden = false
    }
    
    public func resetBadgeForRedDot() {
        if self.badgeRadius > 0 {
            self.badge?.frame = CGRectMake(self.badge?.center.x ?? 0 - self.badgeRadius, self.badge?.center.y ?? 0 + self.badgeRadius, self.badgeRadius * 2, self.badgeRadius * 2)
        }
    }
    
    public func showNewBadge(newValue: String = "new") {
        if self.badge?.tag != PTBadgeStyle.New.rawValue {
            self.badge?.text = newValue
            self.badge?.tag = PTBadgeStyle.New.rawValue
            self.adjustLabelWidth(label: self.badge!)
            var frame = self.badge!.frame
            frame.size.width += 0
            frame.size.height = self.badge!.font.pointSize + 4
            self.badge?.frame = frame
            self.badge?.center = CGPoint(x: CGRectGetWidth(self.frame) + 2 + self.badgeCenterOffset.x, y: self.badgeCenterOffset.y)
            self.badge?.font = .appfont(size: 9)
            PTGCDManager.gcdMain {
                self.badge?.viewCorner(radius: CGRectGetHeight(self.badge?.frame ?? .zero) / 3,borderWidth: self.badgeBorderLine,borderColor: self.badgeBorderColor)
            }
        }
        self.badge?.isHidden = false
    }
    
    public func showNumberBadge(value: Int) {
        if value < 0 {
            return
        }
        
        self.badge?.isHidden = value == 0
        self.badge?.tag = PTBadgeStyle.Number.rawValue
        self.badge?.font = self.badgeFont
        self.badge?.text = value > self.badgeMaximumBadgeNumber ? "\(self.badgeMaximumBadgeNumber)+" : "\(value)"
        var frame = self.badge!.frame
        frame.size.width = self.badge?.sizeFor(height: CGRectGetHeight(self.badge!.frame)).width ?? 0 + 4
        frame.size.height = frame.size.width
        self.badge?.frame = frame
        self.badge?.center = CGPoint(x: CGRectGetWidth(self.frame) + 2 + self.badgeCenterOffset.x, y: self.badgeCenterOffset.y)
        PTGCDManager.gcdMain {
            self.badge?.viewCorner(radius: CGRectGetHeight(self.badge!.frame) / 2,borderWidth: self.badgeBorderLine,borderColor: self.badgeBorderColor)
        }
    }
    
    public func clearBadge() {
        self.badge?.isHidden = true
    }
    
    public func resumeBadge() {
        if self.badge?.isHidden == true {
            self.badge?.isHidden = false
        }
    }
    
    func adjustLabelWidth(label: UILabel) {
        label.numberOfLines = 0
        var frame = label.frame
        frame.size.width = label.sizeFor(height: CGRectGetHeight(label.frame)).width
        label.frame = frame
    }
    
    func removeAnimation() {
        self.badge?.layer.removeAllAnimations()
    }
    
    func beginAnimation() {
        switch aniType {
        case .None:
            break
        case .Scale:
            badge?.layer.add(CAAnimation.scale(fromScale: 1.4, toScale: 0.6, duration: 1, repeatCount: MAXFLOAT), forKey: kBadgeScaleAniKey)
        case .Shake:
            badge?.layer.add(CAAnimation.shakeAnimation(repeatTimes: MAXFLOAT, duration: 1, forObj: self.badge!.layer), forKey: kBadgeShakeAniKey)
        case .Bounce:
            badge?.layer.add(CAAnimation.bounceAnimation(repeatTimes: MAXFLOAT, duration: 1, forObj: self.badge!.layer), forKey: kBadgeBounceAniKey)
        case .Breathe:
            badge?.layer.add(CAAnimation.bounceAnimation(repeatTimes: MAXFLOAT, duration: 1, forObj: self.badge!.layer), forKey: kBadgeBounceAniKey)
        }
    }
}
