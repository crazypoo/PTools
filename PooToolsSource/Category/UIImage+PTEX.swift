//
//  UIImage+SizeEx.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

#if !os(macOS)

import UIKit
import Accelerate
import AVFoundation
import Photos
import MobileCoreServices
import ImageIO
import SwifterSwift
import CoreImage

extension UIImage : PTProtocolCompatible {}
extension CIImage : PTProtocolCompatible {}

public extension UIImage {
    
    // MARK: - 1. 基础初始化与主题支持
    
    convenience init?(color: UIColor, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // 根据需要调整缩放
        let renderer = UIGraphicsImageRenderer(bounds: rect, format: format)
        
        let image = renderer.image { context in
            color.setFill()
            context.fill(rect)
        }
        
        guard let cgImage = image.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    /// 动态支持暗黑模式的图片
    static func darkModeImage(light: UIImage, dark: UIImage) -> UIImage {
        let imageAsset = UIImageAsset()
        // 注册浅色模式图片
        let lightTrait = UITraitCollection(userInterfaceStyle: .light)
        imageAsset.register(light, with: lightTrait)
        // 注册深色模式图片
        let darkTrait = UITraitCollection(userInterfaceStyle: .dark)
        imageAsset.register(dark, with: darkTrait)
        
        return imageAsset.image(with: UITraitCollection.current)
    }

    // MARK: - 2. SF Symbols (系统图标)
    static func system(_ name: String) -> UIImage {
        UIImage(systemName: name) ?? UIImage()
    }
    
    static func system(_ name: String, pointSize: CGFloat, weight: UIImage.SymbolWeight) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        return UIImage(systemName: name, withConfiguration: configuration) ?? UIImage()
    }
    
