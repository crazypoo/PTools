//
//  UIImage+SizeEx.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import Accelerate

public extension UIImage
{
    @objc func transformImage(size:CGSize)->UIImage
    {
        if #available(iOS 15.0, *) {
            return self.preparingThumbnail(of: size)!
        } else {
            return self.transform(size: CGSize.init(width: size.width, height: size.height))
        }
    }
    
    private func transform(size:CGSize)->UIImage
    {
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
    
    func blurImage()->UIImage
    {
        return self.img(alpha: 0.1, radius: 10, colorSaturationFactor: 1)
    }
    
    func img(alpha:Float,radius:Float,colorSaturationFactor:Float)->UIImage
    {
        let tintColor = UIColor.init(white: 1, alpha: CGFloat(alpha))
        return self.imgBluredWithRadius(blurRadius: radius, tintColor: tintColor, saturationDeltaFactor: colorSaturationFactor, maskImage: nil)
    }
    
    func imgBluredWithRadius(blurRadius:Float,tintColor:UIColor?,saturationDeltaFactor:Float,maskImage:UIImage?)->UIImage
    {
        let imageRect = CGRect.init(origin: .zero, size: self.size)
        var effectImage = self
        let hadBlur = blurRadius > Float.ulpOfOne
        let hasSaturationChange = abs(saturationDeltaFactor - 1) > Float.ulpOfOne
        if hadBlur || hasSaturationChange
        {
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
            
            let redPointer = UnsafePointer<UInt8>([0xFF,0x00,0x00])
            if hadBlur
            {
                let inputRadius = blurRadius * Float(UIScreen.main.scale)
                let sqartReslut = sqrt(2 * Double.pi)
                var radius:NSInteger = NSInteger(floor(Double(inputRadius) * 3.0 * sqartReslut / 4.0 + 0.5))
                if radius % 2 != 1
                {
                    radius += 1
                }
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, UInt32(radius), UInt32(radius), redPointer, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, nil, 0, 0, UInt32(radius), UInt32(radius), redPointer, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, UInt32(radius), UInt32(radius), redPointer, vImage_Flags(kvImageEdgeExtend))
            }
            
            var effectImageBuffersAreSwapped = false
            if hasSaturationChange
            {
                let s = saturationDeltaFactor
                let floatingPointSaturationMatrix = [0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                                                     0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                                                     0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                                                     0,                    0,                    0,  1]
                let divesor : Int32 = 256
                let matrixSize = MemoryLayout.size(ofValue: floatingPointSaturationMatrix) / MemoryLayout.size(ofValue: floatingPointSaturationMatrix[0])
                var saturationMatrix = [Int16]()
                
                for i in 0...(matrixSize - 1)
                {
                    saturationMatrix[i] = Int16(roundf(floatingPointSaturationMatrix[i] * Float(divesor)))
                }
                
                if hadBlur
                {
                    vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, &saturationMatrix, divesor, nil,nil, vImage_Flags(kvImageNoFlags))
                    effectImageBuffersAreSwapped = true
                }
                else
                {
                    vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, &saturationMatrix, divesor, nil,nil, vImage_Flags(kvImageNoFlags))
                }
                
                if !effectImageBuffersAreSwapped
                {
                    effectImage = UIGraphicsGetImageFromCurrentImageContext()!
                    UIGraphicsEndImageContext()
                }
                else
                {
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
        
        if hadBlur
        {
            outputContext?.saveGState()
            if maskImage != nil
            {
                outputContext?.clip(to: imageRect, mask: (maskImage?.cgImage)!)
            }
            outputContext?.draw(self.cgImage!, in: imageRect)
            outputContext?.restoreGState()
        }
        
        if tintColor != nil
        {
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
    @objc func watermark(title:String,font:UIFont = UIFont.systemFont(ofSize: 23),color:UIColor?) -> UIImage
    {
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
        let strWidth = PTUtils.sizeFor(string: title, font: font, height: CGFloat(MAXFLOAT), width: CGFloat(MAXFLOAT)).width
        let strHeight = PTUtils.sizeFor(string: title, font: font, height: CGFloat(MAXFLOAT), width: CGFloat(MAXFLOAT)).height
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
        for i in 0...totalCount
        {
            mark.draw(in: CGRect.init(x: tempOrignX, y: tempOrignY, width: strWidth, height: strHeight), withAttributes: attr)
            if i % horCount == 0 && i != 0
            {
                tempOrignX = orignX
                tempOrignY += (strHeight + CGFloat(VERTICAL_SPACE))
            }
            else
            {
                tempOrignX += (strWidth + CGFloat(HORIZONTAL_SPACE))
            }
        }
        
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        context.restoreGState()
        return finalImg
    }

    func imageScale(scaleSize:CGFloat)->UIImage
    {
        UIGraphicsBeginImageContext(CGSize(width: self.size.width * scaleSize, height: self.size.height * scaleSize))
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width * scaleSize, height: self.size.height * scaleSize))
        UIGraphicsEndImageContext()
        return self
    }
    
    func imageMask(text:NSString,point:CGPoint,attributed:NSDictionary)->UIImage
    {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        text.draw(at: point,withAttributes: (attributed as! [NSAttributedString.Key : Any]))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func imageMask(maskImage:UIImage,maskRect:CGRect)->UIImage
    {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        maskImage.draw(in: maskRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    @objc func imageMostColor()->UIColor
    {
        let context = self.getImageContext()
                
        let newImgData = unsafeBitCast(context.data, to: UnsafeMutablePointer<CUnsignedChar>.self)

        let cls = NSCountedSet.init(capacity: Int(self.size.width * self.size.height))
        for i in 0...Int(self.size.width)
        {
            for j in 0...Int(self.size.height)
            {
                let offSet = 4 * (i * j)
                let red = (newImgData + offSet).pointee
                let green = (newImgData + (offSet + 1)).pointee
                let blue = (newImgData + (offSet + 2)).pointee
                let alpha = (newImgData + (offSet + 3)).pointee
                if alpha > 0
                {
                    if red == 255 && green == 255 && blue == 255
                    {
                        
                    }
                    else
                    {
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
    
    func getImgePointColor(point:CGPoint)->UIColor
    {
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
        
    func getImageContext()-> CGContext
    {
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
