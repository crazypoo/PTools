//
//  PTFuncNameViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import DeviceKit
import AnyImageKit
import Photos
import Combine

public extension String {
    static let localNetWork = "局域网传送"
    
    static let imageReview = "图片展示"
    static let videoEditor = "视频编辑"
    static let sign = "签名"
    static let dymanicCode = "动态验证码"
    static let osskit = "语音"
    static let vision = "看图识字"

    static let phoneSimpleInfo = "手机信息"
    static let phoneCall = "打电话"
    static let cleanCache = "清理缓存"
    static let touchID = "TouchID"
    static let rotation = "旋转屏幕"

    static let slider = "滑动条"
    static let rate = "评价星星"
    static let segment = "分选栏目"
    static let countLabel = "跳动Label"
    static let throughLabel = "划线Label"
}

class PTFuncNameViewController: PTBaseViewController {

    fileprivate lazy var outputURL :URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDirectory.appendingPathComponent("output.mp4")
        return outputURL
    }()

    private var videoEdit: PTVideoEdit?
    fileprivate var cancellables = Set<AnyCancellable>()

    let disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 12))
    
    lazy var cSections : [PTSection] = {
        /**
            网络
         */
        let localNet = PTFusionCellModel()
        localNet.name = .localNetWork
        localNet.accessoryType = .DisclosureIndicator
        localNet.disclosureIndicatorImage = self.disclosureIndicatorImage
        
        let netArrs = [localNet]
        
        var netRows = [PTRows]()
        netArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            netRows.append(row)
        }
        
        let netSection = PTSection.init(headerTitle: "网络",headerCls: PTTestHeader.self,headerID: PTTestHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: netRows)
        
        /**
            图片
         */
        let imageReview = PTFusionCellModel()
        imageReview.name = .imageReview
        imageReview.accessoryType = .DisclosureIndicator
        imageReview.disclosureIndicatorImage = self.disclosureIndicatorImage
        
        let videoEditor = PTFusionCellModel()
        videoEditor.name = .videoEditor
        videoEditor.accessoryType = .DisclosureIndicator
        videoEditor.disclosureIndicatorImage = self.disclosureIndicatorImage

        let sign = PTFusionCellModel()
        sign.name = .sign
        sign.accessoryType = .DisclosureIndicator
        sign.disclosureIndicatorImage = self.disclosureIndicatorImage

        let dymanicCode = PTFusionCellModel()
        dymanicCode.name = .dymanicCode
        dymanicCode.accessoryType = .DisclosureIndicator
        dymanicCode.disclosureIndicatorImage = self.disclosureIndicatorImage

        let oss = PTFusionCellModel()
        oss.name = .osskit
        oss.accessoryType = .DisclosureIndicator
        oss.disclosureIndicatorImage = self.disclosureIndicatorImage

        let vision = PTFusionCellModel()
        vision.name = .vision
        vision.accessoryType = .DisclosureIndicator
        vision.disclosureIndicatorImage = self.disclosureIndicatorImage
        
        let mediaArrs = [imageReview,videoEditor,sign,dymanicCode,oss,vision]
        
        var mediaRows = [PTRows]()
        mediaArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            mediaRows.append(row)
        }
        
        let mediaSection = PTSection.init(headerTitle: "多媒体",headerCls: PTTestHeader.self,headerID: PTTestHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: mediaRows)

        /**
            本机
         */
        let jailBroken = PTFusionCellModel()
        jailBroken.name = .phoneSimpleInfo
        jailBroken.cellDescFont = .appfont(size: 12)
        jailBroken.desc = "是否X类型:\(UIDevice.pt.oneOfXDevice() ? "是" : "否"),是否越狱了:\(UIDevice.pt.isJailBroken ? "是" : "否"),机型:\(Device.identifier),运营商:\(String(describing: UIDevice.pt.carrierNames()?.first))"
        jailBroken.accessoryType = .NoneAccessoryView
        
        let callPhone = PTFusionCellModel()
        callPhone.name = .phoneCall
        callPhone.cellDescFont = .appfont(size: 12)
        callPhone.desc = "打电话到13800138000"
        callPhone.accessoryType = .DisclosureIndicator
        callPhone.disclosureIndicatorImage = self.disclosureIndicatorImage

        let cleanCaches = PTFusionCellModel()
        cleanCaches.name = .cleanCache
        cleanCaches.cellDescFont = .appfont(size: 12)
        cleanCaches.desc = "缓存:\(String(format: "%@", PCleanCache.getCacheSize()))"
        cleanCaches.accessoryType = .DisclosureIndicator
        cleanCaches.disclosureIndicatorImage = self.disclosureIndicatorImage

        let touchID = PTFusionCellModel()
        touchID.name = .touchID
        touchID.accessoryType = .DisclosureIndicator
        touchID.disclosureIndicatorImage = self.disclosureIndicatorImage

        let rotation = PTFusionCellModel()
        rotation.name = .rotation
        rotation.accessoryType = .DisclosureIndicator
        rotation.disclosureIndicatorImage = self.disclosureIndicatorImage

        let phoneArrs = [jailBroken,callPhone,cleanCaches,touchID,rotation]
        
        var phoneRows = [PTRows]()
        phoneArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            phoneRows.append(row)
        }
        
        let phoneSection = PTSection.init(headerTitle: "本机",headerCls: PTTestHeader.self,headerID: PTTestHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: phoneRows)
        
        /**
            UIKIT
         */
        let slider = PTFusionCellModel()
        slider.name = .slider
        slider.accessoryType = .DisclosureIndicator
        slider.disclosureIndicatorImage = self.disclosureIndicatorImage
        
        let rate = PTFusionCellModel()
        rate.name = .rate
        rate.accessoryType = .DisclosureIndicator
        rate.disclosureIndicatorImage = self.disclosureIndicatorImage

        let segment = PTFusionCellModel()
        segment.name = .segment
        segment.accessoryType = .DisclosureIndicator
        segment.disclosureIndicatorImage = self.disclosureIndicatorImage

        let countLabel = PTFusionCellModel()
        countLabel.name = .countLabel
        countLabel.accessoryType = .DisclosureIndicator
        countLabel.disclosureIndicatorImage = self.disclosureIndicatorImage
        
        let throughLabel = PTFusionCellModel()
        throughLabel.name = .throughLabel
        throughLabel.accessoryType = .DisclosureIndicator
        throughLabel.disclosureIndicatorImage = self.disclosureIndicatorImage
        
        let uikitArrs = [slider,rate,segment,countLabel,throughLabel]
        
        var uikitRows = [PTRows]()
        uikitArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            uikitRows.append(row)
        }
        
        let uikitSection = PTSection.init(headerTitle: "UIKIT",headerCls: PTTestHeader.self,headerID: PTTestHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: uikitRows)

        return [netSection,mediaSection,phoneSection,uikitSection]
    }()
    
    lazy var collectionView : PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Normal
        cConfig.itemHeight = PTAppBaseConfig.share.baseCellHeight
        cConfig.topRefresh = true
        if #available(iOS 17.0, *) {
        } else {
//            cConfig.showEmptyAlert = true
        }
        let aaaaaaa = PTCollectionView(viewConfig: cConfig)
                
        aaaaaaa.headerInCollection = { kind,collectionView,model,index in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as! PTTestHeader
            header.backgroundColor = .blue
            return header
        }
        aaaaaaa.footerInCollection = { kind,collectionView,model,index in
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.footerID!, for: index) as! PTTestFooter
            footer.backgroundColor = .red
            return footer
        }
        aaaaaaa.cellInCollection = { collectionView ,dataModel,indexPath in
            let itemRow = dataModel.rows[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
            return cell
        }
        aaaaaaa.collectionDidSelect = { collectionViews,sModel,indexPath in
            let itemRow = sModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTFusionCellModel)
            if itemRow.title == .imageReview {
                let model1 = PTMediaBrowserModel()
                model1.imageURL = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
                model1.imageInfo = "56555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555551312333444444"
                
                let model2 = PTMediaBrowserModel()
                model2.imageURL = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
                model2.imageInfo = "123"

                let model3 = PTMediaBrowserModel()
                model3.imageURL = "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
                model3.imageInfo = "MP4"

                let model4 = PTMediaBrowserModel()
                model4.imageURL = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"
                model4.imageInfo = "GIF"

                let mediaConfig = PTMediaBrowserConfig()
                mediaConfig.actionType = .All
                mediaConfig.mediaData = [model1,model2,model3,model4]
                
                let browser = PTMediaBrowserController()
                browser.viewConfig = mediaConfig
                browser.modalPresentationStyle = .fullScreen
                self.present(browser, animated: true)
            } else if itemRow.title == .phoneCall {
                PTPhoneBlock.callPhoneNumber(phoneNumber: "13800138000", call: { duration in
                }, cancel: {
                    
                }, canCall: { finish in
                    
                })
            } else if itemRow.title == .cleanCache {
                if PCleanCache.clearCaches() {
                    UIAlertController.gobal_drop(title: "清理成功")
                    self.showCollectionViewData()
                } else {
                    UIAlertController.gobal_drop(title: "暂时没有缓存了")
                }
            } else if itemRow.title == .touchID {
                let touchID = PTBiologyID.shared
                touchID.biologyStatusBlock = { type in
                    PTNSLogConsole("\(type)")
                }
                touchID.biologyVerifyStatusBlock = { type in
                    PTNSLogConsole("\(type)")
                }
                touchID.biologyStart(alertTitle: "Test")
            } else if itemRow.title == .videoEditor {
                var options = PickerOptionsInfo()
                options.selectLimit = 1
                options.selectOptions = .video
                
                let controller = ImagePickerController(options: options, delegate: self)
                controller.trackDelegate = self
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: true, completion: nil)
            } else if itemRow.title == .sign {
                let signConfig = PTSignatureConfig()
                
                let sign = PTSignView(viewConfig: signConfig)
                sign.showView()
                sign.doneBlock = { image in
                    let newImage = UIImageView(image: image)
                    self.view.addSubview(newImage)
                    newImage.snp.makeConstraints { make in
                        make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                        make.top.equalTo(self.collectionView)
                        make.height.equalTo(150)
                    }
                    
                    PTGCDManager.gcdAfter(time: 5) {
                        newImage.removeFromSuperview()
                    }
                }
                sign.dismissBlock = {
                    
                }
            } else if itemRow.title == .rotation {
                let r:Int = Int(arc4random_uniform(6))
                PTRotationManager.share.setOrientation(orientation: UIDeviceOrientation.init(rawValue: r)!)
            } else if itemRow.title == .osskit {
                let vc = PTSpeechViewController()
                self.navigationController?.pushViewController(vc)
            } else {
                let vc = PTFuncDetailViewController(typeString: itemRow.title)
                PTFloatingPanelFuction.floatPanel_VC(vc: vc,panGesDelegate: self,currentViewController: self)
            }
        }
        aaaaaaa.headerRefreshTask = { sender in
            PTGCDManager.gcdAfter(time: 3) {
                sender.endRefreshing()
            }
        }
        return aaaaaaa
    }()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.flashAd(notifi:)), name: NSNotification.Name.init(PLaunchAdDetailDisplayNotification), object: nil)
        
        let more = UIButton(type: .custom)
        more.setTitleColor(.random, for: .normal)
        more.setTitle("More", for: .normal)
        more.bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubviews([more])
        more.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            more.size.equalTo(more.bounds.size)
            make.bottom.equalToSuperview().inset(5)
        }
