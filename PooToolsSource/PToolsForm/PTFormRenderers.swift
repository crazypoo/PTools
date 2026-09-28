// English: Independent Form renderers backed by the existing PTools controls.
// Español: Renderizadores independientes de Form respaldados por los controles PTools existentes.
// 中文：使用现有 PTools 控件实现的独立 Form renderer。

#if canImport(UIKit)
import UIKit
#if SWIFT_PACKAGE
import ptools
import PToolsCore
import PooToolsPicker
import PooToolsCheckBox
import PooToolsSlider
#else
#if canImport(PToolsCore)
import PToolsCore
#endif
#if canImport(PooToolsInput)
import PooToolsInput
#endif
#if canImport(PooTools)
import PooTools
#endif
#if canImport(PooToolsPicker)
import PooToolsPicker
#endif
#if canImport(PooToolsCheckBox)
import PooToolsCheckBox
#endif
#if canImport(PooToolsSlider)
import PooToolsSlider
#endif
#if canImport(PooToolsStepper)
import PooToolsStepper
#endif
#endif

@MainActor
open class PTFormRendererBase: PTFormFieldRenderer {
    public let kind: PTFormFieldKind
    public private(set) var themeAdapter = PTFormThemeAdapter()

    public init(kind: PTFormFieldKind) { self.kind = kind }

    open func makeView(for field: PTFormField,
                       onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        PTFormMissingRendererView(kind: field.kind)
    }

    public func apply(theme: PTFormThemeAdapter) {
        themeAdapter = theme
    }

