//
//  UIImageView+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/4.
//  Copyright © 2022 crazypoo. All rights reserved.
//

#if !os(macOS)

import UIKit
import Kingfisher
import ImageIO
import Photos
import ObjectiveC
import AVFoundation // 补充导入以支持 AVAsset

public extension UIImageView {
    //MARK: 獲取圖片的某像素點的顏色
    @objc func getImagePointColor(point:CGPoint) -> UIColor {
        if let currentImage = image {
            let thumbSize = CGSize(width: image!.size.width, height: currentImage.size.height)

            // 当前点在图片中的相对位置 (优化：移除 CGPointMake，使用原生 CGPoint)
            let pInImage = CGPoint(x: point.x * thumbSize.width / self.bounds.width,
                                   y: point.y * thumbSize.height / self.bounds.height)
            //TODO: 此处假设 getImgePointColor 是 UIImage 的自定义扩展，拼写可能存在错别字，建议同步检查 UIImage 扩展中的命名
            return currentImage.getImgePointColor(point: pInImage)
        } else {
            return .clear
        }
    }
    
    //TODO: 由于内部使用的是 Kingfisher，此方法名带有 SDWebImage 可能会引起误解，建议未来重命名
    @objc func pt_SDWebImage(imageString:String,placeholder:UIImage = PTAppBaseConfig.share.defaultPlaceholderImage,loadedHandler:PTImageLoadHandler? = nil) {
        kf.setImage(with: URL(string: imageString),placeholder: placeholder,options: PTAppBaseConfig.share.gobalWebImageLoadOption()) { result in
            switch result {
            case .success(let result):
                loadedHandler?(nil,result.originalSource.url,result.image)
            case .failure(let error):
                loadedHandler?(error,nil,nil)
            }
        }
    }
    
    // MARK: - Runtime
    func loadImage(contentData: Any,
                   iCloudDocumentName: String = "",
                   borderWidth: CGFloat = PTAppBaseConfig.share.loadImageProgressBorderWidth,
                   borderColor: UIColor = PTAppBaseConfig.share.loadImageProgressBorderColor,
                   showValueLabel: Bool = PTAppBaseConfig.share.loadImageShowValueLabel,
                   valueLabelFont: UIFont = PTAppBaseConfig.share.loadImageShowValueFont,
                   valueLabelColor: UIColor = PTAppBaseConfig.share.loadImageShowValueColor,
                   uniCount: Int = PTAppBaseConfig.share.loadImageShowValueUniCount,
                   emptyImage: UIImage = PTAppBaseConfig.share.defaultEmptyImage,
                   progressHandle: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)? = nil,
                   loadFinish: ((PTLoadImageResult) -> Void)? = nil) {
        // 直接调用父类 UIView 封装好的核心逻辑
        pt_loadCoreImage(
            contentData: contentData,
            iCloudDocumentName: iCloudDocumentName,
            borderWidth: borderWidth,
            borderColor: borderColor,
            showValueLabel: showValueLabel,
            valueLabelFont: valueLabelFont,
            valueLabelColor: valueLabelColor,
            uniCount: uniCount,
            emptyImage: emptyImage,
            progressHandle: progressHandle,
            setImageBlock: { [weak self] image in
                self?.image = image // UIImageView 特有的渲染方式
            },
            loadFinish: loadFinish
        )
    }
    
    //MARK: 視頻剪輯
    var frameForImageInImageViewAspectFit: CGRect {
        if let img = self.image {
            let imageRatio = img.size.width / img.size.height
            let viewRatio = self.frame.size.width / self.frame.size.height
            if (imageRatio < viewRatio) {
                let scale = self.frame.size.height / img.size.height
                let width = scale * img.size.width
                let topLeftX = (self.frame.size.width - width) * 0.5
                return CGRect(x: topLeftX, y: 0, width: width, height: self.frame.size.height)
            } else {
                let scale = self.frame.size.width / img.size.width
                let height = scale * img.size.height
                let topLeftY = (self.frame.size.height - height) * 0.5
                return CGRect(x: 0, y: topLeftY, width: self.frame.size.width, height: height)
            }
        }
        return .zero
    }
    
    var imageFrame: CGRect {
        // 与 frameForImageInImageViewAspectFit 逻辑一致，保留以作兼容
        return frameForImageInImageViewAspectFit
    }
    
    @available(iOS 17.0, *)
    func hdrSet(hdrModel:UIImage.DynamicRange = .constrainedHigh) {
        self.preferredImageDynamicRange = hdrModel
    }
}

