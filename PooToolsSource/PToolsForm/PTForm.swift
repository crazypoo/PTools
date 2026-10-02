// English: A typed form engine with stable field identity and cancellable validation.
// Español: Un motor de formularios tipado con identidad estable y validación cancelable.
// 中文：提供稳定字段身份和可取消校验的类型化表单引擎。

import Foundation

#if canImport(UIKit)
import UIKit
#if SWIFT_PACKAGE
import ptools
import PToolsCore
import PToolsTheme
import PToolsAccessibility
#endif
#if canImport(PToolsCore) && !SWIFT_PACKAGE
import PToolsCore
#endif
#if canImport(PToolsTheme) && !SWIFT_PACKAGE
import PToolsTheme
#endif
#if canImport(PToolsAccessibility) && !SWIFT_PACKAGE
import PToolsAccessibility
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
    public let severity: PTFormValidationSeverity

    // English: Preserve the 5.x initializer while defaulting legacy issues to errors.
    // Español: Conserva el inicializador de 5.x y trata las incidencias heredadas como errores.
    // 中文：保留 5.x 初始化方法，并将旧版问题默认视为错误。
    public init(fieldID: PTFormFieldID, message: String) {
        self.init(fieldID: fieldID, message: message, severity: .error)
    }

    public init(fieldID: PTFormFieldID,
                message: String,
                severity: PTFormValidationSeverity = .error) {
        self.fieldID = fieldID
        self.message = message
        self.severity = severity
    }
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
    public var subtitle: String?
    public var placeholder: String?
    public var value: PTFormValue
    public var isEnabled: Bool
    public var isReadOnly: Bool
    public var dependency: PTFormDependency?
    /// English: Keep the legacy string options so existing 5.x callers remain source compatible.
    /// Español: Conserva las opciones de texto heredadas para mantener la compatibilidad de código con los consumidores 5.x.
    /// 中文：保留旧的字符串选项，避免破坏 5.x 调用方的源码兼容性。
    public let pickerOptions: [String]
    /// Structured picker options keep stable IDs and typed values for new callers.
    /// Las opciones estructuradas conservan IDs estables y valores tipados para los nuevos consumidores.
    /// 结构化 Picker 选项为新调用方保留稳定 ID 和类型化值。
    public let pickerOptionModels: [PTFormPickerOption]
    public let rules: [PTFormValidationRule]
    public let validators: [PTFormValidator]
    public var configuration: PTFormFieldConfiguration?
    public var visibility: PTFormVisibilityRule?
    public var accessibility: PTFormAccessibilityConfiguration?
    public var rendererIdentifier: String?

    public init(id: PTFormFieldID,
                kind: PTFormFieldKind,
                title: String,
                value: PTFormValue = .empty,
                isEnabled: Bool = true,
                dependency: PTFormDependency? = nil,
                rules: [PTFormValidationRule] = [],
                validators: [PTFormValidator] = [],
                isReadOnly: Bool = false,
                pickerOptions: [String] = [],
                subtitle: String? = nil,
                placeholder: String? = nil,
                configuration: PTFormFieldConfiguration? = nil,
                visibility: PTFormVisibilityRule? = nil,
                accessibility: PTFormAccessibilityConfiguration? = nil,
                rendererIdentifier: String? = nil) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.value = value
        self.isEnabled = isEnabled
        self.isReadOnly = isReadOnly
        self.dependency = dependency
        self.pickerOptions = pickerOptions
        self.pickerOptionModels = pickerOptions.map { PTFormPickerOption(id: $0, title: $0) }
        self.rules = rules
        self.validators = validators
        self.configuration = configuration
        self.visibility = visibility
        self.accessibility = accessibility
        self.rendererIdentifier = rendererIdentifier
    }

    public init(id: PTFormFieldID,
                kind: PTFormFieldKind,
                title: String,
                value: PTFormValue = .empty,
                isEnabled: Bool = true,
                dependency: PTFormDependency? = nil,
                rules: [PTFormValidationRule] = [],
                validators: [PTFormValidator] = [],
                isReadOnly: Bool = false,
                pickerOptions: [PTFormPickerOption],
                subtitle: String? = nil,
                placeholder: String? = nil,
                configuration: PTFormFieldConfiguration? = nil,
                visibility: PTFormVisibilityRule? = nil,
                accessibility: PTFormAccessibilityConfiguration? = nil,
                rendererIdentifier: String? = nil) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.value = value
        self.isEnabled = isEnabled
        self.isReadOnly = isReadOnly
        self.dependency = dependency
        self.pickerOptionModels = pickerOptions
        self.pickerOptions = pickerOptions.map(\.title)
        self.rules = rules
        self.validators = validators
        self.configuration = configuration
        self.visibility = visibility
        self.accessibility = accessibility
        self.rendererIdentifier = rendererIdentifier
    }
}

public struct PTFormSection: Sendable {
    public let id: String
    public var title: String?
    public var subtitle: String?
    public var header: PTFormSupplementaryContent?
    public var footer: PTFormSupplementaryContent?
    public var fieldIDs: [PTFormFieldID]
    public var configuration: PTFormSectionConfiguration?
    public var visibility: PTFormVisibilityRule?

