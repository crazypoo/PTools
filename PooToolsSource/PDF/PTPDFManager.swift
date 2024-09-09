//
//  PTPDFManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import PDFKit
import CoreGraphics

enum PTPDFManager {

    static func generatePDF(title: String, body: String, image: UIImage?, logs: String) -> Data? {
        let bounds = UIScreen.main.bounds
        let pdfSize = CGSize(width: 610, height: 790)

        let pdfDocument = PDFDocument()
        let pdfPage = PDFPage.createPage(color: .white, size: pdfSize)
        pdfDocument.insert(pdfPage, at: .zero)

        // Add title
        let titleBounds = CGRect(x: .zero, y: pdfSize.height - 30, width: pdfSize.width,height: 30)
        let titleAnnotation = PDFAnnotation.createTextAnnotation(text: title, bounds: titleBounds, fontSize: 20, alignment: .center)
        pdfPage.addAnnotation(titleAnnotation)

        // Body
        let bodyBounds = CGRect(x: 50, y: .zero, width: pdfSize.width - 50, height: pdfSize.height - 40)
        let bodyAnnotation = PDFAnnotation.createTextAnnotation(text: body, bounds: bodyBounds, fontSize: 8, alignment: .left)

        pdfPage.addAnnotation(bodyAnnotation)

        // Add image
        if let image {
            let screenWidth = bounds.size.width / 1.3
            let screenHeight = bounds.size.height / 1.3

            let pdfPage2 = PDFPage.createPage(color: .white, size: pdfSize)

            // Add title to the page
            let titleBounds = CGRect(x: .zero, y: .zero, width: pdfSize.width, height: pdfSize.height)
            let titleAnnotation = PDFAnnotation.createTextAnnotation(text: "screenshot".localized(), bounds: titleBounds, fontSize: 20, alignment: .center)
            pdfPage2.addAnnotation(titleAnnotation)

            // Add Image

            let imageRect = CGRect(x: 145, y: .zero, width: screenWidth, height: screenHeight)
            let imageAnnotation = ImageAnnotation(imageBounds: imageRect, image: image)
            pdfPage2.addAnnotation(imageAnnotation)

            pdfDocument.insert(pdfPage2, at: 1)
        }

        // Add logs
        if !logs.isEmpty {
            let pdfPage3 = PDFPage.createPage(color: .white, size: pdfSize)
            pdfDocument.insert(pdfPage3, at: 2)

            // Add title
            let titleBounds = CGRect(x: .zero, y: pdfSize.height - 30, width: pdfSize.width, height: 30)
            let titleAnnotation = PDFAnnotation.createTextAnnotation(text: "logs".localized(), bounds: titleBounds, fontSize: 20, alignment: .center)
            pdfPage3.addAnnotation(titleAnnotation)

            // Body
            let bodyBounds = CGRect(x: 50, y: .zero, width: pdfSize.width - 50, height: pdfSize.height - 40)
            let bodyAnnotation = PDFAnnotation.createTextAnnotation(text: logs, bounds: bodyBounds, fontSize: 6, alignment: .left)

            pdfPage3.addAnnotation(bodyAnnotation)
        }

        // Convert PDF document to data
        return pdfDocument.dataRepresentation()
    }

    static func savePDFData(_ pdfData: Data, fileName: String) -> URL? {
        // Get the documents directory
        let documentsDirectory = FileManager.pt.getFileDirectory(type: .Documnets)

        // Create a file URL for the PDF
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        if !FileManager.pt.judgeFileOrFolderExists(filePath: fileURL.absoluteString.replacingOccurrences(of: "file:///", with: "/")) {
            let createFile = FileManager.pt.createFile(filePath: fileURL.absoluteString.replacingOccurrences(of: "file:///", with: "/")).isSuccess
            if !createFile {
                PTNSLogConsole("Error create PDF file")
                return nil
            }
        }
        
        do {
            // Write the PDF data to the file
            try pdfData.write(to: URL(fileURLWithPath: fileURL.absoluteString.replacingOccurrences(of: "file:///", with: "/")))
            return fileURL
        } catch {
            PTNSLogConsole("Error saving PDF data: \(error)")
            return nil
        }
    }    
}

private final class ImageAnnotation: PDFAnnotation {

    private var _image: UIImage?

