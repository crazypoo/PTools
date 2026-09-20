//
//  PTSearchSuggestionProvider.swift
//  PooTools
//
// English: Suggestions use their own provider and never share the result array.
// Español: Las sugerencias usan su propio provider y nunca comparten el array de resultados.
// 中文：建议使用独立 Provider，不与最终结果数组共用状态。
//

import Foundation

public protocol PTSearchSuggestionProvider: Sendable {
    associatedtype Suggestion: Sendable

    func suggestions(for keyword: String) async throws -> [Suggestion]
}

public struct PTClosureSearchSuggestionProvider<Suggestion: Sendable>: PTSearchSuggestionProvider {
    private let handler: @Sendable (String) async throws -> [Suggestion]

    public init(handler: @escaping @Sendable (String) async throws -> [Suggestion]) {
        self.handler = handler
    }

    public func suggestions(for keyword: String) async throws -> [Suggestion] {
        try await handler(keyword)
    }
}
