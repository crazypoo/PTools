//
//  PTPDFManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import PDFKit

// MARK: - 第一部分：生成报表类型的 PDF
public enum PTPDFManager {
    
    /// 生成包含标题、正文、图片和日志的报表 PDF
    public static func generatePDF(title: String, body: String, image: UIImage?, logs: String) -> Data? {
        let pdfSize = CGSize(width: 610, height: 790)
        let pageRect = CGRect(origin: .zero, size: pdfSize)
        
        // 1. 初始化现代的 PDF 渲染器
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        // 2. 开始渲染 PDF 数据
        let pdfData = renderer.pdfData { context in
            let cgContext = context.cgContext
            
            // ========== 第一页：标题和正文 ==========
            context.beginPage()
            
            // 绘制标题
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.black
            ]
            let titleString = NSAttributedString(string: title, attributes: titleAttributes)
            // 居中显示标题
            let titleSize = titleString.size()
            titleString.draw(at: CGPoint(x: (pdfSize.width - titleSize.width) / 2, y: 30))
            
            // 绘制正文
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.black
            ]
            let bodyRect = CGRect(x: 50, y: 80, width: pdfSize.width - 100, height: pdfSize.height - 100)
            body.draw(in: bodyRect, withAttributes: bodyAttributes)
            
            // ========== 第二页：图片 (如果有) ==========
            if let targetImage = image {
                context.beginPage()
                
                // 绘制“截图”标题
                let imgTitleText = NSLocalizedString("screenshot", comment: "")
                let imgTitle = NSAttributedString(string: imgTitleText, attributes: titleAttributes)
                imgTitle.draw(at: CGPoint(x: (pdfSize.width - imgTitle.size().width) / 2, y: 30))
                
                // 绘制图片
                let imgWidth = pdfSize.width / 1.3
                let imgHeight = pdfSize.height / 1.3
                let imgRect = CGRect(x: (pdfSize.width - imgWidth) / 2, y: 80, width: imgWidth, height: imgHeight)
                targetImage.draw(in: imgRect)
                
                // 绘制图片边框 (替代以前复杂的 ImageAnnotation)
                let borderWidth: CGFloat = 10
                cgContext.setStrokeColor(UIColor.black.cgColor)
                cgContext.setLineWidth(borderWidth)
                cgContext.stroke(imgRect.insetBy(dx: -borderWidth / 2, dy: -borderWidth / 2))
            }
            
            // ========== 第三页：日志 (如果有) ==========
            if !logs.isEmpty {
                context.beginPage()
                
                // 绘制“日志”标题
                let logTitleText = NSLocalizedString("logs", comment: "")
                let logTitle = NSAttributedString(string: logTitleText, attributes: titleAttributes)
                logTitle.draw(at: CGPoint(x: (pdfSize.width - logTitle.size().width) / 2, y: 30))
                
                // 绘制日志正文
                let logAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 6),
                    .foregroundColor: UIColor.black
                ]
                let logRect = CGRect(x: 50, y: 80, width: pdfSize.width - 100, height: pdfSize.height - 100)
                logs.draw(in: logRect, withAttributes: logAttributes)
            }
        }
        
        return pdfData
    }
    
    /// 保存 PDF 数据到沙盒 Documents 目录
    public static func savePDFData(_ pdfData: Data, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            PTNSLogConsole("PDF 保存成功: \(fileURL.path)")
            return fileURL
        } catch {
            PTNSLogConsole("保存 PDF 出错: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - 第二部分：多图合成 PDF 并加密
public class PDFWithImage: NSObject {
    
    /// 将多个 UIImage 合成为一个 PDF，支持密码保护
    public static func createPDF(withImages dataSource: [UIImage], pdfSize: CGSize, pdfPWD: String?, filePath: String) {
        
        let targetSize = pdfSize == .zero ? CGSize(width: 595, height: 842) : pdfSize
        let pageRect = CGRect(origin: .zero, size: targetSize)
        
        // 1. 设置 PDF 属性和密码保护 (告别繁杂的 C 字典)
        let format = UIGraphicsPDFRendererFormat()
        var documentInfo: [String: Any] = [
            kCGPDFContextTitle as String: "图片转PDF",
            kCGPDFContextAuthor as String: "Emo",
            kCGPDFContextAllowsPrinting as String: true
        ]
        
        if let pwd = pdfPWD, !pwd.isEmpty {
            // 给 PDF 加上用户密码和所有者密码
            documentInfo[kCGPDFContextOwnerPassword as String] = pwd
            documentInfo[kCGPDFContextUserPassword as String] = pwd
        }
        format.documentInfo = documentInfo
        
        // 2. 初始化渲染器
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let url = URL(fileURLWithPath: filePath)
        
        do {
            // 3. 直接将内容写入目标文件路径
            try renderer.writePDF(to: url) { context in
                for image in dataSource {
                    // 开始新的一页
                    context.beginPage()
                    
                    // 计算图片位置并绘制
                    let imageRect = calculatePDFPageRect(imgW: image.size.width, imgH: image.size.height, pdfW: targetSize.width, pdfH: targetSize.height)
                    image.draw(in: imageRect)
                }
            }
            PTNSLogConsole("多图 PDF 生成成功！路径: \(filePath)")
        } catch {
            PTNSLogConsole("生成 PDF 失败: \(error.localizedDescription)")
        }
    }

    /// 等比计算图片在 PDF 中的居中位置 (保留你原有的优秀数学逻辑)
    public static func calculatePDFPageRect(imgW: CGFloat, imgH: CGFloat, pdfW: CGFloat, pdfH: CGFloat) -> CGRect {
        let aspectRatio = imgW / imgH
        var pageRect = CGRect.zero
        
        if aspectRatio > pdfW / pdfH {
            let newHeight = pdfW / aspectRatio
            pageRect = CGRect(x: 0, y: (pdfH - newHeight) / 2, width: pdfW, height: newHeight)
        } else {
            let newWidth = pdfH * aspectRatio
            pageRect = CGRect(x: (pdfW - newWidth) / 2, y: 0, width: newWidth, height: pdfH)
        }
        return pageRect
    }
}
