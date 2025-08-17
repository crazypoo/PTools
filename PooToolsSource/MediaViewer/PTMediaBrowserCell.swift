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

class PTMediaBrowserCell: PTBaseNormalCell {
    static let ID = "PTMediaBrowserCell"
    
    var viewerDismissBlock:PTActionTask?
    var zoomTask:PTBoolTask?
    var tapTask:PTActionTask?
    var currentCellType:PTViewerDataType = .None
    var longTapWakeUp:PTActionTask?
    var imageLongTaped:Bool = false
    var videoPlayHandler:((AVPlayerViewController) -> Void)!
    
    let maxZoomSale:CGFloat = 2
    let minZoomSale:CGFloat = 0.6
    
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

    var viewConfig:PTMediaBrowserConfig!
    var dataModel:PTMediaBrowserModel! {
        didSet {
            if viewConfig.dynamicBackground {
                effectView.frame = contentView.frame
                backgroundImageView.frame = effectView.frame
                contentView.insertSubview(effectView, at: 0)
                contentView.insertSubview(backgroundImageView, at: 0)
            } else {
                effectView.removeFromSuperview()
                backgroundImageView.removeFromSuperview()
            }
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
            self.reloadButton.removeFromSuperview()
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
        view.imageView?.contentMode = .scaleAspectFit
        view.setImage(self.viewConfig.playButtonImage, for: .normal)
        return view
    }()
    
    fileprivate lazy var livePhoto:PHLivePhotoView = {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.delegate = self
        view.backgroundColor = .clear
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        contentView.addSubview(contentScrolView)
        contentScrolView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentScrolView.addSubview(imageView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adjustFrame(normal:Bool = true,fixed:PTActionTask? = nil) {
        var zoomSize:CGSize = .zero
        if let gifImage = gifImage {
            let imageSize = gifImage.size
            let imageFrame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
            
            contentScrolView.contentSize = imageFrame.size
            let iamgeHeight = CGFloat.kSCREEN_WIDTH / imageSize.width * imageSize.height
            zoomSize = CGSize(width: CGFloat.kSCREEN_WIDTH, height: iamgeHeight)
            if normal {
                livePhoto.alpha = 0
                livePhoto.isHidden = true
                imageView.alpha = 1
                imageView.isHidden = false
                imageView.snp.remakeConstraints { make in
                    make.width.equalTo(CGFloat.kSCREEN_WIDTH)
                    make.height.equalTo(iamgeHeight)
                    make.centerX.centerY.equalToSuperview()
                }
            } else {
                imageView.alpha = 0
                imageView.isHidden = true
                livePhoto.alpha = 1
                livePhoto.isHidden = false
                livePhoto.snp.remakeConstraints { make in
                    make.width.equalTo(CGFloat.kSCREEN_WIDTH)
                    make.height.equalTo(iamgeHeight)
                    make.centerX.centerY.equalToSuperview()
                }
            }
            
            var maxScale = frame.size.height / imageFrame.size.height
            maxScale = frame.size.width / imageFrame.width > maxScale ? frame.width / imageFrame.width : maxScale
            maxScale = maxScale > maxZoomSale ? maxScale : maxZoomSale
            contentScrolView.minimumZoomScale = minZoomSale
            contentScrolView.maximumZoomScale = maxScale
            contentScrolView.zoomScale = 1
        } else {
            zoomSize = frame.size
            frame.origin = .zero
            if normal {
                imageView.frame = frame
                contentScrolView.contentSize = zoomSize
            } else {
                livePhoto.frame = frame
                contentScrolView.contentSize = zoomSize
            }
        }
        contentScrolView.contentOffset = .zero
        zoomImageSize = zoomSize
        fixed?()
    }
            
    func createReloadButton() {
        contentView.addSubview(reloadButton)
        let reloadMaxWidth = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2
        reloadButton.setTitle(self.viewConfig.imageReloadButton, for: .normal)
        var reloadWidth = reloadButton.sizeFor(height: 34).width + 16
        var baseHeight:CGFloat = 34
        if reloadWidth > reloadMaxWidth {
            reloadWidth = reloadMaxWidth
            baseHeight = reloadButton.sizeFor(lineSpacing: 2.5,width: reloadMaxWidth).height + 16
        }
        reloadButton.snp.makeConstraints { make in
            make.width.equalTo(reloadWidth)
            make.height.equalTo(baseHeight)
            make.centerY.centerX.equalToSuperview()
        }
        bringSubviewToFront(reloadButton)
    }
        
    open class func centerOfScrollVIewContent(scrollView:UIScrollView) -> CGPoint {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? ((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5) : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? ((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5) : 0
        let actualCenter = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        return actualCenter
    }
    
    private func clearContentView() {
        gifImage = nil
        reloadButton.removeFromSuperview()
    }
    
    func cellLoadData() {
        PTGCDManager.gcdMain {
            let loading = PTMediaBrowserLoadingView(type: .LoopDiagram)
            self.contentView.addSubview(loading)
            loading.snp.makeConstraints { make in
                make.width.height.equalTo(50)
                make.centerX.centerY.equalToSuperview()
            }
            
            switch self.dataModel.imageURL {
            case let urlString as String:
                self.loadDataUrl(loadUrl: urlString, loading: loading)
            case let url as URL:
                self.loadDataUrl(loadUrl: url.absoluteString, loading: loading)
            case let avItem as AVPlayerItem:
                self.videoAVItem(avItem: avItem, loading: loading)
            case let avAsset as AVAsset:
                let avPlayerItem = AVPlayerItem(asset: avAsset)
                self.videoAVItem(avItem: avPlayerItem, loading: loading)
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
                    self.contentScrolView.addSubviews([self.livePhoto])
                    self.livePhoto.livePhoto = livePhotoTarget
                    self.adjustFrame(normal: false) {
                        self.livePhoto.startPlayback(with: .hint)
                    }
                    self.setupGestureRecognizers(normal: false)
                }
            default:
                self.baseLoadImageData(imageData: self.dataModel.imageURL as Any, loading: loading)
            }
        }
    }
    
    func loadDataUrl(loadUrl:String,loading:PTMediaBrowserLoadingView) {
        if !loadUrl.isEmpty {
            if ["mp4","mov"].contains(loadUrl.pathExtension.lowercased()) {
                self.videoUrlLoad(url: loadUrl, loading: loading)
            } else {
                if !loadUrl.stringIsEmpty() {
                    self.setImageTypeView(url:loadUrl,loading: loading)
                } else {
                    self.currentCellType = .None
                    self.createReloadButton()
                    self.adjustFrame()
                    loading.removeFromSuperview()
                }
            }
        } else {
            self.currentCellType = .None
            self.createReloadButton()
            self.adjustFrame()
            loading.removeFromSuperview()
        }
    }
            
    func prepareForHide() {
        contentView.addSubview(tempView)
        contentView.backgroundColor = .clear
        imageView.alpha = 0
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
                self.contentScrolView.bringSubviewToFront(self.playBtn)
            }
        }
    }
}

//MARK: Image handling logic
extension PTMediaBrowserCell {
    func setImageTypeView(url:String,loading:PTMediaBrowserLoadingView) {
        clearContentView()
        setupGestureRecognizers()
        loadImageData(url:url,loading: loading)
    }
    
    private func loadImageData(url:String,loading: PTMediaBrowserLoadingView) {
        baseLoadImageData(imageData: url, loading: loading)
     }
    
    private func baseLoadImageData(imageData:Any,loading: PTMediaBrowserLoadingView) {
        imageView.loadImage(contentData: imageData, iCloudDocumentName: viewConfig.iCloudDocumentName, emptyImage: UIImage()) { receivedSize, totalSize in
            PTGCDManager.gcdMain {
                let progress = CGFloat(receivedSize / totalSize)
                loading.progress = progress
            }
        } loadFinish: { images, image,gifTime in
            PTGCDManager.gcdMain {
                self.handleImageLoadFinish(images: images, image: image, loading: loading,time: gifTime)
            }
        }
    }

    private func handleImageLoadFinish(images: [UIImage]?, image: UIImage?, loading: PTMediaBrowserLoadingView,time:TimeInterval) {
        if let images = images, images.count > 1 {
            currentCellType = .GIF
            gifImage = image
            if viewConfig.dynamicBackground {
                backgroundImageView.image = UIImage.animatedImage(with: images, duration: time)
            }
        } else if let images = images, images.count == 1 {
            currentCellType = .Normal
            gifImage = image
            if viewConfig.dynamicBackground {
                backgroundImageView.image = images.first
            }
        } else {
            currentCellType = .None
            createReloadButton()
        }
        adjustFrame()
        loading.removeFromSuperview()
    }
}

//MARK: Video handling logic
extension PTMediaBrowserCell {
    func videoUrlLoad(url:String,loading:PTMediaBrowserLoadingView) {
        imageView.image = UIImage()
        gifImage = nil
        reloadButton.removeFromSuperview()
        handleVideoLoading(loading: loading, videoUrl: url)
    }

    func handleVideoLoading(loading: PTMediaBrowserLoadingView, videoUrl: String) {
        
        UIImage.pt.getVideoFirstImage(videoUrl: videoUrl) { image in
            PTGCDManager.gcdMain {
                if let image = image {
                    self.setupVideoView(image: image, videoUrl: videoUrl, loading: loading)
                } else {
                    self.handleVideoLoadError(loading: loading)
                }
            }
        }
    }
    
    private func setupVideoView(image: UIImage, videoUrl: String, loading: PTMediaBrowserLoadingView) {
        currentCellType = .Video
        loading.removeFromSuperview()
        
        contentScrolView.addSubviews([imageView, playBtn])
        playBtn.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.centerX.centerY.equalToSuperview()
        }
        
        let singleTap = UITapGestureRecognizer { sender in
            self.tapTask?()
        }
        singleTap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(singleTap)
        
        gifImage = image
        imageView.image = image
        adjustFrame()
        if viewConfig.dynamicBackground {
            backgroundImageView.image = image
        }
        
        reloadButton.removeFromSuperview()
        playBtn.addActionHandlers { sender in
            let videoController = AVPlayerViewController()
            videoController.player = AVPlayer(url: URL(string: videoUrl)!)
            self.videoPlayHandler(videoController)
        }
    }
    
    private func handleVideoLoadError(loading: PTMediaBrowserLoadingView) {
        gifImage = nil
        imageView.contentMode = .scaleAspectFit
        contentScrolView.addSubview(imageView)
        imageView.image = UIImage()
        currentCellType = .None
        loading.removeFromSuperview()
        createReloadButton()
    }
    
    private func videoAVItem(avItem:AVPlayerItem,loading:PTMediaBrowserLoadingView) {
        reloadButton.removeFromSuperview()
        imageView.image = UIImage()
        gifImage = nil
        avItem.generateThumbnail { image in
            PTGCDManager.gcdMain {
                if image != nil {
                    self.currentCellType = .Video
                    loading.removeFromSuperview()
                    self.contentScrolView.addSubviews([self.imageView,self.playBtn])
                    self.playBtn.snp.makeConstraints { make in
                        make.width.height.equalTo(44)
                        make.centerX.centerY.equalToSuperview()
                    }
                    
                    let singleTap = UITapGestureRecognizer { sender in
                        self.tapTask?()
                    }
                    singleTap.numberOfTapsRequired = 1
                    self.imageView.addGestureRecognizer(singleTap)
                    
                    self.gifImage = image
                    self.imageView.image = image
                    self.adjustFrame()
                    if self.viewConfig.dynamicBackground {
                        self.backgroundImageView.image = image
                    }
                    self.playBtn.addActionHandlers { sender in
                        let videoController = AVPlayerViewController()
                        videoController.player = AVPlayer(playerItem: avItem)
                        self.videoPlayHandler(videoController)
                    }
                } else {
                    self.gifImage = nil
                    self.imageView.contentMode = .scaleAspectFit
                    self.contentScrolView.addSubview(self.imageView)
                    self.imageView.image = UIImage()
                    self.currentCellType = .None
                    loading.removeFromSuperview()
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

//MARK: Image Ges
extension PTMediaBrowserCell {
    private func setupGestureRecognizers(normal:Bool = true) {
        if normal {
            let doubleTap = UITapGestureRecognizer { sender in
                if let ges = sender as? UITapGestureRecognizer {
                    let touchPoint = ges.location(in: self)
                    if self.contentScrolView.zoomScale <= 1 {
                        self.zoomTask?(true)
                        let scaleX = touchPoint.x + self.contentScrolView.contentOffset.x
                        let scaleY = touchPoint.y + self.contentScrolView.contentOffset.y
                        self.contentScrolView.zoom(to: CGRect(x: scaleX, y: scaleY, width: 10, height: 10), animated: true)
                    } else {
                        self.zoomTask?(false)
                        self.contentScrolView.setZoomScale(1, animated: true)
                    }
                }
            }
            doubleTap.numberOfTapsRequired = 2
            
            let singleTap = UITapGestureRecognizer { sender in
                self.tapTask?()
            }
            singleTap.numberOfTapsRequired = 1
            
            var imageActions:[UIGestureRecognizer] = [singleTap,doubleTap]
            if viewConfig.imageLongTapAction {
                let longTap = UILongPressGestureRecognizer { sender in
                    if !self.imageLongTaped {
                        self.longTapWakeUp?()
                        self.imageLongTaped = true
                    }
                }
                longTap.minimumPressDuration = 1.5
                imageActions = [singleTap,doubleTap,longTap]
            }

            imageView.addGestureRecognizers(imageActions)
        } else {
            let longpress = UILongPressGestureRecognizer { sender in
                self.livePhoto.startPlayback(with: .hint)
            }
            longpress.minimumPressDuration = 1
            livePhoto.addGestureRecognizers([longpress])
        }
    }
}

extension PTMediaBrowserCell : PHLivePhotoViewDelegate { }
