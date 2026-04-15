//
//  UIImage+PTpdfEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import Foundation

// MARK: - UIImage+PDF
public extension UIImage {
    
    static func pdfImage(with name: String, size: PDFImageSize, pageNumber: Int = 1) -> UIImage? {
        guard let url = resourceURLForName(name) else { return nil }
        return _pdfImage(with: url, size: size, pageNumber: pageNumber)
    }
    
    static func pdfImage(with name: String, width: CGFloat, pageNumber: Int = 1) -> UIImage? {
        guard let url = resourceURLForName(name) else { return nil }
        return _pdfImage(with: url, size: .customWidth(width), pageNumber: pageNumber)
    }
    
    static func pdfImage(with name: String, height: CGFloat, pageNumber: Int = 1) -> UIImage? {
        guard let url = resourceURLForName(name) else { return nil }
        return _pdfImage(with: url, size: .customHeight(height), pageNumber: pageNumber)
    }
    
    static func pdfImage(with name: String, pageNumber: Int = 1) -> UIImage? {
        guard let url = resourceURLForName(name) else { return nil }
        return _pdfImage(with: url, size: .default, pageNumber: pageNumber)
    }
    
    static func pdfImage(with name: String, size: CGSize, pageNumber: Int = 1) -> UIImage? {
        guard let url = resourceURLForName(name) else { return nil }
        return _pdfImage(with: url, size: .custom(size), pageNumber: pageNumber)
    }
    
    static func pdfImage(with url: URL, size: PDFImageSize, pageNumber: Int = 1) -> UIImage? {
        return _pdfImage(with:url, size: size, pageNumber: pageNumber)
    }
    
    static func pdfImage(with url: URL, width: CGFloat, pageNumber: Int = 1) -> UIImage? {
        return _pdfImage(with: url, size: .customWidth(width), pageNumber: pageNumber)
    }
    
    static func pdfImage(with url: URL, height: CGFloat, pageNumber: Int = 1) -> UIImage? {
        return _pdfImage(with: url, size: .customHeight(height), pageNumber: pageNumber)
    }
    
    static func pdfImage(with url: URL, pageNumber: Int = 1) -> UIImage? {
        return _pdfImage(with: url, size: .default, pageNumber: pageNumber)
    }
    
    static func pdfImage(with url: URL, size: CGSize, pageNumber: Int = 1) -> UIImage? {
        return _pdfImage(with:url, size: .custom(size), pageNumber: pageNumber)
    }
}

// MARK: - ImageSize
extension UIImage {
    public enum PDFImageSize {
        case `default`
        case custom(CGSize)
        case customWidth(CGFloat)
        case customHeight(CGFloat)
    }
}

// MARK: - Private
extension UIImage {
    
    private static func _pdfImage(with url: URL, size: PDFImageSize, pageNumber: Int) -> UIImage? {
        
        guard let pdf = CGPDFDocument(url as CFURL), let page = pdf.page(at: pageNumber) else { return nil }
        
        let targetSize = pdfSize(
            withOrginalSize: page.getBoxRect(.mediaBox).size,
            selectedSize: size
        )
        
        // 1. 检查内存缓存
        if pdfCacheInMemory, let image = memoryCachedImage(url: url, size: targetSize, pageNumber: pageNumber) {
            return image
        }
        
        guard let imageUrl = pdfCacheURL(with: url, size: targetSize, pageNumber: pageNumber) else { return nil }
        
        // 2. 检查磁盘缓存
        if pdfCacheOnDisk, FileManager.default.fileExists(atPath: imageUrl.path), let image = UIImage(contentsOfFile: imageUrl.path), let cgImage = image.cgImage {
            // 确保从磁盘读取的图片也进入内存缓存，提升下次访问速度
            let finalImage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
            if pdfCacheInMemory { cacheImageInMemory(finalImage, url: url, size: targetSize, pageNumber: pageNumber) }
            return finalImage
        }
        
        // 3. 优化点：使用现代的 UIGraphicsImageRenderer 替代 UIGraphicsBeginImageContextWithOptions
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let imageFromContext = renderer.image { context in
            let cgContext = context.cgContext
            
            // Core Graphics 的坐标系在左下角，需要进行翻转和位移
            cgContext.translateBy(x: 0, y: targetSize.height)
            cgContext.scaleBy(x: 1, y: -1)
            
            let rect = page.getBoxRect(.mediaBox)
            cgContext.scaleBy(x: targetSize.width / rect.size.width, y: targetSize.height / rect.size.height)
            cgContext.translateBy(x: -rect.origin.x, y: -rect.origin.y)
            
            cgContext.drawPDFPage(page)
        }
        
        guard let imageData = imageFromContext.pngData(), let cgImage = imageFromContext.cgImage else { return nil }
        let finalImage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        
        // 4. 保存缓存
        if pdfCacheOnDisk   { cacheOnDisk(data: imageData, url: imageUrl) }
        if pdfCacheInMemory { cacheImageInMemory(finalImage, url: url, size: targetSize, pageNumber: pageNumber) }
        
        return finalImage
    }
    