/*
 GIF 播放逻辑
 */
public typealias PTGIFImageTask = (UIImageView) -> Void
public typealias PTGIFImageFailTask = (UIImageView,URL,Error?) -> Void

public extension UIImageView {
    /// Set an image and a manager to an existing UIImageView. If the image is not an GIF image, set it in normal way and remove self form PTGifManager
    /// WARNING : this overwrite any previous gif.
    /// - Parameter gifImage: The UIImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    /// - Parameter loopCount: The number of loops we want for this gif. -1 means infinite.
    func setImage(_ image: UIImage, manager: PTGifManager = .defaultManager, loopCount: Int = -1) {
        if let _ = image.imageData {
            setGifImage(image, manager: manager, loopCount: loopCount)
        } else {
            manager.deleteImageView(self)
            self.image = image
        }
    }
}

public extension UIImageView {
    
    // MARK: - Inits
    /// Convenience initializer. Creates a gif holder (defaulted to infinite loop).
    /// - Parameter gifImage: The UIImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    convenience init(gifImage: UIImage, manager: PTGifManager = .defaultManager, loopCount: Int = -1) {
        self.init()
        setGifImage(gifImage,manager: manager, loopCount: loopCount)
    }
    
    /// Convenience initializer. Creates a gif holder (defaulted to infinite loop).
    ///
    /// - Parameter gifImage: The UIImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    convenience init(gifURL: URL, manager: PTGifManager = .defaultManager, loopCount: Int = -1) {
        self.init()
        setGifFromURL(gifURL, manager: manager, loopCount: loopCount)
    }
    
    /// Set a gif image and a manager to an existing UIImageView.
    /// WARNING : this overwrite any previous gif.
    /// - Parameter gifImage: The UIImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    /// - Parameter loopCount: The number of loops we want for this gif. -1 means infinite.
    func setGifImage(_ gifImage: UIImage, manager: PTGifManager = .defaultManager, loopCount: Int = -1) {
        if let imageData = gifImage.imageData, (gifImage.imageCount ?? 0) < 1 {
            image = UIImage(data: imageData)
            return
        }
        
        self.loopCount = loopCount
        self.gifImage = gifImage
        animationManager = manager
        syncFactor = 0
        displayOrderIndex = 0
        cache = NSCache()
        haveCache = false
        
        if let source = gifImage.imageSource, let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            currentImage = UIImage(cgImage: cgImage)
            
            if manager.addImageView(self) {
                startDisplay()
                startAnimatingGif()
            }
        }
    }
}

// MARK: - Download gif

public extension UIImageView {
    
    /// Download gif image and sets it.
    /// - Parameters:
    ///     - url: The URL pointing to the gif data
    ///     - manager: The manager to handle the gif display
    ///     - loopCount: The number of loops we want for this gif. -1 means infinite.
    ///     - showLoader: Show UIActivityIndicatorView or not
    /// - Returns: An URL session task. Note: You can cancel the downloading task if it needed.
    @discardableResult
    func setGifFromURL(_ url: URL,
                       manager: PTGifManager = .defaultManager,
                       loopCount: Int = -1,
                       levelOfIntegrity: PTGifLevelOfIntegrity = .default,
                       session: URLSession = URLSession.shared,
                       showLoader: Bool = true,
                       customLoader: UIView? = nil) -> URLSessionDataTask? {
        
        if let data =  manager.remoteCache[url] {
            self.parseDownloadedGif(url: url,
                    data: data,
                    error: nil,
                    manager: manager,
                    loopCount: loopCount,
                    levelOfIntegrity: levelOfIntegrity)
            return nil
        }
        
        stopAnimatingGif()
        
        let loader: UIView? = showLoader ? createLoader(from: customLoader) : nil
        
        let task = session.dataTask(with: url) { [weak self] data, _, error in
            loader?.removeFromSuperview()
            self?.parseDownloadedGif(url: url,
                                    data: data,
                                    error: error,
                                    manager: manager,
                                    loopCount: loopCount,
                                    levelOfIntegrity: levelOfIntegrity)
        }
        
        task.resume()
        return task
    }
    
    // 优化：使用 Anchor API 代替老式的 NSLayoutConstraint 初始化
    private func createLoader(from view: UIView? = nil) -> UIView {
        let loader = view ?? UIActivityIndicatorView()
        addSubview(loader)
        loader.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        (loader as? UIActivityIndicatorView)?.startAnimating()
        
        return loader
    }
    
