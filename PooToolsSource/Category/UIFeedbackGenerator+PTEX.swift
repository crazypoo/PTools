//
//  UIFeedbackGenerator.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && os(iOS)
import UIKit
#if SWIFT_PACKAGE
// English: Import the split Core target explicitly for the shared MainActor feedback bridge.
// Español: Importa explícitamente el target Core dividido para el puente compartido de feedback en MainActor.
// 中文：独立 SwiftPM 编译时，显式导入拆分后的 Core target 以使用共享的 MainActor 反馈桥接。
import PToolsCore
#endif

public extension UIFeedbackGenerator {
    
    static func impactOccurred(_ style: Style) {
        // English: Keep this compatibility API on MainActor and delegate policy to PTFeedbackCenter.
        // Español: Mantiene esta API compatible en MainActor y delega la política a PTFeedbackCenter.
        // 中文：兼容入口统一在 MainActor 执行，并交由 PTFeedbackCenter 决定反馈策略。
        PTMainActorBridge.perform {
            switch style {
            case .light:
                PTFeedbackCenter.shared.emit(.selectionChanged)
            case .medium:
                PTFeedbackCenter.shared.emit(.navigation)
            case .heavy:
                PTFeedbackCenter.shared.emit(.actionConfirmed)
            case .notificationError:
                PTFeedbackCenter.shared.emit(.error)
            case .notificationSuccess:
                PTFeedbackCenter.shared.emit(.success)
            case .notificationWarning:
                PTFeedbackCenter.shared.emit(.warning)
            case .selectionChanged:
                PTFeedbackCenter.shared.emit(.selectionChanged)
            }
        }
    }
    
    enum Style {
        
        case light
        case medium
        case heavy
        
        case notificationError
        case notificationSuccess
        case notificationWarning
        
        case selectionChanged
    }
}
#endif