    private static func resourceURLForName(_ resourceName: String) -> URL? {
        let isSuffix = resourceName.lowercased().hasSuffix(".pdf")
        let name = isSuffix ? resourceName : resourceName + ".pdf"
        
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    private static func pdfSize(with url: URL, size: PDFImageSize, pageNumber: Int) -> CGSize? {
        guard let pdf = CGPDFDocument(url as CFURL), let page = pdf.page(at: pageNumber) else { return nil }
        return pdfSize(withOrginalSize: page.getBoxRect(.mediaBox).size, selectedSize: size)
    }
    
    private static func pdfSize(withOrginalSize orginalSize: CGSize, selectedSize: PDFImageSize) -> CGSize {
        switch selectedSize {
        case .default:
            return orginalSize
        case .custom(let size):
            return size
        case .customWidth(let width):
            let multiplier = width / orginalSize.width
            return CGSize(width: ceil(orginalSize.width * multiplier), height: ceil(orginalSize.height * multiplier))
        case .customHeight(let height):
            let multiplier = height / orginalSize.height
            return CGSize(width: ceil(orginalSize.width * multiplier), height: ceil(orginalSize.height * multiplier))
        }
    }
}

// MARK: - Cache Public
public extension UIImage {
    
    static var pdfCacheOnDisk = false
    static var pdfCacheInMemory = true
    
    // all
    static func removeAllPDFCache() {
        removeAllPDFDiskCache()
        removeAllPDFMemoryCache()
    }
    
    static func removeAllPDFMemoryCache() {
        imageCache.removeAllObjects()
    }
    
    static func removeAllPDFDiskCache() {
        // 优化点：使用现代 FileManager API 获取缓存目录
        guard let cacheDirectory = diskCacheDirectoryURL else { return }
        try? FileManager.default.removeItem(at: cacheDirectory)
    }
    
    // memory
    static func removeMemoryCachedPDFImage(with name: String, size: PDFImageSize, pageNumber: Int = 1) {
        guard let url = resourceURLForName(name) else { return }
        removeMemoryCachedPDFImage(with: url, size: size, pageNumber: pageNumber)
    }
    
    static func removeMemoryCachedPDFImage(with url: URL, size: PDFImageSize, pageNumber: Int = 1) {
        guard let targetSize = pdfSize(with: url, size: size, pageNumber: pageNumber),
              let hashString = pdfCacheHashString(with: url, size: targetSize, pageNumber: pageNumber) else { return }
        
        imageCache.removeObject(forKey: NSString(string: hashString))
    }
    
    // disk
    static func removeDiskCachedPDFImage(with name: String, size: PDFImageSize, pageNumber: Int = 1) {
        guard let url = resourceURLForName(name) else { return }
        removeDiskCachedPDFImage(with: url, size: size, pageNumber: pageNumber)
    }
    
    static func removeDiskCachedPDFImage(with url: URL, size: PDFImageSize, pageNumber: Int = 1) {
        guard let targetSize = pdfSize(with: url, size: size, pageNumber: pageNumber),
              let imageUrl = pdfCacheURL(with: url, size: targetSize, pageNumber: pageNumber) else { return }
        try? FileManager.default.removeItem(at: imageUrl)
    }
}

// MARK: - Cache Private
extension UIImage {
    
    // MARK: - Memory Cache
    private static let imageCache = NSCache<NSString, UIImage>()
    
    private static func cacheImageInMemory(_ image: UIImage, url: URL, size: CGSize, pageNumber: Int) {
        guard let hashString = pdfCacheHashString(with: url, size: size, pageNumber: pageNumber) else { return }
        imageCache.setObject(image, forKey: NSString(string: hashString))
    }
    
    private static func memoryCachedImage(url: URL, size: CGSize, pageNumber: Int) -> UIImage? {
        guard let hashString = pdfCacheHashString(with: url, size: size, pageNumber: pageNumber) else { return nil }
        return imageCache.object(forKey: NSString(string: hashString))
    }
    
    // MARK: - Disk Cache
    private static let kDiskCacheFolderName = "PDFCache"
    
    // 提取统一的磁盘缓存目录方法
    private static var diskCacheDirectoryURL: URL? {
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        return cacheDir.appendingPathComponent(kDiskCacheFolderName)
    }
    
    private static func cacheOnDisk(data: Data, url: URL) {
        try? data.write(to: url, options: [])
    }
    
    private static func pdfCacheURL(with url: URL, size: CGSize, pageNumber: Int) -> URL? {
        do {
            guard let hashString = pdfCacheHashString(with: url, size: size, pageNumber: pageNumber),
                  let directoryURL = diskCacheDirectoryURL else { return nil }
            
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            
            return directoryURL.appendingPathComponent("\(hashString).png")
        } catch { return nil }
    }
    
    // 优化点：修复了 String.hash 会在应用重启时发生变化的严重 Bug
    // 将返回值从 Int? 改为 String? 确保其绝对稳定
    private static func pdfCacheHashString(with url: URL, size: CGSize, pageNumber: Int) -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? NSNumber,
              let fileDate = attributes[.modificationDate] as? Date else { return nil }
        
        // 拼接一个稳定不变的特征字符串
        let identifier = "\(url.lastPathComponent)_\(fileSize.stringValue)_\(fileDate.timeIntervalSince1970)_\(size.width)x\(size.height)_p\(pageNumber)"
        
        // 使用 Base64 编码以防止文件名中出现非法字符，替换掉可能破坏路径的 "/"
        if let base64String = identifier.data(using: .utf8)?.base64EncodedString() {
            return base64String.replacingOccurrences(of: "/", with: "_")
        }
        return nil
    }
}