    private func parseDownloadedGif(url: URL,
                                    data: Data?,
                                    error: Error?,
                                    manager: PTGifManager,
                                    loopCount: Int,
                                    levelOfIntegrity: PTGifLevelOfIntegrity) {
        guard let data = data else {
            report(url: url, error: error)
            return
        }
        
        do {
            let image = try UIImage(gifData: data, levelOfIntegrity: levelOfIntegrity)
            manager.remoteCache[url] = data
            setGifImage(image, manager: manager, loopCount: loopCount)
            startAnimatingGif()
            gifURLDidFinish?(self)
        } catch {
            report(url: url, error: error)
        }
    }
    
    private func report(url: URL, error: Error?) {
        gifURLDidFail?(self,url,error)
    }
}

// MARK: - Logic
public extension UIImageView {
    
    /// Start displaying the gif for this UIImageView.
    private func startDisplay() {
        displaying = true
        updateCache()
    }
    
    /// Stop displaying the gif for this UIImageView.
    private func stopDisplay() {
        displaying = false
        updateCache()
    }
    
    /// Start displaying the gif for this UIImageView.
    func startAnimatingGif() { isPlaying = true }
    
    /// Stop displaying the gif for this UIImageView.
    func stopAnimatingGif() { isPlaying = false }
    
    /// Check if this imageView is currently playing a gif
    /// - Returns wether the gif is currently playing
    func isAnimatingGif() -> Bool { return isPlaying }
    
    /// Show a specific frame based on a delta from current frame
    /// - Parameter delta: The delsta from current frame we want
    func showFrameForIndexDelta(_ delta: Int) {
        guard let gifImage = gifImage else { return }
        var nextIndex = displayOrderIndex + delta
        
        while nextIndex >= gifImage.framesCount() {
            nextIndex -= gifImage.framesCount()
        }
        
        while nextIndex < 0 {
            nextIndex += gifImage.framesCount()
        }
        
        showFrameAtIndex(nextIndex)
    }
    
    /// Show a specific frame
    /// - Parameter index: The index of frame to show
    func showFrameAtIndex(_ index: Int) {
        displayOrderIndex = index
        updateFrame()
    }
    
    /// Update cache for the current imageView.
    func updateCache() {
        guard let animationManager = animationManager else { return }
        
        if animationManager.hasCache(self) && !haveCache {
            prepareCache()
            haveCache = true
        } else if !animationManager.hasCache(self) && haveCache {
            cache?.removeAllObjects()
            haveCache = false
        }
    }
    
    /// Update current image displayed. This method is called by the manager.
    func updateCurrentImage() {
        if displaying {
            updateFrame()
            updateIndex()
            
            if loopCount == 0 || !isDisplayedInScreen(self) || !isPlaying {
                stopDisplay()
            }
        } else {
            if isDisplayedInScreen(self) && loopCount != 0 && isPlaying {
                startDisplay()
            }
            
            if isDiscarded(self) {
                animationManager?.deleteImageView(self)
            }
        }
    }
    
    /// Force update frame
    private func updateFrame() {
        if haveCache, let image = cache?.object(forKey: displayOrderIndex as AnyObject) as? UIImage {
            currentImage = image
        } else {
            currentImage = frameAtIndex(index: currentFrameIndex())
        }
    }
    
    /// Get current frame index
    func currentFrameIndex() -> Int { return displayOrderIndex }
    
