//
//  PTUrlChange.swift
//  Diou
//
//  Created by ken lam on 2021/10/16.
//  Copyright © 2021 DO. All rights reserved.
//

import Foundation

// English: Keep URL query parsing in the Foundation-only core so UI modules do not own this utility.
// Español: Mantiene el análisis de consultas URL en el núcleo basado solo en Foundation para que los módulos UI no sean propietarios de esta utilidad.
// 中文：将 URL 查询解析放在仅依赖 Foundation 的核心中，避免由 UI 模块重复维护。
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
    // English: Expose the canonical query parser without changing the legacy URL category API.
    // Español: Expone el analizador canónico sin cambiar la API heredada de la categoría URL.
    // 中文：暴露统一查询解析器，同时不改变旧 URL 分类 API。
    var pt_queryParameters: [String: String]? {
        PTURLParser.queryParameters(from: self)
    }
}

@objcMembers
public class PTUrlChange: NSObject {

    public class func getRange(text: String, findText: String) -> [Int] {
        // 如果 text 是空字符串，直接返回空数组
        if text.stringIsEmpty() {
            return []
        }

        var arrayRanges: [Int] = []
        var searchRange = text.startIndex..<text.endIndex
        
        while let range = text.range(of: findText, options: .caseInsensitive, range: searchRange) {
            // 获取匹配文本的起始位置
            let location = text.distance(from: text.startIndex, to: range.lowerBound)
            arrayRanges.append(location)

            // 更新搜索范围，继续查找后续的匹配项
            searchRange = range.upperBound..<text.endIndex
        }

        return arrayRanges
    }}
