//
//  PTFuncNameViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if SWIFT_PACKAGE
import PToolsDevice
#endif
import Photos
import Combine
#if SWIFT_PACKAGE
import PToolsSymbols
#endif
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif
import PooTools

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
    static let segmentPagingRegression = "SegmentedPagingRegression"
    static let segmentItemSeparator = "SegmentedItemSeparator"
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
        backgroundColor = .secondarySystemBackground
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
        return .solid(.systemBackground)
    }

    var cacheSize = ""
    
    lazy var currentSelectedLanguage : String = {
        let string = LanguageKey(rawValue: PTLanguage.share.language)?.desc ?? LanguageKey.ChineseHans.desc
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
    // English: Keep catalog filtering state separate from the stable Demo identity.
    // Español: Mantén el estado del filtro separado de la identidad estable del Demo.
    // 中文：将目录筛选状态与稳定 Demo 身份分开保存。
    private var demoSearchText = ""
    
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
            // English: PTDevice identity is a Sendable value and does not require a main-thread hop.
            // Español: La identidad de PTDevice es un valor Sendable y no necesita saltar al hilo principal.
            // 中文：PTDevice 身份是 Sendable 值，不需要切换到主线程获取。
            return PTDevice.current.identifier
        } else {
            return PTDevice.current.identifier
        }
    }
    
    // English: Build the catalog from stable Demo IDs instead of display strings.
    // Español: Construye el catálogo con IDs estables en lugar de textos visibles.
    // 中文：使用稳定 Demo ID 构建目录，不再使用展示文本作为身份。
    func cSections() -> [PTSection] {
        let keyword = demoSearchText.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
        return PTDemoRegistry.sections.compactMap { section -> PTSection? in
            let rows = section.demos.filter { descriptor in
                guard !keyword.isEmpty else { return true }
                let searchableText = [
                    descriptor.id.rawValue,
                    descriptor.moduleID,
                    descriptor.titleKey,
                    descriptor.category.displayTitle,
                    descriptor.tags.joined(separator: " ")
                ].joined(separator: " ").localizedLowercase
                return searchableText.contains(keyword)
            }.map { descriptor in
                let model = rowBaseModel(name: descriptor.titleKey)
                let row = PTRows(
                    title: descriptor.titleKey,
                    ID: PTFusionCell.ID,
                    diffId: descriptor.id.rawValue,
                    dataModel: model
                )
                row.cellClass = PTFusionCell.self
                return row
            }
            guard !rows.isEmpty else { return nil }
            let headerModel = PTFusionCellModel(diffIdentifier: "demo-section.\(section.id)")
            headerModel.name = section.title
            headerModel.cellFont = .appfont(size: 18, bold: true)
            headerModel.accessoryType = .NoneAccessoryView
            let result = PTSection(
                identifier: "demo-section.\(section.id)",
                headerTitle: section.title,
                headerID: "demo-header.\(section.id)",
                footerHeight: 44,
                headerHeight: 44,
                rows: rows,
                headerDataModel: headerModel
            )
            result.headerClass = PTFusionHeader.self
            result.footerClass = PTTestFooter.self
            return result
        }
    }


    var catalogCollectionView:PTCollectionView!
    
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
        emptyView.backgroundColor = .secondarySystemBackground
        emptyView.isUserInteractionEnabled = true
        emptyView.clipsToBounds = true
        
        
        
        let emptyReloadButton = UIButton(type: .custom)
        emptyReloadButton.addActionHandlers { _ in
            emptyView.backgroundColor = .systemGray5
            self.showCollectionViewData()
        }
        emptyView.addSubviews([emptyReloadButton])
        emptyReloadButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyConfig.customerView = emptyView
        emptyConfig.verticalOffSet = -120
