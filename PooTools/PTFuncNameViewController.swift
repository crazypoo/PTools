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
import Photos
import Combine
import SafeSFSymbols
import AttributedString

public extension String {
    static let localNetWork = "局域网传送"
    
    static let imageReview = "图片展示"
    static let videoEditor = "视频编辑"
    static let sign = "签名"
    static let dymanicCode = "动态验证码"
    static let osskit = "语音"
    static let vision = "看图识字"
    static let mediaSelect = "媒體選擇"

    static let phoneSimpleInfo = "手机信息"
    static let phoneCall = "打电话"
    static let cleanCache = "清理缓存"
    static let touchID = "TouchID"
    static let rotation = "旋转屏幕"
    static let share = "分享"
    static let checkUpdate = "检测更新"
    static let language = "語言"
    static let darkMode = "DarkMode"

    static let slider = "滑动条"
    static let rate = "评价星星"
    static let segment = "分选栏目"
    static let countLabel = "跳动Label"
    static let throughLabel = "划线Label"
    static let twitterLabel = "推文Label"
    static let movieCutOutput = "类似剪映的视频输出进度效果"
    static let progressBar = "进度条"
    static let alert = "Alert"
    static let feedbackAlert = "反馈弹框"
    static let menu = "Menu"
    static let loading = "Loading"
    static let permission = "Permission"
    static let permissionSetting = "Permission Setting"
    static let tipkit = "TipKit"
    static let document = "UIDocument"
    static let svga = "SVGA"
    static let swipe = "Swipe"
    static let scanQR = "ScanQRCode"
    static let filtercamera = "FilterCamera"
    static let editimage = "EditImage"
    static let sortButton = "SortButton"
    static let messageKit = "MessageKit"
    static let BlurImageList = "BlurImageList"
    static let CycleBanner = "CycleBanner"
    static let CollectionTag = "CollectionTag"
    static let InputBox = "InputBox"
    static let Stepper = "Stepper"
    static let LoginDesc = "LoginDesc"
    static let StepperList = "StepperList"
    static let LivePhoto = "LivePhoto"
    static let LivePhotoDisassemble = "LivePhotoDisassemble"

    static let route = "路由"
    
    static let encryption = "Encryption"
}

