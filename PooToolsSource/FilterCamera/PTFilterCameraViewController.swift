//
//  PTFilterCameraViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Harbeth
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import AVFoundation
import SnapKit
import SwifterSwift

public class PTFilterCameraViewController: PTBaseViewController {

    private lazy var cameraConfig = PTCameraFilterConfig.share
    /// 是否正在调整焦距
    private var isAdjustingFocusPoint = false
    private var dragStart = false

    static let largeCircleRadius: CGFloat = 80
    static let borderLayerWidth: CGFloat = 1.8
    static let smallCircleRadius: CGFloat = 65
    static let largeCircleRecordScale: CGFloat = 1.2
    static let smallCircleRecordScale: CGFloat = 0.5
    static let cameraBtnRecodingBorderColor: UIColor = .white.withAlphaComponent(0.8)
    static let cameraBtnNormalColor: UIColor = .white
    static let toolBarHeight: CGFloat = 120
    static let animateLayerWidth: CGFloat = 5
    static let filterCollectionHeight: CGFloat = 108
    private var currentFilter: PTHarBethFilter = PTHarBethFilter.none

    ///是否打開手電筒
    private var torchOn:Bool = false

    lazy var originImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()
    
    lazy var camera: C7CollectorCamera = {
        let camera = C7CollectorCamera.init(delegate: self)
//        camera.largeCircleView = self.largeCircleView
//        camera.smallCircleView = self.smallCircleView
//        camera.borderLayer = self.borderLayer
//        camera.animateLayer = self.animateLayer
//        camera.recordLongGes = self.recordLongGes
//        camera.focusCursorView = self.focusCursorView
//        camera.isAdjustingFocusPoint = self.isAdjustingFocusPoint
//        camera.captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
//        camera.filters = [PTCameraFilterConfig.share.filters.first!.type.getFilterResult(texture: PTHarBethFilter.overTexture()).filter]
        return camera
    }()
    
