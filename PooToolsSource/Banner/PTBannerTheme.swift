// English: Adaptive banner appearance with accessibility-aware UIKit colors.
// Español: Apariencia adaptativa con colores UIKit conscientes de accesibilidad.
// 中文：支持无障碍适配的 UIKit 自适应 Banner 外观。

import UIKit
#if canImport(PToolsSymbols)
import PToolsSymbols
#endif

@MainActor
public struct PTBannerAppearance {
    public let backgroundColor: UIColor
    public let tintColor: UIColor
    public let titleColor: UIColor
    public let subtitleColor: UIColor
    public let borderColor: UIColor
    public let symbol: PTSymbol?

    public init(backgroundColor: UIColor,
                tintColor: UIColor,
                titleColor: UIColor = .label,
                subtitleColor: UIColor = .secondaryLabel,
                borderColor: UIColor = .clear,
                symbol: PTSymbol? = nil) {
        self.backgroundColor = backgroundColor
        self.tintColor = tintColor
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.borderColor = borderColor
        self.symbol = symbol
    }
}

@MainActor
public protocol PTBannerThemeProviding: AnyObject {
    func appearance(for style: PTBannerStyle, traits: UITraitCollection) -> PTBannerAppearance
}

@MainActor
public final class PTBannerDefaultTheme: PTBannerThemeProviding {
    public init() {}

    public func appearance(for style: PTBannerStyle, traits: UITraitCollection) -> PTBannerAppearance {
        let tint: UIColor
        let symbol: PTSymbol?
        switch style {
        case .info:
            tint = .systemBlue
            symbol = PTSymbol(rawValue: "info.circle")
        case .success:
            tint = .systemGreen
            symbol = .checkmarkCircle
        case .warning:
            tint = .systemOrange
            symbol = .exclamationmarkTriangle
        case .danger:
            tint = .systemRed
            symbol = .xmarkCircle
        case .neutral:
            tint = .secondaryLabel
            symbol = nil
        case .custom:
            tint = .tintColor
            symbol = nil
        }
        let border = traits.accessibilityContrast == .high ? tint : .separator
        return PTBannerAppearance(backgroundColor: .secondarySystemBackground,
                                  tintColor: tint,
                                  borderColor: border,
                                  symbol: symbol)
    }
}
