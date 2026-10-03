// English: Rich-text match rules and conflict policies remain value-only and independent from caching.
// Español: Las reglas y políticas de conflicto son valores independientes de la caché.
// 中文：富文本匹配规则和冲突策略保持值类型，并与缓存解耦。

import Foundation

public enum PTTextMatchRule: Sendable, Hashable {
    case range(NSRange)
    case regex(pattern: String, options: UInt32 = 0)
    case custom(String)
    case link
    case date
    case phoneNumber
    case address
    case transitInformation
}

public enum PTTextMatchKind: String, Sendable {
    case range
    case regex
    case custom
    case link
    case date
    case phoneNumber
    case address
    case transitInformation
}

public enum PTTextMatchConflictPolicy: Sendable {
    case firstWins
    case lastWins
    case longestWins
    case priority
    case allowOverlap
}

public struct PTTextMatch: Sendable, Equatable {
    public let range: NSRange
    public let kind: PTTextMatchKind
    public let text: String

    public init(range: NSRange, kind: PTTextMatchKind, text: String) {
        self.range = range
        self.kind = kind
        self.text = text
    }
}