    static func system(_ name: String, font: UIFont) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(font: font)
        return UIImage(systemName: name, withConfiguration: configuration) ?? UIImage()
    }

    // MARK: - 3. 尺寸与压缩处理
    var bytesSize: Int { jpegData(compressionQuality: 1)?.count ?? .zero }
    var kilobytesSize: Double { Double(bytesSize) / 1024.0 }
    
    /// 修正了命名：compresse -> compressed
    func compressed(quality: CGFloat) -> UIImage? {
        guard let data = jpegData(compressionQuality: quality) else { return nil }
        return UIImage(data: data)
    }
    
    func compressedData(quality: CGFloat) -> Data? {
        jpegData(compressionQuality: quality)
    }
    
    // MARK: - Appearance
    
    var alwaysTemplate: UIImage {
        withRenderingMode(.alwaysTemplate)
    }
    
    var alwaysOriginal: UIImage {
        withRenderingMode(.alwaysOriginal)
    }
    
    func alwaysOriginal(with color: UIColor) -> UIImage {
        withTintColor(color, renderingMode: .alwaysOriginal)
    }
    
    #if canImport(CoreImage)
    fileprivate func resize(newWidth desiredWidth: CGFloat) -> UIImage {
        let oldWidth = size.width
        let scaleFactor = desiredWidth / oldWidth
        let newHeight = size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)
        return resize(targetSize: newSize)
    }
    
    fileprivate func resize(newHeight desiredHeight: CGFloat) -> UIImage {
        let scaleFactor = desiredHeight / size.height
        let newWidth = size.width * scaleFactor
        let newSize = CGSize(width: newWidth, height: desiredHeight)
        return resize(targetSize: newSize)
    }
    
    // MARK: - 4. 尺寸裁剪与重绘 (现代化写法)
    fileprivate func resize(targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    #endif
    
    /// 将 UIImage 转换为 HEIC 格式的 Data
    /// - Parameters:
    ///   - image: 需要转换的 UIImage
    ///   - quality: 压缩质量（0.0 - 1.0），默认 1.0（最高质量）
    ///   - lossless: 是否使用无损压缩，默认为 false
    /// - Returns: 转换后的 HEIC 格式 Data，若转换失败则返回 nil
    func heicDataBelow17Version(quality: CGFloat? = 1.0, lossless: Bool = false) -> Data? {
        return self.heicData()
    }

    //MARK: 更改圖片大小
    ///更改圖片大小
    @objc func transformImage(size:CGSize) -> UIImage {
        if isSymbolImage {
            return resize(targetSize: size)
        } else {
            return preparingThumbnail(of: size) ?? resize(targetSize: size)
        }
    }
    
    private func transform(size:CGSize) -> UIImage {
        let destW = size.width
        let destH = size.height
        let sourceW = size.width
        let sourceH = size.height
        
        guard destW > 0, destH > 0,
              sourceW > 0, sourceH > 0,
              let imageRef = cgImage,
              let colorSpace = imageRef.colorSpace,
              let bitmap = CGContext(data: nil,
                                      width: Int(destW),
                                      height: Int(destH),
                                      bitsPerComponent: imageRef.bitsPerComponent,
                                      bytesPerRow: 4 * Int(destW),
                                      space: colorSpace,
                                      bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            return self
        }
        
        bitmap.draw(imageRef, in: CGRect(x: 0, y: 0, width: sourceW, height: sourceH))
        
        guard let ref = bitmap.makeImage() else { return self }
        return UIImage(cgImage: ref)
    }
    
    //MARK: 圖片高斯模糊
    ///圖片高斯模糊
    @MainActor @objc func blurImage() -> UIImage? {
        return img(alpha: 0.1, radius: 10, colorSaturationFactor: 1)
    }
    
    /*
     1.白色,参数:
     透明度 0~1,  0为白,   1为深灰色
     半径:默认30,推荐值 3   半径值越大越模糊 ,值越小越清楚
     色彩饱和度(浓度)因子:  0是黑白灰, 9是浓彩色, 1是原色  默认1.8
     “彩度”，英文是称Saturation，即饱和度。将无彩色的黑白灰定为0，最鲜艳定为9s，这样大致分成十阶段，让数值和人的感官直觉一致。
     */
    @MainActor func img(alpha:CGFloat,
                        radius:CGFloat,
                        colorSaturationFactor:CGFloat) -> UIImage? {
        let tintColor = UIColor(white: 1, alpha: alpha)
        return imgBluredWithRadius(blurRadius: radius, tintColor: tintColor, saturationDeltaFactor: colorSaturationFactor, maskImage: nil)
    }
    
    private static let sharedCIContext = CIContext(options: nil)
    
    @MainActor func imgBluredWithRadius(blurRadius:CGFloat,
                                        tintColor:UIColor?,
                                        saturationDeltaFactor:CGFloat,
                                        maskImage:UIImage?) -> UIImage? {
        // 1. 安全校验：确保图片尺寸有效且包含 CGImage
        guard size.width > 0 && size.height > 0, let cgImage = self.cgImage else {
            return nil
        }
        
        let imageRect = CGRect(origin: .zero, size: size)
        let hasBlur = blurRadius > .ulpOfOne
        let hasSaturationChange = abs(saturationDeltaFactor - 1.0) > .ulpOfOne
        
        var effectCGImage: CGImage? = nil
        
        // 2. 核心优化：使用 CoreImage 的经典 KVC 方式处理滤镜 (向下兼容性极佳)
        if hasBlur || hasSaturationChange {
            var ciImage = CIImage(cgImage: cgImage)
            
            // 模糊处理
            if hasBlur {
                // clampedToExtent 防止图片边缘在模糊时出现透明黑边
                ciImage = ciImage.clampedToExtent()
                
                // 使用字符串名称初始化滤镜，兼容所有 iOS 版本
                if let blurFilter = CIFilter(name: "CIGaussianBlur") {
                    blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
                    blurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)
                    ciImage = blurFilter.outputImage ?? ciImage
                }
            }
            
            // 饱和度处理
            if hasSaturationChange {
                if let colorFilter = CIFilter(name: "CIColorControls") {
                    colorFilter.setValue(ciImage, forKey: kCIInputImageKey)
                    colorFilter.setValue(saturationDeltaFactor, forKey: kCIInputSaturationKey)
                    ciImage = colorFilter.outputImage ?? ciImage
                }
            }
            
            // 将处理后的图像裁剪回原始尺寸，并渲染成 CGImage
            ciImage = ciImage.cropped(to: CGRect(origin: .zero, size: size))
            effectCGImage = Self.sharedCIContext.createCGImage(ciImage, from: ciImage.extent)
        }
        
        // 3. 现代绘制 API：使用 UIGraphicsImageRenderer 进行最终的图层合成
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // 翻转 CoreGraphics 坐标系（因为 CG 和 UIKit 坐标系的 Y 轴是相反的）
            cgContext.scaleBy(x: 1.0, y: -1.0)
            cgContext.translateBy(x: 0, y: -size.height)
            
            // 底层：绘制原始图片
            cgContext.draw(cgImage, in: imageRect)
            
            // 中层：如果应用了效果，根据 mask 绘制特效图片
            if let effectCGImage = effectCGImage {
                cgContext.saveGState()
                if let maskCGImage = maskImage?.cgImage {
                    // 应用遮罩裁剪
                    cgContext.clip(to: imageRect, mask: maskCGImage)
                }
                cgContext.draw(effectCGImage, in: imageRect)
                cgContext.restoreGState()
            }
            
            // 顶层：覆盖颜色 (TintColor)
            if let tintColor = tintColor {
                cgContext.saveGState()
                cgContext.setFillColor(tintColor.cgColor)
                cgContext.fill(imageRect)
                cgContext.restoreGState()
            }
        }
    }
    
    //MARK: 加水印
    ///加水印
    @objc func watermark(title:String,
                         font:UIFont = UIFont.systemFont(ofSize: 23),
                         color:UIColor? = nil) -> UIImage {
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
        
        let textColor = color ?? (self.imageMostColor() ?? .white)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: self.size))
            
            // 此处保留了你原本倾斜绘制水印的逻辑
            let ctx = context.cgContext
            let viewWidth = self.size.width
            let viewHeight = self.size.height
            
            ctx.saveGState()
            ctx.translateBy(x: viewWidth / 2, y: viewHeight / 2)
            ctx.rotate(by: .pi / 3)
            ctx.translateBy(x: -viewWidth / 2, y: -viewHeight / 2)
            
            let textSize = title.nsString.size(withAttributes: attributes)
            let diagonal = hypot(viewWidth, viewHeight)
            let startX = -(diagonal - viewWidth) / 2
            let startY = -(diagonal - viewHeight) / 2
            
            let cols = Int(diagonal / (textSize.width + 30)) + 1
            let rows = Int(diagonal / (textSize.height + 50)) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = startX + CGFloat(col) * (textSize.width + 30)
                    let y = startY + CGFloat(row) * (textSize.height + 50)
                    title.nsString.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
                }
            }
            ctx.restoreGState()
        }
    }
    
    func imageScale(scaleSize:CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: size.width * scaleSize, height: size.height * scaleSize))
        self.draw(in: CGRect(x: 0, y: 0, width: size.width * scaleSize, height: size.height * scaleSize))
        UIGraphicsEndImageContext()
        return self
    }
    
    func imageMask(text:NSString,
                   point:CGPoint,
                   attributed:NSDictionary) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let attributes = attributed as? [NSAttributedString.Key: Any] ?? [:]
        text.draw(at: point, withAttributes: attributes)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
    
    func imageMask(maskImage:UIImage,
                   maskRect:CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        maskImage.draw(in: maskRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
    
    //MARK: 獲取圖片中大部分占有的顏色
    ///獲取圖片中大部分占有的顏色
    @objc func imageMostColor() -> UIColor? {
        guard let ciImage = CIImage(image: self) ?? self.ciImage else { return nil }
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)
        
        return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                       green: CGFloat(bitmap[1]) / 255.0,
                       blue: CGFloat(bitmap[2]) / 255.0,
                       alpha: CGFloat(bitmap[3]) / 255.0)
    }
    
    //MARK: 獲取圖片中某個像素點的顏色
    ///獲取圖片中某個像素點的顏色
    func getImgePointColor(point:CGPoint) -> UIColor {
        guard point.x >= 0, point.y >= 0,
              point.x < size.width, point.y < size.height,
              let context = getImageContext(),
              let data = context.data else {
            return .clear
        }

        let newImgData = data.assumingMemoryBound(to: UInt8.self)
        
        // 根据当前所选择的点计算出对应位图数据的index
        let offset = Int(point.y * size.width + point.x) * 4
        
        // 获取4种信息
        let alpha = (newImgData + offset).pointee
        let red   = (newImgData + (offset + 1)).pointee
        let green = (newImgData + (offset + 2)).pointee
        let blue  = (newImgData + (offset + 3)).pointee
        
        // 得到颜色
        return UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: CGFloat(alpha)/255.0)
    }
    
    func getImageContext() -> CGContext? {
        guard let currentImage = cgImage else { return nil }
        
        let bitmapInfo = CGBitmapInfo.byteOrderDefault.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let thumbSize = CGSize(width: max(size.width, 1), height: max(size.height, 1))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: nil,
                                      width: Int(thumbSize.width),
                                      height: Int(thumbSize.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: Int(thumbSize.width) * 4,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        let drawRect = CGRect(x: 0, y: 0, width: thumbSize.width, height: thumbSize.height)
        context.draw(currentImage, in: drawRect)
        return context
    }
    
    //MARK: 把圖片換成圓形
    ///把圖片換成圓形
    @objc func circularImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: self.size)
            UIBezierPath(ovalIn: rect).addClip()
            self.draw(in: rect)
        }
    }
    
    //MARK: 判斷一個圖片是否大於或者小於某個尺寸
    ///判斷一個圖片是否大於或者小於某個尺寸
    @objc func checkImage(smallerThan:Bool = false,checkSize:CGSize) -> Bool {
        if smallerThan {
            return self.size.width < checkSize.width && self.size.height < checkSize.height
        } else {
            return self.size.width > checkSize.width || self.size.height > checkSize.height
        }
    }
    
    //MARK: 判断 UIImage 的图片数据大小是否大于某个值（以字节为单位）
    ///判断 UIImage 的图片数据大小是否大于某个值（以字节为单位）
    @objc func checkImageSizeLargerThan(byteSize: Int) -> Bool {
        // 将 UIImage 转换为 JPEG 格式的图片数据
        // 检查图片数据的字节大小是否大于指定值
        return self.bytesSize > byteSize // 如果转换失败，则默认为大小不超过指定值
    }
    
    //MARK: 保存圖片為JPEG,並且返回鏈接
    ///保存圖片為JPEG,並且返回鏈接
    func saveImageAsJPEG(completion: @escaping (URL?) -> Void) {
        if let data = self.jpegData(compressionQuality: 1.0) {
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = tempDirectory.appendingPathComponent(fileName)

            do {
                try data.write(to: fileURL)
                completion(fileURL)
            } catch {
                PTNSLogConsole("Error saving image: \(error)")
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }

    //MARK: 保存圖片為PNG,並且返回鏈接
    ///保存圖片為PNG,並且返回鏈接
    func saveImageAsPNG(completion: @escaping (URL?) -> Void) {

        if let data = self.pngData() {
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".png"
            let fileURL = tempDirectory.appendingPathComponent(fileName)

            do {
                try data.write(to: fileURL)
                completion(fileURL)
            } catch {
                PTNSLogConsole("Error saving image: \(error)")
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    
    /// 使用vImage对图像进行高斯模糊处理
    static func applyGaussianBlur(to image: UIImage, withRadius radius: Float) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        // 创建图像格式
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passRetained(CGColorSpaceCreateDeviceRGB()),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        // 创建vImage缓冲区
        var sourceBuffer = vImage_Buffer()
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, vImage_Flags(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }
        // 创建目标缓冲区
        var destinationBuffer = vImage_Buffer()
        destinationBuffer.data = malloc(sourceBuffer.rowBytes * Int(sourceBuffer.height))
        destinationBuffer.width = sourceBuffer.width
        destinationBuffer.height = sourceBuffer.height
        destinationBuffer.rowBytes = sourceBuffer.rowBytes
        guard destinationBuffer.data != nil else {
            free(sourceBuffer.data)
            return nil
        }
        // 卷积核大小
        let kernelSize = UInt32(max(3, Int(radius) | 1))
        // 应用高斯模糊
        error = vImageTentConvolve_ARGB8888(&sourceBuffer,
                                            &destinationBuffer,
                                            nil,
                                            0, 0,
                                            kernelSize, kernelSize,
                                            nil,
                                            vImage_Flags(kvImageEdgeExtend))
        guard error == kvImageNoError else {
            free(sourceBuffer.data)
            free(destinationBuffer.data)
            return nil
        }
        // 从vImage缓冲区创建新的CGImage
        guard let blurredImage = vImageCreateCGImageFromBuffer(&destinationBuffer,
                                                               &format,
                                                               nil,
                                                               nil,
                                                               vImage_Flags(kvImageNoFlags),
                                                               &error) else {
            free(sourceBuffer.data)
            free(destinationBuffer.data)
            return nil
        }
        // 释放内存
        free(sourceBuffer.data)
        free(destinationBuffer.data)
        if error != kvImageNoError {
            return nil
        }
        // 从CGImage创建UIImage
        return UIImage(cgImage: blurredImage.takeRetainedValue())
    }
    
    static func gradient(colors: [UIColor],
                         size: CGSize,
                         direction: Imagegradien) -> UIImage? {
            
            guard !colors.isEmpty,
                  size.width > 0,
                  size.height > 0 else {
                return nil
            }
            
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                let gradientLayer = CAGradientLayer()
                gradientLayer.frame = CGRect(origin: .zero, size: size)
                gradientLayer.colors = colors.map(\.cgColor)
                
                switch direction {
                case .LeftToRight:
                    gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
                    gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
                    
                case .TopToBottom:
                    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
                    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
                    
                case .RightToLeft:
                    gradientLayer.startPoint = CGPoint(x: 1, y: 0.5)
                    gradientLayer.endPoint = CGPoint(x: 0, y: 0.5)
                    
                case .BottomToTop:
                    gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
                    gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
                }
                
                gradientLayer.render(in: context.cgContext)
            }
        }
}

public extension PTPOP where Base: UIImage {
    //MARK: 设置图片的圆角
    ///设置图片的圆角
    /// - Parameters:
    ///   - radius: 圆角大小 (默认:3.0,图片大小)
    ///   - corners: 切圆角的方式
    ///   - imageSize: 图片的大小
    /// - Returns: 剪切后的图片
    @MainActor func isRoundCorner(radius: CGFloat = 3,
                       byRoundingCorners corners: UIRectCorner = .allCorners,
                       imageSize: CGSize?) -> UIImage? {
        let weakSize = imageSize ?? base.size
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: weakSize)
        // 开始图形上下文
        UIGraphicsBeginImageContextWithOptions(weakSize, false, UIScreen.main.scale)
        guard let contentRef: CGContext = UIGraphicsGetCurrentContext() else {
            // 关闭上下文
            UIGraphicsEndImageContext()
            return nil
        }
        // 绘制路线
        contentRef.addPath(UIBezierPath(roundedRect: rect,
                                        byRoundingCorners: UIRectCorner.allCorners,
                                        cornerRadii: CGSize(width: radius, height: radius)).cgPath)
        // 裁剪
        contentRef.clip()
        // 将原图片画到图形上下文
        base.draw(in: rect)
        contentRef.drawPath(using: .fillStroke)
        guard let output = UIGraphicsGetImageFromCurrentImageContext() else {
            // 关闭上下文
            UIGraphicsEndImageContext()
            return nil
        }
        // 关闭上下文
        UIGraphicsEndImageContext()
        return output
    }
    
    //MARK: 获取视频的第一帧
    ///获取视频的第一帧
    /// - Parameters:
    ///   - videoUrl: 视频 url
    ///   - maximumSize: 图片的最大尺寸
    ///   - closure:
    /// - Returns: 视频的第一帧
    static func getVideoFirstImage(videoUrl: String,
                                   maximumSize: CGSize = CGSize(width: 1000, height: 1000),
                                   closure: @escaping @MainActor @Sendable (UIImage?) -> Void) {
        guard let url = URL(string: videoUrl) else {
            Task { @MainActor in closure(nil) }
            return
        }
        PTVideoThumbnailService.image(for: url,
                                      maximumSize: maximumSize,
                                      completion: closure)
    }
        
    //MARK: 设置图片透明度
    ///设置图片透明度
    /// - Parameters:
    ///  - alpha: 透明度
    /// - Returns: newImage
    func imageByApplayingAlpha(_ alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(base.size)
        let context = UIGraphicsGetCurrentContext()
        let area = CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height)
        context?.scaleBy(x: 1, y: -1)
        context?.translateBy(x: 0, y: -area.height)
        context?.setBlendMode(.multiply)
        context?.setAlpha(alpha)
        if let image = base.cgImage {
            context?.draw(image, in: area)
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? base
    }
    
    //MARK: 更改图片颜色
    ///更改图片颜色
    /// - Parameters:
    ///   - color: 图片颜色
    ///   - blendMode: 模式
    /// - Returns: 返回更改后的图片颜色
    func tint(color: UIColor,
              blendMode: CGBlendMode = .destinationIn) -> UIImage? {
        /**
         有时我们的App需要能切换不同的主题和场景，希望图片能动态的改变颜色以配合对应场景的色调。虽然我们可以根据不同主题事先创建不同颜色的图片供调用，但既然用的图片素材都一样，还一个个转换显得太麻烦，而且不便于维护。使用blendMode变可以满足这个需求。
         */
        defer {
            UIGraphicsEndImageContext()
        }
        let drawRect = CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height)
        UIGraphicsBeginImageContextWithOptions(base.size, false, base.scale)
        color.setFill()
        UIRectFill(drawRect)
        base.draw(in: drawRect, blendMode: CGBlendMode.destinationIn, alpha: 1.0)
        guard let tintedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        return tintedImage
    }
    
    //MARK: 保存图片到相册
    ///保存图片到相册
    @available(*, deprecated, message: "Use PTMediaSaveService.save(image:completion:) instead")
    func savePhotosImageToAlbum(completion: @escaping @Sendable (Bool, Error?) -> Void) {
        Task { @MainActor in
            PTMediaSaveService.save(image: base) { result in
                switch result {
                case .success:
                    completion(true, nil)
                case .failure(let error):
                    completion(false, error)
                }
            }
        }
    }
    
    @available(*, deprecated, message: "Use PTMediaSaveService.save(image:completion:) instead")
    func saveImageToAlbum(completion: @escaping @Sendable (String?) -> Void) {
        Task { @MainActor in
            PTMediaSaveService.save(image: base) { result in
                switch result {
                case .success(let asset):
                    completion(asset.localIdentifier)
                case .failure:
                    completion(nil)
                }
            }
        }
    }
    
    static func getAssetURL(from localIdentifier: String, completion: @escaping (URL?) -> Void) {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = result.firstObject else {
            completion(nil)
            return
        }

        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true // 允許從 iCloud 下載

        asset.requestContentEditingInput(with: options) { input, _ in
            completion(input?.fullSizeImageURL)
        }
    }
    
    /// 保存圖片到相簿，並回傳 `PHAsset`
    @available(*, deprecated, message: "Use PTMediaSaveService.save(image:completion:) instead")
    func saveImageToAlbum(completion: @escaping @Sendable (PHAsset?) -> Void) {
        Task { @MainActor in
            PTMediaSaveService.save(image: base) { result in
                switch result {
                case .success(let asset):
                    completion(asset)
                case .failure:
                    completion(nil)
                }
            }
        }
    }

    
    /// 加马赛克
    @MainActor func mosaicImage() -> UIImage? {
        guard let cgImage = base.cgImage else {
            return nil
        }
        
        let scale = 8 * base.size.width / UIScreen.main.bounds.width
        let currCiImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(currCiImage, forKey: kCIInputImageKey)
        filter?.setValue(scale, forKey: kCIInputScaleKey)
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        
        if let cgImage = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: base.size)) {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }

    func toCIImage() -> CIImage? {
        var ciImage = base.ciImage
        if ciImage == nil, let cgImage = base.cgImage {
            ciImage = CIImage(cgImage: cgImage)
        }
        return ciImage
    }

    func blurImage(level: CGFloat) -> UIImage? {
        guard let ciImage = toCIImage() else {
            return nil
        }
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
                
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(level, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: base.scale, orientation: base.imageOrientation)
    }
    
    func clipImage(angle: CGFloat, editRect: CGRect, isCircle: Bool) -> UIImage {
        let a = ((Int(angle) % 360) - 360) % 360
        var newImage: UIImage = base
        if a == -90 {
            newImage = rotate(orientation: .left)
        } else if a == -180 {
            newImage = rotate(orientation: .down)
        } else if a == -270 {
            newImage = rotate(orientation: .right)
        }
        guard editRect.size != newImage.size else {
            return newImage
        }
        
        let origin = CGPoint(x: -editRect.minX, y: -editRect.minY)
        
        let temp = UIGraphicsImageRenderer.pt.renderImage(size: editRect.size) { format in
            format.scale = newImage.scale
        } imageActions: { context in
            if isCircle {
                context.addEllipse(in: CGRect(origin: .zero, size: editRect.size))
                context.clip()
            }
            newImage.draw(at: origin)
        }
        
        guard let cgi = temp.cgImage else { return temp }
        
        let clipImage = UIImage(cgImage: cgi, scale: newImage.scale, orientation: .up)
        return clipImage
    }

    /// 旋转方向
    func rotate(orientation: UIImage.Orientation) -> UIImage {
        guard let imagRef = base.cgImage else {
            return base
        }
        let rect = CGRect(origin: .zero, size: CGSize(width: CGFloat(imagRef.width), height: CGFloat(imagRef.height)))
        
        var bnds = rect
        
        var transform = CGAffineTransform.identity
        
        switch orientation {
        case .up:
            return base
        case .upMirrored:
            transform = transform.translatedBy(x: rect.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .down:
            transform = transform.translatedBy(x: rect.width, y: rect.height)
            transform = transform.rotated(by: .pi)
        case .downMirrored:
            transform = transform.translatedBy(x: 0, y: rect.height)
            transform = transform.scaledBy(x: 1, y: -1)
        case .left:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: 0, y: rect.width)
            transform = transform.rotated(by: CGFloat.pi * 3 / 2)
        case .leftMirrored:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: rect.height, y: rect.width)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: CGFloat.pi * 3 / 2)
        case .right:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: rect.height, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .rightMirrored:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: CGFloat.pi / 2)
        @unknown default:
            return base
        }
        
        UIGraphicsBeginImageContext(bnds.size)
        let context = UIGraphicsGetCurrentContext()
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.scaleBy(x: -1, y: 1)
            context?.translateBy(x: -rect.height, y: 0)
        default:
            context?.scaleBy(x: 1, y: -1)
            context?.translateBy(x: 0, y: -rect.height)
        }
        context?.concatenate(transform)
        context?.draw(imagRef, in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? base
    }

    func swapRectWidthAndHeight(_ rect: CGRect) -> CGRect {
        var r = rect
        r.size.width = rect.height
        r.size.height = rect.width
        return r
    }

    func fixOrientation() -> UIImage {
        if base.imageOrientation == .up {
            return base
        }
        
        var transform = CGAffineTransform.identity
        
        switch base.imageOrientation {
        case .down, .downMirrored:
            transform = CGAffineTransform(translationX: base.size.width, y: base.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = CGAffineTransform(translationX: base.size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .right, .rightMirrored:
            transform = CGAffineTransform(translationX: 0, y: base.size.height)
            transform = transform.rotated(by: -CGFloat.pi / 2)
        default:
            break
        }
        
        switch base.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: base.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: base.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let cgImage = base.cgImage, let colorSpace = cgImage.colorSpace else {
            return base
        }
        let context = CGContext(
            data: nil,
            width: Int(base.size.width),
            height: Int(base.size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )
        context?.concatenate(transform)
        switch base.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: base.size.height, height: base.size.width))
        default:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height))
        }
        
        guard let newCgImage = context?.makeImage() else {
            return base
        }
        return UIImage(cgImage: newCgImage)
    }

    /// Resize image. Processing speed is better than resize(:) method
    /// - Parameters:
    ///   - size: Dest size of the image
    ///   - scale: The scale factor of the image
    func resize_vI(_ size: CGSize, scale: CGFloat? = nil) -> UIImage? {
        guard let cgImage = base.cgImage else { return nil }
        
        var format = vImage_CGImageFormat(bitsPerComponent: 8,
                                          bitsPerPixel: 32,
                                          colorSpace: nil,
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: .defaultIntent)
        
        var sourceBuffer = vImage_Buffer()
        defer {
            sourceBuffer.free()
        }
        
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }
        
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let destBytesPerRow = destWidth * bytesPerPixel
        
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
        
        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }
        
        // create a CGImage from vImage_Buffer
        guard let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue() else { return nil }
        guard error == kvImageNoError else { return nil }
        
        // create a UIImage
        return UIImage(cgImage: destCGImage, scale: scale ?? base.scale, orientation: base.imageOrientation)
    }


    func hasAlphaChannel() -> Bool {
        guard let info = base.cgImage?.alphaInfo else {
            return false
        }
        
        return info == .first || info == .last || info == .premultipliedFirst || info == .premultipliedLast
    }

    @MainActor
    static func animateGifImage(data: Data) -> UIImage? {
        // Kingfisher
        let info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: UTType.gif
        ]

        guard let imageSource = CGImageSourceCreateWithData(data as CFData, info as CFDictionary) else {
            return UIImage(data: data)
        }

        var frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 1 else {
            return UIImage(data: data)
        }

        var maxFrameCount = 50
        #if POOTOOLS_IMAGEEDITOR
        maxFrameCount = PTImageEditorConfig.share.maxFrameCountForGIF
        #endif
        
        let ratio = CGFloat(max(frameCount, maxFrameCount)) / CGFloat(maxFrameCount)
        frameCount = min(frameCount, maxFrameCount)

        var images = [UIImage]()
        var frameDuration = [Int]()

        for i in 0..<frameCount {
            let index = Int(floor(CGFloat(i) * ratio))

            guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, info as CFDictionary) else {
                return nil
            }

            // Get current animated GIF frame duration
            let currFrameDuration = getFrameDuration(from: imageSource, at: index) * min(ratio, 3)
            // Second to ms
            frameDuration.append(Int(currFrameDuration * 1000))

            images.append(UIImage(cgImage: imageRef, scale: 1, orientation: .up))
        }
        var sum = 0
        for val in frameDuration {
            sum += val
        }

        let duration: Int = sum

        // 求出每一帧的最大公约数
        let gcd = gcdForArray(frameDuration)
        var frames = [UIImage]()

        for i in 0..<frameCount {
            let frameImage = images[i]
            // 每张图片的时长除以最大公约数，得出需要展示的张数
            let count = Int(frameDuration[i] / gcd)

            for _ in 0..<count {
                frames.append(frameImage)
            }
        }

        return .animatedImage(with: frames, duration: TimeInterval(duration) / 1000)
    }

    /// Calculates frame duration at a specific index for a gif from an `imageSource`.
    static func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
            as? [String: Any] else { return 0.0 }

        let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        return getFrameDuration(from: gifInfo)
    }
    
    /// Calculates frame duration for a gif frame out of the kCGImagePropertyGIFDictionary dictionary.
    static func getFrameDuration(from gifInfo: [String: Any]?) -> TimeInterval {
        let defaultFrameDuration = 0.1
        guard let gifInfo = gifInfo else { return defaultFrameDuration }
        
        let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let duration = unclampedDelayTime ?? delayTime
        
        guard let frameDuration = duration else {
            return defaultFrameDuration
        }
        return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : defaultFrameDuration
    }

    private static func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }

        var gcd = array[0]

        for val in array {
            gcd = gcdForPair(val, gcd)
        }

        return gcd
    }

    private static func gcdForPair(_ num1: Int?, _ num2: Int?) -> Int {
        guard var num1 = num1, var num2 = num2 else {
            return num1 ?? (num2 ?? 0)
        }
        
        if num1 < num2 {
            swap(&num1, &num2)
        }

        var rest: Int
        while true {
            rest = num1 % num2

            if rest == 0 {
                return num2
            } else {
                num1 = num2
                num2 = rest
            }
        }
    }
}

