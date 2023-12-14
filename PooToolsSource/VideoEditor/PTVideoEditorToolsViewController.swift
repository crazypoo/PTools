//
//  PTVideoEditorToolsViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import SwifterSwift
import SnapKit
import Harbeth
import Photos
import SafeSFSymbols
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: .zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: newSize.width/2, y: newSize.height/2)
        context?.rotate(by: CGFloat(radians))
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

class PTCropDimView: UIView {
    private var path: CGPath?

    init() {
        super.init(frame: .zero)
        self.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func mask(_ path: CGPath, duration: TimeInterval, animated: Bool) {
        self.path = path
        if let mask = self.layer.mask as? CAShapeLayer {
            mask.removeAllAnimations()
            if animated {
                let animation = CABasicAnimation(keyPath: "path")
                animation.delegate = self
                animation.fromValue = mask.path
                animation.toValue = path
                animation.byValue = path
                animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                animation.duration = duration
                mask.add(animation, forKey: "path")
            } else {
                mask.path = path
            }
        } else {
            let maskLayer = CAShapeLayer()
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
            maskLayer.backgroundColor = UIColor.clear.cgColor
            maskLayer.path = path
            self.layer.mask = maskLayer
        }
    }
}

extension PTCropDimView:CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let path = self.path else { return }
        if let mask = self.layer.mask as? CAShapeLayer {
            mask.removeAllAnimations()
            mask.path = path
        }
    }
}

@objcMembers
public class PTVideoEditorToolsViewController: PTBaseViewController {

    public var onEditCompleteHandler:((URL)->Void)?
    public var onlyOutput:Bool = false
    
    lazy var dismissButtonItem:UIButton = {
        let image = "❌".emojiToImage(emojiFont: .appfont(size: 20))
        let buttonItem = UIButton(type: .custom)
        buttonItem.setImage(image, for: .normal)
        buttonItem.addActionHandlers { sender in
            self.c7Player.pause()
            self.returnFrontVC()
        }
        return buttonItem
    }()
    
    var loadingProgress:PTMediaBrowserLoadingView?

