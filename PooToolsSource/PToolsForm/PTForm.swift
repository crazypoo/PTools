// English: A typed form engine with stable field identity and cancellable validation.
// Español: Un motor de formularios tipado con identidad estable y validación cancelable.
// 中文：提供稳定字段身份和可取消校验的类型化表单引擎。

import Foundation

#if canImport(UIKit)
import UIKit
#if SWIFT_PACKAGE
import ptools
#endif
#endif

public struct PTFormFieldID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
}

public enum PTFormFieldKind: String, Codable, Sendable, Hashable {
    case text, secureText, multilineText, number, phone, bankCard, toggle, checkbox, slider, stepper, date, picker, custom
}

public enum PTFormValue: Codable, Hashable, Sendable {
    case empty
    case string(String)
    case number(Double)
    case boolean(Bool)
    case date(Date)
    case data(Data)
}

public enum PTFormValidationRule: Codable, Hashable, Sendable {
    case required
    case length(minimum: Int, maximum: Int?)
    case regex(String)
    case range(minimum: Double, maximum: Double)
    case email
    case phone
    case bankCard
}

public struct PTFormValidationIssue: Codable, Hashable, Sendable {
    public let fieldID: PTFormFieldID
    public let message: String
    public init(fieldID: PTFormFieldID, message: String) { self.fieldID = fieldID; self.message = message }
}

public struct PTFormValidationResult: Codable, Hashable, Sendable {
    public let issues: [PTFormValidationIssue]
    public var isValid: Bool { issues.isEmpty }
    public init(issues: [PTFormValidationIssue] = []) { self.issues = issues }
}

public struct PTFormDependency: Codable, Hashable, Sendable {
    public let fieldID: PTFormFieldID
    public let expectedValue: PTFormValue

    public init(fieldID: PTFormFieldID, expectedValue: PTFormValue) {
        self.fieldID = fieldID; self.expectedValue = expectedValue
    }
}

public struct PTFormValidator: Sendable {
    public let validate: @Sendable (PTFormValue) async -> String?
    public init(validate: @escaping @Sendable (PTFormValue) async -> String?) { self.validate = validate }
}

public struct PTFormField: Sendable {
    public let id: PTFormFieldID
    public let kind: PTFormFieldKind
    public let title: String
    public var value: PTFormValue
    public var isEnabled: Bool
    public var dependency: PTFormDependency?
    public let rules: [PTFormValidationRule]
    public let validators: [PTFormValidator]

    public init(id: PTFormFieldID,
                kind: PTFormFieldKind,
                title: String,
                value: PTFormValue = .empty,
                isEnabled: Bool = true,
                dependency: PTFormDependency? = nil,
                rules: [PTFormValidationRule] = [],
                validators: [PTFormValidator] = []) {
        self.id = id; self.kind = kind; self.title = title; self.value = value; self.isEnabled = isEnabled
        self.dependency = dependency; self.rules = rules; self.validators = validators
    }
}

public struct PTFormSection: Sendable {
    public let id: String
    public let title: String?
    public let fieldIDs: [PTFormFieldID]
    public init(id: String, title: String? = nil, fieldIDs: [PTFormFieldID]) {
        self.id = id; self.title = title; self.fieldIDs = fieldIDs
    }
}

public enum PTFormSubmission: Sendable, Equatable {
    case idle
    case submitting
    case succeeded
    case failed(String)
}

public enum PTFormError: Error, Sendable, Equatable {
    case missingField(PTFormFieldID)
    case invalid(PTFormValidationResult)
    case cancelled
}

