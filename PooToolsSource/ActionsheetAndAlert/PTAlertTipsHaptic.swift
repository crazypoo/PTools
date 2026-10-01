//
//  PTAlertTipsHaptic.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public enum PTAlertTipsHaptic {
    case success
    case warning
    case error
    case none
    
    @MainActor func impact() {
        #if os(iOS)
        // English: Route alert feedback through the shared semantic haptic backend.
        // Español: Enruta la respuesta háptica de la alerta mediante el backend semántico compartido.
        // 中文：提示反馈统一转发到共享的语义触觉后端。
        switch self {
        case .success:
            PTFeedbackCenter.shared.emit(.success)
        case .warning:
            PTFeedbackCenter.shared.emit(.warning)
        case .error:
            PTFeedbackCenter.shared.emit(.error)
        case .none:
            break
        }
        #endif
    }
}
