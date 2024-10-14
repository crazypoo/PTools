//
//  NSImageView+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/1/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(macOS)

import ImageIO
import AppKit

public typealias PTGIFImageTask = (NSImageView) -> Void
public typealias PTGIFImageFailTask = (NSImageView,URL,Error?) -> Void

public extension NSImageView {
    /// Set an image and a manager to an existing NSImageView. If the image is not an GIF image, set it in normal way and remove self form SwiftyGifManager
    ///
    /// WARNING : this overwrite any previous gif.
    /// - Parameter gifImage: The NSImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    /// - Parameter loopCount: The number of loops we want for this gif. -1 means infinite.
    func setImage(_ image: NSImage, manager: PTGifManager = .defaultManager, loopCount: Int = -1) {
        if let _ = image.imageData {
            setGifImage(image, manager: manager, loopCount: loopCount)
        } else {
            manager.deleteImageView(self)
            self.image = image
        }
    }
}

public extension NSImageView {
    
    // MARK: - Inits
    
    /// Convenience initializer. Creates a gif holder (defaulted to infinite loop).
    ///
    /// - Parameter gifImage: The NSImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    convenience init(gifImage: NSImage, manager: PTGifManager = .defaultManager, loopCount: Int = -1) {
        self.init()
        setGifImage(gifImage,manager: manager, loopCount: loopCount)
    }
    
    /// Convenience initializer. Creates a gif holder (defaulted to infinite loop).
    ///
    /// - Parameter gifImage: The NSImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    convenience init(gifURL: URL, manager: PTGifManager = .defaultManager, loopCount: Int = -1) {
        self.init()
        setGifFromURL(gifURL, manager: manager, loopCount: loopCount)
    }
    
    /// Set a gif image and a manager to an existing NSImageView.
    ///
    /// WARNING : this overwrite any previous gif.
    /// - Parameter gifImage: The NSImage containing the gif backing data
    /// - Parameter manager: The manager to handle the gif display
    /// - Parameter loopCount: The number of loops we want for this gif. -1 means infinite.
    func setGifImage(_ gifImage: NSImage, manager: PTGifManager = .defaultManager, loopCount: Int = -1) {
        if let imageData = gifImage.imageData, (gifImage.imageCount ?? 0) < 1 {
            image = NSImage(data: imageData)
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
            currentImage = NSImage(cgImage: cgImage, size: .zero)
            
            if manager.addImageView(self) {
                startDisplay()
                startAnimatingGif()
            }
        }
    }
}

// MARK: - Download gif

