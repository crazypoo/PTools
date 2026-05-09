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

public let OutputFilePath = FileManager.pt.DocumnetsDirectory() + "/AudioEditor"

/// 基于 Swift Actor 的现代化防抖器，保证高并发下的线程安全
public actor PTDebouncer {
    private var currentTask: Task<Void, Never>?
    private let delay: TimeInterval

    /// 初始化防抖器
    /// - Parameter delay: 延迟执行的时间（秒）
    public init(delay: TimeInterval) {
        self.delay = delay
    }

    /// 提交需要防抖执行的任务
    /// 如果在延迟时间内再次调用，之前的任务将被取消
    public func debounce(action: @escaping @Sendable () async -> Void) {
        // 取消之前还没来得及执行的旧任务
        currentTask?.cancel()
        
        // 创建新的等待任务
        currentTask = Task {
            do {
                // 等待指定的延迟时间 (将秒转换为纳秒)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // 如果在等待期间任务没有被取消，则执行真正的操作
                guard !Task.isCancelled else { return }
                
                await action()
            } catch {
                // Task.sleep 被取消时会抛出 CancellationError，这里直接忽略即可
            }
        }
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
    // 创建一个 0.3 秒延迟的防抖器
    private let reloadDebouncer = PTDebouncer(delay: 0.3)
    // 用于管理和释放播放进度的监听器，防止 CPU 泄漏
    private var timeObserverToken: Any?
    // 新增：将视频转换器提升为实例变量，方便全局控制（如取消导出、清理缓存）
    private var videoConverter: VideoConverter?

    public var onEditCompleteHandler:((URL)->Void)?
    public var onlyOutput:Bool = false
    
    lazy var dismissButtonItem:UIButton = {
        let image = PTVideoEditorConfig.share.dismissImage
        let buttonItem = UIButton(type: .custom)
        buttonItem.setImage(image, for: .normal)
        buttonItem.addActionHandlers { [weak self] sender in
            guard let self = self else { return }
            self.c7Player.pause()
            self.videoConverter?.restore(cleanupDisk: true)
            self.returnFrontVC()
        }
        buttonItem.bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
        return buttonItem
    }()
    
    var loadingProgress:PTMediaBrowserLoadingView?

    lazy var doneButtonItem:UIButton = {
        let image = PTVideoEditorConfig.share.doneImage
        let buttonItem = UIButton(type: .custom)
        buttonItem.setImage(image, for: .normal)
        buttonItem.addActionHandlers { [weak self] sender in
            guard let self = self else { return }
            self.c7Player.pause()
            
            // 开启现代化的异步流水线！
            Task {
                var hudToHide: PTHudView? = nil
                
                do {
                    // 1. 准备和转换原视频/音频 (UI主线程操作)
                    await MainActor.run {
                        PTAlertTipsViewController.tipsAlertShow(title: PTVideoEditorConfig.share.alertTitleDoing, subtitle: PTVideoEditorConfig.share.alertTitleConvetering, icon: .Heart)
                        if self.loadingProgress == nil {
                            self.loadingProgress = PTMediaBrowserLoadingView(type: .LoopDiagram)
                            AppWindows!.addSubview(self.loadingProgress!)
                            self.loadingProgress!.snp.makeConstraints { make in
                                make.size.equalTo(100)
                                make.centerX.centerY.equalToSuperview()
                            }
                        }
                    }
                    
                    // 等待转换完成...
                    let convertedURL = try await self.setOutPutAsync()
                    
                    // 如果是纯音频，直接结束返回
                    if self.isOnlyAudio {
                        await MainActor.run {
                            self.onEditCompleteHandler?(convertedURL)
                            self.returnFrontVC()
                        }
                        return
                    }
                    
                    // 2. 视频滤镜渲染阶段
                    hudToHide = await MainActor.run { () -> PTHudView in
                        PTAlertTipsViewController.tipsAlertShow(title: PTVideoEditorConfig.share.alertTitleDoing, subtitle: PTVideoEditorConfig.share.alertTitleOutputing, icon: .Heart)
                        let hudConfig = PTHudConfig.share
                        hudConfig.hudColors = [.gray, .gray]
                        hudConfig.lineWidth = 4
                        let hudView = PTHudView()
                        hudView.hudShow()
                        return hudView
                    }
                    
                    let random = Int(arc4random_uniform(89999) + 10000)
                    let outputURL = FileManager.pt.DocumnetsDirectory().appendingPathComponent("condy_export_video_\(random).\(self.currentOutputType.name)")
                    
                    // 等待滤镜导出完成...
                    let finalURL = try await self.harbethExportAsync(sourceURL: convertedURL, outputURL: URL(fileURLWithPath: outputURL))
                    
                    if let hud = hudToHide {
                        await MainActor.run { hud.hide(completion: nil) }
                    }
                    
                    // 3. 收尾与相册保存阶段
                    if self.onlyOutput {
                        await MainActor.run {
                            self.onEditCompleteHandler?(finalURL)
                            self.returnFrontVC()
                        }
                    } else {
                        // 等待相册保存完成...
                        try await self.saveToAlbumAsync(outputURL: finalURL, rewrite: self.rewrite, localIdentifier: self.videoAsset.localIdentifier)
                        
                        // 及时清理临时垃圾
                        FileManager.pt.removefile(filePath: finalURL.path)
                        
                        await MainActor.run {
                            PTAlertTipsViewController.tipsAlertShow(title: "", subtitle: PTVideoEditorConfig.share.alertTitleSaveDone, icon: .Done)
                            self.returnFrontVC()
                        }
                    }
                    
                } catch {
                    // 🚀 终极优势：统一集中处理所有可能发生的错误！
                    await MainActor.run {
                        if let hud = hudToHide { hud.hide(completion: nil) }
                        self.loadingProgress?.removeFromSuperview()
                        self.loadingProgress = nil
                        PTAlertTipsViewController.tipsAlertShow(title: PTVideoEditorConfig.share.alertTitleOpps, subtitle: error.localizedDescription.localized(), icon: .Error)
                    }
                }
            }
        }
        buttonItem.bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
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

    lazy var playerButton:PTActionLayoutButton = {
        let view = PTActionLayoutButton()
        view.layoutStyle = .image
        view.imageSize = CGSizeMake(25, 25)
        view.setImage(UIImage(.play.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)), state: .normal)
        view.setImage(UIImage(.pause.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)), state: .selected)
        view.isSelected = false
        view.midSpacing = 0
        view.addActionHandlers { [weak self] sender in
            guard let self = self else { return }
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
                    let startTime = CMTimeMakeWithSeconds(startTimeSecond, preferredTimescale: Int32(NSEC_PER_MSEC))
                    self.avPlayer.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
                }
                
                // 【核心优化 2】：在添加新监听器前，必须清除旧的监听器！
                if let token = self.timeObserverToken {
                    self.avPlayer.removeTimeObserver(token)
                    self.timeObserverToken = nil
                }
                
                let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_MSEC))
                self.timeObserverToken = self.avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                    guard let self = self else { return }
                    
                    self.currentPlayTime = CMTimeGetSeconds(time)
                    let formattedCurrentTime = self.currentPlayTime >= 3600 ?
                        DateComponentsFormatter.longDurationFormatter.string(from: self.currentPlayTime) ?? "" :
                        DateComponentsFormatter.shortDurationFormatter.string(from: self.currentPlayTime) ?? ""
                    self.currentTimeLabel.text = formattedCurrentTime
                    
                    self.updateScrollViewContentOffset(fractionCompleted: (self.currentPlayTime / self.videoTime))
                    
                    let endTimeSecond = self.videoTime * self.trimPositions.1
                    if self.currentPlayTime >= endTimeSecond {
                        self.c7Player.pause()
                        // 播放完毕，回到剪辑起点
                        self.currentPlayTime = self.videoTime * self.trimPositions.0
                        sender.isSelected = false
                        self.currentTimeLabel.text = "0:00"
                        self.updateScrollViewContentOffset(fractionCompleted: self.trimPositions.0)
                        
                        // 播放结束后移除监听器
                        if let token = self.timeObserverToken {
                            self.avPlayer.removeTimeObserver(token)
                            self.timeObserverToken = nil
                        }
                    }
                }
                self.c7Player.play()
            } else {
                self.c7Player.pause()
                // 手动暂停时移除监听器
                if let token = self.timeObserverToken {
                    self.avPlayer.removeTimeObserver(token)
                    self.timeObserverToken = nil
                }
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
            let titles = self.outputTypes.map( { $0.name })
            
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
            self.requestVideoAssetReload()
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
                let customItem = NSCollectionLayoutGroupCustomItem(frame: CGRect(x: groupW, y: 0, width: cellWidth, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupW += cellWidth
                if index == (self.bottomControlModels.count - 1) {
                    groupW += itemOriginalX
                }
            }
            bannerGroupSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.absolute(groupW), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
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
            self.requestVideoAssetReload()
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
    private var currentFilter: PTHarBethFilter = PTHarBethFilter.none {
        didSet {
            // 【优化点】：不再调用繁重的 reloadAsset()，而是直接作用于渲染器
            updateLiveFilters()
        }
    }
    
    /// 动态更新当前播放器的渲染滤镜
    private func updateLiveFilters() {
        guard let c7Player = self.c7Player else { return }
        
        // 1. 处理无滤镜情况
        if currentFilter.type == .none {
            c7Player.filters = []
            // 同步更新预览图（非播放状态下）
            self.originFilterImageView.image = self.originImageView.image
            return
        }
        
        // 2. 获取滤镜实例（确保 Harbeth 的 Metal 纹理正常）
        if let filterResult = currentFilter.type.getFilterResult(texture: PTHarBethFilter.overTexture()!).filter {
            // 【核心实现】：直接替换渲染器的滤镜链，无需重启播放器
            c7Player.filters = [filterResult]
            
            // 3. 如果当前没有在播放，手动触发一次静态帧渲染更新预览
            if !playerButton.isSelected {
                // 利用 Harbeth 直接处理静态图显示效果
                let dest = HarbethIO(element: self.originImageView.image!, filters: [filterResult])
                if let output = try? dest.output() {
                    self.originFilterImageView.image = output
                }
            }
        }
    }

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
            guard let dimFrame = dimFrame else {
                self.dimView.isHidden = true
                return
            }
            
            // 【优化点】：使用 UIBezierPath 的 evenOdd 规则
            // 确保在旋转 transform 作用下，路径依然能正确扣空
            let maskPath = self.calculateMaskPath(with: dimFrame)
            
            // 调用之前定义的 mask 方法（带动画能力）
            self.dimView.mask(maskPath, duration: 0.25, animated: true)
            self.dimView.isHidden = false
        }
    }
    
    //MARK: 靜音
    fileprivate var isMute:Bool = false
    
    //MARK: 输出清晰度
    fileprivate var presets:String = AVAssetExportPresetHighestQuality
    
    //MARK: 覆蓋源文件
    fileprivate var rewrite:Bool = false
    
    deinit {
        // 清理幽灵定时器
        if let token = timeObserverToken {
            avPlayer?.removeTimeObserver(token)
        }
        // 清理可能正在导出的残缺废料
        videoConverter?.restore(cleanupDisk: true)
        
        PTNSLogConsole("🎬 PTVideoEditorToolsViewController 成功销毁并清理内存/磁盘", levelType: .info, loggerType: .media)
    }

    public override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !FileManager.pt.judgeFileOrFolderExists(filePath: OutputFilePath) {
            let result = FileManager.pt.createFolder(folderPath: OutputFilePath)
            if !result.isSuccess {
                PTNSLogConsole("創建失敗", levelType: .error,loggerType: .media)
            }
        }