public actor PTFormEngine {
    private var fields: [PTFormFieldID: PTFormField]
    private var order: [PTFormFieldID]
    private var generations: [PTFormFieldID: UInt64] = [:]
    private var validationTasks: [PTFormFieldID: Task<PTFormValidationResult, Never>] = [:]
    public private(set) var submission: PTFormSubmission = .idle

    public init(fields: [PTFormField], sections: [PTFormSection] = []) {
        self.fields = Dictionary(uniqueKeysWithValues: fields.map { ($0.id, $0) })
        let sectionOrder = sections.flatMap(\.fieldIDs)
        let remaining = fields.map(\.id).filter { !sectionOrder.contains($0) }
        self.order = sectionOrder + remaining
    }

    public func snapshot() -> [PTFormField] { order.compactMap { fields[$0] } }

    public func visibleFields() -> [PTFormField] {
        snapshot().filter { field in
            guard let dependency = field.dependency else { return true }
            return fields[dependency.fieldID]?.value == dependency.expectedValue
        }
    }

    public func setValue(_ value: PTFormValue, for id: PTFormFieldID) throws {
        guard var field = fields[id] else { throw PTFormError.missingField(id) }
        field.value = value
        fields[id] = field
        generations[id, default: 0] &+= 1
        validationTasks[id]?.cancel()
        validationTasks[id] = nil
    }

    public func value(for id: PTFormFieldID) -> PTFormValue? { fields[id]?.value }

    public func validateField(_ id: PTFormFieldID, debounce: Duration = .milliseconds(250)) async -> PTFormValidationResult {
        validationTasks[id]?.cancel()
        let generation = generations[id, default: 0]
        let task = Task { [weak self] in
            do { try await Task.sleep(for: debounce) } catch { return PTFormValidationResult() }
            guard let self else { return PTFormValidationResult() }
            return await self.performValidation(id, generation: generation)
        }
        validationTasks[id] = task
        let result = await task.value
        if generations[id, default: 0] == generation { validationTasks[id] = nil }
        return result
    }

    public func validateAll() async -> PTFormValidationResult {
        let current = snapshot()
        var issues: [PTFormValidationIssue] = []
        for field in current where visibleFields().contains(where: { $0.id == field.id }) {
            issues.append(contentsOf: await performValidation(field.id, generation: generations[field.id, default: 0]).issues)
        }
        return PTFormValidationResult(issues: issues)
    }

    public func submit(_ operation: @escaping @Sendable ([PTFormFieldID: PTFormValue]) async throws -> Void) async throws {
        let result = await validateAll()
        guard result.isValid else { submission = .failed("Validation failed"); throw PTFormError.invalid(result) }
        submission = .submitting
        do {
            try await operation(fields.reduce(into: [:]) { $0[$1.key] = $1.value.value })
            submission = .succeeded
        } catch is CancellationError {
            submission = .failed("Cancelled"); throw PTFormError.cancelled
        } catch {
            submission = .failed(error.localizedDescription); throw error
        }
    }

    private func performValidation(_ id: PTFormFieldID, generation: UInt64) async -> PTFormValidationResult {
        guard let field = fields[id], generations[id, default: 0] == generation else { return PTFormValidationResult() }
        var issues = Self.validate(field)
        for validator in field.validators {
            guard generations[id, default: 0] == generation else { return PTFormValidationResult() }
            if let message = await validator.validate(field.value) { issues.append(.init(fieldID: id, message: message)) }
        }
        return PTFormValidationResult(issues: issues)
    }

    private static func validate(_ field: PTFormField) -> [PTFormValidationIssue] {
        field.rules.compactMap { rule in
            switch rule {
            case .required:
                if case .string(let value) = field.value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
                if case .empty = field.value { return .init(fieldID: field.id, message: "Required") }
                return nil
            case .length(let minimum, let maximum):
                guard case .string(let value) = field.value else { return nil }
                guard value.count >= minimum, maximum.map({ value.count <= $0 }) ?? true else { return .init(fieldID: field.id, message: "Invalid length") }
            case .regex(let pattern):
                guard case .string(let value) = field.value else { return nil }
                guard value.range(of: pattern, options: .regularExpression) != nil else { return .init(fieldID: field.id, message: "Invalid format") }
            case .range(let minimum, let maximum):
                guard case .number(let value) = field.value, (minimum...maximum).contains(value) else { return .init(fieldID: field.id, message: "Out of range") }
            case .email:
                guard case .string(let value) = field.value, value.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil else { return .init(fieldID: field.id, message: "Invalid email") }
            case .phone:
                guard case .string(let value) = field.value, value.range(of: #"^[0-9+()\-\s]{6,}$"#, options: .regularExpression) != nil else { return .init(fieldID: field.id, message: "Invalid phone") }
            case .bankCard:
                guard case .string(let value) = field.value else { return .init(fieldID: field.id, message: "Invalid card") }
                let digits = value.filter(\.isNumber)
                guard (12...19).contains(digits.count) else { return .init(fieldID: field.id, message: "Invalid card") }
            }
            return nil
        }
    }
}

#if canImport(UIKit)
@MainActor
public protocol PTFormFieldRenderer: AnyObject {
    var kind: PTFormFieldKind { get }
    func makeView(for field: PTFormField,
                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView
}

@MainActor
public final class PTFormFieldRendererRegistry {
    private var renderers: [PTFormFieldKind: any PTFormFieldRenderer] = [:]

    public init() {}

    public func register(_ renderer: any PTFormFieldRenderer) {
        renderers[renderer.kind] = renderer
    }

    public func renderer(for kind: PTFormFieldKind) -> any PTFormFieldRenderer {
        renderers[kind] ?? PTDefaultFormFieldRenderer()
    }
}

@MainActor
public final class PTDefaultFormFieldRenderer: PTFormFieldRenderer {
    public let kind: PTFormFieldKind

    public init(kind: PTFormFieldKind = .custom) {
        self.kind = kind
    }

    public func makeView(for field: PTFormField,
                         onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        switch field.kind {
        case .text, .secureText, .number, .phone, .bankCard:
            let textField = UITextField()
            textField.text = PTFormViewController.display(field.value)
            textField.placeholder = field.title
            textField.borderStyle = .roundedRect
            textField.adjustsFontForContentSizeCategory = true
            textField.font = .preferredFont(forTextStyle: .body)
            textField.isSecureTextEntry = field.kind == .secureText
            textField.keyboardType = field.kind == .number ? .decimalPad : (field.kind == .phone ? .phonePad : .default)
            textField.isEnabled = field.isEnabled
            textField.addAction(UIAction { [weak textField] _ in
                guard let textField else { return }
                let value: PTFormValue = field.kind == .number
                    ? .number(Double(textField.text ?? "") ?? 0)
                    : .string(textField.text ?? "")
                onChange(value)
            }, for: .editingChanged)
            return textField

        case .multilineText:
            let textView = PTFormTextView()
            textView.text = PTFormViewController.display(field.value)
            textView.font = .preferredFont(forTextStyle: .body)
            textView.adjustsFontForContentSizeCategory = true
            textView.isEditable = field.isEnabled
            textView.layer.borderWidth = 1
            textView.layer.borderColor = UIColor.separator.cgColor
            textView.layer.cornerRadius = 8
            textView.onTextChange = { text in onChange(.string(text)) }
            return textView

        case .toggle:
            let control = UISwitch()
            if case .boolean(let value) = field.value { control.isOn = value }
            control.isEnabled = field.isEnabled
            control.addAction(UIAction { [weak control] _ in
                onChange(.boolean(control?.isOn ?? false))
            }, for: .valueChanged)
            return control

        case .checkbox:
            let control = UIButton(type: .system)
            control.configuration = .bordered
            control.configuration?.title = field.title
            control.isSelected = field.value == .boolean(true)
            control.isEnabled = field.isEnabled
            control.addAction(UIAction { [weak control] _ in
                guard let control else { return }
                control.isSelected.toggle()
                onChange(.boolean(control.isSelected))
            }, for: .touchUpInside)
            return control

        case .slider:
            let control = UISlider()
            if case .number(let value) = field.value { control.value = Float(value) }
            control.isEnabled = field.isEnabled
            control.addAction(UIAction { [weak control] _ in
                onChange(.number(Double(control?.value ?? 0)))
            }, for: .valueChanged)
            return control

        case .stepper:
            let container = UIStackView()
            container.axis = .horizontal
            container.spacing = 8
            let valueLabel = UILabel()
            valueLabel.font = .preferredFont(forTextStyle: .body)
            valueLabel.adjustsFontForContentSizeCategory = true
            let control = UIStepper()
            if case .number(let value) = field.value {
                control.value = value
                valueLabel.text = String(value)
            }
            control.isEnabled = field.isEnabled
            control.addAction(UIAction { [weak control, weak valueLabel] _ in
                let value = control?.value ?? 0
                valueLabel?.text = String(value)
                onChange(.number(value))
            }, for: .valueChanged)
            container.addArrangedSubview(valueLabel)
            container.addArrangedSubview(control)
            return container

        case .date:
            let control = UIDatePicker()
            control.datePickerMode = .dateAndTime
            if case .date(let value) = field.value { control.date = value }
            control.isEnabled = field.isEnabled
            control.addAction(UIAction { [weak control] _ in
                if let date = control?.date { onChange(.date(date)) }
            }, for: .valueChanged)
            return control

        case .picker, .custom:
            let label = UILabel()
            label.text = PTFormViewController.display(field.value).isEmpty ? field.title : PTFormViewController.display(field.value)
            label.textColor = .secondaryLabel
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            return label
        }
    }
}

@MainActor
private final class PTFormTextView: UITextView, UITextViewDelegate {
    var onTextChange: ((String) -> Void)?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        delegate = self
        isScrollEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
        isScrollEnabled = false
    }

    func textViewDidChange(_ textView: UITextView) {
        onTextChange?(textView.text)
    }
}

@MainActor
private final class PTFormFieldBox: NSObject {
    let field: PTFormField
    init(field: PTFormField) { self.field = field }
}

@MainActor
private final class PTFormFieldCell: UICollectionViewCell {
    static let reuseID = "PTFormFieldCell"

    private let titleLabel = UILabel()
    private let fieldContainer = UIView()
    private let issueLabel = UILabel()
    private var renderedView: UIView?
    var onReturn: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.addSubview(fieldContainer)
        contentView.addSubview(issueLabel)
        [titleLabel, fieldContainer, issueLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            fieldContainer.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            fieldContainer.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            fieldContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            fieldContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
            issueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            issueLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            issueLabel.topAnchor.constraint(equalTo: fieldContainer.bottomAnchor, constant: 4),
            issueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        issueLabel.font = .preferredFont(forTextStyle: .caption1)
        issueLabel.adjustsFontForContentSizeCategory = true
        issueLabel.textColor = .systemRed
        issueLabel.numberOfLines = 0
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func prepareForReuse() {
        super.prepareForReuse()
        renderedView?.removeFromSuperview()
        renderedView = nil
        onReturn = nil
        issueLabel.text = nil
    }

    func configure(field: PTFormField,
                   renderer: any PTFormFieldRenderer,
                   issue: String?,
                   onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void,
                   onReturn: @escaping () -> Void) {
        renderedView?.removeFromSuperview()
        let view = renderer.makeView(for: field, onChange: onChange)
        renderedView = view
        fieldContainer.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor),
            view.topAnchor.constraint(equalTo: fieldContainer.topAnchor),
            view.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor)
        ])
        titleLabel.text = field.title
        issueLabel.text = issue
        isUserInteractionEnabled = field.isEnabled
        accessibilityLabel = field.title
        accessibilityValue = PTFormViewController.display(field.value)
        self.onReturn = onReturn
        if let textField = view as? UITextField {
            textField.returnKeyType = .next
            textField.addAction(UIAction { [weak self] _ in self?.onReturn?() }, for: .editingDidEndOnExit)
        }
    }

    func focusField() {
        if let textField = renderedView as? UITextField { textField.becomeFirstResponder() }
        else if let textView = renderedView as? UITextView { textView.becomeFirstResponder() }
    }
}