public extension NSImageView {
    
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
                       customLoader: NSView? = nil) -> URLSessionDataTask? {
        
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
        
        let loader: NSView? = showLoader ? createLoader(from: customLoader) : nil
        
        let task = session.dataTask(with: url) { [weak self] data, _, error in
            PTGCDManager.gcdMain {
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
    
    private func createLoader(from view: NSView? = nil) -> NSView {
        let loader = view ?? {
            let indicator = NSProgressIndicator()
            indicator.style = .spinning
            return indicator
        }()
        
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
        
        (loader as? NSProgressIndicator)?.startAnimation(nil)
        
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
            let image = try NSImage(gifData: data, levelOfIntegrity: levelOfIntegrity)
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

public extension NSImageView {
    
    /// Start displaying the gif for this NSImageView.
    private func startDisplay() {
        displaying = true
        updateCache()
    }
    
    /// Stop displaying the gif for this NSImageView.
    private func stopDisplay() {
        displaying = false
        updateCache()
    }
    
    /// Start displaying the gif for this NSImageView.
    func startAnimatingGif() {
        isPlaying = true
    }
    
    /// Stop displaying the gif for this NSImageView.
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
        if haveCache, let image = cache?.object(forKey: displayOrderIndex as AnyObject) as? NSImage {
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
    func frameAtIndex(index: Int) -> NSImage {
        guard let gifImage = gifImage,
            let imageSource = gifImage.imageSource,
            let displayOrder = gifImage.displayOrder, index < displayOrder.count,
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, displayOrder[index], nil) else {
                return NSImage()
        }
        
        return NSImage(cgImage: cgImage, size: .zero)
    }
    
    /// Check if the imageView has been discarded and is not in the view hierarchy anymore.
    ///
    /// - Returns : A boolean for weather the imageView was discarded
    func isDiscarded(_ imageView: NSView?) -> Bool {
        return imageView?.superview == nil
    }
    
    /// Check if the imageView is displayed.
    ///
    /// - Returns : A boolean for weather the imageView is displayed
    func isDisplayedInScreen(_ imageView: NSView?) -> Bool {
        guard !isHidden, window != nil, let imageView = imageView else  {
            return false
        }

        for screen in NSScreen.screens {
          let screenRect = screen.visibleFrame
          let viewRect = imageView.convert(bounds, to: nil)
          let intersectionRect = viewRect.intersection(screenRect)

          if !intersectionRect.isEmpty && !intersectionRect.isNull {
            // The image view is visible on a screen
            return true
          }
        }

        return false
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
            
            cache.setObject(NSImage(cgImage: cgImage, size: .zero), forKey: i as AnyObject)
        }
    }
}

// MARK: - Dynamic properties
public extension NSImageView {
    
    private struct AssociatedKeys {
        static var NSImageViewGIFDidStartKey = malloc(4)
        static var NSImageViewGIFDidLoopKey = malloc(4)
        static var NSImageViewGIFDidStopKey = malloc(4)
        static var NSImageViewGIFURLDidFinishKey = malloc(4)
        static var NSImageViewGIFURLDidFailKey = malloc(4)
        static var NSImageViewGIFImageKey = malloc(4)
        static var NSImageViewGIFCacheKey = malloc(4)
        static var NSImageViewGIFCurrentImageKey = malloc(4)
        static var NSImageViewGIFDisplayOrderIndexKey = malloc(4)
        static var NSImageViewGIFSyncFactorKey = malloc(4)
        static var NSImageViewGIFHaveCacheKey = malloc(4)
        static var NSImageViewGIFLoopCountKey = malloc(4)
        static var NSImageViewGIFDisplayingKey = malloc(4)
        static var NSImageViewGIFIsPlayingKey = malloc(4)
        static var NSImageViewGIFAnimationManagerKey = malloc(4)
    }

    var gifImage: NSImage? {
        get { return possiblyNil(AssociatedKeys.NSImageViewGIFImageKey) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFImageKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var currentImage: NSImage? {
        get { return possiblyNil(AssociatedKeys.NSImageViewGIFCurrentImageKey) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFCurrentImageKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var displayOrderIndex: Int {
        get { return value(AssociatedKeys.NSImageViewGIFDisplayOrderIndexKey, 0) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFDisplayOrderIndexKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var syncFactor: Int {
        get { return value(AssociatedKeys.NSImageViewGIFSyncFactorKey, 0) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFSyncFactorKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var loopCount: Int {
        get { return value(AssociatedKeys.NSImageViewGIFLoopCountKey, 0) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFLoopCountKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var animationManager: PTGifManager? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.NSImageViewGIFAnimationManagerKey!) as? PTGifManager) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFAnimationManagerKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
        
    private var haveCache: Bool {
        get { return value(AssociatedKeys.NSImageViewGIFHaveCacheKey, false) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFHaveCacheKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var displaying: Bool {
        get { return value(AssociatedKeys.NSImageViewGIFDisplayingKey, false) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFDisplayingKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var gifDidStart:PTGIFImageTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.NSImageViewGIFDidStartKey!) as? PTGIFImageTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFDidStartKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    var gifDidLoop:PTGIFImageTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.NSImageViewGIFDidLoopKey!) as? PTGIFImageTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFDidLoopKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    var gifDidStop:PTGIFImageTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.NSImageViewGIFDidStopKey!) as? PTGIFImageTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFDidStopKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    var gifURLDidFinish:PTGIFImageTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.NSImageViewGIFURLDidFinishKey!) as? PTGIFImageTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFURLDidFinishKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    var gifURLDidFail:PTGIFImageFailTask? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.NSImageViewGIFURLDidFailKey!) as? PTGIFImageFailTask) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFURLDidFailKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }

    private var isPlaying: Bool {
        get {
            return value(AssociatedKeys.NSImageViewGIFIsPlayingKey, false)
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFIsPlayingKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if newValue {
                if gifDidStart != nil {
                    gifDidStart!(self)
                }
            } else {
                if gifDidStop != nil {
                    gifDidStop!(self)
                }
            }
        }
    }
    
    private var cache: NSCache<AnyObject, AnyObject>? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.NSImageViewGIFCacheKey!) as? NSCache) }
        set { objc_setAssociatedObject(self, AssociatedKeys.NSImageViewGIFCacheKey!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
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
