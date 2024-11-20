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
    
    // MARK: 获取缓存容量
    /// 获取缓存容量
    /// - Returns: 容量字符串
    @MainActor
    public class func getCacheSize() async -> String {
        var totalSize: Float = 0

        // 计算本地文件缓存大小
        totalSize += calculateLocalCacheSize()
        
        // 计算 SDWebImage 缓存大小
        #if canImport(SDWebImage)
        totalSize += Float(SDImageCache.shared.totalDiskSize())
        #endif
        
        // 计算 Kingfisher 缓存大小
        do {
            let size = try await ImageCache.default.diskStorageSize
            totalSize += Float(size)
        } catch {
            PTNSLogConsole("Kingfisher: \(error)", levelType: .Error, loggerType: .CleanCache)
        }
        
        return formatSize(totalSize)
    }
    
    // MARK: 清理缓存
    /// 清理缓存
    /// - Returns: 是否清理完成
    @MainActor
    public class func clearCaches() async -> Bool {
        var flag = false

        // 清理本地文件缓存
        flag = clearLocalCaches()
        
        // 清理 SDWebImage 缓存
        #if canImport(SDWebImage)
        await withCheckedContinuation { continuation in
            SDImageCache.shared.clearDisk {
                flag = true
                continuation.resume()
            }
        }
        #endif
        
        // 清理 Kingfisher 缓存
        do {
            try await ImageCache.default.clearDiskCache()
            flag = true
        } catch {
            PTNSLogConsole("Kingfisher: \(error)", levelType: .Error, loggerType: .CleanCache)
        }
        
        if !flag {
            PTNSLogConsole("提示:您已经清理了所有可以访问的文件,不可访问的文件无法删除", levelType: .Info, loggerType: .CleanCache)
        }
        
        return flag
    }
    
    // MARK: 私有方法
    
    /// 计算本地缓存大小
    private class func calculateLocalCacheSize() -> Float {
        var totalSize: Float = 0
        
        guard let subpathArray = FileManager.pt.fileManager.subpaths(atPath: FileManager.pt.CachesDirectory()) else {
            return totalSize
        }
        
        for subpath in subpathArray {
            let filePath = FileManager.pt.CachesDirectory().appendingPathComponent(subpath)
            var isDirectory: ObjCBool = false
            let isExist = FileManager.pt.fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory)
            
            if !isExist || isDirectory.boolValue || filePath.contains(".DS") {
                continue
            }
            
            do {
                let fileAttributes = try FileManager.pt.fileManager.attributesOfItem(atPath: filePath)
                if let fileSize = fileAttributes[.size] as? Float {
                    totalSize += fileSize
                }
            } catch {
                PTNSLogConsole(error.localizedDescription, levelType: .Error, loggerType: .CleanCache)
            }
        }
        
        return totalSize
    }
    
    /// 清理本地缓存
    private class func clearLocalCaches() -> Bool {
        var flag = false
        
        do {
            let subpathArray = try FileManager.pt.fileManager.contentsOfDirectory(atPath: FileManager.pt.CachesDirectory())
            if subpathArray.isEmpty {
                return false
            }
            
            for subpath in subpathArray {
                let filePath = FileManager.pt.CachesDirectory().appendingPathComponent(subpath)
                if FileManager.pt.judgeFileOrFolderExists(filePath: filePath) {
                    let removeResult = FileManager.pt.removefile(filePath: filePath)
                    if removeResult.isSuccess {
                        flag = true
                    } else {
                        PTNSLogConsole(removeResult.error, levelType: .Error, loggerType: .CleanCache)
                    }
                }
            }
        } catch {
            PTNSLogConsole(error.localizedDescription, levelType: .Error, loggerType: .CleanCache)
        }
        
        return flag
    }
    
    /// 格式化大小字符串
    private class func formatSize(_ size: Float) -> String {
        if size > 1_000_000 {
            return String(format: "%.2fM", size / 1_000_000)
        } else if size > 1_000 {
            return String(format: "%.2fKB", size / 1_000)
        } else {
            return String(format: "%.2fB", size)
        }
    }
}
