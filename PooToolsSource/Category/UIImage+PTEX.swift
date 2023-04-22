//
//  UIImage+SizeEx.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import Accelerate
import AVFoundation
import Photos

extension UIImage : PTProtocolCompatible {}

public extension UIImage {
    //MARK: 更改圖片大小
    ///更改圖片大小
    @objc func transformImage(size:CGSize)->UIImage {
        if #available(iOS 15.0, *) {
            return self.preparingThumbnail(of: size)!
        } else {
            return self.transform(size: CGSize.init(width: size.width, height: size.height))
        }
    }
    
    private func transform(size:CGSize)->UIImage {
        let destW = size.width
        let destH = size.height
        let sourceW = size.width
        let sourceH = size.height
        
        let imageRef = self.cgImage
        let bitmap:CGContext = CGContext(data: nil , width: Int(destW), height: Int(destH), bitsPerComponent: (imageRef?.bitsPerComponent)!, bytesPerRow: 4 * Int(destW), space: (imageRef?.colorSpace)!, bitmapInfo: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue))!
        
        bitmap.draw(imageRef!, in: CGRect.init(x: 0, y: 0, width: sourceW, height: sourceH))
        
        let ref = bitmap.makeImage()
        let resultImage = UIImage.init(cgImage: ref!)
        return resultImage
    }
    
    //MARK: 圖片高斯模糊
    ///圖片高斯模糊
    @objc func blurImage()->UIImage {
        return self.img(alpha: 0.1, radius: 10, colorSaturationFactor: 1)
    }
    
    /*
     1.白色,参数:
     透明度 0~1,  0为白,   1为深灰色
     半径:默认30,推荐值 3   半径值越大越模糊 ,值越小越清楚
     色彩饱和度(浓度)因子:  0是黑白灰, 9是浓彩色, 1是原色  默认1.8
     “彩度”，英文是称Saturation，即饱和度。将无彩色的黑白灰定为0，最鲜艳定为9s，这样大致分成十阶段，让数值和人的感官直觉一致。
     */
    func img(alpha:Float,radius:Float,colorSaturationFactor:Float)->UIImage {
        let tintColor = UIColor.init(white: 1, alpha: CGFloat(alpha))
        return self.imgBluredWithRadius(blurRadius: radius, tintColor: tintColor, saturationDeltaFactor: colorSaturationFactor, maskImage: nil)
    }
    
    func imgBluredWithRadius(blurRadius:Float,tintColor:UIColor?,saturationDeltaFactor:Float,maskImage:UIImage?)->UIImage {
        let imageRect = CGRect.init(origin: .zero, size: self.size)
        var effectImage = self
        let hadBlur = blurRadius > Float.ulpOfOne
        let hasSaturationChange = abs(saturationDeltaFactor - 1) > Float.ulpOfOne
        if hadBlur || hasSaturationChange {
            UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
            let effectContext = UIGraphicsGetCurrentContext()
            effectContext!.scaleBy(x: 1,y: -1)
            effectContext!.translateBy(x: 0, y: -self.size.height)
            effectContext!.draw(self.cgImage!, in: imageRect)
            
            var effectInBuffer = vImage_Buffer()
            effectInBuffer.data = effectContext!.data
            effectInBuffer.width = vImagePixelCount(effectContext!.width)
            effectInBuffer.height = vImagePixelCount(effectContext!.height)
            effectInBuffer.rowBytes = effectContext!.bytesPerRow
            
            UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
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
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        let outputContext = UIGraphicsGetCurrentContext()
        outputContext?.scaleBy(x: 1, y: -1)
        outputContext?.translateBy(x: 0, y: -self.size.height)
        outputContext?.draw(self.cgImage!, in: imageRect)
        
        if hadBlur {
            outputContext?.saveGState()
            if maskImage != nil {
                outputContext?.clip(to: imageRect, mask: (maskImage?.cgImage)!)
            }
            outputContext?.draw(self.cgImage!, in: imageRect)
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
    @objc func watermark(title:String,font:UIFont = UIFont.systemFont(ofSize: 23),color:UIColor?) -> UIImage {
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
        let strWidth = UIView.sizeFor(string: title, font: font, height: CGFloat(MAXFLOAT), width: CGFloat(MAXFLOAT)).width
        let strHeight = UIView.sizeFor(string: title, font: font, height: CGFloat(MAXFLOAT), width: CGFloat(MAXFLOAT)).height
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
        UIGraphicsBeginImageContext(CGSize(width: self.size.width * scaleSize, height: self.size.height * scaleSize))
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width * scaleSize, height: self.size.height * scaleSize))
        UIGraphicsEndImageContext()
        return self
    }
    
    func imageMask(text:NSString,point:CGPoint,attributed:NSDictionary)->UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        text.draw(at: point,withAttributes: (attributed as! [NSAttributedString.Key : Any]))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func imageMask(maskImage:UIImage,maskRect:CGRect)->UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        maskImage.draw(in: maskRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    //MARK: 獲取圖片中大部分占有的顏色
    ///獲取圖片中大部分占有的顏色
    @objc func imageMostColor()->UIColor {
        let context = self.getImageContext()
                
        let newImgData = unsafeBitCast(context.data, to: UnsafeMutablePointer<CUnsignedChar>.self)

        let cls = NSCountedSet.init(capacity: Int(self.size.width * self.size.height))
        for i in 0...Int(self.size.width) {
            for j in 0...Int(self.size.height) {
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
        let context = self.getImageContext()
                
        let newImgData = unsafeBitCast(context.data, to: UnsafeMutablePointer<CUnsignedChar>.self)
        
        // 根据当前所选择的点计算出对应位图数据的index
        let offset = Int(point.y * self.size.width + point.x) * 4
        
        // 获取4种信息
        let alpha = (newImgData + offset).pointee
        let red   = (newImgData + (offset + 1)).pointee
        let green = (newImgData + (offset + 2)).pointee
        let blue  = (newImgData + (offset + 3)).pointee
        
        // 得到颜色
        return UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: CGFloat(alpha)/255.0)
    }
        
    func getImageContext()-> CGContext {
        let currentImage = self.cgImage ?? UIColor.red.createImageWithColor().transformImage(size: CGSize(width: 100, height: 100)).cgImage!
        
        let bitmapInfo = CGBitmapInfo.byteOrderDefault.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let thumbSize = CGSize(width: self.size.width, height: self.size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext.init(data: nil, width: Int(thumbSize.width), height: Int(thumbSize.height), bitsPerComponent: 8, bytesPerRow: Int(thumbSize.width) * 4, space: colorSpace, bitmapInfo: bitmapInfo)
        
        let drawRect = CGRect(x: 0, y: 0, width: thumbSize.width, height: thumbSize.height)
        context?.draw(currentImage, in: drawRect)
        return context!
    }
}

public extension PTProtocol where Base: UIImage {
    //MARK: 设置图片的圆角
    ///设置图片的圆角
    /// - Parameters:
    ///   - radius: 圆角大小 (默认:3.0,图片大小)
    ///   - corners: 切圆角的方式
    ///   - imageSize: 图片的大小
    /// - Returns: 剪切后的图片
    func isRoundCorner(radius: CGFloat = 3, byRoundingCorners corners: UIRectCorner = .allCorners, imageSize: CGSize?) -> UIImage? {
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
    /// - Returns: 视频的第一帧
    static func getVideoFirstImage(videoUrl: String, maximumSize: CGSize = CGSize(width: 1000, height: 1000), closure: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: videoUrl) else {
            closure(nil)
            return
        }
        DispatchQueue.global().async {
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
            } catch {
                PTGCDManager.gcdMain {
                    closure(nil)
                }
                return
            }
            guard let image = cgImage else {
                PTGCDManager.gcdMain {
                    closure(nil)
                }
                return
            }
            PTGCDManager.gcdMain {
                closure(UIImage(cgImage: image))
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
        context?.draw(self.base.cgImage!, in: area)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self.base
    }
    
    //MARK: 更改图片颜色
    ///更改图片颜色
    /// - Parameters:
    ///   - color: 图片颜色
    ///   - blendMode: 模式
    /// - Returns: 返回更改后的图片颜色
    func tint(color: UIColor, blendMode: CGBlendMode = .destinationIn) -> UIImage? {
        /**
         有时我们的App需要能切换不同的主题和场景，希望图片能动态的改变颜色以配合对应场景的色调。虽然我们可以根据不同主题事先创建不同颜色的图片供调用，但既然用的图片素材都一样，还一个个转换显得太麻烦，而且不便于维护。使用blendMode变可以满足这个需求。
         */
        defer {
            UIGraphicsEndImageContext()
        }
        let drawRect = CGRect(x: 0, y: 0, width: self.base.size.width, height: self.base.size.height)
        UIGraphicsBeginImageContextWithOptions(self.base.size, false, self.base.scale)
        color.setFill()
        UIRectFill(drawRect)
        self.base.draw(in: drawRect, blendMode: CGBlendMode.destinationIn, alpha: 1.0)
        guard let tintedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        return tintedImage
    }

    //MARK: 保存图片到相册
    ///保存图片到相册
    func savePhotosImageToAlbum(completion: @escaping ((Bool, Error?) -> Void)) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: self.base)
        } completionHandler: { (isSuccess: Bool, error: Error?) in
            completion(isSuccess, error)
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
public extension PTProtocol where Base: UIImage {
    
    //MARK: 压缩图片
    ///压缩图片
    /// - Parameters:
    ///  - mode: 压缩模式
    /// - Returns: 压缩后Data
    func compress(mode: CompressionMode = .medium) -> Data? {
        return resizeIO(resizeSize: mode.resize(base.size))?.pt.compressDataSize(maxSize: mode.maxDataSize)
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
            let data = resizeIO(resizeSize: mode.resize(self.base.size))?.pt.compressDataSize(maxSize: mode.maxDataSize)
            PTGCDManager.gcdMain {
                complete(data, mode.resize(self.base.size))
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
        guard var data = self.base.jpegData(compressionQuality: 1) else { return nil }
        if data.count < maxSize {
            return data
        }
        var max: CGFloat = 1
        var min: CGFloat = 0
        var count = 0
        for _ in 0..<6 {
            count = count + 1
            compression = (max + min) / 2
            data = self.base.jpegData(compressionQuality: compression)!
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
        guard let oldData = self.base.jpegData(compressionQuality: 1) else { return nil }
        if oldData.count < maxSize {
            return oldData
        }
        var compress: CGFloat = 0.9
        guard var data = self.base.jpegData(compressionQuality: compress) else { return nil }
        while data.count > maxSize && compress > 0.01 {
            compress -= 0.02
            data = self.base.jpegData(compressionQuality: compress)!
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
            return self.base
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
            return self.base
        }
        guard  let cgImage = self.base.cgImage else { return nil }
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
