//
//  PTFileBrowser.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers // iOS 14+ 的文件类型检测框架

public class PTFileBrowser: NSObject {
    
    public static let shared = PTFileBrowser()
    public var rootDirectoryPath = FileManager.pt.getFileDirectory(type: .Directory)
    
    lazy var navigationController: PTBaseNavControl = {
        let rootViewController = PTFileBrowserViewController()
        let navigation = PTBaseNavControl(rootViewController: rootViewController)
        // 注意：在 iOS 15+ 中，barTintColor 的设置可能需要通过 UINavigationBarAppearance 来处理
        navigation.navigationBar.barTintColor = .black
        return navigation
    }()
}

public extension PTFileBrowser {
    
    /// 启动并展示文件浏览器
    func start() {
        // 增加 [weak self] 确保闭包内的内存安全
        navigationController.dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            PTUtils.getCurrentVC()?.pt_present(self.navigationController, animated: true, completion: nil)
        }
    }

    /// 解析 URL 获取对应的 PTFileType
    func getFileType(filePath: URL?) -> PTFileType {
        guard let filePath = filePath else { return .unknown }
        
        // 1. 优先判断系统隐藏文件 (以 . 开头)
        if filePath.lastPathComponent.hasPrefix(".") {
            return .system
        }
        
        // 2. 对于某些特殊的后缀，可以直接提前拦截 (例如 .db)
        if filePath.pathExtension.lowercased() == "db" {
            return .db
        }
        
        // 3. 获取 UTType，如果获取失败直接返回 unknown
        guard let utType = getFileUTType(filePath: filePath) else {
            return .unknown
        }
        
        // 4. 扁平化类型判断，代码更清晰
        if utType.conforms(to: .directory) || utType.conforms(to: .folder) { return .folder }
        if utType.conforms(to: .image) { return .image }
        if utType.conforms(to: .movie) || utType.conforms(to: .video) { return .video }
        if utType.conforms(to: .audio) { return .audio }
        if utType.conforms(to: .archive) || utType.conforms(to: .zip) { return .zip } // 添加了对 .archive 的泛型支持
        if utType.conforms(to: .pdf) { return .pdf }
        if utType.conforms(to: .html) || utType.conforms(to: .url) || utType.conforms(to: .fileURL) { return .web }
        if utType.conforms(to: .application) || utType.conforms(to: .sourceCode) { return .application }
        if utType.conforms(to: .plainText) || utType.conforms(to: .rtf) { return .txt }
        
        // 5. 对办公软件和日志进行标识符(Identifier)匹配
        let identifier = utType.identifier.lowercased()
        
        if identifier.contains("wordprocessingml") || identifier.contains("word.doc") {
            return .word
        }
        if identifier.contains("presentationml") || identifier.contains("powerpoint.ppt") {
            return .ppt
        }
        if identifier.contains("spreadsheetml") || identifier.contains("excel.xls") {
            return .excel
        }
        if identifier == "com.apple.log" || filePath.pathExtension.lowercased() == "log" {
            return .log
        }
        
        return .unknown
    }
}

// MARK: - 私有辅助方法
private extension PTFileBrowser {
    
    /// 获取文件的 UTType (统一类型标识符)
    func getFileUTType(filePath: URL) -> UTType? {
        // 1. 【性能优化】使用 URL 的 resourceValues 检查是否为目录，比 FileManager 更现代、更高效
        if let isDirectory = try? filePath.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, isDirectory {
            return .directory // 返回标准的目录类型
        }
        
        // 2. 根据扩展名推断 UTType
        return UTType(filenameExtension: filePath.pathExtension)
    }
}
