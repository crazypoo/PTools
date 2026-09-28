// English: Typed semantic design tokens for iOS 17+ UIKit components.
// Español: Tokens semánticos tipados para componentes UIKit de iOS 17+.
// 中文：面向 iOS 17+ UIKit 组件的类型化语义设计令牌。

import Foundation

#if canImport(UIKit)
import UIKit
#endif

public struct PTColorValue: Codable, Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
        self.alpha = min(max(alpha, 0), 1)
    }

    #if canImport(UIKit)
    @MainActor
    public var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    #endif
}

public struct PTAdaptiveColor: Codable, Hashable, Sendable {
    public let light: PTColorValue
    public let dark: PTColorValue
    public let highContrastLight: PTColorValue?
    public let highContrastDark: PTColorValue?

    public init(light: PTColorValue,
                dark: PTColorValue? = nil,
                highContrastLight: PTColorValue? = nil,
                highContrastDark: PTColorValue? = nil) {
        self.light = light
        self.dark = dark ?? light
        self.highContrastLight = highContrastLight
        self.highContrastDark = highContrastDark
    }

    public func value(isDark: Bool, highContrast: Bool) -> PTColorValue {
        if isDark { return highContrast ? (highContrastDark ?? dark) : dark }
        return highContrast ? (highContrastLight ?? light) : light
    }
}

public enum PTColorToken: String, Codable, Sendable, CaseIterable {
    case backgroundPrimary
    case backgroundSecondary
    case surface
    case surfaceElevated
    case textPrimary
    case textSecondary
    case separator
    case accent
    case success
    case warning
    case danger
}

public struct PTColorPalette: Codable, Hashable, Sendable {
    public let backgroundPrimary: PTAdaptiveColor
    public let backgroundSecondary: PTAdaptiveColor
    public let surface: PTAdaptiveColor
    public let surfaceElevated: PTAdaptiveColor
    public let textPrimary: PTAdaptiveColor
    public let textSecondary: PTAdaptiveColor
    public let separator: PTAdaptiveColor
    public let accent: PTAdaptiveColor
    public let success: PTAdaptiveColor
    public let warning: PTAdaptiveColor
    public let danger: PTAdaptiveColor

    public init(backgroundPrimary: PTAdaptiveColor,
                backgroundSecondary: PTAdaptiveColor,
                surface: PTAdaptiveColor,
                surfaceElevated: PTAdaptiveColor,
                textPrimary: PTAdaptiveColor,
                textSecondary: PTAdaptiveColor,
                separator: PTAdaptiveColor,
                accent: PTAdaptiveColor,
                success: PTAdaptiveColor,
                warning: PTAdaptiveColor,
                danger: PTAdaptiveColor) {
        self.backgroundPrimary = backgroundPrimary
        self.backgroundSecondary = backgroundSecondary
        self.surface = surface
        self.surfaceElevated = surfaceElevated
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.separator = separator
        self.accent = accent
        self.success = success
        self.warning = warning
        self.danger = danger
    }

    public func color(for token: PTColorToken) -> PTAdaptiveColor {
        switch token {
        case .backgroundPrimary: backgroundPrimary
        case .backgroundSecondary: backgroundSecondary
        case .surface: surface
        case .surfaceElevated: surfaceElevated
        case .textPrimary: textPrimary
        case .textSecondary: textSecondary
        case .separator: separator
        case .accent: accent
        case .success: success
        case .warning: warning
        case .danger: danger
        }
    }

