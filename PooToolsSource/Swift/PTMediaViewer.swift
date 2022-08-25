//
//  PTMediaViewer.swift
//  PooTools_Example
//
//  Created by jax on 2022/8/25.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SceneKit
import CoreMotion
import AVFoundation
import AVKit
import PooTools

public let PTViewerBaseTag = 9999
public typealias PTViewerActionFinishBlock = () -> Void

@objc public enum PTViewerDataType:Int
{
    case Normal
    case GIF
    case Video
    case FullView
    case ThreeD
}

@objc public enum PTViewerActionType:Int
{
    case All
    case Save
    case Delete
    case DIY
    case Empty
}

@objcMembers
public class PTViewerModel: NSObject {
    var imageInfo:String = ""
    var imageType:PTViewerDataType = .Normal
    var imageURL:Any!
}

@objc public enum PTLoadingViewMode:Int
{
    case LoopDiagram
    case PieDiagram
}

public let PTLoadingBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
public let PTLoadingItemSpace :CGFloat = 10
@objcMembers
public class PTLoadingView: UIView {
    
    public var progress:CGFloat?
    {
        didSet{
            self.setNeedsDisplay()
            if self.progress! >= 1
            {
                self.removeFromSuperview()
            }
        }
    }
    
    fileprivate var progressMode:PTLoadingViewMode = .LoopDiagram
    
    public init(type:PTLoadingViewMode) {
        super.init(frame: .zero)
        self.progressMode = type
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = PTLoadingBackgroundColor
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        let xCenter = rect.size.width * 0.5
        let yCenter = rect.size.height * 0.5
        UIColor.white.set()
        
        switch self.progressMode {
        case .PieDiagram:
            let radius = min(xCenter, yCenter) - PTLoadingItemSpace
            let w = radius * 2 - PTLoadingItemSpace
            let h = w
            let x = (rect.size.width - 2) * 0.5
            let y = (rect.size.height - 2) * 0.5
            ctx!.addEllipse(in: CGRect.init(x: x, y: y, width: w, height: h))
            ctx!.fillPath()
            
            PTLoadingBackgroundColor.set()
            ctx!.move(to: CGPoint.init(x: xCenter, y: yCenter))
            ctx?.addLine(to: CGPoint.init(x: xCenter, y: 0))
            let piFloat :CGFloat = -.pi
            let to = (piFloat * 0.5 + self.progress! * .pi * 2 + 0.01)
            ctx!.addArc(center: CGPoint.init(x: xCenter, y: yCenter), radius: yCenter / 2, startAngle: (piFloat * 0.5), endAngle: to, clockwise: true)
            ctx!.closePath()
            ctx!.fillPath()
        case .LoopDiagram:
            ctx!.setLineWidth(4)
            ctx!.setLineCap(.round)
            let piFloat :CGFloat = -.pi
            let to = (piFloat * 0.5 + self.progress! * .pi * 2 + 0.05)
            let radius = min(rect.size.width, rect.self.size.height) * 0.5 - PTLoadingItemSpace
            ctx!.addArc(center: CGPoint.init(x: xCenter, y: yCenter), radius: radius, startAngle: (piFloat * 0.5), endAngle: to, clockwise: false)
            ctx!.strokePath()
        }
    }
}

@objcMembers
public class PTViewerConfig: NSObject {
    ///默认到哪一页,默认0
    var defultIndex:Int = PTViewerBaseTag
    ///数据源
    var mediaData:[PTViewerModel]!
    ///内容的文字颜色
    var titleColor:UIColor = UIColor.white
    ///内容字体
    var viewerFont:UIFont = UIFont.systemFont(ofSize: 18)
    ///内容的容器背景颜色
    var viewerContentBackgroundColor:UIColor = UIColor.black
    ///操作方式
    var actionType:PTViewerActionType = .All
    ///关闭页面按钮图片连接/名字
    var closeViewerImageName:String = ""
    ///更多操作按钮图片连接/名字
    var moreActionImageName:String = ""
    ///更多功能扩展,如果选择全部,则默认保存0删除1........
    var moreActionEX:[String] = []
}