//MARK: 压缩模式
public enum CompressionMode: Sendable {
    /// 分辨率规则
    private static let resolutionRule: (min: CGFloat, max: CGFloat, low: CGFloat, default: CGFloat, high: CGFloat) = (10, 4096, 512, 1024, 2048)
    /// 数据大小规则
    private static let  dataSizeRule: (min: Int, max: Int, low: Int, default: Int, high: Int) = (1024 * 10, 1024 * 1024 * 20, 1024 * 512, 1024 * 1024 * 2, 1024 * 1024 * 10)
    // 低质量
    case low
    // 中等质量 默认
    case medium
    // 高质量
    case high
    // 自定义(最大分辨率, 最大输出数据大小)
    case other(CGFloat, Int)
    
    fileprivate var maxDataSize: Int {
        switch self {
        case .low:
            return CompressionMode.dataSizeRule.low
        case .medium:
            return CompressionMode.dataSizeRule.default
        case .high:
            return CompressionMode.dataSizeRule.high
        case .other(_, let dataSize):
            if dataSize < CompressionMode.dataSizeRule.min {
                return CompressionMode.dataSizeRule.default
            }
            if dataSize > CompressionMode.dataSizeRule.max {
                return CompressionMode.dataSizeRule.max
            }
            return dataSize
        }
    }
    