    public static let `default` = PTColorPalette(
        backgroundPrimary: .init(light: .init(red: 0.97, green: 0.97, blue: 0.99), dark: .init(red: 0.07, green: 0.07, blue: 0.09)),
        backgroundSecondary: .init(light: .init(red: 0.93, green: 0.93, blue: 0.95), dark: .init(red: 0.12, green: 0.12, blue: 0.14)),
        surface: .init(light: .init(red: 1, green: 1, blue: 1), dark: .init(red: 0.11, green: 0.11, blue: 0.13)),
        surfaceElevated: .init(light: .init(red: 1, green: 1, blue: 1), dark: .init(red: 0.17, green: 0.17, blue: 0.19)),
        textPrimary: .init(light: .init(red: 0.08, green: 0.08, blue: 0.1), dark: .init(red: 0.96, green: 0.96, blue: 0.98)),
        textSecondary: .init(light: .init(red: 0.35, green: 0.35, blue: 0.38), dark: .init(red: 0.68, green: 0.68, blue: 0.72)),
        separator: .init(light: .init(red: 0.78, green: 0.78, blue: 0.82), dark: .init(red: 0.28, green: 0.28, blue: 0.31)),
        accent: .init(light: .init(red: 0.05, green: 0.35, blue: 0.95), dark: .init(red: 0.32, green: 0.55, blue: 1)),
        success: .init(light: .init(red: 0.1, green: 0.55, blue: 0.2), dark: .init(red: 0.35, green: 0.8, blue: 0.4)),
        warning: .init(light: .init(red: 0.85, green: 0.48, blue: 0.05), dark: .init(red: 1, green: 0.68, blue: 0.2)),
        danger: .init(light: .init(red: 0.8, green: 0.1, blue: 0.12), dark: .init(red: 1, green: 0.35, blue: 0.38))
    )
}

public struct PTFontToken: Codable, Hashable, Sendable {
    public let textStyle: String
    public let weight: Double
    public let fixedPointSize: Double?

    public init(textStyle: String, weight: Double = 0, fixedPointSize: Double? = nil) {
        self.textStyle = textStyle
        self.weight = weight
        self.fixedPointSize = fixedPointSize
    }
}

public struct PTTypography: Codable, Hashable, Sendable {
    public let largeTitle: PTFontToken
    public let title: PTFontToken
    public let body: PTFontToken
    public let caption: PTFontToken

    public init(largeTitle: PTFontToken = .init(textStyle: "largeTitle", weight: 0.7),
                title: PTFontToken = .init(textStyle: "headline", weight: 0.6),
                body: PTFontToken = .init(textStyle: "body"),
                caption: PTFontToken = .init(textStyle: "caption1")) {
        self.largeTitle = largeTitle
        self.title = title
        self.body = body
        self.caption = caption
    }
}

public struct PTSpacingScale: Codable, Hashable, Sendable {
    public let xSmall: Double
    public let small: Double
    public let medium: Double
    public let large: Double
    public let xLarge: Double

    public init(xSmall: Double = 4, small: Double = 8, medium: Double = 12, large: Double = 16, xLarge: Double = 24) {
        self.xSmall = xSmall; self.small = small; self.medium = medium; self.large = large; self.xLarge = xLarge
    }
}

public struct PTRadiusScale: Codable, Hashable, Sendable {
    public let small: Double
    public let medium: Double
    public let large: Double

    public init(small: Double = 6, medium: Double = 10, large: Double = 16) {
        self.small = small; self.medium = medium; self.large = large
    }
}

public struct PTElevationScale: Codable, Hashable, Sendable {
    public let low: Double
    public let medium: Double
    public let high: Double

    public init(low: Double = 1, medium: Double = 4, high: Double = 10) {
        self.low = low; self.medium = medium; self.high = high
    }
}

public struct PTMaterialPalette: Codable, Hashable, Sendable {
    public let usesGlassWhenAvailable: Bool
    public let reduceTransparencyFallback: PTColorToken

    public init(usesGlassWhenAvailable: Bool = true, reduceTransparencyFallback: PTColorToken = .surface) {
        self.usesGlassWhenAvailable = usesGlassWhenAvailable
        self.reduceTransparencyFallback = reduceTransparencyFallback
    }
}

public struct PTMotionToken: Codable, Hashable, Sendable {
    public let standardDuration: Double
    public let reducedMotionDuration: Double

