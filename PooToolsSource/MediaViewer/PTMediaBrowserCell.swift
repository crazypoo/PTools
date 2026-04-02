//
//  PTMediaBrowserCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AVFoundation
import AVKit
import Kingfisher
import Photos
import PhotosUI
#if POOTOOLS_VIDEOCACHE
import KTVHTTPCache
#endif

class PTMediaBrowserCell: PTBaseNormalCell {
    static let ID = "PTMediaBrowserCell"
    
    let videoExts: Set<String> = ["mp4","mov","m4v","avi","mkv","3gp","webm"]

    var viewerDismissBlock:PTActionTask?
    var zoomTask:PTBoolTask?
    var tapTask:PTActionTask?
    var currentCellType:PTViewerDataType = .None
    var longTapWakeUp:PTActionTask?
    var imageLongTaped:Bool = false
    var videoPlayHandler:((PTPlayerViewController) -> Void)?
    
    let maxZoomSale:CGFloat = 2
    let minZoomSale:CGFloat = 0.6
    fileprivate var videoCacheURL:URL?
    
    private var hasSetupGesture = false

    lazy var contentScrolView:UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.clipsToBounds = true
        return view
    }()

    lazy var effectView: UIVisualEffectView = {
      let effect = UIBlurEffect(style: .dark)
      let view = UIVisualEffectView(effect: effect)
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      return view
    }()

    lazy var backgroundImageView: UIImageView = {
      let view = UIImageView()
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      return view
    }()

    let viewConfig = PTMediaBrowserConfig.share
    
    var dataModel:PTMediaBrowserModel! {
        didSet {
            self.cellLoadData()
        }
    }

    lazy var tempView:UIImageView = {
        let view = UIImageView()
        
        let tempImageX:CGFloat = self.imageView.frame.origin.x - self.scrollOffset!.x
        var tempImageY:CGFloat = self.imageView.frame.origin.y - self.scrollOffset!.y

        let tempImageW = self.zoomImageSize!.width
        var tempImageH = self.zoomImageSize!.height
        
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape {
            if tempImageH > self.frame.size.height {
                tempImageH = tempImageH > (tempImageW * 1.5) ? (tempImageW * 1.5) : tempImageH
                if abs(tempImageY) > tempImageH {
                    tempImageY = 0
                }
            }
        }
        
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.frame = CGRect(x: tempImageX, y: tempImageY, width: tempImageW, height: tempImageH)
        view.image = self.gifImage
        return view
    }()

    //MARK: 图片相关
    fileprivate var scrollOffset:CGPoint? = CGPoint.zero
    fileprivate lazy var zoomImageSize:CGSize? = CGSize(width: frame.size.width, height: frame.size.height)
    
    fileprivate lazy var reloadButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.viewCorner(radius: 2,borderWidth:1,borderColor: .white)
        view.titleLabel?.font = self.viewConfig.viewerFont
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        view.setTitleColor(.white, for: .normal)
        view.addActionHandlers { sender in
            self.reloadButton.isHidden = true
            self.cellLoadData()
        }
        return view
    }()
    
    lazy var imageView:UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    var gifImage:UIImage? = nil

    //MARK: 视频相关
    fileprivate lazy var playBtn:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage( viewConfig.playButtonImage, for: .normal)
        view.imageView?.contentMode = .scaleAspectFill
        return view
    }()
    
    fileprivate lazy var livePhoto:PHLivePhotoView = {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.delegate = self
        view.backgroundColor = .clear
        return view
    }()
    
    fileprivate lazy var loading: PTMediaBrowserLoadingView = {
        let view = PTMediaBrowserLoadingView(type: .LoopDiagram)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        contentView.addSubviews([backgroundImageView,effectView,contentScrolView, playBtn, loading, reloadButton])
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        effectView.isHidden = !viewConfig.dynamicBackground
        backgroundImageView.isHidden = !viewConfig.dynamicBackground
        
        contentScrolView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentScrolView.addSubviews([imageView,livePhoto])
        
        playBtn.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(viewConfig.playButtonImageSize)
        }

        loading.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(50)
        }

        reloadButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        livePhoto.isHidden = true
        loading.isHidden = true
        reloadButton.isHidden = true
        setupGestureOnce()
    }
    
    private func setupGestureOnce() {
        guard !hasSetupGesture else { return }
        hasSetupGesture = true

        imageView.removeGestureRecognizers()
        let doubleTap = UITapGestureRecognizer { sender in
            if let ges = sender as? UITapGestureRecognizer {
                if self.contentScrolView.zoomScale > 1 {
                    self.contentScrolView.setZoomScale(1, animated: true)
                    self.zoomTask?(false)
                } else {
                    let point = ges.location(in: self.imageView)
                    let rect = CGRect(x: point.x, y: point.y, width: 10, height: 10)
                    self.contentScrolView.zoom(to: rect, animated: true)
                    self.zoomTask?(true)
                }
            }
        }
        doubleTap.numberOfTapsRequired = 2

        let singleTap = UITapGestureRecognizer { sender in
            if let _ = sender as? UITapGestureRecognizer {
                self.tapTask?()
            }
        }
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)

        var imageActions:[UIGestureRecognizer] = [singleTap,doubleTap]

        if viewConfig.imageLongTapAction {
            let longTap = UILongPressGestureRecognizer { sender in
                if let _ = sender as? UILongPressGestureRecognizer {
                    if !self.imageLongTaped {
                        self.longTapWakeUp?()
                        self.imageLongTaped = true
                    }
                }
            }
            longTap.numberOfTapsRequired = 1
            longTap.minimumPressDuration = 1.5
            imageActions.append(longTap)
        }
        imageView.addGestureRecognizers(imageActions)
        
        let longPress = UILongPressGestureRecognizer { sender in
            self.livePhoto.startPlayback(with: .hint)
        }
        longPress.minimumPressDuration = 1
        livePhoto.addGestureRecognizer(longPress)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        currentCellType = .None
        gifImage = nil
        videoCacheURL = nil
        imageLongTaped = false

        imageView.image = nil
        livePhoto.livePhoto = nil

        imageView.isHidden = false
        livePhoto.isHidden = true
        playBtn.isHidden = true

        loading.isHidden = true
        reloadButton.isHidden = true

        contentScrolView.setZoomScale(1, animated: false)
        contentScrolView.contentOffset = .zero
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adjustFrame(normal:Bool = true,fixed:PTActionTask? = nil) {
        guard let image = gifImage else {
            imageView.frame = bounds
            livePhoto.frame = bounds
            contentScrolView.contentSize = bounds.size
            return
        }

        let width = bounds.width
        let height = width * (image.size.height / image.size.width)

        let frame = CGRect(x: 0,
                           y: max(0, (bounds.height - height) / 2),
                           width: width,
                           height: height)

        imageView.frame = frame
        livePhoto.frame = frame
        contentScrolView.contentSize = frame.size

        let maxScale = max(bounds.height / height, bounds.width / width, maxZoomSale)

        contentScrolView.minimumZoomScale = minZoomSale
        contentScrolView.maximumZoomScale = maxScale
        contentScrolView.zoomScale = 1

        fixed?()
    }
                    
    open class func centerOfScrollVIewContent(scrollView:UIScrollView) -> CGPoint {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? ((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5) : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? ((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5) : 0
        let actualCenter = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        return actualCenter
    }
    
    private func clearContentView() {
        gifImage = nil
        reloadButton.isHidden = true
    }
    
    func cellLoadData() {
        PTGCDManager.gcdMain {
            self.showLoading()
            
            switch self.dataModel.imageURL {
            case let urlString as String:
                self.loadDataUrl(loadUrl: urlString.urlToUnicodeURLString() ?? "")
            case let url as URL:
                self.loadDataUrl(loadUrl: url.absoluteString.urlToUnicodeURLString() ?? "")
            case let avItem as AVPlayerItem:
                self.videoAVItem(avItem: avItem)
            case let avAsset as AVAsset:
                let avPlayerItem = AVPlayerItem(asset: avAsset)
                self.videoAVItem(avItem: avPlayerItem)
            case let livePhotoTarget as PHLivePhoto:
                self.currentCellType = .LivePhoto
                PTLivePhoto.extractResources(from: livePhotoTarget) { resources in
                    if let keyPhotoPath = resources?.pairedImage {
                        if FileManager.pt.judgeFileOrFolderExists(filePath: keyPhotoPath.path) {
                            guard let keyPhotoImage = UIImage(contentsOfFile: keyPhotoPath.path) else {
                                return
                            }
                            self.gifImage = keyPhotoImage
                        }
                    }
                    self.livePhoto.livePhoto = livePhotoTarget
                    self.adjustFrame(normal: false) {
                        self.livePhoto.startPlayback(with: .hint)
                    }
                    self.livePhoto.isHidden = false
                }
            default:
                self.baseLoadImageData(imageData: self.dataModel.imageURL as Any)
            }
        }
    }
    
    func loadDataUrl(loadUrl:String) {
        if !loadUrl.isEmpty {
            if videoExts.contains(loadUrl.pathExtension.lowercased()) {
                self.videoUrlLoad(url: loadUrl)
            } else {
                if !loadUrl.stringIsEmpty() {
                    self.setImageTypeView(url:loadUrl)
                } else {
                    self.currentCellType = .None
                    self.createReloadButton()
                    self.adjustFrame()
                    self.hideLoading()
                }
            }
        } else {
            self.currentCellType = .None
            self.createReloadButton()
            self.adjustFrame()
            self.hideLoading()
        }
    }
                
    func hideAnimation() {
        contentView.isUserInteractionEnabled = false
        let window = AppWindows!
        var targetTemp:CGRect? = CGRect(x: window.center.x, y: window.center.y, width: 0, height: 0)
        targetTemp = contentView.convert(contentView.frame, to: contentView)

        window.windowLevel = .normal
        UIView.animate(withDuration: 0.35) {
            self.tempView.transform = self.contentView.transform.inverted()
            self.tempView.frame = targetTemp!
        } completion: { finish in
            self.tempView.removeFromSuperview()
            self.contentView.alpha = 0
            
            switch self.currentCellType {
            case .GIF:
                self.imageView.stopAnimating()
            default:
                break
            }
            self.viewerDismissBlock?()
        }
    }

    func bounceToOriginal() {
        contentScrolView.isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.35) {
            self.tempView.transform = CGAffineTransform.identity
            self.contentView.alpha = 1
        } completion: { finish in
            self.contentView.isUserInteractionEnabled = true
            self.tempView.removeFromSuperview()
            self.imageView.alpha = 1
            self.contentView.alpha = 1
            if self.currentCellType == .Video {
                self.playBtn.isHidden = false
                self.playBtn.isUserInteractionEnabled = true
            } else {
                self.playBtn.isHidden = true
                self.playBtn.isUserInteractionEnabled = false
            }
        }
    }
}

