//
//  URLCache+PTDebugEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension URLCache {
    // 采用懒加载单例模式保障全局唯一性
    static let customHttp: URLCache = {
        let memoryCapacity = 32 * 1024 * 1024   // 32 MB
        let diskCapacity = 1024 * 1024 * 1024 // 1 GB
        
        // 确保 Caches 路径存在，避免底层存取失败
        let cacheDirectory = PTApplicationDirectories.shared.support.appendingPathComponent("Caches")
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        return URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: cacheDirectory.path
        )
    }()
    
    // 静态资源白名单
    private static let cachedExtensions = ["swf", "flv", "png", "jpg", "jpeg", "mp3"]
    
    // 引入内部串行同步队列，保障多线程环境下对数据库/磁盘写入的绝对安全
    private static let cacheIOQueue = DispatchQueue(label: "com.custom.http.urlCacheIOQueue")
    
    /// 按需将合规的静态资源响应存入持久化磁盘（线程安全）
    func storeIfNeeded(for task: URLSessionTask, data: Data) {
        // 在调用线程先完成基础数据的快速校验
        guard let request = task.originalRequest,
              let response = task.response as? HTTPURLResponse,
              let ext = request.url?.pathExtension.lowercased(),
              URLCache.cachedExtensions.contains(ext),
              // 假设 extension HTTPURLResponse 中实现了 expires() 返回 Date?
              let expires = response.expires() else {
            return
        }
        
        // 组装缓存对象
        let cachedResponse = CachedURLResponse(
            response: response,
            data: data,
            userInfo: ["Expires": expires],
            storagePolicy: .allowed
        )
        
        // 派发到专用的串行 I/O 队列中安全落盘，避免底层 SQLite 写入死锁
        URLCache.cacheIOQueue.async {
            self.storeCachedResponse(cachedResponse, for: request)
        }
    }
    
    /// 验证并提取有效的本地缓存（线程安全）
    func validCache(for request: URLRequest) -> CachedURLResponse? {
        // 同步安全读取底层缓存数据
        return URLCache.cacheIOQueue.sync {
            guard let cache = self.cachedResponse(for: request),
                  let info = cache.userInfo,
                  let expires = info["Expires"] as? Date else {
                return nil
            }
            
            // 校验是否在有效期内
            if Date().compare(expires) == .orderedAscending {
                return cache
            } else {
                // 如果已经过期，顺手清理掉本地陈旧缓存释放空间
                self.removeCachedResponse(for: request)
                return nil
            }
        }
    }
}

