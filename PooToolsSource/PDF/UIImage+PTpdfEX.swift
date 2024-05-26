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
        
        let size = pdfSize(
            withOrginalSize: page.getBoxRect(.mediaBox).size,
            selectedSize: size
        )
        
        if pdfCacheInMemory, let image = memoryCachedImage(url: url, size: size, pageNumber: pageNumber) {
            return image
        }
        
        guard let imageUrl = pdfCacheOnDisk ? pdfCacheURL(with: url, size: size, pageNumber: pageNumber) : url else { return nil }
        
        if pdfCacheOnDisk, FileManager.default.fileExists(atPath: imageUrl.path), let image = UIImage(contentsOfFile: imageUrl.path), let cgImage = image.cgImage {
            return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.concatenate(CGAffineTransform(a: 1, b: .zero, c: .zero, d: -1, tx: .zero, ty: size.height))
        let rect = page.getBoxRect(.mediaBox)
        context.translateBy(x: -rect.origin.x, y: -rect.origin.y)
        context.scaleBy(x: size.width / rect.size.width, y: size.height / rect.size.height)
        context.drawPDFPage(page)
        let imageFromContext = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = imageFromContext, let imageData = image.pngData(), let cgImage = image.cgImage else { return nil }
        
        if pdfCacheOnDisk   { cacheOnDisk(data: imageData, url: imageUrl) }
        if pdfCacheInMemory { cacheImageInMemory(image, url: url, size: size, pageNumber: pageNumber) }
        
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
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

        return pdfSize(
          withOrginalSize: page.getBoxRect(.mediaBox).size,
          selectedSize: size
        )
    }
    
    private static func pdfSize(withOrginalSize orginalSize: CGSize, selectedSize: PDFImageSize) -> CGSize {
        switch selectedSize {
        case .default:
            return orginalSize
        case .custom(let size):
            return size
        case .customWidth(let width):
            let multiplier = width / orginalSize.width
            return CGSize(
              width: ceil(orginalSize.width * multiplier),
              height: ceil(orginalSize.height * multiplier)
            )
        case .customHeight(let height):
            let multiplier = height / orginalSize.height
            
            return CGSize(
                width: ceil(orginalSize.width * multiplier),
                height: ceil(orginalSize.height * multiplier)
            )
        }
    }
}

// MARK: - Cache Public

public extension UIImage {
  
    static var pdfCacheOnDisk = false
    static var pdfCacheInMemory = true
    
    //all
    
    static func removeAllPDFCache() {
        removeAllPDFDiskCache()
        removeAllPDFMemoryCache()
    }
    
    static func removeAllPDFMemoryCache() {
        imageCache.removeAllObjects()
    }
    
    static func removeAllPDFDiskCache() {
        
        let cacheDirectory = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory,
            .userDomainMask,
            true
        )[.zero] + "/" + kDiskCacheFolderName
        