    // English: Keep the original section initializer source-compatible.
    // Español: Conserva el inicializador original de sección para mantener compatibilidad de código.
    // 中文：保留原有 Section 初始化方法，确保源码兼容。
    public init(id: String, title: String? = nil, fieldIDs: [PTFormFieldID]) {
        self.init(id: id,
                  title: title,
                  subtitle: nil,
                  header: nil,
                  footer: nil,
                  fieldIDs: fieldIDs,
                  configuration: nil,
                  visibility: nil)
    }

    public init(id: String,
                title: String? = nil,
                subtitle: String? = nil,
                header: PTFormSupplementaryContent? = nil,
                footer: PTFormSupplementaryContent? = nil,
                fieldIDs: [PTFormFieldID],
                configuration: PTFormSectionConfiguration? = nil,
                visibility: PTFormVisibilityRule? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.header = header
        self.footer = footer
        self.fieldIDs = fieldIDs
        self.configuration = configuration
        self.visibility = visibility
    }
}

public indirect enum PTFormVisibilityRule: Sendable, Hashable {
    case always
    case equals(field: PTFormFieldID, value: PTFormValue)
    case notEquals(field: PTFormFieldID, value: PTFormValue)
    case isEmpty(field: PTFormFieldID)
    case isNotEmpty(field: PTFormFieldID)
    case all([PTFormVisibilityRule])
    case any([PTFormVisibilityRule])
    case not(PTFormVisibilityRule)
}

public enum PTFormSubmission: Sendable, Equatable {
    case idle
    case submitting
    case succeeded
    case failed(String)
}

public enum PTFormError: Error, Sendable, Equatable {
    case missingField(PTFormFieldID)
    case missingSection(String)
    case invalid(PTFormValidationResult)
    case cancelled
}

