//
//  PTFileModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

// MARK: - 文件类型枚举
public enum PTFileType: String {
    case unknown
    case folder         // 文件夹
    case image          // 图片
    case video          // 视频
    case audio          // 音频
    case web            // 链接
    case application    // 应用和执行文件
    case zip            // 压缩包
    case log            // 日志
    case excel          // 表格
    case word           // word文档
    case ppt            // ppt
    case pdf            // pdf
    case system         // 系统文件
    case txt            // 文本
    case db             // 数据库
    
    /// 根据文件扩展名获取对应的文件类型
    public static func type(from extensionString: String) -> PTFileType {
        let ext = extensionString.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "heic", "webp": return .image
        case "mp4", "mov", "avi", "mkv": return .video
        case "mp3", "wav", "aac", "m4a": return .audio
        case "zip", "rar", "7z", "tar", "gz": return .zip
        case "xls", "xlsx", "csv": return .excel
        case "doc", "docx": return .word
        case "ppt", "pptx": return .ppt
        case "pdf": return .pdf
        case "txt", "rtf": return .txt
        case "db", "sqlite", "sqlite3": return .db
        case "log": return .log
        case "html", "htm", "url": return .web
        case "app", "ipa", "exe", "dmg": return .application
        case "": return .folder // 假设没有后缀的通常是文件夹，具体视业务逻辑而定
        default: return .unknown
        }
    }
}

// MARK: - 文件数据模型
class PTFileModel: NSObject {
    /// 文件名 (包含后缀)
    var name: String = ""
    
    /// 文件的本地路径或URL
    var fileURL: URL?
    
    /// 最后修改时间
    var modificationDate: Date = Date()
    
    /// 文件大小 (以字节 Byte 为单位，使用 Int64 更安全)
    var size: Int64 = 0
    
    /// 文件类型
    var fileType: PTFileType = .unknown
    
    // MARK: - 便捷属性 (Convenience Properties)
    
    /// 获取人类可读的文件大小字符串 (例如: "1.2 MB", "500 KB")
    var formattedSize: String {
        guard size > 0 else { return "0 KB" }
        // 使用 iOS 自带的 ByteCountFormatter 自动处理单位转换
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    /// 获取格式化后的修改时间字符串 (例如: "2023-10-25 14:30")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: modificationDate)
    }
}
