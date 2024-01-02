//
//  NSImage+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/1/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(macOS)
import ImageIO
import AppKit

public extension NSImage {
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
public extension NSImage {
    
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
    convenience init(gifName: String, levelOfIntegrity: PTGifLevelOfIntegrity = .default) throws {
        self.init()
        try setGif(gifName, levelOfIntegrity: levelOfIntegrity)
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
    func setGif(_ name: String) throws {
        try setGif(name, levelOfIntegrity: .default)
    }
    
    /// Check the number of frame for this gif
    ///
    /// - Return number of frames
    func framesCount() -> Int {
        return displayOrder?.count ?? 0
    }

    private func giflog(_ msg: String) {
        print("SwiftyGIF: \(msg)")
    }
    
    /// Set backing data for this gif. Overwrites any existing data.
    ///
    /// - Parameter name: Filename
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    func setGif(_ name: String, levelOfIntegrity: PTGifLevelOfIntegrity, bundle: Bundle = Bundle.main) throws {
        
        if let url = bundle.url(forResource: name,
                                     withExtension: name.pathExtension() == "gif" ? "" : "gif") {
            if let data = try? Data(contentsOf: url) {
                try setGifFromData(data, levelOfIntegrity: levelOfIntegrity)
            }
        } else {
            throw GifParseError.invalidFilename
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
        
        // Factors send to CADisplayLink.frameInterval
        let displayRefreshFactors = [60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, 1]
        
        // maxFramePerSecond,default is 60
        let maxFramePerSecond = displayRefreshFactors[0]
        
        // frame numbers per second
        let displayRefreshRates = displayRefreshFactors.map { maxFramePerSecond / $0 }
        
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
        
        
        let image = NSImage(cgImage: cgImage, size: .zero)
        imageSize = Int(image.size.height * image.size.width * 4) * imageCount / 1_000_000
    }
}

// MARK: - Properties
public extension NSImage {
    
    private struct AssociatedKeys {
        static var NSImageGIFImageSourceKey = malloc(4)
        static var NSImageGIFDisplayRefreshFactorKey = malloc(4)
        static var NSImageGIFImageSizeKey = malloc(4)
        static var NSImageGIFImageCountKey = malloc(4)
        static var NSImageGIFDisplayOrderKey = malloc(4)
        static var NSImageGIFImageDataKey = malloc(4)
    }

    var imageSource: CGImageSource? {
        get {
            let result = objc_getAssociatedObject(self, AssociatedKeys.NSImageGIFImageSourceKey!)
            return result == nil ? nil : (result as! CGImageSource)
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.NSImageGIFImageSourceKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var displayRefreshFactor: Int?{
        get { return objc_getAssociatedObject(self, AssociatedKeys.NSImageGIFDisplayRefreshFactorKey!) as? Int }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageGIFDisplayRefreshFactorKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var imageSize: Int?{
        get { return objc_getAssociatedObject(self, AssociatedKeys.NSImageGIFImageSizeKey!) as? Int }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageGIFImageSizeKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var imageCount: Int?{
        get { return objc_getAssociatedObject(self, AssociatedKeys.NSImageGIFImageCountKey!) as? Int }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageGIFImageCountKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var displayOrder: [Int]?{
        get { return objc_getAssociatedObject(self, AssociatedKeys.NSImageGIFDisplayOrderKey!) as? [Int] }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageGIFDisplayOrderKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var imageData:Data? {
        get {
            let result = objc_getAssociatedObject(self, AssociatedKeys.NSImageGIFImageDataKey!)
            return result == nil ? nil : (result as? Data)
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.NSImageGIFImageDataKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
#endif
