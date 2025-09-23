//
//  PTFilterCameraViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Harbeth
import AVFoundation
import SnapKit
import SwifterSwift
import SafeSFSymbols
import DeviceKit
import Photos

public class PTFilterCameraViewController: PTBaseViewController {

    public var onlyCamera:Bool = true
    public var useThisImageHandler:((UIImage) -> Void)?
    public var mediaLibDismissCallback:PTActionTask? = nil
    
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

    var takePhotoView:PTTakePictureReviewer?
    
    lazy var originImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .black
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    lazy var camera: C7CollectorCamera = {
        let camera = C7CollectorCamera(delegate: self)
        camera.largeCircleView = self.largeCircleView
        camera.smallCircleView = self.smallCircleView
        camera.borderLayer = self.borderLayer
        camera.animateLayer = self.animateLayer
        camera.recordLongGes = self.recordLongGes
        camera.focusCursorView = self.focusCursorView
        camera.isAdjustingFocusPoint = self.isAdjustingFocusPoint
        camera.showedImageView = self.originImageView
        camera.haveRecordVideo = {
            self.resetButton.isHidden = false
            self.useButton.isHidden = false
        }
        camera.savedVideo = {
            PTGCDManager.gcdMain {
                self.resetToolBarView()
            }
        }
        camera.shotImageCallback = { image in
            if self.onlyCamera {
                self.takePhotoView = PTTakePictureReviewer(screenShotImage: image)
                self.takePhotoView?.actionHandle = { type,images in
                    let vc = PTEditImageViewController(readyEditImage: images)
                    vc.editFinishBlock = { ei ,_ in
                        PHPhotoLibrary.pt.saveImageToAlbum(image: ei) { finish, _ in
                            if !finish {
                                PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle: "PT Photo picker save image error".localized(),icon:.Error,style: .Normal)
                            }
                        }
                    }
                    let nav = PTBaseNavControl(rootViewController: vc)
                    nav.view.backgroundColor = .black
                    nav.modalPresentationStyle = .fullScreen
                    PTUtils.getCurrentVC().present(nav, animated: true)
                }
                self.takePhotoView?.reviewHandle = {
                    let browserModel = PTMediaBrowserModel()
                    browserModel.imageURL = image
                    
                    let browserConfig = PTMediaBrowserConfig()
                    browserConfig.mediaData = [browserModel]
                    
                    let review = PTMediaBrowserController()
                    review.modalPresentationStyle = .fullScreen
                    review.reloadConfig(mediaConfig: browserConfig)
                    self.pt_present(review)
                }
                self.takePhotoView?.dismissTask = {
                    self.takePhotoView = nil
                }
                PHPhotoLibrary.pt.saveImageToAlbum(image: image) { [weak self] finish, _ in
                    if !finish {
                        PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle: "PT Photo picker save image error".localized(),icon:.Error,style: .Normal)
                    }
                }
                
                PTGCDManager.gcdAfter(time: 3) {
                    self.takePhotoView?.dismissAlert()
                }
            } else {
                self.camera.stopRunning()
                
                let reviewView = PTFlashImageReviewView(image: image)
                AppWindows?.addSubview(reviewView)
                reviewView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                reviewView.backButton.addActionHandlers { sender in
                    reviewView.removeFromSuperview()
                    self.camera.startRunning()
                }
                reviewView.editButton.addActionHandlers { sender in
                    reviewView.removeFromSuperview()
                    let vc = PTEditImageViewController(readyEditImage: image)
                    vc.editFinishBlock = { ei ,editImageModel in
                        if self.checkVCIsPresenting() {
                            self.dismiss(animated: true) {
                                self.useThisImageHandler?(ei)
                            }
                        } else {
                            self.navigationController?.popViewController(animated: true) {
                                self.useThisImageHandler?(ei)
                            }
                        }
                    }
                    vc.backHandler = {
                        self.camera.startRunning()
                    }
                    let nav = PTBaseNavControl(rootViewController: vc)
                    UIViewController.currentPresentToSheet(vc: nav,sizes: [.fullscreen],dismissPanGes: false)
                }
                reviewView.justThisButton.addActionHandlers { sender in
                    reviewView.removeFromSuperview()
                    if self.checkVCIsPresenting() {
                        self.dismiss(animated: true) {
                            self.useThisImageHandler?(image)
                        }
                    } else {
                        self.navigationController?.popViewController(animated: true) {
                            self.useThisImageHandler?(image)
                        }
                    }
                }
            }
            
