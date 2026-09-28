// English: Sendable Form configuration types stay independent from UIKit.
// Español: Los tipos de configuración Sendable de Form permanecen independientes de UIKit.
// 中文：Sendable 的 Form 配置类型与 UIKit 解耦，便于跨 actor 安全传递。

import Foundation

public struct PTFormInsets: Sendable, Codable, Hashable {
    public var top: CGFloat
    public var leading: CGFloat
    public var bottom: CGFloat
    public var trailing: CGFloat

    public init(top: CGFloat = 0,
                leading: CGFloat = 0,
                bottom: CGFloat = 0,
                trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public static let zero = PTFormInsets()
}

public enum PTFormDimension: Sendable, Hashable {
    case automatic
    case fixed(CGFloat)
    case estimated(CGFloat)

    public var fallback: CGFloat {
        switch self {
        case .automatic: return 44
        case .fixed(let value), .estimated(let value): return max(1, value)
        }
    }
}

public enum PTFormTitlePlacement: Sendable, Hashable {
    case top
    case leading
    case hidden
}

public enum PTFormFieldLayout: Sendable, Hashable {
    case automatic
    case vertical
    case horizontal
}

public enum PTFormBackgroundStyle: Sendable, Hashable {
    case none
    case grouped
    case card
}

public enum PTFormSeparatorStyle: Sendable, Hashable {
    case none
    case fullWidth
    case inset
}

public struct PTFormShadowStyle: Sendable, Hashable {
    public var opacity: Float
    public var radius: CGFloat
    public var offsetY: CGFloat

    public init(opacity: Float = 0.08,
                radius: CGFloat = 8,
                offsetY: CGFloat = 2) {
        self.opacity = opacity
        self.radius = radius
        self.offsetY = offsetY
    }
}

public struct PTFormSectionAppearance: Sendable, Hashable {
    public var backgroundStyle: PTFormBackgroundStyle?
    public var cornerRadius: CGFloat?
    public var separatorStyle: PTFormSeparatorStyle?
    public var shadow: PTFormShadowStyle?

    public init(backgroundStyle: PTFormBackgroundStyle? = nil,
                cornerRadius: CGFloat? = nil,
                separatorStyle: PTFormSeparatorStyle? = nil,
                shadow: PTFormShadowStyle? = nil) {
        self.backgroundStyle = backgroundStyle
        self.cornerRadius = cornerRadius
        self.separatorStyle = separatorStyle
        self.shadow = shadow
    }
}

public struct PTFormSectionConfiguration: Sendable, Hashable {
    public var contentInsets: PTFormInsets?
    public var rowSpacing: CGFloat?
    public var topSpacing: CGFloat?
    public var bottomSpacing: CGFloat?
    public var headerSpacing: CGFloat?
    public var footerSpacing: CGFloat?
    public var headerHeight: PTFormDimension?
    public var footerHeight: PTFormDimension?
    public var appearance: PTFormSectionAppearance?

    public init(contentInsets: PTFormInsets? = nil,
                rowSpacing: CGFloat? = nil,
                topSpacing: CGFloat? = nil,
                bottomSpacing: CGFloat? = nil,
                headerSpacing: CGFloat? = nil,
                footerSpacing: CGFloat? = nil,
                headerHeight: PTFormDimension? = nil,
                footerHeight: PTFormDimension? = nil,
                appearance: PTFormSectionAppearance? = nil) {
        self.contentInsets = contentInsets
        self.rowSpacing = rowSpacing
        self.topSpacing = topSpacing
        self.bottomSpacing = bottomSpacing
        self.headerSpacing = headerSpacing
        self.footerSpacing = footerSpacing
        self.headerHeight = headerHeight
        self.footerHeight = footerHeight
        self.appearance = appearance
    }
}

public struct PTFormFieldConfiguration: Sendable, Hashable {
    public var layout: PTFormFieldLayout?
    public var contentInsets: PTFormInsets?
    public var titlePlacement: PTFormTitlePlacement?
    public var titleSpacing: CGFloat?
    public var minimumHeight: CGFloat?
    public var preferredHeight: PTFormDimension?
    public var showsValidationMessage: Bool?
    public var numeric: PTFormNumericControlConfiguration?
    public var date: PTFormDateConfiguration?
    public var textInput: PTFormTextInputConfiguration?

