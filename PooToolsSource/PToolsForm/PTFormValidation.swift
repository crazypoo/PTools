// English: Cross-field validation contracts are Sendable and do not retain UIKit.
// Español: Los contratos de validación entre campos son Sendable y no retienen UIKit.
// 中文：跨字段校验契约遵守 Sendable，不持有 UIKit 对象。

import Foundation

public enum PTFormValidationSeverity: Sendable, Codable, Hashable {
    case info
    case warning
    case error
}

public struct PTFormValidationContext: Sendable {
    public let values: [PTFormFieldID: PTFormValue]
    public let revision: UInt64

    public init(values: [PTFormFieldID: PTFormValue], revision: UInt64 = 0) {
        self.values = values
        self.revision = revision
    }

    public func value(for id: PTFormFieldID) -> PTFormValue? {
        values[id]
    }
}

public struct PTFormCrossValidator: Sendable {
    public let fieldIDs: Set<PTFormFieldID>
    public let validate: @Sendable (PTFormValidationContext) async -> [PTFormValidationIssue]

    public init(fieldIDs: Set<PTFormFieldID>,
                validate: @escaping @Sendable (PTFormValidationContext) async -> [PTFormValidationIssue]) {
        self.fieldIDs = fieldIDs
        self.validate = validate
    }
}

public struct PTFormValidationMessageProvider: Sendable {
    public let message: @Sendable (PTFormValidationRule) -> String

    public init(message: @escaping @Sendable (PTFormValidationRule) -> String = { rule in
        switch rule {
        case .required: return "Required"
        case .length: return "Invalid length"
        case .regex: return "Invalid format"
        case .range: return "Out of range"
        case .email: return "Invalid email"
        case .phone: return "Invalid phone"
        case .bankCard: return "Invalid card"
        }
    }) {
        self.message = message
    }
}