@MainActor
public final class PTFormViewController: PTBaseViewController {
    public let form: PTFormEngine
    public let listView: PTCollectionView
    public let rendererRegistry: PTFormFieldRendererRegistry
    private var cachedFields: [PTFormFieldID: PTFormField] = [:]
    private var visibleFieldIDs: [PTFormFieldID] = []
    private var validationIssues: [PTFormFieldID: String] = [:]

    public init(form: PTFormEngine) {
        self.init(form: form, rendererRegistry: .init())
    }

    public init(form: PTFormEngine,
                rendererRegistry: PTFormFieldRendererRegistry) {
        self.form = form
        self.rendererRegistry = rendererRegistry
        self.listView = PTCollectionView(viewConfig: PTCollectionViewConfig())
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        form = PTFormEngine(fields: [])
        rendererRegistry = PTFormFieldRendererRegistry()
        listView = PTCollectionView(viewConfig: PTCollectionViewConfig())
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(listView)
        listView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            listView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listView.topAnchor.constraint(equalTo: view.topAnchor),
            listView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        listView.viewConfig.itemHeight = 92
        listView.registerClassCells(classs: [PTFormFieldCell.reuseID: PTFormFieldCell.self])
        listView.cellInCollection = { [weak self] collectionView, section, indexPath in
            guard let self,
                  let row = section.rows?[safe: indexPath.item],
                  let box = row.dataModel as? PTFormFieldBox,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PTFormFieldCell.reuseID,
                                                                 for: indexPath) as? PTFormFieldCell else { return nil }
            cell.configure(field: box.field,
                           renderer: self.rendererRegistry.renderer(for: box.field.kind),
                           issue: self.validationIssues[box.field.id],
                           onChange: { [weak self] value in
                self?.setValue(value, for: box.field.id)
            },
                           onReturn: { [weak self] in self?.focusNext(after: box.field.id) })
            return cell
        }
        Task { await refresh() }
    }

    public func refresh() async {
        let fields = await form.visibleFields()
        cachedFields = Dictionary(uniqueKeysWithValues: fields.map { ($0.id, $0) })
        visibleFieldIDs = fields.map(\.id)
        let rows = fields.map { field in
            PTRows(title: field.title,
                   ID: PTFormFieldCell.reuseID,
                   diffId: field.id.rawValue,
                   diffHash: field.value.hashValue,
                   dataModel: PTFormFieldBox(field: field))
        }
        let section = PTSection(identifier: "form", rows: rows)
        listView.showCollectionDetail(collectionData: [section], animated: false)
    }

    private func setValue(_ value: PTFormValue, for id: PTFormFieldID) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await form.setValue(value, for: id)
            let result = await form.validateField(id)
            validationIssues[id] = result.issues.first?.message
            await refresh()
        }
    }

    public func validate() async -> PTFormValidationResult {
        let result = await form.validateAll()
        validationIssues = Dictionary(uniqueKeysWithValues: result.issues.map { ($0.fieldID, $0.message) })
        await refresh()
        return result
    }

    public func submit(_ operation: @escaping @Sendable ([PTFormFieldID: PTFormValue]) async throws -> Void) async throws {
        let result = await validate()
        guard result.isValid else { throw PTFormError.invalid(result) }
        try await form.submit(operation)
    }

    private func focusNext(after id: PTFormFieldID) {
        guard let index = visibleFieldIDs.firstIndex(of: id), visibleFieldIDs.indices.contains(index + 1) else {
            view.endEditing(true)
            return
        }
        let nextID = visibleFieldIDs[index + 1]
        guard let rowIndex = listView.contentCollectionView.indexPathsForVisibleItems.first(where: { indexPath in
            listView.getRow(at: indexPath)?.diffId == nextID
        }) else { return }
        listView.contentCollectionView.scrollToItem(at: rowIndex, at: .centeredVertically, animated: true)
        DispatchQueue.main.async { [weak self] in
            (self?.listView.contentCollectionView.cellForItem(at: rowIndex) as? PTFormFieldCell)?.focusField()
        }
    }

    fileprivate static func display(_ value: PTFormValue) -> String {
        switch value { case .empty: ""; case .string(let v): v; case .number(let v): String(v); case .boolean(let v): v ? "On" : "Off"; case .date(let v): v.formatted(); case .data: "Data" }
    }
}
#endif