            self.camera.isTakingPicture = false
            self.originImageView.contentMode = .scaleAspectFill
        }
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
            if !Gobal_device_info.isSimulator {
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
                        PTNSLogConsole(error.localizedDescription,levelType: .Error,loggerType: .Filter)
                    }
                }
            }
        }
        return view
    }()
    
    lazy var switchCameraButton:UIButton = {
        let cameraCount = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices.count

        let view = UIButton(type: .custom)
        view.setImage(cameraConfig.switchCameraImage, for: .normal)
        view.setImage(cameraConfig.switchCameraImageSelected, for: .selected)
        view.isHidden = cameraCount <= 1
        view.addActionHandlers { sender in
            self.camera.changeCamera {
                PTGCDManager.gcdMain {
                    sender.isSelected.toggle()
                    let rotationAngle: CGFloat = CGFloat.pi / 2
                    self.originImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)

                    self.originImageView.contentMode = .scaleAspectFill
                    self.originImageView.image = self.originImageView.image?.transformImage(size: CGSizeMake(CGFloat.kSCREEN_WIDTH, CGFloat.kSCREEN_HEIGHT))

                    self.originImageView.snp.remakeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                }
            }
        }
        return view
    }()
    
    lazy var backBtn : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(cameraConfig.backImage, for: .normal)
        view.addActionHandlers { _ in
            self.camera.stopRunning()
            if self.navigationController?.viewControllers.count ?? 0 > 1 {
                self.navigationController?.popViewController(animated: true) {
                    self.mediaLibDismissCallback?()
                }
            } else {
                self.returnFrontVC()
            }
        }
        return view
    }()
    
    private var thumbnailFilterImages: [UIImage] = []
    private lazy var filterCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom
        config.alwaysBounceVertical = false
        config.alwaysBounceHorizontal = true

        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFilterImageCell.ID:PTFilterImageCell.self])
        view.isUserInteractionEnabled = true
        view.customerLayout = { sectionIndex,sectionModel in
            return UICollectionView.horizontalLayout(data: sectionModel.rows!,itemOriginalX: PTAppBaseConfig.share.defaultViewSpace,itemWidth: 78,itemHeight: PTFilterCameraViewController.filterCollectionHeight,topContentSpace: 5,itemLeadingSpace: 10)
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTImageEditorConfig.share
            if let itemRow = sectionModel.rows?[indexPath.row],let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFilterImageCell,let cellTools = itemRow.dataModel as? UIImage {
                let cellFilter = PTCameraFilterConfig.share.filters[indexPath.row]
                cell.imageView.image = cellTools
                cell.nameLabel.text = cellFilter.name
                
                if self.currentFilter == cellFilter {
                    cell.nameLabel.textColor = config.themeColor
                } else {
                    cell.nameLabel.textColor = .lightGray
                }
                return cell
            }
            return nil
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
                self.resetToolBarView()
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
            view.addSubviews([filterCollectionView])
            filterCollectionView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(PTFilterCameraViewController.filterCollectionHeight)
                make.bottom.equalTo(self.toolBar.snp.top)
            }
            view.bringSubviewToFront(filterCollectionView)
            
            let rows = thumbnailFilterImages.map {
                PTRows(ID:PTFilterImageCell.ID,dataModel: $0)
            }
            
            let section = PTSection(rows: rows)
            filterCollectionView.showCollectionDetail(collectionData: [section])

        } else {
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
        layer.strokeColor = PTCameraFilterConfig.share.recordingLineColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = PTFilterCameraViewController.animateLayerWidth
        layer.lineCap = .round
        return layer
    }()
    
    public lazy var resetButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(cameraConfig.reloadCameraImage, for: .normal)
        view.isHidden = true
        view.addActionHandlers { sender in
            self.resetToolBarView()
        }
        return view
    }()
    
    public lazy var useButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(cameraConfig.outputVideImage, for: .normal)
        view.isHidden = true
        view.addActionHandlers { sender in
            self.camera.saveVideoToAlbum()
        }
        return view
    }()
    
    //MARK: 生命週期
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.view.backgroundColor = .clear
        changeStatusBar(type: .Dark)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.view.backgroundColor = .clear
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.mediaLibDismissCallback?()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
                
        PTGCDManager.gcdAfter(time: 0.1) {
            if !Gobal_device_info.isSimulator {
                switch PTPermission.camera.status {
                case .notDetermined:
                    PTPermission.camera.request {
                        switch PTPermission.camera.status {
                        case .authorized:
                            self.camera.startRunning()
                        default:
                            return
                        }
                    }
                case .authorized:
                    self.camera.startRunning()
                default:
                    return
                }
                PTGCDManager.gcdAfter(time: 1, block: {
                    if self.camera.captureSession.isRunning,self.originImageView.image != nil {
                        self.generateFilterImages()
                    }
                })
            }
        }
    }
    
    func resetToolBarView() {
        self.camera.isTakingPicture = false
        self.resetButton.isHidden = true
        self.useButton.isHidden = true
        self.camera.resetCameraView()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.black
        view.addSubviews([originImageView,toolBar,flashButton,switchCameraButton,focusCursorView,backBtn,filtersButton])
        originImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        toolBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.kTabbarSaveAreaHeight + PTFilterCameraViewController.toolBarHeight)
        }
        
        switchCameraButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.size.equalTo(34)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + 5)
        }
        
        flashButton.snp.makeConstraints { make in
            make.size.right.equalTo(self.switchCameraButton)
            make.top.equalTo(self.switchCameraButton.snp.bottom).offset(10)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        filtersButton.snp.makeConstraints { make in
            make.size.right.equalTo(self.flashButton)
            make.top.equalTo(self.flashButton.snp.bottom).offset(10)
        }
        
        backBtn.snp.makeConstraints { make in
            make.size.top.equalTo(self.switchCameraButton)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        originImageView.addGestureRecognizer(focusCursorTapGes)

        setupToolBar()
    }
    
    func setupToolBar() {
        toolBar.addSubviews([largeCircleView,smallCircleView,resetButton,useButton])
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
            takePictureTap = UITapGestureRecognizer { _ in
                self.resetToolBarView()
                if self.onlyCamera {
                    if self.takePhotoView != nil {
                        self.takePhotoView?.dismissAlert()
                        self.takePhotoView?.dismissTask = {
                            self.takePhotoView = nil
                        }
                    }
                }
                self.showFilterView(show: false)
                self.camera.takePicture(flashBtn: self.flashButton)
            }
            takePictureTap?.delegate = self
            largeCircleView.addGestureRecognizer(takePictureTap!)
        }
        
        if cameraConfig.allowRecordVideo {
            camera.isTakingPicture = true
            let longGes = UILongPressGestureRecognizer { sender in
                if let ges = sender as? UILongPressGestureRecognizer {
                    if ges.state == .began {
                        self.camera.startRecord()
                    } else if ges.state == .cancelled || ges.state == .ended {
                        self.camera.finishRecord()
                    }
                }
            }
            longGes.minimumPressDuration = 0.3
            longGes.delegate = self
            largeCircleView.addGestureRecognizer(longGes)
            takePictureTap?.require(toFail: longGes)
            recordLongGes = longGes

            let panGes = UIPanGestureRecognizer { sender in
                if let pan = sender as? UIPanGestureRecognizer {
                    let convertRect = self.toolBar.convert(self.largeCircleView.frame, to: self.view)
                    let point = pan.location(in: self.view)

                    if pan.state == .began {
                        self.dragStart = true
                        self.camera.startRecord()
                    } else if pan.state == .changed {
                        guard self.dragStart else {
                            return
                        }
                        let maxZoomFactor = self.getMaxZoomFactor()
                        var zoomFactor = (convertRect.midY - point.y) / convertRect.midY * maxZoomFactor
                        zoomFactor = max(1, min(zoomFactor, maxZoomFactor))
                        self.camera.setVideoZoomFactor(zoomFactor)
                    } else if pan.state == .cancelled || pan.state == .ended {
                        guard self.dragStart else {
                            return
                        }
                        self.dragStart = false
                        self.camera.finishRecord()
                    }
                }
            }
            panGes.delegate = self
            panGes.maximumNumberOfTouches = 1
            largeCircleView.addGestureRecognizer(panGes)
            cameraFocusPanGes = panGes

            NotificationCenter.default.addObserver(self, selector: #selector(recordVideoPlayFinished), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
        
        resetButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.centerY.equalTo(self.largeCircleView)
            make.right.equalTo(self.largeCircleView.snp.left).offset(-10)
        }
        
        useButton.snp.makeConstraints { make in
            make.size.centerY.equalTo(self.resetButton)
            make.left.equalTo(self.largeCircleView.snp.right).offset(10)
        }
    }
    
    private func setFocusCusor(point: CGPoint) {
        animateFocusCursor(point: point)
        
        // UI坐标转换为摄像头坐标
        let cameraPoint = view.center
        focusCamera(mode: cameraConfig.focusMode.avFocusMode,
                    exposureMode: cameraConfig.exposureMode.avFocusMode,
                    point: cameraPoint)
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
            guard let device = camera.deviceInput?.device else {
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
            PTNSLogConsole("相机聚焦设置失败 \(error.localizedDescription)",levelType: .Error,loggerType: .Filter)
        }
    }

    private func getMaxZoomFactor() -> CGFloat {
        guard let device = camera.deviceInput?.device else {
            return 1
        }
        return min(15, device.maxAvailableVideoZoomFactor)
    }
    
    @objc private func recordVideoPlayFinished() {
        camera.avPlayer?.player.seek(to: .zero)
        camera.avPlayer?.play()
    }
}