    fileprivate func resize(_ size: CGSize) -> CGSize {
        if size.width < CompressionMode.resolutionRule.min || size.height < CompressionMode.resolutionRule.min {
            return size
        }
        let maxResolution = maxSize
        let aspectRatio = max(size.width, size.height) / maxResolution
        if aspectRatio <= 1.0 {
            return size
        } else {
            let resizeWidth = size.width / aspectRatio
            let resizeHeighth = size.height / aspectRatio
            if resizeHeighth < CompressionMode.resolutionRule.min || resizeWidth < CompressionMode.resolutionRule.min {
                return size
            } else {
                return CGSize(width: resizeWidth, height: resizeHeighth)
            }
        }
    }
    
    fileprivate var maxSize: CGFloat {
        switch self {
        case .low:
            return CompressionMode.resolutionRule.low
        case .medium:
            return CompressionMode.resolutionRule.default
        case .high:
            return CompressionMode.resolutionRule.high
        case .other(let size, _):
            if size < CompressionMode.resolutionRule.min {
                return CompressionMode.resolutionRule.default
            }
            if size > CompressionMode.resolutionRule.max {
                return CompressionMode.resolutionRule.max
            }
            return size
        }
    }
}

//MARK: UIImage 压缩相关
public extension PTPOP where Base: UIImage {
    //MARK: 压缩图片
    ///压缩图片
    /// - Parameters:
    ///  - mode: 压缩模式
    /// - Returns: 压缩后Data
    func compress(mode: CompressionMode = .medium) -> Data? {
        resizeIO(resizeSize: mode.resize(base.size))?.pt.compressDataSize(maxSize: mode.maxDataSize)
    }
    
