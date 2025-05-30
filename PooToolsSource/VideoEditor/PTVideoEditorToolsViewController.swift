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

public let OutputFilePath = FileManager.pt.DocumnetsDirectory() + "/AudioEditor"

actor ImageStore {
    private var images: [CGImage] = []
    
    func append(_ image: CGImage) {
        images.append(image)
    }
    
    func getImages() -> [CGImage] {
        return images
    }
    
    var count: Int {
        return images.count
    }
}

actor ErrorStore {
    private var error: Error?
    
    func set(_ newError: Error) {
        if error == nil {
            error = newError
        }
    }
    
    func get() -> Error? {
        return error
    }
}

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
        let image = PTVideoEditorConfig.share.dismissImage
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
        let image = PTVideoEditorConfig.share.doneImage
        let buttonItem = UIButton(type: .custom)
        buttonItem.setImage(image, for: .normal)
        buttonItem.addActionHandlers { sender in
            self.c7Player.pause()
            
            PTGCDManager.gcdMain {
                PTAlertTipControl.present(title:PTVideoEditorConfig.share.alertTitleDoing,subtitle:PTVideoEditorConfig.share.alertTitleConvetering,icon:.Heart,style: .Normal)
                if self.loadingProgress == nil {
                    self.loadingProgress = PTMediaBrowserLoadingView(type: .LoopDiagram)
                    AppWindows!.addSubview(self.loadingProgress!)
                    self.loadingProgress!.snp.makeConstraints { make in
                        make.size.equalTo(100)
                        make.centerX.centerY.equalToSuperview()
                    }
                }
                self.setOutPut { url, error in
                    if url != nil {
                        if self.isOnlyAudio {
                            self.onEditCompleteHandler?(url!)
                            self.returnFrontVC()
                        } else {
                            PTGCDManager.gcdMain {
                                PTAlertTipControl.present(title:PTVideoEditorConfig.share.alertTitleDoing,subtitle:PTVideoEditorConfig.share.alertTitleOutputing,icon:.Heart,style: .Normal)

                                let hudConfig = PTHudConfig.share
                                hudConfig.hudColors = [.gray,.gray]
                                hudConfig.lineWidth = 4
                                
                                let hud = PTHudView()
                                hud.hudShow()

                                let documents = FileManager.pt.DocumnetsDirectory()
                                let random = Int(arc4random_uniform(89999) + 10000)
                                let outputURL = documents.appendingPathComponent("condy_export_video_\(random).\(self.currentOutputType.name)")

                                let exporter = Exporter(provider: Exporter.Provider.init(with: url!,to: URL(fileURLWithPath: outputURL)))
                                exporter.export(options: [
                                    .OptimizeForNetworkUse: true,
                                ], filtering: { buffer in
                                    let dest = HarbethIO(element: buffer, filters: self.c7Player.filters)
                                    return try? dest.output()
                                }, complete: { res in
                                    PTGCDManager.gcdMain {
                                        hud.hide(completion: nil)
                                    }
                                    switch res {
                                    case .success(let outputURL):
                                        if self.onlyOutput {
                                            PTGCDManager.gcdMain {
                                                self.onEditCompleteHandler?(outputURL)
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
                                                            PTAlertTipControl.present(title:"",subtitle:PTVideoEditorConfig.share.alertTitleSaveDone,icon:.Done,style: .Normal)
                                                            self.returnFrontVC()
                                                        }
                                                    } else {
                                                        PTGCDManager.gcdMain {
                                                            PTAlertTipControl.present(title:PTVideoEditorConfig.share.alertTitleOpps,subtitle:PTVideoEditorConfig.share.alertTitleSaveError,icon:.Done,style: .Normal)
                                                        }
                                                    }
                                                    FileManager.pt.removefile(filePath: outputURL.description)
                                                }
                                            } else {
                                                PHPhotoLibrary.pt.saveVideoToAlbum(fileURL: outputURL) { finish, error in
                                                    if error == nil,finish {
                                                        PTGCDManager.gcdMain {
                                                            PTAlertTipControl.present(title:"",subtitle:PTVideoEditorConfig.share.alertTitleSaveDone,icon:.Done,style: .Normal)
                                                            self.returnFrontVC()
                                                        }
                                                    } else {
                                                        PTGCDManager.gcdMain {
                                                            PTAlertTipControl.present(title:PTVideoEditorConfig.share.alertTitleOpps,subtitle:error!.localizedDescription.localized(),icon:.Done,style: .Normal)
                                                        }
                                                    }
                                                    FileManager.pt.removefile(filePath: outputURL.description)
                                                }
                                            }
                                        }
                                    case .failure(let error):
                                        PTGCDManager.gcdMain {
                                            self.loadingProgress?.removeFromSuperview()
                                            self.loadingProgress = nil
                                            PTAlertTipControl.present(title:PTVideoEditorConfig.share.alertTitleOpps,subtitle:error.localizedDescription.localized(),icon:.Done,style: .Normal)
                                        }
                                    }
                                })

                            }
                        }
                    } else {
                        self.loadingProgress?.removeFromSuperview()
                        self.loadingProgress = nil
                        PTAlertTipControl.present(title:PTVideoEditorConfig.share.alertTitleOpps,subtitle:error?.localizedDescription ?? "",icon: .Error,style: .Normal)
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

    lazy var playerButton:PTLayoutButton = {
        let view = PTLayoutButton()
        view.imageSize = CGSizeMake(25, 25)
        view.normalImage = UIImage(.play.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        view.selectedImage = UIImage(.pause.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        view.isSelected = false
        view.normalTitle = ""
        view.midSpacing = 0
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
    
    lazy var muteButton:PTActionLayoutButton = {
        let view = PTActionLayoutButton()
        view.layoutStyle = .leftImageRightTitle
        view.imageSize = CGSizeMake(25, 25)
        view.setImage(UIImage(.speaker).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)), state: .normal)
        view.setImage(UIImage(.speaker.zzz).withTintColor(.purple), state: .selected)
        view.isSelected = false
        view.isUserInteractionEnabled = true
        view.midSpacing = 0
        view.addActionHandlers { sender in
            sender.isSelected = !sender.isSelected
            self.isMute = sender.isSelected
        }
        return view
    }()
    
    var currentOutputType:PTConverterOptionOutputType = PTConverterOptionOutputType()
    
    var isOnlyAudio:Bool = false
    let outputTypes:[PTConverterOptionOutputType] = {
        
        /*
         视频
         */
        
        let mov = PTConverterOptionOutputType()
        mov.type = .mov
        
        let mp4 = PTConverterOptionOutputType()
        mp4.type = .mp4

        let m4v = PTConverterOptionOutputType()
        m4v.type = .m4v

        let gp = PTConverterOptionOutputType()
        gp.type = .mobile3GPP

        let gp2 = PTConverterOptionOutputType()
        gp2.type = .mobile3GPP2
        
        /*
         音频
         */
        
        let m4a = PTConverterOptionOutputType()
        m4a.type = .m4a

        let caf = PTConverterOptionOutputType()
        caf.type = .caf
        
        let wav = PTConverterOptionOutputType()
        wav.type = .wav
        
        let aiff = PTConverterOptionOutputType()
        aiff.type = .aiff
        
        let aifc = PTConverterOptionOutputType()
        aifc.type = .aifc
        
        let amr = PTConverterOptionOutputType()
        amr.type = .amr
        
        let mp3 = PTConverterOptionOutputType()
        mp3.type = .mp3
        
        let au = PTConverterOptionOutputType()
        au.type = .au
        
        let ac3 = PTConverterOptionOutputType()
        ac3.type = .ac3
        
        let eac3 = PTConverterOptionOutputType()
        eac3.type = .eac3

        return [mov,mp4,m4v,gp,gp2,m4a,caf,wav,aiff,aifc,amr,mp3,au,ac3,eac3]
    }()
    
    lazy var outputTypeButton:PTLayoutButton = {
        let view = PTLayoutButton()
        view.layoutStyle = .leftTitleRightImage
        view.imageSize = CGSizeMake(15, 15)
        view.normalTitle = currentOutputType.name
        view.normalTitleFont = .appfont(size: 14)
        view.normalTitleColor = .systemBlue
        view.midSpacing = 5
        view.normalImage = UIImage(.chevron.upChevronDown).withTintColor(.systemBlue)
        view.addActionHandlers { sender in
            var titles = [String]()
            self.outputTypes.enumerated().forEach { index,value in
                titles.append(value.name)
            }
            
            UIAlertController.baseActionSheet(title: PTVideoEditorConfig.share.alertTitleOutputType,subTitle: String(format: PTVideoEditorConfig.share.alertTitleOutputTypeOption, self.currentOutputType.name), titles: titles) { sheet, index, title in
                self.currentOutputType = self.outputTypes[index]
                self.outputTypeButton.normalTitle = self.currentOutputType.name
                switch self.currentOutputType.type {
                case .mov,.mp4,.m4v,.mobile3GPP,.mobile3GPP2:
                    self.isOnlyAudio = false
                    self.muteButton.isUserInteractionEnabled = true
                    self.muteButton.isSelected = false
                default:
                    self.isOnlyAudio = true
                    self.muteButton.isSelected = false
                    self.muteButton.isUserInteractionEnabled = false
                }
                self.outputTypeButton.snp.updateConstraints { make in
                    make.width.equalTo(UIView.sizeFor(string: self.currentOutputType.name, font: .appfont(size: 14),height: 34).width + 25)
                }
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
        label.textAlignment = .right
        label.text = "0:00"
        label.font = .systemFont(ofSize: 13.0)
        label.textColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)
        return label
    }()

    lazy var videoTimeLabel:UILabel = {
        let label = UILabel()
        label.textAlignment = .left
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
//        let muteModel = PTVideoEditorToolsModel(videoControl: .mute)
        let presetsModel = PTVideoEditorToolsModel(videoControl: .presets)
//        let rewriteModel = PTVideoEditorToolsModel(videoControl: .rewrite)
        return [filterModel,speedModel,trimModel,cropModel,rotateModel/*,muteModel*/,presetsModel/*,rewriteModel*/]
    }()
    
    lazy var bottomControlCollection:PTCollectionView = {
        let collectionConfig = PTCollectionViewConfig()
        collectionConfig.viewType = .Custom
        
        let view = PTCollectionView(viewConfig: collectionConfig)
        view.registerClassCells(classs: [PTVideoEditorToolsCell.ID:PTVideoEditorToolsCell.self])
        view.customerLayout = { sectionIndex,sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            let groupH:CGFloat = 60
            let screenW:CGFloat = self.bottomContent.frame.size.width
            let cellHeight:CGFloat = groupH
            let cellWidth:CGFloat = 85
            var itemOriginalX:CGFloat = 0
            if CGFloat(self.bottomControlModels.count) * cellWidth >= screenW {
                itemOriginalX = 0
            } else {
                itemOriginalX = (screenW - CGFloat(self.bottomControlModels.count) * cellWidth) / 2
            }
            var groupW:CGFloat = itemOriginalX
            sectionModel.rows?.enumerated().forEach { (index,model) in
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
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTVideoEditorToolsModel,let cell = collectionViews.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTVideoEditorToolsCell {
                cell.configure(with: cellModel)
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collectionViews,sectionModel,indexPath in
            self.c7Player.pause()
            self.playerButton.isSelected = false
            
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTVideoEditorToolsModel {
                switch cellModel.videoControl {
                case .speed:
                    let vc = PTVideoEditorToolsSpeedControl(speed: self.speed,typeModel: cellModel)
                    vc.speedHandler = { value in
                        self.speed = value
                    }
                    self.sheetPresent(vc: vc, size: 0.3)
                case .trim:
                    let vc = PTVideoEditorToolsTrimControl(trimPositions: self.trimPositions, asset: self.avPlayer.currentItem!.asset,typeModel: cellModel)
                    self.sheetPresent(vc: vc, size: 0.3)
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
                    if let cell = collectionViews.cellForItem(at: indexPath) as? PTVideoEditorToolsCell {
                        cell.buttonView.isSelected.toggle()
                        self.isMute.toggle()
                    }
                case .presets:
                    let presets = AVAssetExportSession.exportPresets(compatibleWith: self.avPlayer.currentItem!.asset)
                    
                    UIAlertController.baseActionSheet(title: PTVideoEditorConfig.share.alertTitleExportType,subTitle: String(format: PTVideoEditorConfig.share.alertTitleOutputTypeOption, self.presets), titles: presets) { sheet, index, title in
                        self.presets = title
                    }
                case .filter:
                    let vc = PTVideoEditorFilterControl(currentImage: self.originFilterImageView, currentFilter: self.currentFilter, viewControl: cellModel)
                    vc.filterHandler = { filter in
                        self.currentFilter = filter
                        self.reloadAsset()
                    }
                    self.sheetPresent(vc: vc, size: 0.3)
                case .rewrite:
                    if let cell = collectionViews.cellForItem(at: indexPath) as? PTVideoEditorToolsCell {
                        cell.buttonView.isSelected.toggle()
                        self.rewrite.toggle()
                    }
                }
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
    private var currentFilter: PTHarBethFilter = PTHarBethFilter.none
    
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
        
        if !FileManager.pt.judgeFileOrFolderExists(filePath: OutputFilePath) {
            let result = FileManager.pt.createFolder(folderPath: OutputFilePath)
            if !result.isSuccess {
                PTNSLogConsole("創建失敗", levelType: .Error,loggerType: .Media)
            }
        }
#if POOTOOLS_NAVBARCONTROLLER
#else
        guard let nav = navigationController else { return }
        PTBaseNavControl.GobalNavControl(nav: nav)
#endif
    }
    
    public init(asset:PHAsset,avAsset:AVAsset) {
        videoAsset = asset
        videoAVAsset = avAsset
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

        Task {
            do {
                self.avPlayerItem = AVPlayerItem(asset: self.videoAVAsset)
                self.avPlayer = AVPlayer(playerItem: self.avPlayerItem)
                self.c7Player = C7CollectorVideo(player: self.avPlayer, delegate: self)

                self.videoTime = self.avPlayer.currentItem?.duration.seconds ?? 0.0
                self.videoTime = self.videoTime.isNaN ? 0.0 : self.videoTime
                let formattedDuration = self.videoTime >= 3600 ?
                    DateComponentsFormatter.longDurationFormatter.string(from: self.videoTime) ?? "" :
                    DateComponentsFormatter.shortDurationFormatter.string(from: self.videoTime) ?? ""
                self.videoTimeLabel.text = formattedDuration

                let timeLineViewRect = CGRect(x: 0, y: 0, width: self.timeLineContent.bounds.width, height: 64)
                let cgImages = try await self.videoTimeline(for: self.videoAVAsset, in: timeLineViewRect, numberOfFrames: self.numberOfFrames(within: timeLineViewRect))
                self.timeLineScroll.contentSize = CGSize(width: self.view.bounds.width, height: 64.0)
                self.timeLineView.configure(with: cgImages, assetAspectRatio: self.assetAspectRatio)
                self.updateScrollViewContentOffset(fractionCompleted: .zero)
                self.currentTimeLabel.text = "0:00"

                let imageSize = UIImage(cgImage: cgImages.first!).size
                let scale = self.imageContent.frame.size.height / imageSize.height
                let showImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
                self.originFilterImageView.image = UIImage(cgImage: cgImages.first!)
                self.originImageView.image = UIImage(cgImage: cgImages.first!)
                self.originImageView.snp.makeConstraints { make in
                    make.width.equalTo(showImageSize.width)
                    make.centerX.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                    make.centerX.centerY.equalToSuperview()
                }

                
                let width: CGFloat = 2.0
                let height: CGFloat = 160.0
                let x = self.timeLineContent.bounds.midX - width / 2
                let y = (self.timeLineContent.bounds.height - height) / 2
                self.currentTimeLine.frame = CGRect(x: x, y: y, width: width, height: height)
                self.reloadAsset()
            } catch {
                PTAlertTipControl.present(title:"",subtitle:error.localizedDescription,icon: .Error,style: .Normal)
            }
        }
    }
    
    func playContentSet() {
        playContent.addSubviews([playerButton,muteButton,centerLine,currentTimeLabel,videoTimeLabel,outputTypeButton])
        
        playerButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(10)
        }
        
        muteButton.snp.makeConstraints { make in
            make.size.centerY.equalTo(self.playerButton)
            make.left.equalTo(self.playerButton.snp.right).offset(10)
        }

        centerLine.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12.5)
            make.width.equalTo(1.5)
            make.centerX.equalToSuperview()
        }
        
        outputTypeButton.snp.makeConstraints { make in
            make.height.equalTo(34)
            make.right.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(UIView.sizeFor(string: self.currentOutputType.name, font: .appfont(size: 14),height: 34).width + 25)
        }
        
        currentTimeLabel.snp.makeConstraints { make in
            make.right.equalTo(self.centerLine.snp.left).offset(-5)
            make.centerY.equalToSuperview()
            make.left.lessThanOrEqualTo(self.muteButton.snp.right).offset(10)
        }
        
        videoTimeLabel.snp.makeConstraints { make in
            make.left.equalTo(self.centerLine.snp.left).offset(5)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(self.outputTypeButton.snp.left).offset(-10)
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
            let row = PTRows(ID:PTVideoEditorToolsCell.ID,dataModel: value)
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
            speed: speed,
            outputModel: currentOutputType)

        let videoConverter: VideoConverter = VideoConverter(asset:self.videoAVAsset)
        videoConverter.convert(options,progress: { progress in
            PTGCDManager.gcdMain {
                if progress ?? 0 >= 1 {
                    self.loadingProgress?.removeFromSuperview()
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

            Task {
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
    
    func sheetPresent(vc:UIViewController,size:CGFloat, options: PTSheetOptions? = nil,completion:PTActionTask? = nil,dismissPanGes:Bool = true) {
        let sheet = PTSheetViewController(controller: vc,sizes:[.percent(Float(size))],options: options,dismissPanGes: dismissPanGes)
        sheet.overlayColor = UIColor(white: 0, alpha: 0.25)
        sheet.dismissOnPull = false
        sheet.dismissOnOverlayTap = true
        sheet.hasBlurBackground = false
        sheet.shouldRecognizePanGestureWithUIControls = false
        sheet.allowPullingPastMinHeight = false
        sheet.allowPullingPastMaxHeight = false
        let currentVC = PTUtils.getCurrentVC()
        if currentVC is PTSideMenuControl {
            let currentVC = (currentVC as! PTSideMenuControl).contentViewController
            if let presentedVC = currentVC?.presentedViewController {
                presentedVC.present(sheet, animated: true) {
                    completion?()
                }
            } else {
                currentVC!.present(sheet, animated: true) {
                    completion?()
                }
            }
        } else {
            if let presentedVC = PTUtils.getCurrentVC().presentedViewController {
                presentedVC.present(sheet, animated: true) {
                    completion?()
                }
            } else {
                PTUtils.getCurrentVC().present(sheet, animated: true) {
                    completion?()
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
        try await withUnsafeThrowingContinuation { continuation in
            let generator = AVAssetImageGenerator(asset: asset)
            let times = self.frameTimes(for: asset, numberOfFrames: numberOfFrames)
            
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = .zero
            
            let imageStore = ImageStore()
            let errorStore = ErrorStore()
            let group = DispatchGroup()
            
            for time in times {
                group.enter()
                generator.generateCGImagesAsynchronously(forTimes: [time]) { _, cgImage, _, _, error in
                    Task {
                        if let error = error {
                            await errorStore.set(error)
                        } else if let cgImage = cgImage {
                            await imageStore.append(cgImage)
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                Task {
                    if let error = await errorStore.get() {
                        continuation.resume(throwing: error)
                    } else if await imageStore.count == numberOfFrames {
                        continuation.resume(returning: await imageStore.getImages())
                    } else {
                        continuation.resume(throwing: NSError(domain: "Error while generating CGImages", code: 0))
                    }
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
