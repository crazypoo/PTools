// English: Shared Form theme, keyboard, and accessibility adapters.
// Español: Adaptadores compartidos de tema, teclado y accesibilidad para Form.
// 中文：Form 共享的主题、键盘和无障碍适配器。

import Foundation

#if canImport(UIKit)
import UIKit
#if SWIFT_PACKAGE
import PToolsTheme
import PToolsAccessibility
import ptools
#else
#if canImport(PToolsTheme)
import PToolsTheme
#endif
#if canImport(PToolsAccessibility)
import PToolsAccessibility
#endif
#endif

@MainActor
public final class PTFormThemeAdapter {
    public private(set) var resolver: PTThemeResolver

    public init(resolver: PTThemeResolver? = nil) {
        self.resolver = resolver ?? PTThemeRegistry.shared.resolver()
    }

    public func update(resolver: PTThemeResolver) {
        self.resolver = resolver
    }

    public func backgroundColor() -> UIColor { resolver.color(.backgroundPrimary) }
    public func fieldColor() -> UIColor { resolver.color(.surface) }
    public func primaryTextColor() -> UIColor { resolver.color(.textPrimary) }
    public func secondaryTextColor() -> UIColor { resolver.color(.textSecondary) }
    public func separatorColor() -> UIColor { resolver.color(.separator) }
    public func accentColor() -> UIColor { resolver.color(.accent) }
    public func errorColor() -> UIColor { resolver.color(.danger) }
    public func bodyFont() -> UIFont { resolver.font(resolver.theme.typography.body) }
    public func titleFont() -> UIFont { resolver.font(resolver.theme.typography.title) }
    public func cornerRadius() -> CGFloat { CGFloat(resolver.theme.radii.medium) }
}

@MainActor
public final class PTFormKeyboardCoordinator {
    public init() {}

    public func attach(to view: UIView,
                       previous: @escaping @MainActor @Sendable () -> Void,
                       next: @escaping @MainActor @Sendable () -> Void,
                       done: @escaping @MainActor @Sendable () -> Void,
                       hasPrevious: Bool,
                       hasNext: Bool) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let previousItem = UIBarButtonItem(title: "Previous", style: .plain, target: nil, action: nil)
        previousItem.primaryAction = UIAction { _ in previous() }
        previousItem.isEnabled = hasPrevious
        let nextItem = UIBarButtonItem(title: hasNext ? "Next" : "Done", style: .plain, target: nil, action: nil)
        nextItem.primaryAction = UIAction { _ in hasNext ? next() : done() }
        let flexible = UIBarButtonItem(systemItem: .flexibleSpace)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneItem.primaryAction = UIAction { _ in done() }
        toolbar.items = [previousItem, nextItem, flexible, doneItem]
        if let textField = view as? UITextField {
            textField.inputAccessoryView = toolbar
        } else if let textView = view as? UITextView {
            textView.inputAccessoryView = toolbar
        }
    }
}

@MainActor
public enum PTFormAccessibilityAdapter {
    public static func apply(field: PTFormField,
                             value: String,
                             issue: String?,
                             to view: UIView) {
        view.isAccessibilityElement = true
        view.accessibilityLabel = field.title
        view.accessibilityValue = value.isEmpty ? nil : value
        var hints: [String] = []
        if field.rules.contains(.required) { hints.append("Required") }
        if field.isReadOnly { hints.append("Read only") }
        if let issue, !issue.isEmpty { hints.append(issue) }
        view.accessibilityHint = hints.isEmpty ? nil : hints.joined(separator: ", ")
        if !field.isEnabled { view.accessibilityTraits.insert(.notEnabled) }
        if field.isReadOnly { view.accessibilityTraits.insert(.staticText) }
    }

    public static func announceValidationFailure(_ issue: PTFormValidationIssue) {
        PTAccessibilityFocusCoordinator.shared.announce(.init(message: issue.message))
    }
}
#endif