class YDSWhiteDecorationView: UICollectionReusableView {
    public static let ID = "YDSWhiteDecorationView"
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .random
        PTGCDManager.gcdMain {
            self.viewCornerRectCorner(cornerRadii: 8,corner: [.allCorners])
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PTFuncNameViewController: PTBaseViewController {

    var cacheSize = ""
    
    lazy var currentSelectedLanguage : String = {
        let string = LanguageKey(rawValue: PTLanguage.share.language)!.desc
        return string
    }()

    enum LanguageKey : String {
        case ChineseHans = "zh-Hans"
        case ChineseHK = "zh-HK"
        case English = "en"
        case Spanish = "es"
        
        static var allValues : [LanguageKey] {
            [.ChineseHans, .ChineseHK, .English, .Spanish]
        }
        
        var desc:String {
            switch self {
            case .ChineseHans:
                return "中文(简体)"
            case .ChineseHK:
                return "中文(繁体)"
            case .English:
                return "English"
            case .Spanish:
                return "Español"
            }
        }
        
        static var allNames : [String] {
            var values = [String]()
            allValues.enumerated().forEach { index,value in
                values.append(value.desc)
            }
            return values
        }
    }

    fileprivate var vcEmpty:Bool = false
    
    fileprivate lazy var outputURL :URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDirectory.appendingPathComponent("\(Date().getTimeStamp()).mp4")
        return outputURL
    }()

//    private var videoEdit: PTVideoEdit?
//    fileprivate var cancellables = Set<AnyCancellable>()

    func rowBaseModel(name:String) -> PTFusionCellModel {
        let models = PTFusionCellModel()
        models.name = name
        models.haveLine = .Normal
        models.accessoryType = .DisclosureIndicator
        models.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 12))
        return models
    }
    
    func cSections() -> [PTSection] {
        let disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 12))
        let sectionTitleFont:UIFont = .appfont(size: 18,bold: true)
        /**
            网络
         */
        let localNet = self.rowBaseModel(name: .localNetWork)
        localNet.leftImage = "🌐".emojiToImage(emojiFont: .appfont(size: 24))
        localNet.contentIcon = "🌠".emojiToImage(emojiFont: .appfont(size: 24))
        localNet.content = "12312312312312312312312312312312312312312312321"
        localNet.cellClass = PTFusionCell.self
        localNet.cellID = PTFusionCell.ID
        let netArrs = [localNet]
                
        let sectionModel_net = PTFusionCellModel()
        sectionModel_net.name = "网络"
        sectionModel_net.cellFont = sectionTitleFont
        sectionModel_net.accessoryType = .More
        sectionModel_net.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_net.moreLayoutStyle = .leftTitleRightImage
        sectionModel_net.moreDisclosureIndicator = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"

        let netSection = PTSection.init(headerTitle: sectionModel_net.name,headerID: PTFusionHeader.ID,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: UICollectionView.sectionRows(rowsModel: netArrs),headerDataModel: sectionModel_net)
        
        /**
            图片
         */
        let imageReview = self.rowBaseModel(name: .imageReview)
        
        let videoEditor = self.rowBaseModel(name: .videoEditor)

        let sign = self.rowBaseModel(name: .sign)

        let dymanicCode = self.rowBaseModel(name: .dymanicCode)

        let oss = self.rowBaseModel(name: .osskit)

        let vision = self.rowBaseModel(name: .vision)
        
        let mediaSelect = self.rowBaseModel(name: .mediaSelect)
        
        let mediaArrs = [imageReview,videoEditor,sign,dymanicCode,oss,vision,mediaSelect]
        
        var mediaRows = [PTRows]()
        mediaArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,ID: PTFusionCell.ID,dataModel: value)
            mediaRows.append(row)
        }
        
        let sectionModel_media = PTFusionCellModel()
        sectionModel_media.name = "多媒体"
        sectionModel_media.cellFont = sectionTitleFont
        sectionModel_media.accessoryType = .Switch
        sectionModel_media.switchControlWidth = 25

        let mediaSection = PTSection.init(headerTitle: sectionModel_media.name,headerID: PTFusionHeader.ID,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: mediaRows,headerDataModel: sectionModel_media)

        /**
            本机
         */
        let jailBroken = PTFusionCellModel()
        jailBroken.name = .phoneSimpleInfo
        jailBroken.cellDescFont = .appfont(size: 12)
        jailBroken.desc = "是否X类型:\(UIDevice.pt.oneOfXDevice() ? "是" : "否"),是否越狱了:\(UIDevice.pt.isJailBroken ? "是" : "否"),机型:\(Device.identifier),运营商:\(String(describing: UIDevice.pt.carrierNames()?.first))"
        jailBroken.accessoryType = .NoneAccessoryView
        
        let callPhone = self.rowBaseModel(name: .phoneCall)
        callPhone.cellDescFont = .appfont(size: 12)
        callPhone.desc = "打电话到13800138000"

        let cleanCaches = self.rowBaseModel(name: .cleanCache)
        cleanCaches.cellDescFont = .appfont(size: 12)
        cleanCaches.desc = "缓存:\(String(format: "%@", cacheSize))"
        
        let touchID = self.rowBaseModel(name: .touchID)

        let rotation = self.rowBaseModel(name: .rotation)

        let share = self.rowBaseModel(name: .share)

        let checkUpdate = self.rowBaseModel(name: .checkUpdate)
        
        let language = self.rowBaseModel(name: .language)
        
        let darkMode = self.rowBaseModel(name: .darkMode)
        
        let phoneArrs = [jailBroken,callPhone,cleanCaches,touchID,rotation,share,checkUpdate,language,darkMode]
        
        var phoneRows = [PTRows]()
        phoneArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,ID: PTFusionCell.ID,dataModel: value)
            phoneRows.append(row)
        }
        
        let sectionModel_phone = PTFusionCellModel()
        sectionModel_phone.name = "本机"
        sectionModel_phone.cellFont = sectionTitleFont
        sectionModel_phone.accessoryType = .More
        sectionModel_phone.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_phone.moreLayoutStyle = .leftTitleRightImage

        let phoneSection = PTSection.init(headerTitle: sectionModel_phone.name,headerID: PTFusionHeader.ID,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: phoneRows,headerDataModel: sectionModel_phone)
        
        /**
            UIKIT
         */
        let slider = self.rowBaseModel(name: .slider)
        
        let rate = self.rowBaseModel(name: .rate)

        let segment = self.rowBaseModel(name: .segment)

        let countLabel = self.rowBaseModel(name: .countLabel)
        
        let throughLabel = self.rowBaseModel(name: .throughLabel)
        
        let twitterLabel = self.rowBaseModel(name: .twitterLabel)
        
        let movieCutOutput = self.rowBaseModel(name: .movieCutOutput)
        
        let progressBar = self.rowBaseModel(name: .progressBar)
        
        let asTips = self.rowBaseModel(name: .alert)
        
        let menu = self.rowBaseModel(name: .menu)
        
        let loading = self.rowBaseModel(name: .loading)

        let permission = self.rowBaseModel(name: .permission)
        
        let permissionSetting = self.rowBaseModel(name: .permissionSetting)

        let tipkit = self.rowBaseModel(name: .tipkit)
        
        let document = self.rowBaseModel(name: .document)
        
        let svga = self.rowBaseModel(name: .svga)
        
        let swipe = self.rowBaseModel(name: .swipe)
        
        let scanQR = self.rowBaseModel(name: .scanQR)
        
        let filtercamera = self.rowBaseModel(name: .filtercamera)
        
        let editimage = self.rowBaseModel(name: .editimage)
        
        let sortButton = self.rowBaseModel(name: .sortButton)
        
        let messageKit = self.rowBaseModel(name: .messageKit)

        let blurImageList = self.rowBaseModel(name: .BlurImageList)

        let cycleBanner = self.rowBaseModel(name: .CycleBanner)
        
        let CollectionTag = self.rowBaseModel(name: .CollectionTag)

        let InputBox = self.rowBaseModel(name: .InputBox)
        
        let Stepper = self.rowBaseModel(name: .Stepper)

        let LoginDesc = self.rowBaseModel(name: .LoginDesc)
        
        let StepperList = self.rowBaseModel(name: .StepperList)

        let LivePhoto = self.rowBaseModel(name: .LivePhoto)

        let LivePhotoDisassemble = self.rowBaseModel(name: .LivePhotoDisassemble)
        
        let uikitArrs = [slider,rate,segment,countLabel,throughLabel,twitterLabel,movieCutOutput,progressBar,asTips,menu,loading,permission,permissionSetting,tipkit,document,svga,swipe,scanQR,filtercamera,editimage,sortButton,messageKit,blurImageList,cycleBanner,CollectionTag,InputBox,Stepper,LoginDesc,StepperList,LivePhoto,LivePhotoDisassemble]
        
        var uikitRows = [PTRows]()
        uikitRows = uikitArrs.map {
            switch $0.name {
                case .swipe:
                let row = PTRows(title:$0.name,ID: PTFusionSwipeCell.ID,dataModel: $0)
                return row
            default:
                let row = PTRows(title:$0.name,ID: PTFusionCell.ID,dataModel: $0)
                return row
            }
        }
        
        let sectionModel_uikit = PTFusionCellModel()
        sectionModel_uikit.name = "UIKIT"
        sectionModel_uikit.cellFont = sectionTitleFont
        sectionModel_uikit.accessoryType = .More
        sectionModel_uikit.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_uikit.moreLayoutStyle = .upTitleDownImage

        let uikitSection = PTSection.init(headerTitle: sectionModel_uikit.name,headerID: PTFusionHeader.ID,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: uikitRows,headerDataModel: sectionModel_uikit)
        
        /**
            Route
         */
        let route = self.rowBaseModel(name: .route)

        let routeArrs = [route]
        
        var routeRows = [PTRows]()
        routeArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,ID: PTFusionCell.ID,dataModel: value)
            routeRows.append(row)
        }
        
        let sectionModel_route = PTFusionCellModel()
        sectionModel_route.name = "Route"
        sectionModel_route.cellFont = sectionTitleFont
        sectionModel_route.accessoryType = .NoneAccessoryView

        let routeSection = PTSection.init(headerTitle: sectionModel_route.name,headerID: PTFusionHeader.ID,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: routeRows,headerDataModel: sectionModel_route)
        
        /**
            Encryption
         */
        let encryption = self.rowBaseModel(name: .encryption)

        let encryptionArrs = [encryption]
        
        var encryptionRows = [PTRows]()
        encryptionArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,ID: PTFusionCell.ID,dataModel: value)
            encryptionRows.append(row)
        }
        
        let sectionModel_encryption = PTFusionCellModel()
        sectionModel_encryption.name = "Encryption"
        sectionModel_encryption.cellFont = sectionTitleFont
        sectionModel_encryption.accessoryType = .NoneAccessoryView

        let encryptionSection = PTSection.init(headerTitle: sectionModel_encryption.name,headerID: PTFusionHeader.ID,footerID: PTVersionFooter.ID,footerHeight: 88,headerHeight: 44, rows: encryptionRows,headerDataModel: sectionModel_encryption)

        return [netSection,mediaSection,phoneSection,uikitSection,routeSection,encryptionSection]
    }
    
    var aaaaaaa:PTCollectionView!
    
    func collectionViewConfig() -> PTCollectionViewConfig {

        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Normal
        cConfig.itemHeight = PTAppBaseConfig.share.baseCellHeight
        cConfig.topRefresh = true
        cConfig.showEmptyAlert = !vcEmpty
        var strings = [String]()
        cSections().enumerated().forEach { index,value in
            strings.append("\(index)")
        }
        cConfig.indexConfig = PTCollectionIndexViewConfiguration()
        cConfig.sideIndexTitles = strings

        let emptyConfig = PTEmptyDataViewConfig()
        
        let emptyView = UIView(frame: CGRectMake(0, 0, 100, 100))
        emptyView.backgroundColor = .randomColor
        emptyView.isUserInteractionEnabled = true
        emptyView.clipsToBounds = true
        
        
        
        let aaaaaaaaaaaa = UIButton(type: .custom)
        aaaaaaaaaaaa.addActionHandlers { sender in
//            self.aaaaaaa.viewConfig = cConfig
//            self.aaaaaaa.clearAllData { cView in
//                self.aaaaaaa.reloadEmptyConfig()
//            }
            emptyView.backgroundColor = .randomColor
//            PTNSLogConsole("123123123123123123")
            self.showCollectionViewData()
        }
        emptyView.addSubviews([aaaaaaaaaaaa])
        aaaaaaaaaaaa.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyConfig.customerView = emptyView
        emptyConfig.verticalOffSet = -120
//        emptyConfig.image = UIImage(named: "DemoImage")
//        emptyConfig.backgroundColor = .systemRed
//        emptyConfig.mainTitleAtt = """
//                \(wrap: .embedding("""
//                \("沒數據",.foreground(.random),.font(.appfont(size: 14)),.paragraph(.alignment(.center)))
//                """))
//                """
//        emptyConfig.secondaryEmptyAtt = """
//                \(wrap: .embedding("""
//                \("111111111111",.foreground(.random),.font(.appfont(size: 14)),.paragraph(.alignment(.center)))
//                """))
//                """
//        emptyConfig.buttonTitle = "點擊"
//        emptyConfig.buttonFont = .appfont(size: 14)
//        emptyConfig.buttonTextColor = .randomColor
        cConfig.emptyViewConfig = emptyConfig
        
        return cConfig
    }
    
    lazy var collectionView : PTCollectionView = {
        aaaaaaa = PTCollectionView(viewConfig: self.collectionViewConfig())
        aaaaaaa.registerClassCells(classs: [PTFusionCell.ID:PTFusionCell.self,PTFusionSwipeCell.ID:PTFusionSwipeCell.self])
        aaaaaaa.registerSupplementaryView(classs: [PTFusionHeader.ID:PTFusionHeader.self], kind: UICollectionView.elementKindSectionHeader)
        aaaaaaa.registerSupplementaryView(classs: [PTTestFooter.ID:PTTestFooter.self,PTVersionFooter.ID:PTVersionFooter.self], kind: UICollectionView.elementKindSectionFooter)
        aaaaaaa.layoutSubviews()
        aaaaaaa.decorationInCollectionView = { index,sectionModel in
            let backItemId = YDSWhiteDecorationView.ID
            let topSpace:CGFloat = 10
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: backItemId)
            backItem.contentInsets = NSDirectionalEdgeInsets.init(top: topSpace, leading: 12, bottom: 0, trailing: 12)
            return [backItem]
        }
        aaaaaaa.decorationCustomLayoutInsetReset = { index,sectionModel in
            let topSpace:CGFloat = 10
            return NSDirectionalEdgeInsets.init(top: (sectionModel.headerHeight ?? CGFloat.leastNormalMagnitude) + topSpace, leading: 12, bottom: 0, trailing: 12)
        }
        aaaaaaa.headerInCollection = { kind,collectionView,model,index in
            let sectionModel = (model.headerDataModel as! PTFusionCellModel)
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as! PTFusionHeader
            header.sectionModel = sectionModel
            if sectionModel.name == "网络" {
                header.moreActionBlock = { text,sender in
                    PTNSLogConsole("点击了More")
                }
            } else if sectionModel.name == "多媒体" {
                header.switchValue = true
                header.switchValueChangeBlock = { text,sender in
                    PTNSLogConsole("点击了Switch")
                }
            }
            return header
        }
        aaaaaaa.footerInCollection = { kind,collectionView,model,index in
            if model.footerID == PTVersionFooter.ID {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.footerID!, for: index) as! PTVersionFooter
                return footer
            } else {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.footerID!, for: index) as! PTTestFooter
                return footer
            }
        }
        aaaaaaa.cellInCollection = { collectionView ,dataModel,indexPath in
            if let itemRow = dataModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTFusionCellModel {
                let baseCell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath)
                if itemRow.ID == PTFusionCell.ID,let cell = baseCell as? PTFusionCell {
                    cell.cellModel = cellModel
                    cell.contentView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
                    
                    if dataModel.rows!.count == 1 {
                        cell.hideTopLine = true
                    } else {
                        cell.hideTopLine = indexPath.row == 0 ? true : false
                    }
                    cell.hideBottomLine = (dataModel.rows!.count - 1) == indexPath.row ? true : false
                    return cell
                } else if itemRow.ID == PTFusionSwipeCell.ID,let cell = baseCell as? PTFusionSwipeCell {
                    cell.cellModel = cellModel
                    cell.contentView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
                    
                    if dataModel.rows!.count == 1 {
                        cell.hideTopLine = true
                    } else {
                        cell.hideTopLine = indexPath.row == 0 ? true : false
                    }
                    cell.hideBottomLine = (dataModel.rows!.count - 1) == indexPath.row ? true : false
                    return cell
                }
            }
            return nil
        }
        aaaaaaa.indexPathSwipe = { model,indxPath in
            return true
        }
        aaaaaaa.swipeLeftHandler = { collection,sectionModel,indexPath in
            let swipeAction = PTSwipeAction(name: "1111111", image: nil, backgroundColor: .random) { sender in
                PTNSLogConsole("123123123123123")
            }
            return [swipeAction]
        }
        aaaaaaa.swipeRightHandler = { collection,sectionModel,indexPath in
            let swipeAction = PTSwipeAction(name: "333333", image: nil, backgroundColor: .random) { sender in
                PTNSLogConsole("4444444")
            }
            return [swipeAction]
        }
        aaaaaaa.collectionDidSelect = { collectionViews,sModel,indexPath in
            if let itemRow = sModel.rows?[indexPath.row] {
                let cellModel = (itemRow.dataModel as! PTFusionCellModel)
                if itemRow.title == .imageReview {
                    let model1 = PTMediaBrowserModel()
                    model1.imageURL = "https://i-blog.csdnimg.cn/blog_migrate/becd8bdd2845791b0f9b28ba58a27bac.jpeg"
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
                    mediaConfig.dismissY = 200
                    mediaConfig.actionType = .All
                    mediaConfig.pageControlOption = .snake
                    mediaConfig.mediaData = [model1]
                    mediaConfig.imageLongTapAction = true
                    mediaConfig.dynamicBackground = true
                    let browser = PTMediaBrowserController()
                    browser.medisShow(mediaConfig: mediaConfig)
                } else if itemRow.title == .phoneCall {
                    PTPhoneBlock.callPhoneNumber(phoneNumber: "13800138000", call: { duration in
                    }, cancel: {
                        
                    }, canCall: { finish in
                        
                    })
                } else if itemRow.title == .cleanCache {
                    PTGCDManager.gcdGobal(qosCls: .background) {
                        Task {
                            let isCleared = await PCleanCache.clearCaches()
                            if isCleared {
                                UIAlertController.gobal_drop(title: "清理成功")
                                self.showCollectionViewData()
                            } else {
                                UIAlertController.gobal_drop(title: "暂时没有缓存了")
                            }
                        }
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
                    let pickerConfig = PTMediaLibConfig.share
                    pickerConfig.allowSelectImage = false
                    pickerConfig.allowSelectVideo = true
                    pickerConfig.allowSelectGif = false
                    pickerConfig.allowEditVideo = false
                    pickerConfig.maxSelectCount = 1
                    pickerConfig.maxVideoSelectCount = 1
                    pickerConfig.useCustomCamera = false
                    
                    let vc = PTMediaLibViewController()
                    vc.mediaLibShow()
                    vc.selectedHudStatusBlock = { result in
                        if result {
                            PTAlertTipControl.present(icon:.Heart,style: .Normal)
                        } else {
                            PTAlertTipControl.present(icon:.Done,style: .Normal)
                        }
                    }
                    vc.selectImageBlock = { result, isOriginal in
                        PTNSLogConsole("視頻選擇後:>>>>>>>>>>>>>\(result)")
                        if let resultFirst = result.first {
                            resultFirst.asset.convertPHAssetToAVAsset { progress in
                                PTNSLogConsole("progress:>>>>>>>>>>>>>\(progress)")

                            } completion: { avAsset in
                                if let getAv = avAsset {
                                    PTGCDManager.gcdMain {
                                        let controller = PTVideoEditorToolsViewController(asset: resultFirst.asset,avAsset: getAv)
                                        controller.videoEditorShow(vc: self)
                                        controller.onEditCompleteHandler = { url in
                                            PTAlertTipControl.present(title:"我好了\(url)",icon:.Done,style: .Normal)
                                        }
                                    }
                                } else {
                                    PTGCDManager.gcdMain {
                                        PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:"PT Video editor get video error".localized(),icon:.Error,style: .Normal)
                                    }
                                }
                            }
                        } else {
                            PTGCDManager.gcdMain {
                                PTAlertTipControl.present(title:"沒有選擇Video",icon:.Error,style: .Normal)
                            }
                        }
                    }
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
                    PTRotationManager.shared.toggleOrientation()
    //                let r:Int = Int(arc4random_uniform(2))
    //                PTRotationManager.shared.rotation(to: PTRotationManager.Orientation.allCases[r])
                } else if itemRow.title == .osskit {
                    let vc = PTSpeechViewController()
                    self.navigationController?.pushViewController(vc)
                } else if itemRow.title == .share {
                    guard let url = URL(string: shareURLString) else {
                        return
                    }

                    let share = PTShareCustomActivity()
                    share.text = shareText
                    share.url = url
                    share.image = UIImage(named: "DemoImage")
                    share.customActivityTitle = "测试Title"
                    share.customActivityImage = "🖼️".emojiToImage(emojiFont: .appfont(size: 54))

                    let items: [Any] = [shareText, url, UIImage(named: "DemoImage")!]

                    let vc = PTActivityViewController(activityItems: items,applicationActivities: [share])
                    vc.previewNumberOfLines = 10
                    if let cell = self.aaaaaaa.contentCollectionView.cellForItem(at: indexPath) {
                        vc.presentActionSheet(self, from: cell)
                    }
                } else if itemRow.title == .checkUpdate {
                    PTCheckUpdateFunction.share.checkTheVersionWithappid(appid: "6596749489", test: false, url: URL(string: shareURLString), version: "1.0.0", note: "123", force: false,alertType: .User)
                } else if itemRow.title == .route {
                    UIAlertController.baseActionSheet(title: "Route", titles: ["普通","帶數據","Handler"], otherBlock: { sheet,index,title in
                        switch index {
                        case 0:
                            PTRouter.routeJump(vcName: NSStringFromClass(PTRouteViewController.self), scheme: PTRouteViewController.patternString.first!)
                        case 1:
                            PTRouter.addRouterItem(RouteItem(path: PTRouteViewController.patternString.first!, className: NSStringFromClass(PTRouteViewController.self)))
                            let model = PTRouterExampleModel()
                            PTRouter.openURL(("scheme://route/route",["model":model]))
                        case 2:
                            PTRouter.addRouterItem(RouteItem(path: PTRouteViewController.patternString.first!, className: NSStringFromClass(PTRouteViewController.self)))
                            
                            let handler = { (value:String) in
                                UIViewController.gobal_drop(title: value)
                            }
                            
                            PTRouter.openURL(("scheme://route/route",["task":handler]))
                        default:
                            break
                        }
                    })
                } else if itemRow.title == .alert {
                    UIAlertController.baseActionSheet(title: "AlertTips", titles: ["low","hight",String.feedbackAlert,"ActionSheet","CustomActionSheet","new","newActionSheet"], otherBlock: { sheet,index,title in
                        switch index {
                        case 0:
                            PTAlertTipControl.present(title:"Job Done!",subtitle: "WOW",icon:.Done,style: .Normal)
                        case 1:
                            PTAlertTipControl.present(title:"Hola!",subtitle: "Que?",icon:.Error,style: .SupportVisionOS)
                        case 2:
                            UIAlertController.alertSendFeedBack { title, content in
                                UIAlertController.gobal_drop(title: title,subTitle: content) {
                                    UIAlertController.base_textfield_alertVC(okBtn: "PT Button comfirm".localized(), cancelBtn: "PT Button cancel".localized(), placeHolders: ["placeholder"], textFieldTexts: ["Test"], keyboardType: [.default], textFieldDelegate: self) { result in
                                        
                                    }
                                } notifiDismiss: {
                                    UIAlertController.alertVC(title: "notifi消失之后", msg: "哦", cancel: "PT Button cancel".localized(), cancelBlock: {
                                        
                                    })
                                }
                            }
                        case 3:
                            UIAlertController.baseActionSheet(title: "Title",subTitle: "SubTitle",cancelButtonName: "Cancel",destructiveButtons: ["Destructive","Destructive1","Destructive2"], titles: ["1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1"], destructiveBlock: { sheet, index, title in
                                
                            },otherBlock: { sheet,index,title in
                            })
                        case 4:
                            let title = PTActionSheetTitleItem(title: "Title", subTitle: "SubTitle")
                            
                            let cancelItem = PTActionSheetItem(title: "取消",image: UIImage(named: "DemoImage"),itemAlignment:.leading,itemLayout: .leftImageRightTitle)

                            let deItem = PTActionSheetItem(title: "其他",titleColor:.systemRed,image: "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif",itemAlignment:.trailing,itemLayout: .leftTitleRightImage)

                            let content1 = PTActionSheetItem(title: "1",image: "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg",itemAlignment:.left,itemLayout: .leftTitleRightImage)
                            let content2 = PTActionSheetItem(title: "2",image: "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg",itemAlignment:.right,itemLayout: .leftTitleRightImage)
                            let content3 = PTActionSheetItem(title: "3",image: "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg",itemAlignment:.fill,itemLayout: .leftTitleRightImage)

                            let actionSheet = PTActionSheetController(titleItem:title,cancelItem:cancelItem,destructiveItems: [deItem],contentItems: [content1,content2,content3])
                            PTAlertManager.show(actionSheet)

                        case 5:
                            let newAlertController = PTCustomerAlertController(title: "",buttons: ["11111","33333"],buttonsColors: [.systemBlue],cornerSize: 15)
                            PTAlertManager.show(newAlertController)
                        case 6:
                            let titleItem = PTActionSheetTitleItem(title: "Title",subTitle: "SubTitle")

                            var destructiveItems = [PTActionSheetItem]()
                            ["Destructive","Destructive1","Destructive2"].enumerated().forEach { index,value in
                                let item = PTActionSheetItem(title: value)
                                item.titleColor = .systemRed
                                destructiveItems.append(item)
                            }
                            
                            var contentItems = [PTActionSheetItem]()
                            ["1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1","1"].enumerated().forEach { index,value in
                                let item = PTActionSheetItem(title: value)
                                contentItems.append(item)
                            }
                            
                            let newAlertController = PTActionSheetController(titleItem:titleItem,destructiveItems: destructiveItems,contentItems: contentItems)
                            PTAlertManager.show(newAlertController)

                        default:
                            break
                        }
                    })

                } else if itemRow.title == .loading {
                    UIAlertController.baseActionSheet(title: "Loading", titles: ["LoadingHub","CycleLoading"], otherBlock: { sheet,index,title in
                        switch index {
                        case 0:
                            let hud = PTHudView()
                            hud.hudShow()
                            PTGCDManager.gcdAfter(time: 5) {
                                hud.hide {
                                    
                                }
                            }
                        case 1:
                            let cycle = PTCycleLoadingView()
                            self.view.addSubviews([cycle])
                            cycle.snp.makeConstraints { make in
                                make.size.equalTo(100)
                                make.centerX.centerY.equalToSuperview()
                            }
                            cycle.startAnimation()
                            PTGCDManager.gcdAfter(time: 5) {
                                cycle.stopAnimation {
                                    cycle.removeFromSuperview()
                                }
                            }
                        default:
                            break
                        }
                    })
                } else if itemRow.title == .permission {

                    let permissionVC = PTPermissionViewController()
                    permissionVC.permissionShow(vc: self)
                    permissionVC.viewDismissBlock = {
                    }

                } else if itemRow.title == .permissionSetting {
                    
                    let permissionVC = PTPermissionSettingViewController()
                    permissionVC.permissionShow(vc: self)
                } else if itemRow.title == .language {
                    UIAlertController.baseActionSheet(title: .language,subTitle: self.currentSelectedLanguage, titles: LanguageKey.allNames, otherBlock: { sheet,index,title in
                        self.currentSelectedLanguage = LanguageKey.allValues[index].desc
                        PTLanguage.share.language = LanguageKey.allValues[index].rawValue
                    })
                } else if itemRow.title == .darkMode {
                    let vc = PTDarkModeControl()
                    self.navigationController?.pushViewController(vc)
                } else if itemRow.title == .tipkit {
                    if #available(iOS 17.0, *) {
                        let vc = PTTipsDemoController()
                        self.navigationController?.pushViewController(vc)
                    }
                } else if itemRow.title == .document {
                    if #available(iOS 17.0, *) {
                        let vc = PTDocumentViewController()
                        self.navigationController?.pushViewController(vc)
                    }
                } else if itemRow.title == .svga {
    //                let vc = PTSVGAViewController()
    //                self.navigationController?.pushViewController(vc)
                } else if itemRow.title == .scanQR {
                    let vc = PTScanQRController(viewConfig: PTScanQRConfig())
                    vc.resultBlock = { result,error in
                        PTNSLogConsole("\(result)")
                    }
                    self.navigationController?.pushViewController(vc)
                } else if itemRow.title == .filtercamera {
                    let cameraConfig = PTCameraFilterConfig.share
                    cameraConfig.allowRecordVideo = true
                    let pointFont = UIFont.appfont(size: 20)

                    cameraConfig.backImage = "❌".emojiToImage(emojiFont: pointFont)
                    cameraConfig.flashImage = UIImage(.flashlight.offFill).withTintColor(.white)
                    cameraConfig.flashImageSelected = UIImage(.flashlight.onFill).withTintColor(.white)
                    
                    if #available(iOS 15.0, *) {
                        cameraConfig.filtersImageSelected = UIImage(.line._3HorizontalDecreaseCircleFill)
                        cameraConfig.filtersImage = UIImage(.line._3HorizontalDecreaseCircle)
                    } else {
                        cameraConfig.filtersImage = UIImage(.f.cursiveCircle)
                        cameraConfig.filtersImageSelected = UIImage(.f.cursiveCircleFill)
                    }

                    let vc = PTFilterCameraViewController()
                    vc.onlyCamera = false
                    vc.modalPresentationStyle = .fullScreen
                    self.showDetailViewController(vc, sender: nil)
                } else if itemRow.title == .editimage {
                    let image = UIImage(named: "DemoImage")!
                    
                    let vc = PTEditImageViewController(readyEditImage: image)
                    vc.editFinishBlock = { ei ,editImageModel in
                        PHPhotoLibrary.pt.saveImageToAlbum(image: ei) { finish, asset in
                            if !finish {
                                PTAlertTipControl.present(title:"Opps",subtitle: "保存图片失败",icon:.Error,style: .Normal)
                            }
                        }
                    }
                    let nav = PTBaseNavControl(rootViewController: vc)
                    nav.view.backgroundColor = .black
                    nav.modalPresentationStyle = .fullScreen
                    self.showDetailViewController(nav, sender: nil)
                } else if itemRow.title == .messageKit {
                    let vc = PTTestChatViewController()
                    self.navigationController?.pushViewController(vc)
                } else if itemRow.title == .BlurImageList {
                    let vc = PTImageListViewController()
                    self.navigationController?.pushViewController(vc)
                } else if itemRow.title == .mediaSelect {
                    let config = PTMediaLibConfig.share
                    config.maxSelectCount = 9
                    config.allowSelectImage = true
                    config.allowSelectVideo = true
                    config.allowMixSelect = true
                    config.maxVideoSelectCount = 1
                    config.allowEditImage = true
                    config.allowEditVideo = true
                    config.useCustomCamera = false

                    let vc = PTMediaLibViewController()
                    vc.mediaLibShow()
                    vc.selectImageBlock = { result,isOriginal in
                        if result.count > 0 {
                            PTNSLogConsole("\(result)")
                        } else {
                            PTAlertTipControl.present(title:"失败",subtitle:"",icon:.Error,style: .Normal)
                        }
                    }
                } else {
                    var sheetSize = [PTSheetSize]()
                    if itemRow.title == .StepperList || itemRow.title == .LivePhoto  || itemRow.title == .LivePhotoDisassemble {
                        sheetSize = [.percent(0.9)]
                    } else {
                        sheetSize = [.percent(0.5)]
                    }
                    let vc = PTFuncDetailViewController(typeString: itemRow.title)
                    self.currentPresentToSheet(vc: vc,sizes: sheetSize)
                }
            }
        }
        aaaaaaa.headerRefreshTask = { sender in
            if #available(iOS 17, *) {
                self.collectionView.clearAllData { collectionview in
                    self.collectionView.endRefresh()
                }
            } else {
                self.collectionView.endRefresh()
            }
        }
        aaaaaaa.emptyTap = { sender in
            if #available(iOS 17, *) {
                self.collectionView.showEmptyLoading()
                PTGCDManager.gcdAfter(time: 1, block: {
                    self.collectionView.hideEmptyLoading(task: {
                        self.showCollectionViewData()
                    })
                })
            } else {
                self.showCollectionViewData()
            }
        }
        aaaaaaa.emptyButtonTap = { sender in
            PTNSLogConsole("12312312312312312")
        }
        aaaaaaa.forceController = { cView,index,model in
            return PTBaseViewController()
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
                
        registerScreenShotService()
        
        NotificationCenter.default.addObserver(self, selector: #selector(flashAd(notifi:)), name: NSNotification.Name.init(PLaunchAdDetailDisplayNotification), object: nil)
        
        let more = UIButton(type: .custom)
        more.setTitleColor(.random, for: .normal)
        more.setTitle("More", for: .normal)
        more.bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
        more.badge?.badgeBorderLine = 1
        more.badge?.badgeBorderColor = .random
        more.showBadge(style: .New, value: "我愛你", aniType: .None)
        
        let popover = PTActionLayoutButton()
        popover.imageSize = CGSize(width: 15, height: 15)
        popover.layoutStyle = .leftImageRightTitle
        popover.midSpacing = 0
        popover.setTitleFont(.appfont(size: 12), state: .normal)
        popover.setTitleColor(.random, state: .normal)
        popover.setTitle("Popover", state: .normal)
        popover.bounds = CGRect(x: 0, y: 0, width: 100, height: 40)
        popover.setImage("http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg", state: .normal)
        
        let searchBarConfig = PTSearchBarTextFieldClearButtonConfig()
        searchBarConfig.clearTopSpace = 20
        searchBarConfig.clearImage = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
        searchBarConfig.clearAction = {
            PTNSLogConsole("1231231231")
        }
        
        let searchBar = PTSearchBar()
        searchBar.clearConfig = searchBarConfig
        searchBar.bounds = CGRect(x: 0, y: 0, width: 64, height: 34)
        
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubviews([more,popover])
        more.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            more.size.equalTo(more.bounds.size)
            make.bottom.equalToSuperview().inset(2)
        }
        
        popover.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            more.size.equalTo(more.bounds.size)
            make.bottom.equalToSuperview().inset(5)
        }
