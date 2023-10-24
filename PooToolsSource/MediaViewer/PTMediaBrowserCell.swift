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
import SceneKit
import CoreMotion
import AVFoundation
import AVKit
import Kingfisher

class PTMediaBrowserCell: PTBaseNormalCell {
    static let ID = "PTMediaBrowserCell"
    
    var viewerDismissBlock:PTActionTask?
    
    let maxZoomSale:CGFloat = 2
    let minZoomSale:CGFloat = 0.6

    var isFullWidthForLandScape:Bool = false
    
    lazy var contentScrolView:UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.clipsToBounds = true
        return view
    }()

    var viewConfig:PTViewerConfig!
    var dataModel:PTViewerModel! {
        didSet {
            self.cellLoadData()
        }
    }

    lazy var tempView:UIImageView = {
        let view = UIImageView()
        
        var tempImageX:CGFloat = 0
        var tempImageY:CGFloat = 0

        switch self.dataModel.imageShowType {
        case .GIF,.Normal:
            tempImageX = self.imageView.frame.origin.x - self.scrollOffset!.x
            tempImageY = self.imageView.frame.origin.y - self.scrollOffset!.y
        case .Video:
            tempImageX = self.player.view.frame.origin.x - self.scrollOffset!.x
            tempImageY = self.player.view.frame.origin.y - self.scrollOffset!.y
        default:
            break
        }

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

    //MARK: 全景相关
    fileprivate var lastPoint_x:CGFloat = 0
    fileprivate var lastPoint_y:CGFloat = 0
    fileprivate var fingerRotationX:CGFloat = 0
    fileprivate var fingerRotationY:CGFloat = 0
    fileprivate var currentScale:CGFloat = 0.0
    fileprivate var prevScale:CGFloat = 0
    fileprivate var gestureDuring:Bool? = false
    fileprivate var cameraNode:SCNNode?
    fileprivate var sceneView:SCNView?
    var panoramaNode:SCNNode?
    fileprivate lazy var motionManager : CMMotionManager = {
        let view = CMMotionManager()
        view.deviceMotionUpdateInterval = 1/6
        return view
    }()

    //MARK: 图片相关
    fileprivate var scrollOffset:CGPoint? = CGPoint.zero
    public lazy var zoomImageSize:CGSize? = CGSize.init(width: frame.size.width, height: frame.size.height)
    var hasLoadedImage:Bool? = false
    fileprivate lazy var reloadButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.viewCorner(radius: 2,borderWidth:1,borderColor: .white)
        view.titleLabel?.font = UIFont.init(name: self.viewConfig.viewerFont.familyName, size: self.viewConfig.viewerFont.pointSize * 0.7)
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
    var playedVideo:Bool? = false
    fileprivate var playedFull:Bool? = false
    
    lazy var player:AVPlayerViewController = {
        let view = AVPlayerViewController()
        return view
    }()
    
    fileprivate lazy var videoSlider:UISlider = {
        let view = UISlider()
        view.addSliderAction { sender in
            self.player.player!.pause()
            self.playInSomeTime(someTime: sender.value)
        }
        let sliderTap = UITapGestureRecognizer.init { sender in
            self.player.player!.pause()
            let touchPoint = (sender as! UITapGestureRecognizer).location(in: self.videoSlider)
            let value = CGFloat(self.videoSlider.maximumValue - self.videoSlider.minimumValue) / (touchPoint.x / self.videoSlider.frame.size.width)
            self.videoSlider.setValue(Float(value), animated: true)
            self.playInSomeTime(someTime: Float(value))
        }
        view.addGestureRecognizer(sliderTap)
        return view
    }()
    
    fileprivate lazy var playBtn:UIButton = {
        
        let playImage = UIImage(systemName: "play.fill")

        let view = UIButton.init(type: .custom)
        view.setImage(playImage, for: .normal)
        view.addActionHandlers { sender in
            self.stopBtn.isHidden = false
            self.stopBtn.isSelected = false
            self.videoSlider.isHidden = false
            sender.isHidden = true
            if self.playedFull! {
                self.playInSomeTime(someTime: 0)
            } else {
                self.player.player!.play()
            }
        }
        return view
    }()
    
    lazy var stopBtn:UIButton = {
        let playImage = UIImage(systemName: "play.fill")
        let stopImage = UIImage(systemName: "pause.fill")

        let view = UIButton.init(type: .custom)
        view.setImage(playImage, for: .selected)
        view.setImage(stopImage, for: .normal)
        view.addActionHandlers { sender in
            sender.isSelected = !sender.isSelected
            if sender.isSelected {
                self.player.player!.pause()
            } else {
                self.stopBtn.isHidden = false
                self.videoSlider.isHidden = false
                if self.playedFull! {
                    self.playInSomeTime(someTime: 0)
                } else {
                    self.player.player!.play()
                }
            }
        }
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
                
        addSubview(contentScrolView)
        contentScrolView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adjustFrame() {
        switch dataModel.imageShowType {
        case .GIF,.Normal:
            if gifImage != nil {
                let imageSize = gifImage!.size
                var imageFrame = CGRect.init(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
                if isFullWidthForLandScape {
                    let ratio = contentView.frame.size.width / imageFrame.size.width
                    imageFrame.size.height = imageFrame.size.height * ratio
                    imageFrame.size.width = contentView.frame.size.width
                } else {
                    if frame.size.width <= frame.size.height {
                        let ratio = contentView.frame.size.width / imageFrame.size.width
                        imageFrame.size.height = imageFrame.size.height * ratio
                        imageFrame.size.width = contentView.frame.size.width
                    } else {
                        let ratio = frame.size.height / imageFrame.size.height
                        imageFrame.size.width = imageFrame.size.width * ratio
                        imageFrame.size.height = contentView.frame.size.height
                    }
                }
                imageView.frame = imageFrame
                contentScrolView.contentSize = imageView.frame.size
                imageView.center = PTMediaBrowserCell.centerOfScrollVIewContent(scrollView: contentScrolView)
                
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
        default:
            break
        }
    }
        
    func createThreeDView(image:UIImage) {
        let camera = SCNCamera()
        cameraNode = SCNNode()
        
        sceneView = SCNView()
        sceneView?.scene = SCNScene()
        contentScrolView.addSubview(sceneView!)
        sceneView?.snp.makeConstraints({ make in
            make.left.right.equalToSuperview()
            make.height.equalTo(self.frame.size.height - CGFloat.kNavBarHeight - 80)
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight)
        })
        sceneView?.allowsCameraControl = true
        
        cameraNode?.camera = camera
        cameraNode?.camera?.automaticallyAdjustsZRange = true
        cameraNode?.position = SCNVector3.init(x: 0, y: 0, z: 0)
        cameraNode?.camera?.fieldOfView = 60
        cameraNode?.camera?.focalLength = 60
        sceneView?.scene?.rootNode.addChildNode(cameraNode!)
        
        panoramaNode = SCNNode()
        panoramaNode?.geometry = SCNSphere.init(radius: 150)
        panoramaNode?.geometry?.firstMaterial?.cullMode = .front
        panoramaNode?.geometry?.firstMaterial?.isDoubleSided = true
        panoramaNode?.position = SCNVector3.init(x: 0, y: 0, z: 0)
        sceneView?.scene?.rootNode.addChildNode(panoramaNode!)
        
        panoramaNode?.geometry?.firstMaterial?.diffuse.contents = image
        
        let pan = UIPanGestureRecognizer.init { sender in
            let ges = sender as! UIPanGestureRecognizer
            if ges.delaysTouchesBegan {
                self.gestureDuring = true
                let currentPoint = ges.location(in: self.sceneView)
                self.lastPoint_x = currentPoint.x
                self.lastPoint_y = currentPoint.y
            } else if ges.delaysTouchesEnded {
                self.gestureDuring = false
            } else {
                let currentPoint = ges.location(in: self.sceneView)
                var distX = currentPoint.x - self.lastPoint_x
                var distY = currentPoint.y - self.lastPoint_y
                self.lastPoint_x = currentPoint.x
                self.lastPoint_y = currentPoint.y
                distX *= -0.003
                distY *= -0.003
                self.fingerRotationX += distX
                self.fingerRotationY += distY
                var modelMatrix = SCNMatrix4MakeRotation(0, 0, 0, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, Float(self.fingerRotationX), 0, 1, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, Float(self.fingerRotationY), 1, 0, 0)
                self.cameraNode?.pivot = modelMatrix
            }
        }
        sceneView?.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer.init { sender in
            //TODO: pinch
            let ges = sender as! UIPinchGestureRecognizer
            if ges.state != .ended && ges.state != .failed {
                if ges.scale != 0.0 {
                    var scale = ges.scale - 1
                    if scale < 0 {
                        scale *= (5 - 0.5)
                    }
                    self.currentScale = scale + self.prevScale
                    self.currentScale = self.validateScale(scale: self.currentScale)
                    
                    let valScale = self.validateScale(scale: self.currentScale)
                    let scaleRatio = 1 - (valScale - 1) * 0.15
                    let xFov = 60 * scaleRatio
                    let yFov = 60 * scaleRatio
                    
                    self.cameraNode?.camera?.fieldOfView = xFov
                    self.cameraNode?.camera?.focalLength = yFov
                }
            } else if ges.state == .ended {
                self.prevScale = self.currentScale
            }
        }
        sceneView?.addGestureRecognizer(pinch)
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates()
        } else {
            PTNSLogConsole("该设备的deviceMotion不可用")
        }
        
        motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue.current!) { motion, error in
            
            var orientation:UIInterfaceOrientation = .unknown
            orientation = PTUtils.getCurrentVC().view.window!.windowScene!.interfaceOrientation

            if orientation == .portrait && !self.gestureDuring! {
                var modelMatrix = SCNMatrix4MakeRotation(0, 0, 0, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, -Float(motion!.attitude.roll), 0, 1, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, -Float(motion!.attitude.pitch), 1, 0, 0)
                self.cameraNode?.pivot = modelMatrix
            }
        }
        
        hasLoadedImage = true
        contentScrolView.contentSize = CGSize.init(width: contentView.frame.size.width, height: contentView.frame.size.height)
    }
    
    func validateScale(scale:CGFloat)->CGFloat {
        var validateScale = scale
        if scale < 0.5 {
            validateScale = 0.5
        } else if scale > 5 {
            validateScale = 5
        }
        return validateScale
    }
    
    func createReloadButton() {
        hasLoadedImage = false
        addSubview(reloadButton)
        reloadButton.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.height.equalTo(40)
            make.centerY.centerX.equalToSuperview()
        }
        bringSubviewToFront(reloadButton)
    }
    
    func playInSomeTime(someTime:Float) {
        let fps = player.player!.currentItem!.asset.tracks(withMediaType: .video)[0].nominalFrameRate
        let time = CMTimeMakeWithSeconds(Float64(someTime), preferredTimescale: Int32(fps))
        self.player.player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { finish in
            self.player.player!.play()
        })
    }
    
    open class func centerOfScrollVIewContent(scrollView:UIScrollView) ->CGPoint {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? ((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5) : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? ((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5) : (0 + CGFloat.kNavBarHeight_Total + CGFloat.kTabbarHeight_Total)
        let actualCenter = CGPoint.init(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        return actualCenter
    }
    
    func cellLoadData() {
        
//        switch self.dataModel.imageShowType {
//        case .GIF,.Normal,.Video:
//            let pan = UIPanGestureRecognizer.init { sender in
//                let panGes = sender as! UIPanGestureRecognizer
//                self.contentScrolView.isUserInteractionEnabled = false
//                self.contentScrolView.isScrollEnabled = false
//                let orientation = UIDevice.current.orientation
//                if orientation.isLandscape {
//                    return
//                }
//                
//                let transPoint = panGes.translation(in: self)
//                let veloctiy = panGes.velocity(in: self)
//                
//                
//                switch panGes.state {
//                case .began:
//                    self.prepareForHide()
//                case .changed:
//                    PTNSLogConsole("changed")
//                    var delt = 1 - abs(transPoint.y) / self.contentView.frame.size.height
//                    delt = max(delt, 0)
//                    let s = max(delt, 0.5)
//                    let translation = CGAffineTransform(translationX: transPoint.x / s, y: transPoint.y / s)
//                    let scale = CGAffineTransform(scaleX: s, y: s)
//                    self.tempView.transform = translation.concatenating(scale)
////                    self.coverView.alpha = delt
//                case .ended:
//                    if abs(transPoint.y) > 220 || abs(veloctiy.y) > 500 {
//                        self.hideAnimation()
//                    } else {
//                        self.bounceToOriginal()
//                    }
//                    self.contentScrolView.isScrollEnabled = true
//                default:break
//                }
//            }
//            pan.minimumNumberOfTouches = 3
//            self.contentView.addGestureRecognizer(pan)
//
//        default:
//            break
//        }
//
        let loading = PTLoadingView(type: .LoopDiagram)
        addSubview(loading)
        loading.snp.makeConstraints { make in
            make.width.height.equalTo(50)
            make.centerX.centerY.equalToSuperview()
        }
        
        PTGCDManager.gcdAfter(time: 0.1) {
            switch self.dataModel.imageShowType {
            case .ThreeD,.FullView:
                if self.dataModel.imageURL is String {
                    let urlString = self.dataModel.imageURL as! String
                    if urlString.isValidUrl {
                        ImageDownloader.default.downloadImage(with: URL(string: urlString)!,options: PTAppBaseConfig.share.gobalWebImageLoadOption(), progressBlock: { receivedSize, totalSize in
                            PTGCDManager.gcdMain {
                                loading.progress = CGFloat(receivedSize / totalSize)
                            }
                        }) { result in
                            switch result {
                            case .success(let value):
                                loading.removeFromSuperview()
                                self.createThreeDView(image: value.image)
                            case .failure(let error):
                                loading.removeFromSuperview()
                                PTNSLogConsole(error)
                                self.createReloadButton()
                            }
                        }
                    }
                } else if self.dataModel.imageURL is UIImage {
                    loading.removeFromSuperview()
                    self.createThreeDView(image: self.dataModel.imageURL as! UIImage)
                }
            case .Video:
                self.imageView.removeFromSuperview()
                loading.removeFromSuperview()
                self.contentScrolView.delaysContentTouches = false
                if self.dataModel.imageURL is String {
                    self.playedVideo = false

                    var videoUrl:NSURL?
                    let urlString = self.dataModel.imageURL as! String
                    if FileManager.pt.judgeFileOrFolderExists(filePath: urlString) {
                        videoUrl = NSURL.init(fileURLWithPath: urlString)
                    } else {
                        videoUrl = NSURL.init(string: urlString.nsString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
                    }
                    
                    UIImage.pt.getVideoFirstImage(videoUrl: videoUrl!.description, closure: { image in
                        self.gifImage = image
                    })
                    
                    let opts = NSDictionary.init(object: NSNumber.init(booleanLiteral: false), forKey: AVURLAssetPreferPreciseDurationAndTimingKey as NSCopying)
                    let urlAsset = AVURLAsset.init(url: videoUrl! as URL,options: (opts as! [String : Any]))
                    let playerItem = AVPlayerItem.init(asset: urlAsset)
                    self.player.player = AVPlayer.init(playerItem: playerItem)
                    self.player.showsPlaybackControls = false
                    self.contentScrolView.addSubview(self.player.view)
                    PTGCDManager.gcdAfter(time: 0.1) {
                        self.player.view.snp.makeConstraints { make in
                            make.width.equalTo(self.frame.size.width)
                            make.top.equalTo(CGFloat.kNavBarHeight_Total)
                            make.left.equalTo(0)
                            make.height.equalTo(self.contentView.frame.size.height - CGFloat.kNavBarHeight_Total)
                        }
                    }
                    
                    self.player.player!.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: nil, using: { time in
                        
                        let duration = Float(CMTimeGetSeconds(self.player.player?.currentItem?.duration ?? .zero))
                        
                        self.videoSlider.maximumValue = duration
                        self.videoSlider.minimumValue = 0
                        
                        let progress = Float(CMTimeGetSeconds(self.player.player!.currentItem!.currentTime())) / duration
                        
                        let sliderCurrentValue = Float(CMTimeGetSeconds(self.player.player!.currentItem!.currentTime()))
                        
                        self.videoSlider.setValue(sliderCurrentValue, animated: true)
                        
                        if progress >= 1 {
                            self.playedFull = true
                            if !self.playedVideo! {
                                self.playBtn.isHidden = false
                            }
                            self.videoSlider.isHidden = true
                            self.videoSlider.setValue(0, animated: true)
                            self.stopBtn.isHidden = true
                        }
                    })
                    
                    self.contentScrolView.addSubviews([self.playBtn,self.stopBtn,self.videoSlider])
                    self.contentScrolView.bringSubviewToFront(self.playBtn)
                    self.playBtn.snp.makeConstraints { make in
                        make.width.height.equalTo(44)
                        make.centerX.centerY.equalToSuperview()
                    }
                    
                    self.stopBtn.snp.makeConstraints { make in
                        make.width.height.equalTo(44)
                        make.left.equalTo(self.player.view).offset(10)
                        make.bottom.equalTo(self.player.view).offset(-10)
                    }
                    self.stopBtn.isHidden = true
                    
                    self.videoSlider.snp.makeConstraints { make in
                        make.left.equalTo(self.stopBtn.snp.right).offset(10)
                        make.right.equalTo(self.player.view).offset(-10)
                        make.height.equalTo(20)
                        make.centerY.equalTo(self.stopBtn)
                    }
                    self.videoSlider.isHidden = true
                    self.hasLoadedImage = true
                }
            case .GIF,.Normal:
                self.gifImage = nil
                self.videoSlider.removeFromSuperview()
                self.playBtn.removeFromSuperview()
                self.stopBtn.removeFromSuperview()
                self.player.view.removeFromSuperview()
                self.imageView.contentMode = .scaleAspectFit
                self.contentScrolView.addSubview(self.imageView)
                
                let doubleTap = UITapGestureRecognizer.init { sender in
                    let touchPoint = (sender as! UITapGestureRecognizer).location(in: self)
                    if self.contentScrolView.zoomScale <= 1 {
                        let scaleX = touchPoint.x + self.contentScrolView.contentOffset.x
                        let scaleY = touchPoint.y + self.contentScrolView.contentOffset.y
                        self.contentScrolView.zoom(to: CGRect.init(x: scaleX, y: scaleY, width: 10, height: 10), animated: true)
                    } else {
                        self.contentScrolView.setZoomScale(1, animated: true)
                    }
                }
                doubleTap.numberOfTapsRequired = 2
                self.imageView.addGestureRecognizer(doubleTap)
                
                PTLoadImageFunction.loadImage(contentData: self.dataModel.imageURL as Any,iCloudDocumentName: self.viewConfig.iCloudDocumentName) { receivedSize, totalSize in
                    loading.progress = CGFloat(receivedSize / totalSize)
                } taskHandle: { images,image in
                    if (images?.count ?? 0) > 1 {
                        self.gifImage = image
                        self.imageView.animationImages = images
                        self.imageView.animationDuration = 2
                        self.imageView.startAnimating()
                        self.adjustFrame()
                        self.hasLoadedImage = true
                        loading.removeFromSuperview()
                    } else if images?.count == 1 {
                        self.gifImage = image
                        self.imageView.image = images!.first
                        self.adjustFrame()
                        self.hasLoadedImage = true
                        loading.removeFromSuperview()
                    } else {
                        loading.removeFromSuperview()
                        self.createReloadButton()
                        self.adjustFrame()
                        self.hasLoadedImage = false
                    }
                }
            default:
                break
            }
        }
    }
    
    func prepareForHide() {
        self.contentView.addSubview(tempView)
        self.contentView.backgroundColor = .clear
        switch self.dataModel.imageShowType {
        case .GIF,.Normal:
            self.imageView.alpha = 0
        case .Video:
            self.player.view.alpha = 0
        default:
            break
        }
    }
    
    func hideAnimation() {
        self.contentView.isUserInteractionEnabled = false
        let window = AppWindows!
        var targetTemp:CGRect? = CGRect.init(x: window.center.x, y: window.center.y, width: 0, height: 0)
        switch self.dataModel.imageShowType {
        case .Normal,.GIF:
            targetTemp = self.contentView.convert(self.contentView.frame, to: self.contentView)
        case .Video:
            targetTemp = CGRect.init(x: AppWindows!.center.x, y: AppWindows!.center.y, width: 0, height: 0)
        default:
            break
        }
        
        window.windowLevel = .normal
        UIView.animate(withDuration: 0.35) {
            switch self.dataModel.imageShowType {
            case .Normal,.GIF,.Video:
                self.tempView.transform = self.contentView.transform.inverted()
            default:break
            }
            self.tempView.frame = targetTemp!
        } completion: { finish in
            self.tempView.removeFromSuperview()
            self.contentView.alpha = 0
            
            switch self.dataModel.imageShowType {
            case .GIF:
                self.imageView.stopAnimating()
            case .Video:
                self.player.player?.pause()
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
            self.isUserInteractionEnabled = true
            self.tempView.removeFromSuperview()
            switch self.dataModel.imageShowType {
            case .GIF,.Normal:
                self.imageView.alpha = 1
            case .Video:
                self.player.view.alpha = 1
            default:
                break
            }
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
        imageView.center = PTMediaMediaView.centerOfScrollVIewContent(scrollView: scrollView)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollOffset = scrollView.contentOffset
    }
}

