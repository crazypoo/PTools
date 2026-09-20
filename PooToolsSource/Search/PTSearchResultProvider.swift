//
//  PTSearchResultProvider.swift
//  PooTools
//
// English: Providers keep transport and business data outside the search controller.
// Español: Los providers mantienen el transporte y los datos de negocio fuera del controlador.
// 中文：Provider 将传输和业务数据隔离在搜索控制器之外。
//

import Foundation

public protocol PTSearchResultProvider: Sendable {
    associatedtype Item: Sendable

    func search(keyword: String) async throws -> [Item]
}

public struct PTClosureSearchResultProvider<Item: Sendable>: PTSearchResultProvider {
    private let handler: @Sendable (String) async throws -> [Item]

    public init(handler: @escaping @Sendable (String) async throws -> [Item]) {
        self.handler = handler
    }

    public func search(keyword: String) async throws -> [Item] {
        try await handler(keyword)
    }
}
