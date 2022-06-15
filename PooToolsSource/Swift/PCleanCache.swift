//
//  PCleanCache.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SDWebImage

@objcMembers
public class PCleanCache: NSObject {
    static let fileManager = FileManager.default
    static let cachePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last
    
    class public func getCacheSize()->String
    {
        #if DEBUG
        var isDirectory:ObjCBool = false
        let isExist = PCleanCache.fileManager.fileExists(atPath: PCleanCache.cachePath!, isDirectory: &isDirectory)
        if !isExist || !isDirectory.boolValue
        {
            let exception = NSException.init(name: NSExceptionName(rawValue: "文件错误"), reason: "请检查你的文件路径!", userInfo: nil)
            exception.raise()
        }
        #endif
        
        let subpathArray = PCleanCache.fileManager.subpaths(atPath: PCleanCache.cachePath!)
        var filePath = ""
        var totalSize : Float = 0
        
        for subpath in subpathArray!
        {
            filePath = PCleanCache.cachePath!.appendingPathComponent(subpath)
            var isDirectory:ObjCBool = false
            let isExist = PCleanCache.fileManager.fileExists(atPath: PCleanCache.cachePath!, isDirectory: &isDirectory)
            if !isExist || isDirectory.boolValue || filePath.contains(".DS")
            {
                continue
            }
            
            do {
                let fileAttributes = try PCleanCache.fileManager.attributesOfItem(atPath: filePath)
                let fileSize = fileAttributes[FileAttributeKey.size]
                totalSize += fileSize as! Float

            } catch {
                print("\(error)")
            }
        }
        totalSize += Float(SDImageCache.shared.totalDiskSize())
        
        var totalSizeString = ""
        
        if totalSize > (1000 * 1000)
        {
            totalSizeString = String.init(format: "%.1fM", totalSize/1000/1000)
        }
        else if totalSize > 1000
        {
            totalSizeString = String.init(format: "%.1fKB", totalSize/1000)
        }
        else
        {
            totalSizeString = String.init(format: "%.1fB", totalSize)
        }
        return totalSizeString
    }
    
    class public func clearCaches()->Bool
    {
        var filePath = ""
        var flag = false

        do
        {
            let subpathArray = try PCleanCache.fileManager.contentsOfDirectory(atPath: PCleanCache.cachePath!)
            if subpathArray.count == 0
            {
                return false
            }
            
            for subpath in subpathArray
            {
                filePath = PCleanCache.cachePath!.appendingPathComponent(subpath)
                if PCleanCache.fileManager.fileExists(atPath: PCleanCache.cachePath!)
                {
                    do{
                        try PCleanCache.fileManager.removeItem(atPath: filePath)
                        flag = true
                    }
                    catch
                    {
                        print("\(error)")
                    }
                }
            }
            
            SDImageCache.shared.clearDisk {
                flag = true
            }
        }   catch {
            print("\(error)")
        }
        
        if !flag
        {
            print("提示:您已经清理了所有可以访问的文件,不可访问的文件无法删除")
        }
        return flag
    }
    
    class public func fileSizeAtPath(path:String)->Float
    {
        if PCleanCache.fileManager.fileExists(atPath: path)
        {
            do {
                let fileAttributes = try PCleanCache.fileManager.attributesOfItem(atPath: path)
                return fileAttributes[FileAttributeKey.size] as! Float
            } catch {
                print("\(error)")
                return 0
            }
        }
        return 0
    }
    
    class public func folderSizeAtPath(path:String)->Float
    {
        if !PCleanCache.fileManager.fileExists(atPath: path)
        {
           return 0
        }
        
        let childFilesEnumerator = PCleanCache.fileManager.subpaths(atPath: path)
        var fileName = ""
        var folderSize = 0
        childFilesEnumerator?.enumerated().forEach({ (index,value) in
            fileName = value
            if !(fileName).stringIsEmpty()
            {
                let fileAbsolutePath = path.appendingPathComponent(fileName)
                folderSize += Int(PCleanCache.fileSizeAtPath(path: fileAbsolutePath))
            }
        })
        return Float(folderSize/(1024*1024))
    }
    
    class public func cleanDocumentAtPath(path:String)->Bool
    {
        let enumerator = PCleanCache.fileManager.enumerator(atPath: path)
        enumerator?.enumerated().forEach({ index,value in
            do {
                try PCleanCache.fileManager.removeItem(atPath: path.appendingPathComponent(value as! String))
            } catch {
                print("\(error)")
            }
        })
        
        if PCleanCache.folderSizeAtPath(path: path) > 0
        {
            return false
        }
        else
        {
            return true
        }
    }
}