#else
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: more)
#endif
        let popoverContent = PTBaseViewController(hideBaseNavBar: true)
        
        let popoverButton = UIButton(type: .custom)
        popoverButton.backgroundColor = .random
        
        popoverContent.view.addSubview(popoverButton)
        popoverButton.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.centerY.centerX.equalToSuperview()
        }
        popoverButton.addActionHandlers { sender in
            popoverContent.dismiss(animated: true) {
                let infoVc = PTSwiftViewController()
                self.navigationController?.pushViewController(infoVc)
            }
        }
        
        more.addActionHandlers { sender in
            self.popover(popoverVC: popoverContent, popoverSize: CGSize(width: 100, height: 300), sender: sender, arrowDirections: .any)
        }
        
        
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
            make.top.equalToSuperview()
#endif
            make.left.right.bottom.equalToSuperview()
        }
        
        if #available(iOS 17.0, *) {
            self.emptyDataViewConfig = PTEmptyDataViewConfig()
            self.showEmptyView {
                self.emptyReload()
            }
            
            PTGCDManager.gcdAfter(time: 5) {
                self.emptyReload()
            }
        } else {
            self.showCollectionViewData()
        }
    }
    
    func flashAd(notifi:Notification) {
        PTNSLogConsole("启动广告")
    }
    
    @available(iOS 17, *)
    func emptyReload() {
        self.emptyViewLoading()
        PTGCDManager.gcdAfter(time: 2) {
            self.hideEmptyView {
                self.showCollectionViewData()
            }
        }
    }
    
    func showCollectionViewData() {
        collectionView.showCollectionDetail(collectionData: cSections)
    }
}

