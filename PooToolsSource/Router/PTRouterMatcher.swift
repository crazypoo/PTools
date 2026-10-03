//
//  PTRouterMatcher.swift
//  PooTools
//
//  English: Keep route pattern filtering and matching independent from navigation side effects.
//  Español: Mantiene el filtrado y la coincidencia de patrones separados de los efectos de navegación.
//  中文：将路由模式筛选和匹配从导航副作用中独立出来。
//

import Foundation

struct PTRouterMatchResult {
    let pattern: PTRouterPattern?
    let parameters: [String: Sendable]
    let isWebURL: Bool
}

enum PTRouterMatcher {
    static func match(urlString: String,
                      request: PTRouterRequest,
                      patterns: [PTRouterPattern],
                      webPath: String?,
                      isWebURL: Bool) -> PTRouterMatchResult {
        let candidates: [PTRouterPattern]
        if isWebURL {
            candidates = patterns.filter { $0.patternString == webPath }
        } else {
            candidates = patterns.filter { $0.patternString.hasPrefix("\(request.sheme)://") }
        }

        guard !isWebURL else {
            return PTRouterMatchResult(pattern: candidates.first,
                                       parameters: [:],
                                       isWebURL: true)
        }

        for pattern in candidates {
            let result = pattern.matchResult(for: urlString)
            if result.matched {
                return PTRouterMatchResult(pattern: pattern,
                                           parameters: result.queries,
                                           isWebURL: false)
            }
        }
        return PTRouterMatchResult(pattern: nil, parameters: [:], isWebURL: false)
    }
}
