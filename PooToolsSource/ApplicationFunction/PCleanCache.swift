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
    class public func getCacheSize() -> String {
        var totalSize: Float = 0
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "com.pt.totalsize.sync")

        // 计算本地文件缓存大小
        totalSize += calculateLocalCacheSize()
        
        // 计算 SDWebImage 缓存大小
        #if canImport(SDWebImage)
        dispatchGroup.enter()
        queue.sync {
            totalSize += Float(SDImageCache.shared.totalDiskSize())
        }
        dispatchGroup.leave()
        #endif
        
        // 计算 Kingfisher 缓存大小
        dispatchGroup.enter()
        ImageCache.default.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                queue.sync {
                    totalSize += Float(size)
                }
            case .failure(let error):
                PTNSLogConsole("Kingfisher: \(error)", levelType: .Error, loggerType: .CleanCache)
            }
            dispatchGroup.leave()
        }
        
        // 等待所有异步任务完成
        dispatchGroup.wait()
        
        return formatSize(totalSize)
    }
    
    // MARK: 清理缓存
    /// 清理缓存
    /// - Returns: 是否清理完成
    class public func clearCaches() -> Bool {
        var flag = false
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "com.pt.flag.sync")

        // 清理本地文件缓存
        flag = clearLocalCaches()
        
        // 清理 SDWebImage 缓存
        #if canImport(SDWebImage)
        dispatchGroup.enter()
        SDImageCache.shared.clearDisk {
            flag = true
            dispatchGroup.leave()
        }
        #endif
        
        // 清理 Kingfisher 缓存
        dispatchGroup.enter()
        ImageCache.default.clearDiskCache {
            queue.sync {
                flag = true
            }
            dispatchGroup.leave()
        }
        
        // 等待所有清理任务完成
        dispatchGroup.wait()
        
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
