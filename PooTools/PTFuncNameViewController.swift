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
@preconcurrency import DeviceKit
import Photos
import Combine
import SafeSFSymbols
import AttributedString

struct UserModel: PTPickerStringModel {
    let userId: String
    let userName: String
    
    // 告訴 Picker，滾輪上顯示 userName
    var pickerDisplayText: String { return userName }
}

struct RegionModel: PTTreePickerModel {
    let id: String
    let name: String
    let children: [RegionModel]
    
    // 實現協議：告訴選擇器顯示的文字
    var pickerDisplayText: String { return name }
    
    // 實現協議：告訴選擇器子節點是誰 (轉型返回即可)
    var pickerChildren: [PTTreePickerModel] { return children }
}

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
        Task { @MainActor in
            self.viewCornerRectCorner(radius: 8,corner: [.allCorners])
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PTFuncNameViewController: PTBaseViewController {

    // 🎯 直接告诉 TabBar：这就是你要监听的滑动视图！
    override var pt_observedScrollView: UIScrollView? {
        return collectionView.contentCollectionView
    }

    open override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.random)
    }

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
    
    func DeviceIdentifier() -> String {
        // 1. 如果当前已经在主线程，直接获取
        if Thread.isMainThread {
            // 注意：这里由于 Swift 6 的静态检查，直接写 Device.identifier 可能还是会黄牌警告。
            // 所以我们依然需要 assumeIsolated 来安抚编译器
            return MainActor.assumeIsolated { Device.identifier }
        } else {
            // 2. 如果在后台线程，同步阻塞当前线程，去主线程拿数据后再返回
            return DispatchQueue.main.sync {
                return Device.identifier
            }
        }
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

        let netSection = PTSection.init(headerTitle: sectionModel_net.name,footerHeight: 44,headerHeight: 44, rows: UICollectionView.sectionRows(rowsModel: netArrs),headerDataModel: sectionModel_net)
        netSection.headerClass = PTFusionHeader.self
        netSection.footerClass = PTTestFooter.self
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
            let row = PTRows(title:value.name,dataModel: value)
            row.cellClass = PTFusionCell.self
            mediaRows.append(row)
        }
        
        let sectionModel_media = PTFusionCellModel()
        sectionModel_media.name = "多媒体"
        sectionModel_media.cellFont = sectionTitleFont
        sectionModel_media.accessoryType = .Switch(type: .Framework)
        sectionModel_media.switchControlWidth = 51

        let mediaSection = PTSection.init(headerTitle: sectionModel_media.name,headerID: "1111111",footerHeight: 44,headerHeight: 44, rows: mediaRows,headerDataModel: sectionModel_media)
        mediaSection.headerClass = PTFusionHeader.self
        mediaSection.footerClass = PTTestFooter.self
        /**
            本机
         */
        let jailBroken = PTFusionCellModel()
        jailBroken.name = .phoneSimpleInfo
        jailBroken.cellDescFont = .appfont(size: 12)
        jailBroken.desc = "是否X类型:\(UIDevice.pt.oneOfXDevice() ? "是" : "否"),是否越狱了:\(UIDevice.pt.isJailBroken ? "是" : "否"),机型:\(DeviceIdentifier()),运营商:\(String(describing: UIDevice.pt.carrierNames()?.first))"
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
            let row = PTRows(title:value.name,dataModel: value)
            row.cellClass = PTFusionCell.self
            phoneRows.append(row)
        }
        
        let sectionModel_phone = PTFusionCellModel()
        sectionModel_phone.name = "本机"
        sectionModel_phone.cellFont = sectionTitleFont
        sectionModel_phone.accessoryType = .More
        sectionModel_phone.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_phone.moreLayoutStyle = .leftTitleRightImage

        let phoneSection = PTSection.init(headerTitle: sectionModel_phone.name,footerHeight: 44,headerHeight: 44, rows: phoneRows,headerDataModel: sectionModel_phone)
        phoneSection.headerClass = PTFusionHeader.self
        phoneSection.footerClass = PTTestFooter.self

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
                let row = PTRows(title:$0.name,dataModel: $0)
                row.cellClass = PTFusionSwipeCell.self
                return row
            default:
                let row = PTRows(title:$0.name,dataModel: $0)
                row.cellClass = PTFusionCell.self
                return row
            }
        }
        
        let sectionModel_uikit = PTFusionCellModel()
        sectionModel_uikit.name = "UIKIT"
        sectionModel_uikit.cellFont = sectionTitleFont
        sectionModel_uikit.accessoryType = .More
        sectionModel_uikit.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_uikit.moreLayoutStyle = .upTitleDownImage

        let uikitSection = PTSection.init(headerTitle: sectionModel_uikit.name,footerHeight: 44,headerHeight: 44, rows: uikitRows,headerDataModel: sectionModel_uikit)
        uikitSection.headerClass = PTFusionHeader.self
        uikitSection.footerClass = PTTestFooter.self

        /**
            Route
         */
        let route = self.rowBaseModel(name: .route)

        let routeArrs = [route]
        
        var routeRows = [PTRows]()
        routeArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,dataModel: value)
            row.cellClass = PTFusionCell.self
            routeRows.append(row)
        }
        
        let sectionModel_route = PTFusionCellModel()
        sectionModel_route.name = "Route"
        sectionModel_route.cellFont = sectionTitleFont
        sectionModel_route.accessoryType = .NoneAccessoryView

        let routeSection = PTSection.init(headerTitle: sectionModel_route.name,footerHeight: 44,headerHeight: 44, rows: routeRows,headerDataModel: sectionModel_route)
        routeSection.headerClass = PTFusionHeader.self
        routeSection.footerClass = PTTestFooter.self

        /**
            Encryption
         */
        let encryption = self.rowBaseModel(name: .encryption)

        let encryptionArrs = [encryption]
        
        var encryptionRows = [PTRows]()
        encryptionArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,dataModel: value)
            row.cellClass = PTFusionCell.self
            encryptionRows.append(row)
        }
        
        let sectionModel_encryption = PTFusionCellModel()
        sectionModel_encryption.name = "Encryption"
        sectionModel_encryption.cellFont = sectionTitleFont
        sectionModel_encryption.accessoryType = .NoneAccessoryView

        let encryptionSection = PTSection(headerTitle: sectionModel_encryption.name,footerHeight: 88,headerHeight: 44, rows: encryptionRows,headerDataModel: sectionModel_encryption)
        encryptionSection.headerClass = PTFusionHeader.self
        encryptionSection.footerClass = PTVersionFooter.self

        return [netSection,mediaSection,phoneSection,uikitSection,routeSection,encryptionSection]
    }
    
    var aaaaaaa:PTCollectionView!
    
    func collectionViewConfig() -> PTCollectionViewConfig {

        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Normal
        cConfig.itemHeight = PTAppBaseConfig.share.baseCellHeight
        cConfig.topRefresh = true
        cConfig.footerRefresh = true
        cConfig.showEmptyAlert = !vcEmpty
        var strings = [String]()
        cSections().enumerated().forEach { index,value in
            strings.append("\(index)")
        }
        let indexConfig = PTCollectionIndexViewConfiguration()
        indexConfig.indexViewBackgroundColor = .orange
        indexConfig.containerBottomOffset = CGFloat.kTabbarHeight_Total
        indexConfig.containerTopOffset = CGFloat.kNavBarHeight_Total
        cConfig.indexConfig = indexConfig
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
    
    func routeFunction() {
        Task {
            do {
                // 完美体验：自动补全、类型安全、精确错误捕获
                let detailVC = try await PTTypedBuilder<PTRouteViewController>(path: "ptools://routerTest")
                    .with(params: PTRouterExampleModel(foo: "1", poo: "123"))
                    .jumpType(.modal, wrapInNav: true, presentationStyle: .fullScreen, transitionStyle: .coverVertical)
                    .navigation()
                
                PTNSLogConsole("成功拿到目标控制器：\(detailVC.id)")
                
            } catch PTRouterError.interceptorBlocked {
                PTNSLogConsole("跳转被拦截（如未登录）")
            } catch {
                PTNSLogConsole("路由异常: \(error)")
            }
        }
    }
    
//    override func loadView() {
//        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//    }
    
    lazy var collectionView : PTCollectionView = {
        aaaaaaa = PTCollectionView(viewConfig: self.collectionViewConfig())
        aaaaaaa.registerSupplementaryView(classs: ["1111111":PTFusionHeader.self], kind: UICollectionView.elementKindSectionHeader)
//        aaaaaaa.registerSupplementaryView(classs: [PTTestFooter.ID:PTTestFooter.self,PTVersionFooter.ID:PTVersionFooter.self], kind: UICollectionView.elementKindSectionFooter)
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
            if let headerID = model.headerReuseID,let sectionModel = model.headerDataModel as? PTFusionCellModel {
                let baseHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerID, for: index)
                switch baseHeader {
                case let header as PTFusionHeader:
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
                default:
                    return nil
                }
            }
            return nil
        }
        aaaaaaa.footerInCollection = { kind,collectionView,model,index in
            if let footerID = model.footerReuseID {
                let baseFooter = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerID, for: index)
                switch baseFooter {
                case let footer as PTVersionFooter:
                    return footer
                case let footer as PTTestFooter:
                    return footer
                default:
                    return nil
                }
            }
            return nil
        }
        aaaaaaa.cellInCollection = { collectionView ,dataModel,indexPath in
            if let itemRow = dataModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTFusionCellModel {
                let baseCell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.reuseID, for: indexPath)
                switch baseCell {
                case let cell as PTFusionCell:
                    cell.cellModel = cellModel
                    cell.contentView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
                    return cell
                case let cell as PTFusionSwipeCell:
                    cell.cellModel = cellModel
                    cell.contentView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
                    return cell
                default:
                    return nil
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
            if let itemRow = sModel.rows?[indexPath.row], let cellModel = (itemRow.dataModel as? PTFusionCellModel) {
                if itemRow.title == .imageReview {
                    PTGCDManager.shared.runOnMain {
                        let model1 = PTMediaBrowserModel()
                        model1.imageURL = "https://i-blog.csdnimg.cn/blog_migrate/becd8bdd2845791b0f9b28ba58a27bac.jpeg"
                        model1.imageInfo = "56555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555551312333444444"
                        
                        let model2 = PTMediaBrowserModel()
                        model2.imageURL = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
                        model2.imageInfo = "123"

                        let model3 = PTMediaBrowserModel()
                        model3.imageURL = "https://imgservice.appsmartnet.com/bab1688/after/1770799498649A9178A4122E547D39B72A55A6950BE84_mmexport1749953776009 2.mp4"
                        model3.imageInfo = "MP4"

                        let model4 = PTMediaBrowserModel()
                        model4.imageURL = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"
                        model4.imageInfo = "GIF"
                        
                        let mediaConfig = PTMediaBrowserConfig.share
                        mediaConfig.dismissY = 200
                        mediaConfig.actionType = .All
                        mediaConfig.pageControlOption = .snake
                        mediaConfig.imageLongTapAction = true
                        mediaConfig.dynamicBackground = true
                        mediaConfig.pageControlShow = true
                        let browser = PTMediaBrowserController(mediaData: [model3,model1,model2,model4])
                        browser.mediasShow()
                    }
                } else if itemRow.title == .phoneCall {
                    PTGCDManager.shared.runOnMain {
                        PTPhoneBlock.callPhoneNumber(phoneNumber: "13800138000", call: { duration in
                        }, cancel: {
                            
                        }, canCall: { finish in
                            
                        })
                    }
                } else if itemRow.title == .cleanCache {
                    PTGCDManager.shared.runOnBackground(priority: .background) {
                        Task { @MainActor in
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
                    
                    Task { @MainActor in
                        let biometricsManager = PTBiometricsManager.shared
                            
                        // 1. 获取设备支持状态 (对应以前的 biologyStatusBlock)
                        // 现在变成了一个同步属性，直接读取即可，不用等回调！
                        let supportType = biometricsManager.currentBiometryStatus
                        PTNSLogConsole("设备支持的生物识别类型: \(supportType)")
                        // 2. 发起验证并等待结果 (对应以前的 biologyStart + biologyVerifyStatusBlock)
                        // 使用 Task 包装异步任务
                        PTNSLogConsole("开始验证...")
                        
                        // 使用 await 等待验证结果，代码会在这里暂停，直到用户验证完成才往下走
                        let verifyStatus = await biometricsManager.startAuthentication(alertTitle: "Test")
                        
                        // 拿到结果后直接处理
                        PTNSLogConsole("验证结果: \(verifyStatus)")
                        
                        // 你可以根据具体状态进行业务处理，例如：
                        if verifyStatus == .success {
                            PTNSLogConsole("✅ 验证成功，可以进入下一步了！")
                        } else if verifyStatus == .domainStateChanged {
                            PTNSLogConsole("⚠️ 警告：检测到用户录入了新的指纹/面容，需要重新登录！")
                        } else {
                            PTNSLogConsole("❌ 验证失败或取消")
                        }
                    }
                } else if itemRow.title == .videoEditor {
                    PTGCDManager.shared.runOnMain {
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
                            Task { @MainActor in
                                if result {
                                    PTAlertTipsViewController.tipsAlertShow(icon: .Heart)
                                } else {
                                    PTAlertTipsViewController.tipsAlertShow(icon: .Done)
                                }
                            }
                        }
                        vc.selectImageBlock = { result, isOriginal in
                            PTNSLogConsole("視頻選擇後:>>>>>>>>>>>>>\(result)")
                            if let resultFirst = result.first {
                                resultFirst.asset.convertPHAssetToAVAsset { progress in
                                    PTNSLogConsole("progress:>>>>>>>>>>>>>\(progress)")

                                } completion: { avAsset in
                                    if let getAv = avAsset {
                                        Task { @MainActor in
                                            let controller = PTVideoEditorToolsViewController(asset: resultFirst.asset,avAsset: getAv.asset)
                                            controller.videoEditorShow(vc: self)
                                            controller.onEditCompleteHandler = { url in
                                                PTAlertTipsViewController.tipsAlertShow(title:"我好了\(url)",icon: .Done)
                                            }
                                        }
                                    } else {
                                        Task { @MainActor in
                                            PTAlertTipsViewController.tipsAlertShow(title:"PT Alert Opps".localized(),subtitle:"PT Video editor get video error".localized(),icon: .Error)
                                        }
                                    }
                                }
                            } else {
                                Task { @MainActor in
                                    PTAlertTipsViewController.tipsAlertShow(title:"沒有選擇Video",icon: .Error)
                                }
                            }
                        }
                    }
                } else if itemRow.title == .sign {
                    PTGCDManager.shared.runOnMain {
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
                            
                            PTGCDManager.shared.delayOnMain(time: 5) {
                                newImage.removeFromSuperview()
                            }
                        }
                        sign.dismissBlock = {
                            
                        }
                    }
                } else if itemRow.title == .rotation {
                    PTGCDManager.shared.runOnMain {
                        PTRotationManager.shared.toggleOrientation()
                    }
    //                let r:Int = Int(arc4random_uniform(2))
    //                PTRotationManager.shared.rotation(to: PTRotationManager.Orientation.allCases[r])
                } else if itemRow.title == .osskit {
                    PTGCDManager.shared.runOnMain {
                        let vc = PTSpeechViewController()
                        self.navigationController?.pushViewController(vc)
                    }
                } else if itemRow.title == .share {
                    PTGCDManager.shared.runOnMain {
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
                    }
                } else if itemRow.title == .checkUpdate {
                    PTGCDManager.shared.runOnMain {
                        PTCheckUpdateFunction.share.checkTheVersionWithappid(appid: "6596749489", test: false, url: URL(string: shareURLString), version: "1.0.0", note: "123", force: false,alertType: .User)
                    }
                } else if itemRow.title == .route {
                    PTGCDManager.shared.runOnMain {
                        UIAlertController.baseActionSheet(title: "Route", titles: ["example"], otherBlock: { sheet,index,title in
                            switch index {
                            case 0:
                                PTGCDManager.shared.runOnMain(block: {
                                    self.routeFunction()
                                })
                            default:
                                break
                            }
                        })
                    }
                } else if itemRow.title == .alert {
                    PTGCDManager.shared.runOnMain {
                        UIAlertController.baseActionSheet(title: "AlertTips", titles: ["low","hight",String.feedbackAlert,"ActionSheet","CustomActionSheet","new","newActionSheet"], otherBlock: { sheet,index,title in
                            switch index {
                            case 0:
                                let tips = PTAlertTipsViewController(title: "Job Done!", subtitle: "WOW", icon: .Done)
                                PTAlertManager.show(tips)
                            case 1:
                                let tips = PTAlertTipsViewController(title: "Hola!", subtitle: "Que?", icon: .Error,style: .SupportVisionOS)
                                PTAlertManager.show(tips)
                            case 2:
                                UIAlertController.alertSendFeedBack { title, content in
                                    UIAlertController.gobal_drop(title: title,subTitle: content) {
                                        Task { @MainActor in
                                            UIAlertController.base_textfield_alertVC(okBtn: "PT Button comfirm".localized(), cancelBtn: "PT Button cancel".localized(), placeHolders: ["placeholder"], textFieldTexts: ["Test"], keyboardType: [.default], textFieldDelegate: self) { result in
                                                
                                            }
                                        }
                                    } notifiDismiss: {
                                        Task { @MainActor in
                                            UIAlertController.alertVC(title: "notifi消失之后", msg: "哦", cancel: "PT Button cancel".localized(), cancelBlock: {
                                            })
                                        }
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
                    }
                } else if itemRow.title == .loading {
                    PTGCDManager.shared.runOnMain {
                        UIAlertController.baseActionSheet(title: "Loading", titles: ["LoadingHub","CycleLoading","TextHub","ButtonHud","Progress1","Progress2","Progress3"], otherBlock: { sheet,index,title in
                            switch index {
                            case 0:
                                let hud = PTHudView()
                                hud.hudShow()
                                PTGCDManager.shared.delayOnMain(time: 5) {
                                    hud.hide { }
                                }
                            case 1:
                                let cycle = PTCycleLoadingView()
                                self.view.addSubviews([cycle])
                                cycle.snp.makeConstraints { make in
                                    make.size.equalTo(100)
                                    make.centerX.centerY.equalToSuperview()
                                }
                                cycle.startAnimation()
                                PTGCDManager.shared.delayOnMain(time: 5) {
                                    cycle.stopAnimation {
                                        Task { @MainActor in
                                            cycle.removeFromSuperview()
                                        }
                                    }
                                }
                            case 2:
                                PTGCDManager.shared.delayOnMain(time: 1, block: {
                                    PTProgressHUD.show(text: "12312312312312312312")
                                })
                            case 3:
                                PTGCDManager.shared.delayOnMain(time: 1, block: {
                                    PTProgressHUD.showLogo(text: "123123123123", image: UIImage(named: "DemoImage"))
                                })
                            case 4:
                                PTGCDManager.shared.delayOnMain(time: 1, block: {
                                    PTProgressHUD.showProgress(text:"111111111",progressMode: .determinateBar)
                                })
                            case 5:
                                PTGCDManager.shared.delayOnMain(time: 1, block: {
                                    PTProgressHUD.showProgress(text:"2222222222222",progressMode: .determinatePie)
                                })
                            case 6:
                                PTGCDManager.shared.delayOnMain(time: 1, block: {
                                    PTProgressHUD.showProgress(text:"333333333333",progressMode: .determinateRing)
                                })
                            default:
                                break
                            }
                        })
                    }
                } else if itemRow.title == .permission {
                    PTGCDManager.shared.runOnMain {
                        let permissionVC = PTPermissionViewController()
                        permissionVC.permissionShow(vc: self)
                        permissionVC.viewDismissBlock = {
                        }
                    }
                } else if itemRow.title == .permissionSetting {
                    PTGCDManager.shared.runOnMain {
                        let permissionVC = PTPermissionSettingViewController()
                        permissionVC.permissionShow(vc: self)
                    }
                } else if itemRow.title == .language {
                    PTGCDManager.shared.runOnMain {
                        UIAlertController.baseActionSheet(title: .language,subTitle: self.currentSelectedLanguage, titles: LanguageKey.allNames, otherBlock: { sheet,index,title in
                            self.currentSelectedLanguage = LanguageKey.allValues[index].desc
                            PTLanguage.share.language = LanguageKey.allValues[index].rawValue
                        })
                    }
                } else if itemRow.title == .darkMode {
                    PTGCDManager.shared.runOnMain {
                        let vc = PTDarkModeControl()
                        self.navigationController?.pushViewController(vc)
                    }
                } else if itemRow.title == .tipkit {
                    PTGCDManager.shared.runOnMain {
                        if #available(iOS 17.0, *) {
                            let vc = PTTipsDemoController()
                            self.navigationController?.pushViewController(vc)
                        }
                    }
                } else if itemRow.title == .document {
                    PTGCDManager.shared.runOnMain {
                        if #available(iOS 17.0, *) {
                            let vc = PTDocumentViewController()
                            self.navigationController?.pushViewController(vc)
                        }
                    }
                } else if itemRow.title == .svga {
    //                let vc = PTSVGAViewController()
    //                self.navigationController?.pushViewController(vc)
                } else if itemRow.title == .scanQR {
                    PTGCDManager.shared.runOnMain {
                        let vc = PTScanQRController(viewConfig: PTScanQRConfig())
                        vc.resultBlock = { result,error in
                            PTNSLogConsole("\(result)")
                        }
                        self.navigationController?.pushViewController(vc)
                    }
                } else if itemRow.title == .filtercamera {
                    PTGCDManager.shared.runOnMain {
                        let cameraConfig = PTCameraFilterConfig.share
                        cameraConfig.allowRecordVideo = true
                        let pointFont = UIFont.appfont(size: 20)

                        cameraConfig.backImage = "❌".emojiToImage(emojiFont: pointFont)
                        cameraConfig.flashImage = UIImage(.flashlight.offFill).withTintColor(.white)
                        cameraConfig.flashImageSelected = UIImage(.flashlight.onFill).withTintColor(.white)
                        
                        cameraConfig.filtersImageSelected = UIImage(.line._3HorizontalDecreaseCircleFill)
                        cameraConfig.filtersImage = UIImage(.line._3HorizontalDecreaseCircle)

                        let vc = PTFilterCameraViewController()
                        vc.onlyCamera = false
                        vc.modalPresentationStyle = .fullScreen
                        self.showDetailViewController(vc, sender: nil)
                    }
                } else if itemRow.title == .editimage {
                    PTGCDManager.shared.runOnMain {
                        let image = UIImage(named: "DemoImage")!
                        
                        let vc = PTEditImageViewController(readyEditImage: image)
                        vc.editFinishBlock = { ei ,editImageModel in
                            PHPhotoLibrary.pt.saveImageToAlbum(image: ei) { finish, asset in
                                if !finish {
                                    PTGCDManager.shared.runOnMain {
                                        PTAlertTipsViewController.tipsAlertShow(title:"Opps",subtitle: "保存图片失败",icon: .Error)
                                    }
                                }
                            }
                        }
                        let nav = PTBaseNavControl(rootViewController: vc)
                        nav.view.backgroundColor = .black
                        nav.modalPresentationStyle = .fullScreen
                        self.showDetailViewController(nav, sender: nil)
                    }
                } else if itemRow.title == .messageKit {
                    PTGCDManager.shared.runOnMain {
                        let vc = PTTestChatViewController()
                        self.navigationController?.pushViewController(vc)
                    }
                } else if itemRow.title == .BlurImageList {
                    PTGCDManager.shared.runOnMain {
                        let vc = PTImageListViewController()
                        self.navigationController?.pushViewController(vc)
                    }
                } else if itemRow.title == .mediaSelect {
                    PTGCDManager.shared.runOnMain {
                        PTMediaLibConfig.share.allowEditImage = true
                        PTMediaLibConfig.share.maxSelectCount = 9
                        PTMediaLibConfig.share.allowSelectImage = true
                        PTMediaLibConfig.share.allowSelectVideo = true
                        PTMediaLibConfig.share.allowMixSelect = true
                        PTMediaLibConfig.share.maxVideoSelectCount = 1
                        PTMediaLibConfig.share.allowEditVideo = true
                        PTMediaLibConfig.share.useCustomCamera = true

                        let vc = PTMediaLibViewController()
                        vc.mediaLibShow()
                        vc.selectImageBlock = { result,isOriginal in
                            if result.count > 0 {
                                PTNSLogConsole("\(result)")
                            } else {
                                PTAlertTipsViewController.tipsAlertShow(title:"失败",subtitle: "",icon: .Error)
                            }
                        }
                    }
                } else {
                    PTGCDManager.shared.runOnMain {
                        var sheetSize = [PTSheetSize]()
                        if itemRow.title == .StepperList || itemRow.title == .LivePhoto  || itemRow.title == .LivePhotoDisassemble || itemRow.title == .CycleBanner {
                            sheetSize = [.percent(0.9)]
                        } else {
                            sheetSize = [.percent(0.5)]
                        }
                        let vc = PTFuncDetailViewController(typeString: itemRow.title)
                        self.currentPresentToSheet(vc: vc,sizes: sheetSize)
                    }
                }
            }

        }
        aaaaaaa.headerRefreshTask = { [weak self] in
            PTGCDManager.shared.runOnMain {
                if #available(iOS 17, *) {
                    self?.collectionView.clearAllData { collectionview in
                        self?.collectionView.endRefresh()
                    }
                } else {
                    self?.collectionView.endRefresh()
                }
            }
        }
        aaaaaaa.footRefreshTask = {
            PTGCDManager.shared.delayOnMain(time: 5, block: {
                PTNSLogConsole("12312312312312312312312312312312312313")
                self.collectionView.endRefresh()
            })
        }
        aaaaaaa.emptyTap = { sender in
            if #available(iOS 17, *) {
                self.collectionView.showEmptyLoading()
                PTGCDManager.shared.delayOnMain(time: 1, block: {
                    self.collectionView.hideEmptyLoading(task: {
                        Task { @MainActor in
                            self.showCollectionViewData()
                        }
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
        let mask = PTRotationManager.shared.orientationMask
        PTNSLogConsole("【DEBUG】业务VC 报告权限: \(mask)")
        return mask
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
//    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
//        PTRotationManager.shared.orientationMask
//    }
    
    lazy var searchBar:PTSearchBar = {
        let searchBarConfig = PTSearchBarTextFieldClearButtonConfig()
        searchBarConfig.clearTopSpace = 2
        searchBarConfig.clearImage = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
        searchBarConfig.clearAction = {
            PTNSLogConsole("1231231231")
        }
        
        let searchBar = PTSearchBar()
        searchBar.clearConfig = searchBarConfig
        searchBar.searchBarImage = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
        return searchBar
    }()
    
    lazy var navTitleView:PTNavTitleContainer = {
        let view = PTNavTitleContainer()
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(32)
            make.centerY.equalToSuperview()
        }
        view.frame = CGRect(origin: .zero, size: .init(width: CGFloat.kSCREEN_WIDTH - 150, height: PTAppBaseConfig.share.bavTitleContainerHeight))
        view.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: CGFloat.kSCREEN_WIDTH - 150, height: PTAppBaseConfig.share.bavTitleContainerHeight))
        }
        return view
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let more = UIButton(type: .custom)
        more.setTitleColor(.random, for: .normal)
        more.setTitle("More", for: .normal)
        more.frame = CGRect(x: 0, y: 0, width: 54, height: 40)

        let popover = PTActionLayoutButton()
        popover.imageSize = CGSize(width: 15, height: 15)
        popover.layoutStyle = .leftImageRightTitle
        popover.midSpacing = 0
        popover.setTitleFont(.appfont(size: 12), state: .normal)
        popover.setTitleColor(.random, state: .normal)
        popover.setTitle("Popover", state: .normal)
        popover.setImage("http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg", state: .normal)
        popover.isUserInteractionEnabled = true
        
        let searchBarConfig = PTSearchBarTextFieldClearButtonConfig()
        searchBarConfig.clearTopSpace = 20
        searchBarConfig.clearImage = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
        searchBarConfig.clearAction = {
            PTNSLogConsole("1231231231")
        }
        
        setCustomTitleView(navTitleView)

        setCustomBackButtonView(popover,size: CGSizeMake(64, 34))
        popover.addActionHandlers(handler: { sender in
            PTNSLogConsole("123123123")
            self.sideMenuController?.revealMenu()
        })
        
        setCustomRightButtons(buttons: [more])
        
        var config = PTBadgeConfiguration()
        config.centerOffset = CGPointMake(20, 0)
        config.bgColor = .random
        config.canDragToDelete = true
        more.badgeConfig = config
        more.showBadge(style: .new, value: "我愛你", aniType: .none)
        
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

        more.addActionHandlers { sender in
            self.popover(popoverVC: popoverContent, popoverSize: CGSize(width: 100, height: 300), sender: sender, arrowDirections: .any)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTLaunchProfiler.shared.markFirstScreenRender()
        
        LaunchVisualizer.shared.showEntry()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        // Do any additional setup after loading the view.
                        
        registerScreenShotService()
        
        NotificationCenter.default.addObserver(self, selector: #selector(flashAd(notifi:)), name: NSNotification.Name.init(PLaunchAdDetailDisplayNotification), object: nil)
        
        collectionView.backgroundColor = .random
        
        let collectionInset:CGFloat = CGFloat.kTabbarHeight_Total
        let collectionInset_Top:CGFloat = CGFloat.kNavBarHeight_Total
        
        collectionView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentCollectionView.contentInset.top = collectionInset_Top
        collectionView.contentCollectionView.contentInset.bottom = collectionInset
        collectionView.contentCollectionView.verticalScrollIndicatorInsets.bottom = collectionInset

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.right.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
                
        if #unavailable(iOS 17.0) {
            PTGCDManager.shared.delayOnMain(time: 10) {
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
                    Task { @MainActor in
                        self.emptyReload()
                    }
                }
                
                PTGCDManager.shared.delayOnMain(time: 5) {
                    self.emptyReload()
                }
            }
        }
        
        inputValueSample(value: 15)
                
        @PTLockAtomic
        var json:[String:String]?
        json = ["A":"1"]
        PTNSLogConsole(">>>>>>>>>>>>>>>>>\(String(describing: json))")        
        
        PTGCDManager.shared.delayOnMain(time: 5, block: {
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
        })
        
        PTGCDManager.shared.delayOnMain(time: 5) {
            let vvvvv = PTDynamicNotificationView(showTimes: 3, canTap: true) { view in
                view.backgroundColor = .random
            }
            vvvvv.showNotification()
            vvvvv.hideHandler = {
            }
            
////            let items = ["苹果", "香蕉", "橘子", "葡萄", "西瓜"]
//                    
//            let pickerView = PTDatePickerView(style: PTPickerStyle.shared)
//            // 现代化的闭包回调，比 Delegate 更加方便
//            pickerView.show(title: "请选择水果", mode:.yw) { selectedDate, dateString in
//                PTNSLogConsole("回调的日期对象：\(selectedDate)")
//                PTNSLogConsole("格式化后的字符串：\(dateString)")
//            }
            
//            let users = [
//                UserModel(userId: "1001", userName: "張三"),
//                UserModel(userId: "1002", userName: "李四")
//            ]
//            
//            let pickerView = PTStringPickerView()
//            
//            // 传入一个二维数组
//            pickerView.show(title: "請選擇負責人", data: users) { result in
//                if let selectedUser = result.originalModel as? UserModel {
//                    PTNSLogConsole("選中的用戶 ID 是：\(selectedUser.userId)")
//                    PTNSLogConsole("選中的用戶 名字 是：\(selectedUser.userName)")
//                }
//            }
            let treeData: [RegionModel] = [
                RegionModel(id: "1", name: "廣東省", children: [
                    RegionModel(id: "1-1", name: "廣州市", children: [
                        RegionModel(id: "1-1-1", name: "天河區", children: []),
                        RegionModel(id: "1-1-2", name: "番禺區", children: [])
                    ]),
                    RegionModel(id: "1-2", name: "深圳市", children: []) // 注意：深圳這裡故意不給區
                ]),
                RegionModel(id: "2", name: "北京市", children: [
                    RegionModel(id: "2-1", name: "朝陽區", children: [])
                ])
            ]

            // 3. 調用極其簡單！
            let treePicker = PTTreePickerView()
            treePicker.show(title: "選擇地區", treeData: treeData) { results in
                
                PTNSLogConsole("你一共選了 \(results.count) 級地區")
                
                // 解析出最終選中的 ID
                let names = results.map { $0.value }.joined(separator: "-")
                let ids = results.compactMap { ($0.originalModel as? RegionModel)?.id }.joined(separator: "-")
                
                PTNSLogConsole("選中名稱: \(names)") // 輸出: 廣東省-廣州市-天河區
                PTNSLogConsole("選中 ID : \(ids)")   // 輸出: 1-1-1-1-1
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
        
        let buttonSize = CGSize.init(width: 60, height: 60)
        let buttonView = PTMenuSheetButtonView(baseSize: buttonSize, direction: .right, items: items)
        buttonView.backgroundColor = .randomColor
        buttonView.arrowWidth = 2
        buttonView.separatorWidth = 2
        buttonView.separatorInset = 12
        buttonView.layer.cornerRadius = 30
        buttonView.accessibilityIdentifier = "expandableButton"
        view.addSubview(buttonView)
        buttonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20) // 固定左侧
            make.centerY.equalToSuperview()
        }
        
        PTGCDManager.shared.delayOnMain(time: 10, block: {
            PTNSLogConsole(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\(String(describing: self.aaaaaaa.getSectionIndex(byHeaderID: "1111111")))")
        })
    }
    
    override func viewControllerOrientation(_ orientationMask: UIInterfaceOrientationMask) {
        PTNSLogConsole(">>>>>>>>>>>>>??>>>>>>>>>>>>>>>>>>>\(orientationMask)")
        PTGCDManager.shared.delayOnMain(time: 0.3) {
            self.aaaaaaa.reloadAllData()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // 1. 旋转开始前：可以隐蔽索引条或清理部分旧高度缓存
        collectionView.hideIndicator()
        collectionView.clearLayoutCaches()
        self.view.setNeedsLayout()
        // 2. 伴随系统的物理旋转动画一起过渡
        coordinator.animate(alongsideTransition: { [weak self] _ in
            // 这里可以放置需要与旋转动画同步变宽的自定义 UI 代码
            guard let self = self else { return }
            self.view.frame = CGRect(origin: .zero, size: size)
            self.view.layoutIfNeeded()
            self.collectionView.contentCollectionView.collectionViewLayout.invalidateLayout()
            
            self.view.backgroundColor = .blue
            self.collectionView.backgroundColor = .green
        }, completion: { [weak self] _ in
            // 🌟 3. 核心修复：当屏幕已经完全成功切换、动画彻底结束、宽度绝对稳定后，在这里触发重绘！
            // 此时 myCollectionView 内部的 layoutCache、heightCache 会在最新的横/竖屏宽度下进行按需精准重新计算，UI 绝不会再发生任何错位或挤压
            PTNSLogConsole("【旋转闭环】屏幕尺寸已稳定，最新宽度: \(size.width)")
            self?.collectionView.reloadAllData(animated: false)
            self?.collectionView.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.right.bottom.equalToSuperview()
                make.left.right.equalToSuperview()
            }
        })
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
        PTGCDManager.shared.delayOnMain(time: 2) {
            self.hideEmptyView {
                Task { @MainActor in
                    self.collectionView.clearAllData { cView in
                        Task { @MainActor in
                            self.showCollectionViewData()
                        }
                    }
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
            Task { @MainActor in
                self.collectionView.showCollectionDetail(collectionData: self.cSections())
            }
        }
    }
    
    func inputValueSample(@PTClampedPropertyWrapper(range:1...10) value:Int = 1) {
        PTNSLogConsole(">>>>>>>>>>>>>>>>>>>>>>>>>\(value)")
    }
}

// MARK: - ImagePickerControllerDelegate
extension PTFuncNameViewController {
    
    func saveVideoToAlbum(result:(@Sendable (_ finish:Bool)->Void)? = nil) {
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

extension PTProgressHUD {
    class func show(text:String) {
        let hud = PTProgressHUD.showOnWindow()
        hud?.titleFont = .appfont(size: 14)
        hud?.title = text
        hud?.titleColor = .white
        hud?.mode = .text
        hud?.dimBackground = false
        hud?.blurEffectStyle = .dark
        hud?.bezelColor = .black.withAlphaComponent(0.4)
        hud?.hide(animated: true, afterDelay: 1.5)
    }
    
    class func showLogo(text:String = "",image:UIImage? = nil) {
        let layoutView = PTLayoutButton()
        layoutView.layoutStyle = .leftImageRightTitle
        layoutView.midSpacing = 0
        var imageSize:CGFloat = 0
        if let image = image {
            layoutView.imageSize = CGSize(width: 24, height: 24)
            layoutView.normalImage = image
            imageSize = 24
        }
        layoutView.normalTitle = text
        layoutView.normalTitleFont = .appfont(size: 14)
        layoutView.normalTitleColor = .white
        var buttonW = UIView.sizeFor(string: text, font: layoutView.normalTitleFont,height: 24).width + imageSize + layoutView.midSpacing + 40
        let maxWidth = (CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2)
        var baseHeight:CGFloat = 56
        if buttonW >= maxWidth {
            buttonW = maxWidth
            let buttonHeight = UIView.sizeFor(string: text, font: layoutView.normalTitleFont,width: maxWidth).height
            if buttonHeight > 56 {
                baseHeight = buttonHeight + 32
            }
        }
        
        layoutView.frame = CGRectMake(0, 0, buttonW, baseHeight)
        layoutView.isUserInteractionEnabled = false
        
        let hud = PTProgressHUD.showOnWindow()
        hud?.mode = .customView(layoutView)
        hud?.blurEffectStyle = .dark
        hud?.bezelColor = .black.withAlphaComponent(0.6)
        hud?.hide(animated: true, afterDelay: 1.5)
    }

    class func showProgress(text:String = "",progressMode:Mode = .determinateBar) {
        let hud = PTProgressHUD.showOnWindow()
        hud?.titleFont = .appfont(size: 14)
        hud?.title = text
        hud?.titleColor = .white
        hud?.mode = progressMode
        hud?.blurEffectStyle = .dark
        hud?.bezelColor = .black.withAlphaComponent(0.4)
        hud?.progress = 0.5
        
        PTGCDManager.shared.delayOnMain(time: 2.5, block: {
            hud?.progress = 1
        })
    }
}