#else
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: popover)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: more)
        navigationItem.titleView = searchBar
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
                let fromAnimation = PTListAnimationType.vector(CGVector(dx: 30, dy: 0))
                let zoomAnimation = PTListAnimationType.zoom(scale: 0.2)
                UIView.animate(views: self.collectionView.contentCollectionView.visibleCells,
                               animations: [fromAnimation, zoomAnimation], delay: 0.5)
            }
        }
        
        let customSwitch = PTSwitch()
        customSwitch.isOn = true
        customSwitch.thumbColor = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
        popoverContent.view.addSubview(customSwitch)
        customSwitch.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.width.equalTo(30)
            make.top.equalTo(popoverButton.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }

        let testButton = UIButton(type: .custom)
        testButton.setBackgroundColor(color: .random, forState: .normal)
        popoverContent.view.addSubview(testButton)
        testButton.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.centerX.equalToSuperview()
            make.top.equalTo(customSwitch.snp.bottom).offset(10)
        }
        testButton.addActionHandlers { sender in
            let vc = PTTestVC()
            self.currentPresentToSheet(vc: vc,sizes: [.percent(0.9)])
        }
        
        popover.addActionHandlers { sender in
//            let items = PTPopoverItem()
//            items.name = "123123123123"
////            items.icon = "DemoImage"
//            
//            self.listPopover(items: [items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items,items], popoverWidth: 300, sender: sender, arrowDirections: .any) { itemName, index in
//                PTNSLogConsole("?????????????>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\(itemName)")
//            }
            PTNSLogConsole("123123123123123123123123123123123123123123")
            self.sideMenuController?.revealMenu()
        }
        more.addActionHandlers { sender in
            self.popover(popoverVC: popoverContent, popoverSize: CGSize(width: 100, height: 300), sender: sender, arrowDirections: .any)
        }
        
        collectionView.backgroundColor = .random
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
            make.top.equalToSuperview()