    init(imageBounds: CGRect, image: UIImage?) {
        self._image = image
        super.init(bounds: imageBounds, forType: .stamp, withProperties: nil)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage = _image?.cgImage else {
            return
        }

        let drawingBox = page?.bounds(for: box)
        let imageBounds = bounds.applying(
            CGAffineTransform(translationX: (drawingBox?.origin.x)! * -1.0, y: (drawingBox?.origin.y)! * -1.0)
        )

        // Draw the image
        context.draw(cgImage, in: imageBounds)

        // Add a border around the image
        let borderWidth: CGFloat = 10
        context.setStrokeColor(UIColor.black.cgColor) // Set border color
        context.setLineWidth(borderWidth)
        context.addRect(imageBounds.insetBy(dx: -borderWidth / 2, dy: -borderWidth / 2))
        context.strokePath()
    }
}

extension PDFAnnotation {
    static func createTextAnnotation(text: String, bounds: CGRect, fontSize: CGFloat, alignment: NSTextAlignment) -> PDFAnnotation {
        let annotation = PDFAnnotation(bounds: bounds, forType: .widget, withProperties: nil)
        annotation.widgetFieldType = .text
        annotation.font = UIFont.systemFont(ofSize: fontSize)
        annotation.fontColor = .black
        annotation.backgroundColor = .clear
        annotation.isMultiline = true
        annotation.widgetStringValue = text
        annotation.alignment = alignment

        return annotation
    }
}

extension PDFPage {
    static func createPage(color: UIColor, size: CGSize) -> PDFPage {
        let page = PDFPage()

        return page
    }
}

public class PDFWithImage : NSObject {
    public class func createPDF(withImages dataSource: [UIImage], pdfSize: CGSize, pdfPWD: String?, filePath: String) {
        // 将OC字符串转成C字符串
        var pwdStrRef: CFString? = nil
        if let pwd = pdfPWD, !pwd.isEmpty {
            pwdStrRef = pwd as CFString
        }
        
        let filePathStrRef: CFString = filePath as CFString
        
        // 获取PDF单页尺寸
        var pdfSize = pdfSize
        if pdfSize == .zero {
            pdfSize = CGSize(width: 595, height: 842)
        }
        var pdfRect = CGRect(origin: .zero, size: pdfSize)
        
        // 创建本地存储PDF路径url
        guard let urlRef = CFURLCreateWithFileSystemPath(nil, filePathStrRef, .cfurlposixPathStyle, false) else {
            PTNSLogConsole("create file path url fail.")
            return
        }
        
        // 创建pdf信息字典
        var pdfInfo: [CFString: Any] = [
            kCGPDFContextTitle: "图片转PDF" as CFString,
            kCGPDFContextAuthor: "Emo," as CFString,
            kCGPDFContextAllowsPrinting: kCFBooleanTrue!
        ]
        
        if let pwdStrRef = pwdStrRef {
            pdfInfo.setValue(keys: [kCGPDFContextOwnerPassword as String], newValue: pwdStrRef)
            pdfInfo.setValue(keys: [kCGPDFContextUserPassword as String], newValue: pwdStrRef)
        }
        
        // 转换rect为data
        let rectDataRef = CFDataCreate(nil, &pdfRect, MemoryLayout.size(ofValue: pdfRect))!
        
        // 创建单页信息
        let pageInfo: [CFString: Any] = [
            kCGPDFContextMediaBox: rectDataRef
        ]
        
        guard let context = CGContext(urlRef, mediaBox: &pdfRect, pdfInfo as CFDictionary) else {
            PTNSLogConsole("create pdf context fail.")
            return
        }
        
        // 循环创建PDF页面
        for image in dataSource {
            // 等比计算图片尺寸
            let imgW = image.size.width
            let imgH = image.size.height
            let pdfW = pdfRect.size.width
            let pdfH = pdfRect.size.height
            let pageRect = calculatePDFPageRect(imgW: imgW, imgH: imgH, pdfW: pdfW, pdfH: pdfH)
            
            // 将UIImage转成NSData
            guard let imageData = image.jpegData(compressionQuality: 0.1) else { continue }
            let imgDataRef = imageData as CFData
            
            // 开始绘制PDF单页
            context.beginPDFPage(pageInfo as CFDictionary)
            
            // 绘制PDF单页
            guard let providerRef = CGDataProvider(data: imgDataRef),
                  let imageRef = CGImage(jpegDataProviderSource: providerRef, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { continue }
            
            context.draw(imageRef, in: pageRect)
            
            // 结束绘制PDF单页
            context.endPDFPage()
        }
        
        // 释放资源
        context.closePDF()
    }

    class func calculatePDFPageRect(imgW: CGFloat, imgH: CGFloat, pdfW: CGFloat, pdfH: CGFloat) -> CGRect {
        // 根据你的逻辑计算PDF中的图片位置
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
