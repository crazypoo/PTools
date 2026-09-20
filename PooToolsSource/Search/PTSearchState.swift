//
//  PTSearchState.swift
//  PooTools
//
// English: UI state is MainActor-bound because it contains UIKit-facing errors and rendering decisions.
// Español: El estado de UI está ligado a MainActor porque contiene errores y decisiones de renderizado de UIKit.
// 中文：UI 状态绑定 MainActor，因为它包含 UIKit 相关错误和渲染决策。
//

import Foundation

@MainActor
public enum PTSearchState {
    case idle
    case focused
    case history
    case typing(String)
    case suggestions(String)
    case searching(String)
    case refreshing(String)
    case results(String, count: Int)
    case loadingMore(String)
    case empty(String)
    case failure(String, Error)

    public var keyword: String? {
        switch self {
        case .idle, .focused, .history:
            return nil
        case .typing(let keyword), .suggestions(let keyword), .searching(let keyword),
             .refreshing(let keyword), .results(let keyword, _), .loadingMore(let keyword),
             .empty(let keyword), .failure(let keyword, _):
            return keyword
        }
    }

    public var isLoading: Bool {
        switch self {
        case .searching, .refreshing, .loadingMore:
            return true
        default:
            return false
        }
    }
}

public enum PTSearchError: Error, LocalizedError, Sendable {
    case providerUnavailable
    case invalidKeyword
    case paginationUnavailable

    public var errorDescription: String? {
        switch self {
        case .providerUnavailable:
            return "No search provider is configured"
        case .invalidKeyword:
            return "The search keyword is invalid"
        case .paginationUnavailable:
            return "Pagination is unavailable"
        }
    }
}
