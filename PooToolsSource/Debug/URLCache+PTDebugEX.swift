//
//  URLCache+PTDebugEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension URLCache {
    static let customHttp = URLCache(
        memoryCapacity: 32 * 1024 * 1024,
        diskCapacity: 1024 * 1024 * 1024,
        diskPath: PTApplicationDirectories.shared.support.appendingPathComponent("Caches").path
    )
    static let cachedExtensions = ["swf", "flv", "png", "jpg", "jpeg", "mp3"]

    func storeIfNeeded(for task: URLSessionTask, data: Data) {
        if let request = task.originalRequest,
           let response = task.response as? HTTPURLResponse,
           let ext = request.url?.pathExtension,
           URLCache.cachedExtensions.contains(ext),
           let expires = response.expires() {
            let cache = CachedURLResponse(
                response: response,
                data: data,
                userInfo: ["Expires": expires],
                storagePolicy: .allowed
            )
            storeCachedResponse(cache, for: request)
        }
    }

    func validCache(for request: URLRequest) -> CachedURLResponse? {
        if let cache = cachedResponse(for: request),
           let info = cache.userInfo,
           let expires = info["Expires"] as? Date,
           Date().compare(expires) == .orderedAscending {
            return cache
        }

        return nil
    }
}

