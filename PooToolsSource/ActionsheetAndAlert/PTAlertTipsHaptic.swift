//
//  PTAlertTipsHaptic.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

// English: Import the split Core target explicitly when the umbrella target builds under SwiftPM.
// Español: Importa explícitamente el target Core dividido cuando el umbrella se compila con SwiftPM.
// 中文：SwiftPM 编译聚合 target 时，显式导入拆分后的 Core target。
#if SWIFT_PACKAGE
import PToolsCore
#endif

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
