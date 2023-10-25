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

class PTMediaBrowserCell: PTBaseNormalCell {
    static let ID = "PTMediaBrowserCell"
    
    var viewerDismissBlock:PTActionTask?
    var zoomTask:((Bool)->Void)?
    var tapTask:PTActionTask?
    var currentCellType:PTViewerDataType = .None
    
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
            if self.viewConfig.dynamicBackground {
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
        
        var tempImageX:CGFloat = 0
        var tempImageY:CGFloat = 0

        tempImageX = self.imageView.frame.origin.x - self.scrollOffset!.x
        tempImageY = self.imageView.frame.origin.y - self.scrollOffset!.y

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
        view.frame = CGRect.init(x: tempImageX, y: tempImageY, width: tempImageW, height: tempImageH)
        view.image = self.gifImage
        return view
    }()

    //MARK: 图片相关
    fileprivate var scrollOffset:CGPoint? = CGPoint.zero
    public lazy var zoomImageSize:CGSize? = CGSize.init(width: frame.size.width, height: frame.size.height)
    
    fileprivate lazy var reloadButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.viewCorner(radius: 2,borderWidth:1,borderColor: .white)
        view.titleLabel?.font = self.viewConfig.viewerFont
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        view.setTitle("图片加载失败,点击重试", for: .normal)
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
        return view
    }()
    
    var gifImage:UIImage? = nil

    //MARK: 视频相关        
    fileprivate lazy var playBtn:UIButton = {
        
        let view = UIButton.init(type: .custom)
        view.imageView?.contentMode = .scaleAspectFit
        view.setImage(self.viewConfig.playButtonImage, for: .normal)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        contentView.addSubview(contentScrolView)
        contentScrolView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adjustFrame() {
        if gifImage != nil {
            let imageSize = gifImage!.size
            let imageFrame = CGRect.init(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
            
            contentScrolView.contentSize = imageFrame.size
            
            let iamgeHeight = CGFloat.kSCREEN_WIDTH / imageSize.width * imageSize.height
            imageView.frame = CGRectMake(0, (CGFloat.kSCREEN_HEIGHT - iamgeHeight) / 2, CGFloat.kSCREEN_WIDTH, iamgeHeight)
            
            var maxScale = frame.size.height / imageFrame.size.height
            maxScale = frame.size.width / imageFrame.width > maxScale ? frame.width / imageFrame.width : maxScale
            maxScale = maxScale > maxZoomSale ? maxScale : maxZoomSale
            contentScrolView.minimumZoomScale = minZoomSale
            contentScrolView.maximumZoomScale = maxScale
            contentScrolView.zoomScale = 1
        } else {
            frame.origin = .zero
            imageView.frame = frame
            contentScrolView.contentSize = imageView.frame.size
        }
        contentScrolView.contentOffset = .zero
        zoomImageSize = imageView.frame.size
    }
            
    func createReloadButton() {
        contentView.addSubview(reloadButton)
        reloadButton.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.height.equalTo(34)
            make.centerY.centerX.equalToSuperview()
        }
        bringSubviewToFront(reloadButton)
    }
        
    open class func centerOfScrollVIewContent(scrollView:UIScrollView) ->CGPoint {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? ((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5) : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? ((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5) : 0
        let actualCenter = CGPoint.init(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        return actualCenter
    }
    
    func setImageTypeView(loading:PTMediaBrowserLoadingView) {
        self.gifImage = nil
        self.imageView.contentMode = .scaleAspectFit
        self.contentScrolView.addSubview(self.imageView)
        
        let doubleTap = UITapGestureRecognizer.init { sender in
            let touchPoint = (sender as! UITapGestureRecognizer).location(in: self)
            if self.contentScrolView.zoomScale <= 1 {
                if self.zoomTask != nil {
                    self.zoomTask!(true)
                }
                let scaleX = touchPoint.x + self.contentScrolView.contentOffset.x
                let scaleY = touchPoint.y + self.contentScrolView.contentOffset.y
                self.contentScrolView.zoom(to: CGRect.init(x: scaleX, y: scaleY, width: 10, height: 10), animated: true)
            } else {
                if self.zoomTask != nil {
                    self.zoomTask!(false)
                }
                self.contentScrolView.setZoomScale(1, animated: true)
            }
        }
        doubleTap.numberOfTapsRequired = 2
        self.imageView.addGestureRecognizer(doubleTap)
        
        let singleTap = UITapGestureRecognizer.init { sender in
            if self.tapTask != nil {
                self.tapTask!()
            }
        }
        singleTap.numberOfTapsRequired = 1
        self.imageView.addGestureRecognizer(singleTap)

        PTLoadImageFunction.loadImage(contentData: self.dataModel.imageURL as Any,iCloudDocumentName: self.viewConfig.iCloudDocumentName) { receivedSize, totalSize in
            loading.progress = CGFloat(receivedSize / totalSize)
        } taskHandle: { images,image in
            if (images?.count ?? 0) > 1 {
                self.currentCellType = .GIF
                self.gifImage = image
                self.imageView.animationImages = images
                self.imageView.animationDuration = 2
                self.imageView.startAnimating()
                if self.viewConfig.dynamicBackground {
                    self.backgroundImageView.animationImages = images
                    self.imageView.animationDuration = 2
                    self.imageView.startAnimating()
                }

                self.adjustFrame()
                loading.removeFromSuperview()
            } else if images?.count == 1 {
                self.currentCellType = .Normal
                self.gifImage = image
                self.imageView.image = images!.first
                if self.viewConfig.dynamicBackground {
                    self.backgroundImageView.image = images!.first
                }

                self.adjustFrame()
                loading.removeFromSuperview()
            } else {
                self.currentCellType = .None
                loading.removeFromSuperview()
                self.createReloadButton()
                self.adjustFrame()
            }
        }
    }
    
    func cellLoadData() {
        
        let loading = PTMediaBrowserLoadingView(type: .LoopDiagram)
        addSubview(loading)
        loading.snp.makeConstraints { make in
            make.width.height.equalTo(50)
            make.centerX.centerY.equalToSuperview()
        }
        
        if self.dataModel.imageURL is String {
            let urlString = self.dataModel.imageURL as! String

            UIImage.pt.getVideoFirstImage(videoUrl: urlString, closure: { image in
                if image == nil {
                    self.setImageTypeView(loading: loading)
                } else {
                    self.currentCellType = .Video
                    loading.removeFromSuperview()
                    self.contentScrolView.addSubviews([self.imageView,self.playBtn])
                    self.playBtn.snp.makeConstraints { make in
                        make.width.height.equalTo(44)
                        make.centerX.centerY.equalToSuperview()
                    }
                    
                    let singleTap = UITapGestureRecognizer.init { sender in
                        if self.tapTask != nil {
                            self.tapTask!()
                        }
                    }
                    singleTap.numberOfTapsRequired = 1
                    self.imageView.addGestureRecognizer(singleTap)

                    if self.dataModel.imageURL is String {
                        self.gifImage = nil

                        var videoUrl:NSURL?
                        let urlString = self.dataModel.imageURL as! String
                        if FileManager.pt.judgeFileOrFolderExists(filePath: urlString) {
                            videoUrl = NSURL.init(fileURLWithPath: urlString)
                        } else {
                            videoUrl = NSURL.init(string: urlString.nsString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
                        }
                        
                        self.gifImage = image
                        self.imageView.image = image
                        self.adjustFrame()
                        if self.viewConfig.dynamicBackground {
                            self.backgroundImageView.image = image
                        }

                        self.playBtn.addActionHandlers() { sender in
                            let videoController = AVPlayerViewController()
                            videoController.player = AVPlayer(url: videoUrl! as URL)

                            PTUtils.getCurrentVC().present(videoController, animated: true) {
                              videoController.player?.play()
                            }
                        }
                    }
                }
            })
        } else {
            self.setImageTypeView(loading: loading)
        }
    }
    
    func prepareForHide() {
        self.contentView.addSubview(tempView)
        self.contentView.backgroundColor = .clear
        self.imageView.alpha = 0
    }
    
    func hideAnimation() {
        self.contentView.isUserInteractionEnabled = false
        let window = AppWindows!
        var targetTemp:CGRect? = CGRect.init(x: window.center.x, y: window.center.y, width: 0, height: 0)
        targetTemp = self.contentView.convert(self.contentView.frame, to: self.contentView)

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

            if self.viewerDismissBlock != nil {
                self.viewerDismissBlock!()
            }
        }
    }

    func bounceToOriginal() {
        self.contentScrolView.isUserInteractionEnabled = true
        self.contentView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.35) {
            self.tempView.transform = CGAffineTransform.identity
            self.contentView.alpha = 1
        } completion: { finish in
            self.contentView.isUserInteractionEnabled = true
            self.tempView.removeFromSuperview()
            self.imageView.alpha = 1
            self.contentView.alpha = 1
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
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = PTMediaBrowserCell.centerOfScrollVIewContent(scrollView: scrollView)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollOffset = scrollView.contentOffset
    }
}