    internal func configureTextField(_ textField: UITextField,
                                     field: PTFormField,
                                     keyboard: UIKeyboardType,
                                     secure: Bool = false,
                                     onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UITextField {
        textField.text = PTFormValueFormatter.display(field.value, kind: field.kind)
        textField.placeholder = field.title
        textField.borderStyle = .roundedRect
        textField.adjustsFontForContentSizeCategory = true
        textField.font = themeAdapter.bodyFont()
        textField.textColor = themeAdapter.primaryTextColor()
        textField.backgroundColor = themeAdapter.fieldColor()
        textField.layer.cornerRadius = themeAdapter.cornerRadius()
        textField.layer.borderColor = themeAdapter.separatorColor().cgColor
        textField.layer.borderWidth = 1
        textField.isSecureTextEntry = secure
        textField.keyboardType = keyboard
        textField.isEnabled = field.isEnabled
        textField.isUserInteractionEnabled = field.isEnabled && !field.isReadOnly
        textField.addAction(UIAction { [weak textField] _ in
            guard let textField else { return }
            let value = PTFormValueFormatter.value(from: textField.text ?? "", kind: field.kind)
            let display = PTFormValueFormatter.displayString(from: textField.text ?? "", kind: field.kind)
            if textField.text != display { textField.text = display }
            onChange(value)
        }, for: .editingChanged)
        PTFormAccessibilityAdapter.apply(field: field,
                                         value: textField.text ?? "",
                                         issue: nil,
                                         to: textField)
        return textField
    }

    internal func makeTextField() -> UITextField {
#if canImport(PooToolsInput) || canImport(PooTools)
        PTTextField()
#else
        UITextField()
#endif
    }
}

@MainActor
public final class PTFormTextFieldRenderer: PTFormRendererBase {
    public init() { super.init(kind: .text) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        configureTextField(makeTextField(), field: field, keyboard: .default, onChange: onChange)
    }
}

@MainActor
public final class PTFormSecureTextFieldRenderer: PTFormRendererBase {
    public init() { super.init(kind: .secureText) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        configureTextField(makeTextField(), field: field, keyboard: .default, secure: true, onChange: onChange)
    }
}

@MainActor
public final class PTFormNumberRenderer: PTFormRendererBase {
    public init() { super.init(kind: .number) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        configureTextField(makeTextField(), field: field, keyboard: .decimalPad, onChange: onChange)
    }
}

@MainActor
public final class PTFormPhoneRenderer: PTFormRendererBase {
    public init() { super.init(kind: .phone) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        configureTextField(makeTextField(), field: field, keyboard: .phonePad, onChange: onChange)
    }
}

@MainActor
public final class PTFormBankCardRenderer: PTFormRendererBase {
    public init() { super.init(kind: .bankCard) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        configureTextField(makeTextField(), field: field, keyboard: .numberPad, onChange: onChange)
    }
}

@MainActor
public final class PTFormMultilineRenderer: PTFormRendererBase {
    public init() { super.init(kind: .multilineText) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
#if canImport(PooToolsInput)
        let textView = PTGrowingTextView()
#else
        let textView = UITextView()
#endif
        textView.text = PTFormValueFormatter.display(field.value, kind: field.kind)
        textView.font = themeAdapter.bodyFont()
        textView.textColor = themeAdapter.primaryTextColor()
        textView.backgroundColor = themeAdapter.fieldColor()
        textView.adjustsFontForContentSizeCategory = true
        textView.isEditable = field.isEnabled && !field.isReadOnly
        textView.isScrollEnabled = false
        textView.layer.borderWidth = 1
        textView.layer.borderColor = themeAdapter.separatorColor().cgColor
        textView.layer.cornerRadius = themeAdapter.cornerRadius()
#if canImport(PooToolsInput)
        textView.minHeight = 44
        textView.maxHeight = 200
        textView.growingTextDidChange = { view in onChange(.string(view.text)) }
#endif
        PTFormAccessibilityAdapter.apply(field: field, value: textView.text, issue: nil, to: textView)
        return textView
    }
}

@MainActor
public final class PTFormToggleRenderer: PTFormRendererBase {
    public init() { super.init(kind: .toggle) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
#if SWIFT_PACKAGE || canImport(PooTools)
        let control = PTSwitch()
#else
        let control = UISwitch()
#endif
        if case .boolean(let value) = field.value {
#if SWIFT_PACKAGE || canImport(PooTools)
            control.setOn(value, animated: false)
#else
            control.isOn = value
#endif
        }
        control.isEnabled = field.isEnabled && !field.isReadOnly
        control.addAction(UIAction { [weak control] _ in
#if SWIFT_PACKAGE || canImport(PooTools)
            onChange(.boolean(control?.isOn ?? false))
#else
            onChange(.boolean((control as? UISwitch)?.isOn ?? false))
#endif
            PTFeedbackCenter.shared.emit(.toggle)
        }, for: .valueChanged)
        PTFormAccessibilityAdapter.apply(field: field,
                                         value: PTFormViewController.display(field.value),
                                         issue: nil,
                                         to: control)
        return control
    }
}

@MainActor
public final class PTFormCheckboxRenderer: PTFormRendererBase {
    public init() { super.init(kind: .checkbox) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
#if canImport(PooToolsCheckBox)
        let control = PTCheckBox()
        control.useHapticFeedback = false
        control.isChecked = field.value == .boolean(true)
        control.isEnabled = field.isEnabled && !field.isReadOnly
        control.addAction(UIAction { [weak control] _ in
            onChange(.boolean(control?.isChecked ?? false))
            PTFeedbackCenter.shared.emit(.selectionChanged)
        }, for: .valueChanged)
        PTFormAccessibilityAdapter.apply(field: field, value: control.isChecked ? "On" : "Off", issue: nil, to: control)
        return control
#else
        return PTFormMissingRendererView(kind: field.kind)
#endif
    }
}

@MainActor
public final class PTFormSliderRenderer: PTFormRendererBase {
    public init() { super.init(kind: .slider) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
#if canImport(PooToolsSlider)
        let control = PTSlider()
        control.enableHapticFeedback = false
#else
        let control = UISlider()
#endif
        if case .number(let value) = field.value { control.value = Float(value) }
        control.isEnabled = field.isEnabled && !field.isReadOnly
        control.addAction(UIAction { [weak control] _ in
            onChange(.number(Double(control?.value ?? 0)))
            PTFeedbackCenter.shared.emit(.selectionChanged)
        }, for: .valueChanged)
        return control
    }
}

@MainActor
public final class PTFormStepperRenderer: PTFormRendererBase {
    public init() { super.init(kind: .stepper) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
#if canImport(PooToolsStepper)
        let control = PTStepper()
        if case .number(let value) = field.value { control.baseNum = String(Int(value)) }
        control.canText = field.isEnabled && !field.isReadOnly
        control.valueBlock = { value, _ in
            Task { @MainActor in
                onChange(.number(Double(value) ?? 0))
                PTFeedbackCenter.shared.emit(.selectionChanged)
            }
        }
        return control
#else
        let control = UIStepper()
        if case .number(let value) = field.value { control.value = value }
        control.isEnabled = field.isEnabled && !field.isReadOnly
        control.addAction(UIAction { [weak control] _ in onChange(.number(control?.value ?? 0)) }, for: .valueChanged)
        return control
#endif
    }
}

@MainActor
public final class PTFormDateRenderer: PTFormRendererBase {
    public init() { super.init(kind: .date) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
#if canImport(PooToolsPicker)
        let button = PTActionLayoutButton()
        button.layoutStyle = .title
        let current = PTFormValueFormatter.display(field.value, kind: field.kind)
        button.setTitle(current.isEmpty ? field.title : current, state: .normal)
        let picker = PTDatePickerView()
        let currentDate: Date = { if case .date(let value) = field.value { return value }; return Date() }()
        button.addActionHandler(for: .touchUpInside) { (_: PTActionLayoutButton) in
            picker.configure(title: field.title, defaultDate: currentDate)
            picker.resultBlock = { date, _ in
                onChange(.date(date))
            }
            picker.show()
        }
        button.isEnabled = field.isEnabled && !field.isReadOnly
        return button
#else
        let control = UIDatePicker()
        if case .date(let value) = field.value { control.date = value }
        control.isEnabled = field.isEnabled && !field.isReadOnly
        control.addAction(UIAction { [weak control] _ in if let date = control?.date { onChange(.date(date)) } }, for: .valueChanged)
        return control
#endif
    }
}

@MainActor
public final class PTFormPickerRenderer: PTFormRendererBase {
    public init() { super.init(kind: .picker) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
#if canImport(PooToolsPicker)
        let button = PTActionLayoutButton()
        button.layoutStyle = .title
        let current = PTFormValueFormatter.display(field.value, kind: field.kind)
        button.setTitle(current.isEmpty ? field.title : current, state: .normal)
        let picker = PTStringPickerView()
        button.addActionHandler(for: .touchUpInside) { (_: PTActionLayoutButton) in
            picker.configure(title: field.title, data: field.pickerOptions)
            picker.singleResultBlock = { result in
                onChange(.string(result.value))
            }
            picker.show()
        }
        button.isEnabled = field.isEnabled && !field.isReadOnly
        return button
#else
        let label = UILabel()
        label.text = PTFormViewController.display(field.value).isEmpty ? field.title : PTFormViewController.display(field.value)
        return label
#endif
    }
}

@MainActor
public final class PTFormActionButtonRenderer: PTFormRendererBase {
    public init() { super.init(kind: .custom) }
    public override func makeView(for field: PTFormField,
                                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        let button = PTActionLayoutButton()
        button.layoutStyle = .title
        button.setTitle(field.title, state: .normal)
        button.isEnabled = field.isEnabled && !field.isReadOnly
        button.addActionHandler(for: .touchUpInside) { (_: PTActionLayoutButton) in
            PTFeedbackCenter.shared.emit(.actionConfirmed)
            onChange(.boolean(true))
        }
        return button
    }
}

@MainActor
public final class PTFormMissingRendererView: UILabel {
    public init(kind: PTFormFieldKind) {
        super.init(frame: .zero)
        text = "Missing Form renderer: \(kind.rawValue)"
        textColor = .systemRed
        numberOfLines = 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}

@MainActor
private final class PTFormMissingRenderer: PTFormRendererBase {
    override init(kind: PTFormFieldKind) { super.init(kind: kind) }
    override func makeView(for field: PTFormField,
                           onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        PTFormMissingRendererView(kind: field.kind)
    }
}

@MainActor
enum PTFormRendererFactory {
    static func make(kind: PTFormFieldKind) -> any PTFormFieldRenderer {
        switch kind {
        case .text: return PTFormTextFieldRenderer()
        case .secureText: return PTFormSecureTextFieldRenderer()
        case .multilineText: return PTFormMultilineRenderer()
        case .number: return PTFormNumberRenderer()
        case .phone: return PTFormPhoneRenderer()
        case .bankCard: return PTFormBankCardRenderer()
        case .toggle: return PTFormToggleRenderer()
        case .checkbox: return PTFormCheckboxRenderer()
        case .slider: return PTFormSliderRenderer()
        case .stepper: return PTFormStepperRenderer()
        case .date: return PTFormDateRenderer()
        case .picker: return PTFormPickerRenderer()
        case .custom: return PTFormMissingRenderer(kind: kind)
        }
    }
}

@MainActor
internal enum PTFormValueFormatter {
    static func value(from text: String, kind: PTFormFieldKind) -> PTFormValue {
        if kind == .number { return .number(Double(text) ?? 0) }
        if kind == .bankCard { return .string(text.filter(\.isNumber)) }
        return .string(text)
    }

    static func displayString(from text: String, kind: PTFormFieldKind) -> String {
        guard kind == .bankCard else { return text }
        let digits = text.filter(\.isNumber)
        return stride(from: 0, to: digits.count, by: 4).map { start in
            let begin = digits.index(digits.startIndex, offsetBy: start)
            let end = digits.index(begin, offsetBy: min(4, digits.distance(from: begin, to: digits.endIndex)))
            return String(digits[begin..<end])
        }.joined(separator: " ")
    }

    static func display(_ value: PTFormValue, kind: PTFormFieldKind) -> String {
        switch value {
        case .empty: return ""
        case .string(let value): return displayString(from: value, kind: kind)
        case .number(let value): return String(value)
        case .boolean(let value): return value ? "On" : "Off"
        case .date(let value): return value.formatted()
        case .data: return "Data"
        }
    }
}
#endif