//MARK: Image handling logic
extension PTMediaBrowserCell {
    func setImageTypeView(url:String) {
        clearContentView()
        playBtn.isHidden = true
        playBtn.isUserInteractionEnabled = false
        loadImageData(url:url)
    }
    
    private func loadImageData(url:String) {
        baseLoadImageData(imageData: url)
     }
    
    private func baseLoadImageData(imageData:Any) {
        imageView.loadImage(contentData: imageData, iCloudDocumentName: viewConfig.iCloudDocumentName, emptyImage: UIImage()) { receivedSize, totalSize in
            PTGCDManager.gcdMain {
                let progress = CGFloat(receivedSize / totalSize)
                self.loading.progress = progress
            }
        } loadFinish: { value in
            PTGCDManager.gcdMain {
                self.handleImageLoadFinish(result:value)
            }
        }
    }

    private func handleImageLoadFinish(result:PTLoadImageResult) {
        if let images = result.allImages, images.count > 1 {
            currentCellType = .GIF
            gifImage = UIImage.animatedImage(with: images, duration: result.loadTime)
            if viewConfig.dynamicBackground {
                backgroundImageView.image = result.firstImage
            }
        } else if let images = result.allImages, images.count == 1 {
            currentCellType = .Normal
            gifImage = result.firstImage
            if viewConfig.dynamicBackground {
                backgroundImageView.image = images.first
            }
        } else {
            currentCellType = .None
            createReloadButton()
        }
        adjustFrame()
        hideLoading()
    }
}

