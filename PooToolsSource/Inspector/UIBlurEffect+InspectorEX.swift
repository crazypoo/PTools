//
//  UIBlurEffect+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIBlurEffect.Style: CustomStringConvertible {
    public var description: String {
        switch self {
        case .extraLight:
            return "Extra Light"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .regular:
            return "Regular"
        case .prominent:
            return "Prominent"
        case .systemUltraThinMaterial:
            return "Ultra Thin Material"
        case .systemThinMaterial:
            return "Thin Material"
        case .systemMaterial:
            return "Material"
        case .systemThickMaterial:
            return "Thick Material"
        case .systemChromeMaterial:
            return "Chrome Material"
        case .systemUltraThinMaterialLight:
            return "Ultra Thin Material Light"
        case .systemThinMaterialLight:
            return "Thin Material Light"
        case .systemMaterialLight:
            return "Material Light"
        case .systemThickMaterialLight:
            return "Thick Material Light"
        case .systemChromeMaterialLight:
            return "Chrome Material Light"
        case .systemUltraThinMaterialDark:
            return "Ultra Thin Material Dark"
        case .systemThinMaterialDark:
            return "Thin Material Dark"
        case .systemMaterialDark:
            return "Material Dark"
        case .systemThickMaterialDark:
            return "Thick Material Dark"
        case .systemChromeMaterialDark:
            return "Chrome Material Dark"
        @unknown default:
            return "Unkown"
        }
    }
}

extension UIBlurEffect.Style: @retroactive CaseIterable {
    public typealias AllCases = [UIBlurEffect.Style]

    public static let allCases: [UIBlurEffect.Style] = [
        .regular,
        .prominent,

        .systemUltraThinMaterial,
        .systemThinMaterial,
        .systemMaterial,
        .systemThickMaterial,
        .systemChromeMaterial,

        .systemUltraThinMaterialLight,
        .systemThinMaterialLight,
        .systemMaterialLight,
        .systemThickMaterialLight,
        .systemChromeMaterialLight,

        .systemUltraThinMaterialDark,
        .systemThinMaterialDark,
        .systemMaterialDark,
        .systemThickMaterialDark,
        .systemChromeMaterialDark
    ]
}

extension UIBlurEffect {
    var style: Style? {
        let description = self.description

        if description.contains("UIBlurEffectStyleExtraLight") {
            return .extraLight
        }
        if description.contains("UIBlurEffectStyleLight") {
            return .light
        }
        if description.contains("UIBlurEffectStyleDark") {
            return .dark
        }
        if description.contains("UIBlurEffectStyleRegular") {
            return .regular
        }
        if description.contains("UIBlurEffectStyleProminent") {
            return .prominent
        }

        if description.contains("UIBlurEffectStyleSystemUltraThinMaterialLight") {
            return .systemUltraThinMaterialLight
        }
        if description.contains("UIBlurEffectStyleSystemThinMaterialLight") {
            return .systemThinMaterialLight
        }
        if description.contains("UIBlurEffectStyleSystemMaterialLight") {
            return .systemMaterialLight
        }
        if description.contains("UIBlurEffectStyleSystemThickMaterialLight") {
            return .systemThickMaterialLight
        }
        if description.contains("UIBlurEffectStyleSystemChromeMaterialLight") {
            return .systemChromeMaterialLight
        }
        if description.contains("UIBlurEffectStyleSystemUltraThinMaterialDark") {
            return .systemUltraThinMaterialDark
        }
        if description.contains("UIBlurEffectStyleSystemThinMaterialDark") {
            return .systemThinMaterialDark
        }
        if description.contains("UIBlurEffectStyleSystemMaterialDark") {
            return .systemMaterialDark
        }
        if description.contains("UIBlurEffectStyleSystemThickMaterialDark") {
            return .systemThickMaterialDark
        }
        if description.contains("UIBlurEffectStyleSystemChromeMaterialDark") {
            return .systemChromeMaterialDark
        }
        if description.contains("UIBlurEffectStyleSystemUltraThinMaterial") {
            return .systemUltraThinMaterial
        }
        if description.contains("UIBlurEffectStyleSystemThinMaterial") {
            return .systemThinMaterial
        }
        if description.contains("UIBlurEffectStyleSystemMaterial") {
            return .systemMaterial
        }
        if description.contains("UIBlurEffectStyleSystemThickMaterial") {
            return .systemThickMaterial
        }
        if description.contains("UIBlurEffectStyleSystemChromeMaterial") {
            return .systemChromeMaterial
        }

        return nil
    }
}
