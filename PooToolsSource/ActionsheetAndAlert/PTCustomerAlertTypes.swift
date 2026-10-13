//
//  PTCustomerAlertTypes.swift
//  PooTools
//
//  English: Keep public alert compatibility types independent from controller layout code.
//  Español: Mantiene los tipos públicos compatibles del alert separados del diseño del controlador.
//  中文：将公开 Alert 兼容类型从控制器布局代码中独立出来。
//

import UIKit

public typealias PTCustomerCustomerBlock = (_ alertCustomerView: UIView) -> Void

@objc public enum PTAlertAnimationType: Int {
    case Top
    case Bottom
    case Left
    case Right
    case Normal
}

@objcMembers
public class PTCustomBottomButtonModel: NSObject {
    public var titleName: String? = ""
    public var titleColor: UIColor? = .systemBlue
}

// English: Render alert actions as accessible capsules with one material decision point.
// Español: Renderiza las acciones de alerta como cápsulas accesibles con un único punto de decisión material.
// 中文：通过唯一的材质决策入口，将 Alert 操作渲染为可访问的胶囊按钮。
@MainActor
enum PTCustomerAlertButtonStyler {

    static func configure(
        _ button: PTBaseButton,
        title: String,
        titleColor: UIColor,
        role: PTCustomerAlertActionStyle,
        isPrimary: Bool,
        appearance: PTCustomerAlertButtonAppearance,
        font: UIFont,
        usesNativeGlassSurface: Bool
    ) {
        let semanticColor = titleColor.resolvedColor(with: button.traitCollection)
        let usesHighContrast = button.traitCollection.accessibilityContrast == .high
        let useNativeGlass = shouldUseNativeGlass(
            appearance: appearance,
            usesNativeGlassSurface: usesNativeGlassSurface,
            usesHighContrast: usesHighContrast
        )

        var configuration = makeConfiguration(
            isPrimary: isPrimary,
            useNativeGlass: useNativeGlass,
            usesHighContrast: usesHighContrast
        )
        configuration.cornerStyle = .capsule
        configuration.title = title
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: safeTitleInset(appearance.titleHorizontalInsets),
            bottom: 10,
            trailing: safeTitleInset(appearance.titleHorizontalInsets)
        )
        configuration.titleTextAttributesTransformer = .init { container in
            container.merging(
                AttributeContainer.font(PTUIAccessibility.scaledFont(font))
            )
        }

        if isPrimary {
            configuration.baseBackgroundColor = semanticColor
            configuration.baseForegroundColor = contrastingColor(for: semanticColor)
        } else {
            configuration.baseBackgroundColor = semanticColor.withAlphaComponent(0.14)
            configuration.baseForegroundColor = semanticColor
        }

        if role == .destructive, isPrimary {
            configuration.baseBackgroundColor = UIColor.systemRed.resolvedColor(with: button.traitCollection)
            configuration.baseForegroundColor = .white
        }

        // English: The configuration owns title and state colors; avoid setTitleColor conflicts.
        // Español: La configuración controla el título y los colores de estado; evita conflictos con setTitleColor.
        // 中文：由 Configuration 统一管理标题和状态颜色，避免与 setTitleColor 相互覆盖。
        button.configuration = configuration
        button.expandClickEdgeInsets = .zero
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
        button.accessibilityTraits = .button
        if role == .destructive {
            button.accessibilityHint = "Destructive action / Acción destructiva / 危险操作"
        } else {
            button.accessibilityHint = nil
        }

        button.configurationUpdateHandler = { button in
            // English: Keep the system state transition while avoiding a second animation layer.
            // Español: Conserva la transición de estado del sistema sin añadir otra capa de animación.
            // 中文：保留系统状态反馈，不额外叠加第二套动画。
            button.alpha = button.isEnabled
                ? (button.isHighlighted ? 0.72 : 1)
                : 0.45
        }
        button.setNeedsUpdateConfiguration()
    }

    private static func makeConfiguration(
        isPrimary: Bool,
        useNativeGlass: Bool,
        usesHighContrast: Bool
    ) -> UIButton.Configuration {
        if usesHighContrast {
            return isPrimary ? .filled() : .bordered()
        }

        #if compiler(>=6.2)
        if #available(iOS 26.0, *), useNativeGlass {
            return isPrimary ? .prominentGlass() : .glass()
        }
        #endif

        return isPrimary ? .filled() : .tinted()
    }

    private static func shouldUseNativeGlass(
        appearance: PTCustomerAlertButtonAppearance,
        usesNativeGlassSurface: Bool,
        usesHighContrast: Bool
    ) -> Bool {
        guard appearance.visualStyle == .glassPreferred,
              !usesNativeGlassSurface,
              !PTUIAccessibility.reduceTransparencyEnabled,
              !usesHighContrast else {
            return false
        }

        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            return true
        }
        return false
        #else
        return false
        #endif
    }

    private static func safeTitleInset(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 16 }
        return min(40, max(8, value))
    }

    private static func contrastingColor(for color: UIColor) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return .white
        }

        let luminance = red * 0.299 + green * 0.587 + blue * 0.114
        return luminance > 0.62 ? .black : .white
    }
}
