//
//  PTSearchPagination.swift
//  PooTools
//
// English: Pagination state is small, explicit, and guarded against duplicate loads.
// Español: El estado de paginación es pequeño, explícito y protegido contra cargas duplicadas.
// 中文：分页状态保持轻量、明确，并防止重复加载。
//

import Foundation

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