extension PTFilterCameraViewController: C7CollectorImageDelegate {
    
    public func preview(_ collector: C7Collector, fliter image: C7Image) {
        self.originImageView.image = image.pt.fixOrientation()
    }
}

extension PTFilterCameraViewController {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        let gesTuples: [(UIGestureRecognizer?, UIGestureRecognizer?)] = [(recordLongGes, cameraFocusPanGes), (recordLongGes, focusCursorTapGes), (cameraFocusPanGes, focusCursorTapGes)]
//
//        let result = gesTuples.map { ges1, ges2 in
//            (ges1 == gestureRecognizer && ges2 == otherGestureRecognizer) ||
//                (ges2 == otherGestureRecognizer && ges1 == gestureRecognizer)
//        }.filter { $0 == true }
//        return !result.isEmpty
        true
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

class PTFlashImageReviewView:UIView {
    
    lazy var imageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    lazy var backButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTCameraFilterConfig.share.reviewImageBack, for: .normal)
        return view
    }()
    
    lazy var editButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTCameraFilterConfig.share.reviewImageEdit, for: .normal)
        return view
    }()
    
    lazy var justThisButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTCameraFilterConfig.share.reviewImageUse, for: .normal)
        return view
    }()
    
    init(image:UIImage) {
        super.init(frame: .zero)
        
        backgroundColor = .black
        imageView.image = image
        addSubviews([backButton,imageView,editButton,justThisButton])
        
        backButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + 5)
        }
        
        imageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarHeight_Total)
        }
        
        editButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + (CGFloat.kTabbarHeight - 34) / 2)
            make.size.equalTo(34)
        }
        
        justThisButton.snp.makeConstraints { make in
            make.bottom.size.equalTo(self.editButton)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