    lazy var toolBar:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var flashButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(cameraConfig.flashImage, for: .normal)
        view.setImage(cameraConfig.flashImageSelected, for: .selected)
        view.addActionHandlers { sender in
            self.torchOn = !self.torchOn
            if self.camera.deviceInput!.device.hasTorch {
                do {
                    try self.camera.deviceInput!.device.lockForConfiguration()
                    
                    if self.torchOn {
                        self.camera.deviceInput!.device.torchMode = .on
                        sender.isSelected = true
                    } else {
                        self.camera.deviceInput!.device.torchMode = .off
                        sender.isSelected = false
                    }
                    self.camera.deviceInput!.device.unlockForConfiguration()
                } catch {
                    PTNSLogConsole(error.localizedDescription)
                }
            }
        }
        return view
    }()
    
    lazy var switchCameraButton:UIButton = {
        let cameraCount = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices.count

        let view = UIButton(type: .custom)
        view.setImage(cameraConfig.switchCameraImage, for: .normal)
        view.isHidden = cameraCount <= 1
        view.addActionHandlers { sender in
            self.camera.changeCamera {
                PTGCDManager.gcdBackground {
//                    self.originImageView.image = self.originImageView.image?.imageRotated(byDegrees: 90)
                }
            }
        }
        return view
    }()
    
    lazy var backBtn : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(cameraConfig.backImage, for: .normal)
        view.addActionHandlers { sender in
            self.camera.stopRunning()
            self.returnFrontVC()
        }
        return view
    }()
    
    private var thumbnailFilterImages: [UIImage] = []
    private lazy var filterCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom

        let view = PTCollectionView(viewConfig: config)
        view.isUserInteractionEnabled = true
        view.customerLayout = { sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            var groupW:CGFloat = PTAppBaseConfig.share.defaultViewSpace
            let screenW:CGFloat = 88
            let cellHeight:CGFloat = PTFilterCameraViewController.filterCollectionHeight
            sectionModel.rows.enumerated().forEach { (index,model) in
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: PTAppBaseConfig.share.defaultViewSpace + 10 * CGFloat(index) + screenW * CGFloat(index), y: 5, width: screenW, height: cellHeight-10), zIndex: 1000+index)
                customers.append(customItem)
                groupW += (cellHeight + 10)
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupW), heightDimension: NSCollectionLayoutDimension.absolute(cellHeight))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTMediaLibConfig.share
            let itemRow = sectionModel.rows[indexPath.row]
            let cellTools = itemRow.dataModel as! UIImage
            let cellFilter = PTCameraFilterConfig.share.filters[indexPath.row]
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFilterImageCell
            cell.imageView.image = cellTools
            cell.nameLabel.text = cellFilter.name
            
            if self.currentFilter == cellFilter {
                cell.nameLabel.textColor = .purple
            } else {
                cell.nameLabel.textColor = .lightGray
            }
            return cell
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            
            let filters = PTCameraFilterConfig.share.filters[indexPath.row]
            if filters.type == .none {
                self.camera.filters = []
                self.currentFilter = PTHarBethFilter.none
            } else {
                PTHarBethFilter.share.texureSize = self.originImageView.image!.size
                let filter = PTCameraFilterConfig.share.filters[indexPath.row].type.getFilterResult(texture: PTHarBethFilter.overTexture()).filter!
                self.camera.filters = [filter]
                self.currentFilter = PTCameraFilterConfig.share.filters[indexPath.row]
            }
            collection.reloadData()
        }
        return view
    }()

    lazy var filtersButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(cameraConfig.filtersImage, for: .normal)
        view.setImage(cameraConfig.filtersImageSelected, for: .selected)
        view.isSelected = false
        view.addActionHandlers { sender in
            sender.isSelected = !sender.isSelected
            self.showFilterView(show: sender.isSelected)
        }
        return view
    }()
    
    func showFilterView(show:Bool) {
        if show {
            filterCollectionView.alpha = 1
            view.addSubviews([self.filterCollectionView])
            filterCollectionView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(PTFilterCameraViewController.filterCollectionHeight)
                make.bottom.equalTo(self.toolBar.snp.top)
            }
            
            var rows = [PTRows]()
            thumbnailFilterImages.enumerated().forEach { index,value in
                let row = PTRows(cls: PTFilterImageCell.self,ID:PTFilterImageCell.ID,dataModel: value)
                rows.append(row)
            }
            
            let section = PTSection(rows: rows)
            filterCollectionView.showCollectionDetail(collectionData: [section])

        } else {
            filterCollectionView.alpha = 0
            filterCollectionView.removeFromSuperview()
        }
    }
    
    private func generateFilterImages() {
        let image = originImageView.image!
        let size: CGSize
        let ratio = (image.size.width / image.size.height)
        let fixLength: CGFloat = 200
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        let thumbnailImage = image.pt.resize_vI(size) ?? PTAppBaseConfig.share.defaultEmptyImage
        
        PTGCDManager.gcdGobal {
            let filters = PTCameraFilterConfig.share.filters
            filters.enumerated().forEach { index,value in
                if value.type == .none {
                    self.thumbnailFilterImages.append(PTAppBaseConfig.share.defaultEmptyImage)
                } else {
                    PTHarBethFilter.share.texureSize = thumbnailImage.size
                    self.thumbnailFilterImages.append(value.getCurrentFilterImage(image: thumbnailImage))
                }
            }
        }
    }
    
    private lazy var focusCursorTapGes: UITapGestureRecognizer = {
        let taps = UITapGestureRecognizer { sender in
            let tap = sender as! UITapGestureRecognizer
            guard !self.filtersButton.isSelected else {
                return
            }
            
            guard self.camera.captureSession.isRunning, !self.isAdjustingFocusPoint else {
                return
            }
            let point = tap.location(in: self.view)
            if point.y > self.toolBar.frame.minY - 30 {
                return
            }
            self.setFocusCusor(point: point)
        }
        taps.delegate = self
        return taps
    }()

    public lazy var focusCursorView: UIImageView = {
        let view = UIImageView(image: cameraConfig.focusImage)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        view.alpha = 0
        return view
    }()

    private var cameraFocusPanGes: UIPanGestureRecognizer?
    private var recordLongGes: UILongPressGestureRecognizer?

    public lazy var largeCircleView: UIView = {
        let view = UIView()
        view.layer.addSublayer(borderLayer)
        return view
    }()
    
    public lazy var smallCircleView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = PTFilterCameraViewController.smallCircleRadius / 2
        view.isUserInteractionEnabled = false
        view.backgroundColor = PTFilterCameraViewController.cameraBtnNormalColor
        return view
    }()

    public lazy var borderLayer: CAShapeLayer = {
        let animateLayerRadius = PTFilterCameraViewController.largeCircleRadius
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: animateLayerRadius, height: animateLayerRadius), cornerRadius: animateLayerRadius / 2)
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = PTFilterCameraViewController.cameraBtnNormalColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = PTFilterCameraViewController.borderLayerWidth
        return layer
    }()

    public lazy var animateLayer: CAShapeLayer = {
        let animateLayerRadius = PTFilterCameraViewController.largeCircleRadius
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: animateLayerRadius, height: animateLayerRadius), cornerRadius: animateLayerRadius / 2)
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = UIColor.randomColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = PTFilterCameraViewController.animateLayerWidth
        layer.lineCap = .round
        return layer
    }()
    
    //MARK: 生命週期
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBarBackgroundColor = .clear
        self.zx_hideBaseNavBar = true