    /// Get frame at specific index
    func frameAtIndex(index: Int) -> UIImage {
        guard let gifImage = gifImage,
            let imageSource = gifImage.imageSource,
            let displayOrder = gifImage.displayOrder, index < displayOrder.count,
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, displayOrder[index], nil) else {
                return UIImage()
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Check if the imageView has been discarded and is not in the view hierarchy anymore.
    ///
    /// - Returns : A boolean for weather the imageView was discarded
    func isDiscarded(_ imageView: UIView?) -> Bool {
        return imageView?.superview == nil
    }
    
    /// Check if the imageView is displayed.
    ///
    /// - Returns : A boolean for weather the imageView is displayed
    func isDisplayedInScreen(_ imageView: UIView?) -> Bool {
        guard !isHidden, let imageView = imageView else  {
            return false
        }
        
        let screenRect = UIScreen.main.bounds
        let viewRect = imageView.convert(bounds, to:nil)
        let intersectionRect = viewRect.intersection(screenRect)
        
        return window != nil && !intersectionRect.isEmpty && !intersectionRect.isNull
    }
    
    func clear() {
        gifImage?.clear()
        gifImage = nil
        currentImage = nil
        cache?.removeAllObjects()
        animationManager = nil
        image = nil
    }
    
    /// Update loop count and sync factor.
    private func updateIndex() {
        guard let gif = self.gifImage,
            let displayRefreshFactor = gif.displayRefreshFactor,
            displayRefreshFactor > 0 else {
            return
        }
        
        syncFactor = (syncFactor + 1) % displayRefreshFactor
        
        if syncFactor == 0, let imageCount = gif.imageCount, imageCount > 0 {
            displayOrderIndex = (displayOrderIndex+1) % imageCount
            
            if displayOrderIndex == 0 {
                if loopCount == -1 {
                    gifDidLoop?(self)
                } else if loopCount > 1 {
                    gifDidLoop?(self)
                    loopCount -= 1
                } else {
                    gifDidStop?(self)
                    loopCount -= 1
                }
            }
        }
    }
    
    /// Prepare the cache by adding every images of the gif to an NSCache object.
    private func prepareCache() {
        guard let cache = self.cache else { return }
        cache.removeAllObjects()
        
        guard let gif = self.gifImage,
            let displayOrder = gif.displayOrder,
            let imageSource = gif.imageSource else { return }
        
        for (i, order) in displayOrder.enumerated() {
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, order, nil) else { continue }
            cache.setObject(UIImage(cgImage: cgImage), forKey: i as AnyObject)
        }
    }
}

// MARK: - Dynamic properties
public extension UIImageView {
    // 优化：彻底移除了极度危险的 malloc(4)，改用 Swift 标准的安全指针绑定方式
    private struct AssociatedKeys {
        static var gifDidStart: UInt8 = 0
        static var gifDidLoop: UInt8 = 0
        static var gifDidStop: UInt8 = 0
        static var gifURLDidFinish: UInt8 = 0
        static var gifURLDidFail: UInt8 = 0
        static var gifImage: UInt8 = 0
        static var cache: UInt8 = 0
        static var currentImage: UInt8 = 0
        static var displayOrderIndex: UInt8 = 0
        static var syncFactor: UInt8 = 0
        static var haveCache: UInt8 = 0
        static var loopCount: UInt8 = 0
        static var displaying: UInt8 = 0
        static var isPlaying: UInt8 = 0
        static var animationManager: UInt8 = 0
    }
    
    var gifImage: UIImage? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.gifImage) as? UIImage }
        set { objc_setAssociatedObject(self, &AssociatedKeys.gifImage, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var currentImage: UIImage? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.currentImage) as? UIImage }
        set { objc_setAssociatedObject(self, &AssociatedKeys.currentImage, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var displayOrderIndex: Int {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.displayOrderIndex) as? Int) ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.displayOrderIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var syncFactor: Int {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.syncFactor) as? Int) ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.syncFactor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var loopCount: Int {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.loopCount) as? Int) ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.loopCount, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var animationManager: PTGifManager? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.animationManager) as? PTGifManager }
        set { objc_setAssociatedObject(self, &AssociatedKeys.animationManager, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var haveCache: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.haveCache) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.haveCache, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var displaying: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.displaying) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.displaying, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var gifDidStart: PTGIFImageTask? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.gifDidStart) as? PTGIFImageTask }
        set { objc_setAssociatedObject(self, &AssociatedKeys.gifDidStart, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var gifDidLoop: PTGIFImageTask? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.gifDidLoop) as? PTGIFImageTask }
        set { objc_setAssociatedObject(self, &AssociatedKeys.gifDidLoop, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var gifDidStop: PTGIFImageTask? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.gifDidStop) as? PTGIFImageTask }
        set { objc_setAssociatedObject(self, &AssociatedKeys.gifDidStop, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var gifURLDidFinish: PTGIFImageTask? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.gifURLDidFinish) as? PTGIFImageTask }
        set { objc_setAssociatedObject(self, &AssociatedKeys.gifURLDidFinish, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var gifURLDidFail: PTGIFImageFailTask? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.gifURLDidFail) as? PTGIFImageFailTask }
        set { objc_setAssociatedObject(self, &AssociatedKeys.gifURLDidFail, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var isPlaying: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.isPlaying) as? Bool) ?? false }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isPlaying, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue {
                gifDidStart?(self)
            }
        }
    }
    
    private var cache: NSCache<AnyObject, AnyObject>? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.cache) as? NSCache }
        set { objc_setAssociatedObject(self, &AssociatedKeys.cache, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

#endif
