//
//  PTViewToPDF.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import CoreGraphics

public class PTViewToPDF: NSObject {
    
    /// 将 UIView 数组转换为 PDF 文件
    /// - Parameter pages: 要转换为 PDF 的 UIView 数组（每个 View 代表一页）
    /// - Returns: 生成的 PDF 文件的本地路径
    public static func generatePDF(with pages: [UIView]) -> String? {
        // 确保数组不为空
        guard !pages.isEmpty else { return nil }
        
        // 1. 设置保存路径 (使用系统标准临时目录，并加上 UUID 防止多次生成时的文件覆盖)
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "temp_\(UUID().uuidString).pdf"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // 2. 初始化 PDF 渲染器 (默认以第一页的大小为准，后续每页可动态调整)
        let defaultBounds = pages.first?.bounds ?? CGRect(x: 0, y: 0, width: 612, height: 792) // 默认 8.5x11 英寸
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: defaultBounds)
        
        do {
            // 3. 开启 PDF 绘制上下文
            try pdfRenderer.writePDF(to: fileURL) { context in
                
                // 4. 遍历每个 UIView
                for page in pages {
                    // 如果传入的 view frame 为 empty，跳过防止崩溃
                    guard page.bounds.width > 0 && page.bounds.height > 0 else { continue }
                    
                    // 开启 PDF 的新一页，尺寸完全匹配当前 View 的尺寸
                    context.beginPage(withBounds: page.bounds, pageInfo: [:])
                    
                    // 5. 核心魔法：直接让 View 的 Core Animation Layer 渲染到 PDF 上下文中
                    // 这将完美保留所有子视图、文字、图片、背景色、甚至是圆角等属性
                    page.layer.render(in: context.cgContext)
                }
            }
            
            // 绘制成功，返回路径
            return fileURL.path
            
        } catch {
            PTNSLogConsole("PDF 生成失败: \(error.localizedDescription)")
            return nil
        }
    }
}