//MARK: Video handling logic
extension PTMediaBrowserCell {
    func videoUrlLoad(url:String) {
        imageView.image = UIImage()
        gifImage = nil
        reloadButton.isHidden = true
        reloadButton.isUserInteractionEnabled = false
        playBtn.isHidden = true
        playBtn.isUserInteractionEnabled = false
        handleVideoLoading(videoUrl: url)
    }

    func handleVideoLoading(videoUrl: String) {
        if let url = URL(string: videoUrl) {
            self.videoCacheURL = PTVideoFileCache.shared.cachedFileURL(for: url)
            PTVideoCoverCache.getVideoFirstImage(videoUrl: url.absoluteString) { image in
                PTGCDManager.gcdMain {
                    if let findImage = image {
                        self.hideLoading()
                        self.setupVideoView(image: findImage, videoUrl: videoUrl)
                    } else {
                        self.handleVideoLoadError()
                    }
                }
            }
            
            if let _ = self.videoCacheURL {
            } else {
                PTVideoFileCache.shared.prepareVideo(url: url) { localURL in
                    self.videoCacheURL = localURL
                }
            }
        } else {
            self.handleVideoLoadError()
        }
    }
    
    private func setupVideoView(image: UIImage, videoUrl: String) {
        currentCellType = .Video
        hideLoading()
        
        playBtn.isHidden = false
        playBtn.isUserInteractionEnabled = true
        
        gifImage = image
        imageView.image = image
        adjustFrame()
        if viewConfig.dynamicBackground {
            backgroundImageView.image = image
        }
        
        reloadButton.isHidden = true
        reloadButton.isUserInteractionEnabled = false
        playBtn.addActionHandlers { sender in
            let videoController = PTPlayerViewController()
            if let url = URL(string: videoUrl) {
                if let findLocal = self.videoCacheURL {
                    videoController.videoPlayer = AVPlayer(url: findLocal)
                    self.videoPlayHandler?(videoController)
                } else {
#if POOTOOLS_VIDEOCACHE
                    if let proxyURL = KTVHTTPCache.proxyURL(withOriginalURL: url) {
                        let playerItem = AVPlayerItem(url: proxyURL)
                        let player = AVPlayer(playerItem: playerItem)
                        videoController.videoPlayer = player
                        self.videoPlayHandler?(videoController)
                    } else {
                        self.prepareVideoFunction(url: url, videoController: videoController)
                    }
#else
                    self.prepareVideoFunction(url: url, videoController: videoController)
#endif
                }
            } else {
                PTNSLogConsole("Video url error")
            }
        }
    }
    