public actor PTFormEngine {
    private var fields: [PTFormFieldID: PTFormField]
    private var order: [PTFormFieldID]
    private var sections: [PTFormSection]
    private var initialValues: [PTFormFieldID: PTFormValue]
    private var sectionVisibilityOverrides: [String: Bool] = [:]
    private var generations: [PTFormFieldID: UInt64] = [:]
    private var validationTasks: [PTFormFieldID: Task<PTFormValidationResult, Never>] = [:]
    private let crossValidators: [PTFormCrossValidator]
    private let messageProvider: PTFormValidationMessageProvider
    public let configuration: PTFormConfiguration
    public let unsectionedFieldPolicy: PTFormUnsectionedFieldPolicy
    public private(set) var definitionIssues: [PTFormDefinitionIssue]
    public private(set) var revision: UInt64 = 0
    public private(set) var submission: PTFormSubmission = .idle

    // English: Preserve the original two-argument engine initializer.
    // Español: Conserva el inicializador original de dos argumentos del motor.
    // 中文：保留原有的双参数引擎初始化方法。
    public init(fields: [PTFormField], sections: [PTFormSection] = []) {
        self.init(fields: fields, sections: sections, configuration: .grouped)
    }

    public init(fields: [PTFormField],
                sections: [PTFormSection] = [],
                configuration: PTFormConfiguration = .grouped,
                unsectionedFieldPolicy: PTFormUnsectionedFieldPolicy = .appendToImplicitSection,
                crossValidators: [PTFormCrossValidator] = [],
                messageProvider: PTFormValidationMessageProvider = .init()) {
        let normalized = Self.normalize(fields: fields,
                                        sections: sections,
                                        policy: unsectionedFieldPolicy)
        self.fields = normalized.fields
        self.order = normalized.order
        self.sections = normalized.sections
        self.initialValues = normalized.fields.mapValues(\.value)
        self.crossValidators = crossValidators
        self.messageProvider = messageProvider
        self.configuration = configuration
        self.unsectionedFieldPolicy = unsectionedFieldPolicy
        self.definitionIssues = normalized.issues
    }

    public func snapshot() -> [PTFormField] { order.compactMap { fields[$0] } }

    public func visibleFields() -> [PTFormField] {
        makeSnapshot().fields
    }

    public func makeSnapshot() -> PTFormSnapshot {
        let visibleSections = sections.compactMap { section -> PTFormSectionSnapshot? in
            guard sectionVisibilityOverrides[section.id] != false,
                  evaluate(section.visibility) else { return nil }
            let visible = section.fieldIDs.compactMap { id -> PTFormField? in
                guard let field = fields[id], isVisible(field) else { return nil }
                return field
            }
            guard !configuration.hideEmptySections || !visible.isEmpty else { return nil }
            return PTFormSectionSnapshot(section: section, fields: visible)
        }
        return PTFormSnapshot(revision: revision, sections: visibleSections)
    }

    public func setValue(_ value: PTFormValue, for id: PTFormFieldID) throws {
        guard var field = fields[id] else { throw PTFormError.missingField(id) }
        field.value = value
        fields[id] = field
        revision &+= 1
        generations[id, default: 0] &+= 1
        validationTasks[id]?.cancel()
        validationTasks[id] = nil
    }

    public func value(for id: PTFormFieldID) -> PTFormValue? { fields[id]?.value }

    public func updateField(_ field: PTFormField) throws {
        guard fields[field.id] != nil else { throw PTFormError.missingField(field.id) }
        fields[field.id] = field
        revision &+= 1
        generations[field.id, default: 0] &+= 1
        validationTasks[field.id]?.cancel()
        validationTasks[field.id] = nil
    }

    public func setFieldEnabled(_ enabled: Bool, for id: PTFormFieldID) throws {
        guard var field = fields[id] else { throw PTFormError.missingField(id) }
        field.isEnabled = enabled
        try updateField(field)
    }

    public func setFieldReadOnly(_ readOnly: Bool, for id: PTFormFieldID) throws {
        guard var field = fields[id] else { throw PTFormError.missingField(id) }
        field.isReadOnly = readOnly
        try updateField(field)
    }

    public func updateSection(_ section: PTFormSection) throws {
        guard let index = sections.firstIndex(where: { $0.id == section.id }) else {
            throw PTFormError.missingSection(section.id)
        }
        sections[index] = section
        revision &+= 1
    }

    public func setSectionVisible(_ visible: Bool, for id: String) throws {
        guard sections.contains(where: { $0.id == id }) else { throw PTFormError.missingSection(id) }
        sectionVisibilityOverrides[id] = visible
        revision &+= 1
    }

    public func performUpdates(_ mutations: [PTFormMutation]) throws {
        for mutation in mutations {
            switch mutation {
            case .setValue(let value, let fieldID): try setValue(value, for: fieldID)
            case .setFieldEnabled(let enabled, let fieldID): try setFieldEnabled(enabled, for: fieldID)
            case .setFieldReadOnly(let readOnly, let fieldID): try setFieldReadOnly(readOnly, for: fieldID)
            case .updateSection(let section): try updateSection(section)
            case .setSectionVisible(let visible, let sectionID): try setSectionVisible(visible, for: sectionID)
            }
        }
    }

    public func reset() {
        for id in order where fields[id]?.value != initialValues[id] {
            fields[id]?.value = initialValues[id] ?? .empty
            generations[id, default: 0] &+= 1
        }
        revision &+= 1
        validationTasks.values.forEach { $0.cancel() }
        validationTasks.removeAll()
    }

    public func reset(field id: PTFormFieldID) throws {
        guard var field = fields[id] else { throw PTFormError.missingField(id) }
        field.value = initialValues[id] ?? .empty
        try updateField(field)
    }

    public var isDirty: Bool {
        order.contains { fields[$0]?.value != initialValues[$0] }
    }

    public var changedFieldIDs: Set<PTFormFieldID> {
        Set(order.filter { fields[$0]?.value != initialValues[$0] })
    }

    public func validateField(_ id: PTFormFieldID, debounce: Duration = .milliseconds(250)) async -> PTFormValidationResult {
        await validateFieldImplementation(id, debounce: debounce)
    }

    private func validateFieldImplementation(_ id: PTFormFieldID,
                                             debounce: Duration?) async -> PTFormValidationResult {
        validationTasks[id]?.cancel()
        let generation = generations[id, default: 0]
        let capturedRevision = revision
        let delay = debounce ?? configuration.validationPolicy.debounce
        let task = Task { [weak self] in
            do { try await Task.sleep(for: delay) } catch { return PTFormValidationResult() }
            guard let self else { return PTFormValidationResult() }
            return await self.performValidation(id, generation: generation, revision: capturedRevision)
        }
        validationTasks[id] = task
        let result = await task.value
        if generations[id, default: 0] == generation { validationTasks[id] = nil }
        return result
    }

    public func validateAll() async -> PTFormValidationResult {
        let current = makeSnapshot().fields
        var issues: [PTFormValidationIssue] = []
        for field in current {
            issues.append(contentsOf: await performValidation(field.id,
                                                              generation: generations[field.id, default: 0],
                                                              revision: revision).issues)
        }
        let context = PTFormValidationContext(values: fields.mapValues(\.value), revision: revision)
        for validator in crossValidators {
            guard !Task.isCancelled else { return PTFormValidationResult(issues: issues) }
            issues.append(contentsOf: await validator.validate(context))
        }
        return PTFormValidationResult(issues: issues)
    }

    public func validateSection(_ id: String) async -> PTFormValidationResult {
        guard let section = makeSnapshot().sections.first(where: { $0.section.id == id }) else {
            return PTFormValidationResult()
        }
        let ids = Set(section.fields.map(\.id))
        let result = await validateAll()
        return PTFormValidationResult(issues: result.issues.filter { ids.contains($0.fieldID) })
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

    private func performValidation(_ id: PTFormFieldID,
                                   generation: UInt64,
                                   revision: UInt64) async -> PTFormValidationResult {
        guard let field = fields[id],
              generations[id, default: 0] == generation,
              self.revision == revision else { return PTFormValidationResult() }
        var issues = Self.validate(field, messageProvider: messageProvider)
        for validator in field.validators {
            guard generations[id, default: 0] == generation,
                  self.revision == revision else { return PTFormValidationResult() }
            if let message = await validator.validate(field.value) { issues.append(.init(fieldID: id, message: message)) }
        }
        return PTFormValidationResult(issues: issues)
    }

    private static func validate(_ field: PTFormField,
                                 messageProvider: PTFormValidationMessageProvider) -> [PTFormValidationIssue] {
        field.rules.compactMap { rule in
            switch rule {
            case .required:
                if case .string(let value) = field.value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
                if case .empty = field.value { return .init(fieldID: field.id, message: messageProvider.message(rule)) }
                return nil
            case .length(let minimum, let maximum):
                guard case .string(let value) = field.value else { return nil }
                guard value.count >= minimum, maximum.map({ value.count <= $0 }) ?? true else { return .init(fieldID: field.id, message: messageProvider.message(rule)) }
            case .regex(let pattern):
                guard case .string(let value) = field.value else { return nil }
                guard value.range(of: pattern, options: .regularExpression) != nil else { return .init(fieldID: field.id, message: messageProvider.message(rule)) }
            case .range(let minimum, let maximum):
                guard case .number(let value) = field.value, (minimum...maximum).contains(value) else { return .init(fieldID: field.id, message: messageProvider.message(rule)) }
            case .email:
                guard case .string(let value) = field.value, value.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil else { return .init(fieldID: field.id, message: messageProvider.message(rule)) }
            case .phone:
                guard case .string(let value) = field.value, value.range(of: #"^[0-9+()\-\s]{6,}$"#, options: .regularExpression) != nil else { return .init(fieldID: field.id, message: messageProvider.message(rule)) }
            case .bankCard:
                guard case .string(let value) = field.value else { return .init(fieldID: field.id, message: messageProvider.message(rule)) }
                let digits = value.filter(\.isNumber)
                guard (12...19).contains(digits.count) else { return .init(fieldID: field.id, message: messageProvider.message(rule)) }
            }
            return nil
        }
    }

    private func isVisible(_ field: PTFormField) -> Bool {
        let legacyVisible = field.dependency.map { fields[$0.fieldID]?.value == $0.expectedValue } ?? true
        return legacyVisible && evaluate(field.visibility)
    }

    private func evaluate(_ rule: PTFormVisibilityRule?, visited: Set<PTFormFieldID> = []) -> Bool {
        guard let rule else { return true }
        switch rule {
        case .always: return true
        case .equals(let field, let value): return fields[field]?.value == value
        case .notEquals(let field, let value): return fields[field]?.value != value
        case .isEmpty(let field): return isEmpty(fields[field]?.value)
        case .isNotEmpty(let field): return !isEmpty(fields[field]?.value)
        case .all(let rules): return rules.allSatisfy { evaluate($0, visited: visited) }
        case .any(let rules): return rules.contains { evaluate($0, visited: visited) }
        case .not(let nested): return !evaluate(nested, visited: visited)
        }
    }

    private func isEmpty(_ value: PTFormValue?) -> Bool {
        guard let value else { return true }
        if case .empty = value { return true }
        if case .string(let string) = value { return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return false
    }

    private static func normalize(fields: [PTFormField],
                                  sections: [PTFormSection],
                                  policy: PTFormUnsectionedFieldPolicy) -> (fields: [PTFormFieldID: PTFormField], order: [PTFormFieldID], sections: [PTFormSection], issues: [PTFormDefinitionIssue]) {
        var result: [PTFormFieldID: PTFormField] = [:]
        var order: [PTFormFieldID] = []
        var issues: [PTFormDefinitionIssue] = []
        for field in fields {
            guard result[field.id] == nil else {
                issues.append(.duplicateFieldID(field.id))
                continue
            }
            result[field.id] = field
            order.append(field.id)
        }

        var normalizedSections: [PTFormSection] = []
        var sectionIDs = Set<String>()
        var referenced = Set<PTFormFieldID>()
        for source in sections {
            guard sectionIDs.insert(source.id).inserted else {
                issues.append(.duplicateSectionID(source.id))
                continue
            }
            var ids: [PTFormFieldID] = []
            for fieldID in source.fieldIDs {
                guard result[fieldID] != nil else {
                    issues.append(.missingField(sectionID: source.id, fieldID: fieldID))
                    continue
                }
                guard referenced.insert(fieldID).inserted else {
                    issues.append(.duplicatedFieldReference(fieldID: fieldID, sectionID: source.id))
                    continue
                }
                ids.append(fieldID)
            }
            var section = source
            section.fieldIDs = ids
            normalizedSections.append(section)
        }

        let orphans = order.filter { !referenced.contains($0) }
        if !orphans.isEmpty {
            switch policy {
            case .appendToImplicitSection:
                normalizedSections.append(PTFormSection(id: "__pt_form_implicit_section__", fieldIDs: orphans))
            case .prependToImplicitSection:
                normalizedSections.insert(PTFormSection(id: "__pt_form_implicit_section__", fieldIDs: orphans), at: 0)
            case .reject:
                orphans.forEach { issues.append(.unsectionedField($0)) }
            }
        }

        // English: Keep invalid definitions observable through diagnostics without crashing a host app.
        // Español: Mantén las definiciones inválidas visibles mediante diagnósticos sin bloquear la aplicación anfitriona.
        // 中文：通过诊断结果暴露非法定义，但不让宿主应用因配置错误崩溃。
        return (result, order, normalizedSections, issues)
    }
}

#if canImport(UIKit)
@MainActor
public protocol PTFormFieldRenderer: AnyObject {
    var kind: PTFormFieldKind { get }
    var focusBehavior: PTFormFocusBehavior { get }
    func makeView(for field: PTFormField,
                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView
    func makeView(context: PTFormFieldRenderContext,
                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView
    func apply(theme: PTFormThemeAdapter)
}

public extension PTFormFieldRenderer {
    var focusBehavior: PTFormFocusBehavior { .automatic }

    func makeView(context: PTFormFieldRenderContext,
                  onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        makeView(for: context.field, onChange: onChange)
    }

    func apply(theme: PTFormThemeAdapter) {}
}

@MainActor
public struct PTFormFieldRenderContext {
    public let field: PTFormField
    public let sectionID: String
    public let theme: PTFormThemeAdapter
    public let validationIssue: PTFormValidationIssue?
    public let environment: PTFormEnvironment

    public init(field: PTFormField,
                sectionID: String,
                theme: PTFormThemeAdapter,
                validationIssue: PTFormValidationIssue? = nil,
                environment: PTFormEnvironment = .init()) {
        self.field = field
        self.sectionID = sectionID
        self.theme = theme
        self.validationIssue = validationIssue
        self.environment = environment
    }
}

@MainActor
public final class PTFormFieldRendererRegistry {
    private var renderers: [PTFormFieldKind: any PTFormFieldRenderer] = [:]
    private var identifiedRenderers: [String: any PTFormFieldRenderer] = [:]
    public var themeAdapter: PTFormThemeAdapter {
        didSet { renderers.values.forEach { $0.apply(theme: themeAdapter) } }
    }

    public init(themeAdapter: PTFormThemeAdapter = .init()) {
        self.themeAdapter = themeAdapter
        let defaults: [any PTFormFieldRenderer] = [
            PTFormTextFieldRenderer(), PTFormSecureTextFieldRenderer(), PTFormMultilineRenderer(),
            PTFormNumberRenderer(), PTFormPhoneRenderer(), PTFormBankCardRenderer(), PTFormToggleRenderer(),
            PTFormCheckboxRenderer(), PTFormSliderRenderer(), PTFormStepperRenderer(), PTFormDateRenderer(),
            PTFormPickerRenderer()
        ]
        defaults.forEach(register)
    }

    public func register(_ renderer: any PTFormFieldRenderer) {
        renderer.apply(theme: themeAdapter)
        renderers[renderer.kind] = renderer
    }

    public func register(_ renderer: any PTFormFieldRenderer, identifier: String) {
        renderer.apply(theme: themeAdapter)
        identifiedRenderers[identifier] = renderer
    }

    public func renderer(for kind: PTFormFieldKind) -> any PTFormFieldRenderer {
        let renderer = renderers[kind] ?? PTDefaultFormFieldRenderer(kind: kind)
        renderer.apply(theme: themeAdapter)
        return renderer
    }

    public func renderer(for identifier: String?, kind: PTFormFieldKind) -> any PTFormFieldRenderer {
        if let identifier, let renderer = identifiedRenderers[identifier] {
            renderer.apply(theme: themeAdapter)
            return renderer
        }
        return renderer(for: kind)
    }
}

@MainActor
public final class PTDefaultFormFieldRenderer: PTFormFieldRenderer {
    public let kind: PTFormFieldKind
    private let routedRenderer: any PTFormFieldRenderer

    public init(kind: PTFormFieldKind = .custom) {
        self.kind = kind
        routedRenderer = PTFormRendererFactory.make(kind: kind)
    }

    public func makeView(for field: PTFormField,
                         onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void) -> UIView {
        routedRenderer.makeView(for: field, onChange: onChange)
    }

    public var focusBehavior: PTFormFocusBehavior {
        routedRenderer.focusBehavior
    }

    public func apply(theme: PTFormThemeAdapter) {
        routedRenderer.apply(theme: theme)
    }
}

@MainActor
final class PTFormFieldCell: UICollectionViewCell {
    static let reuseID = "PTFormFieldCell"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let fieldContainer = UIView()
    private let issueLabel = UILabel()
    private let rootStack = UIStackView()
    private let titleStack = UIStackView()
    private let leadingStack = UIStackView()
    private var renderedView: UIView?
    private var onReturn: (@MainActor @Sendable () -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        rootStack.axis = .vertical
        rootStack.spacing = 6
        titleStack.axis = .vertical
        titleStack.spacing = 2
        leadingStack.axis = .horizontal
        leadingStack.alignment = .center
        leadingStack.spacing = 12
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        rootStack.addArrangedSubview(titleStack)
        rootStack.addArrangedSubview(fieldContainer)
        rootStack.addArrangedSubview(issueLabel)
        contentView.addSubview(rootStack)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            fieldContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
        ])
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 0
        issueLabel.font = .preferredFont(forTextStyle: .caption1)
        issueLabel.adjustsFontForContentSizeCategory = true
        issueLabel.textColor = .systemRed
        issueLabel.numberOfLines = 0
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func prepareForReuse() {
        super.prepareForReuse()
        renderedView?.removeFromSuperview()
        renderedView = nil
        onReturn = nil
        subtitleLabel.text = nil
        issueLabel.text = nil
    }

    func configure(field: PTFormField,
                   sectionID: String,
                   renderer: any PTFormFieldRenderer,
                   issue: String?,
                   themeAdapter: PTFormThemeAdapter,
                   environment: PTFormEnvironment,
                   keyboardCoordinator: PTFormKeyboardCoordinator,
                   hasPrevious: Bool,
                   hasNext: Bool,
                   onChange: @escaping @MainActor @Sendable (PTFormValue) -> Void,
                   onPrevious: @escaping @MainActor @Sendable () -> Void,
                   onNext: @escaping @MainActor @Sendable () -> Void,
                   onDone: @escaping @MainActor @Sendable () -> Void) {
        renderedView?.removeFromSuperview()
        renderer.apply(theme: themeAdapter)
        let context = PTFormFieldRenderContext(field: field,
                                               sectionID: sectionID,
                                               theme: themeAdapter,
                                               validationIssue: issue.map { PTFormValidationIssue(fieldID: field.id, message: $0) },
                                               environment: environment)
        let view = renderer.makeView(context: context, onChange: onChange)
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
        subtitleLabel.text = field.subtitle
        subtitleLabel.isHidden = field.subtitle == nil
        titleLabel.textColor = themeAdapter.primaryTextColor()
        titleLabel.font = themeAdapter.titleFont()
        issueLabel.text = issue
        issueLabel.isHidden = issue == nil || field.configuration?.showsValidationMessage == false
        issueLabel.textColor = issue == nil ? themeAdapter.secondaryTextColor() : themeAdapter.errorColor()
        isUserInteractionEnabled = field.isEnabled
        PTFormAccessibilityAdapter.apply(field: field,
                                         value: PTFormViewController.display(field.value),
                                         issue: issue,
                                         to: self)
        clearArrangedSubviews(from: rootStack)
        clearArrangedSubviews(from: leadingStack)
        switch field.configuration?.titlePlacement ?? .top {
        case .top:
            rootStack.addArrangedSubview(titleStack)
            rootStack.addArrangedSubview(fieldContainer)
            rootStack.addArrangedSubview(issueLabel)
        case .hidden:
            rootStack.addArrangedSubview(fieldContainer)
            rootStack.addArrangedSubview(issueLabel)
        case .leading:
            leadingStack.addArrangedSubview(titleStack)
            leadingStack.addArrangedSubview(fieldContainer)
            rootStack.addArrangedSubview(leadingStack)
            rootStack.addArrangedSubview(issueLabel)
        }
        self.onReturn = hasNext ? onNext : onDone
        if let textField = view as? UITextField {
            textField.returnKeyType = hasNext ? .next : .done
            textField.addAction(UIAction { [weak self] _ in self?.onReturn?() }, for: .editingDidEndOnExit)
            keyboardCoordinator.attach(to: textField,
                                       previous: onPrevious,
                                       next: onNext,
                                       done: onDone,
                                       hasPrevious: hasPrevious,
                                       hasNext: hasNext)
        } else if let textView = view as? UITextView {
            keyboardCoordinator.attach(to: textView,
                                       previous: onPrevious,
                                       next: onNext,
                                       done: onDone,
                                       hasPrevious: hasPrevious,
                                       hasNext: hasNext)
        }
    }

    func focusField() {
        if let textField = renderedView as? UITextField { textField.becomeFirstResponder() }
        else if let textView = renderedView as? UITextView { textView.becomeFirstResponder() }
    }

    // English: Remove arranged views from both the stack and its hierarchy before reusing them.
    // Español: Retira las vistas organizadas del stack y de su jerarquía antes de reutilizarlas.
    // 中文：复用布局容器前，同时从 stack 和视图层级中移除旧的 arranged view。
    private func clearArrangedSubviews(from stack: UIStackView) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
}

@MainActor
public final class PTFormViewController: PTBaseViewController {
    public let form: PTFormEngine
    public let listView: PTCollectionView
    public let rendererRegistry: PTFormFieldRendererRegistry
    public let sectionRendererRegistry: PTFormSectionRendererRegistry
    public let formTheme: PTFormThemeAdapter
    public let configuration: PTFormConfiguration
    public var onEvent: (@MainActor @Sendable (PTFormEvent) -> Void)?
    public var showsValidationSummary = false

    private let keyboardCoordinator = PTFormKeyboardCoordinator()
    private let collectionAdapter: PTFormCollectionAdapter
    private var cachedFields: [PTFormFieldID: PTFormField] = [:]
    private var latestLocations: [PTFormFieldLocation] = []
    private var validationIssues: [PTFormFieldID: String] = [:]
    private var announcedIssueIDs: Set<PTFormFieldID> = []
    private var refreshTask: Task<Void, Never>?

    // English: Preserve the original controller initializer for existing callers.
    // Español: Conserva el inicializador original del controlador para los consumidores existentes.
    // 中文：保留原有控制器初始化方法，避免破坏现有调用方。
    public init(form: PTFormEngine) {
        self.form = form
        self.configuration = .grouped
        self.rendererRegistry = PTFormFieldRendererRegistry()
        self.sectionRendererRegistry = PTFormSectionRendererRegistry()
        self.formTheme = rendererRegistry.themeAdapter
        self.listView = PTCollectionView(viewConfig: PTCollectionViewConfig())
        self.collectionAdapter = PTFormCollectionAdapter()
        super.init(nibName: nil, bundle: nil)
    }

    public init(form: PTFormEngine,
                configuration: PTFormConfiguration = .grouped,
                rendererRegistry: PTFormFieldRendererRegistry = .init(),
                sectionRendererRegistry: PTFormSectionRendererRegistry = .init(),
                themeAdapter: PTFormThemeAdapter? = nil) {
        self.form = form
        self.configuration = configuration
        self.rendererRegistry = rendererRegistry
        self.sectionRendererRegistry = sectionRendererRegistry
        self.formTheme = themeAdapter ?? rendererRegistry.themeAdapter
        self.listView = PTCollectionView(viewConfig: PTCollectionViewConfig())
        self.collectionAdapter = PTFormCollectionAdapter()
        self.rendererRegistry.themeAdapter = self.formTheme
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, deprecated, message: "Use init(form:configuration:rendererRegistry:sectionRendererRegistry:themeAdapter:).")
    public init(form: PTFormEngine,
                rendererRegistry: PTFormFieldRendererRegistry) {
        self.form = form
        self.configuration = .grouped
        self.rendererRegistry = rendererRegistry
        self.sectionRendererRegistry = PTFormSectionRendererRegistry()
        self.formTheme = rendererRegistry.themeAdapter
        self.listView = PTCollectionView(viewConfig: PTCollectionViewConfig())
        self.collectionAdapter = PTFormCollectionAdapter()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, deprecated, message: "Use init(form:configuration:rendererRegistry:sectionRendererRegistry:themeAdapter:).")
    public init(form: PTFormEngine,
                rendererRegistry: PTFormFieldRendererRegistry,
                themeAdapter: PTFormThemeAdapter) {
        self.form = form
        self.configuration = .grouped
        self.rendererRegistry = rendererRegistry
        self.sectionRendererRegistry = PTFormSectionRendererRegistry()
        self.formTheme = themeAdapter
        self.rendererRegistry.themeAdapter = themeAdapter
        self.listView = PTCollectionView(viewConfig: PTCollectionViewConfig())
        self.collectionAdapter = PTFormCollectionAdapter()
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        form = PTFormEngine(fields: [])
        configuration = .grouped
        rendererRegistry = PTFormFieldRendererRegistry()
        sectionRendererRegistry = PTFormSectionRendererRegistry()
        formTheme = rendererRegistry.themeAdapter
        listView = PTCollectionView(viewConfig: PTCollectionViewConfig())
        collectionAdapter = PTFormCollectionAdapter()
        super.init(coder: coder)
    }

    deinit {
        refreshTask?.cancel()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]) { [weak self] (_: PTFormViewController, _: UITraitCollection) in
            guard let self else { return }
            self.rendererRegistry.themeAdapter = self.formTheme
            self.listView.contentCollectionView.reloadData()
        }
        view.addSubview(listView)
        listView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            listView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listView.topAnchor.constraint(equalTo: view.topAnchor),
            listView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        listView.viewConfig.sectionEdges = NSDirectionalEdgeInsets(top: configuration.contentInsets.top,
                                                                     leading: configuration.contentInsets.leading,
                                                                     bottom: configuration.contentInsets.bottom,
                                                                     trailing: configuration.contentInsets.trailing)
        listView.registerClassCells(classs: [PTFormFieldCell.reuseID: PTFormFieldCell.self])
        listView.registerSupplementaryView(classs: [PTFormDefaultSectionHeader.reuseID: PTFormDefaultSectionHeader.self],
                                            kind: UICollectionView.elementKindSectionHeader)
        listView.registerSupplementaryView(classs: [PTFormDefaultSectionFooter.reuseID: PTFormDefaultSectionFooter.self],
                                            kind: UICollectionView.elementKindSectionFooter)

        listView.headerInCollection = { [weak self] kind, collectionView, section, indexPath in
            guard let self,
                  let box = section.headerDataModel as? PTFormSupplementaryBox else { return nil }
            let context = PTFormSectionRenderContext(sectionID: box.sectionID,
                                                     theme: self.formTheme,
                                                     environment: self.formEnvironment())
            return self.sectionRendererRegistry.dequeueView(content: box.content,
                                                             context: context,
                                                             kind: kind,
                                                             collectionView: collectionView,
                                                             indexPath: indexPath)
        }
        listView.footerInCollection = { [weak self] kind, collectionView, section, indexPath in
            guard let self,
                  let box = section.footerDataModel as? PTFormSupplementaryBox else { return nil }
            let context = PTFormSectionRenderContext(sectionID: box.sectionID,
                                                     theme: self.formTheme,
                                                     environment: self.formEnvironment())
            return self.sectionRendererRegistry.dequeueView(content: box.content,
                                                             context: context,
                                                             kind: kind,
                                                             collectionView: collectionView,
                                                             indexPath: indexPath)
        }
        listView.cellInCollection = { [weak self] collectionView, section, indexPath in
            guard let self,
                  let row = section.rows?[safe: indexPath.item],
                  let box = row.dataModel as? PTFormFieldBox,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PTFormFieldCell.reuseID,
                                                                 for: indexPath) as? PTFormFieldCell else { return nil }
            let field = self.renderField(box.field)
            cell.configure(field: field,
                           sectionID: section.identifier,
                           renderer: self.rendererRegistry.renderer(for: field.rendererIdentifier,
                                                                     kind: field.kind),
                           issue: self.validationIssues[box.field.id],
                           themeAdapter: self.formTheme,
                           environment: self.formEnvironment(),
                           keyboardCoordinator: self.keyboardCoordinator,
                           hasPrevious: self.focusableLocation(for: field.id, step: -1) != nil,
                           hasNext: self.focusableLocation(for: field.id, step: 1) != nil,
                           onChange: { [weak self] value in
                self?.setValue(value, for: box.field.id)
           },
                           onPrevious: { [weak self] in self?.focusPrevious(after: field.id) },
                           onNext: { [weak self] in self?.focusNext(after: field.id) },
                           onDone: { [weak self] in self?.view.endEditing(true) })
            return cell
        }
        refreshTask = Task { @MainActor [weak self] in
            await self?.refresh()
        }
    }

    public func refresh() async {
        let snapshot = await form.makeSnapshot()
        latestLocations = collectionAdapter.locations(for: snapshot)
        cachedFields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.id, $0) })
        let sections = collectionAdapter.makeSections(from: snapshot,
                                                       configuration: configuration,
                                                       themeAdapter: formTheme,
                                                       validationIssues: validationIssues)
        listView.showCollectionDetail(collectionData: sections, animated: false)
    }

    private func setValue(_ value: PTFormValue, for id: PTFormFieldID) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await form.setValue(value, for: id)
                onEvent?(.valueChanged(id, value))
                if configuration.validationPolicy.trigger == .onChange {
                    let result = await form.validateField(id)
                    applyValidation(result, for: id)
                    onEvent?(.validationChanged(id))
                } else {
                    validationIssues[id] = nil
                }
                await refresh()
            } catch {
                PTFeedbackCenter.shared.emit(.error)
            }
        }
    }

    public func validate() async -> PTFormValidationResult {
        let result = await form.validateAll()
        validationIssues = Dictionary(result.issues.map { ($0.fieldID, $0.message) }, uniquingKeysWith: { _, last in last })
        if let issue = result.issues.first {
            PTFormAccessibilityAdapter.announceValidationFailure(issue)
            PTFeedbackCenter.shared.emit(.validationFailure)
            if configuration.validationPolicy.focusesFirstInvalidField {
                focusField(issue.fieldID)
            }
        }
        if let issue = result.issues.first {
            onEvent?(.validationChanged(issue.fieldID))
        }
        await refresh()
        return result
    }

    public func submit(_ operation: @escaping @Sendable ([PTFormFieldID: PTFormValue]) async throws -> Void) async throws {
        let result = await validate()
        guard result.isValid else { throw PTFormError.invalid(result) }
        do {
            try await form.submit(operation)
            PTFeedbackCenter.shared.emit(.success)
            onEvent?(.submissionChanged(.succeeded))
        } catch {
            PTFeedbackCenter.shared.emit(.error)
            throw error
        }
    }

    private func focusNext(after id: PTFormFieldID) {
        guard let location = focusableLocation(for: id, step: 1) else {
            view.endEditing(true)
            return
        }
        focus(location: location)
    }

    private func focusPrevious(after id: PTFormFieldID) {
        guard let location = focusableLocation(for: id, step: -1) else { return }
        focus(location: location)
    }

    public func focusField(_ id: PTFormFieldID) {
        guard let location = latestLocations.first(where: { $0.fieldID == id }) else { return }
        focus(location: location)
    }

    public func scrollToField(_ id: PTFormFieldID, animated: Bool = true) {
        guard let location = latestLocations.first(where: { $0.fieldID == id }) else { return }
        listView.contentCollectionView.scrollToItem(at: IndexPath(item: location.itemIndex,
                                                                  section: location.sectionIndex),
                                                    at: .centeredVertically,
                                                    animated: animated)
    }

    private func focus(location: PTFormFieldLocation) {
        let indexPath = IndexPath(item: location.itemIndex, section: location.sectionIndex)
        listView.contentCollectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        Task { @MainActor [weak self] in
            await Task.yield()
            (self?.listView.contentCollectionView.cellForItem(at: indexPath) as? PTFormFieldCell)?.focusField()
        }
    }

    private func focusableLocation(for id: PTFormFieldID, step: Int) -> PTFormFieldLocation? {
        let locations = latestLocations.filter { location in
            guard let field = cachedFields[location.fieldID], field.isEnabled, !field.isReadOnly else { return false }
            return rendererRegistry.renderer(for: field.rendererIdentifier, kind: field.kind).focusBehavior != .notFocusable
        }
        guard let start = locations.firstIndex(where: { $0.fieldID == id }) else { return nil }
        let index = start + step
        return locations.indices.contains(index) ? locations[index] : nil
    }

    private func renderField(_ field: PTFormField) -> PTFormField {
        var result = field
        if result.configuration == nil {
            result.configuration = configuration.defaultFieldConfiguration
        }
        switch configuration.interactionMode {
        case .editable:
            break
        case .readOnly:
            result.isReadOnly = true
        case .disabled:
            result.isEnabled = false
        }
        return result
    }

    private func formEnvironment() -> PTFormEnvironment {
        PTFormEnvironment(isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
                          isHighContrastEnabled: traitCollection.accessibilityContrast == .high,
                          layoutDirection: view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .rightToLeft : .leftToRight)
    }

    private func applyValidation(_ result: PTFormValidationResult, for id: PTFormFieldID) {
        validationIssues[id] = result.issues.first?.message
        if let issue = result.issues.first, announcedIssueIDs.insert(id).inserted {
            PTFormAccessibilityAdapter.announceValidationFailure(issue)
            PTFeedbackCenter.shared.emit(.validationFailure)
        } else if result.issues.isEmpty {
            announcedIssueIDs.remove(id)
        }
    }

    static func display(_ value: PTFormValue) -> String {
        switch value { case .empty: ""; case .string(let v): v; case .number(let v): String(v); case .boolean(let v): v ? "On" : "Off"; case .date(let v): v.formatted(); case .data: "Data" }
    }
}
#endif