    lazy var doneButtonItem:UIButton = {
        let image = "✅".emojiToImage(emojiFont: .appfont(size: 20))
        let buttonItem = UIButton(type: .custom)
        buttonItem.setImage(image, for: .normal)
        buttonItem.addActionHandlers { sender in
            self.c7Player.pause()
            
            PTGCDManager.gcdMain {
                if self.loadingProgress == nil {
                    self.loadingProgress = PTMediaBrowserLoadingView(type: .LoopDiagram)
                    self.view.addSubview(self.loadingProgress!)
                    self.loadingProgress!.snp.makeConstraints { make in
                        make.size.equalTo(100)
                        make.centerX.centerY.equalToSuperview()
                    }
                }
                self.setOutPut { url, error in
                    if url != nil {
                        let exporter = Exporter(provider: Exporter.Provider.init(with: url!))
                        exporter.export(options: [
                            .OptimizeForNetworkUse: true,
                        ], filtering: { buffer in
                            let dest = BoxxIO(element: buffer, filters: self.c7Player.filters)
                            return try? dest.output()
                        }, complete: { res in
                            switch res {
                            case .success(let outputURL):
                                if self.onlyOutput {
                                    PTGCDManager.gcdMain {
                                        if self.onEditCompleteHandler != nil {
                                            self.onEditCompleteHandler!(outputURL)
                                        }
                                        self.returnFrontVC()
                                    }
                                } else {
                                    if self.rewrite {
                                        PHPhotoLibrary.shared().performChanges({
                                            // 获取原视频所在的相册
                                            let fetchOptions = PHFetchOptions()
                                            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
                                            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [self.videoAsset.localIdentifier], options: fetchOptions)
                                            
                                            if let asset = assets.firstObject {
                                                let assetCollectionList = PHAssetCollection.fetchAssetCollectionsContaining(asset, with: .album, options: nil)
                                                if let assetCollection = assetCollectionList.firstObject {
                                                    // 从相册中移除原视频
                                                    PTGCDManager.gcdMain {
                                                        let assetToDelete = [asset] as NSArray
                                                        let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                                                        albumChangeRequest?.removeAssets(assetToDelete)
                                                    }
                                                }
                                            }
                                            
                                            // 保存编辑后的视频到用户相册
                                            if let changeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL) {
                                                let assetPlaceholder = changeRequest.placeholderForCreatedAsset
                                            }

                                        }) { success, error in
                                            if success {
                                                PTGCDManager.gcdMain {
                                                    PTAlertTipControl.present(title:"",subtitle:"PT Video editor function save done".localized(),icon:.Done,style: .Normal)
                                                    self.returnFrontVC()
                                                }
                                            } else {
                                                PTGCDManager.gcdMain {
                                                    PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:"PT Photo picker save video error".localized(),icon:.Done,style: .Normal)
                                                }
                                            }
                                            FileManager.pt.removefile(filePath: outputURL.description)
                                        }
                                    } else {
                                        PHPhotoLibrary.pt.saveVideoToAlbum(fileURL: outputURL) { finish, error in
                                            if error == nil,finish {
                                                PTGCDManager.gcdMain {
                                                    PTAlertTipControl.present(title:"",subtitle:"PT Video editor function save done".localized(),icon:.Done,style: .Normal)
                                                    self.returnFrontVC()
                                                }
                                            } else {
                                                PTGCDManager.gcdMain {
                                                    PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:error!.localizedDescription.localized(),icon:.Done,style: .Normal)
                                                }
                                            }
                                            FileManager.pt.removefile(filePath: outputURL.description)
                                        }
                                    }
                                }
                            case .failure(let error):
                                PTGCDManager.gcdMain {
                                    PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:error.localizedDescription.localized(),icon:.Done,style: .Normal)
                                }
                            }
                        })
                    } else {
                        PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:error?.localizedDescription ?? "",icon: .Error,style: .Normal)
                    }
                }
            }
        }
        return buttonItem
    }()
    
    fileprivate var videoAsset:PHAsset!
    fileprivate var videoAVAsset:AVAsset!
    var c7Player:C7CollectorVideo!
    
    lazy var imageContent:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var originImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var originFilterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    
    fileprivate var avPlayer : AVPlayer!
    fileprivate var avPlayerItem : AVPlayerItem!
    var assetAspectRatio: CGFloat {
        guard let track = avPlayerItem.asset.tracks(withMediaType: AVMediaType.video).first else {
            return .zero
        }

        let assetSize = track.naturalSize.applying(track.preferredTransform)

        return abs(assetSize.width) / abs(assetSize.height)
    }
    
    //MARK: 播放按鈕
    lazy var playContent:UIView = {
        let view = UIView()
        return view
    }()
    
    var currentPlayTime:Float64 = 0
    var videoTime:Double = 0

    lazy var playerButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(UIImage(.play.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)), for: .normal)
        view.setImage(UIImage(.pause.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)), for: .selected)
        view.isSelected = false
        view.addActionHandlers { sender in
            sender.isSelected = !sender.isSelected
            if sender.isSelected {
                if self.currentFilter.type == .none {
                    self.c7Player.filters = []
                } else {
                    self.c7Player.filters = [self.currentFilter.type.getFilterResult(texture: PTHarBethFilter.overTexture()!).filter!]
                }

                if self.currentPlayTime != 0  {
                    let cmTime = CMTimeMakeWithSeconds(self.currentPlayTime, preferredTimescale: Int32(NSEC_PER_MSEC))
                    self.avPlayer.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
                } else {
                    let startTimeSecond = self.videoTime * self.trimPositions.0
                    let endTimeSecond = self.videoTime * self.trimPositions.1
                    let startTime = CMTimeMakeWithSeconds(startTimeSecond, preferredTimescale: Int32(NSEC_PER_MSEC))
                    let endTime = CMTimeMakeWithSeconds(endTimeSecond, preferredTimescale: Int32(NSEC_PER_MSEC))
                    self.avPlayer.seek(to: startTime)
                }
                let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_MSEC))
                let timeObserverToken = self.avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { time in
                    // 在这里处理播放时间的更新
                    PTGCDManager.gcdMain {
                        self.currentPlayTime = CMTimeGetSeconds(time)
                        let formattedCurrentTime = self.currentPlayTime >= 3600 ?
                            DateComponentsFormatter.longDurationFormatter.string(from: self.currentPlayTime) ?? "" :
                            DateComponentsFormatter.shortDurationFormatter.string(from: self.currentPlayTime) ?? ""
                        self.currentTimeLabel.text = formattedCurrentTime
                        
                        self.updateScrollViewContentOffset(fractionCompleted: (self.currentPlayTime / self.videoTime))
                        
                        let endTimeSecond = self.videoTime * self.trimPositions.1
                        if self.currentPlayTime >= CMTimeGetSeconds(CMTime(seconds: endTimeSecond, preferredTimescale: CMTimeScale(NSEC_PER_MSEC))) {
                            self.c7Player.pause()
                            self.currentPlayTime = self.videoTime * self.trimPositions.0
                            sender.isSelected = false
                            self.currentTimeLabel.text = "0:00"
                            self.updateScrollViewContentOffset(fractionCompleted: self.trimPositions.0)
                        }
                    }
                }
                self.c7Player.play()
            } else {
                self.c7Player.pause()
            }
        }
        return view
    }()
    
    lazy var centerLine:UIView = {
        let view = UIView()
        view.backgroundColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)
        return view
    }()

    lazy var currentTimeLabel:UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "0:00"
        label.font = .systemFont(ofSize: 13.0)
        label.textColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)
        return label
    }()

    lazy var videoTimeLabel:UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "0:00"
        label.font = .systemFont(ofSize: 13.0)
        label.textColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)
        return label
    }()
    
    //MARK: 時間線
    var trimPositions: (Double, Double) = (0.0,1.0) {
        didSet {
            self.setVideoAsset()
            self.reloadAsset()
        }
    }
    
    var isSeeking: Bool = false {
        didSet {
            if isSeeking {
                if self.playerButton.isSelected {
                    self.playerButton.isSelected = false
                }
                self.c7Player.pause()
            }
        }
    }
    
    var seekerValue: Double = 0.0
    
    lazy var timeLineContent:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var timeLineView:PTVideoEditorVideoTimeLineView = {
        let view = PTVideoEditorVideoTimeLineView()
        return view
    }()
    
    lazy var timeLineScroll:UIScrollView = {
        let view = UIScrollView()
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    lazy var currentTimeLine:CALayer = {
        let layer = CALayer()
        layer.backgroundColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white).cgColor
        layer.cornerRadius = 1.0
        return layer
    }()


    //MARK: Bottom Control
    lazy var bottomContent:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var bottomControlModels:[PTVideoEditorToolsModel] = {
        let filterModel = PTVideoEditorToolsModel(videoControl: .filter)
        let speedModel = PTVideoEditorToolsModel(videoControl: .speed)
        let trimModel = PTVideoEditorToolsModel(videoControl: .trim)
        let cropModel = PTVideoEditorToolsModel(videoControl: .crop)
        let rotateModel = PTVideoEditorToolsModel(videoControl: .rotate)
        let muteModel = PTVideoEditorToolsModel(videoControl: .mute)
        let presetsModel = PTVideoEditorToolsModel(videoControl: .presets)
//        let rewriteModel = PTVideoEditorToolsModel(videoControl: .rewrite)
        return [filterModel,speedModel,trimModel,cropModel,rotateModel,muteModel,presetsModel/*,rewriteModel*/]
    }()
    
    lazy var bottomControlCollection:PTCollectionView = {
        let collectionConfig = PTCollectionViewConfig()
        collectionConfig.viewType = .Custom
        
        let view = PTCollectionView(viewConfig: collectionConfig)
        view.customerLayout = { sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            let groupH:CGFloat = 60
            let screenW:CGFloat = self.bottomContent.frame.size.width
            let cellHeight:CGFloat = groupH
            let cellWidth:CGFloat = 90
            var itemOriginalX:CGFloat = 0
            if CGFloat(self.bottomControlModels.count) * cellWidth >= screenW {
                itemOriginalX = 0
            } else {
                itemOriginalX = (screenW - CGFloat(self.bottomControlModels.count) * cellWidth) / 2
            }
            var groupW:CGFloat = itemOriginalX
            sectionModel.rows.enumerated().forEach { (index,model) in
                let cellHeight:CGFloat = cellHeight
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: groupW, y: 0, width: cellWidth, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupW += cellWidth
                if index == (self.bottomControlModels.count - 1) {
                    groupW += itemOriginalX
                }
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupW), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collectionViews,sectionModel,indexPath in
            let itemRow = sectionModel.rows[indexPath.row]
            let cellModel = itemRow.dataModel as! PTVideoEditorToolsModel
            let cell = collectionViews.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTVideoEditorToolsCell
            cell.configure(with: cellModel)
            return cell
        }
        view.collectionDidSelect = { collectionViews,sectionModel,indexPath in
            self.c7Player.pause()
            self.playerButton.isSelected = false
            
            let itemRow = sectionModel.rows[indexPath.row]
            let cellModel = itemRow.dataModel as! PTVideoEditorToolsModel
            switch cellModel.videoControl {
            case .speed:
                let vc = PTVideoEditorToolsSpeedControl(speed: self.speed,typeModel: cellModel)
                vc.speedHandler = { value in
                    self.speed = value
                }
                self.sheetPresent_floating(modalViewController:vc,type:.custom, scale:0.3,panGesDelegate:self,completion:{
                    
                },dismissCompletion:{
                })
            case .trim:
                let vc = PTVideoEditorToolsTrimControl(trimPositions: self.trimPositions, asset: self.avPlayer.currentItem!.asset,typeModel: cellModel)
                self.sheetPresent_floating(modalViewController:vc,type:.custom, scale:0.3,panGesDelegate:self,completion:{
                    
                },dismissCompletion:{
                    
                })
                vc.trimPosotionsHandler = { value in
                    self.trimPositions = value
                }
            case .crop:
                guard let image = self.originImageView.image!.rotate(radians: Float(CGFloat(.pi/2 * self.rotate))) else { return }
                
                let vc = PTVideoEditorToolsCropControl(image: image)
                vc.cropImageHandler = { imageSize,cropFrame in
                    PTGCDManager.gcdAfter(time: 0.1) {
                        let videoRect = self.videoRect
                        let frameX = cropFrame.origin.x * videoRect.size.width / imageSize.width
                        let frameY = cropFrame.origin.y * videoRect.size.height / imageSize.height
                        let frameWidth = cropFrame.size.width * videoRect.size.width / imageSize.width
                        let frameHeight = cropFrame.size.height * videoRect.size.height / imageSize.height
                        let dimFrame = CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight)
                        self.dimFrame = dimFrame
                    }
                }
                let nav = PTBaseNavControl(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: false)

            case .rotate:
                var transform = CGAffineTransform.identity
                self.rotate += 1
                if self.rotate == 4 {
                    self.rotate = 0
                    self.degree = 0
                } else {
                    let rotate = CGFloat(.pi / 2 * self.rotate)
                    transform = transform.rotated(by: rotate)
                    self.degree = rotate * 180 / CGFloat.pi
                }
                self.dimFrame = nil
                self.originImageView.transform = transform
                self.dimView.transform = transform
            case .mute:
                let cell = collectionViews.cellForItem(at: indexPath) as! PTVideoEditorToolsCell
                cell.buttonView.isSelected.toggle()
                self.isMute.toggle()
            case .presets:
                let presets = AVAssetExportSession.exportPresets(compatibleWith: self.avPlayer.currentItem!.asset)
                
                UIAlertController.baseActionSheet(title: "PT Video editor function export preset select".localized(),subTitle: String(format: "PT Video editor function export preset select current".localized(), self.presets), titles: presets) { sheet, index, title in
                    self.presets = title
                }
            case .filter:
                let vc = PTVideoEditorFilterControl(currentImage: self.originFilterImageView, currentFilter: self.currentFilter, viewControl: cellModel)
                vc.filterHandler = { filter in
                    self.currentFilter = filter
                    self.reloadAsset()
                }
                self.sheetPresent_floating(modalViewController:vc,type:.custom, scale:0.3,panGesDelegate:self,completion:{
                    
                },dismissCompletion:{
                    
                })
            case .rewrite:
                let cell = collectionViews.cellForItem(at: indexPath) as! PTVideoEditorToolsCell
                cell.buttonView.isSelected.toggle()
                self.rewrite.toggle()
            }
        }
        return view
    }()
    
    //MARK: 速度
    fileprivate var speed:Double = 1 {
        didSet {
            self.setVideoAsset()
            self.reloadAsset()
        }
    }
    
    //MARK: 旋轉
    fileprivate var rotate:Double = 0
    
    //MARK: 裁剪
    private let dimView: PTCropDimView = {
        let dimView = PTCropDimView()
        dimView.backgroundColor = UIColor(white: 0/255, alpha: 0.8)
        return dimView
    }()
    
    //MARK: Filter
    private var currentFilter: PTHarBethFilter! = PTHarBethFilter.none
    
    var videoRect: CGRect {
        if self.degree == 0 || self.degree == 180 {
            return self.originImageView.frame
        } else if self.degree == 90 || self.degree == 270 {
            return CGRect(x: self.originImageView.frame.origin.y, y: self.originImageView.frame.origin.x, width: self.originImageView.size.height, height: self.originImageView.size.width)
        } else {
            return .zero
        }
    }
    
    var degree: CGFloat = 0 {
        didSet {
            let dimFrame = self.dimFrame
            self.dimFrame = dimFrame
        }
    }

    var dimFrame: CGRect? = nil {
        didSet {
            if let dimFrame = self.dimFrame {
                var maskX: CGFloat = 0
                var maskY: CGFloat = 0
                var maskWidth: CGFloat = 0
                var maskHeight: CGFloat = 0
                if self.degree == 0 || self.degree == 180 {
                    maskX = ((self.dimView.frame.width - self.originImageView.width) / 2) + dimFrame.origin.x
                    maskY = ((self.dimView.frame.height - self.originImageView.height) / 2) + dimFrame.origin.y
                    maskWidth = dimFrame.width
                    maskHeight = dimFrame.height
                } else if self.degree == 90 || self.degree == 270 {
                    maskX = ((self.dimView.frame.width - self.originImageView.height) / 2) + dimFrame.origin.x
                    maskY = ((self.dimView.frame.height - self.originImageView.width) / 2) + dimFrame.origin.y
                    maskWidth = dimFrame.width
                    maskHeight = dimFrame.height
                }
                let rect = CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
                let path = UIBezierPath(rect: rect)
                path.append(UIBezierPath(rect: self.dimView.bounds))
                self.dimView.mask(path.cgPath, duration: 0, animated: false)
                self.dimView.isHidden = false
            } else {
                self.dimView.isHidden = true
            }
        }
    }
    
    //MARK: 靜音
    fileprivate var isMute:Bool = false
    
    //MARK: 输出清晰度
    fileprivate var presets:String = AVAssetExportPresetHighestQuality
    
    //MARK: 覆蓋源文件
    fileprivate var rewrite:Bool = false
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
#else
        PTBaseNavControl.GobalNavControl(nav: navigationController!)
