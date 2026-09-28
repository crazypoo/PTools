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

public enum PTFormFieldKind: String, Codable, Sendable {
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
public final class PTFormViewController: PTBaseViewController {
    public let form: PTFormEngine
    private let listView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout.list(using: .init(appearance: .insetGrouped)))
    private var dataSource: UICollectionViewDiffableDataSource<Int, PTFormFieldID>!
    private var cachedFields: [PTFormFieldID: PTFormField] = [:]

    public init(form: PTFormEngine) { self.form = form; super.init(nibName: nil, bundle: nil) }
    public required init?(coder: NSCoder) { fatalError("PTFormViewController requires init(form:)") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(listView); listView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([listView.leadingAnchor.constraint(equalTo: view.leadingAnchor), listView.trailingAnchor.constraint(equalTo: view.trailingAnchor), listView.topAnchor.constraint(equalTo: view.topAnchor), listView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        let registration = UICollectionView.CellRegistration<UICollectionViewListCell, PTFormFieldID> { [weak self] cell, _, id in
            guard let field = self?.formField(id) else { return }
            var content = cell.defaultContentConfiguration(); content.text = field.title; content.secondaryText = Self.display(field.value); cell.contentConfiguration = content
        }
        dataSource = UICollectionViewDiffableDataSource<Int, PTFormFieldID>(collectionView: listView) { collectionView, indexPath, id in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: id)
        }
        Task { await refresh() }
    }

    public func refresh() async {
        let fields = await form.visibleFields()
        cachedFields = Dictionary(uniqueKeysWithValues: fields.map { ($0.id, $0) })
        var snapshot = NSDiffableDataSourceSnapshot<Int, PTFormFieldID>(); snapshot.appendSections([0]); snapshot.appendItems(fields.map(\.id)); dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func formField(_ id: PTFormFieldID) -> PTFormField? { cachedFields[id] }
    private static func display(_ value: PTFormValue) -> String {
        switch value { case .empty: ""; case .string(let v): v; case .number(let v): String(v); case .boolean(let v): v ? "On" : "Off"; case .date(let v): v.formatted(); case .data: "Data" }
    }
}
#endif
