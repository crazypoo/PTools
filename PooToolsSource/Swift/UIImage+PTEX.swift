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
        
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage!
    }
    
    func imageMostColor()->UIColor?
    {
        let thumbSize = CGSize.init(width: self.size.width/2, height: self.size.height/2)
        let pixelData = self.cgImage!.dataProvider!.data
        if let data:UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        {
            let cls = NSCountedSet.init(capacity: Int(thumbSize.width * thumbSize.height))
            for x in 0..<Int(thumbSize.width)
            {
                for y in 0..<Int(thumbSize.height)
                {
                    let offset = 4 * (x * y)
                    let red = data[offset]
                    let green = data[offset + 1]
                    let blue = data[offset + 2]
                    let alpha = data[offset + 3]
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

            let enumerator = cls.objectEnumerator()
            var curColor : NSArray?
            var MaxColor : NSArray?
            var MaxCount : Int = 0
            while (curColor = (enumerator.nextObject() as! NSArray)) != nil {
                let tmpCount = cls.count(for: curColor)
                if tmpCount < MaxCount
                {
                    continue
                }
                MaxCount = tmpCount
                MaxColor = curColor
            }
            return UIColor(red:MaxColor![0] as! CGFloat / 255,green: MaxColor![1] as! CGFloat / 255,blue:MaxColor![2] as! CGFloat / 255,alpha:MaxColor![3] as! CGFloat / 255)
        }
        else
        {
            return nil
        }
    }
}
