//
//  PCleanCache.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
#if canImport(SDWebImage)
import SDWebImage
#endif
import Kingfisher

@objcMembers
public class PCleanCache: NSObject {
    
    // MARK: - 获取缓存容量
    /// 获取缓存容量 (并发计算，不阻塞主线程)
    /// - Returns: 容量字符串 (如 "12.5 MB")
    @MainActor
    public class func getCacheSize() async -> String {
        // 1. 异步并发计算本地缓存
        async let localSizeTask = calculateLocalCacheSize()
        
        // 2. 异步并发获取 SDWebImage 缓存
        #if canImport(SDWebImage)
        async let sdSizeTask = Task.detached(priority: .background) {
            return Int64(SDImageCache.shared.totalDiskSize())
        }.value
        #else
        async let sdSizeTask: Int64 = 0
        #endif
        
        // 3. 异步并发获取 Kingfisher 缓存
        async let kfSizeTask = Task.detached(priority: .background) {
            do {
                return try await Int64(ImageCache.default.diskStorageSize)
            } catch {
                PTNSLogConsole("Kingfisher Size Error: \(error)", levelType: .error, loggerType: .cleanCache)
                return Int64(0)
            }
        }.value
        
        // 同时等待三个结果返回并求和
        let (localSize, sdSize, kfSize) = await (localSizeTask, sdSizeTask, kfSizeTask)
        let totalSizeBytes = localSize + sdSize + kfSize
        
        return formatSize(totalSizeBytes)
    }
    
    // MARK: - 清理缓存
    /// 清理所有缓存 (并发清理)
    /// - Returns: 是否有清理动作发生
    @MainActor
    public class func clearCaches() async -> Bool {
        // 1. 并发清理本地缓存
        async let localFlagTask = clearLocalCaches()
        
        // 2. 并发清理 SDWebImage
        #if canImport(SDWebImage)
        async let sdFlagTask: Bool = await withCheckedContinuation { continuation in
            SDImageCache.shared.clearDisk {
                continuation.resume(returning: true)
            }
        }
        #else
        async let sdFlagTask: Bool = false
        #endif
        
        // 3. 并发清理 Kingfisher
        async let kfFlagTask: Bool = {
            await ImageCache.default.clearDiskCache()
            return true
        }()
        
        // 等待所有清理任务完成
        let (localFlag, sdFlag, kfFlag) = await (localFlagTask, sdFlagTask, kfFlagTask)
        
        // 只要有一个清理成功，就返回 true
        return localFlag || sdFlag || kfFlag
    }
    
    // MARK: - 私有方法
    
    /// 高效计算本地缓存大小 (移至后台线程，适配 Swift 6)
    private class func calculateLocalCacheSize() async -> Int64 {
        // 使用 detached 将重度 I/O 任务剥离出当前 Actor (MainActor)
        return await Task.detached(priority: .background) {
            var totalSize: Int64 = 0
            
            let cachePath = FileManager.pt.CachesDirectory()
            let cacheURL = URL(fileURLWithPath: cachePath)
            
            let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
            
            guard let enumerator = FileManager.default.enumerator(
                at: cacheURL,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
            ) else {
                return 0
            }
            
            // 🌟 修复点：使用 while let 和 nextObject() 替代 for case let
            // 这是 Swift 6 下遍历 DirectoryEnumerator 最安全、最标准的方式
            while let fileURL = enumerator.nextObject() as? URL {
                // 跳过 .DS_Store 等文件
                if fileURL.lastPathComponent.contains(".DS") { continue }
                
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    // 确保是普通文件且有大小
                    if resourceValues.isRegularFile == true, let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                } catch {
                    // 单个文件读取失败不中断整体流程
                    continue
                }
            }
            
            return totalSize
        }.value
    }

    /// 高效清理本地缓存 (移至后台线程)
    private class func clearLocalCaches() async -> Bool {
        return await Task.detached(priority: .userInitiated) {
            var flag = false
            let cachePath = FileManager.pt.CachesDirectory()
            let cacheURL = URL(fileURLWithPath: cachePath)
            
            do {
                // 仅获取第一层目录结构，不深度遍历
                let contents = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
                if contents.isEmpty { return false }
                
                for fileURL in contents {
                    do {
                        try FileManager.default.removeItem(at: fileURL)
                        flag = true
                    } catch {
                        PTNSLogConsole("Remove Error: \(error.localizedDescription)", levelType: .error, loggerType: .cleanCache)
                    }
                }
            } catch {
                PTNSLogConsole("Read Directory Error: \(error.localizedDescription)", levelType: .error, loggerType: .cleanCache)
            }
            return flag
        }.value
    }
    
    /// 使用系统原生格式化器，性能最好且符合国际化标准
    private class func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file // .file 会使用 1000 进制 (Apple 标准), 如果你想用 1024 进制，使用 .memory
        return formatter.string(fromByteCount: size)
    }
}
