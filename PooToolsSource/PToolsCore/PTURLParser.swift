//
//  PTURLParser.swift
//  PToolsCore
//
//  Foundation-only URL query parsing.
//  Análisis de consultas URL basado únicamente en Foundation.
//  仅使用 Foundation 的 URL 查询解析。
//

import Foundation

// English: Keep URL parsing independent from UIKit and feature modules.
// Español: Mantiene el análisis URL independiente de UIKit y de los módulos de funciones.
// 中文：让 URL 解析独立于 UIKit 和具体功能模块。
public enum PTURLParser {
    public static func queryParameters(from url: URL,
                                       allowSchemeFallback: Bool = true) -> [String: String]? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems {
            let parameters = queryItems.reduce(into: [String: String]()) { result, item in
                guard let value = item.value else { return }
                result[item.name] = value
            }
            if !parameters.isEmpty || !allowSchemeFallback {
                return parameters.isEmpty ? nil : parameters
            }
        }

        guard allowSchemeFallback,
              let separator = url.absoluteString.range(of: "://") else {
            return nil
        }

        let queryPart = url.absoluteString[separator.upperBound...]
        var parameters: [String: String] = [:]
        for pair in queryPart.split(separator: "&") {
            guard let equalsIndex = pair.firstIndex(of: "=") else { continue }
            let rawKey = String(pair[..<equalsIndex])
            let rawValue = String(pair[pair.index(after: equalsIndex)...])
            guard !rawKey.isEmpty else { continue }
            let key = rawKey.removingPercentEncoding ?? rawKey
            let value = rawValue.removingPercentEncoding ?? rawValue
            parameters[key] = value
        }
        return parameters.isEmpty ? nil : parameters
    }
}

public extension URL {
    // English: Expose the canonical parser without introducing a UIKit dependency.
    // Español: Expone el analizador canónico sin introducir una dependencia de UIKit.
    // 中文：暴露统一解析器，同时不引入 UIKit 依赖。
    var pt_queryParameters: [String: String]? {
        PTURLParser.queryParameters(from: self)
    }
}
