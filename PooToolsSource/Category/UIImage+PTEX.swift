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

extension UIImage : PTProtocolCompatible {}
extension CIImage : PTProtocolCompatible {}

public extension UIImage {
    
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        defer {
            UIGraphicsEndImageContext()
        }
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        guard let aCgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            self.init()
            return
        }
        self.init(cgImage: aCgImage)
    }
    
    static func darkModeImage(light: UIImage, dark: UIImage) -> UIImage {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return dark
        } else {
            return light
        }
   }

    static func system(_ name: String) -> UIImage {
        UIImage.init(systemName: name) ?? UIImage()
    }
    
    static func system(_ name: String, pointSize: CGFloat, weight: UIImage.SymbolWeight) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        return UIImage(systemName: name, withConfiguration: configuration) ?? UIImage()
    }
    
    static func system(_ name: String, font: UIFont) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(font: font)
        return UIImage(systemName: name, withConfiguration: configuration) ?? UIImage()
    }

    var bytesSize: Int { jpegData(compressionQuality: 1)?.count ?? .zero }
    var kilobytesSize: Int { (jpegData(compressionQuality: 1)?.count ?? .zero) / 1024 }
    
    func compresse(quality: CGFloat) -> UIImage? {
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
    
    fileprivate func resize(targetSize: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    #endif

    //MARK: 更改圖片大小
    ///更改圖片大小
    @objc func transformImage(size:CGSize)->UIImage {
        if #available(iOS 15.0, *) {
            if isSymbolImage {
                return resize(targetSize: size)
            } else {
                return preparingThumbnail(of: size) ?? resize(targetSize: size)
            }
        } else {
            if isSymbolImage {
                return resize(targetSize: size)
            } else {
                return transform(size: CGSize.init(width: size.width, height: size.height))
            }
        }
    }
    
    private func transform(size:CGSize)->UIImage {
        let destW = size.width
        let destH = size.height
        let sourceW = size.width
        let sourceH = size.height
        
        let imageRef = cgImage
        let bitmap:CGContext = CGContext(data: nil , width: Int(destW), height: Int(destH), bitsPerComponent: (imageRef?.bitsPerComponent)!, bytesPerRow: 4 * Int(destW), space: (imageRef?.colorSpace)!, bitmapInfo: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue))!
        
        bitmap.draw(imageRef!, in: CGRect.init(x: 0, y: 0, width: sourceW, height: sourceH))
        
        let ref = bitmap.makeImage()
        let resultImage = UIImage.init(cgImage: ref!)
        return resultImage
    }
    
    //MARK: 圖片高斯模糊
    ///圖片高斯模糊
    @objc func blurImage()->UIImage {
        img(alpha: 0.1, radius: 10, colorSaturationFactor: 1)
    }
    
    /*
     1.白色,参数:
     透明度 0~1,  0为白,   1为深灰色
     半径:默认30,推荐值 3   半径值越大越模糊 ,值越小越清楚
     色彩饱和度(浓度)因子:  0是黑白灰, 9是浓彩色, 1是原色  默认1.8
     “彩度”，英文是称Saturation，即饱和度。将无彩色的黑白灰定为0，最鲜艳定为9s，这样大致分成十阶段，让数值和人的感官直觉一致。
     */
    func img(alpha:Float,
             radius:Float,
             colorSaturationFactor:Float)->UIImage {
        let tintColor = UIColor.init(white: 1, alpha: CGFloat(alpha))
        return imgBluredWithRadius(blurRadius: radius, tintColor: tintColor, saturationDeltaFactor: colorSaturationFactor, maskImage: nil)
    }
    
    func imgBluredWithRadius(blurRadius:Float,
                             tintColor:UIColor?,
                             saturationDeltaFactor:Float,
                             maskImage:UIImage?)->UIImage {
        let imageRect = CGRect.init(origin: .zero, size: size)
        var effectImage = self
        let hadBlur = blurRadius > Float.ulpOfOne
        let hasSaturationChange = abs(saturationDeltaFactor - 1) > Float.ulpOfOne
        if hadBlur || hasSaturationChange {
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            let effectContext = UIGraphicsGetCurrentContext()
            effectContext!.scaleBy(x: 1,y: -1)
            effectContext!.translateBy(x: 0, y: -size.height)
            effectContext!.draw(cgImage!, in: imageRect)
            
            var effectInBuffer = vImage_Buffer()
            effectInBuffer.data = effectContext!.data
            effectInBuffer.width = vImagePixelCount(effectContext!.width)
            effectInBuffer.height = vImagePixelCount(effectContext!.height)
            effectInBuffer.rowBytes = effectContext!.bytesPerRow
            
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            let effectOutContext = UIGraphicsGetCurrentContext()
            var effectOutBuffer = vImage_Buffer()
            effectOutBuffer.data = effectOutContext!.data
            effectOutBuffer.width = vImagePixelCount(effectOutContext!.width)
            effectOutBuffer.height = vImagePixelCount(effectOutContext!.height)
            effectOutBuffer.rowBytes = effectOutContext!.bytesPerRow
            
            //            var redPointer = [0xFF,0x00,0x00]
            if hadBlur {
                let inputRadius = blurRadius * Float(UIScreen.main.scale)
                let sqartReslut = sqrt(2 * Double.pi)
                var radius:NSInteger = NSInteger(floor(Double(inputRadius) * 3.0 * sqartReslut / 4.0 + 0.5))
                if radius % 2 != 1 {
                    radius += 1
                }
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, UInt32(radius), UInt32(radius), nil, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, nil, 0, 0, UInt32(radius), UInt32(radius), nil, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, UInt32(radius), UInt32(radius), nil, vImage_Flags(kvImageEdgeExtend))
            }
            
            var effectImageBuffersAreSwapped = false
            if hasSaturationChange {
                let s = saturationDeltaFactor
                let floatingPointSaturationMatrix = [0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                                                     0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                                                     0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                                                     0,                    0,                    0,  1]
                let divesor : Int32 = 256
                let matrixSize = MemoryLayout.size(ofValue: floatingPointSaturationMatrix) / MemoryLayout.size(ofValue: floatingPointSaturationMatrix[0])
                var saturationMatrix = [Int16]()
                
                for i in 0...(matrixSize - 1) {
                    saturationMatrix[i] = Int16(roundf(floatingPointSaturationMatrix[i] * Float(divesor)))
                }
                
                if hadBlur {
                    vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, &saturationMatrix, divesor, nil,nil, vImage_Flags(kvImageNoFlags))
                    effectImageBuffersAreSwapped = true
                } else {
                    vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, &saturationMatrix, divesor, nil,nil, vImage_Flags(kvImageNoFlags))
                }
                
                if !effectImageBuffersAreSwapped {
                    effectImage = UIGraphicsGetImageFromCurrentImageContext()!
                    UIGraphicsEndImageContext()
                } else {
                    effectImage = UIGraphicsGetImageFromCurrentImageContext()!
                    UIGraphicsEndImageContext()
                }
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let outputContext = UIGraphicsGetCurrentContext()
        outputContext?.scaleBy(x: 1, y: -1)
        outputContext?.translateBy(x: 0, y: -size.height)
        outputContext?.draw(cgImage!, in: imageRect)
        
        if hadBlur {
            outputContext?.saveGState()
            if maskImage != nil {
                outputContext?.clip(to: imageRect, mask: (maskImage?.cgImage)!)
            }
            outputContext?.draw(cgImage!, in: imageRect)
            outputContext?.restoreGState()
        }
        
        if tintColor != nil {
            outputContext?.saveGState()
            outputContext?.setFillColor(tintColor!.cgColor)
            outputContext?.fill(imageRect)
            outputContext?.restoreGState()
        }
        
        effectImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return effectImage
    }
    
    //MARK: 加水印
    ///加水印
    @objc func watermark(title:String,
                         font:UIFont = UIFont.systemFont(ofSize: 23),
                         color:UIColor?) -> UIImage {
        let originalImage = self
        
        let HORIZONTAL_SPACE = 30
        let VERTICAL_SPACE = 50
        
        let viewWidth = originalImage.size.width
        let viewHeight = originalImage.size.height
        
        let newColor = (color == nil) ? originalImage.imageMostColor() : color
        
        UIGraphicsBeginImageContext(CGSize.init(width: viewWidth, height: viewHeight))
        originalImage.draw(in: CGRect.init(x: 0, y: 0, width: viewWidth, height: viewHeight))
        let sqrtLength = sqrt(viewWidth * viewWidth + viewHeight * viewHeight)
        let attr = [NSAttributedString.Key.font:font,NSAttributedString.Key.foregroundColor:newColor!]
        let mark : NSString = title as NSString
        let strWidth = UIView.sizeFor(string: title, font: font).width
        let strHeight = UIView.sizeFor(string: title, font: font).height
        let context = UIGraphicsGetCurrentContext()!
        context.concatenate(CGAffineTransform(translationX: viewWidth/2, y: viewHeight/2))
        context.concatenate(CGAffineTransform(rotationAngle: (Double.pi / 2 / 3)))
        context.concatenate(CGAffineTransform(translationX: -viewWidth/2, y: -viewHeight/2))
        
        let horCount : Int = Int(sqrtLength / (strWidth + CGFloat(HORIZONTAL_SPACE)) + 1)
        let verCount : Int = Int(sqrtLength / (strHeight + CGFloat(VERTICAL_SPACE)) + 1)
        
        let orignX = -(sqrtLength - viewWidth)/2
        let orignY = -(sqrtLength - viewHeight)/2
        
        var tempOrignX = orignX
        var tempOrignY = orignY
        
        let totalCount : Int = Int(horCount * verCount)
        for i in 0...totalCount {
            mark.draw(in: CGRect.init(x: tempOrignX, y: tempOrignY, width: strWidth, height: strHeight), withAttributes: attr)
            if i % horCount == 0 && i != 0 {
                tempOrignX = orignX
                tempOrignY += (strHeight + CGFloat(VERTICAL_SPACE))
            } else {
                tempOrignX += (strWidth + CGFloat(HORIZONTAL_SPACE))
            }
        }
        
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        context.restoreGState()
        return finalImg
    }
    
    func imageScale(scaleSize:CGFloat)->UIImage {
        UIGraphicsBeginImageContext(CGSize(width: size.width * scaleSize, height: size.height * scaleSize))
        self.draw(in: CGRect(x: 0, y: 0, width: size.width * scaleSize, height: size.height * scaleSize))
        UIGraphicsEndImageContext()
        return self
    }
    
    func imageMask(text:NSString,
                   point:CGPoint,
                   attributed:NSDictionary)->UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        text.draw(at: point,withAttributes: (attributed as! [NSAttributedString.Key : Any]))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func imageMask(maskImage:UIImage,
                   maskRect:CGRect)->UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        maskImage.draw(in: maskRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    //MARK: 獲取圖片中大部分占有的顏色
    ///獲取圖片中大部分占有的顏色
    @objc func imageMostColor()->UIColor {
        let context = getImageContext()
        
        let newImgData = unsafeBitCast(context.data, to: UnsafeMutablePointer<CUnsignedChar>.self)
        
        let cls = NSCountedSet.init(capacity: Int(size.width * size.height))
        for i in 0...Int(size.width) {
            for j in 0...Int(size.height) {
                let offSet = 4 * (i * j)
                let red = (newImgData + offSet).pointee
                let green = (newImgData + (offSet + 1)).pointee
                let blue = (newImgData + (offSet + 2)).pointee
                let alpha = (newImgData + (offSet + 3)).pointee
                if alpha > 0 {
                    if red == 255 && green == 255 && blue == 255 {
                        
                    } else {
                        let clr = [red,green,blue,alpha]
                        cls.add(clr)
                    }
                }
            }
        }
        
        var maxColor:NSArray? = nil
        let enumerator = cls.enumerated()
        enumerator.forEach { index,value in
            maxColor = (value as! NSArray)
        }
        
        return UIColor(red: maxColor![0] as! CGFloat / 255, green: maxColor![1] as! CGFloat / 255, blue: maxColor![2] as! CGFloat / 255, alpha: maxColor![3] as! CGFloat / 255)
    }
    
    //MARK: 獲取圖片中某個像素點的顏色
    ///獲取圖片中某個像素點的顏色
    func getImgePointColor(point:CGPoint)->UIColor {
        let context = getImageContext()
        
        let newImgData = unsafeBitCast(context.data, to: UnsafeMutablePointer<CUnsignedChar>.self)
        
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
    
    func getImageContext()-> CGContext {
        let currentImage = cgImage ?? UIColor.red.createImageWithColor().transformImage(size: CGSize(width: 100, height: 100)).cgImage!
        
        let bitmapInfo = CGBitmapInfo.byteOrderDefault.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let thumbSize = CGSize(width: size.width, height: size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext.init(data: nil, width: Int(thumbSize.width), height: Int(thumbSize.height), bitsPerComponent: 8, bytesPerRow: Int(thumbSize.width) * 4, space: colorSpace, bitmapInfo: bitmapInfo)
        
        let drawRect = CGRect(x: 0, y: 0, width: thumbSize.width, height: thumbSize.height)
        context?.draw(currentImage, in: drawRect)
        return context!
    }
    
    //MARK: 把圖片換成圓形
    ///把圖片換成圓形
    @objc func circularImage() -> UIImage? {
        let imageSize = CGSize(width: self.size.width, height: self.size.height)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        let _ = UIGraphicsGetCurrentContext()!

        let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: imageSize))
        circlePath.addClip()

        self.draw(in: CGRect(origin: .zero, size: imageSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
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
    @objc func ckeckImageSizeLargerThan(byteSize: Int) -> Bool {
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
}

public extension PTPOP where Base: UIImage {
    //MARK: 设置图片的圆角
    ///设置图片的圆角
    /// - Parameters:
    ///   - radius: 圆角大小 (默认:3.0,图片大小)
    ///   - corners: 切圆角的方式
    ///   - imageSize: 图片的大小
    /// - Returns: 剪切后的图片
    func isRoundCorner(radius: CGFloat = 3,
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
                                   closure: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: videoUrl) else {
            closure(nil)
            return
        }
        
        PTGCDManager.gcdGobalNormal {
            let opts = [AVURLAssetPreferPreciseDurationAndTimingKey: false]
            let avAsset = AVURLAsset(url: url, options: opts)
            let generator = AVAssetImageGenerator(asset: avAsset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = maximumSize
            var cgImage: CGImage? = nil
            let time = CMTimeMake(value: 0, timescale: 600)
            var actualTime : CMTime = CMTimeMake(value: 0, timescale: 0)
            do {
                try cgImage = generator.copyCGImage(at: time, actualTime: &actualTime)
                guard let image = cgImage else {
                    PTGCDManager.gcdMain {
                        closure(nil)
                    }
                    return
                }
                PTGCDManager.gcdMain {
                    closure(UIImage(cgImage: image))
                }
            } catch {
                PTGCDManager.gcdMain {
                    closure(nil)
                }
                return
            }
        }
    }
    
    //MARK: 获取视频的第一帧
    ///获取视频的第一帧
    /// - Parameters:
    ///   - asset: AVAsset
    ///   - maximumSize: 图片的最大尺寸
    ///   - closure:
    /// - Returns: 视频的第一帧
    static func getVideoFirstImage(asset: AVAsset,
                                   maximumSize: CGSize = CGSize(width: 1000, height: 1000),
                                   closure: @escaping (UIImage?) -> Void) {
        PTGCDManager.gcdGobalNormal {
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = maximumSize
            var cgImage: CGImage? = nil
            let time = CMTimeMake(value: 0, timescale: 600)
            var actualTime : CMTime = CMTimeMake(value: 0, timescale: 0)
            do {
                try cgImage = generator.copyCGImage(at: time, actualTime: &actualTime)
                guard let image = cgImage else {
                    PTGCDManager.gcdMain {
                        closure(nil)
                    }
                    return
                }
                PTGCDManager.gcdMain {
                    closure(UIImage(cgImage: image))
                }
            } catch {
                PTGCDManager.gcdMain {
                    closure(nil)
                }
                return
            }
        }
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
        context?.draw(base.cgImage!, in: area)
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
    func savePhotosImageToAlbum(completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: base)
        } completionHandler: { (isSuccess: Bool, error: Error?) in
            completion(isSuccess, error)
        }
    }
    
    /// 加马赛克
    func mosaicImage() -> UIImage? {
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
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: "inputImage")
        blurFilter?.setValue(level, forKey: "inputRadius")
        
        guard let outputImage = blurFilter?.outputImage else {
            return nil
        }
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
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
        
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: nil,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
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

    static func animateGifImage(data: Data) -> UIImage? {
        // Kingfisher
        let info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
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
public enum CompressionMode {
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
                       complete:@escaping (Data?, CGSize) -> Void) {
        queue.async {
            let data = resizeIO(resizeSize: mode.resize(base.size))?.pt.compressDataSize(maxSize: mode.maxDataSize)
            PTGCDManager.gcdMain {
                complete(data, mode.resize(base.size))
            }
        }
    }
    
    //MARK: 压缩图片质量
    ///压缩图片质量
    /// - Parameters:
    ///  - maxSize: 最大数据大小
    /// - Returns: 压缩后数据
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
            data = base.jpegData(compressionQuality: compression)!
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
            data = base.jpegData(compressionQuality: compress)!
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

/*
  GIF
 */
public extension UIImage {
    /// Convenience initializer. Creates a gif with its backing data.
    ///
    /// - Parameter imageData: The actual image data, can be GIF or some other format
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    convenience init?(imageData:Data, levelOfIntegrity: PTGifLevelOfIntegrity = .default) throws {
        do {
            try self.init(gifData: imageData, levelOfIntegrity: levelOfIntegrity)
        } catch {
            self.init(data: imageData)
        }
    }

    /// Convenience initializer. Creates a image with its backing data.
    ///
    /// - Parameter imageName: Filename
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    convenience init?(imageName: String, levelOfIntegrity: PTGifLevelOfIntegrity = .default, bundle: Bundle = Bundle.main) throws {
        self.init()

        do {
            try setGif(imageName, levelOfIntegrity: levelOfIntegrity, bundle: bundle)
        } catch {
            self.init(named: imageName)
        }
    }
}

// MARK: - Inits

public extension UIImage {
    
    /// Convenience initializer. Creates a gif with its backing data.
    ///
    /// - Parameter gifData: The actual gif data
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    convenience init(gifData:Data, levelOfIntegrity: PTGifLevelOfIntegrity = .default) throws {
        self.init()
        try setGifFromData(gifData, levelOfIntegrity: levelOfIntegrity)
    }
    
    /// Convenience initializer. Creates a gif with its backing data.
    ///
    /// - Parameter gifName: Filename
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    convenience init(gifName: String, levelOfIntegrity: PTGifLevelOfIntegrity = .default, bundle: Bundle = Bundle.main) throws {
        self.init()
        try setGif(gifName, levelOfIntegrity: levelOfIntegrity, bundle: bundle)
    }
    
    /// Set backing data for this gif. Overwrites any existing data.
    ///
    /// - Parameter data: The actual gif data
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    func setGifFromData(_ data: Data, levelOfIntegrity: PTGifLevelOfIntegrity) throws {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
        self.imageSource = imageSource
        imageData = data
        
        calculateFrameDelay(try delayTimes(imageSource), levelOfIntegrity: levelOfIntegrity)
        calculateFrameSize()
    }
    
    /// Set backing data for this gif. Overwrites any existing data.
    ///
    /// - Parameter name: Filename
    func setGif(_ name: String, bundle: Bundle = Bundle.main) throws {
        try setGif(name, levelOfIntegrity: .default, bundle: bundle)
    }
    
    /// Check the number of frame for this gif
    ///
    /// - Return number of frames
    func framesCount() -> Int {
        return displayOrder?.count ?? 0
    }
    
    /// Set backing data for this gif. Overwrites any existing data.
    ///
    /// - Parameter name: Filename
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    func setGif(_ name: String, levelOfIntegrity: PTGifLevelOfIntegrity, bundle: Bundle = Bundle.main) throws {
        if let url = bundle.url(forResource: name, withExtension: name.pathExtension() == "gif" ? "" : "gif") {
            if let data = try? Data(contentsOf: url) {
                try setGifFromData(data, levelOfIntegrity: levelOfIntegrity)
            }
        } else {
            throw PTGifParseError.invalidFilename
        }
    }
    
    func clear() {
        imageData = nil
        imageSource = nil
        displayOrder = nil
        imageCount = nil
        imageSize = nil
        displayRefreshFactor = nil
    }
    
    // MARK: Logic
    
    private func convertToDelay(_ pointer:UnsafeRawPointer?) -> Float? {
        if pointer == nil {
            return nil
        }
        
        return unsafeBitCast(pointer, to:AnyObject.self).floatValue
    }
    
    /// Get delay times for each frames
    ///
    /// - Parameter imageSource: reference to the gif image source
    /// - Returns array of delays
    private func delayTimes(_ imageSource:CGImageSource) throws -> [Float] {
        let imageCount = CGImageSourceGetCount(imageSource)
        
        guard imageCount > 0 else {
            throw PTGifParseError.noImages
        }
        
        var imageProperties = [CFDictionary]()
        
        for i in 0..<imageCount {
            if let dict = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) {
                imageProperties.append(dict)
            } else {
                throw PTGifParseError.noProperties
            }
        }
        
        let frameProperties = try imageProperties.map() { (dict: CFDictionary) -> CFDictionary in
            let key = Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()
            let value = CFDictionaryGetValue(dict, key)
            
            if value == nil {
                throw PTGifParseError.noGifDictionary
            }
            
            return unsafeBitCast(value, to: CFDictionary.self)
        }
        
        let EPS:Float = 1e-6
        
        let frameDelays:[Float] = try frameProperties.map() {
            let unclampedKey = Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()
            let unclampedPointer:UnsafeRawPointer? = CFDictionaryGetValue($0, unclampedKey)
            
            if let value = convertToDelay(unclampedPointer), value >= EPS {
                return value
            }
            
            let clampedKey = Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()
            let clampedPointer:UnsafeRawPointer? = CFDictionaryGetValue($0, clampedKey)
            
            if let value = convertToDelay(clampedPointer) {
                return value
            }
            
            throw PTGifParseError.noTimingInfo
        }
        
        return frameDelays
    }
    
    /// Compute backing data for this gif
    ///
    /// - Parameter delaysArray: decoded delay times for this gif
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    private func calculateFrameDelay(_ delaysArray: [Float], levelOfIntegrity: PTGifLevelOfIntegrity) {
        let levelOfIntegrity = max(0, min(1, levelOfIntegrity))
        var delays = delaysArray

        var displayRefreshFactors = [Int]()

        displayRefreshFactors.append(contentsOf: [60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, 1])
        
        // maxFramePerSecond,default is 60
        let maxFramePerSecond = displayRefreshFactors[0]

        // frame numbers per second
        var displayRefreshRates = displayRefreshFactors.map { maxFramePerSecond / $0 }

        // Will be 120 on devices with ProMotion display, 60 otherwise.
        let maximumFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        if maximumFramesPerSecond == 120 {
            displayRefreshRates.append(maximumFramesPerSecond)
            displayRefreshFactors.insert(maximumFramesPerSecond, at: 0)
        }

        // time interval per frame
        let displayRefreshDelayTime = displayRefreshRates.map { 1 / Float($0) }
        
        // calculate the time when each frame should be displayed at(start at 0)
        for i in delays.indices.dropFirst() {
            delays[i] += delays[i - 1]
        }
        
        //find the appropriate Factors then BREAK
        for (i, delayTime) in displayRefreshDelayTime.enumerated() {
            let displayPosition = delays.map { Int($0 / delayTime) }
           
            var frameLoseCount: Float = 0
            
            for j in displayPosition.indices.dropFirst() where displayPosition[j] == displayPosition[j - 1] {
                frameLoseCount += 1
            }
            
            if displayPosition.first == 0 {
                frameLoseCount += 1
            }
            
            if frameLoseCount <= Float(displayPosition.count) * (1 - levelOfIntegrity) || i == displayRefreshDelayTime.count - 1 {
                imageCount = displayPosition.last
                displayRefreshFactor = displayRefreshFactors[i]
                displayOrder = []
                var oldIndex = 0
                var newIndex = 1
                let imageCount = self.imageCount ?? 0
                
                while newIndex <= imageCount && oldIndex < displayPosition.count {
                    if newIndex <= displayPosition[oldIndex] {
                        displayOrder?.append(oldIndex)
                        newIndex += 1
                    } else {
                        oldIndex += 1
                    }
                }
                break
            }
        }
    }
    
    /// Compute frame size for this gif
    private func calculateFrameSize(){
        guard let imageSource = imageSource,
            let imageCount = imageCount,
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                return
        }
        
        let image = UIImage(cgImage: cgImage)
        imageSize = Int(image.size.height * image.size.width * 4) * imageCount / 1_000_000
    }
}

// MARK: - Properties
public extension UIImage {
    
    private struct AssociatedKeys {
        static var UIImageGIFImageSourceKey = malloc(4)
        static var UIImageGIFDisplayRefreshFactorKey = malloc(4)
        static var UIImageGIFImageSizeKey = malloc(4)
        static var UIImageGIFImageCountKey = malloc(4)
        static var UIImageGIFDisplayOrderKey = malloc(4)
        static var UIImageGIFImageDataKey = malloc(4)
    }

    var imageSource: CGImageSource? {
        get {
            let result = objc_getAssociatedObject(self, AssociatedKeys.UIImageGIFImageSourceKey!)
            return result == nil ? nil : (result as! CGImageSource)
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.UIImageGIFImageSourceKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var displayRefreshFactor: Int?{
        get { return objc_getAssociatedObject(self, AssociatedKeys.UIImageGIFDisplayRefreshFactorKey!) as? Int }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageGIFDisplayRefreshFactorKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var imageSize: Int?{
        get { return objc_getAssociatedObject(self, AssociatedKeys.UIImageGIFImageSizeKey!) as? Int }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageGIFImageSizeKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var imageCount: Int?{
        get { return objc_getAssociatedObject(self, AssociatedKeys.UIImageGIFImageCountKey!) as? Int }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageGIFImageCountKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var displayOrder: [Int]?{
        get { return objc_getAssociatedObject(self, AssociatedKeys.UIImageGIFDisplayOrderKey!) as? [Int] }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageGIFDisplayOrderKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var imageData:Data? {
        get {
            let result = objc_getAssociatedObject(self, AssociatedKeys.UIImageGIFImageDataKey!)
            return result == nil ? nil : (result as? Data)
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.UIImageGIFImageDataKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

#endif