fileprivate class PTMediaMediaView:UIView
{
    let maxZoomSale:CGFloat = 2
    let minZoomSale:CGFloat = 0.6

    var isFullWidthForLandScape:Bool = false
    
    fileprivate lazy var contentScrolView:UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.clipsToBounds = true
        return view
    }()
    
    fileprivate var viewConfig:PTViewerConfig!
    fileprivate var dataModel:PTViewerModel!

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
    fileprivate var panoramaNode:SCNNode?
    fileprivate lazy var motionManager : CMMotionManager = {
        let view = CMMotionManager()
        view.deviceMotionUpdateInterval = 1/6
        return view
    }()

    //MARK: 图片相关
    fileprivate var scrollOffset:CGPoint?
    fileprivate var zoomImageSize:CGSize?
    var hasLoadedImage:Bool? = false
    fileprivate lazy var reloadButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.viewCorner(radius: 2,borderWidth:1,borderColor: .white)
        view.titleLabel?.font = UIFont.init(name: self.viewConfig.viewerFont.familyName, size: self.viewConfig.viewerFont.pointSize * 0.7)
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        view.setTitle("图片加载失败,点击重试", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.addActionHandlers { sender in
            self.setMediaData(dataModel: self.dataModel)
        }
        return view
    }()
    
    fileprivate lazy var imageView:UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    fileprivate var gifImage:UIImage? = nil

    //MARK: 视频相关
    var playedVideo:Bool? = false
    fileprivate var playedFull:Bool? = false
    fileprivate var player:AVPlayerViewController?
    fileprivate lazy var videoSlider:UISlider = {
        let view = UISlider()
        view.addBlock(for: .valueChanged) { sender in
            self.player!.player!.pause()
            self.playInSomeTime(someTime: (sender as! UISlider).value)
        }
        let sliderTap = UITapGestureRecognizer.init { sender in
            self.player!.player!.pause()
            let touchPoint = (sender as! UITapGestureRecognizer).location(in: self.videoSlider)
            let value = CGFloat(self.videoSlider.maximumValue - self.videoSlider.minimumValue) / (touchPoint.x / self.videoSlider.frame.size.width)
            self.videoSlider.setValue(Float(value), animated: true)
            self.playInSomeTime(someTime: Float(value))
        }
        view.addGestureRecognizer(sliderTap)
        return view
    }()
    
    let bundlePath = Bundle.init(path: PTUtils.cgBaseBundle().path(forResource: "PooTools", ofType: "bundle")!)

    fileprivate lazy var playBtn:UIButton = {
        
        let playImage = UIImage.init(contentsOfFile: bundlePath!.path(forResource: "p_play", ofType: "png")!)

        let view = UIButton.init(type: .custom)
        view.setImage(playImage, for: .normal)
        view.addActionHandlers { sender in
            self.stopBtn.isHidden = false
            self.videoSlider.isHidden = false
            sender.isHidden = true
            if self.playedFull!
            {
                self.playInSomeTime(someTime: 0)
            }
            else
            {
                self.player!.player!.play()
            }
            self.playBtn.isHidden = true
        }
        return view
    }()
    
    fileprivate lazy var stopBtn:UIButton = {
        let playImage = UIImage.init(contentsOfFile: bundlePath!.path(forResource: "p_play", ofType: "png")!)
        let stopImage = UIImage.init(contentsOfFile: bundlePath!.path(forResource: "p_pause", ofType: "png")!)

        let view = UIButton.init(type: .custom)
        view.setImage(playImage, for: .selected)
        view.setImage(stopImage, for: .normal)
        view.addActionHandlers { sender in
            sender.isSelected = !sender.isSelected
            if sender.isSelected
            {
                self.player!.player!.pause()
            }
            else
            {
                self.stopBtn.isHidden = false
                self.videoSlider.isHidden = false
                if self.playedFull!
                {
                    self.playInSomeTime(someTime: 0)
                }
                else
                {
                    self.player!.player!.play()
                }
            }
        }
        return view
    }()
    
    init(viewConfig:PTViewerConfig) {
        super.init(frame: .zero)
        
        self.viewConfig = viewConfig
        
        self.addSubview(self.contentScrolView)
        self.contentScrolView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.adjustFrame()
    }
    
    func adjustFrame()
    {
        switch self.dataModel.imageType {
        case .GIF,.Normal:
            if self.gifImage != nil
            {
                let imageSize = self.gifImage!.size
                var imageFrame = CGRect.init(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
                if self.isFullWidthForLandScape
                {
                    let ratio = frame.size.width / imageFrame.size.width
                    imageFrame.size.height = imageFrame.size.height * ratio
                    imageFrame.size.width = frame.size.width
                }
                else
                {
                    if self.frame.size.width <= self.frame.size.height
                    {
                        let ratio = frame.size.width / imageFrame.size.width
                        imageFrame.size.height = imageFrame.size.height * ratio
                        imageFrame.size.width = frame.size.width
                    }
                    else
                    {
                        let ratio = frame.size.height / imageFrame.size.height
                        imageFrame.size.width = imageFrame.size.width * ratio
                        imageFrame.size.height = frame.size.height
                    }
                }
                self.imageView.frame = imageFrame
                self.contentScrolView.contentSize = self.imageView.frame.size
                self.imageView.center = self.centerOfScrollVIewContent(scrollView: self.contentScrolView)
                
                var maxScale = frame.size.height / imageFrame.size.height
                maxScale = frame.size.width / imageFrame.self.width > maxScale ? frame.self.width / imageFrame.self.width : maxScale
                maxScale = maxScale > maxZoomSale ? maxScale : maxZoomSale
                self.contentScrolView.minimumZoomScale = minZoomSale
                self.contentScrolView.maximumZoomScale = maxScale
                self.contentScrolView.zoomScale = 1
            }
            else
            {
                frame.origin = .zero
                self.imageView.frame = frame
                self.contentScrolView.contentSize = self.imageView.frame.size
            }
            self.contentScrolView.contentOffset = .zero
            self.zoomImageSize = self.imageView.frame.size
        default:
            break
        }
    }
    
    func centerOfScrollVIewContent(scrollView:UIScrollView) ->CGPoint
    {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? ((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5) : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? ((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5) : 0
        let actualCenter = CGPoint.init(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        return actualCenter
    }
    
    func setMediaData(dataModel:PTViewerModel)
    {
        self.dataModel = dataModel
        
        let loading = PTLoadingView.init(type: .LoopDiagram)
        self.addSubview(loading)
        loading.snp.makeConstraints { make in
            make.width.height.equalTo(50)
            make.centerX.centerY.equalToSuperview()
        }
        
        switch dataModel.imageType {
        case .ThreeD,.FullView:
            if dataModel.imageURL is String
            {
                let urlString = dataModel.imageURL as! String
                if urlString.isValidUrl
                {
                    SDWebImageManager.shared.loadImage(with: URL(string: urlString)) { receivedSize, expectedSendSize, targetURL in
                        loading.progress = CGFloat(receivedSize / expectedSendSize)
                    } completed: { image, data, error, type, finish, url in
                        loading.removeFromSuperview()
                        if error != nil
                        {
                            self.createReloadButton()
                            return
                        }
                        
                        self.createThreeDView(image: image!)
                    }
                }
            }
            else if dataModel.imageURL is UIImage
            {
                loading.removeFromSuperview()
                self.createThreeDView(image: dataModel.imageURL as! UIImage)
            }
        case .Video:
            loading.removeFromSuperview()
            self.contentScrolView.delaysContentTouches = false
            if dataModel.imageURL is String
            {
                self.playedVideo = false

                var videoUrl:NSURL?
                let urlString = dataModel.imageURL as! String
                if urlString.nsString.range(of: "/var").length > 0
                {
                    videoUrl = NSURL.init(fileURLWithPath: urlString)
                }
                else
                {
                    videoUrl = NSURL.init(string: urlString.nsString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
                }
                
                let opts = NSDictionary.init(object: NSNumber.init(booleanLiteral: false), forKey: AVURLAssetPreferPreciseDurationAndTimingKey as NSCopying)
                let urlAsset = AVURLAsset.init(url: videoUrl! as URL,options: (opts as! [String : Any]))
                let playerItem = AVPlayerItem.init(asset: urlAsset)
                self.player? = AVPlayerViewController()
                self.player?.player = AVPlayer.init(playerItem: playerItem)
                self.player?.showsPlaybackControls = false
                self.contentScrolView.addSubview(self.player!.view)
                self.player!.view.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalToSuperview().inset(kNavBarHeight)
                    make.height.equalTo(self.frame.size.height - kNavBarHeight - 80)
                }
                
                self.player?.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: nil, using: { time in
                    
                    let duration = Float(CMTimeGetSeconds(self.player!.player!.currentItem!.duration))
                    
                    self.videoSlider.maximumValue = duration
                    self.videoSlider.minimumValue = 0
                    
                    let progress = Float(CMTimeGetSeconds(self.player!.player!.currentItem!.currentTime())) / duration
                    
                    let sliderCurrentValue = Float(CMTimeGetSeconds(self.player!.player!.currentItem!.currentTime()))
                    
                    self.videoSlider.setValue(sliderCurrentValue, animated: true)
                    
                    if progress >= 1
                    {
                        self.playedFull = true
                        if !self.playedVideo!
                        {
                            self.playBtn.isHidden = false
                        }
                        self.videoSlider.isHidden = true
                        self.videoSlider.setValue(0, animated: true)
                        self.stopBtn.isHidden = true
                    }
                })
                
                self.contentScrolView.addSubviews([self.playBtn,self.stopBtn,self.videoSlider])
                self.playBtn.snp.makeConstraints { make in
                    make.width.height.equalTo(44)
                    make.centerX.centerY.equalToSuperview()
                }
                
                self.stopBtn.snp.makeConstraints { make in
                    make.width.height.equalTo(44)
                    make.left.equalTo(self.player!.view).offset(10)
                    make.bottom.equalTo(self.player!.view).offset(-10)
                }
                self.stopBtn.isHidden = true
                
                self.videoSlider.snp.makeConstraints { make in
                    make.left.equalTo(self.stopBtn.snp.right).offset(10)
                    make.right.equalTo(self.player!.view).offset(-10)
                    make.height.equalTo(20)
                    make.centerY.equalTo(self.stopBtn)
                }
                self.videoSlider.isHidden = true
                self.hasLoadedImage = true
            }
        case .GIF,.Normal:
            self.imageView.contentMode = .scaleAspectFit
            self.contentScrolView.addSubview(self.imageView)
            
            if dataModel.imageURL is UIImage
            {
                self.imageView.image = dataModel.imageURL as? UIImage
                self.setNeedsLayout()
                self.hasLoadedImage = true
            }
            else if dataModel.imageURL is String
            {
                SDWebImageManager.shared.loadImage(with: URL.init(string: dataModel.imageURL as! String)) { receivedSize, expectedSendSize, targetURL in
                    loading.progress = CGFloat(receivedSize / expectedSendSize)
                    self.imageView.image = nil
                } completed: { image, data, error, type, finish, url in
                    loading.removeFromSuperview()
                    if error != nil
                    {
                        self.createReloadButton()
                        return
                    }
                    
                    self.gifImage = image

                    switch Utils.contentType(forImageData: data!) {
                    case .GIF:
                        let source = CGImageSourceCreateWithData(data! as CFData, nil)
                        let frameCount = CGImageSourceGetCount(source!)
                        var frames = [UIImage]()
                        for i in 0...frameCount
                        {
                            let imageref = CGImageSourceCreateImageAtIndex(source!,i,nil)
                            let imageName = UIImage.init(cgImage: imageref!)
                            frames.append(imageName)
                        }
                        self.imageView.animationImages = frames
                        self.imageView.animationDuration = 2
                        self.imageView.startAnimating()
                    default:
                        self.imageView.image = image
                    }
                    self.setNeedsLayout()
                    self.hasLoadedImage = true
                }
            }
        default:
            break
        }
    }
    
    func createThreeDView(image:UIImage)
    {
        let camera = SCNCamera()
        self.cameraNode = SCNNode()
        
        self.sceneView = SCNView()
        self.sceneView?.scene = SCNScene()
        self.contentScrolView.addSubview(self.sceneView!)
        self.sceneView?.snp.makeConstraints({ make in
            make.left.right.equalToSuperview()
            make.height.equalTo(self.frame.size.height - kNavBarHeight - 80)
            make.top.equalToSuperview().inset(kNavBarHeight)
        })
        self.sceneView?.allowsCameraControl = true
        
        self.cameraNode?.camera = camera
        self.cameraNode?.camera?.automaticallyAdjustsZRange = true
        self.cameraNode?.position = SCNVector3.init(x: 0, y: 0, z: 0)
        if #available(iOS 11.0, *) {
            self.cameraNode?.camera?.fieldOfView = 60
            self.cameraNode?.camera?.focalLength = 60
        } else {
            self.cameraNode?.camera?.xFov = 60
            self.cameraNode?.camera?.yFov = 60
        }
        self.sceneView?.scene?.rootNode.addChildNode(self.cameraNode!)
        
        self.panoramaNode = SCNNode()
        self.panoramaNode?.geometry = SCNSphere.init(radius: 150)
        self.panoramaNode?.geometry?.firstMaterial?.cullMode = .front
        self.panoramaNode?.geometry?.firstMaterial?.isDoubleSided = true
        self.panoramaNode?.position = SCNVector3.init(x: 0, y: 0, z: 0)
        self.sceneView?.scene?.rootNode.addChildNode(self.panoramaNode!)
        
        self.panoramaNode?.geometry?.firstMaterial?.diffuse.contents = image
        
        let pan = UIPanGestureRecognizer.init { sender in
            let ges = sender as! UIPanGestureRecognizer
            if ges.delaysTouchesBegan
            {
                self.gestureDuring = true
                let currentPoint = ges.location(in: self.sceneView)
                self.lastPoint_x = currentPoint.x
                self.lastPoint_y = currentPoint.y
            }
            else if ges.delaysTouchesEnded
            {
                self.gestureDuring = false
            }
            else
            {
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
        self.sceneView?.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer.init { sender in
            //TODO: pinch
            let ges = sender as! UIPinchGestureRecognizer
            if ges.state != .ended && ges.state != .failed
            {
                if ges.scale != 0.0
                {
                    var scale = ges.scale - 1
                    if scale < 0
                    {
                        scale *= (5 - 0.5)
                    }
                    self.currentScale = scale + self.prevScale
                    self.currentScale = self.validateScale(scale: self.currentScale)
                    
                    let valScale = self.validateScale(scale: self.currentScale)
                    let scaleRatio = 1 - (valScale - 1) * 0.15
                    let xFov = 60 * scaleRatio
                    let yFov = 60 * scaleRatio
                    
                    if #available(iOS 11.0, *) {
                        self.cameraNode?.camera?.fieldOfView = xFov
                        self.cameraNode?.camera?.focalLength = yFov
                    } else {
                        self.cameraNode?.camera?.xFov = xFov
                        self.cameraNode?.camera?.yFov = yFov
                    }
                }
            }
            else if ges.state == .ended
            {
                self.prevScale = self.currentScale
            }
        }
        self.sceneView?.addGestureRecognizer(pinch)
        
        if self.motionManager.isDeviceMotionAvailable
        {
            self.motionManager.startDeviceMotionUpdates()
        }
        else
        {
            print("该设备的deviceMotion不可用")
        }
        
        self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue.current!) { motion, error in
            let orientation = UIApplication.shared.statusBarOrientation
            if orientation == .portrait && !self.gestureDuring!
            {
                var modelMatrix = SCNMatrix4MakeRotation(0, 0, 0, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, -Float(motion!.attitude.roll), 0, 1, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, -Float(motion!.attitude.pitch), 1, 0, 0)
                self.cameraNode?.pivot = modelMatrix
            }
        }
        
        self.hasLoadedImage = true
        self.contentScrolView.contentSize = CGSize.init(width: self.frame.size.width, height: self.frame.size.height)
    }
    
    func validateScale(scale:CGFloat)->CGFloat
    {
        var validateScale = scale
        if scale < 0.5
        {
            validateScale = 0.5
        }
        else if scale > 5
        {
            validateScale = 5
        }
        return validateScale
    }
    
    func createReloadButton()
    {
        self.hasLoadedImage = false
        self.addSubview(self.reloadButton)
        self.reloadButton.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.height.equalTo(40)
            make.centerY.centerX.equalToSuperview()
        }
    }
    
    func playInSomeTime(someTime:Float)
    {
        let fps = self.player!.player!.currentItem!.asset.tracks(withMediaType: .video)[0].nominalFrameRate
        let time = CMTimeMakeWithSeconds(Float64(someTime), preferredTimescale: Int32(fps))
        self.player!.player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { finish in
            self.player!.player!.play()
        })
    }
}