// MARK: - ImagePickerControllerDelegate
extension PTFuncNameViewController: ImagePickerControllerDelegate {
    
    // 获取PHAsset并转换为AVAsset的方法
    func convertPHAssetToAVAsset(phAsset: PHAsset, completion: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original

        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, _ in
            completion(avAsset)
        }
    }
        
    func saveVideoToCache(playerItem: AVPlayerItem,result:((_ finish:Bool)->Void)? = nil) {
        let videoAsset = playerItem.asset
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = .mp4

        guard let exportSession = exportSession else {
            PTNSLogConsole("无法创建AVAssetExportSession")
            return
        }

        exportSession.outputURL = outputURL
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                PTNSLogConsole("视频保存到本地成功")
                if result != nil {
                    result!(true)
                }
            case .failed:
                PTNSLogConsole("视频导出失败：\(exportSession.error?.localizedDescription ?? "")")
                if result != nil {
                    result!(false)
                }
            default:
                break
            }
        }
    }
    
    func saveVideoToAlbum(result:((_ finish:Bool)->Void)? = nil) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputURL)
        }) { success, error in
            if success {
                PTNSLogConsole("视频保存成功")
                if result != nil {
                    result!(true)
                }
            } else {
                PTNSLogConsole("视频保存失败：\(error?.localizedDescription ?? "")")
                if result != nil {
                    result!(false)
                }
            }
        }
    }

    func imagePicker(_ picker: ImagePickerController, didFinishPicking result: PickerResult) {
        PTNSLogConsole(result.assets.first!.image)
        
        picker.dismiss(animated: true, completion: nil)

        convertPHAssetToAVAsset(phAsset: result.assets.first!.phAsset) { avAsset in
            if let avAsset = avAsset {
                PTGCDManager.gcdMain {
                    let controller = PTVideoEditorVideoEditorViewController(asset: avAsset, videoEdit: self.videoEdit)
                    controller.onEditCompleted
                        .sink {  editedPlayerItem, videoEdit in
                            self.videoEdit = videoEdit
                            
                            self.saveVideoToCache(playerItem: editedPlayerItem) { finish in
                                if finish {
                                    UIImage.pt.getVideoFirstImage(videoUrl: self.outputURL.description) { images in
                                        PTNSLogConsole(images as Any)
                                    }
                                }
                            }
                        }
                        .store(in: &self.cancellables)
                    controller.modalPresentationStyle = .fullScreen
                    let nav = PTBaseNavControl(rootViewController: controller)
                    self.navigationController?.present(nav, animated: true)
                }
            } else {
                UIViewController.gobal_drop(title: "获取失败,请重试")
            }
        }
    }
}

// MARK: - ImageKitDataTrackDelegate
extension PTFuncNameViewController: ImageKitDataTrackDelegate {
    
    func dataTrack(page: AnyImagePage, state: AnyImagePageState) {
        switch state {
        case .enter:
            PTNSLogConsole("[Data Track] ENTER Page: \(page.rawValue)")
        case .leave:
            PTNSLogConsole("[Data Track] LEAVE Page: \(page.rawValue)")
        }
    }
    
    func dataTrack(event: AnyImageEvent, userInfo: [AnyImageEventUserInfoKey: Any]) {
        PTNSLogConsole("[Data Track] EVENT: \(event.rawValue), userInfo: \(userInfo)")
    }
}