    public init(layout: PTFormFieldLayout? = nil,
                contentInsets: PTFormInsets? = nil,
                titlePlacement: PTFormTitlePlacement? = nil,
                titleSpacing: CGFloat? = nil,
                minimumHeight: CGFloat? = nil,
                preferredHeight: PTFormDimension? = nil,
                showsValidationMessage: Bool? = nil,
                numeric: PTFormNumericControlConfiguration? = nil,
                date: PTFormDateConfiguration? = nil,
                textInput: PTFormTextInputConfiguration? = nil) {
        self.layout = layout
        self.contentInsets = contentInsets
        self.titlePlacement = titlePlacement
        self.titleSpacing = titleSpacing
        self.minimumHeight = minimumHeight
        self.preferredHeight = preferredHeight
        self.showsValidationMessage = showsValidationMessage
        self.numeric = numeric
        self.date = date
        self.textInput = textInput
    }
}

public enum PTFormUpdatePolicy: Sendable, Hashable {
    case automatic
    case immediate
    case batched
}

public enum PTFormValidationTrigger: Sendable, Hashable {
    case onChange
    case onBlur
    case onSubmit
}

public struct PTFormValidationPolicy: Sendable, Hashable {
    public var trigger: PTFormValidationTrigger
    public var debounce: Duration
    public var showsInlineIssue: Bool
    public var focusesFirstInvalidField: Bool

    public init(trigger: PTFormValidationTrigger = .onChange,
                debounce: Duration = .milliseconds(250),
                showsInlineIssue: Bool = true,
                focusesFirstInvalidField: Bool = true) {
        self.trigger = trigger
        self.debounce = debounce
        self.showsInlineIssue = showsInlineIssue
        self.focusesFirstInvalidField = focusesFirstInvalidField
    }
}

public struct PTFormKeyboardPolicy: Sendable, Hashable {
    public var showsToolbar: Bool
    public var allowsCrossSectionNavigation: Bool

    public init(showsToolbar: Bool = true,
                allowsCrossSectionNavigation: Bool = true) {
        self.showsToolbar = showsToolbar
        self.allowsCrossSectionNavigation = allowsCrossSectionNavigation
    }
}

public enum PTFormSafeAreaPolicy: Sendable, Hashable {
    case automatic
    case respectContentInsets
    case ignore
}

public enum PTFormInteractionMode: Sendable, Hashable {
    case editable
    case readOnly
    case disabled
}

public enum PTFormSectionPresentation: Sendable, Hashable {
    case grouped
    case flat
}

public struct PTFormSubmissionBehavior: Sendable, Hashable {
    public var disablesFields: Bool
    public var showsOverlay: Bool
    public var submitButtonLoading: Bool

    public init(disablesFields: Bool = true,
                showsOverlay: Bool = false,
                submitButtonLoading: Bool = true) {
        self.disablesFields = disablesFields
        self.showsOverlay = showsOverlay
        self.submitButtonLoading = submitButtonLoading
    }
}

public struct PTFormConfiguration: Sendable, Hashable {
    public var contentInsets: PTFormInsets
    public var sectionSpacing: CGFloat
    public var defaultSectionConfiguration: PTFormSectionConfiguration
    public var defaultFieldConfiguration: PTFormFieldConfiguration
    public var updatePolicy: PTFormUpdatePolicy
    public var validationPolicy: PTFormValidationPolicy
    public var keyboardPolicy: PTFormKeyboardPolicy
    public var safeAreaPolicy: PTFormSafeAreaPolicy
    public var interactionMode: PTFormInteractionMode
    public var sectionPresentation: PTFormSectionPresentation
    public var hideEmptySections: Bool
    public var submissionBehavior: PTFormSubmissionBehavior

    public init(contentInsets: PTFormInsets = .init(top: 16, leading: 16, bottom: 24, trailing: 16),
                sectionSpacing: CGFloat = 20,
                defaultSectionConfiguration: PTFormSectionConfiguration = .init(),
                defaultFieldConfiguration: PTFormFieldConfiguration = .init(),
                updatePolicy: PTFormUpdatePolicy = .automatic,
                validationPolicy: PTFormValidationPolicy = .init(),
                keyboardPolicy: PTFormKeyboardPolicy = .init(),
                safeAreaPolicy: PTFormSafeAreaPolicy = .automatic,
                interactionMode: PTFormInteractionMode = .editable,
                sectionPresentation: PTFormSectionPresentation = .grouped,
                hideEmptySections: Bool = true,
                submissionBehavior: PTFormSubmissionBehavior = .init()) {
        self.contentInsets = contentInsets
        self.sectionSpacing = sectionSpacing
        self.defaultSectionConfiguration = defaultSectionConfiguration
        self.defaultFieldConfiguration = defaultFieldConfiguration
        self.updatePolicy = updatePolicy
        self.validationPolicy = validationPolicy
        self.keyboardPolicy = keyboardPolicy
        self.safeAreaPolicy = safeAreaPolicy
        self.interactionMode = interactionMode
        self.sectionPresentation = sectionPresentation
        self.hideEmptySections = hideEmptySections
        self.submissionBehavior = submissionBehavior
    }

