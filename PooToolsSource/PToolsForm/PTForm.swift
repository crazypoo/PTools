// English: A typed form engine with stable field identity and cancellable validation.
// Español: Un motor de formularios tipado con identidad estable y validación cancelable.
// 中文：提供稳定字段身份和可取消校验的类型化表单引擎。

import Foundation

#if canImport(UIKit)
import UIKit
import SnapKit
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
    case text, secureText, multilineText, number, phone, bankCard, toggle, checkbox, slider, stepper, date, picker, custom, action, detail, status
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
    public var actionID: PTFormActionID?
    public var detailText: String?
    public var isLoading: Bool
    public var isDestructive: Bool

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
                rendererIdentifier: String? = nil,
                actionID: PTFormActionID? = nil,
                detailText: String? = nil,
                isLoading: Bool = false,
                isDestructive: Bool = false) {
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
        self.actionID = actionID
        self.detailText = detailText
        self.isLoading = isLoading
        self.isDestructive = isDestructive
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
                rendererIdentifier: String? = nil,
                actionID: PTFormActionID? = nil,
                detailText: String? = nil,
                isLoading: Bool = false,
                isDestructive: Bool = false) {
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
        self.actionID = actionID
        self.detailText = detailText
        self.isLoading = isLoading
        self.isDestructive = isDestructive
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
    case duplicateField(PTFormFieldID)
    case duplicateSection(String)
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
        try validateSectionMembership(section, excluding: section.id)
        sections[index] = section
        revision &+= 1
    }

    private func validateSectionMembership(_ section: PTFormSection, excluding excludedID: String?) throws {
        var seen = Set<PTFormFieldID>()
        for id in section.fieldIDs {
            guard fields[id] != nil else { throw PTFormError.missingField(id) }
            guard seen.insert(id).inserted else { throw PTFormError.duplicateField(id) }
            guard !sections.contains(where: { $0.id != excludedID && $0.fieldIDs.contains(id) }) else {
                throw PTFormError.duplicateField(id)
            }
        }
    }

    public func setSectionVisible(_ visible: Bool, for id: String) throws {
        guard sections.contains(where: { $0.id == id }) else { throw PTFormError.missingSection(id) }
        sectionVisibilityOverrides[id] = visible
        revision &+= 1
    }

    public func setFieldLoading(_ loading: Bool, for id: PTFormFieldID) throws {
        guard var field = fields[id] else { throw PTFormError.missingField(id) }
        guard field.isLoading != loading else { return }
        field.isLoading = loading
        try updateField(field)
    }

    public func insertField(_ field: PTFormField, in sectionID: String? = nil, at index: Int? = nil) throws {
        guard fields[field.id] == nil else { throw PTFormError.duplicateField(field.id) }
        let destinationID = sectionID ?? "__pt_form_implicit_section__"
        if !sections.contains(where: { $0.id == destinationID }) {
            guard sectionID == nil else { throw PTFormError.missingSection(destinationID) }
            sections.append(PTFormSection(id: destinationID, fieldIDs: []))
        }
        guard let sectionIndex = sections.firstIndex(where: { $0.id == destinationID }) else {
            throw PTFormError.missingSection(destinationID)
        }
        fields[field.id] = field
        initialValues[field.id] = field.value
        order.append(field.id)
        let insertIndex = min(max(0, index ?? sections[sectionIndex].fieldIDs.count),
                              sections[sectionIndex].fieldIDs.count)
        sections[sectionIndex].fieldIDs.insert(field.id, at: insertIndex)
        revision &+= 1
    }

    public func removeField(_ id: PTFormFieldID) throws {
        guard fields.removeValue(forKey: id) != nil else { throw PTFormError.missingField(id) }
        order.removeAll { $0 == id }
        initialValues.removeValue(forKey: id)
        generations.removeValue(forKey: id)
        validationTasks[id]?.cancel()
        validationTasks.removeValue(forKey: id)
        for index in sections.indices {
            sections[index].fieldIDs.removeAll { $0 == id }
        }
        revision &+= 1
    }

    public func insertSection(_ section: PTFormSection, at index: Int? = nil) throws {
        guard !sections.contains(where: { $0.id == section.id }) else {
            throw PTFormError.duplicateSection(section.id)
        }
        try validateSectionMembership(section, excluding: nil)
        let location = min(max(0, index ?? sections.count), sections.count)
        sections.insert(section, at: location)
        revision &+= 1
    }

    public func removeSection(_ id: String) throws {
        guard let index = sections.firstIndex(where: { $0.id == id }) else {
            throw PTFormError.missingSection(id)
        }
        let removed = sections.remove(at: index)
        sectionVisibilityOverrides.removeValue(forKey: id)
        for fieldID in removed.fieldIDs where !sections.contains(where: { $0.fieldIDs.contains(fieldID) }) {
            try removeField(fieldID)
        }
        revision &+= 1
    }

    public func moveField(_ id: PTFormFieldID, to sectionID: String, at index: Int? = nil) throws {
        guard fields[id] != nil else { throw PTFormError.missingField(id) }
        guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionID }) else {
            throw PTFormError.missingSection(sectionID)
        }
        for i in sections.indices { sections[i].fieldIDs.removeAll { $0 == id } }
        let destination = min(max(0, index ?? sections[sectionIndex].fieldIDs.count),
                              sections[sectionIndex].fieldIDs.count)
        sections[sectionIndex].fieldIDs.insert(id, at: destination)
        revision &+= 1
    }

    // Preflight the entire batch before changing actor state. A missing or duplicate
    // ID never leaves a partially updated form snapshot.
    public func performUpdates(_ mutations: [PTFormMutation]) throws {
        var availableFields = Set(fields.keys)
        var membership = Dictionary(uniqueKeysWithValues:
            sections.map { ($0.id, Set($0.fieldIDs)) })
        for mutation in mutations {
            switch mutation {
            case .setValue(_, let id), .setFieldEnabled(_, let id),
                 .setFieldReadOnly(_, let id), .setFieldLoading(_, let id):
                guard availableFields.contains(id) else { throw PTFormError.missingField(id) }
            case .updateSection(let section):
                guard membership[section.id] != nil else { throw PTFormError.missingSection(section.id) }
                for id in section.fieldIDs {
                    guard availableFields.contains(id) else { throw PTFormError.missingField(id) }
                    guard !membership.contains(where: { $0.key != section.id && $0.value.contains(id) }) else {
                        throw PTFormError.duplicateField(id)
                    }
                }
                guard Set(section.fieldIDs).count == section.fieldIDs.count else {
                    throw PTFormError.duplicateField(section.fieldIDs[0])
                }
                membership[section.id] = Set(section.fieldIDs)
            case .setSectionVisible(_, let id):
                guard membership[id] != nil else { throw PTFormError.missingSection(id) }
            case .removeSection(let id):
                guard let removed = membership.removeValue(forKey: id) else {
                    throw PTFormError.missingSection(id)
                }
                for fieldID in removed where !membership.values.contains(where: { $0.contains(fieldID) }) {
                    availableFields.remove(fieldID)
                }
            case .insertSection(let section, _):
                guard membership[section.id] == nil else { throw PTFormError.duplicateSection(section.id) }
                for id in section.fieldIDs {
                    guard availableFields.contains(id) else { throw PTFormError.missingField(id) }
                    guard !membership.values.contains(where: { $0.contains(id) }) else {
                        throw PTFormError.duplicateField(id)
                    }
                }
                guard Set(section.fieldIDs).count == section.fieldIDs.count else {
                    throw PTFormError.duplicateField(section.fieldIDs[0])
                }
                membership[section.id] = Set(section.fieldIDs)
            case .insertField(let field, let sectionID, _):
                guard availableFields.insert(field.id).inserted else { throw PTFormError.duplicateField(field.id) }
                let destination = sectionID ?? "__pt_form_implicit_section__"
                if sectionID != nil && membership[destination] == nil {
                    throw PTFormError.missingSection(destination)
                }
                membership[destination, default: []].insert(field.id)
            case .removeField(let id):
                guard availableFields.remove(id) != nil else { throw PTFormError.missingField(id) }
                for key in Array(membership.keys) { membership[key]?.remove(id) }
            case .moveField(let id, let sectionID, _):
                guard availableFields.contains(id) else { throw PTFormError.missingField(id) }
                guard membership[sectionID] != nil else { throw PTFormError.missingSection(sectionID) }
                for key in Array(membership.keys) { membership[key]?.remove(id) }
                membership[sectionID, default: []].insert(id)
            }
        }
        for mutation in mutations {
            switch mutation {
            case .setValue(let value, let id): try setValue(value, for: id)
            case .setFieldEnabled(let enabled, let id): try setFieldEnabled(enabled, for: id)
            case .setFieldReadOnly(let readOnly, let id): try setFieldReadOnly(readOnly, for: id)
            case .setFieldLoading(let loading, let id): try setFieldLoading(loading, for: id)
            case .updateSection(let section): try updateSection(section)
            case .setSectionVisible(let visible, let id): try setSectionVisible(visible, for: id)
            case .insertField(let field, let sectionID, let index):
                try insertField(field, in: sectionID, at: index)
            case .removeField(let id): try removeField(id)
            case .insertSection(let section, let index): try insertSection(section, at: index)
            case .removeSection(let id): try removeSection(id)
            case .moveField(let id, let sectionID, let index):
                try moveField(id, to: sectionID, at: index)
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
            PTFormPickerRenderer(),
            PTFormSettingsRowRenderer(kind: .action),
            PTFormSettingsRowRenderer(kind: .detail),
            PTFormSettingsRowRenderer(kind: .status)
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
    private var activeFieldID: PTFormFieldID?
    private var currentTitlePlacement: PTFormTitlePlacement?
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
        rootStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
        }
        fieldContainer.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(36)
        }
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
        activeFieldID = nil
        currentTitlePlacement = nil
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
        // Keep the active text editor attached during diffable reconfiguration.
        // Recreating a focused UITextField/UITextView would dismiss the keyboard.
        let isEditing = activeFieldID == field.id && (renderedView?.isFirstResponder ?? false)
        renderer.apply(theme: themeAdapter)
        let view: UIView
        if isEditing, let current = renderedView {
            view = current
        } else {
            renderedView?.removeFromSuperview()
            let context = PTFormFieldRenderContext(field: field,
                                                   sectionID: sectionID,
                                                   theme: themeAdapter,
                                                   validationIssue: issue.map { PTFormValidationIssue(fieldID: field.id, message: $0) },
                                                   environment: environment)
            view = renderer.makeView(context: context, onChange: onChange)
            renderedView = view
            activeFieldID = field.id
            fieldContainer.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
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
        let placement = field.configuration?.titlePlacement ?? .top
        if placement != currentTitlePlacement {
            clearArrangedSubviews(from: rootStack)
            clearArrangedSubviews(from: leadingStack)
            switch placement {
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
            currentTitlePlacement = placement
        }
        self.onReturn = hasNext ? onNext : onDone
        if let textField = view as? UITextField, !isEditing {
            textField.returnKeyType = hasNext ? .next : .done
            textField.addAction(UIAction { [weak self] _ in self?.onReturn?() }, for: .editingDidEndOnExit)
            keyboardCoordinator.attach(to: textField,
                                       previous: onPrevious,
                                       next: onNext,
                                       done: onDone,
                                       hasPrevious: hasPrevious,
                                       hasNext: hasNext)
        } else if let textView = view as? UITextView, !isEditing {
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
    public let formView: PTFormView
    public var form: PTFormEngine { formView.form }
    public var listView: PTCollectionView { formView.listView }
    public var rendererRegistry: PTFormFieldRendererRegistry { formView.rendererRegistry }
    public var sectionRendererRegistry: PTFormSectionRendererRegistry { formView.sectionRendererRegistry }
    public var formTheme: PTFormThemeAdapter { formView.formTheme }
    public var configuration: PTFormConfiguration { formView.configuration }
    public var onEvent: (@MainActor @Sendable (PTFormEvent) -> Void)? {
        get { formView.onEvent }
        set { formView.onEvent = newValue }
    }
    public var showsValidationSummary: Bool {
        get { formView.showsValidationSummary }
        set { formView.showsValidationSummary = newValue }
    }

    public init(form: PTFormEngine) {
        formView = PTFormView(form: form)
        super.init(nibName: nil, bundle: nil)
    }

    public init(form: PTFormEngine,
                configuration: PTFormConfiguration = .grouped,
                rendererRegistry: PTFormFieldRendererRegistry = .init(),
                sectionRendererRegistry: PTFormSectionRendererRegistry = .init(),
                themeAdapter: PTFormThemeAdapter? = nil) {
        formView = PTFormView(form: form, configuration: configuration,
                              rendererRegistry: rendererRegistry,
                              sectionRendererRegistry: sectionRendererRegistry,
                              themeAdapter: themeAdapter)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, deprecated, message: "Use init(form:configuration:rendererRegistry:sectionRendererRegistry:themeAdapter:).")
    public init(form: PTFormEngine, rendererRegistry: PTFormFieldRendererRegistry) {
        formView = PTFormView(form: form, rendererRegistry: rendererRegistry)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, deprecated, message: "Use init(form:configuration:rendererRegistry:sectionRendererRegistry:themeAdapter:).")
    public init(form: PTFormEngine,
                rendererRegistry: PTFormFieldRendererRegistry,
                themeAdapter: PTFormThemeAdapter) {
        formView = PTFormView(form: form, rendererRegistry: rendererRegistry, themeAdapter: themeAdapter)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        formView = PTFormView(form: PTFormEngine(fields: []))
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(formView)
        formView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func refresh() async { await formView.refresh() }
    public func validate() async -> PTFormValidationResult { await formView.validate() }
    public func submit(_ operation: @escaping @Sendable ([PTFormFieldID: PTFormValue]) async throws -> Void) async throws {
        try await formView.submit(operation)
    }
    public func focusField(_ id: PTFormFieldID) { formView.focusField(id) }
    public func scrollToField(_ id: PTFormFieldID, animated: Bool = true) {
        formView.scrollToField(id, animated: animated)
    }
    public static func display(_ value: PTFormValue) -> String { PTFormView.display(value) }
}
#endif