    public init(standardDuration: Double = 0.25, reducedMotionDuration: Double = 0) {
        self.standardDuration = standardDuration; self.reducedMotionDuration = reducedMotionDuration
    }
}

public struct PTGlassToken: Codable, Hashable, Sendable {
    public let enabled: Bool
    public let cornerRadius: Double

    public init(enabled: Bool = true, cornerRadius: Double = 16) {
        self.enabled = enabled; self.cornerRadius = cornerRadius
    }
}

public struct PTTheme: Codable, Hashable, Sendable {
    public let colors: PTColorPalette
    public let typography: PTTypography
    public let spacing: PTSpacingScale
    public let radii: PTRadiusScale
    public let elevation: PTElevationScale
    public let materials: PTMaterialPalette
    public let motion: PTMotionToken
    public let glass: PTGlassToken

    public init(colors: PTColorPalette = .default,
                typography: PTTypography = .init(),
                spacing: PTSpacingScale = .init(),
                radii: PTRadiusScale = .init(),
                elevation: PTElevationScale = .init(),
                materials: PTMaterialPalette = .init(),
                motion: PTMotionToken = .init(),
                glass: PTGlassToken = .init()) {
        self.colors = colors; self.typography = typography; self.spacing = spacing; self.radii = radii
        self.elevation = elevation; self.materials = materials; self.motion = motion; self.glass = glass
    }
}

#if canImport(UIKit)
public enum PTThemeScope: Hashable, Sendable { case app; case scene(String); case viewController(String); case component(String) }

@MainActor
public final class PTThemeResolver {
    public let theme: PTTheme
    public init(theme: PTTheme = .init()) { self.theme = theme }

    public func color(_ token: PTColorToken, traits: UITraitCollection? = nil) -> UIColor {
        let traits = traits ?? UITraitCollection.current
        let adaptive = theme.colors.color(for: token)
        return adaptive.value(isDark: traits.userInterfaceStyle == .dark,
                              highContrast: traits.accessibilityContrast == .high).uiColor
    }

    public func font(_ token: PTFontToken, traits: UITraitCollection? = nil) -> UIFont {
        let style = UIFont.TextStyle(rawValue: token.textStyle)
        let base: UIFont
        if let fixedPointSize = token.fixedPointSize {
            base = UIFont.systemFont(ofSize: fixedPointSize, weight: UIFont.Weight(rawValue: token.weight))
        } else {
            base = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: style).pointSize,
                                     weight: UIFont.Weight(rawValue: token.weight))
        }
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }

    public func blurEffect() -> UIBlurEffect? {
        guard theme.materials.usesGlassWhenAvailable, !UIAccessibility.isReduceTransparencyEnabled else { return nil }
        return UIBlurEffect(style: .systemMaterial)
    }
}

@MainActor
public final class PTThemeRegistry {
    public static let shared = PTThemeRegistry()
    public var appTheme = PTTheme()
    private var scopedThemes: [PTThemeScope: PTTheme] = [:]

    public func set(_ theme: PTTheme, for scope: PTThemeScope) { scopedThemes[scope] = theme }
    public func remove(scope: PTThemeScope) { scopedThemes.removeValue(forKey: scope) }

    public func resolver(for viewController: UIViewController? = nil,
                         scene: UIWindowScene? = nil,
                         component: String? = nil) -> PTThemeResolver {
        if let component, let theme = scopedThemes[.component(component)] { return PTThemeResolver(theme: theme) }
        if let viewController, let theme = scopedThemes[.viewController(String(describing: type(of: viewController)))] { return PTThemeResolver(theme: theme) }
        if let scene, let identifier = scene.session.persistentIdentifier,
           let theme = scopedThemes[.scene(identifier)] { return PTThemeResolver(theme: theme) }
        return PTThemeResolver(theme: scopedThemes[.app] ?? appTheme)
    }
}
#endif