    //MARK: 异步图片压缩
    ///异步图片压缩
    /// - Parameters:
    ///   - mode: 压缩模式
    ///   - queue: 压缩队列
    ///   - complete: 完成回调(压缩后Data, 调整后分辨率)
    func asyncCompress(mode: CompressionMode = .medium,
                       queue: DispatchQueue = DispatchQueue.global(),
                       complete:@escaping @Sendable (Data?, CGSize) -> Void) {
        queue.async {
            let data = resizeIO(resizeSize: mode.resize(base.size))?.pt.compressDataSize(maxSize: mode.maxDataSize)
            PTGCDManager.shared.runOnMain {
                complete(data, mode.resize(base.size))
            }
        }
    }
    
    //MARK: 压缩图片质量
    ///压缩图片质量
    /// - Parameters:
    ///  - maxSize: 最大数据大小
    /// - Returns: 压缩后数据
    func compressDataSizeAsync(maxSize: Int = 1024 * 1024 * 2) async -> Data? {
        return await withCheckedContinuation { continuation in
            PTGCDManager.shared.runOnBackground {
                let compressed = self.base.pt.compressDataSize(maxSize: maxSize)
                continuation.resume(returning: compressed)
            }
        }
    }
    
    func compressDataSize(maxSize: Int = 1024 * 1024 * 2) -> Data? {
        var compression: CGFloat = 1
        guard var data = base.jpegData(compressionQuality: 1) else { return nil }
        if data.count < maxSize {
            return data
        }
        var max: CGFloat = 1
        var min: CGFloat = 0
        var count = 0
        for _ in 0..<6 {
            count = count + 1
            compression = (max + min) / 2
            guard let compressedData = base.jpegData(compressionQuality: compression) else {
                return nil
            }
            data = compressedData
            if CGFloat(data.count) < CGFloat(maxSize) * 0.9 {
                min = compression
            } else if data.count > maxSize {
                max = compression
            } else {
                break
            }
        }
        if data.count < maxSize {
            return data
        }
        return cycleCompressDataSize(maxSize: maxSize)
    }
    
