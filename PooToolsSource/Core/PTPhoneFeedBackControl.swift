//
//  PTPhoneFeedBackControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/7.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import AudioToolbox

/// 统一的设备震动与触觉反馈控制工具
public enum PTPhoneFeedbackControl {
    
    // MARK: - 传统系统震动
    
    /// 触发系统默认长震动 (常用于老机型或需要强烈震感的场景)
    public static func triggerSystemVibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    // MARK: - UINotificationFeedbackGenerator (通知类型反馈)
    
    /// 触发通知类型反馈 (成功/警告/失败)
    /// - Parameter type: 反馈类型，默认为 .success
    public static func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare() // 唤醒 Taptic Engine 硬件
            generator.notificationOccurred(type)
        }
    }

    // MARK: - UIImpactFeedbackGenerator (物理碰撞反馈)
    
    /// 触发物理碰撞触觉反馈
    /// - Parameters:
    ///   - style: 震动反馈风格 (如 .light, .medium, .heavy, .rigid, .soft)
    ///   - intensity: 震动强度 (范围 0.0 ~ 1.0)。传 nil 则使用系统默认强度。仅支持 iOS 13.0+
    public static func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, intensity: CGFloat? = nil) {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            
            if #available(iOS 13.0, *), let intensity = intensity {
                // iOS 13 新增功能：允许精细控制震动强度
                // 确保强度值在合法范围内 (0.0 到 1.0)
                let safeIntensity = max(0.0, min(1.0, intensity))
                generator.impactOccurred(intensity: safeIntensity)
            } else {
                generator.impactOccurred()
            }
        }
    }
   
    // MARK: - UISelectionFeedbackGenerator (选择器反馈)
    
    /// 触发选择器变化反馈 (常用于滚轮、滑动列表、拨页等轻微段落感)
    public static func triggerSelection() {
        DispatchQueue.main.async {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
   }
}
