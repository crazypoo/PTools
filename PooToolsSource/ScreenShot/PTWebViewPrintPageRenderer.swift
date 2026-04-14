//
//  PTWebViewPrintPageRenderer.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

internal final class PTWebViewPrintPageRenderer: UIPrintPageRenderer {
    private var formatter: UIPrintFormatter
    private var contentSize: CGSize

    /// 生成 PrintPageRenderer 实例
    ///
    /// - Parameters:
    ///   - formatter: WebView 的 viewPrintFormatter
    ///   - contentSize: WebView 的 ContentSize
    required init(formatter: UIPrintFormatter, contentSize: CGSize) {
        self.formatter = formatter
        self.contentSize = contentSize
        super.init()
        self.addPrintFormatter(formatter, startingAtPageAt: 0)
    }

    override var paperRect: CGRect {
        return CGRect(origin: .zero, size: contentSize)
    }

    override var printableRect: CGRect {
        return CGRect(origin: .zero, size: contentSize)
    }

    // MARK: - 1. 生成单页 PDF
    private func printContentToPDFPage() -> CGPDFPage? {
        // 使用现代的 UIGraphicsPDFRenderer 替代老旧的 UIGraphicsBeginPDFContextToData
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: self.paperRect, format: format)
        
        let pdfData = renderer.pdfData { context in
            self.prepare(forDrawingPages: NSMakeRange(0, 1))
            context.beginPage()
            self.drawPage(at: 0, in: context.pdfContextBounds)
        }

        // 将生成的 Data 转换为 CGPDFDocument
        let cfData = pdfData as CFData
        guard let provider = CGDataProvider(data: cfData),
              let pdfDocument = CGPDFDocument(provider) else {
            return nil
        }
        
        // 返回第一页（PDF 的页码从 1 开始）
        return pdfDocument.page(at: 1)
    }

    // MARK: - 2. 将 PDF 页面绘制为 UIImage
    private func covertPDFPageToImage(_ pdfPage: CGPDFPage, with configuration: SnapshotConfiguration) -> UIImage? {
        let pageRect = pdfPage.getBoxRect(.trimBox)
        // 使用 floor 防止精度问题
        let contentSize = CGSize(width: floor(pageRect.size.width), height: floor(pageRect.size.height))

        // 使用现代的 UIGraphicsImageRenderer 替代 UIGraphicsBeginImageContextWithOptions
        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale      // 动态接入外部配置的缩放比例 (不再硬编码 2.0)
        format.opaque = configuration.isOpaque  // 动态接入外部配置的透明度

        let renderer = UIGraphicsImageRenderer(size: contentSize, format: format)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            // 如果是不透明背景，填充白色以避免出现黑色背景
            if configuration.isOpaque {
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: contentSize))
            }

            cgContext.saveGState()
            
            // 【核心逻辑】由于 PDF 坐标系原点在左下角，这里需要翻转 Y 轴坐标系
            cgContext.translateBy(x: 0, y: contentSize.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)

            // 设置抗锯齿和渲染意图，提高 PDF 渲染质量
            cgContext.interpolationQuality = .low
            cgContext.setRenderingIntent(.defaultIntent)
            
            // 将 PDF 绘制到图像上下文中
            cgContext.drawPDFPage(pdfPage)
            cgContext.restoreGState()
        }

        return image
    }

    // MARK: - 对外暴露：获取完整的网页截图
    
    /// 将 WKWebView 的完整内容生成一张图片
    ///
    /// - Important: 如果网页内容非常长，生成的图片尺寸也会非常大
    /// - Parameter configuration: 截图配置（控制清晰度和透明度）
    /// - Returns: UIImage?
    internal func printContentToImage(with configuration: SnapshotConfiguration) -> UIImage? {
        guard let pdfPage = self.printContentToPDFPage() else {
            return nil
        }

        let image = self.covertPDFPageToImage(pdfPage, with: configuration)
        return image
    }
}
