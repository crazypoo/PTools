//
//  PTiCloudFileManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import Foundation

/// iCloud 文件同步管理器
class PTiCloudFileManager {
    
    // 单例模式，方便在全局调用
    static let shared = PTiCloudFileManager()
    private let fileManager = FileManager.default
    
    // 私有初始化方法
    private init() {}
    
    /// 检查当前设备 iCloud 是否可用
    /// - Returns: 布尔值，true 表示可用，false 表示未登录或不可用
    func isICloudAvailable() -> Bool {
        return fileManager.ubiquityIdentityToken != nil
    }
    
    /// 获取应用在 iCloud 中的云端 Documents 目录 URL
    /// - Returns: iCloud 目录的 URL，如果不可用则返回 nil
    var iCloudDocumentsURL: URL? {
        // 传入 nil 默认使用配置的第一个 iCloud Container
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            PTNSLogConsole("错误：无法获取 iCloud 容器路径。请检查 Xcode Capabilities 配置。")
            return nil
        }
        
        // 通常我们将文件存放在容器内的 Documents 文件夹下
        let documentsURL = containerURL.appendingPathComponent("Documents")
        
        // 如果云端 Documents 目录不存在，则创建它
        if !fileManager.fileExists(atPath: documentsURL.path) {
            do {
                try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                PTNSLogConsole("创建 iCloud Documents 目录失败: \(error.localizedDescription)")
                return nil
            }
        }
        return documentsURL
    }
    
    /// 将本地文件上传/保存到 iCloud
    /// - Parameters:
    ///   - data: 要保存的文件数据
    ///   - fileName: 文件名（包含后缀，例如 "myDatabase.sqlite" 或 "data.json"）
    func saveFileToICloud(data: Data, fileName: String) {
        guard let cloudURL = iCloudDocumentsURL else {
            PTNSLogConsole("无法保存：iCloud 未准备好。")
            return
        }
        
        let fileURL = cloudURL.appendingPathComponent(fileName)
        
        do {
            // 将数据写入 iCloud 路径
            try data.write(to: fileURL, options: .atomic)
            PTNSLogConsole("成功：文件 \(fileName) 已保存到 iCloud！")
        } catch {
            PTNSLogConsole("保存到 iCloud 失败: \(error.localizedDescription)")
        }
    }
    
    /// 从 iCloud 读取文件数据
    /// - Parameter fileName: 要读取的文件名
    /// - Returns: 文件的 Data 数据，如果不存在则返回 nil
    func readFileFromICloud(fileName: String) -> Data? {
        guard let cloudURL = iCloudDocumentsURL else {
            PTNSLogConsole("无法读取：iCloud 未准备好。")
            return nil
        }
        
        let fileURL = cloudURL.appendingPathComponent(fileName)
        
        // 检查云端文件是否存在
        guard fileManager.fileExists(atPath: fileURL.path) else {
            PTNSLogConsole("文件不存在：\(fileName)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            PTNSLogConsole("成功：已从 iCloud 读取文件 \(fileName)")
            return data
        } catch {
            PTNSLogConsole("读取 iCloud 文件失败: \(error.localizedDescription)")
            return nil
        }
    }
}

extension PTiCloudFileManager {
    
    /// 获取本地沙盒的 Documents 目录路径
    private var localDocumentsURL: URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// 将本地的 FMDB 数据库备份到 iCloud
    /// - Parameter dbName: 数据库文件名，例如 "myDatabase.sqlite"
    func backupDatabaseToICloud(dbName: String) {
        guard let cloudURL = iCloudDocumentsURL else {
            PTNSLogConsole("无法备份：iCloud 未准备好。")
            return
        }
        
        let localDBURL = localDocumentsURL.appendingPathComponent(dbName)
        let cloudDBURL = cloudURL.appendingPathComponent(dbName)
        
        // 确保本地存在该数据库
        guard fileManager.fileExists(atPath: localDBURL.path) else {
            PTNSLogConsole("备份失败：本地找不到数据库文件 \(dbName)")
            return
        }
        
        do {
            // 如果 iCloud 中已经有旧的备份，先删除它，否则 copyItem 会报错
            if fileManager.fileExists(atPath: cloudDBURL.path) {
                try fileManager.removeItem(at: cloudDBURL)
            }
            
            // 将本地文件复制到 iCloud 目录
            try fileManager.copyItem(at: localDBURL, to: cloudDBURL)
            PTNSLogConsole("✅ 成功：数据库已安全备份到 iCloud！")
            
        } catch {
            PTNSLogConsole("❌ 备份到 iCloud 失败: \(error.localizedDescription)")
        }
    }
    
    /// 将 iCloud 中的数据库恢复到本地
    /// - Parameter dbName: 数据库文件名，例如 "myDatabase.sqlite"
    func restoreDatabaseFromICloud(dbName: String) -> Bool {
        guard let cloudURL = iCloudDocumentsURL else {
            PTNSLogConsole("无法恢复：iCloud 未准备好。")
            return false
        }
        
        let localDBURL = localDocumentsURL.appendingPathComponent(dbName)
        let cloudDBURL = cloudURL.appendingPathComponent(dbName)
        
        // 确保云端存在备份文件
        guard fileManager.fileExists(atPath: cloudDBURL.path) else {
            PTNSLogConsole("恢复失败：iCloud 中找不到备份文件 \(dbName)")
            return false
        }
        
        do {
            // 如果本地已经有数据库，先删除（注意：这会覆盖本地现有数据！）
            if fileManager.fileExists(atPath: localDBURL.path) {
                try fileManager.removeItem(at: localDBURL)
            }
            
            // 将 iCloud 文件复制到本地
            try fileManager.copyItem(at: cloudDBURL, to: localDBURL)
            PTNSLogConsole("✅ 成功：数据库已从 iCloud 恢复到本地！")
            return true
            
        } catch {
            PTNSLogConsole("❌ 恢复失败: \(error.localizedDescription)")
            return false
        }
    }
}
