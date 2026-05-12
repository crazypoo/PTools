//
//  PTCacheStoragePolicy.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum PTCacheStoragePolicy {
    
    /// 根据原始请求与服务器响应，决定系统层面的缓存存储策略
    /// - Parameters:
    ///   - request: 触发响应的 URLRequest
    ///   - response: 服务器返回的 HTTPURLResponse
    /// - Returns: 合适的 URLCache.StoragePolicy
    static func cacheStoragePolicy(for request: URLRequest, and response: HTTPURLResponse) -> URLCache.StoragePolicy {
        // 🌟 1. 业务最高优先级穿透：检查业务层是否强行注入了自定义缓存策略
        if let customPolicyRaw = request.allHTTPHeaderFields?["cachePolicy"],
           let customPolicy = PTNetworkCachePolicy(rawValue: customPolicyRaw) {
            switch customPolicy {
            case .none, .networkOnly:
                return .notAllowed
            case .cacheOnly, .cacheElseNetwork, .networkElseCache:
                // 只要业务层要求缓存，无视远端服务器的限制强行允许落盘
                return (request.url?.scheme?.lowercased() == "https") ? .allowedInMemoryOnly : .allowed
            }
        }

        // 2. 如果业务层未显式干预，则回退到标准的 HTTP 协议判定逻辑
        var isCacheable = false
        switch response.statusCode {
        case 200, 203, 206, 301, 304, 404, 410: isCacheable = true
        default: isCacheable = false
        }

        if isCacheable {
            if let respCC = (response.allHeaderFields["Cache-Control"] as? String)?.lowercased(), respCC.contains("no-store") {
                isCacheable = false
            }
        }

        if isCacheable {
            if let reqCC = request.allHTTPHeaderFields?["Cache-Control"]?.lowercased(), (reqCC.contains("no-store") || reqCC.contains("no-cache")) {
                isCacheable = false
            }
        }

        guard isCacheable else { return .notAllowed }
        return (request.url?.scheme?.lowercased() == "https") ? .allowedInMemoryOnly : .allowed
    }
}
