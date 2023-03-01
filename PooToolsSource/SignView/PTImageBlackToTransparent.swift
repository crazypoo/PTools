//
//  PTImageBlack.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTImageBlackToTransparent: NSObject {
    class func imageBlackToTransparent(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * imageWidth
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Allocate memory for image data
        guard let rawData = calloc(imageHeight * imageWidth * bytesPerPixel, MemoryLayout<UInt8>.size) else { return nil }
        
        // Create context
        guard let context = CGContext(data: rawData, width: imageWidth, height: imageHeight, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) else {
            free(rawData)
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        
        // Traverse pixels
        let pixelCount = imageWidth * imageHeight
        let data = UnsafeMutablePointer<UInt8>(rawData.assumingMemoryBound(to: UInt8.self))
        for i in 0..<pixelCount {
            let offset = i * bytesPerPixel
            let alpha = data[offset + 3]
            if alpha == 0 {
                // If pixel is black, set alpha to 0
                data[offset] = 0
                data[offset + 1] = 0
                data[offset + 2] = 0
            }
        }
        
        // Create image from context
        guard let imageRef = context.makeImage() else {
            free(rawData)
            return nil
        }
        
        let resultImage = UIImage(cgImage: imageRef)
        
        // Clean up
        free(rawData)
        
        return resultImage
    }

}
