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

@objcMembers
class PTVideoEditorToolsViewController: PTBaseViewController {

    lazy var dismissButtonItem:UIButton = {
        let image = "❌".emojiToImage(emojiFont: .appfont(size: 20))
        let buttonItem = UIButton(type: .custom)
        buttonItem.setImage(image, for: .normal)
        buttonItem.addActionHandlers { sender in
            self.returnFrontVC()
        }
        return buttonItem
    }()
    
    lazy var doneButtonItem:UIButton = {
        let image = "✅".emojiToImage(emojiFont: .appfont(size: 20))
        let buttonItem = UIButton(type: .custom)
        buttonItem.setImage(image, for: .normal)
        buttonItem.addActionHandlers { sender in
            self.c7Player.pause()
            
            self.getURLForPHAsset(asset: self.videoAsset) { url in
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
                            let asset = AVURLAsset(url: outputURL, options: [
                                AVURLAssetPreferPreciseDurationAndTimingKey: true
                            ])
                            let playerItem = AVPlayerItem(asset: asset)
                            PTNSLogConsole("输出:\(playerItem)")
                            PTAlertTipControl.present(title:"",subtitle:outputURL.description,icon: .Done,style: .Normal)
                        case .failure(let error):
                            PTAlertTipControl.present(title:"",subtitle:error.localizedDescription,icon: .Error,style: .Normal)
                        }
                    })
                } else {
                    PTAlertTipControl.present(title:"",subtitle:"空视频地址",icon: .Error,style: .Normal)
                }
            }
        }
        return buttonItem
    }()
    
    fileprivate var videoAsset:PHAsset!
    fileprivate var videoAVAsset:AVAsset!
    var c7Player:C7CollectorVideo!
    lazy var originImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
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
        view.setImage(UIImage(.play.fill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)), for: .normal)
        view.setImage(UIImage(.pause.fill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)), for: .selected)
        view.isSelected = false
        view.addActionHandlers { sender in
            sender.isSelected = !sender.isSelected
            if sender.isSelected {
                
                if self.videoTime > self.currentPlayTime {
                    let cmTime = CMTimeMakeWithSeconds(self.currentPlayTime, preferredTimescale: Int32(NSEC_PER_SEC))
                    self.avPlayer.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
                } else {
                    self.avPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                }
                let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                let timeObserverToken = self.avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { time in
                    // 在这里处理播放时间的更新
                    PTGCDManager.gcdMain {
                        self.currentPlayTime = CMTimeGetSeconds(time)
                        let formattedCurrentTime = self.currentPlayTime >= 3600 ?
                            DateComponentsFormatter.longDurationFormatter.string(from: self.currentPlayTime) ?? "" :
                            DateComponentsFormatter.shortDurationFormatter.string(from: self.currentPlayTime) ?? ""
                        self.currentTimeLabel.text = formattedCurrentTime
                        
                        self.updateScrollViewContentOffset(fractionCompleted: (self.currentPlayTime / self.videoTime))
                        
                        if self.currentPlayTime >= CMTimeGetSeconds(CMTime(seconds: self.videoTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))) {
                            self.c7Player.pause()
                            sender.isSelected = false
                            self.currentTimeLabel.text = "0:00"
                            
                            self.updateScrollViewContentOffset(fractionCompleted: .zero)
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
    var isSeeking: Bool = false {
        didSet {
            if isSeeking {
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
    
    lazy var bottomControlModels:[PTVideoEditorVideoControlCellViewModel] = {
        let speedModel = PTVideoEditorVideoControlCellViewModel(videoControl: .speed)
        let trimModel = PTVideoEditorVideoControlCellViewModel(videoControl: .trim)
        let cropModel = PTVideoEditorVideoControlCellViewModel(videoControl: .crop)
        return [speedModel,trimModel,cropModel]
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
            let cellModel = itemRow.dataModel as! PTVideoEditorVideoControlCellViewModel
            let cell = collectionViews.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTVideoEditorVideoControlCell
            cell.configure(with: cellModel)
            return cell
        }
        view.collectionDidSelect = { collectionViews,sectionModel,indexPath in
            let itemRow = sectionModel.rows[indexPath.row]
            let cellModel = itemRow.dataModel as! PTVideoEditorVideoControlCellViewModel
            switch cellModel.videoControl {
            case .speed:
                let vc = PTVideoEditorToolsSpeedControl(speed: 1)
                vc.speedHandler = { value in
                }
                self.sheetPresent_floating(modalViewController:vc,type:.custom, scale:0.3,panGesDelegate:self,completion:{
                    
                },dismissCompletion:{
                    
                })
            case .trim:
                let vc = PTVideoEditorToolsTrimControl(trimPositions: (0.0,1.0), asset: self.videoAVAsset)
                self.sheetPresent_floating(modalViewController:vc,type:.custom, scale:0.3,panGesDelegate:self,completion:{
                    
                },dismissCompletion:{
                    
                })
                vc.trimPosotionsHandler = { value in
                }
            case .crop:
                break
            }
        }
        return view
    }()

    override func viewWillAppear(_ animated: Bool) {
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
    
    override func viewDidLoad() {
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
        
        view.addSubviews([originImageView,playContent,bottomContent,timeLineContent])
        originImageView.snp.makeConstraints { make in
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total + 10)
#else
            make.top.equalToSuperview().inset(10)
#endif
            make.left.right.equalToSuperview().inset(64)
            make.height.equalTo(self.originImageView.snp.width)
        }
        
        playContent.snp.makeConstraints { make in
            make.top.equalTo(self.originImageView.snp.bottom).offset(7.5)
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
            
            UIImage.pt.getVideoFirstImage(asset: self.videoAVAsset) { image in
                self.originImageView.image = image
            }
            
            self.avPlayerItem = AVPlayerItem(asset: self.videoAVAsset)
            self.avPlayer = AVPlayer(playerItem: self.avPlayerItem)
            self.c7Player = C7CollectorVideo(player: self.avPlayer, delegate: self)
             
            PTHarBethFilter.share.texureSize = self.originImageView.frame.size
//            self.c7Player.filters = [PTHarBethFilter.crosshatch.type.getFilterResult(texture: PTHarBethFilter.overTexture()!).filter!]
                        
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
            let row = PTRows(cls: PTVideoEditorVideoControlCell.self,ID:PTVideoEditorVideoControlCell.ID,dataModel: value)
            rows.append(row)
        }
        
        let sections = [PTSection(rows: rows)]
        bottomControlCollection.showCollectionDetail(collectionData: sections) { cView in
            PTNSLogConsole("12312312312312312")
        }
    }
    
    public func videoEditorShow(vc:UIViewController) {
        let nav = PTBaseNavControl(rootViewController: self)
        nav.modalPresentationStyle = .fullScreen
        vc.present(nav, animated: true)
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
    func preview(_ collector: C7Collector, fliter image: C7Image) {
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

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isSeeking = true
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isSeeking = false
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isSeeking = false
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