extension PTMediaMediaView:UIScrollViewDelegate
{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.zoomImageSize = view?.frame.size
        self.scrollOffset = scrollView.contentOffset
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.imageView.center = self.centerOfScrollVIewContent(scrollView: scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollOffset = scrollView.contentOffset
    }
}


@objcMembers
public class PTMediaViewer: UIView {

    fileprivate var actionSheetTitle:[String] = []
    fileprivate var viewConfig:PTViewerConfig!

    fileprivate lazy var backgroundView:UIView = {
        let view = UIView()
        view.backgroundColor = self.viewConfig.viewerContentBackgroundColor
        return view
    }()
    
    fileprivate lazy var contentScrolView:UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    init(viewConfig:PTViewerConfig!) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
        switch self.viewConfig.actionType {
        case .All:
            self.actionSheetTitle = ["保存图片","删除图片"]
            self.viewConfig.moreActionEX.enumerated().forEach { index,value in
                self.actionSheetTitle.append(value)
            }
        case .Save:
            self.actionSheetTitle = ["保存图片"]
        case .Delete:
            self.actionSheetTitle = ["删除图片"]
        case .DIY:
            self.viewConfig.moreActionEX.enumerated().forEach { index,value in
                self.actionSheetTitle.append(value)
            }
        default:
            break
        }
        
        
        self.addSubview(self.contentScrolView)
        self.contentScrolView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showImageViewer()
    {
        let windows = UIApplication.shared.keyWindow
        windows?.addSubview(self.backgroundView)
        self.backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func show(content:UIView,loadFinishBlock:PTViewerActionFinishBlock)
    {
        content.addSubview(self)
        PTUtils.gcdAfter(time: 0.1) {
            self.contentScrolView.contentSize = CGSize.init(width: self.frame.size.width * CGFloat(self.viewConfig.mediaData.count), height: self.frame.size.height)
        }
    }
}

extension PTMediaViewer:UIScrollViewDelegate
{
    
}