#endif
    }
    
    public init(asset:PHAsset) {
        videoAsset = asset
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

#if POOTOOLS_NAVBARCONTROLLER
        zx_navBar?.addSubviews([dismissButtonItem,doneButtonItem])
        dismissButtonItem.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.bottom.equalToSuperview().inset(5)
        }
        
        doneButtonItem.snp.makeConstraints { make in
            make.size.bottom.equalTo(self.dismissButtonItem)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
#else
        dismissButtonItem.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        doneButtonItem.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButtonItem)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneButtonItem)
#endif
        
        view.addSubviews([imageContent,playContent,bottomContent,timeLineContent])
        imageContent.snp.makeConstraints { make in
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total + 10)
#else
            make.top.equalToSuperview().inset(10)
#endif
            make.left.right.equalToSuperview().inset(64)
            make.height.equalTo(self.imageContent.snp.width)
        }
        
        imageContent.addSubviews([originImageView,originFilterImageView])
                
        originImageView.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        dimFrame = nil
        
        originFilterImageView.snp.makeConstraints { make in
            make.edges.equalTo(self.originImageView)
        }
        
        playContent.snp.makeConstraints { make in
            make.top.equalTo(self.imageContent.snp.bottom).offset(7.5)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
        
        playContentSet()
        
        bottomContent.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
        }
        
        PTGCDManager.gcdAfter(time: 0.35) {
            self.bottomContentSet()
        }
        
        timeLineContent.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.playContent.snp.bottom)
            make.bottom.equalTo(self.bottomContent.snp.top)
        }
        
        timeLineContentSet()

        convertPHAssetToAVAsset(phAsset: videoAsset) { avAsset in
            self.videoAVAsset = avAsset
            
            UIImage.pt.getVideoFirstImage(asset: self.videoAVAsset,maximumSize: CGSizeMake(.infinity, .infinity)) { image in
                let imageSize = image!.size

                let scale = self.imageContent.frame.size.height / imageSize.height
                let showImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
                self.originFilterImageView.image = image
                self.originImageView.image = image
                self.originImageView.snp.makeConstraints { make in
                    make.width.equalTo(showImageSize.width)
                    make.centerX.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                    make.centerX.centerY.equalToSuperview()
                }
            }
            
            self.avPlayerItem = AVPlayerItem(asset: self.videoAVAsset)
            self.avPlayer = AVPlayer(playerItem: self.avPlayerItem)
            self.c7Player = C7CollectorVideo(player: self.avPlayer, delegate: self)
             
            PTGCDManager.gcdMain {
                self.videoTime = self.avPlayer.currentItem?.duration.seconds ?? 0.0
                self.videoTime = self.videoTime.isNaN ? 0.0 : self.videoTime
                let formattedDuration = self.videoTime >= 3600 ?
                    DateComponentsFormatter.longDurationFormatter.string(from: self.videoTime) ?? "" :
                    DateComponentsFormatter.shortDurationFormatter.string(from: self.videoTime) ?? ""
                self.videoTimeLabel.text = formattedDuration
            }
            
            Task.init {
                do {
                    let timeLineViewRect = CGRect(x: 0, y: 0, width: self.timeLineContent.bounds.width, height: 64)
                    let cgImages = try await self.videoTimeline(for: avAsset!, in: timeLineViewRect, numberOfFrames: self.numberOfFrames(within: timeLineViewRect))
                    self.timeLineScroll.contentSize = CGSize(width: self.view.bounds.width, height: 64.0)
                    self.timeLineView.configure(with: cgImages, assetAspectRatio: self.assetAspectRatio)
                    self.updateScrollViewContentOffset(fractionCompleted: .zero)
                    
                    let width: CGFloat = 2.0
                    let height: CGFloat = 160.0
                    let x = self.timeLineContent.bounds.midX - width / 2
                    let y = (self.timeLineContent.bounds.height - height) / 2
                    self.currentTimeLine.frame = CGRect(x: x, y: y, width: width, height: height)

                } catch {
                    PTAlertTipControl.present(title:"",subtitle:error.localizedDescription,icon: .Error,style: .Normal)
                }
            }
        }
    }
    
    func playContentSet() {
        playContent.addSubviews([playerButton,centerLine,currentTimeLabel,videoTimeLabel])
        
        centerLine.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12.5)
            make.width.equalTo(1.5)
            make.centerX.equalToSuperview()
        }
        
        currentTimeLabel.snp.makeConstraints { make in
            make.right.equalTo(self.centerLine.snp.left).offset(-5)
            make.centerY.equalToSuperview()
        }
        
        videoTimeLabel.snp.makeConstraints { make in
            make.left.equalTo(self.centerLine.snp.left).offset(5)
            make.centerY.equalToSuperview()
        }
        
        playerButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(30)
        }
    }
    
    func timeLineContentSet() {
        timeLineContent.addSubviews([timeLineScroll])
        timeLineScroll.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let horizontal = view.bounds.width / 2
        timeLineScroll.contentInset = UIEdgeInsets(top: 0, left: horizontal, bottom: 0, right: horizontal)
        
        timeLineScroll.addSubview(timeLineView)
        timeLineView.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.width.equalTo(CGFloat.kSCREEN_WIDTH)
            make.centerY.centerX.equalTo(timeLineScroll)
        }
        
        timeLineContent.layer.addSublayer(currentTimeLine)
    }
    
    func bottomContentSet() {
        bottomContent.addSubviews([bottomControlCollection])
        bottomControlCollection.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        var rows = [PTRows]()
        bottomControlModels.enumerated().forEach { index,value in
            let row = PTRows(cls: PTVideoEditorToolsCell.self,ID:PTVideoEditorToolsCell.ID,dataModel: value)
            rows.append(row)
        }
        
        let sections = [PTSection(rows: rows)]
        bottomControlCollection.showCollectionDetail(collectionData: sections) { cView in
        }
    }
    
    public func videoEditorShow(vc:UIViewController) {
        let nav = PTBaseNavControl(rootViewController: self)
        nav.modalPresentationStyle = .fullScreen
        vc.present(nav, animated: true)
    }
    
    fileprivate func setOutPut(completion: @escaping ((URL?, Error?) -> Void)) {

        var videoConverterCrop: ConverterCrop?
        if let dimFrame = dimFrame {
            videoConverterCrop = ConverterCrop(frame: dimFrame, contrastSize: originImageView.size)
        }

        let options = ConverterOption(
            trimRange: trimPositions,
            convertCrop: videoConverterCrop,
            rotate: CGFloat(.pi/2 * self.rotate),
            quality: presets,
            isMute: self.isMute,
            speed: speed)

        let videoConverter: VideoConverter = VideoConverter(asset:self.videoAVAsset)
        videoConverter.convert(options,progress: { progress in
            PTGCDManager.gcdMain {
                if progress ?? 0 >= 1 {
                    self.loadingProgress = nil
                } else {
                    self.loadingProgress?.progress = progress ?? 0
                }
                
            }
        },completion: completion)
    }
    
    fileprivate func setVideoAsset() {

        let options = ConverterOption(
            trimRange: trimPositions,
            convertCrop: nil,
            rotate: 0,
            quality: presets,
            isMute: false,
            speed: speed)

        let videoConverter: VideoConverter = VideoConverter(asset:self.videoAVAsset)
        videoConverter.convert(options) { ac,avc in
            PTGCDManager.gcdMain {
                self.avPlayerItem = AVPlayerItem(asset: ac)
                self.avPlayerItem.videoComposition = avc
                self.avPlayer = AVPlayer(playerItem: self.avPlayerItem)
                
                
                UIImage.pt.getVideoFirstImage(asset: self.avPlayer.currentItem!.asset,maximumSize: CGSizeMake(.infinity, .infinity)) { image in
                    self.originImageView.image = image
                }
                self.c7Player = C7CollectorVideo(player: self.avPlayer, delegate: self)
            }
        }
    }
    
    func reloadAsset() {
        PTGCDManager.gcdAfter(time: 0.35) {
            PTGCDManager.gcdMain {
                self.videoTime = self.avPlayer.currentItem?.duration.seconds ?? 0.0
                self.videoTime = self.videoTime.isNaN ? 0.0 : self.videoTime
                let formattedDuration = self.videoTime >= 3600 ?
                    DateComponentsFormatter.longDurationFormatter.string(from: self.videoTime) ?? "" :
                    DateComponentsFormatter.shortDurationFormatter.string(from: self.videoTime) ?? ""
                self.videoTimeLabel.text = formattedDuration
                self.currentPlayTime = 0
            }

            Task.init {
                do {
                    let timeLineViewRect = CGRect(x: 0, y: 0, width: self.timeLineContent.bounds.width, height: 64)
                    let cgImages = try await self.videoTimeline(for: self.avPlayer.currentItem!.asset, in: timeLineViewRect, numberOfFrames: self.numberOfFrames(within: timeLineViewRect))
                    self.timeLineScroll.contentSize = CGSize(width: self.view.bounds.width, height: 64.0)
                    self.timeLineView.configure(with: cgImages, assetAspectRatio: self.assetAspectRatio)
                    self.updateScrollViewContentOffset(fractionCompleted: .zero)
                    
                    let width: CGFloat = 2.0
                    let height: CGFloat = 160.0
                    let x = self.timeLineContent.bounds.midX - width / 2
                    let y = (self.timeLineContent.bounds.height - height) / 2
                    self.currentTimeLine.frame = CGRect(x: x, y: y, width: width, height: height)

                } catch {
                    PTAlertTipControl.present(title:"",subtitle:error.localizedDescription,icon: .Error,style: .Normal)
                }
            }
        }
    }
}