        try? FileManager.default.removeItem(atPath: cacheDirectory)
    }
    
    //memory
    
    static func removeMemoryCachedPDFImage(with name: String, size: PDFImageSize, pageNumber: Int = 1) {
        guard let url = resourceURLForName(name) else { return }
        removeMemoryCachedPDFImage(with: url, size: size, pageNumber: pageNumber)
    }
    
    static func removeMemoryCachedPDFImage(with url: URL, size: PDFImageSize, pageNumber: Int = 1) {
        guard let size = pdfSize(with: url, size: size, pageNumber: pageNumber), let hash = pdfCacheHashString(with: url, size: size, pageNumber: pageNumber) else { return }
        
        imageCache.removeObject(forKey: NSString(string: String(hash)))
    }
    
    @available(*, deprecated, renamed: "removeMemoryCachedPDFImage(with:size:pageNumber:)")
    static func removeMemoryCachedPDFImage(with name: String, size: CGSize, pageNumber: Int = 1) {
        guard let url = resourceURLForName(name) else { return }
        removeMemoryCachedPDFImage(with: url, size: size, pageNumber: pageNumber)
    }
    
    @available(*, deprecated, renamed: "removeMemoryCachedPDFImage(with:size:pageNumber:)")
    static func removeMemoryCachedPDFImage(with url: URL, size: CGSize, pageNumber: Int = 1) {
      
      guard let size = pdfSize(with: url, size: .custom(size), pageNumber: pageNumber), let hash = pdfCacheHashString(with: url, size: size, pageNumber: pageNumber) else { return }
        imageCache.removeObject(forKey: NSString(string: String(hash)))
    }
    
    //disk
    
    static func removeDiskCachedPDFImage(with name: String, size: PDFImageSize, pageNumber: Int = 1) {
        guard let url = resourceURLForName(name) else { return }
        removeDiskCachedPDFImage(with: url, size: size, pageNumber: pageNumber)
    }
    
    static func removeDiskCachedPDFImage(with url: URL, size: PDFImageSize, pageNumber: Int = 1) {
        guard let size = pdfSize(with: url, size: size, pageNumber: pageNumber), let imageUrl = pdfCacheURL(with: url, size: size, pageNumber: pageNumber) else { return }
        try? FileManager.default.removeItem(at: imageUrl)
    }
    
    @available(*, deprecated, renamed: "removeDiskCachedPDFImage(with:size:pageNumber:)")
    static func removeDiskCachedPDFImage(with name: String, size: CGSize, pageNumber: Int = 1) {
        guard let url = resourceURLForName(name) else { return }
        removeDiskCachedPDFImage(with: url, size: size, pageNumber: pageNumber)
    }
    
    @available(*, deprecated, renamed: "removeDiskCachedPDFImage(with:size:pageNumber:)")
    static func removeDiskCachedPDFImage(with url: URL, size: CGSize, pageNumber: Int = 1) {
        guard let size = pdfSize(with: url, size: .custom(size), pageNumber: pageNumber), let imageUrl = pdfCacheURL(with: url, size: size, pageNumber: pageNumber) else { return }
        
        try? FileManager.default.removeItem(at: imageUrl)
    }
}

// MARK: - Cache Private

extension UIImage {
  
    // MARK: - Memory Cache
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
    private static func cacheImageInMemory(_ image: UIImage, url: URL, size: CGSize, pageNumber: Int) {
        guard let hash = pdfCacheHashString(with: url, size: size, pageNumber: pageNumber) else { return }
        imageCache.setObject(image, forKey: NSString(string: String(hash)))
    }
    
    private static func memoryCachedImage(url: URL, size: CGSize, pageNumber: Int) -> UIImage? {
        guard let hash = pdfCacheHashString(with: url, size: size, pageNumber: pageNumber) else { return nil }
        return imageCache.object(forKey: NSString(string: String(hash)))
    }
    
    // MARK: - Disk Cache
    
    private static let kDiskCacheFolderName = "PDFCache"
    
    private static func cacheOnDisk(data: Data, url: URL) {
        try? data.write(to: url, options: [])
    }
    
    private static func pdfCacheURL(with url: URL, size: CGSize, pageNumber: Int) -> URL? {
        do {
            guard let hash = pdfCacheHashString(with: url, size: size, pageNumber: pageNumber) else { return nil }
            
            let cacheDirectory = NSSearchPathForDirectoriesInDomains( .cachesDirectory, .userDomainMask, true)[.zero] + "/" + kDiskCacheFolderName
            
            try FileManager.default.createDirectory( atPath: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            
            return URL(fileURLWithPath: cacheDirectory + "/" + String(format:"%2X", hash) + ".png")

        } catch { return nil }
    }
    
    private static func pdfCacheHashString(with url: URL, size: CGSize, pageNumber: Int) -> Int? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path), let fileSize = attributes[.size] as? NSNumber, let fileDate = attributes[.modificationDate] as? Date else { return nil }
        
        let hashables = url.path + fileSize.stringValue + String(fileDate.timeIntervalSince1970) + String(describing: size) + String(describing: pageNumber)
        return hashables.hash
    }
}

