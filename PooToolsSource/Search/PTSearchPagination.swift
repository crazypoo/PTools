//
//  PTSearchPagination.swift
//  PooTools
//
// English: Pagination state is small, explicit, and guarded against duplicate loads.
// Español: El estado de paginación es pequeño, explícito y protegido contra cargas duplicadas.
// 中文：分页状态保持轻量、明确，并防止重复加载。
//

import Foundation
#if SWIFT_PACKAGE || canImport(PToolsCore)
import PToolsCore
#endif

@MainActor
public enum PTSearchPaginationState {
    case idle
    case loading
    case finished
    case failed(Error)
}

@MainActor
public struct PTSearchPagination {
    public private(set) var currentPage: Int
    public private(set) var pageSize: Int
    public private(set) var hasMore: Bool
    public private(set) var state: PTSearchPaginationState

    public init(pageSize: Int = 20) {
        self.currentPage = 0
        self.pageSize = max(1, pageSize)
        self.hasMore = true
        self.state = .idle
    }

    public var canLoadMore: Bool {
        hasMore && !isLoading
    }

    public var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    public mutating func reset(pageSize: Int? = nil) {
        if let pageSize { self.pageSize = max(1, pageSize) }
        currentPage = 0
        hasMore = true
        state = .idle
    }

    public mutating func beginLoading() -> Int? {
        guard canLoadMore else { return nil }
        let nextPage = currentPage + 1
        state = .loading
        return nextPage
    }

    public mutating func finish(hasMore: Bool) {
        currentPage += 1
        self.hasMore = hasMore
        state = hasMore ? .idle : .finished
    }

    public mutating func fail(_ error: Error) {
        state = .failed(error)
    }
}

// English: Opt-in adapter for callers that need generation-safe pagination without changing the legacy type.
// Español: Adaptador opt-in para paginación segura por generación sin cambiar el tipo heredado.
// 中文：为需要代次安全分页的调用方提供可选适配器，不改变旧类型。
@MainActor
public struct PTSearchPaginationAdapter {
    private var machine: PTPaginationMachine

    public init(configuration: PTPaginationConfiguration = .init()) {
        machine = PTPaginationMachine(configuration: configuration)
    }

    public var currentPage: Int { machine.currentPage }
    public var pageSize: Int { machine.configuration.pageSize }
    public var hasMore: Bool { machine.hasMore }
    public var isLoading: Bool { machine.isLoading }

    @discardableResult
    public mutating func beginRefresh() -> PTPaginationRequestToken {
        machine.beginRefresh()
    }

    @discardableResult
    public mutating func beginNextPage() -> PTPaginationRequestToken? {
        machine.beginNextPage()
    }

    public func isCurrent(_ token: PTPaginationRequestToken) -> Bool {
        machine.isCurrent(token)
    }

    @discardableResult
    public mutating func applySuccess(_ token: PTPaginationRequestToken,
                                      itemCount: Int,
                                      hasMore: Bool? = nil,
                                      totalPages: Int? = nil) -> Bool {
        machine.applySuccess(token,
                             itemCount: itemCount,
                             hasMore: hasMore,
                             totalPages: totalPages)
    }

    @discardableResult
    public mutating func applyFailure(_ token: PTPaginationRequestToken) -> Bool {
        machine.applyFailure(token)
    }

    @discardableResult
    public mutating func cancel(_ token: PTPaginationRequestToken) -> Bool {
        machine.cancel(token)
    }

    public mutating func invalidate() {
        machine.invalidate()
    }
}