//MARK: 視頻轉換
extension PTVideoEditorToolsViewController {
    func getURLForPHAsset(asset: PHAsset, completion: @escaping (URL?) -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { (avAsset, _, _) in
            guard let avURLAsset = avAsset as? AVURLAsset else {
                completion(nil)
                return
            }
            completion(avURLAsset.url)
        }
    }
    
    // 获取PHAsset并转换为AVAsset的方法
    func convertPHAssetToAVAsset(phAsset: PHAsset, completion: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original

        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, _ in
            completion(avAsset)
        }
    }
}

//MARK: 實時圖像輸出
extension PTVideoEditorToolsViewController:C7CollectorImageDelegate {
    public func preview(_ collector: C7Collector, fliter image: C7Image) {
        originImageView.image = image
    }
}

//MARK: 分拆視頻幀
fileprivate extension PTVideoEditorToolsViewController {
    func numberOfFrames(within bounds: CGRect) -> Int {
        let frameWidth = bounds.height * assetAspectRatio
        return Int(bounds.width / frameWidth) + 1
    }
    
    func frameTimes(for asset: AVAsset,
                    numberOfFrames: Int) -> [NSValue] {
        let timeIncrement = (asset.duration.seconds * 1000) / Double(numberOfFrames)
        var timesForThumbnails = [CMTime]()

        for index in 0..<numberOfFrames {
            let cmTime = CMTime(value: Int64(timeIncrement * Float64(index)), timescale: 1000)
            timesForThumbnails.append(cmTime)
        }

        return timesForThumbnails.map(NSValue.init)
    }
    
    func videoTimeline(for asset: AVAsset,
                       in bounds: CGRect,
                       numberOfFrames: Int) async throws -> [CGImage] {
        try! await withUnsafeThrowingContinuation { continuation in
            let generator = AVAssetImageGenerator(asset: asset)
            var images = [CGImage]()
            let times = self.frameTimes(for: asset, numberOfFrames: numberOfFrames)

            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = .zero // TODO

            generator.generateCGImagesAsynchronously(forTimes: times) { _, cgImage, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let cgImage = cgImage {
                    images.append(cgImage)
                    if images.count == numberOfFrames {
                        continuation.resume(returning: images)
                    }
                } else {
                    continuation.resume(throwing: NSError(domain: "Error while generating CGImages", code: 0))
                }
            }
        }
    }
}

//MARK: ScrollView Delegate
extension PTVideoEditorToolsViewController: UIScrollViewDelegate {
    func updateScrollViewContentOffset(fractionCompleted: Double) {
        let x = timeLineScroll.contentSize.width * CGFloat(fractionCompleted) - (timeLineScroll.contentSize.width / 2)
        let point = CGPoint(x: x, y: 0)
        timeLineScroll.setContentOffset(point, animated: false)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isSeeking = true
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isSeeking = false
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isSeeking = false
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let presentValue = Double((scrollView.contentOffset.x + (scrollView.contentSize.width / 2)) / scrollView.contentSize.width)
        let current = Float64(videoTime * presentValue)
        let cmTime = CMTimeMakeWithSeconds(current, preferredTimescale: Int32(NSEC_PER_SEC))
        self.currentPlayTime = CMTimeGetSeconds(cmTime)
        let formattedCurrentTime = self.currentPlayTime >= 3600 ?
            DateComponentsFormatter.longDurationFormatter.string(from: self.currentPlayTime) ?? "" :
            DateComponentsFormatter.shortDurationFormatter.string(from: self.currentPlayTime) ?? ""
        self.currentTimeLabel.text = formattedCurrentTime
    }
}