    //MARK: 循环压缩
    ///循环压缩
    /// - Parameter maxSize: 最大数据大小
    /// - Returns: 压缩后数据
    private func cycleCompressDataSize(maxSize: Int) -> Data? {
        guard let oldData = base.jpegData(compressionQuality: 1) else { return nil }
        if oldData.count < maxSize {
            return oldData
        }
        var compress: CGFloat = 0.9
        guard var data = base.jpegData(compressionQuality: compress) else { return nil }
        while data.count > maxSize && compress > 0.01 {
            compress -= 0.02
            guard let compressedData = base.jpegData(compressionQuality: compress) else {
                return data
            }
            data = compressedData
        }
        return data
    }
    
    //MARK: ImageIO 方式调整图片大小 性能很好
    ///ImageIO 方式调整图片大小 性能很好
    /// - Parameters:
    ///  - resizeSize: 图片调整Size
    /// - Returns: 调整后图片
    func resizeIO(resizeSize: CGSize) -> UIImage? {
        if base.size == resizeSize {
            return base
        }
        guard let imageData = base.pngData() else { return nil }
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
        
        let maxPixelSize = max(base.size.width, base.size.height)
        let options = [kCGImageSourceCreateThumbnailWithTransform: true,
                   kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                              kCGImageSourceThumbnailMaxPixelSize: maxPixelSize] as [CFString : Any]
        
        let resizedImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary).flatMap{
            UIImage(cgImage: $0)
        }
        return resizedImage
    }
    
    //MARK: CoreGraphics 方式调整图片大小 性能很好
    ///CoreGraphics 方式调整图片大小 性能很好
    /// - Parameters:
    ///  - resizeSize: 图片调整Size
    /// - Returns: 调整后图片
    func resizeCG(resizeSize: CGSize) -> UIImage? {
        if base.size == resizeSize {
            return base
        }
        guard  let cgImage = base.cgImage else { return nil }
        guard  let colorSpace = cgImage.colorSpace else { return nil }
        guard let context = CGContext(data: nil,
                                      width: Int(resizeSize.width),
                                      height: Int(resizeSize.height),
                                      bitsPerComponent: cgImage.bitsPerComponent,
                                      bytesPerRow: cgImage.bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: cgImage.bitmapInfo.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: resizeSize))
        let resizedImage = context.makeImage().flatMap {
            UIImage(cgImage: $0)
        }
        return resizedImage
    }
}

public extension PTPOP where Base: CIImage {
    func toUIImage() -> UIImage? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(base, from: base.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

#endif
