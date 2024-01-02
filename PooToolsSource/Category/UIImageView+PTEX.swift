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

public extension UIImageView {
    //MARK: 獲取圖片的某像素點的顏色
    ///獲取圖片的某像素點的顏色
    func getImagePointColor(point:CGPoint)->UIColor {
        let thumbSize = CGSize(width: image!.size.width, height: image!.size.height)

        // 当前点在图片中的相对位置
        let pInImage = CGPointMake(point.x * thumbSize.width / self.bounds.size.width,
                                   point.y * thumbSize.height / self.bounds.size.height)
        return image!.getImgePointColor(point: pInImage)
    }
    
    func pt_SDWebImage(imageString:String) {
        kf.setImage(with: URL.init(string: imageString),placeholder: PTAppBaseConfig.share.defaultPlaceholderImage,options: PTAppBaseConfig.share.gobalWebImageLoadOption())
    }
    
    func blur(withStyle style: UIBlurEffect.Style) {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)
        clipsToBounds = true
    }
    
    func loadImage(contentData:Any,
                   iCloudDocumentName:String = "",
                   borderWidth:CGFloat = 1.5,
                   borderColor:UIColor = UIColor.purple,
                   showValueLabel:Bool = false,
                   valueLabelFont:UIFont = .appfont(size: 16,bold: true),
                   valueLabelColor:UIColor = .white,
                   uniCount:Int = 0,
                   emptyImage:UIImage = PTAppBaseConfig.share.defaultEmptyImage) {
        if contentData is UIImage {
            let image = (contentData as! UIImage)
            self.image = image
        } else if contentData is String {
            let dataUrlString = contentData as! String
            if FileManager.pt.judgeFileOrFolderExists(filePath: dataUrlString) {
                let image = UIImage(contentsOfFile: dataUrlString)!
                self.image = image
            } else if dataUrlString.isURL() {
                if dataUrlString.contains("file://") {
                    if iCloudDocumentName.stringIsEmpty() {
                        let image = UIImage(contentsOfFile: dataUrlString)!
                        self.image = image
                    } else {
                        if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(iCloudDocumentName) {
                            let imageURL = icloudURL.appendingPathComponent(dataUrlString.lastPathComponent)
                            if let imageData = try? Data(contentsOf: imageURL) {
                                let image = UIImage(data: imageData)!
                                self.image = image
                            }
                        } else {
                            let image = UIImage(contentsOfFile: dataUrlString)!
                            self.image = image
                        }
                    }
                } else {
                    ImageDownloader.default.downloadImage(with: URL(string: dataUrlString)!, options: PTAppBaseConfig.share.gobalWebImageLoadOption(),progressBlock: { receivedSize, totalSize in
                        PTGCDManager.gcdMain {
                            self.layerProgress(value: CGFloat((receivedSize / totalSize)),borderWidth: borderWidth,borderColor: borderColor,showValueLabel: showValueLabel,valueLabelFont:valueLabelFont,valueLabelColor:valueLabelColor,uniCount:uniCount)
                        }
                    }) { result in
                        switch result {
                        case .success(let value):
                            if value.originalData.detectImageType() == .GIF {
                                let source = CGImageSourceCreateWithData(value.originalData as CFData, nil)
                                let frameCount = CGImageSourceGetCount(source!)
                                var frames = [UIImage]()
                                for i in 0...frameCount {
                                    let imageref = CGImageSourceCreateImageAtIndex(source!,i,nil)
                                    let imageName = UIImage.init(cgImage: (imageref ?? UIColor.clear.createImageWithColor().cgImage)!)
                                    frames.append(imageName)
                                }
                                self.image = UIImage.animatedImage(with: frames, duration: 2)
                            } else {
                                self.image = value.image
                            }
                        case .failure(let error):
                            PTNSLogConsole(error)
                            self.image = emptyImage
                        }
                    }
                }
            } else if dataUrlString.isSingleEmoji {
                let emojiImage = dataUrlString.emojiToImage()
                image = emojiImage
            } else {
                if let image = UIImage(named: dataUrlString) {
                    self.image = image
                } else if let systemImage = UIImage(systemName: dataUrlString) {
                    image = systemImage
                } else {
                    image = emptyImage
                }
            }
        } else if contentData is Data {
            let dataImage = UIImage(data: contentData as! Data)!
            image = dataImage
        } else {
            image = emptyImage
        }
    }
    
    //MARK: 視頻剪輯
    var frameForImageInImageViewAspectFit: CGRect {
        if  let img = self.image {
            let imageRatio = img.size.width / img.size.height
            let viewRatio = self.frame.size.width / self.frame.size.height
            if(imageRatio < viewRatio) {
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
        return CGRect(x: 0, y: 0, width: 0, height: 0)
    }
    
    var imageFrame: CGRect {
        let imageViewSize = self.frame.size
        guard let imageSize = self.image?.size else { return CGRect.zero }
        let imageRatio = imageSize.width / imageSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        if imageRatio < imageViewRatio {
            let scaleFactor = imageViewSize.height / imageSize.height
            let width = imageSize.width * scaleFactor
            let topLeftX = (imageViewSize.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
        } else {
            let scalFactor = imageViewSize.width / imageSize.width
            let height = imageSize.height * scalFactor
            let topLeftY = (imageViewSize.height - height) * 0.5
            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
        }
    }
}

/*
 GIF
 */
public typealias PTGIFImageTask = (UIImageView) -> Void
public typealias PTGIFImageFailTask = (UIImageView,URL,Error?) -> Void

public extension UIImageView {
    /// Set an image and a manager to an existing UIImageView. If the image is not an GIF image, set it in normal way and remove self form PTGifManager
    ///
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
    ///
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
    ///
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
    ///
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
            DispatchQueue.main.async {
                loader?.removeFromSuperview()
                self?.parseDownloadedGif(url: url,
                                        data: data,
                                        error: error,
                                        manager: manager,
                                        loopCount: loopCount,
                                        levelOfIntegrity: levelOfIntegrity)
            }
        }
        
        task.resume()
        
        return task
    }
    
    private func createLoader(from view: UIView? = nil) -> UIView {
        let loader = view ?? UIActivityIndicatorView()
        addSubview(loader)
        loader.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraint(NSLayoutConstraint(
            item: loader,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1,
            constant: 0))
        
        addConstraint(NSLayoutConstraint(
            item: loader,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerY,
            multiplier: 1,
            constant: 0))
        
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
            if gifURLDidFinish != nil {
                gifURLDidFinish!(self)
            }
        } catch {
            report(url: url, error: error)
        }
    }
    
    private func report(url: URL, error: Error?) {
        if gifURLDidFail != nil {
            gifURLDidFail!(self,url,error)
        }
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
    func startAnimatingGif() {
        isPlaying = true
    }
    
    /// Stop displaying the gif for this UIImageView.
    func stopAnimatingGif() {
        isPlaying = false
    }
    
    /// Check if this imageView is currently playing a gif
    ///
    /// - Returns wether the gif is currently playing
    func isAnimatingGif() -> Bool{
        return isPlaying
    }
    
    /// Show a specific frame based on a delta from current frame
    ///
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
    ///
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
            
            if loopCount == 0 || !isDisplayedInScreen(self)  || !isPlaying {
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
    func currentFrameIndex() -> Int{
        return displayOrderIndex
    }
    
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
        if let gifImage = gifImage {
            gifImage.clear()
        }
        
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
                    if gifDidLoop != nil {
                        gifDidLoop!(self)
                    }
                } else if loopCount > 1 {
                    if gifDidLoop != nil {
                        gifDidLoop!(self)
                    }
                    loopCount -= 1
                } else {
                    if gifDidStop != nil {
                        gifDidStop!(self)
                    }
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
    private struct AssociatedKeys {
        static var UIImageViewGIFDidStartKey = malloc(4)
        static var UIImageViewGIFDidLoopKey = malloc(4)
        static var UIImageViewGIFDidStopKey = malloc(4)
        static var UIImageViewGIFURLDidFinishKey = malloc(4)
        static var UIImageViewGIFURLDidFailKey = malloc(4)
        static var UIImageViewGIFImageKey = malloc(4)
        static var UIImageViewGIFCacheKey = malloc(4)
        static var UIImageViewGIFCurrentImageKey = malloc(4)
        static var UIImageViewGIFDisplayOrderIndexKey = malloc(4)
        static var UIImageViewGIFSyncFactorKey = malloc(4)
        static var UIImageViewGIFHaveCacheKey = malloc(4)
        static var UIImageViewGIFLoopCountKey = malloc(4)
        static var UIImageViewGIFDisplayingKey = malloc(4)
        static var UIImageViewGIFIsPlayingKey = malloc(4)
        static var UIImageViewGIFAnimationManagerKey = malloc(4)
    }
    
    var gifImage: UIImage? {
        get { return possiblyNil(AssociatedKeys.UIImageViewGIFImageKey) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFImageKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var currentImage: UIImage? {
        get { return possiblyNil(AssociatedKeys.UIImageViewGIFCurrentImageKey) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFCurrentImageKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var displayOrderIndex: Int {
        get { return value(AssociatedKeys.UIImageViewGIFDisplayOrderIndexKey, 0) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFDisplayOrderIndexKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var syncFactor: Int {
        get { return value(AssociatedKeys.UIImageViewGIFSyncFactorKey, 0) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFSyncFactorKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var loopCount: Int {
        get { return value(AssociatedKeys.UIImageViewGIFLoopCountKey, 0) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFLoopCountKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var animationManager: PTGifManager? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.UIImageViewGIFAnimationManagerKey!) as? PTGifManager) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFAnimationManagerKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
        
    private var haveCache: Bool {
        get { return value(AssociatedKeys.UIImageViewGIFHaveCacheKey, false) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFHaveCacheKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var displaying: Bool {
        get { return value(AssociatedKeys.UIImageViewGIFDisplayingKey, false) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFDisplayingKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var gifDidStart:PTGIFImageTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.UIImageViewGIFDidStartKey!) as? PTGIFImageTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFDidStartKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    var gifDidLoop:PTGIFImageTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.UIImageViewGIFDidLoopKey!) as? PTGIFImageTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFDidLoopKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    var gifDidStop:PTGIFImageTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.UIImageViewGIFDidStopKey!) as? PTGIFImageTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFDidStopKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    var gifURLDidFinish:PTGIFImageTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.UIImageViewGIFURLDidFinishKey!) as? PTGIFImageTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFURLDidFinishKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    var gifURLDidFail:PTGIFImageFailTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.UIImageViewGIFURLDidFailKey!) as? PTGIFImageFailTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFURLDidFailKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    private var isPlaying: Bool {
        get {
            return value(AssociatedKeys.UIImageViewGIFIsPlayingKey, false)
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFIsPlayingKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if newValue {
                if gifDidStart != nil {
                    gifDidStart!(self)
                }
            }
        }
    }
    
    private var cache: NSCache<AnyObject, AnyObject>? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.UIImageViewGIFCacheKey!) as? NSCache) }
        set { objc_setAssociatedObject(self, AssociatedKeys.UIImageViewGIFCacheKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private func value<T>(_ key:UnsafeMutableRawPointer?, _ defaultValue:T) -> T {
        return (objc_getAssociatedObject(self, key!) as? T) ?? defaultValue
    }
    
    private func possiblyNil<T>(_ key:UnsafeMutableRawPointer?) -> T? {
        let result = objc_getAssociatedObject(self, key!)
        
        if result == nil {
            return nil
        }
        
        return (result as? T)
    }
}

#endif
