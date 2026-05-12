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
        var isCacheable = false

        // 1. 基于 HTTP 状态码决定基础可缓存性
        switch response.statusCode {
        case 200, 203, 206, 301, 304, 404, 410:
            isCacheable = true
        default:
            isCacheable = false
        }

        // 2. 检查响应头 (Response Headers) 中的 Cache-Control 指令
        if isCacheable {
            if let responseCacheControl = (response.allHeaderFields["Cache-Control"] as? String)?.lowercased(),
               responseCacheControl.contains("no-store") {
                isCacheable = false
            }
        }

        // 3. 检查请求头 (Request Headers) 中的 Cache-Control 指令
        if isCacheable {
            if let requestCacheControl = request.allHTTPHeaderFields?["Cache-Control"]?.lowercased(),
               (requestCacheControl.contains("no-store") || requestCacheControl.contains("no-cache")) {
                isCacheable = false
            }
        }

        // 4. 决断最终的存储等级
        guard isCacheable else {
            return .notAllowed
        }

        // 现代 iOS 文件系统已高度加密，但为了严格控制敏感通信，HTTPS 默认限定在内存层级
        if request.url?.scheme?.lowercased() == "https" {
            return .allowedInMemoryOnly
        } else {
            return .allowed
        }
    }
}