    public static let plain = PTFormConfiguration(sectionPresentation: .flat,
                                                  hideEmptySections: true)
    public static let grouped = PTFormConfiguration(sectionPresentation: .grouped)
    public static let insetGrouped = PTFormConfiguration(
        contentInsets: .init(top: 16, leading: 20, bottom: 24, trailing: 20),
        sectionSpacing: 20,
        defaultSectionConfiguration: .init(
            contentInsets: .init(top: 8, leading: 16, bottom: 8, trailing: 16),
            rowSpacing: 8,
            appearance: .init(backgroundStyle: .grouped,
                              separatorStyle: .inset)))
    public static let card = PTFormConfiguration(
        defaultSectionConfiguration: .init(
            contentInsets: .init(top: 12, leading: 16, bottom: 12, trailing: 16),
            rowSpacing: 8,
            appearance: .init(backgroundStyle: .card,
                              cornerRadius: 12,
                              shadow: .init())))
}

public struct PTFormAccessibilityConfiguration: Sendable, Hashable {
    public var label: String?
    public var hint: String?

    public init(label: String? = nil, hint: String? = nil) {
        self.label = label
        self.hint = hint
    }
}

public enum PTFormFocusBehavior: Sendable, Hashable {
    case automatic
    case focusable
    case notFocusable
}

public enum PTFormDateMode: Sendable, Hashable {
    case date
    case time
    case dateAndTime
}

public enum PTFormTextContentType: Sendable, Hashable {
    case emailAddress
    case password
    case newPassword
    case telephoneNumber
    case name
    case username
    case oneTimeCode
}

public enum PTFormAutocapitalization: Sendable, Hashable {
    case none
    case words
    case sentences
    case allCharacters
}

public struct PTFormNumericControlConfiguration: Sendable, Hashable {
    public var minimum: Double
    public var maximum: Double
    public var step: Double

    public init(minimum: Double = 0, maximum: Double = 1, step: Double = 1) {
        self.minimum = minimum
        self.maximum = max(minimum, maximum)
        self.step = max(0, step)
    }
}

public struct PTFormDateConfiguration: Sendable, Hashable {
    public var mode: PTFormDateMode
    public var minimumDate: Date?
    public var maximumDate: Date?

    public init(mode: PTFormDateMode = .date,
                minimumDate: Date? = nil,
                maximumDate: Date? = nil) {
        self.mode = mode
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
    }
}

public struct PTFormTextInputConfiguration: Sendable, Hashable {
    public var contentType: PTFormTextContentType?
    public var capitalization: PTFormAutocapitalization?
    public var autocorrection: Bool?
    public var maximumLength: Int?

    public init(contentType: PTFormTextContentType? = nil,
                capitalization: PTFormAutocapitalization? = nil,
                autocorrection: Bool? = nil,
                maximumLength: Int? = nil) {
        self.contentType = contentType
        self.capitalization = capitalization
        self.autocorrection = autocorrection
        self.maximumLength = maximumLength
    }
}

public struct PTFormPickerOption: Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let value: PTFormValue

    public init(id: String, title: String, value: PTFormValue? = nil) {
        self.id = id
        self.title = title
        self.value = value ?? .string(title)
    }
}

public struct PTFormEnvironment: Sendable, Hashable {
    public var isReduceMotionEnabled: Bool
    public var isHighContrastEnabled: Bool
    public var layoutDirection: PTFormLayoutDirection

    public init(isReduceMotionEnabled: Bool = false,
                isHighContrastEnabled: Bool = false,
                layoutDirection: PTFormLayoutDirection = .leftToRight) {
        self.isReduceMotionEnabled = isReduceMotionEnabled
        self.isHighContrastEnabled = isHighContrastEnabled
        self.layoutDirection = layoutDirection
    }
}

public enum PTFormLayoutDirection: Sendable, Hashable {
    case leftToRight
    case rightToLeft
}

public struct PTFormActionID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
}

public enum PTFormEvent: Sendable {
    case valueChanged(PTFormFieldID, PTFormValue)
    case validationChanged(PTFormFieldID)
    case action(PTFormActionID)
    case submissionChanged(PTFormSubmission)
}

public enum PTFormUnsectionedFieldPolicy: Sendable, Hashable {
    case appendToImplicitSection
    case prependToImplicitSection
    case reject
}

public enum PTFormMutation: Sendable {
    case setValue(PTFormValue, fieldID: PTFormFieldID)
    case setFieldEnabled(Bool, fieldID: PTFormFieldID)
    case setFieldReadOnly(Bool, fieldID: PTFormFieldID)
    case updateSection(PTFormSection)
    case setSectionVisible(Bool, sectionID: String)
}