#else
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.view.backgroundColor = .clear
#endif
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBarBackgroundColor = .clear
        self.zx_hideBaseNavBar = true
#else
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.view.backgroundColor = .clear
#endif
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        camera.startRunning()
        
//        PTGCDManager.gcdAfter(time: 5) {
//            let vvvvvv = UIButton(type: .custom)
//            vvvvvv.isSelected = true
//            self.camera.takePicture(flashBtn: vvvvvv)
//        }
        
        PTGCDManager.gcdAfter(time: 1, block: {
            self.generateFilterImages()
        })
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.background
        view.addSubviews([originImageView,toolBar,flashButton/*,switchCameraButton*/,focusCursorView,backBtn,filtersButton])
        originImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        toolBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.kTabbarSaveAreaHeight + PTFilterCameraViewController.toolBarHeight)
        }
        
//        switchCameraButton.snp.makeConstraints { make in
//            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
//            make.size.equalTo(34)
//            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + 5)
//        }
        
        flashButton.snp.makeConstraints { make in
//            make.size.right.equalTo(self.switchCameraButton)
//            make.top.equalTo(self.switchCameraButton.snp.bottom).offset(10)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.size.equalTo(34)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + 5)
        }
        
        filtersButton.snp.makeConstraints { make in
            make.size.right.equalTo(self.flashButton)
            make.top.equalTo(self.flashButton.snp.bottom).offset(10)
        }
        
        backBtn.snp.makeConstraints { make in
            make.size.top.equalTo(self.flashButton)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        view.addGestureRecognizer(focusCursorTapGes)

        setupToolBar()
    }
    
    func setupToolBar() {
        toolBar.addSubviews([largeCircleView,smallCircleView])
        largeCircleView.snp.makeConstraints { make in
            make.size.equalTo(PTFilterCameraViewController.largeCircleRadius)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset((PTFilterCameraViewController.toolBarHeight - PTFilterCameraViewController.largeCircleRadius) / 2)
        }
        
        smallCircleView.snp.makeConstraints { make in
            make.size.equalTo(PTFilterCameraViewController.smallCircleRadius)
            make.centerX.equalToSuperview()
            make.centerY.equalTo(self.largeCircleView)
        }
        
        var takePictureTap: UITapGestureRecognizer?
        if cameraConfig.allowTakePhoto {
            takePictureTap = UITapGestureRecognizer { sender in
                self.showFilterView(show: false)
                self.camera.takePicture(flashBtn: self.flashButton)
            }
            takePictureTap?.delegate = self
            largeCircleView.addGestureRecognizer(takePictureTap!)
        }
        
//        if cameraConfig.allowRecordVideo {
//            let longGes = UILongPressGestureRecognizer { sender in
//                let ges = sender as! UILongPressGestureRecognizer
//                if ges.state == .began {
//                    guard PTMediaLibManager.hasCameraAuthority() else {
//                        return
//                    }
//                    self.camera.startRecord()
//                } else if ges.state == .cancelled || ges.state == .ended {
//                    self.camera.finishRecord()
//                }
//            }
//            longGes.minimumPressDuration = 0.3
//            longGes.delegate = self
//            largeCircleView.addGestureRecognizer(longGes)
//            takePictureTap?.require(toFail: longGes)
//            recordLongGes = longGes
//            
//            let panGes = UIPanGestureRecognizer { sender in
//                let pan = sender as! UIPanGestureRecognizer
//                let convertRect = self.toolBar.convert(self.largeCircleView.frame, to: self.view)
//                let point = pan.location(in: self.view)
//                
//                if pan.state == .began {
//                    self.dragStart = true
//                    self.camera.startRecord()
//                } else if pan.state == .changed {
//                    guard self.dragStart else {
//                        return
//                    }
//                    let maxZoomFactor = self.getMaxZoomFactor()
//                    var zoomFactor = (convertRect.midY - point.y) / convertRect.midY * maxZoomFactor
//                    zoomFactor = max(1, min(zoomFactor, maxZoomFactor))
//                    self.camera.setVideoZoomFactor(zoomFactor)
//                } else if pan.state == .cancelled || pan.state == .ended {
//                    guard self.dragStart else {
//                        return
//                    }
//                    self.dragStart = false
//                    self.camera.finishRecord()
//                }
//
//            }
//            panGes.delegate = self
//            panGes.maximumNumberOfTouches = 1
//            largeCircleView.addGestureRecognizer(panGes)
//            cameraFocusPanGes = panGes
//            
//            camera.recordVideoPlayerLayer = AVPlayerLayer()
//            camera.recordVideoPlayerLayer?.backgroundColor = UIColor.black.cgColor
//            camera.recordVideoPlayerLayer?.videoGravity = .resizeAspect
//            camera.recordVideoPlayerLayer?.isHidden = true
//            camera.recordVideoPlayerLayer?.frame = self.view.frame
//            view.layer.insertSublayer(camera.recordVideoPlayerLayer!, at: 0)
//            
//            NotificationCenter.default.addObserver(self, selector: #selector(recordVideoPlayFinished), name: .AVPlayerItemDidPlayToEndTime, object: nil)
//        }

    }
    
    private func setFocusCusor(point: CGPoint) {
        animateFocusCursor(point: point)
        
        // UI坐标转换为摄像头坐标
        let cameraPoint = view.center//previewLayer?.captureDevicePointConverted(fromLayerPoint: point) ?? view.center
        focusCamera(
            mode: cameraConfig.focusMode.avFocusMode,
            exposureMode: cameraConfig.exposureMode.avFocusMode,
            point: cameraPoint
        )
    }
    
    private func animateFocusCursor(point: CGPoint) {
        isAdjustingFocusPoint = true
        focusCursorView.center = point
        focusCursorView.alpha = 1
        
        let scaleAnimation = PTCameraAnimationUtils.animation(type: .scale, fromValue: 2, toValue: 1, duration: 0.25)
        let fadeShowAnimation = PTCameraAnimationUtils.animation(type: .fade, fromValue: 0, toValue: 1, duration: 0.25)
        let fadeDismissAnimation = PTCameraAnimationUtils.animation(type: .fade, fromValue: 1, toValue: 0, duration: 0.25)
        fadeDismissAnimation.beginTime = 0.75
        let group = CAAnimationGroup()
        group.animations = [scaleAnimation, fadeShowAnimation, fadeDismissAnimation]
        group.duration = 1
        group.delegate = self
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        focusCursorView.layer.add(group, forKey: nil)
    }

    private func focusCamera(mode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, point: CGPoint) {
        do {
            guard let device = self.camera.deviceInput?.device else {
                return
            }
            
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(mode) {
                device.focusMode = mode
            }
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
            }
            if device.isExposureModeSupported(exposureMode) {
                device.exposureMode = exposureMode
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
            }
            
            device.unlockForConfiguration()
        } catch {
            PTNSLogConsole("相机聚焦设置失败 \(error.localizedDescription)")
        }
    }

    private func getMaxZoomFactor() -> CGFloat {
        guard let device = self.camera.deviceInput?.device else {
            return 1
        }
        if #available(iOS 11.0, *) {
            return min(15, device.maxAvailableVideoZoomFactor)
        } else {
            return min(15, device.activeFormat.videoMaxZoomFactor)
        }
    }
    
