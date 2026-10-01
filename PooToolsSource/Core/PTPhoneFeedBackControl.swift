//
//  PTPhoneFeedBackControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/7.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

/// 统一的设备震动与触觉反馈控制工具
@available(*, deprecated, message: "Use PTFeedbackCenter or PTHapticEngine instead.")
public enum PTPhoneFeedbackControl {
    
    // MARK: - 传统系统震动
    
    /// 触发系统默认长震动 (常用于老机型或需要强烈震感的场景)
    public static func triggerSystemVibrate() {
        // English: Keep the legacy vibration entry while using the configured shared backend.
        // Español: Conserva la entrada heredada y usa el backend compartido configurado.
        // 中文：保留旧的震动入口，同时使用已配置的共享后端。
        PTMainActorBridge.perform {
            PTFeedbackCenter.shared.emitSystemVibration()
        }
    }
    
    // MARK: - UINotificationFeedbackGenerator (通知类型反馈)
    
    /// 触发通知类型反馈 (成功/警告/失败)
    /// - Parameter type: 反馈类型，默认为 .success
    public static func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        // English: Convert UIKit feedback types into stable semantic signals.
        // Español: Convierte los tipos de UIKit en señales semánticas estables.
        // 中文：将 UIKit 反馈类型转换为稳定的语义信号。
        PTMainActorBridge.perform {
            switch type {
            case .success:
                PTFeedbackCenter.shared.emit(.success)
            case .warning:
                PTFeedbackCenter.shared.emit(.warning)
            case .error:
                PTFeedbackCenter.shared.emit(.error)
            @unknown default:
                PTFeedbackCenter.shared.emit(.warning)
            }
        }
    }

    // MARK: - UIImpactFeedbackGenerator (物理碰撞反馈)
    
    /// 触发物理碰撞触觉反馈
    /// - Parameters:
    ///   - style: 震动反馈风格 (如 .light, .medium, .heavy, .rigid, .soft)
    ///   - intensity: 震动强度 (范围 0.0 ~ 1.0)。传 nil 则使用系统默认强度。仅支持 iOS 13.0+
    public static func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, intensity: CGFloat? = nil) {
        PTMainActorBridge.perform {
            _ = intensity
            switch style {
            case .light, .soft:
                PTFeedbackCenter.shared.emit(.selectionChanged)
            case .medium, .rigid:
                PTFeedbackCenter.shared.emit(.navigation)
            case .heavy:
                PTFeedbackCenter.shared.emit(.actionConfirmed)
            @unknown default:
                PTFeedbackCenter.shared.emit(.navigation)
            }
        }
    }
   
    // MARK: - UISelectionFeedbackGenerator (选择器反馈)
    
    /// 触发选择器变化反馈 (常用于滚轮、滑动列表、拨页等轻微段落感)
    public static func triggerSelection() {
        PTMainActorBridge.perform {
            PTFeedbackCenter.shared.emit(.selectionChanged)
        }
   }
}