    func prepareVideoFunction(url:URL,videoController:PTPlayerViewController) {
        self.showLoading()
        PTVideoFileCache.shared.prepareVideo(url: url) { _, _, progress in
            self.loading.progress = progress
        } completion: { localURL in
            self.hideLoading()
            self.videoCacheURL = localURL
            if let findLocal = localURL {
                videoController.videoPlayer = AVPlayer(url: findLocal)
                self.videoPlayHandler?(videoController)
            } else {
                PTNSLogConsole("Video url error")
            }
        }
    }
    
    private func handleVideoLoadError() {
        gifImage = nil
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage()
        currentCellType = .None
        hideLoading()
        createReloadButton()
    }
    
    private func videoAVItem(avItem:AVPlayerItem) {
        reloadButton.isHidden = true
        imageView.image = UIImage()
        gifImage = nil
        avItem.generateThumbnail { image in
            PTGCDManager.gcdMain {
                if image != nil {
                    self.currentCellType = .Video
                    self.hideLoading()
                    self.gifImage = image
                    self.imageView.image = image
                    self.adjustFrame()
                    if self.viewConfig.dynamicBackground {
                        self.backgroundImageView.image = image
                    }
                    self.playBtn.addActionHandlers { sender in
                        let videoController = PTPlayerViewController()
                        videoController.videoPlayer = AVPlayer(playerItem: avItem)
                        self.videoPlayHandler?(videoController)
                    }
                } else {
                    self.playBtn.isHidden = true
                    self.playBtn.isUserInteractionEnabled = false
                    self.gifImage = nil
                    self.imageView.contentMode = .scaleAspectFit
                    self.imageView.image = UIImage()
                    self.currentCellType = .None
                    self.hideLoading()
                    self.createReloadButton()
                }
            }
        }
    }
}

extension PTMediaBrowserCell:UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        zoomImageSize = view?.frame.size
        scrollOffset = scrollView.contentOffset
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = PTMediaBrowserCell.centerOfScrollVIewContent(scrollView: scrollView)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollOffset = scrollView.contentOffset
    }
}

extension PTMediaBrowserCell : PHLivePhotoViewDelegate { }

extension PTMediaBrowserCell {
    private func showLoading() {
        loading.isHidden = false
    }

    private func hideLoading() {
        loading.isHidden = true
    }
    
    func createReloadButton() {
        reloadButton.isHidden = false
        reloadButton.isUserInteractionEnabled = true
        bringSubviewToFront(reloadButton)
        playBtn.isHidden = true
        
        let reloadMaxWidth = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2
        reloadButton.setTitle(self.viewConfig.imageReloadButton, for: .normal)
        var reloadWidth = reloadButton.sizeFor(height: 34).width + 16
        var baseHeight:CGFloat = 34
        if reloadWidth > reloadMaxWidth {
            reloadWidth = reloadMaxWidth
            baseHeight = reloadButton.sizeFor(lineSpacing: 2.5,width: reloadMaxWidth).height + 16
        }
        reloadButton.snp.remakeConstraints { make in
            make.width.equalTo(reloadWidth)
            make.height.equalTo(baseHeight)
            make.center.equalToSuperview()
        }
    }
}