#endif
            make.right.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        
        PTRotationManager.shared.orientationMaskDidChange = { orientationMask in
            PTNSLogConsole("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\(orientationMask)")
            self.collectionView.snp.remakeConstraints { make in
    #if POOTOOLS_NAVBARCONTROLLER
                make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
    #else
                make.top.equalToSuperview()
    #endif
                make.right.bottom.equalToSuperview()
                make.left.right.equalToSuperview()
            }
            self.showCollectionViewData()
        }
        
        if #unavailable(iOS 17.0) {
            PTGCDManager.gcdAfter(time: 10) {
                self.showCollectionViewData()
            }    
        } else {
            if vcEmpty {
                let emptyConfig = PTEmptyDataViewConfig()
                emptyConfig.buttonTitle = "點我刷新"
                emptyConfig.image = UIImage(.exclamationmark.triangle)
                emptyConfig.mainTitleAtt = """
                    \(wrap: .embedding("""
                    \("PT Alert Opps".localized(),.foreground(.random),.font(.appfont(size: 20,bold: true)),.paragraph(.alignment(.center)))
                    """))
                    """
                emptyConfig.secondaryEmptyAtt = """
                    \(wrap: .embedding("""
                    \("PT Photo picker empty media".localized(),.foreground(.random),.font(.appfont(size: 18)),.paragraph(.alignment(.center)))
                    """))
                    """

                emptyDataViewConfig = emptyConfig
                showEmptyView {
                    self.emptyReload()
                }
                
                PTGCDManager.gcdAfter(time: 5) {
                    self.emptyReload()
                }
            }
        }
        
        inputValueSample(value: 15)
                
        @PTLockAtomic
        var json:[String:String]?
        json = ["A":"1"]
        PTNSLogConsole(">>>>>>>>>>>>>>>>>\(String(describing: json))")        
        
        if PTWhatsNews.shouldPresent(with: .debug) {
            let item1 = PTWhatsNewsItem()
            item1.subTitle = "比如说.................................................................................................................4"
            
            let item2 = PTWhatsNewsItem()
            item2.newsImage = "🥹".emojiToImage(emojiFont: .appfont(size: 34))
            item2.title = "好好吃"
            item2.subTitle = "public static let appVersion = Bundle.main.infoDictionary?[\"CFBundleShortVersionString\"] as? String"
            
            let item3 = PTWhatsNewsItem()
            item3.newsImage = "🥹".emojiToImage(emojiFont: .appfont(size: 34))
            item3.title = "2"
            item3.subTitle = "1"
            
            let item4 = PTWhatsNewsItem()
            item4.title = "2"
            item4.subTitle = "1"

            let item5 = PTWhatsNewsItem()
            item5.newsImage = "🥹".emojiToImage(emojiFont: .appfont(size: 34))
            item5.title = "11111111"
            
            let iKnowItem = PTWhatsNewsIKnowItem()
            iKnowItem.privacy = "Privacy"
            iKnowItem.privacyURL = "https://www.qq.com"
            
            let view = PTWhatsNewsViewController(titleItem: PTWhatsNewsTitleItem(),iKnowItem: iKnowItem,newsItem: [item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2])
            view.whatsNewsShow(vc: self)
        }
                
        
        PTGCDManager.gcdAfter(time: 5) {
            let vvvvv = PTDynamicNotificationView(showTimes: 3, canTap: true) { view in
                view.backgroundColor = .random
            }
            vvvvv.showNotification()
            vvvvv.hideHandler = {
            }
        }
        
        let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let items = [
            PTMenuSheetButtonItems(
                image: "▶️".emojiToImage(emojiFont: .appfont(size: 24)),
                highlightedImage: "▶️".emojiToImage(emojiFont: .appfont(size: 24)),
                imageEdgeInsets: insets,
                identifier: "delete",
                action: {_ in}
            ),
            PTMenuSheetButtonItems(
                image: "😂".emojiToImage(emojiFont: .appfont(size: 24)),
                highlightedImage: "🤣".emojiToImage(emojiFont: .appfont(size: 24)),
                imageEdgeInsets: insets,
                identifier: "edit",
                action: {_ in}
            )
        ]
        let buttonView = PTMenuSheetButtonView(direction: .right, items: items)
        buttonView.backgroundColor = .randomColor
        buttonView.arrowWidth = 2
        buttonView.separatorWidth = 2
        buttonView.separatorInset = 12
        buttonView.layer.cornerRadius = 30
        buttonView.accessibilityIdentifier = "expandableButton"
        view.addSubview(buttonView)
        PTGCDManager.gcdAfter(time: 0.35) {
            buttonView.frame = CGRect(x: PTAppBaseConfig.share.defaultViewSpace, y: 400, width: 60, height: 60)
        }
    }
    
    func flashAd(notifi:Notification) {
        let obj = notifi.object as! [String:Any]
        obj.allKeys().enumerated().forEach { index,value in
            let keyValue = obj[value]
            if keyValue is String {
                if (keyValue as! String).isURL() {
                    let vc = PTBaseWebViewController(showString: (keyValue as! String))
                    self.navigationController?.pushViewController(vc)
//                    PTAppStoreFunction.jumpLink(url: URL(string: (keyValue as! String))!)
                }
            }
        }
    }
    
    @available(iOS 17, *)
    func emptyReload() {
        emptyViewLoading()
        PTGCDManager.gcdAfter(time: 2) {
            self.hideEmptyView {
                self.collectionView.clearAllData { cView in
                    self.showCollectionViewData()
                }
            }
        }
    }
    
    func showCollectionViewData() {
        Task {
            // 獲取緩存大小
            let cacheSize = await PCleanCache.getCacheSize()
            self.cacheSize = cacheSize
            
            // 切換到主線程更新 UI
            PTGCDManager.gcdMain {
                self.collectionView.showCollectionDetail(collectionData: self.cSections())
            }
        }
    }
    
    func inputValueSample(@PTClampedProperyWrapper(range:1...10) value:Int = 1) {
        PTNSLogConsole(">>>>>>>>>>>>>>>>>>>>>>>>>\(value)")
    }
}

// MARK: - ImagePickerControllerDelegate
extension PTFuncNameViewController {
    
    func saveVideoToAlbum(result:((_ finish:Bool)->Void)? = nil) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputURL)
        }) { success, error in
            if success {
                PTNSLogConsole("视频保存成功")
                result?(true)
            } else {
                PTNSLogConsole("视频保存失败：\(error?.localizedDescription ?? "")")
                result?(false)
            }
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

extension PTFuncNameViewController:UITextFieldDelegate {}
