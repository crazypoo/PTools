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
    //MARK: 獲取緩存容量
    ///獲取緩存容量
    /// - Returns: 容量字符串
    class public func getCacheSize()->String {
#if POOTOOLS_DEBUG
        var isDirectory:ObjCBool = false
        let isExist = FileManager.pt.fileManager.fileExists(atPath: FileManager.pt.CachesDirectory(), isDirectory: &isDirectory)
        if !isExist || !isDirectory.boolValue {
            let exception = NSException.init(name: NSExceptionName(rawValue: "PT Clean cache title".localized()), reason: "PT Clean cache check".localized(), userInfo: nil)
            exception.raise()
        }
#endif
        let subpathArray = FileManager.pt.fileManager.subpaths(atPath: FileManager.pt.CachesDirectory())
        var filePath = ""
        var totalSize : Float = 0
        
        for subpath in subpathArray! {
            filePath = FileManager.pt.CachesDirectory().appendingPathComponent(subpath)
            var isDirectory:ObjCBool = false
            let isExist = FileManager.pt.fileManager.fileExists(atPath: FileManager.pt.CachesDirectory(), isDirectory: &isDirectory)
            if !isExist || isDirectory.boolValue || filePath.contains(".DS") {
                continue
            }
            
            do {
                let fileAttributes = try FileManager.pt.fileManager.attributesOfItem(atPath: filePath)
                let fileSize = fileAttributes[FileAttributeKey.size]
                totalSize += fileSize as! Float
            } catch {
                PTNSLogConsole(error.localizedDescription,levelType: .Error,loggerType: .CleanCache)
            }
        }
#if canImport(SDWebImage)
        totalSize += Float(SDImageCache.shared.totalDiskSize())
#endif
        ImageCache.default.calculateDiskStorageSize(completion: { result in
            switch result {
            case .success(let success):
                totalSize += Float(success)
            case .failure(let failure):
                PTNSLogConsole("Kingfisher:\(failure)",levelType: .Error,loggerType: .CleanCache)
            }
        })

        var totalSizeString = ""
        
        if totalSize > 1_000_000 {
            totalSizeString = String.init(format: "%.2fM", totalSize / 1_000_000)
        } else if totalSize > 1_000_000 {
            totalSizeString = String.init(format: "%.2fKB", totalSize / 1000)
        } else {
            totalSizeString = String.init(format: "%.2fB", totalSize)
        }
        return totalSizeString
    }
    
    //MARK: 清理緩存
    ///清理緩存
    /// - Returns: 是否清理完成
    class public func clearCaches()->Bool {
        var filePath = ""
        var flag = false
        
        do {
            let subpathArray = try FileManager.pt.fileManager.contentsOfDirectory(atPath: FileManager.pt.CachesDirectory())
            if subpathArray.count == 0 {
                return false
            }
            
            for subpath in subpathArray {
                filePath = FileManager.pt.CachesDirectory().appendingPathComponent(subpath)
                if FileManager.pt.judgeFileOrFolderExists(filePath: FileManager.pt.CachesDirectory()) {
                    let removeResult = FileManager.pt.removefile(filePath: filePath)
                    if removeResult.isSuccess {
                        flag = true
                    } else {
                        PTNSLogConsole(removeResult.error,levelType: .Error,loggerType: .CleanCache)
                    }
                }
            }
            
#if canImport(SDWebImage)
            SDImageCache.shared.clearDisk {
                flag = true
            }
#endif
            PTGCDManager.gcdMain {
                ImageCache.default.clearDiskCache {
                    flag = true
                }
            }
            
        } catch {
            PTNSLogConsole(error.localizedDescription,levelType: .Error,loggerType: .CleanCache)
        }
        
        if !flag {
            PTNSLogConsole("提示:您已经清理了所有可以访问的文件,不可访问的文件无法删除",levelType: .Info,loggerType: .CleanCache)
        }
        return flag
    }
    
    //MARK: 獲取某個文件的大小
    ///獲取某個文件的大小
    /// - Parameters:
    ///   - path: 文件路徑
    /// - Returns: 文件Size大小
    class public func fileSizeAtPath(path:String) -> Float {
        guard FileManager.pt.judgeFileOrFolderExists(filePath: path) else {
            return 0
        }
        
        if let fileSize = try? FileManager.pt.fileManager.attributesOfItem(atPath: path)[.size] as? Float {
            return fileSize
        } else {
            PTNSLogConsole("Failed to get file size at path: \(path)", levelType: .Error, loggerType: .CleanCache)
            return 0
        }
    }
    
    //MARK: 獲取某個文件夾的大小
    ///獲取某個文件夾的大小
    /// - Parameters:
    ///   - path: 文件夾路徑
    /// - Returns: 文件夾Size大小
    class public func folderSizeAtPath(path:String) -> Float {
        guard FileManager.pt.judgeFileOrFolderExists(filePath: path) else {
            return 0
        }
        
        var folderSize: Float = 0
        
        if let subpaths = FileManager.pt.fileManager.subpaths(atPath: path) {
            for subpath in subpaths {
                let fileAbsolutePath = path.appendingPathComponent(subpath)
                folderSize += fileSizeAtPath(path: fileAbsolutePath)
            }
        }
        
        return folderSize / (1024 * 1024)
    }
    
    //MARK: 清理某個文件夾
    ///清理某個文件夾
    /// - Parameters:
    ///   - path: 文件夾路徑
    /// - Returns: 是否完成
    class public func cleanDocumentAtPath(path:String)->Bool {
        guard let enumerator = FileManager.pt.fileManager.enumerator(atPath: path) else {
            return false
        }
        
        for case let filePath as String in enumerator {
            let fullPath = path.appendingPathComponent(filePath)
            let removeResult = FileManager.pt.removefolder(folderPath: fullPath)
            if !removeResult.isSuccess {
                PTNSLogConsole(removeResult.error, levelType: .Error, loggerType: .CleanCache)
            }
        }
        
        return folderSizeAtPath(path: path) == 0
    }
}