//    @objc private func recordVideoPlayFinished() {
//        camera.recordVideoPlayerLayer?.player?.seek(to: .zero)
//        camera.recordVideoPlayerLayer?.player?.play()
//    }
}

extension PTFilterCameraViewController: C7CollectorImageDelegate {
    
    public func preview(_ collector: C7Collector, fliter image: C7Image) {
        self.originImageView.image = image.pt.fixOrientation()
    }
    
    public func captureOutput(_ collector: C7Collector, pixelBuffer: CVPixelBuffer) {
    }
    
    public func captureOutput(_ collector: C7Collector, texture: MTLTexture) {
    }
    
    public func takePhoto(_ collector: C7Collector, fliter image: C7Image) {
        //TODO: 拍照了之后
        let imagev = UIImageView(image: image)
        imagev.contentMode = .scaleAspectFill
        AppWindows?.addSubview(imagev)
        imagev.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.centerX.centerY.equalToSuperview()
        }
        self.camera.startRunning()
        self.originImageView.contentMode = .scaleAspectFit
    }
}

extension PTFilterCameraViewController {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let gesTuples: [(UIGestureRecognizer?, UIGestureRecognizer?)] = [(recordLongGes, cameraFocusPanGes), (recordLongGes, focusCursorTapGes), (cameraFocusPanGes, focusCursorTapGes)]
        
        let result = gesTuples.map { ges1, ges2 in
            (ges1 == gestureRecognizer && ges2 == otherGestureRecognizer) ||
                (ges2 == otherGestureRecognizer && ges1 == gestureRecognizer)
        }.filter { $0 == true }
        
        return !result.isEmpty
    }
}

extension PTFilterCameraViewController: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim is CAAnimationGroup {
            focusCursorView.alpha = 0
            focusCursorView.layer.removeAllAnimations()
            isAdjustingFocusPoint = false
        } else {
            camera.finishRecord()
        }
    }
}