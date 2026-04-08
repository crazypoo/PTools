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

// MARK: - Associated Keys
private struct PTBadgeKeys {
    static var badge: UInt8 = 0
    static var config: UInt8 = 0
    static var removeCallback: UInt8 = 0
}

extension UIView: PTBadgeProtocol {
    
    // MARK: - Protocol Properties
    
    public var badge: UILabel? {
        get { objc_getAssociatedObject(self, &PTBadgeKeys.badge) as? UILabel }
        set { objc_setAssociatedObject(self, &PTBadgeKeys.badge, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 统一的配置入口。修改配置后，调用展示方法即可生效。
    public var badgeConfig: PTBadgeConfiguration {
        get {
            if let config = objc_getAssociatedObject(self, &PTBadgeKeys.config) as? PTBadgeConfiguration {
                return config
            }
            let defaultConfig = PTBadgeConfiguration()
            self.badgeConfig = defaultConfig
            return defaultConfig
        }
        set {
            objc_setAssociatedObject(self, &PTBadgeKeys.config, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateBadgeAppearance() // 配置改变时，刷新 UI
        }
    }
    
    public var badgeRemoveCallback: (() -> Void)? {
        get { objc_getAssociatedObject(self, &PTBadgeKeys.removeCallback) as? (() -> Void) }
        set { objc_setAssociatedObject(self, &PTBadgeKeys.removeCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - Initialization & Setup
    
    private func badgeLabelInit() {
        if self.badge == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.isUserInteractionEnabled = true
            label.isHidden = false
            self.addSubview(label)
            self.bringSubviewToFront(label)
            self.badge = label
            
            updateBadgeAppearance()
            setupBadgeGesture()
        }
    }
    
    private func updateBadgeAppearance() {
        guard let badge = self.badge else { return }
        badge.backgroundColor = badgeConfig.bgColor
        badge.textColor = badgeConfig.textColor
        badge.font = badgeConfig.font
        // 如果有自定义的边框和圆角方法，可以在这里统一调用
        // 2. 边框设置 (补齐原有的逻辑)
        if badgeConfig.borderWidth > 0 {
            badge.layer.borderWidth = badgeConfig.borderWidth
            badge.layer.borderColor = badgeConfig.borderColor.cgColor
        } else {
            badge.layer.borderWidth = 0
        }
    }
    
    // MARK: - Gesture Handling (Optimized)
    
    private func setupBadgeGesture() {
        badge?.gestureRecognizers?.removeAll()
        
        guard badgeConfig.canDragToDelete, let badge = self.badge else { return }
        
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(handleBadgePan(_:)))
        badge.addGestureRecognizer(panGes)
    }
    
    @objc private func handleBadgePan(_ pan: UIPanGestureRecognizer) {
        guard let badge = self.badge else { return }
        
        let translation = pan.translation(in: self)
        
        switch pan.state {
        case .changed:
            // 实时拖拽：相对位移
            badge.center = CGPoint(x: badge.center.x + translation.x, y: badge.center.y + translation.y)
            pan.setTranslation(.zero, in: self) // 重置 translation，防止偏移量累加
            
        case .ended, .cancelled:
            // 检查是否拖出了父视图边界
            let badgeFrameInSelf = badge.convert(badge.bounds, to: self)
            if self.bounds.intersects(badgeFrameInSelf) {
                // 没拖出去：弹回原位
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5) {
                    self.resetBadgeCenter()
                }
            } else {
                // 拖出去了：消除角标
                UIView.animate(withDuration: 0.2, animations: {
                    badge.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    badge.alpha = 0
                }) { _ in
                    badge.removeFromSuperview()
                    self.badge = nil
                    self.badgeRemoveCallback?()
                }
            }
        default:
            break
        }
    }
    
    private func resetBadgeCenter() {
        let offsetX = self.bounds.width + 2 + badgeConfig.centerOffset.x
        let offsetY = badgeConfig.centerOffset.y
        self.badge?.center = CGPoint(x: offsetX, y: offsetY)
    }
    
    // MARK: - Public API
    
    public func showBadge() {
        self.showBadge(style: .redDot, value: 0, aniType: .none)
    }
    
    public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) {
        if self.badge == nil { badgeLabelInit() }
        
        badgeConfig.animType = aniType
        
        switch style {
        case .redDot:
            showRedDotBadge()
        case .number:
            let val = (value as? Int) ?? 0
            showNumberBadge(value: val)
        case .new:
            let str = (value as? String) ?? "new"
            showNewBadge(newValue: str)
        }
        
        // 渲染完成后添加动画
        applyAnimation()
    }
    
    public func clearBadge() {
        self.badge?.isHidden = true
        removeAnimation()
    }
    
    public func resumeBadge() {
        if self.badge?.isHidden == true {
            self.badge?.isHidden = false
            applyAnimation()
        }
    }
    
    // MARK: - Private Layout Methods
    
    private func showRedDotBadge() {
        guard let badge = self.badge else { return }
        badge.text = ""
        badge.tag = PTBadgeStyle.redDot.rawValue
        
        let diameter = badgeConfig.radius * 2
        badge.frame.size = CGSize(width: diameter, height: diameter)
        resetBadgeCenter()
        badge.layer.cornerRadius = badgeConfig.radius
        badge.layer.masksToBounds = true
        badge.isHidden = false
    }
    
    private func showNumberBadge(value: Int) {
        guard value >= 0, let badge = self.badge else { return }
        
        if value == 0 {
            clearBadge()
            return
        }
        
        badge.isHidden = false
        badge.tag = PTBadgeStyle.number.rawValue
        badge.text = value > badgeConfig.maximumNumber ? "\(badgeConfig.maximumNumber)+" : "\(value)"
        adjustLabelSize(badge)
    }
    
    private func showNewBadge(newValue: String) {
        guard let badge = self.badge else { return }
        badge.isHidden = false
        badge.tag = PTBadgeStyle.new.rawValue
        badge.text = newValue
        adjustLabelSize(badge)
    }
    
    private func adjustLabelSize(_ label: UILabel) {
        label.sizeToFit()
        var frame = label.frame
        frame.size.width += 8
        frame.size.height = badgeConfig.font.pointSize + 6
        // 保证最小是一个圆
        if frame.size.width < frame.size.height {
            frame.size.width = frame.size.height
        }
        label.frame = frame
        resetBadgeCenter()
        label.layer.cornerRadius = frame.size.height / 2
        label.layer.masksToBounds = true
    }
    
    // MARK: - Animations
    
    private func removeAnimation() {
        self.badge?.layer.removeAllAnimations()
    }
    
    private func applyAnimation() {
        guard let layer = self.badge?.layer else { return }
        removeAnimation()
        
        let animType = badgeConfig.animType
        let key = animType.animationKey
        
        switch animType {
        case .none:
            break
        case .scale:
            layer.add(CAAnimation.scale(fromScale: 1.4, toScale: 0.6, duration: 1.0, repeatCount: .infinity), forKey: key)
        case .shake:
            layer.add(CAAnimation.shakeAnimation(repeatTimes: .infinity, duration: 1.0, offset: 5.0), forKey: key)
        case .bounce:
            layer.add(CAAnimation.bounceAnimation(repeatTimes: .infinity, duration: 1.0, offset: 5.0), forKey: key)
        case .breathe:
            // 修复了原来 Breathe 错调成 bounce 的 Bug，改用我们新写的 opacityForeverAnimation
            layer.add(CAAnimation.opacityForeverAnimation(time: 1.0), forKey: key)
        }
    }
}
