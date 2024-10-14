//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum InspectorColorStyle {
    case light, dark

    init(with traitCollection: UITraitCollection) {
        switch traitCollection.userInterfaceStyle {
        case .dark:
            self = .dark
        default:
            self = .light
        }
    }

    var textColor: UIColor {
        dynamicColor { colorStyle in
            switch colorStyle {
            case .light:
                return .darkText
            case .dark:
                return .white
            }
        }
    }

    var shadowColor: UIColor {
        dynamicColor { colorStyle in
            switch colorStyle {
            case .dark:
                return .black
            case .light:
                return .init(white: 0, alpha: disabledAlpha * 2)
            }
        }
    }

    var backgroundColor: UIColor {
        dynamicColor { colorStyle in
            switch colorStyle {
            case .dark:
                return UIColor(hex: 0x2C2C2E)
            case .light:
                return UIColor(hex: 0xF5F5F5)
            }
        }
    }

    var highlightBackgroundColor: UIColor {
        dynamicColor { colorStyle in
            switch colorStyle {
            case .dark:
                return UIColor(hex: 0x3A3A3C)
            case .light:
                return .white
            }
        }.withAlphaComponent(1 / 2)
    }

    var tintColor: UIColor {
        UIColor(hex: 0xBF5AF2)
    }

    var softTintColor: UIColor {
        tintColor.withAlphaComponent(disabledAlpha)
    }

    var blurStyle: UIBlurEffect.Style {
        switch self {
        case .dark:
            return .systemMaterial
        case .light:
            return .systemThinMaterial
        }
    }

    var selectedSegmentedControlForegroundColor: UIColor {
        dynamicColor { colorStyle in
            switch colorStyle {
            case .dark:
                return textColor
            case .light:
                return backgroundColor
            }
        }
    }

    public var emptyLayerColor: UIColor { wireframeLayerColor }

    public var wireframeLayerColor: UIColor { tertiaryTextColor }

    var cellHighlightBackgroundColor: UIColor {
        dynamicColor { colorStyle in
            switch colorStyle {
            case .light:
                return .white.withAlphaComponent(disabledAlpha)
            case .dark:
                return .white.withAlphaComponent(disabledAlpha / 7)
            }
        }
    }

    var layoutConstraintsCardBackgroundColor: UIColor {
        dynamicColor { colorStyle in
            switch colorStyle {
            case .light:
                return .white.withAlphaComponent(disabledAlpha * 3)
            case .dark:
                return softTintColor
            }
        }
    }

    var layoutConstraintsCardInactiveBackgroundColor: UIColor {
        accessoryControlBackgroundColor
    }

    var accessoryControlBackgroundColor: UIColor {
        textColor.withAlphaComponent(disabledAlpha / 4)
    }

    var accessoryControlDisabledBackgroundColor: UIColor {
        textColor.withAlphaComponent(disabledAlpha / 8)
    }

    var secondaryTextColor: UIColor {
        textColor.withAlphaComponent(disabledAlpha * 2)
    }

    var tertiaryTextColor: UIColor {
        textColor.withAlphaComponent(disabledAlpha)
    }

    var quaternaryTextColor: UIColor {
        textColor.withAlphaComponent(disabledAlpha / 2)
    }

    var disabledAlpha: CGFloat {
        switch self {
        case .dark:
            return 1 / 3
        case .light:
            return 0.2
        }
    }

    private func dynamicColor(_ closure: @escaping (InspectorColorStyle) -> UIColor) -> UIColor {
        UIColor { traitCollection in
            closure(.init(with: traitCollection))
        }
    }
}

// MARK: - ColorStylable

protocol ColorStylable {}

extension ColorStylable {
    var colorStyle: InspectorColorStyle { Inspector.sharedInstance.configuration.colorStyle }
}

extension UIView: ColorStylable {}

extension UIViewController: ColorStylable {}