//        emptyConfig.image = UIImage(named: "DemoImage")
//        emptyConfig.backgroundColor = .systemRed
//        emptyConfig.mainTitleAtt = """
//                \(wrap: .embedding("""
//                \("暂无数据",.foreground(.label),.font(.appfont(size: 14)),.paragraph(.alignment(.center)))
//                """))
//                """
//        emptyConfig.secondaryEmptyAtt = """
//                \(wrap: .embedding("""
//                \("请点击重试",.foreground(.secondaryLabel),.font(.appfont(size: 14)),.paragraph(.alignment(.center)))
//                """))
//                """
//        emptyConfig.buttonTitle = "點擊"
//        emptyConfig.buttonFont = .appfont(size: 14)
//        emptyConfig.buttonTextColor = .label
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
        catalogCollectionView = PTCollectionView(viewConfig: self.collectionViewConfig())
        catalogCollectionView.layoutSubviews()
        catalogCollectionView.decorationInCollectionView = { index,sectionModel in
            let backItemId = YDSWhiteDecorationView.ID
            let topSpace:CGFloat = 10
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: backItemId)
            backItem.contentInsets = NSDirectionalEdgeInsets.init(top: topSpace, leading: 12, bottom: 0, trailing: 12)
            return [backItem]
        }
        catalogCollectionView.decorationCustomLayoutInsetReset = { index,sectionModel in
            let topSpace:CGFloat = 10
            return NSDirectionalEdgeInsets.init(top: (sectionModel.headerHeight ?? CGFloat.leastNormalMagnitude) + topSpace, leading: 12, bottom: 0, trailing: 12)
        }
        catalogCollectionView.headerInCollection = { kind,collectionView,model,index in
            if let headerID = model.headerReuseID,let sectionModel = model.headerDataModel as? PTFusionCellModel {
                let baseHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerID, for: index)
                switch baseHeader {
                case let header as PTFusionHeader:
                    header.sectionModel = sectionModel
                    // English: Use the stable section identifier because display titles are localized.
                    // Español: Usa el identificador estable porque los títulos visibles se localizan.
                    // 中文：使用稳定的分组标识，避免本地化标题变化导致行为失效。
                    if headerID == "demo-header.network-connectivity" {
                        header.moreActionBlock = { text,sender in
                            PTNSLogConsole("点击了More")
                        }
                    } else if headerID == "demo-header.media-graphics" {
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
        catalogCollectionView.footerInCollection = { kind,collectionView,model,index in
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
        catalogCollectionView.cellInCollection = { collectionView ,dataModel,indexPath in
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
        catalogCollectionView.indexPathSwipe = { model,indxPath in
            return true
        }
        catalogCollectionView.swipeLeftHandler = { _, _, _ in
            let swipeAction = PTSwipeAction(name: "Action", image: nil, backgroundColor: .systemBlue) { _ in
                PTNSLogConsole("Left swipe action")
            }
            return [swipeAction]
        }
        catalogCollectionView.swipeRightHandler = { _, _, _ in
            let swipeAction = PTSwipeAction(name: "More", image: nil, backgroundColor: .systemGray) { _ in
                PTNSLogConsole("Right swipe action")
            }
            return [swipeAction]
        }
        catalogCollectionView.collectionDidSelect = { [weak self] _, section, indexPath in
            guard let self else { return }
            PTDemoSelectionCoordinator.select(section: section, indexPath: indexPath, from: self)
        }

        catalogCollectionView.headerRefreshTask = { [weak self] in
            PTGCDManager.shared.runOnMain {
                self?.collectionView.clearAllData { collectionview in
                    self?.collectionView.endRefresh()
                }
            }
        }
        catalogCollectionView.footRefreshTask = {
            PTGCDManager.shared.delayOnMain(time: 5, block: {
                self.collectionView.endRefresh()
            })
        }
        catalogCollectionView.emptyTap = { sender in
            self.collectionView.showEmptyLoading()
            PTGCDManager.shared.delayOnMain(time: 1, block: {
                self.collectionView.hideEmptyLoading(task: {
                    Task { @MainActor in
                        self.showCollectionViewData()
                    }
                })
            })
        }
        catalogCollectionView.emptyButtonTap = { _ in
            PTNSLogConsole("Empty state action")
        }
        catalogCollectionView.forceController = { cView,index,model in
            return PTBaseViewController()
        }
        catalogCollectionView.orthogonalDidScroll = { index,point in
            var scale = (abs(point.y) / 101)
            if scale > 1 {
                scale = 1
            }
            PTNavigationBarManager.shared.setAlpha(scale)
        }
        return catalogCollectionView
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
            PTNSLogConsole("Search clear action")
        }
        
        let searchBar = PTSearchBar()
        // English: Rebuild only the catalog snapshot when the user changes the search text.
        // Español: Reconstruye solo el snapshot del catálogo cuando cambia el texto de búsqueda.
        // 中文：搜索文本变化时只重建目录快照，不触碰 Demo 的业务状态。
        searchBar.textChangeHandler = { [weak self] text in
            self?.demoSearchText = text
            self?.collectionView.showCollectionDetail(collectionData: self?.cSections() ?? [])
        }
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
        more.setTitleColor(.label, for: .normal)
        more.setTitle("More", for: .normal)
        more.frame = CGRect(x: 0, y: 0, width: 54, height: 40)

        let popover = PTActionLayoutButton()
        popover.imageSize = CGSize(width: 15, height: 15)
        popover.layoutStyle = .leftImageRightTitle
        popover.midSpacing = 0
        popover.setTitleFont(.appfont(size: 12), state: .normal)
        popover.setTitleColor(.label, state: .normal)
        popover.setTitle("Popover", state: .normal)
        popover.setImage("http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg", state: .normal)
        popover.isUserInteractionEnabled = true
        
        let searchBarConfig = PTSearchBarTextFieldClearButtonConfig()
        searchBarConfig.clearTopSpace = 20
        searchBarConfig.clearImage = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
        searchBarConfig.clearAction = {
            PTNSLogConsole("Popover search clear action")
        }
        
        setCustomTitleView(navTitleView)

        setCustomBackButtonView(popover,size: CGSizeMake(64, 34))
        popover.addActionHandlers(handler: { sender in
            PTNSLogConsole("Reveal side menu")
            self.sideMenuController?.revealMenu()
        })
        
        setCustomRightButtons(buttons: [more])
        
        var config = PTBadgeConfiguration()
        config.centerOffset = CGPointMake(20, 0)
        config.bgColor = .systemBlue
        config.canDragToDelete = true
        more.badgeConfig = config
        more.showBadge(style: .new, value: "我愛你", aniType: .none)
        
        let popoverContent = PTBaseViewController(hideBaseNavBar: true)
        
        let popoverButton = UIButton(type: .custom)
        popoverButton.backgroundColor = .secondarySystemBackground
        
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
        testButton.backgroundColor = .tertiarySystemBackground
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
        
        collectionView.backgroundColor = .systemBackground
        
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

        // English: Populate the initial snapshot so every registered Demo is visible without an extra tap.
        // Español: Carga el snapshot inicial para mostrar todos los Demos registrados sin otro toque.
        // 中文：主动填充首个快照，让所有已登记 Demo 无需额外点击即可显示。
        showCollectionViewData()
                
        if vcEmpty {
            let emptyConfig = PTEmptyDataViewConfig()
            emptyConfig.buttonTitle = "點我刷新"
            emptyConfig.image = UIImage(.exclamationmark.triangle)
            emptyConfig.mainTitleAtt = """
                \(wrap: .embedding("""
                \("PT Alert Opps".localized(),.foreground(.label),.font(.appfont(size: 20,bold: true)),.paragraph(.alignment(.center)))
                """))
                """
            emptyConfig.secondaryEmptyAtt = """
                \(wrap: .embedding("""
                \("PT Photo picker empty media".localized(),.foreground(.secondaryLabel),.font(.appfont(size: 18)),.paragraph(.alignment(.center)))
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
                item5.title = "Example item"
                
                let iKnowItem = PTWhatsNewsIKnowItem()
                iKnowItem.privacy = "Privacy"
                iKnowItem.privacyURL = "https://www.qq.com"
                
                let view = PTWhatsNewsViewController(titleItem: PTWhatsNewsTitleItem(),iKnowItem: iKnowItem,newsItem: [item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2,item2])
                view.whatsNewsShow(vc: self)
            }
        })
        
        PTGCDManager.shared.delayOnMain(time: 5) {
            let vvvvv = PTDynamicNotificationView(showTimes: 3, canTap: true) { view in
                view.backgroundColor = .systemBackground
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
        buttonView.backgroundColor = .secondarySystemBackground
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
        

       pt_observerLanguage(didChanged: {
            PTNSLogConsole("Language changed")
        })
    }
    
    override func viewControllerOrientation(_ orientationMask: UIInterfaceOrientationMask) {
        PTNSLogConsole(">>>>>>>>>>>>>??>>>>>>>>>>>>>>>>>>>\(orientationMask)")
        PTGCDManager.shared.delayOnMain(time: 0.3) {
            self.catalogCollectionView.reloadAllData()
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
        guard let values = notifi.object as? [String: Any] else { return }
        for value in values.values {
            guard let string = value as? String, string.isURL() else { continue }
            let viewController = PTBaseWebViewController(showString: string)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
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