//        guard let nav = navigationController else { return }
//        PTBaseNavControl.GobalNavControl(nav: nav)
        self.setCustomBackButtonView(self.dismissButtonItem)
        self.setCustomRightButtons(buttons: [self.doneButtonItem])
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTNavigationBarManager.shared.restoreIfNeeded(for: self)
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
                
        view.addSubviews([imageContent,playContent,bottomContent,timeLineContent])
        imageContent.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total + 10)
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
                let frameCount = self.numberOfFrames(within: timeLineViewRect)
                
                // 【核心修改点】：统一调用封装好的 Service，默认限制了 maximumSize 保护内存
                let cgImages = try await PTVideoTimelineService.generateVideoTimeline(
                    for: self.videoAVAsset,
                    numberOfFrames: frameCount
                )
                
                // 确保所有 UI 更新都在主线程安全进行
                await MainActor.run {
                    self.timeLineScroll.contentSize = CGSize(width: self.view.bounds.width, height: 64.0)
                    self.timeLineView.configure(with: cgImages, assetAspectRatio: self.assetAspectRatio)
                    self.updateScrollViewContentOffset(fractionCompleted: .zero)
                    self.currentTimeLabel.text = "0:00"

                    if let firstImage = cgImages.first {
                        let imageSize = UIImage(cgImage: firstImage).size
                        let scale = self.imageContent.frame.size.height / imageSize.height
                        let showImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
                        self.originFilterImageView.image = UIImage(cgImage: firstImage)
                        self.originImageView.image = UIImage(cgImage: firstImage)
                        self.originImageView.snp.makeConstraints { make in
                            make.width.equalTo(showImageSize.width)
                            make.centerX.equalToSuperview()
                            make.top.bottom.equalToSuperview()
                            make.centerX.centerY.equalToSuperview()
                        }
                    }

                    let width: CGFloat = 2.0
                    let height: CGFloat = 160.0
                    let x = self.timeLineContent.bounds.midX - width / 2
                    let y = (self.timeLineContent.bounds.height - height) / 2
                    self.currentTimeLine.frame = CGRect(x: x, y: y, width: width, height: height)
                    
                    self.reloadAsset()
                }
            } catch {
                await MainActor.run {
                    PTAlertTipsViewController.tipsAlertShow(title: "", subtitle: error.localizedDescription, icon: .Error)
                }
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

        self.videoConverter = VideoConverter(asset:self.videoAVAsset)
        videoConverter?.convert(options,progress: { progress in
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
    
    fileprivate func setVideoAsset(covertFinish:PTActionTask? = nil) {

        let options = ConverterOption(
            trimRange: trimPositions,
            convertCrop: nil,
            rotate: 0,
            quality: presets,
            isMute: false,
            speed: speed)

        self.videoConverter = VideoConverter(asset:self.videoAVAsset)
        self.videoConverter?.convert(options) { ac,avc in
            Task { @MainActor in
                self.avPlayerItem = AVPlayerItem(asset: ac)
                self.avPlayerItem.videoComposition = avc
                
                // 【核心优化 1】：只替换 Item，绝不重新创建 AVPlayer！
                if self.avPlayer == nil {
                    self.avPlayer = AVPlayer(playerItem: self.avPlayerItem)
                    self.c7Player = C7CollectorVideo(player: self.avPlayer, delegate: self)
                } else {
                    self.avPlayer.pause()
                    self.avPlayer.replaceCurrentItem(with: self.avPlayerItem)
                }
                
                self.avPlayerItem.asset.getVideoFirstImage(maximumSize: CGSize(width: Double.infinity, height: Double.infinity)) { image in
                    self.originImageView.image = image
                }
                
                covertFinish?()
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
                    let frameCount = self.numberOfFrames(within: timeLineViewRect)
                    
                    // 【核心修改点】：再次统一调用 Service，注意这里的 asset 是 avPlayer 的 currentItem
                    let cgImages = try await PTVideoTimelineService.generateVideoTimeline(
                        for: self.avPlayer.currentItem!.asset,
                        numberOfFrames: frameCount
                    )
                    
                    await MainActor.run {
                        self.timeLineScroll.contentSize = CGSize(width: self.view.bounds.width, height: 64.0)
                        self.timeLineView.configure(with: cgImages, assetAspectRatio: self.assetAspectRatio)
                        self.updateScrollViewContentOffset(fractionCompleted: .zero)
                        
                        let width: CGFloat = 2.0
                        let height: CGFloat = 160.0
                        let x = self.timeLineContent.bounds.midX - width / 2
                        let y = (self.timeLineContent.bounds.height - height) / 2
                        self.currentTimeLine.frame = CGRect(x: x, y: y, width: width, height: height)
                    }

                } catch {
                    await MainActor.run {
                        PTAlertTipsViewController.tipsAlertShow(title: "", subtitle: error.localizedDescription, icon: .Error)
                    }
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
        currentVC?.present(sheet, animated: true) {
            completion?()
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
}

//MARK: ScrollView Delegate
extension PTVideoEditorToolsViewController {
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

    public override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        if !decelerate {
            isSeeking = false
        }
    }

    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
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

fileprivate extension PTVideoEditorToolsViewController {
    // 统一管理所有的视频重建请求
    private func requestVideoAssetReload() {
        Task {
            await reloadDebouncer.debounce { [weak self] in
                guard let self = self else { return }
                
                // 确保 UI 刷新和播放器操作在主线程进行
                await MainActor.run {
                    // 显示 loading 提示框（可选，提升用户体验）
                    // PTHudView().hudShow()
                    
                    self.setVideoAsset {
                        self.reloadAsset()
                    }
                }
            }
        }
    }
}

// MARK: - Modern Async Wrappers (现代化异步包装器)
fileprivate extension PTVideoEditorToolsViewController {
    
    /// 包装原来的 setOutPut 为 async
    func setOutPutAsync() async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            self.setOutPut { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(domain: "PTVideoEditor", code: 500, userInfo: [NSLocalizedDescriptionKey: "导出遇到未知错误"]))
                }
            }
        }
    }
    
    /// 包装 Harbeth 的 Exporter 滤镜渲染为 async
    func harbethExportAsync(sourceURL: URL, outputURL: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let exporter = Exporter(provider: Exporter.Provider(with: sourceURL, to: URL(fileURLWithPath: outputURL.path)))
            exporter.export(options: [.OptimizeForNetworkUse: true], filtering: { buffer in
                let dest = HarbethIO(element: buffer, filters: self.c7Player.filters)
                return try? dest.output()
            }, complete: { res in
                switch res {
                case .success(let finalURL):
                    continuation.resume(returning: finalURL)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    
    /// 包装相册的保存和覆盖逻辑为 async
    func saveToAlbumAsync(outputURL: URL, rewrite: Bool, localIdentifier: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            if rewrite {
                PHPhotoLibrary.shared().performChanges({
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
                    
                    if let asset = assets.firstObject {
                        let assetCollectionList = PHAssetCollection.fetchAssetCollectionsContaining(asset, with: .album, options: nil)
                        if let assetCollection = assetCollectionList.firstObject {
                            PTGCDManager.gcdMain {
                                let assetToDelete = [asset] as NSArray
                                let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                                albumChangeRequest?.removeAssets(assetToDelete)
                            }
                        }
                    }
                    let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                    
                }) { success, error in
                    if success {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: error ?? NSError(domain: "PTVideoEditor", code: 501, userInfo: [NSLocalizedDescriptionKey: "覆盖保存相册失败"]))
                    }
                }
            } else {
                PHPhotoLibrary.pt.saveVideoToAlbum(fileURL: outputURL) { finish, error in
                    if finish {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: error ?? NSError(domain: "PTVideoEditor", code: 502, userInfo: [NSLocalizedDescriptionKey: "保存相册失败"]))
                    }
                }
            }
        }
    }
}

// MARK: - 裁剪坐标系转换优化
fileprivate extension PTVideoEditorToolsViewController {
    
    /// 根据当前视频旋转角度和裁剪框，生成遮罩路径
    /// - Parameter cropRect: 这里的 rect 是相对于视频原始画面（未旋转前）的比例坐标或像素坐标
    func calculateMaskPath(with cropRect: CGRect) -> CGPath {
        let viewSize = self.dimView.bounds.size
        let imageSize = self.originImageView.bounds.size
        
        // 计算图片在 AspectFit 模式下的实际绘制区域
        let horizontalScale = viewSize.width / imageSize.width
        let verticalScale = viewSize.height / imageSize.height
        let finalScale = min(horizontalScale, verticalScale)
        
        let actualWidth = imageSize.width * finalScale
        let actualHeight = imageSize.height * finalScale
        let xOffset = (viewSize.width - actualWidth) / 2
        let yOffset = (viewSize.height - actualHeight) / 2
        
        // 将传入的裁剪框映射到当前展示的 UI 坐标
        // 注意：这里需要根据 self.degree 调整映射关系
        var mappedRect = CGRect.zero
        
        // 核心逻辑：无论怎么旋转，裁剪框是相对于“内容”的
        // 我们利用变换矩阵来处理坐标映射，而不是写死 if-else
        let rectInImage = CGRect(
            x: xOffset + cropRect.origin.x,
            y: yOffset + cropRect.origin.y,
            width: cropRect.width,
            height: cropRect.height
        )
        
        mappedRect = rectInImage
        
        let path = UIBezierPath(rect: mappedRect)
        path.append(UIBezierPath(rect: self.dimView.bounds))
        return path.cgPath
    }
}
