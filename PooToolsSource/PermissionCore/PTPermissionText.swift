//
//  PTPermissionText.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

enum PTPermissionText {
    @MainActor static func permission_name(for kind: PTPermission.Kind) -> String {
        switch kind {
        case .camera:
            return "PT Permission camera".localized()
        case .photoLibrary:
            return "PT Permission photoLibrary".localized()
        case .microphone:
            return "PT Permission microphone".localized()
        case .calendar(access: .full), .calendar(access: .write):
            return "PT Permission calendar".localized()
        case .contacts:
            return "PT Permission contacts".localized()
        case .reminders:
            return "PT Permission reminders".localized()
        case .speech:
            return "PT Permission speech".localized()
        case .motion:
            return "PT Permission motion".localized()
        case .mediaLibrary:
            return "PT Permission media library".localized()
        case .bluetooth:
            return "PT Permission bluetooth".localized()
        case .notification:
            return "PT Permission notification".localized()
        case .location(access: .whenInUse):
            return "PT Permission location when in use".localized()
        case .location(access: .always):
            return "PT Permission location always".localized()
        case .tracking:
            return "PT Permission tracking".localized()
        case .faceID:
            return "PT Permission faceid".localized()
        case .siri:
            return "PT Permission siri".localized()
        case .health:
            return "PT Permission health".localized()
#if POOTOOLS_SPLIT_PERMISSION_CORE
        case .custom(let value):
            // English: Preserve custom permission labels in the split core without requiring a new localization key.
            // Español: Conserva las etiquetas de permisos personalizados sin exigir una nueva clave de localización.
            // 中文：拆分 Core 后保留自定义权限名称，不强制新增本地化键。
            return value
#endif
        }
    }
}
