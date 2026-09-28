// English: Shared accessibility contracts, focus handling and lightweight audits.
// Español: Contratos compartidos de accesibilidad, gestión del foco y auditorías ligeras.
// 中文：统一无障碍契约、焦点处理和轻量审计。

import Foundation

#if canImport(UIKit)
import UIKit
#endif

public enum PTAccessibilityRole: String, Codable, Sendable {
    case button
    case header
    case image
    case link
    case textField
    case adjustable
    case none
}

public struct PTAccessibilityEnvironment: Codable, Hashable, Sendable {
    public let isVoiceOverRunning: Bool
    public let isReduceMotionEnabled: Bool
    public let isReduceTransparencyEnabled: Bool
    public let isDifferentiateWithoutColorEnabled: Bool
    public let isButtonShapesEnabled: Bool
    public let contentSizeCategory: String
    public let layoutDirection: String

    public init(isVoiceOverRunning: Bool = false,
                isReduceMotionEnabled: Bool = false,
                isReduceTransparencyEnabled: Bool = false,
                isDifferentiateWithoutColorEnabled: Bool = false,
                isButtonShapesEnabled: Bool = false,
                contentSizeCategory: String = "UICTContentSizeCategoryL",
                layoutDirection: String = "leftToRight") {
        self.isVoiceOverRunning = isVoiceOverRunning
        self.isReduceMotionEnabled = isReduceMotionEnabled
        self.isReduceTransparencyEnabled = isReduceTransparencyEnabled
        self.isDifferentiateWithoutColorEnabled = isDifferentiateWithoutColorEnabled
        self.isButtonShapesEnabled = isButtonShapesEnabled
        self.contentSizeCategory = contentSizeCategory
        self.layoutDirection = layoutDirection
    }

    #if canImport(UIKit)
    @MainActor
    public static var current: PTAccessibilityEnvironment {
        let traits = UITraitCollection.current
        return PTAccessibilityEnvironment(
            isVoiceOverRunning: UIAccessibility.isVoiceOverRunning,
            isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
            isReduceTransparencyEnabled: UIAccessibility.isReduceTransparencyEnabled,
            isDifferentiateWithoutColorEnabled: UIAccessibility.shouldDifferentiateWithoutColor,
            isButtonShapesEnabled: UIAccessibility.buttonShapesEnabled,
            contentSizeCategory: traits.preferredContentSizeCategory.rawValue,
            layoutDirection: UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft ? "rightToLeft" : "leftToRight"
        )
    }
    #endif
}

public struct PTAccessibilityDescriptor: Codable, Hashable, Sendable {
    public let label: String?
    public let value: String?
    public let hint: String?
    public let role: PTAccessibilityRole
    public let traits: [String]

    public init(label: String? = nil,
                value: String? = nil,
                hint: String? = nil,
                role: PTAccessibilityRole = .none,
                traits: [String] = []) {
        self.label = label; self.value = value; self.hint = hint; self.role = role; self.traits = traits
    }
}

public struct PTAccessibilityAnnouncement: Sendable, Hashable {
    public let message: String
    public let priority: Int

    public init(message: String, priority: Int = 0) {
        self.message = message; self.priority = priority
    }
}

public enum PTAccessibilityAuditIssue: String, Codable, Sendable {
    case missingLabel
    case smallHitTarget
    case likelyDynamicTypeClipping
}

#if canImport(UIKit)
@MainActor
public final class PTAccessibilityFocusCoordinator {
    public static let shared = PTAccessibilityFocusCoordinator()
    private weak var currentView: UIView?
    private weak var previousView: UIView?

    public init() {}

    public func moveFocus(to view: UIView) {
        previousView = currentView
        currentView = view
        UIAccessibility.post(notification: .layoutChanged, argument: view)
    }

    public func captureFocus() { previousView = currentView }

    public func restoreFocus() {
        guard let previousView else { return }
        currentView = previousView
        UIAccessibility.post(notification: .layoutChanged, argument: previousView)
    }

    public func announce(_ announcement: PTAccessibilityAnnouncement) {
        UIAccessibility.post(notification: .announcement, argument: announcement.message)
    }

    public func apply(_ descriptor: PTAccessibilityDescriptor, to view: UIView) {
        view.isAccessibilityElement = descriptor.role != .none || descriptor.label != nil
        view.accessibilityLabel = descriptor.label
        view.accessibilityValue = descriptor.value
        view.accessibilityHint = descriptor.hint
        if descriptor.role == .button { view.accessibilityTraits.insert(.button) }
        if descriptor.role == .header { view.accessibilityTraits.insert(.header) }
        if descriptor.role == .link { view.accessibilityTraits.insert(.link) }
    }

    public func audit(_ view: UIView, minimumHitTarget: CGSize = .init(width: 44, height: 44)) -> [PTAccessibilityAuditIssue] {
        var issues: [PTAccessibilityAuditIssue] = []
        if view.isAccessibilityElement && (view.accessibilityLabel?.isEmpty ?? true) { issues.append(.missingLabel) }
        if view.isAccessibilityElement && (view.bounds.width < minimumHitTarget.width || view.bounds.height < minimumHitTarget.height) {
            issues.append(.smallHitTarget)
        }
        if let label = view as? UILabel, label.adjustsFontForContentSizeCategory == false,
           label.numberOfLines != 1 { issues.append(.likelyDynamicTypeClipping) }
        return issues
    }
}

@MainActor
public enum PTAccessibility {
    public static func scaledFont(for textStyle: UIFont.TextStyle, baseFont: UIFont? = nil) -> UIFont {
        let base = baseFont ?? UIFont.preferredFont(forTextStyle: textStyle)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }

    public static func animationDuration(_ duration: TimeInterval) -> TimeInterval {
        UIAccessibility.isReduceMotionEnabled ? 0 : max(0, duration)
    }

    public static func shouldUseTransparency() -> Bool { !UIAccessibility.isReduceTransparencyEnabled }
}
#endif
