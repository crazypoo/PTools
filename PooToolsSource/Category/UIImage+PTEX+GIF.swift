//
//  UIImage+PTEX+GIF.swift
//  PooTools
//
//  English: GIF decoding and frame metadata helpers for UIImage.
//  Español: Ayudantes de decodificación GIF y metadatos de fotogramas para UIImage.
//  中文：UIImage 的 GIF 解码和帧元数据辅助方法。
//

#if !os(macOS)
import UIKit
import ImageIO

// English: GIF image initialization, frame timing, and associated metadata.
// Español: Inicialización GIF, temporización de fotogramas y metadatos asociados.
// 中文：GIF 图片初始化、帧时序和关联元数据。
public extension UIImage {
    /// Convenience initializer. Creates a gif with its backing data.
    ///
    /// - Parameter imageData: The actual image data, can be GIF or some other format
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    @MainActor convenience init?(imageData:Data, levelOfIntegrity: PTGifLevelOfIntegrity = .default) throws {
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
    @MainActor convenience init?(imageName: String, levelOfIntegrity: PTGifLevelOfIntegrity = .default, bundle: Bundle = Bundle.main) throws {
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
    @MainActor convenience init(gifData:Data, levelOfIntegrity: PTGifLevelOfIntegrity = .default) throws {
        self.init()
        try setGifFromData(gifData, levelOfIntegrity: levelOfIntegrity)
    }
    
    /// Convenience initializer. Creates a gif with its backing data.
    ///
    /// - Parameter gifName: Filename
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    @MainActor convenience init(gifName: String, levelOfIntegrity: PTGifLevelOfIntegrity = .default, bundle: Bundle = Bundle.main) throws {
        self.init()
        try setGif(gifName, levelOfIntegrity: levelOfIntegrity, bundle: bundle)
    }
    
    /// Set backing data for this gif. Overwrites any existing data.
    ///
    /// - Parameter data: The actual gif data
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    @MainActor func setGifFromData(_ data: Data, levelOfIntegrity: PTGifLevelOfIntegrity) throws {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
        self.imageSource = imageSource
        imageData = data
        
        calculateFrameDelay(try delayTimes(imageSource), levelOfIntegrity: levelOfIntegrity)
        calculateFrameSize()
    }
    
    /// Set backing data for this gif. Overwrites any existing data.
    ///
    /// - Parameter name: Filename
    @MainActor func setGif(_ name: String, bundle: Bundle = Bundle.main) throws {
        try setGif(name, levelOfIntegrity: .default, bundle: bundle)
    }
    
    /// Check the number of frame for this gif
    ///
    /// - Return number of frames
    @MainActor func framesCount() -> Int {
        return displayOrder?.count ?? 0
    }
    
    /// Set backing data for this gif. Overwrites any existing data.
    ///
    /// - Parameter name: Filename
    /// - Parameter levelOfIntegrity: 0 to 1, 1 meaning no frame skipping
    @MainActor func setGif(_ name: String, levelOfIntegrity: PTGifLevelOfIntegrity, bundle: Bundle = Bundle.main) throws {
        if let url = bundle.url(forResource: name, withExtension: name.pathExtension() == "gif" ? "" : "gif") {
            if let data = try? Data(contentsOf: url) {
                try setGifFromData(data, levelOfIntegrity: levelOfIntegrity)
            }
        } else {
            throw PTGifParseError.invalidFilename
        }
    }
    
    @MainActor func clear() {
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
    @MainActor private func calculateFrameDelay(_ delaysArray: [Float], levelOfIntegrity: PTGifLevelOfIntegrity) {
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
    @MainActor private func calculateFrameSize(){
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

    @MainActor
    private final class PTImageSourceBox {
        let value: CGImageSource

        init(_ value: CGImageSource) {
            self.value = value
        }
    }
    
    @MainActor
    private struct AssociatedKeys {
        static var imageSource: UInt8 = 0
        static var displayRefreshFactor: UInt8 = 0
        static var imageSize: UInt8 = 0
        static var imageCount: UInt8 = 0
        static var displayOrder: UInt8 = 0
        static var imageData: UInt8 = 0
    }

    @MainActor var imageSource: CGImageSource? {
        get {
            let result = objc_getAssociatedObject(self, &AssociatedKeys.imageSource)
            return (result as? PTImageSourceBox)?.value
        }
        set {
            let boxedValue = newValue.map(PTImageSourceBox.init)
            objc_setAssociatedObject(self, &AssociatedKeys.imageSource, boxedValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @MainActor var displayRefreshFactor: Int?{
        get { return objc_getAssociatedObject(self, &AssociatedKeys.displayRefreshFactor) as? Int }
        set { objc_setAssociatedObject(self, &AssociatedKeys.displayRefreshFactor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    @MainActor var imageSize: Int?{
        get { return objc_getAssociatedObject(self, &AssociatedKeys.imageSize) as? Int }
        set { objc_setAssociatedObject(self, &AssociatedKeys.imageSize, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    @MainActor var imageCount: Int?{
        get { return objc_getAssociatedObject(self, &AssociatedKeys.imageCount) as? Int }
        set { objc_setAssociatedObject(self, &AssociatedKeys.imageCount, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    @MainActor var displayOrder: [Int]?{
        get { return objc_getAssociatedObject(self, &AssociatedKeys.displayOrder) as? [Int] }
        set { objc_setAssociatedObject(self, &AssociatedKeys.displayOrder, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    @MainActor var imageData:Data? {
        get {
            let result = objc_getAssociatedObject(self, &AssociatedKeys.imageData)
            return result == nil ? nil : (result as? Data)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.imageData, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

#endif
