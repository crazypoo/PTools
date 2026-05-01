//
//  PTCollectionView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import AttributedString
#if POOTOOLS_SCROLLREFRESH
import MJRefresh
#endif
import Photos
import SwifterSwift

private let kPTCollectionIndexViewAnimationDuration: Double = 0.25

public typealias PTCollectionCallback = @MainActor (UICollectionView) -> Void

//MARK: CollectionView展示的样式类型
@objc public enum PTCollectionViewType: Int {
    case Normal,Gird,WaterFall,Custom,Horizontal,HorizontalLayoutSystem,Tag
}

//MARK: Collection展示的Section底部样式类型
@objc public enum PTCollectionViewDecorationItemsType: Int {
    case NoItems,Custom,Normal,Corner
}

@objc public class PTDecorationItemModel: NSObject {
    ///Collection展示的Section底部Class
    open var decorationClass: AnyClass!
    ///Collection展示的Section底部ID
    open var decorationID: String!
}

@objc public enum PTCollectionEmptyViewSet: Int {
    ///17之前用第三方17之後包括17用系統
    case Auto
    ///用第三方
    case ThirtyParty
    ///17之後包括17用系統
    case System
}

///ReusableView回调
public typealias PTReusableViewHandler = @MainActor (_ kind: String,_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath: IndexPath) -> UICollectionReusableView?

///Cell设置
public typealias PTCellInCollectionHandler = @MainActor (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> UICollectionViewCell?

///Cell点击事件
public typealias PTCellDidSelectedHandler = @MainActor (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> Void

///Cell将要
public typealias PTCellDisplayHandler = @MainActor (_ collectionView:UICollectionView,_ cell:UICollectionViewCell,_ sectionModel:PTSection,_ indexPath:IndexPath) -> Void

///CollectionView的Scroll回调
public typealias PTCollectionViewScrollHandler = @MainActor (_ collectionView:UICollectionView) -> Void

///CollectionView的Swipe回调
public typealias PTCollectionViewSwipeHandler = @MainActor (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> [PTSwipeAction]

public typealias PTCollectionViewCanSwipeHandler = @MainActor (_ sectionModel:PTSection,_ indexPath:IndexPath) -> Bool

public typealias PTDecorationInCollectionHandler = @MainActor (_ index:Int,_ sectionModel:PTSection) -> [NSCollectionLayoutDecorationItem]

public typealias PTViewInDecorationResetHandler = @MainActor (_ collectionView: UICollectionView, _ view: UICollectionReusableView, _ elementKind: String, _ indexPath: IndexPath,_ sectionModel: PTSection) -> Void

//MARK: Collection展示的基本配置参数设置
@objcMembers
public class PTCollectionViewConfig: NSObject {
    ///CollectionView上下滑动条
    open var showsVerticalScrollIndicator: Bool = true
    ///CollectionView水平滑动条
    open var showsHorizontalScrollIndicator: Bool = true
    ///CollectionView展示的样式类型
    open var viewType: PTCollectionViewType = .Normal
    ///每行多少个(仅在瀑布流和Gird样式中使用)
    open var rowCount: Int = 3
    ///item高度
    open var itemHeight: CGFloat = PTAppBaseConfig.share.baseCellHeight
    ///item宽度(Horizontal下使用)
    open var itemWidth: CGFloat = 100
    ///item起始坐标X
    open var itemOriginalX: CGFloat = 0
    ///item的展示距离顶部的高度
    open var contentTopSpace: CGFloat = 0
    ///item的展示距离底部的高度
    open var contentBottomSpace: CGFloat = 0
    ///每个item的间隔(左右)
    open var cellLeadingSpace: CGFloat = 0
    ///每个item的间隔(上下)
    open var cellTrailingSpace: CGFloat = 0
    ///如果是Tagview,則這是內容的左右間距
    open var tagCellContentSpace: CGFloat = 20
    ///是否开启头部刷新
    open var topRefresh: Bool = false
#if POOTOOLS_SCROLLREFRESH
    ///是否开启底部刷新
    open var footerRefresh: Bool = false
    open var footerRefreshTextColor: UIColor = .white
    open var footerRefreshTextFont: UIFont = .appfont(size: 14)
    open var footerRefreshIdle: String = ""
    open var footerRefreshPulling: String = "鬆開即可刷新"
    open var footerRefreshRefreshing: String = "正在刷新中"
    open var footerRefreshWillRefresh: String = "即將刷新"
    open var footerRefreshNoMoreData: String = "已經全部加載完畢"
    open var triggerAutomaticallyRefreshPercent: CGFloat = 0.5
    open var isAutomaticallyRefresh: Bool = true
    open var ignoredScrollViewContentInsetBottom:CGFloat = 0
#endif
    ///section偏移
    open var sectionEdges: NSDirectionalEdgeInsets = .zero
    ///头部长度偏移
    open var headerWidthOffset: CGFloat = 0
    ///底部长度偏移
    open var footerWidthOffset: CGFloat = 0
    ///是否开启空数据展示
    open var showEmptyAlert: Bool = false
    ///空数据展示参数设置
    open var emptyViewConfig: PTEmptyDataViewConfig?
    ///空數據展示類型
    open var emptyShowType: PTCollectionEmptyViewSet = .Auto
    ///Collection展示的Section底部样式类型
    open var decorationItemsType: PTCollectionViewDecorationItemsType = .NoItems
    ///Collection展示的Section底部样式偏移
    open var decorationItemsEdges: NSDirectionalEdgeInsets = .zero
    ///Collection展示的Section底部Model
    open var decorationModel: [PTDecorationItemModel]?
    ///Collection展示的Section底部样式偏移
    open var collectionViewBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous
    ///是否开启自定义Header和Footer
    open var customReuseViews: Bool = false
    ///首是否开启刷新动画
    open var refreshWithoutAnimation: Bool = false
    ///索引
    open var sideIndexTitles: [String]?
    ///索引设置
    open var indexConfig: PTCollectionIndexViewConfiguration?
    ///移动Item
    open var canMoveItem: Bool = false
    
    ///限制滑动方向
    open var alwaysBounceHorizontal: Bool = false
    open var alwaysBounceVertical: Bool = true
    open var contentOffSetZero: Bool = false
    
    /*
     For Photos
     */
    open var viewForPhoto: Bool = false
    open var previewImageSize: CGSize = CGSizeMake(105, 105)
    
    /// 是否固定 Section Header 在屏幕顶部
    open var pinHeaderToVisibleBounds: Bool = false
    /// 是否固定 Section Footer 在屏幕底部
    open var pinFooterToVisibleBounds: Bool = false
}

public class PTCollectionIndexViewConfiguration: NSObject {
    ///索引格子大小
    open var itemSize: CGSize = CGSize(width: 15, height: 15)
    ///索引上下间隔
    open var itemSpacing: CGFloat = 0
    ///索引格子背景颜色
    open var itemBackgroundColor: UIColor = UIColor.clear
    ///索引字体颜色
    open var itemTextColor: UIColor = UIColor.darkText
    ///索引选中背景颜色
    open var itemSelectedBackgroundColor: UIColor = UIColor.lightGray
    ///索引选中字体颜色
    open var itemSelectedTextColor: UIColor = UIColor.white
    ///根据这个数值来绘制displayLayer
    open var indicatorRadius: CGFloat = 30
    ///放大索引背景颜色
    open var indicatorBackgroundColor: UIColor = UIColor.lightGray
    ///放大索引字体颜色
    open var indicatorTextColor: UIColor = UIColor.white
    ///索引背景颜色
    open var indexViewBackgroundColor: UIColor = .clear
    ///索引字体
    open var indexViewFont: UIFont = .appfont(size: 12)
    ///放大索引字体,这个属性只会使用字体名字
    open var indexViewHudFont: UIFont = .appfont(size: 18)
    ///索引顶部偏移
    open var containerTopOffset:CGFloat = 0
    ///索引底部偏移
    open var containerBottomOffset:CGFloat = 0
    ///索引右边偏移
    open var indexContainerRightOffset:CGFloat = 0
}

open class PTBaseCollectionView: UICollectionView {
    
    public var contentOffSetZero: Bool = false
    
    open override var contentOffset: CGPoint {
        didSet {
            // 始终锁定垂直方向
            if contentOffSetZero, contentOffset.y != 0 {
                setContentOffset(CGPoint(x: contentOffset.x, y: 0), animated: false)
            }
        }
    }
}

final class PTIndexItemView: UILabel {
    
    var index: Int = 0
    
    func update(selected: Bool, config: PTCollectionIndexViewConfiguration) {
        backgroundColor = selected ? config.itemSelectedBackgroundColor : config.itemBackgroundColor
        textColor = selected ? config.itemSelectedTextColor : config.itemTextColor
    }
}

struct LayoutCacheKey: Hashable {
    let section: Int
    let width: CGFloat
    let version: Int   // 👈 新增
}

struct HeightCacheKey: Hashable {
    let id: String
    let width: CGFloat
}

private struct DiffThreshold {
    static let smallItem = 200      // 完整 diff
    static let mediumItem = 500     // 只 section diff
    static let largeItem = 1000     // 直接 reload
}

private struct WaterfallCache {
    var columnHeights: [CGFloat] = []
    var items: [NSCollectionLayoutGroupCustomItem] = []
    var contentHeight: CGFloat = 0
}

private struct WaterfallCacheKey: Hashable {
    let section: Int
    let width: CGFloat
    let version: Int
}

public enum PTDiffAnimation {
    case none
    case fade
    case right
    case left
    case top
    case bottom
    case automatic
    case `default`
}

public enum CornerPosition {
    case single, top, middle, bottom
}

// 1. 定义一个基于 NSCache 的强类型缓存
public class PTLRUCache<Key: Hashable, Value: AnyObject> {
    private let cache = NSCache<WrappedKey, Value>()
    
    public init(countLimit: Int = 1000) {
        cache.countLimit = countLimit // 超过限制时自动淘汰最旧数据
    }
    
    public func set(_ value: Value, forKey key: Key) {
        cache.setObject(value, forKey: WrappedKey(key))
    }
    
    public func get(forKey key: Key) -> Value? {
        return cache.object(forKey: WrappedKey(key))
    }
    
    public func removeAll() {
        cache.removeAllObjects()
    }
    
    // 用于包装 Hashable 的 Key 以适配 NSCache
    private class WrappedKey: NSObject {
        let key: Key
        init(_ key: Key) { self.key = key }
        override var hash: Int { return key.hashValue }
        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? WrappedKey else { return false }
            return key == other.key
        }
    }
    
    public func remove(forKey key: Key) {
        cache.removeObject(forKey: WrappedKey(key))
    }
}

// 写在文件顶部或合适的扩展中
public typealias PTDataSource = UICollectionViewDiffableDataSource<PTSection, PTRows>
public typealias PTSnapshot = NSDiffableDataSourceSnapshot<PTSection, PTRows>

//MARK: 界面展示
@objcMembers
public class PTCollectionView: UIView {
    
    // 声明一个节流任务
    private var scrollDebounceWorkItem: DispatchWorkItem?
    /// 原生 Diffable 数据源 👈 新增
    private var diffableDataSource: PTDataSource!
    ///Photos
    let imageManager = PHCachingImageManager()
    var photoAssets: [PHAsset] = []
    
    ///索引
    fileprivate lazy var indicator: UIView = {
        let indicatorRadius = viewConfig.indexConfig?.indicatorRadius ?? 0
        let indicator = UIView()
        indicator.frame = CGRect(x: 0, y: 0, width: indicatorRadius * 3, height: indicatorRadius * 2)
        indicator.backgroundColor = viewConfig.indexConfig?.indicatorBackgroundColor ?? .clear
        indicator.alpha = 0
        indicator.addSubview(bigTextLabel)
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = indicator.frame
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 2.414 * indicatorRadius, y: indicatorRadius))
        path.addLine(to: CGPoint(x: 1.707 * indicatorRadius, y: 1.707 * indicatorRadius))
        path.addArc(withCenter: CGPoint(x: indicatorRadius, y: indicatorRadius), radius: indicatorRadius, startAngle: 0.25 * CGFloat.pi, endAngle: 1.75 * CGFloat.pi, clockwise: true)
        path.close()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.red.cgColor
        maskLayer.backgroundColor = UIColor.clear.cgColor
        indicator.layer.mask = maskLayer
        return indicator
    }()
    
    /// CATextLayer的内容默认是上对齐的，不如用label方便
    fileprivate lazy var bigTextLabel: UILabel = {
        let indicatorRadius = viewConfig.indexConfig?.indicatorRadius ?? 0
        let label = UILabel()
        label.frame = CGRect(x: 0, y: 0, width: indicatorRadius * 2, height: indicatorRadius * 2)
        label.backgroundColor = viewConfig.indexConfig?.indicatorBackgroundColor ?? .clear
        label.font = UIFont.appCustomFont(size: ceil(indicatorRadius * 1.414),customFont: viewConfig.indexConfig?.indexViewHudFont.fontName ?? UIFont.appfont(size: 18).fontName)
        label.textAlignment = .center
        label.layer.cornerRadius = indicatorRadius
        label.layer.masksToBounds = true
        label.textColor = viewConfig.indexConfig?.indicatorTextColor ?? .clear
        return label
    }()
    
    fileprivate var layerTopSpacing: CGFloat {
        let count = CGFloat(viewConfig.sideIndexTitles?.count ?? 0)
        let floorValue = bounds.height - count * (viewConfig.indexConfig?.itemSize.height ?? 0) - (viewConfig.indexConfig?.itemSpacing ?? 0) * (count - 1)
        return floor(floorValue) / 2
    }
    
    fileprivate var isTouched: Bool = false
    
    fileprivate var touchedIndex: Int = 0 {
        didSet {
            if touchedIndex != oldValue {
                impactFeedbackGenerator.prepare() // 👈 预先唤醒硬件
                impactFeedbackGenerator.impactOccurred()
            }
        }
    }
    
    // 懒加载震动反馈
    fileprivate lazy var impactFeedbackGenerator : UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()
    
    // 使用 NSKeyValueObservation 替代手动 KVO
    private var lastUpdateTime: CFTimeInterval = 0
    private let scrollThrottleInterval: CFTimeInterval = 0.1 // 10fps
    
    private var heightCache = PTLRUCache<HeightCacheKey, NSNumber>(countLimit: 1000)
    private var waterfallCache: [WaterfallCacheKey: WaterfallCache] = [:]
    private var layoutCache =  PTLRUCache<LayoutCacheKey, NSCollectionLayoutSection>(countLimit: 100)
    
    private var fallbackLayouts: [Int: NSCollectionLayoutSection] = [:]
    
    fileprivate lazy var collectionView : PTBaseCollectionView = {
        let view = PTBaseCollectionView(frame: .zero, collectionViewLayout: self.comboLayout())
        view.backgroundColor = .clear
        view.delegate = self
        view.isUserInteractionEnabled = true
        view.isPrefetchingEnabled = true
        // 1. 在初始化 collectionView 时启用 Drag & Drop
        view.dragInteractionEnabled = self.viewConfig.canMoveItem
        view.dragDelegate = self
        view.dropDelegate = self
        view.contentOffSetZero = self.viewConfig.contentOffSetZero
        switch self.viewConfig.viewType {
        case .Normal,.Gird,.WaterFall,.Tag:
            view.alwaysBounceHorizontal = false
            view.alwaysBounceVertical = true
        case .Custom:
            view.alwaysBounceHorizontal = self.viewConfig.alwaysBounceHorizontal
            view.alwaysBounceVertical = self.viewConfig.alwaysBounceVertical
        case .HorizontalLayoutSystem,.Horizontal:
            view.alwaysBounceHorizontal = true
            view.alwaysBounceVertical = false
        }
        view.showsVerticalScrollIndicator = self.viewConfig.showsVerticalScrollIndicator
        view.showsHorizontalScrollIndicator = self.viewConfig.showsHorizontalScrollIndicator
        if self.viewConfig.topRefresh {
            view.refreshControl = self.refreshControl
        }
        view.registerSupplementaryView(classs: [NSStringFromClass(PTBaseCollectionReusableView.self):PTBaseCollectionReusableView.self], kind: UICollectionView.elementKindSectionHeader)
        view.registerSupplementaryView(classs: [NSStringFromClass(PTBaseCollectionReusableView.self):PTBaseCollectionReusableView.self], kind: UICollectionView.elementKindSectionFooter)
#if POOTOOLS_SCROLLREFRESH
        if self.viewConfig.footerRefresh {
            let footerRefresh = PTRefreshAutoStateFooter(refreshingBlock: { [weak self] in
                self?.footRefreshTask?()
            })
            footerRefresh.setTitle(self.viewConfig.footerRefreshIdle, for: .idle)
            footerRefresh.setTitle(self.viewConfig.footerRefreshPulling, for: .pulling)
            footerRefresh.setTitle(self.viewConfig.footerRefreshRefreshing, for: .refreshing)
            footerRefresh.setTitle(self.viewConfig.footerRefreshWillRefresh, for: .willRefresh)
            footerRefresh.setTitle(self.viewConfig.footerRefreshNoMoreData, for: .noMoreData)
            footerRefresh.stateLabel?.font = self.viewConfig.footerRefreshTextFont
            footerRefresh.stateLabel?.textColor = self.viewConfig.footerRefreshTextColor
            footerRefresh.triggerAutomaticallyRefreshPercent = self.viewConfig.triggerAutomaticallyRefreshPercent
            footerRefresh.isAutomaticallyRefresh = self.viewConfig.isAutomaticallyRefresh
            footerRefresh.ignoredScrollViewContentInsetBottom = self.viewConfig.ignoredScrollViewContentInsetBottom
            view.mj_footer = footerRefresh
        }
#endif
        if self.viewConfig.viewForPhoto {
            view.prefetchDataSource = self
        }
        return view
    }()
    
    fileprivate lazy var indexContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = viewConfig.indexConfig?.indexViewBackgroundColor
        return view
    }()
    
    let topSpacer = UIView()
    let bottomSpacer = UIView()

    fileprivate lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = viewConfig.indexConfig?.itemSpacing ?? 0
        return stack
    }()
    
    private(set) lazy var refreshControl:UIRefreshControl = {
        let control = UIRefreshControl()
        control.addRefreshHandlers { [weak self] sender in
            PTGCDManager.gcdMain {
                self?.headerRefreshTask?(sender)
            }
        }
        return control
    }()
    
    //MARK: Cell datasource handler
    open var headerInCollection: PTReusableViewHandler?
    open var footerInCollection: PTReusableViewHandler?
    @MainActor open var cellInCollection: PTCellInCollectionHandler?
    
    //MARK: Cell delegate handler
    open var collectionDidSelect: PTCellDidSelectedHandler?
    open var collectionWillDisplay: PTCellDisplayHandler?
    open var collectionDidEndDisplay: PTCellDisplayHandler?
    
    //MARK: UIScrollView call back
    open var collectionWillBeginDecelerating: PTCollectionViewScrollHandler?
    open var collectionViewDidScroll: PTCollectionViewScrollHandler?
    open var collectionWillBeginDragging: PTCollectionViewScrollHandler?
    open var collectionDidEndDragging: ((UICollectionView,Bool) -> Void)?
    open var collectionDidEndDecelerating: PTCollectionViewScrollHandler?
    open var collectionDidEndScrollingAnimation: PTCollectionViewScrollHandler?
    open var collectionDidScrolltoTop: PTCollectionViewScrollHandler?
    open var collectionWillEndDraging: ((_ scrollView: UIScrollView, _ velocity: CGPoint, _ targetContentOffset: UnsafeMutablePointer<CGPoint>) -> Void)?
    ///头部刷新事件
    open var headerRefreshTask: ((UIRefreshControl) -> Void)?
    ///底部刷新事件
    open var footRefreshTask: PTActionTask?
    
    //MARK: Cell layout (仅仅限于在瀑布流或者自定义的情况下使用)
    open var waterFallLayout: ((Int, AnyObject) -> CGFloat)?
    open var customerLayout: ((Int,PTSection) -> NSCollectionLayoutGroup)?
    open var customerReuseViews: ((Int,PTSection) -> [NSCollectionLayoutBoundarySupplementaryItem])?

    ///当空数据View展示的时候,点击回调
    open var emptyTap: ((UIView?) -> Void)?
    open var emptyButtonTap: ((UIView?) -> Void)?

    ///CollectionView的DecorationItem囘調(自定義模式下使用)
    open var decorationInCollectionView: PTDecorationInCollectionHandler?
    
    ///CollectionView的DecorationItem重新設置囘調(自定義模式下使用)
    open var decorationViewReset: PTViewInDecorationResetHandler?
    
    ///CollectionView的DecorationItem内的Item与Header&Footer重新設置囘調(自定義模式下使用)
    open var decorationCustomLayoutInsetReset: ((Int,PTSection) -> NSDirectionalEdgeInsets)?
    
    public var contentCollectionView:UICollectionView { collectionView }
    public var collectionSectionDatas:[PTSection] { diffableDataSource.snapshot().sectionIdentifiers }
    
    //MARK: Swipe handler
    open var indexPathSwipe: PTCollectionViewCanSwipeHandler?
    open var swipeLeftHandler :PTCollectionViewSwipeHandler?
    open var swipeRightHandler: PTCollectionViewSwipeHandler?
    
    open var itemMoveTo: ((_ cView:UICollectionView,_ move:IndexPath,_ to:IndexPath) -> Void)?
    
    open var forceController: ((_ collectionView:UICollectionView,_ indexPath:IndexPath,_ sectionModel:PTSection) -> UIViewController?)?
    open var forceActions: ((_ collectionView:UICollectionView,_ indexPath:IndexPath,_ sectionModel:PTSection) -> [UIAction]?)?

    public var viewConfig: PTCollectionViewConfig! {
        didSet {
            if (viewConfig.sideIndexTitles?.count ?? 0) > 0 && viewConfig.indexConfig != nil {
                if collectionView.superview == nil {
                    addSubview(collectionView)
                    collectionView.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                }
                setIndexViews()
            }
            
            if viewConfig.canMoveItem {
                self.contentCollectionView.allowsMoveItem()
            }
        }
    }
    
    private var registeredCells: Set<String> = []
    private var registeredSupplementary: Set<String> = []
    
    //MARK: 界面展示
    public init(viewConfig: PTCollectionViewConfig!) {
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        self.viewConfig = viewConfig
        self.registerClassCells(classs: ["CELL":UICollectionViewCell.self])

        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        collectionView.allowsMoveItem()

        setIndexViews()
        
        // 👈 内存警告通知监听，防止 OOM 崩溃
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        setupDiffableDataSource()
        setiOS17EmptyDataView()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didReceiveMemoryWarning() {
        PTGCDManager.gcdMain {
            // 清理缓存以释放内存
            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            self.waterfallCache.removeAll()
            self.fallbackLayouts.removeAll() // 👈 新增
        }
    }
    
    ///展示界面
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension PTCollectionView {
    
    private func setupDiffableDataSource() {
        // 1. 配置 Cell
        diffableDataSource = PTDataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, rowModel) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            
            let snapshot = self.diffableDataSource.snapshot()
            
            guard indexPath.section < snapshot.sectionIdentifiers.count else {
                // 越界说明系统正在执行消失动画，直接返回一个基础占位 Cell
                return collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath)
            }

            let sectionModel = snapshot.sectionIdentifiers[indexPath.section]
            
            // 沿用你写好的自定义回调逻辑
            if let cell = self.cellInCollection?(collectionView, sectionModel, indexPath) {
                if let swipeCell = cell as? PTBaseSwipeCell {
                    if let indexPathSwipe = self.indexPathSwipe {
                        let swipe = indexPathSwipe(sectionModel, indexPath)
                        swipeCell.cellCanSwipe = swipe
                        if swipe {
                            if let actions = self.swipeRightHandler?(collectionView, sectionModel, indexPath) {
                                swipeCell.configureRightActions(actions)
                            } else if let actions = self.swipeLeftHandler?(collectionView, sectionModel, indexPath) {
                                swipeCell.configureLeftActions(actions)
                            }
                        }
                    }
                    return swipeCell
                }
                return cell
            }
            return collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath)
        }
        
        // 2. 配置 Header 和 Footer
        diffableDataSource.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) -> UICollectionReusableView? in
            guard let self = self else { return nil }
            
            let snapshot = self.diffableDataSource.snapshot()
            
            guard indexPath.section < snapshot.sectionIdentifiers.count else {
                // 越界说明 Header/Footer 正在执行消失动画，返回基础占位 View 避免系统拿不到 View 而崩溃
                return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(PTBaseCollectionReusableView.self), for: indexPath)
            }
            let sectionModel = snapshot.sectionIdentifiers[indexPath.section]
            
            if kind == UICollectionView.elementKindSectionHeader,
               !(sectionModel.headerReuseID ?? "").stringIsEmpty(),
               let headerHeight = sectionModel.headerHeight,
               headerHeight != CGFloat.leastNormalMagnitude,
               let headerReusableView = headerInCollection?(kind,collectionView,sectionModel,indexPath) {
                return headerReusableView
            } else if kind == UICollectionView.elementKindSectionFooter,
                      !(sectionModel.footerReuseID ?? "").stringIsEmpty(),
                      let footerHeight = sectionModel.footerHeight,
                      footerHeight != CGFloat.leastNormalMagnitude,
                      let footerReusableView = footerInCollection?(kind,collectionView,sectionModel,indexPath) {
                return footerReusableView
            }
            
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(PTBaseCollectionReusableView.self), for: indexPath)
        }
        
        // 🌟 新增：初始化时给 DataSource 应用一个空数据的 Snapshot
        // 这会让 UICollectionView 知道当前数据是干净的，并且能激活相关代理和空状态
        let initialSnapshot = PTSnapshot()
        diffableDataSource.apply(initialSnapshot, animatingDifferences: false)
    }
}

//MARK: Get something
extension PTCollectionView {
#if POOTOOLS_PAGINGCONTROL
    public func segmentScrolView() -> UIScrollView {
        collectionView
    }
#endif
    
    public func visibleCells() -> [UICollectionViewCell] {
        collectionView.visibleCells
    }
}

//MARK: MoveItem
extension PTCollectionView {
    public func scrolToItem(indexPath:IndexPath,position:UICollectionView.ScrollPosition) {
        collectionView.scrollToItem(at: indexPath, at: position, animated: true)
    }
    
    public func mtSelectItem(indexPath:IndexPath,animated:Bool,scrollPosition:UICollectionView.ScrollPosition) {
        collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
    }
}

extension PTCollectionView {
    public func cornerPosition(row: Int, count: Int) -> CornerPosition {
        if count == 1 { return .single }
        if row == 0 { return .top }
        if row == count - 1 { return .bottom }
        return .middle
    }
}

//MARK: UICollectionViewDelegate
extension PTCollectionView:UICollectionViewDelegate,UIScrollViewDelegate {
    // 💡 辅助方法：统一从单一数据源安全获取 Section 模型
    private func getSafeSectionModel(at index: Int) -> PTSection? {
        let snapshot = self.diffableDataSource.snapshot()
        guard index >= 0, index < snapshot.sectionIdentifiers.count else {
            return nil
        }
        return snapshot.sectionIdentifiers[index]
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        collectionDidSelect?(collectionView,itemSec,indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        collectionDidEndDisplay?(collectionView, cell, itemSec, indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        collectionWillDisplay?(collectionView, cell, itemSec, indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        decorationViewReset?(collectionView,view,elementKind,indexPath,itemSec)
    }
        
    // MARK: 移动cell结束
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        itemMoveTo?(collectionView,sourceIndexPath,destinationIndexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return nil }
        if let preView = self.forceController?(collectionView,indexPath,itemSec),let actions = self.forceActions?(collectionView,indexPath,itemSec) {
            return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: {
                return preView
            }, actionProvider: { suggestedActions in
                return UIMenu(title: "", children: actions)
            })
        } else {
            return nil
        }
    }
            
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return } // 👈 优化类型转换
        collectionWillBeginDecelerating?(cv)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return } // 👈 优化类型转换
        collectionViewDidScroll?(cv)
        throttleScrollUpdate()
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return } // 👈 优化类型转换
        collectionWillBeginDragging?(cv)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let cv = scrollView as? UICollectionView else { return } // 👈 优化类型转换
        collectionDidEndDragging?(cv,decelerate)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let cv = scrollView as? UICollectionView else { return } // 👈 优化类型转换
        collectionWillEndDraging?(cv,velocity,targetContentOffset)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return } // 👈 优化类型转换
        collectionDidEndDecelerating?(cv)
        hideIndicator()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return } // 👈 优化类型转换
        collectionDidEndScrollingAnimation?(cv)
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return } // 👈 优化类型转换
        collectionDidScrolltoTop?(cv)
    }
}

// 2. 实现 Drag 和 Drop 协议
extension PTCollectionView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    // MARK: - Drag Delegate
    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard viewConfig.canMoveItem else { return [] }
        
        let snapshot = diffableDataSource.snapshot()
        guard indexPath.section < snapshot.sectionIdentifiers.count else { return [] }
        let sectionModel = snapshot.sectionIdentifiers[indexPath.section]
        
        guard let rows = sectionModel.rows, indexPath.item < rows.count else { return [] }
        let rowModel = rows[indexPath.item]
        
        // 提供数据载体
        let itemProvider = NSItemProvider(object: rowModel.diffId as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = rowModel // 将模型存在 localObject 中方便当前 App 内部获取
        
        return [dragItem]
    }
    
    // MARK: - Drop Delegate
    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard viewConfig.canMoveItem else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        // 如果是 App 内部的拖放，允许移动
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else { return }
        
        var snapshot = diffableDataSource.snapshot()
        
        // 1. 提取源和目标模型
        guard let sourceItem = diffableDataSource.itemIdentifier(for: sourceIndexPath),
              let destItem = diffableDataSource.itemIdentifier(for: destinationIndexPath) else { return }
        
        // 🌟 2. 核心操作：同步内存中的真实数据 (修改 class 内部的 rows 数组)
        let sourceSection = snapshot.sectionIdentifiers[sourceIndexPath.section]
        let destSection = snapshot.sectionIdentifiers[destinationIndexPath.section]
        
        // a. 从源 Section 的数组中拔出数据
        if let indexToRemove = sourceSection.rows?.firstIndex(of: sourceItem) {
            sourceSection.rows?.remove(at: indexToRemove)
        }
        
        // b. 插入到目标 Section 的数组中
        if destSection.rows == nil { destSection.rows = [] }
        let insertIndex = min(destinationIndexPath.item, destSection.rows?.count ?? 0)
        destSection.rows?.insert(sourceItem, at: insertIndex)
        
        // 🌟 3. 精准清理被影响的缓存，防止布局错乱
        self.layoutCache.removeAll()
        self.heightCache.remove(forKey: HeightCacheKey(id: sourceItem.diffId, width: collectionView.bounds.width))
        
        sourceSection.layoutVersion += 1
        destSection.layoutVersion += 1
        
        if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
            self.clearWaterfallCache(section: sourceIndexPath.section)
            self.clearWaterfallCache(section: destinationIndexPath.section)
        }
        
        // 🌟 4. 更新快照 (驱动 UI 动画)
        if destinationIndexPath >= sourceIndexPath {
            snapshot.moveItem(sourceItem, afterItem: destItem)
        } else {
            snapshot.moveItem(sourceItem, beforeItem: destItem)
        }
        
        // 5. 应用动画，并抛出回调给外部
        let animated = !self.viewConfig.refreshWithoutAnimation
        diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self = self else { return }
            self.itemMoveTo?(collectionView, sourceIndexPath, destinationIndexPath)
        }
        
        // 执行系统的放置动画
        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
    }
}

//MARK: For Photos
extension PTCollectionView:UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard viewConfig.viewForPhoto, !photoAssets.isEmpty else { return }
        let assets = indexPaths.compactMap { idx -> PHAsset? in
            let item = idx.item
            return (item >= 0 && item < photoAssets.count) ? photoAssets[item] : nil
        }
        if !assets.isEmpty {
            imageManager.startCachingImages(for: assets, targetSize: self.viewConfig.previewImageSize, contentMode: .aspectFill, options: nil)
        }
    }
        
    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        guard viewConfig.viewForPhoto, !photoAssets.isEmpty else { return }
        let assets = indexPaths.compactMap { idx -> PHAsset? in
            let item = idx.item
            return (item >= 0 && item < photoAssets.count) ? photoAssets[item] : nil
        }
        if !assets.isEmpty {
            imageManager.stopCachingImages(for: assets, targetSize: self.viewConfig.previewImageSize, contentMode: .aspectFill, options: nil)
        }
    }
}

//MARK: 索引设置
private extension PTCollectionView {
    func setIndexViews() {
        indicator.removeFromSuperview()
        indexContainerView.removeFromSuperview()
        guard (viewConfig.sideIndexTitles?.count ?? 0) > 0 else { return }
        
        addSubviews([indexContainerView,indicator])
        
        indexContainerView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(viewConfig.indexConfig?.indexContainerRightOffset ?? 0)
            make.top.equalToSuperview().inset(viewConfig.indexConfig?.containerTopOffset ?? 0)
            make.bottom.equalToSuperview().inset(viewConfig.indexConfig?.containerBottomOffset ?? 0)
            make.width.equalTo(viewConfig.indexConfig?.itemSize.width ?? 20)
        }
        
        setupIndexUI()
        addIndexGesture()
    }

    private func addIndexGesture() {
        // 👈 添加 [weak self] 防止内存泄漏
        let pan = UIPanGestureRecognizer { [weak self] sender in
            guard let self = self, let gesture = sender as? UIPanGestureRecognizer else { return }
            let point = gesture.location(in: self.stackView)
            
            for case let view as PTIndexItemView in self.stackView.arrangedSubviews {
                
                if view.frame.contains(point) {
                    self.selectIndex(view.index)
                    break
                }
            }
            
            if gesture.state == .ended || gesture.state == .cancelled {
                self.hideIndicator()
            }
        }
        indexContainerView.addGestureRecognizer(pan)
    }
        
    private func selectIndex(_ index: Int) {
        
        guard let config = viewConfig.indexConfig else { return }
        
        for case let view as PTIndexItemView in stackView.arrangedSubviews {
            view.update(selected: view.index == index, config: config)
        }
        
        showIndicator(at: index)
        scrollToSection(index)
    }
    
    private func scrollToSection(_ section: Int) {
        let indexPath = IndexPath(item: 0, section: section)
        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        isTouched = false
    }
    
    private func showIndicator(at index: Int) {
        guard let titles = viewConfig.sideIndexTitles,
              index < titles.count,
              let config = viewConfig.indexConfig else { return }
        
        bigTextLabel.text = titles[index]
        setIndicatorCenter(t: index, config: config)
    }

    func setIndicatorCenter(t index: Int,config:PTCollectionIndexViewConfiguration,alpha:CGFloat = 1) {
        for case let targetView as PTIndexItemView in stackView.arrangedSubviews {
            if targetView.index == index {
                // 🟢 转换坐标（关键）
                let targetFrame = targetView.convert(targetView.bounds, to: self)
                
                // 🟢 计算中心点（让 indicator 对齐 index item）
                let centerY = targetFrame.midY
                
                let indicatorX = bounds.width - indicator.bounds.width / 2 - (config.itemSize.width)
                
                UIView.animate(withDuration: 0.15) {
                    self.indicator.center = CGPoint(x: indicatorX, y: centerY)
                }
                
                indicator.alpha = alpha
                break
            }
        }
    }
    
    private func setupIndexUI() {
        
        guard let titles = viewConfig.sideIndexTitles,
              let config = viewConfig.indexConfig else { return }
        
        indexContainerView.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackView.spacing = config.itemSpacing
        
        topSpacer.backgroundColor = .clear
        bottomSpacer.backgroundColor = .clear

        topSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        bottomSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)

        topSpacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        bottomSpacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        stackView.addArrangedSubview(topSpacer)

        for (i, title) in titles.enumerated() {
            let label = PTIndexItemView()
            label.index = i
            label.text = title
            label.textAlignment = .center
            label.font = config.indexViewFont
            label.layer.cornerRadius = config.itemSize.height / 2
            label.clipsToBounds = true
            label.isUserInteractionEnabled = true
            label.snp.makeConstraints { make in
                make.size.equalTo(config.itemSize)
            }
            
            // 👈 添加 [weak self] 防止内存泄漏
            let tap = UITapGestureRecognizer { [weak self] sender in
                guard let self = self else { return }
                self.isTouched = true
                self.selectIndex(label.index)
            }
            label.addGestureRecognizer(tap)
            stackView.addArrangedSubview(label)
        }
        
        stackView.addArrangedSubview(bottomSpacer)

        setIndicatorCenter(t: 0, config: config,alpha: 0)
    }
    
    func hideIndicator() {
        UIView.animate(withDuration: 0.2) {
            self.indicator.alpha = 0
        }
    }
}

//MARK: 触摸事件
extension PTCollectionView {
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        if view == self {
            if let indexConfig = viewConfig.indexConfig {
                let rect = CGRect(x: self.frame.size.width - indexConfig.itemSize.width, y: layerTopSpacing, width: indexConfig.itemSize.width, height: self.frame.size.height - layerTopSpacing * 2)
                if rect.contains(point) {
                    return self
                } else {
                    return nil
                }
            }
            return view
        } else {
            return view
        }
    }
}

//MARK: KVO相关
extension PTCollectionView {
    private func handleScrollUpdate() {
        guard let section = findCurrentSectionFast(),
              let config = viewConfig.indexConfig else { return }
        
        for case let view as PTIndexItemView in stackView.arrangedSubviews {
            view.update(selected: view.index == section, config: config)
        }
        
        showIndicator(at: section)
    }
    
    private func findCurrentSectionFast() -> Int? {
        let indexPaths = collectionView.indexPathsForVisibleItems
        guard !indexPaths.isEmpty else { return nil }
        
        return indexPaths.min()?.section
    }
    
    private func throttleScrollUpdate() {
        guard isTouched == false else { return }
        
        // 取消上一次还没执行的任务
        scrollDebounceWorkItem?.cancel()
        
        // 创建新任务
        let workItem = DispatchWorkItem { [weak self] in
            self?.handleScrollUpdate()
        }
        scrollDebounceWorkItem = workItem
        
        // 延迟 0.05 秒执行（50ms的防抖，既能跟手，又能极大减少计算频次）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }
}

//MARK: Waterfall相关
extension PTCollectionView {
    private func cachedHeight(for indexPath: IndexPath,
                              model: AnyObject,
                              calculator: (Int, AnyObject) -> CGFloat) -> CGFloat {
        guard let row = diffableDataSource.itemIdentifier(for: indexPath) else {
            // 如果因为某些原因（比如正在执行删除动画）拿不到模型，就走实时计算兜底
            return calculator(indexPath.section, model)
        }

        let key = HeightCacheKey(
            id: row.diffId,                 // 👈 稳定ID
            width: collectionView.bounds.width
        )
        
       
        if let cache = heightCache.get(forKey: key) {
            return cache.doubleValue
        }
        
        let height = calculator(indexPath.section, model)
        heightCache.set(NSNumber(floatLiteral: height), forKey: key)
        return height
    }
}

//MARK: Cell 相关
extension PTCollectionView  {
    private func autoRegisterIfNeeded(sections: [PTSection]) {
        
        for section in sections {
            
            // 🟢 header
            if let headerClass = section.headerClass as? PTSupplementaryRegisterable.Type {
                registerSupplementaryIfNeeded(headerClass)
            }
            
            // 🟢 footer
            if let footerClass = section.footerClass as? PTSupplementaryRegisterable.Type {
                registerSupplementaryIfNeeded(footerClass)
            }
            
            // 🟢 cells
            section.rows?.forEach { row in
                if let cellClass = row.cellClass as? PTCellRegisterable.Type {
                    registerCellIfNeeded(cellClass)
                }
            }
        }
    }
    
    private func registerCellIfNeeded(_ cellClass: PTCellRegisterable.Type) {
        
        let reuseID = cellClass.reuseID
        
        guard !registeredCells.contains(reuseID) else { return }
        
        collectionView.register(cellClass as? UICollectionViewCell.Type, forCellWithReuseIdentifier: reuseID)
        
        registeredCells.insert(reuseID)
    }
    
    private func registerSupplementaryIfNeeded(_ viewClass: PTSupplementaryRegisterable.Type) {
        
        let reuseID = viewClass.reuseID
        
        guard !registeredSupplementary.contains(reuseID) else { return }
        
        collectionView.register(viewClass as? UICollectionReusableView.Type,
                                forSupplementaryViewOfKind: viewClass.kind,
                                withReuseIdentifier: reuseID)
        
        registeredSupplementary.insert(reuseID)
    }
}

//MARK: DIFF
extension PTCollectionView {

    private func markSectionDirty(_ section: Int) {
        let snapshot = self.diffableDataSource.snapshot()
        guard section >= 0, section < snapshot.sectionIdentifiers.count else { return }
        snapshot.sectionIdentifiers[section].layoutVersion += 1
    }
            
    @MainActor public func showCollectionDetail(collectionData:[PTSection],
                                                animated: Bool = true,
                                                animation: PTDiffAnimation = .default,
                                                finishTask:PTCollectionCallback? = nil) {
        // 1. 自动注册 Cell
        self.autoRegisterIfNeeded(sections: collectionData)
        
        // 2. 备份数据，供你其他的布局业务使用
        self.layoutCache.removeAll()
        self.heightCache.removeAll()
        self.waterfallCache.removeAll()
        self.fallbackLayouts.removeAll()
        
        // 3. 构建全新的 Snapshot
        var snapshot = PTSnapshot()
        snapshot.appendSections(collectionData)
        
        for section in collectionData {
            if let rows = section.rows, !rows.isEmpty {
                snapshot.appendItems(rows, toSection: section)
            }
        }
        
        if !collectionData.isEmpty {
            if #available(iOS 17.0, *) {
                PTUnavailableManager.hideUnavailableView(in: self)
            } else {
                // 让第三方库立即感知数据变化并隐藏
                self.collectionView.reloadEmptyDataSet()
            }
        }
        // 4. 交给苹果底层去 Diff 和执行动画！✨
        diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self = self else { return }
            self.setiOS17EmptyDataView()
            finishTask?(self.collectionView)
        }
    }
    
    /// 插入 Rows
    public func clearAllData(finishTask:PTCollectionCallback? = nil) {
        self.layoutCache.removeAll()
        self.heightCache.removeAll()
        self.waterfallCache.removeAll()
        self.fallbackLayouts.removeAll() // 👈 新增
        
        var snapshot = PTSnapshot()
        snapshot.deleteAllItems() // 一键清空快照
        
        let animated = !self.viewConfig.refreshWithoutAnimation
        diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self = self else { return }
            self.setiOS17EmptyDataView()
            finishTask?(self.collectionView)
        }
    }

    public func insertRows(_ rows:[PTRows],section:Int,completion:PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            var snapshot = self.diffableDataSource.snapshot()
            guard section >= 0, section < snapshot.sectionIdentifiers.count else {
                completion?()
                return
            }
            
            let sectionModel = snapshot.sectionIdentifiers[section]
            if sectionModel.rows == nil { sectionModel.rows = [] }
            sectionModel.rows?.append(contentsOf: rows)
            
            // 🌟 4. 清理受影响的缓存
            self.layoutCache.removeAll()
            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.clearWaterfallCache(section: section)
            }
            sectionModel.layoutVersion += 1 // 标记脏数据强制重绘
            
            // 🌟 5. 告诉 DiffableDataSource 把新数据加进去！
            snapshot.appendItems(rows, toSection: sectionModel)
            
            let animated = !self.viewConfig.refreshWithoutAnimation
            self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                self.setiOS17EmptyDataView()
                completion?()
            }
        }
    }
    
    /// 插入 Section
    public func insertSection(_ sections:[PTSection], afterIndex:Int? = nil,completion:PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            guard !sections.isEmpty else {
                completion?()
                return
            }
            
            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            
            var snapshot = self.diffableDataSource.snapshot()
            var insertIndex = snapshot.sectionIdentifiers.count

            // 处理插入位置
            if let index = afterIndex, index < snapshot.sectionIdentifiers.count {
                insertIndex = index + 1
                let anchorSection = snapshot.sectionIdentifiers[index]
                snapshot.insertSections(sections, afterSection: anchorSection)
            } else {
                snapshot.appendSections(sections)
            }

            // 把新 section 里面的 rows 装入 Snapshot，并清理缓存
            for i in 0..<sections.count {
                let targetIndex = insertIndex + i
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.clearWaterfallCache(section: targetIndex)
                }
                sections[i].layoutVersion += 1
                if let rows = sections[i].rows, !rows.isEmpty {
                    snapshot.appendItems(rows, toSection: sections[i])
                }
            }

            let animated = !self.viewConfig.refreshWithoutAnimation
            self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                self.setiOS17EmptyDataView()
                completion?()
            }
        }
    }

    /// 删除 Rows
    public func deleteRows(_ rows: [PTRows], from section: Int, completion: PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            var snapshot = self.diffableDataSource.snapshot()
            guard section >= 0, section < snapshot.sectionIdentifiers.count else {
                completion?()
                return
            }

            self.layoutCache.removeAll()
            
            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.clearWaterfallCache(section: section)
            }

            let sectionModel = snapshot.sectionIdentifiers[section]
            sectionModel.layoutVersion += 1
            sectionModel.rows?.removeAll(where: { rows.contains($0) })

            // 从快照中删除 UI 元素
            snapshot.deleteItems(rows)

            if sectionModel.rows?.isEmpty ?? true {
                snapshot.deleteSections([sectionModel])
            }
            
            let animated = !self.viewConfig.refreshWithoutAnimation
            self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                self.setiOS17EmptyDataView()
                completion?()
            }
        }
    }
    
    /// 跨 Section 批量删除 Rows
    public func deleteSectionsRows(_ rowsMap: [Int: [PTRows]], completion: PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            
            var allRowsToDelete: [PTRows] = []
            var sectionsToDelete: [PTSection] = [] // 🌟 【新增】：收集因为删光了 Row 而变成空的 Section
            var snapshot = self.diffableDataSource.snapshot()
            
            for (sectionIndex, rows) in rowsMap {
                guard sectionIndex >= 0, sectionIndex < snapshot.sectionIdentifiers.count else { continue }
                
                let sectionModel = snapshot.sectionIdentifiers[sectionIndex]
                
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.clearWaterfallCache(section: sectionIndex)
                }
                sectionModel.layoutVersion += 1
                
                sectionModel.rows?.removeAll(where: { rows.contains($0) })
                allRowsToDelete.append(contentsOf: rows)
                
                if sectionModel.rows?.isEmpty ?? true {
                    sectionsToDelete.append(sectionModel)
                }
            }

            guard !allRowsToDelete.isEmpty else {
                completion?()
                return
            }

            snapshot.deleteItems(allRowsToDelete)
            
            if !sectionsToDelete.isEmpty {
                snapshot.deleteSections(sectionsToDelete)
            }

            let animated = !self.viewConfig.refreshWithoutAnimation
            self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
                self.setiOS17EmptyDataView()
                completion?()
            }
        }
    }
    
    /// 删除 Sections
    public func deleteSections(_ sections: [PTSection], completion: PTActionTask? = nil) {
        // 注意：这里我们统一使用 gcdMain。因为 Snapshot 的获取和 Apply 必须在主线程执行！
        // 之前在后台线程(gcdGobal)操作很容易引发数据竞争和崩溃。
        PTGCDManager.gcdMain {
            var snapshot = self.diffableDataSource.snapshot()
                        
            // 利用我们之前说的优雅反查机制，清理缓存
            for sectionModel in sections {
                if let index = snapshot.indexOfSection(sectionModel) {
                    if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                        self.clearWaterfallCache(section: index)
                    }
                    sectionModel.layoutVersion += 1
                }
            }

            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            
            snapshot.deleteSections(sections)
            
            let animated = !self.viewConfig.refreshWithoutAnimation
            self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                self.setiOS17EmptyDataView()
                completion?()
            }
        }
    }
}

//MARK: Layout
extension PTCollectionView {
    fileprivate func comboLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { section, environment in
            self.generateSection(section: section,environment:environment)
        }
        switch viewConfig.decorationItemsType {
        case .Custom:
            viewConfig.decorationModel?.forEach { value in
                layout.register(value.decorationClass, forDecorationViewOfKind: value.decorationID)
            }
        case .Corner:
            layout.register(PTBaseDecorationView_Corner.self, forDecorationViewOfKind: PTBaseDecorationView_Corner.ID)
        case .Normal:
            layout.register(PTBaseDecorationView.self, forDecorationViewOfKind: PTBaseDecorationView.ID)
        default:break
        }
        return layout
    }
    
    private func buildSection(sectionModel: PTSection,sectionIndex: NSInteger, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        // 🌟 修复核心 1：千万不要用 frame.size.width！
        // DiffableDataSource 提前计算布局时，frame 可能为 0。使用 environment 获取真实的可用宽度。
        let screenWidth = environment.container.contentSize.width

        let behavior = viewConfig.collectionViewBehavior
        let group: NSCollectionLayoutGroup
        
        switch viewConfig.viewType {
        case .Gird:
            group = UICollectionView.girdCollectionLayout(
                data: sectionModel.rows,
                groupWidth: screenWidth,
                itemHeight: viewConfig.itemHeight,
                cellRowCount: viewConfig.rowCount,
                originalX: viewConfig.itemOriginalX,
                topContentSpace: viewConfig.contentTopSpace,
                bottomContentSpace: viewConfig.contentBottomSpace,
                cellLeadingSpace: viewConfig.cellLeadingSpace,
                cellTrailingSpace: viewConfig.cellTrailingSpace
            )
        case .Normal:
            group = UICollectionView.girdCollectionLayout(
                data: sectionModel.rows,
                groupWidth: screenWidth,
                itemHeight: viewConfig.itemHeight,
                cellRowCount: 1,
                originalX: viewConfig.itemOriginalX,
                topContentSpace: viewConfig.contentTopSpace,
                bottomContentSpace: viewConfig.contentBottomSpace,
                cellTrailingSpace: viewConfig.cellTrailingSpace
            )
        case .WaterFall:
            if let waterFall = waterFallLayout {
                let result = buildWaterfallItems(
                    section: sectionIndex,
                    data: sectionModel.rows?.compactMap { $0.dataModel } ?? [],
                    width: screenWidth,
                    config: viewConfig,
                    version: sectionModel.layoutVersion,
                    itemHeight: waterFall
                )

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(screenWidth),
                    heightDimension: .absolute(result.height)
                )

                group = NSCollectionLayoutGroup.custom(layoutSize: groupSize) { _ in
                    result.items
                }
            } else {
                group = oneSquareGroup()
            }
        case .Horizontal:
            group = UICollectionView.horizontalLayout(
                data: sectionModel.rows,
                itemOriginalX: viewConfig.itemOriginalX,
                itemWidth: viewConfig.itemWidth,
                itemHeight: viewConfig.itemHeight,
                topContentSpace: viewConfig.contentTopSpace,
                bottomContentSpace: viewConfig.contentBottomSpace,
                itemLeadingSpace: viewConfig.cellLeadingSpace
            )
        case .HorizontalLayoutSystem:
            group = UICollectionView.horizontalLayoutSystem(
                data: sectionModel.rows,
                itemOriginalX: viewConfig.itemOriginalX,
                itemWidth: viewConfig.itemWidth,
                itemHeight: viewConfig.itemHeight,
                topContentSpace: viewConfig.contentTopSpace,
                bottomContentSpace: viewConfig.contentBottomSpace,
                itemLeadingSpace: viewConfig.cellLeadingSpace
            )
        case .Tag:
            let tagDatas = sectionModel.rows?.compactMap { $0.dataModel }
            if let tags = tagDatas as? [PTTagLayoutModel] {
                group = UICollectionView.tagShowLayout(
                    data: tags,
                    screenWidth: self.frame.width,
                    itemOriginalX: viewConfig.itemOriginalX,
                    itemHeight: viewConfig.itemHeight,
                    topContentSpace: viewConfig.contentTopSpace,
                    bottomContentSpace: viewConfig.contentBottomSpace,
                    itemLeadingSpace: viewConfig.cellLeadingSpace,
                    itemTrailingSpace: viewConfig.cellTrailingSpace,
                    itemContentSpace: viewConfig.tagCellContentSpace
                )
            } else {
                group = oneSquareGroup()
            }
        case .Custom:
            if let customerLayout {
                group = customerLayout(sectionIndex, sectionModel)
            } else {
                group = oneSquareGroup()
            }
        }
        
        var sectionInsets = viewConfig.sectionEdges
        let sectionWidth: CGFloat
        switch viewConfig.decorationItemsType {
        case .Normal,.Corner,.NoItems:
            sectionInsets = NSDirectionalEdgeInsets(top: (sectionModel.headerHeight ?? .leastNormalMagnitude) + viewConfig.contentTopSpace + viewConfig.decorationItemsEdges.top, leading: sectionInsets.leading, bottom: viewConfig.contentBottomSpace, trailing: sectionInsets.trailing)
        default:
            sectionInsets = decorationCustomLayoutInsetReset?(sectionIndex, sectionModel) ?? .zero
        }
        
        switch viewConfig.decorationItemsType {
        case .Normal,.Corner:
            sectionWidth = viewConfig.decorationItemsEdges.leading + viewConfig.decorationItemsEdges.trailing
        case .NoItems,.Custom:
            sectionWidth = 0
        }
                
        let laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets
        
        if viewConfig.customReuseViews,let items = customerReuseViews?(sectionIndex,sectionModel) {
            laySection.boundarySupplementaryItems = items
        } else {
            laySection.boundarySupplementaryItems = generateSupplementaryItems(section: sectionIndex, sectionModel: sectionModel, sectionWidth: sectionWidth, screenWidth: screenWidth)
        }
        
        laySection.decorationItems = generateDecorationItems(section: sectionIndex, sectionModel: sectionModel)
        return laySection
    }
    
    fileprivate func generateSection(section: NSInteger, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        
        let snapshot = self.diffableDataSource.snapshot()
        
        // 🌟 核心修复 1：防越界保护！
        // 防止在执行删除动画时，Layout 请求了已经被我们从 mSections 中删除的旧索引
        guard section >= 0, section < snapshot.sectionIdentifiers.count else {
            if let fallback = fallbackLayouts[section] {
                return fallback
            }
            return NSCollectionLayoutSection(group: oneSquareGroup())
        }

        let sectionModel = snapshot.sectionIdentifiers[section]
        let key = LayoutCacheKey(section: section,
                                 width: environment.container.contentSize.width,
                                 version: sectionModel.layoutVersion)
        if let cache = layoutCache.get(forKey: key) {
            return cache
        }

        let sectionLayout = buildSection(sectionModel: sectionModel,sectionIndex: section, environment: environment)
        layoutCache.set(sectionLayout, forKey: key)
        
        fallbackLayouts[section] = sectionLayout
        
        return sectionLayout
    }
    
    private func oneSquareGroup() -> NSCollectionLayoutGroup {
        PTNSLogConsole("Warning: CustomerLayout is nil. Fallback to 1x1 group.")
        let size = NSCollectionLayoutSize(widthDimension: .absolute(1), heightDimension: .absolute(1))
        return NSCollectionLayoutGroup(layoutSize: size)
    }

    private func generateSupplementaryItems(section: NSInteger, sectionModel: PTSection, sectionWidth: CGFloat, screenWidth: CGFloat) -> [NSCollectionLayoutBoundarySupplementaryItem] {
        var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
        
        if !(sectionModel.headerReuseID ?? "").stringIsEmpty() {
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .absolute(screenWidth - viewConfig.headerWidthOffset - sectionWidth),
                heightDimension: .absolute(sectionModel.headerHeight ?? .leastNormalMagnitude)
            )
            
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topTrailing,
                absoluteOffset: CGPoint(x: -viewConfig.decorationItemsEdges.leading, y: viewConfig.decorationItemsEdges.top + (sectionModel.headerHeight ?? .leastNormalMagnitude))
            )
            headerItem.contentInsets = .zero
            // 🌟 新增：开启吸顶效果
            headerItem.pinToVisibleBounds = viewConfig.pinHeaderToVisibleBounds
            supplementaryItems.append(headerItem)
        }
        
        if !(sectionModel.footerReuseID ?? "").stringIsEmpty() {
            let footerSize = NSCollectionLayoutSize(
                widthDimension: .absolute(screenWidth - viewConfig.footerWidthOffset - sectionWidth),
                heightDimension: .absolute(sectionModel.footerHeight ?? .leastNormalMagnitude)
            )

            let footerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom,
                absoluteOffset: CGPoint(x: -viewConfig.decorationItemsEdges.leading, y: 0)
            )
            // 🌟 新增：开启吸底效果
            footerItem.pinToVisibleBounds = viewConfig.pinFooterToVisibleBounds
            supplementaryItems.append(footerItem)
        }
        
        return supplementaryItems
    }

    private func generateDecorationItems(section: NSInteger, sectionModel: PTSection) -> [NSCollectionLayoutDecorationItem] {
        switch viewConfig.decorationItemsType {
        case .Custom:
            let snapshot = self.diffableDataSource.snapshot()
            guard !snapshot.sectionIdentifiers.isEmpty else { return [] }
            if let decorationInCollectionView = decorationInCollectionView?(section, sectionModel) {
                return decorationInCollectionView
            } else {
                return []
            }
        case .Normal:
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: PTBaseDecorationView.ID)
            backItem.contentInsets = viewConfig.decorationItemsEdges
            return [backItem]
        case .Corner:
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: PTBaseDecorationView_Corner.ID)
            backItem.contentInsets = viewConfig.decorationItemsEdges
            return [backItem]
        default:
            return []
        }
    }

    func buildWaterfallItems(section: Int,
                             data: [AnyObject],
                             width: CGFloat,
                             config: PTCollectionViewConfig,
                             version: Int,
                             itemHeight: (Int, AnyObject) -> CGFloat) -> (items: [NSCollectionLayoutGroupCustomItem], height: CGFloat) {
        
        let key = WaterfallCacheKey(section: section, width: width, version: version)
        
        // 🟢 1️⃣ 命中缓存（直接返回）
        if let cache = waterfallCache[key] {
            return (cache.items, cache.contentHeight)
        }
        
        let rowCount = max(1, config.rowCount)
        let itemSpace = config.cellLeadingSpace
        let itemTrailingSpace = config.cellTrailingSpace
        
        let cellWidth = (width - config.itemOriginalX * 2 - CGFloat(rowCount - 1) * itemSpace) / CGFloat(rowCount)
        
        var columnHeights = Array(repeating: config.contentTopSpace, count: rowCount)
        
        var columnX: [CGFloat] = []
        for i in 0..<rowCount {
            columnX.append(config.itemOriginalX + CGFloat(i) * (cellWidth + itemSpace))
        }
        
        var items: [NSCollectionLayoutGroupCustomItem] = []
        
        for (index, model) in data.enumerated() {
            
            let h = itemHeight(index, model)
            
            let minColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            
            let frame = CGRect(
                x: columnX[minColumn],
                y: columnHeights[minColumn],
                width: cellWidth,
                height: h
            )
            
            let item = NSCollectionLayoutGroupCustomItem(frame: frame)
            items.append(item)
            
            columnHeights[minColumn] = frame.maxY + itemTrailingSpace
        }
        
        let maxHeight = (columnHeights.max() ?? 0) - itemTrailingSpace + config.contentBottomSpace
                
        // 🟢 2️⃣ 写入缓存
        waterfallCache[key] = WaterfallCache(
            columnHeights: columnHeights,
            items: items,
            contentHeight: maxHeight
        )
        
        return (items, maxHeight)
    }
    
    private func clearWaterfallCache(section: Int) {
        waterfallCache = waterfallCache.filter { $0.key.section != section }
    }
}

//MARK: EmptyDataView
extension PTCollectionView {
    fileprivate func setiOS17EmptyDataView() {
        switch self.viewConfig.emptyShowType {
        case .Auto:
            if #available(iOS 17.0, *) {
                self.showEmptyConfig()
            } else {
                self.below17EmptyDataSet()
            }
        case .ThirtyParty:
            self.below17EmptyDataSet()
        case .System:
            if #available(iOS 17.0, *) {
                self.showEmptyConfig()
            }
        }
    }
    
    @available(iOS 17, *)
    private func showEmptyConfig() {
        // 🌟 修复：精准计算所有 Section 的总 Row 数量，不要只查 first
        let snapshot = self.diffableDataSource.snapshot()
        let isEmpty = snapshot.numberOfItems == 0
        if viewConfig.showEmptyAlert {
            if isEmpty {
                // 先隐藏，再展示
                PTUnavailableManager.hideUnavailableView(in: self) {
                    if let config = self.viewConfig.emptyViewConfig {
                        PTUnavailableManager.showEmptyView(in: self, config: config) { [weak self] in
                            // 处理按钮点击事件
                            self?.showEmptyLoading()
                            // 延迟触发外部回调
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self?.emptyTap?(nil)
                            }
                        }
                    }
                }
            } else {
                PTUnavailableManager.hideUnavailableView(in: self)
            }
        } else {
            PTUnavailableManager.hideUnavailableView(in: self)
        }
    }
    
    @available(iOS 17, *)
    public func hideEmptyLoading(task: PTActionTask?) {
        PTUnavailableManager.hideUnavailableView(in: self, task: task)
    }
    
    @available(iOS 17, *)
    public func showEmptyLoading() {
        PTUnavailableManager.showEmptyLoadingView(in: self)
    }
    
    private func below17EmptyDataSet() {
        let snapshot = self.diffableDataSource.snapshot()
        let isEmpty = snapshot.numberOfItems == 0
        if self.viewConfig.showEmptyAlert {
            if isEmpty {
                if let empty = self.viewConfig.emptyViewConfig {
                    if let emptyCuston = empty.customerView {
                        collectionView.emptyDataSetView { view in
                            view.backgroundColor = empty.backgroundColor
                            view.customView(emptyCuston)
                                .verticalOffset(empty.verticalOffSet)
                                .isTouchAllowed(true)
                        }
                    } else {
                        let buttonAtt:ASAttributedString = """
                                    \(wrap: .embedding("""
                                    \(empty.buttonTitle,.font(empty.buttonFont),.paragraph(.alignment(.center),.lineSpacing(7.5)),.foreground(empty.buttonTextColor))
                                    """))
                                    """
                        
                        collectionView.emptyDataSetView { view in
                            view.backgroundColor = empty.backgroundColor
                            view.titleLabelString(empty.mainTitleAtt?.value)
                                .detailLabelString(empty.secondaryEmptyAtt?.value)
                                .image(empty.image)
                                .buttonTitle(buttonAtt.value, for: .normal)
                                .verticalOffset(empty.verticalOffSet)
                                .verticalSpace(empty.imageToTextPadding)
                                .didTapContentView {
                                    self.emptyTap?(view)
                                }
                                .didTapDataButton {
                                    self.emptyButtonTap?(view)
                                }
                        }
                    }
                    // 🌟 新增：配置完成后，强制让第三方库立即刷新并展示！
                    self.collectionView.reloadEmptyDataSet()
                }
            } else {
                self.reloadEmptyConfig()
            }
        } else {
            self.reloadEmptyConfig()
        }
    }
    
    public func reloadEmptyConfig() {
        if self.viewConfig.showEmptyAlert {
            collectionView.reloadEmptyDataSet()
        }
    }
}

//MARK: Refresh
extension PTCollectionView {
    public func endRefresh() {
#if POOTOOLS_SCROLLREFRESH
        if viewConfig.footerRefresh {
            PTGCDManager.gcdMain {
                self.collectionView.pt_endMJRefresh()
            }
        }
#endif
        
        if viewConfig.topRefresh {
            PTGCDManager.gcdMain {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
#if POOTOOLS_SCROLLREFRESH
    public func footerRefreshNoMore () {
        collectionView.mj_footer?.endRefreshingWithNoMoreData()
    }
    
    public func footerRefreshReset() {
        collectionView.mj_footer?.resetNoMoreData()
    }
#endif
}

//MARK: Register
extension PTCollectionView {
    public func registerHeaderIdsNClasss(ids:[String],viewClass:AnyClass,kind:String) {
        collectionView.registerSupplementaryView(ids: ids, viewClass: viewClass, kind: kind)
    }
    
    public func registerClassCells(classs:[String:AnyClass]) {
        collectionView.registerClassCells(classs: classs)
    }
    
    public func registerNibCells(nib:[String:String]) {
        collectionView.registerNibCells(nib: nib)
    }
    
    public func registerSupplementaryView(classs:[String:AnyClass],kind:String) {
        //kind:UICollectionView.elementKindSectionFooter && UICollectionView.elementKindSectionHeader
        collectionView.registerSupplementaryView(classs: classs, kind: kind)
    }
}

extension PTCollectionView {
    /// 刷新指定的 Sections (通过 Index)
    public func reloadSections(at indexes: [Int], animated: Bool = true, completion: PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            var snapshot = self.diffableDataSource.snapshot()
                    
            // 🌟 换成从 snapshot 里安全提取模型
            let validSections = indexes.compactMap { index -> PTSection? in
                guard index >= 0 && index < snapshot.sectionIdentifiers.count else { return nil }
                return snapshot.sectionIdentifiers[index]
            }
            
            guard !validSections.isEmpty else {
                completion?()
                return
            }
            
            for index in indexes {
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.clearWaterfallCache(section: index)
                }
                self.markSectionDirty(index)
            }
            
            snapshot.reloadSections(validSections)
            self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                completion?()
            }
        }
    }
    
    /// 刷新指定的 Rows
    /// - Parameters:
    ///   - rows: 需要刷新的 Row 模型数组
    ///   - section: 这些 Row 所在的 Section Index (用于清理相关的布局缓存)
    public func reloadRows(_ rows: [PTRows], in section: Int, completion: PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            var snapshot = self.diffableDataSource.snapshot()
            guard section >= 0, section < snapshot.sectionIdentifiers.count else {
                completion?()
                return
            }
            
            // 1. 清理布局缓存 (因为 reload 可能会改变 cell 的高度或内容)
            let width = self.collectionView.bounds.width
            let sectionModel = snapshot.sectionIdentifiers[section]
            for row in rows {
                let key = HeightCacheKey(id: row.diffId, width: width)
                self.heightCache.remove(forKey: key)
            }

            let oldLayoutKey = LayoutCacheKey(section: section, width: width, version: sectionModel.layoutVersion)
            self.layoutCache.remove(forKey: oldLayoutKey)

            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.clearWaterfallCache(section: section)
            }

            self.markSectionDirty(section)
                        
            // 安全校验：确保这些 row 真的存在于当前的 snapshot 中，避免传入脏数据导致异常
            let existingRows = rows.filter { snapshot.indexOfItem($0) != nil }
            
            guard !existingRows.isEmpty else {
                completion?()
                return
            }
            
            // 直接告诉 Snapshot 重新加载这些 items
            snapshot.reloadItems(existingRows)
            
            // 3. 应用变更
            let animated = !self.viewConfig.refreshWithoutAnimation
            self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                completion?()
            }
        }
    }
    
    /// 跨 Section 批量刷新 Rows
    /// - Parameters:
    ///   - rowsMap: 字典形式传入，Key 为 Section Index，Value 为该 Section 下需要刷新的 Row 模型数组
    public func reloadSectionsRows(_ rowsMap: [Int: [PTRows]], completion: PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            var snapshot = self.diffableDataSource.snapshot()
            let containerWidth = self.collectionView.bounds.width
            
            var allRowsToReload: [PTRows] = []
            
            // 1. 遍历字典，精准清理受影响的 Section 缓存，并收集所有的 Rows
            for (sectionIndex, rows) in rowsMap {
                // 防越界保护
                guard sectionIndex >= 0, sectionIndex < snapshot.sectionIdentifiers.count else { continue }
                let sectionModel = snapshot.sectionIdentifiers[sectionIndex]
                
                // 🌟 精准清理 Height 缓存：只删掉需要重绘的 Row 的高度
                for row in rows {
                    let cacheKey = HeightCacheKey(id: row.diffId, width: containerWidth)
                    self.heightCache.remove(forKey: cacheKey)
                }
                
                // 🌟 细粒度清理 Layout 缓存：在版本升级前，精准抹杀旧布局
                let oldLayoutKey = LayoutCacheKey(section: sectionIndex, width: containerWidth, version: sectionModel.layoutVersion)
                self.layoutCache.remove(forKey: oldLayoutKey)
                // 清理对应的瀑布流缓存
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.clearWaterfallCache(section: sectionIndex)
                }
                // 标记该 Section 布局失效
                sectionModel.layoutVersion += 1
                
                // 把这个 Section 里的需要刷新的 rows 装进大集合里
                allRowsToReload.append(contentsOf: rows)
            }
            
            // 安全过滤：防止外部传入了已经被删除的脏数据
            let existingRows = allRowsToReload.filter { snapshot.indexOfItem($0) != nil }
            guard !existingRows.isEmpty else {
                completion?()
                return
            }
            
            // ✨ 重点：把所有跨 Section 的 Row 一次性丢给底层！
            snapshot.reloadItems(existingRows)
            
            // 3. 应用变更
            let animated = !self.viewConfig.refreshWithoutAnimation
            self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                // 如果是瀑布流，跨 section 刷新可能导致整体高度变化，这里做一次全局 layout 刷新
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
                completion?()
            }
        }
    }
    
    /// 强制重绘当前所有的 Section 和 Row
    /// (适用于主题切换、多语言切换、或者强制重绘现有数据的场景)
    public func reloadAllData(animated: Bool = true, completion: PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            // 1. 既然是全量刷新，先彻底清空所有的布局和高度缓存
            self.layoutCache.removeAll()
            self.heightCache.removeAll()
            self.waterfallCache.removeAll() // 👈 瀑布流缓存也要清空
            
            var snapshot = self.diffableDataSource.snapshot()
            
            // 🌟 换成根据 snapshot 遍历
            for i in 0..<snapshot.sectionIdentifiers.count {
                snapshot.sectionIdentifiers[i].layoutVersion += 1
            }
            
            let allExistingItems = snapshot.itemIdentifiers
            guard !allExistingItems.isEmpty else {
                completion?()
                return
            }
            
            snapshot.reloadItems(allExistingItems)
            
            self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
                completion?()
            }
        }
    }
}

//MARK: Get Models (Data Query)
extension PTCollectionView {
    
    /// 1. 通过 IndexPath 获取单个 Row 模型 (最常用)
    public func getRow(at indexPath: IndexPath) -> PTRows? {
        // 🌟 直接向底层 Diffable 请求，绝对安全，不会有越界崩溃
        return diffableDataSource.itemIdentifier(for: indexPath)
    }
    
    /// 2. 通过一组 IndexPath 批量获取 Row 模型
    public func getRows(at indexPaths: [IndexPath]) -> [PTRows] {
        return indexPaths.compactMap { getRow(at: $0) }
    }
    
    /// 3. 通过数据 ID 查找 Row 模型 (非常适合处理网络回调或通知)
    public func getRow(by diffId: String) -> PTRows? {
        let snapshot = diffableDataSource.snapshot()
        // 从当前屏幕真实展示的数据快照中查找
        return snapshot.itemIdentifiers.first { $0.diffId == diffId }
    }
    
    /// 4. 获取某个 Section 下的所有 Row 模型
    public func getAllRows(in section: Int) -> [PTRows] {
        let snapshot = diffableDataSource.snapshot()
        let sectionIdentifiers = snapshot.sectionIdentifiers
        
        // 防越界保护
        guard section >= 0 && section < sectionIdentifiers.count else { return [] }
        
        let targetSection = sectionIdentifiers[section]
        return snapshot.itemIdentifiers(inSection: targetSection)
    }
    
    /// 将一组 IndexPath 转换为按 Section 分组的 Rows 字典
    /// 非常适合配合 `reloadSectionsRows` 或 `deleteSectionsRows` 使用
    /// - Parameter indexPaths: 需要处理的 IndexPath 数组
    /// - Returns: 按 Section Index 分组的字典 [Int: [PTRows]]
    public func getSectionRowsMap(from indexPaths: [IndexPath]) -> [Int: [PTRows]] {
        var rowsMap: [Int: [PTRows]] = [:]
        
        for indexPath in indexPaths {
            // 获取对应的 Row 模型
            if let row = self.getRow(at: indexPath) {
                // Swift 字典的优雅写法：如果该 section 还没有数组，就默认创建一个空数组并追加
                rowsMap[indexPath.section, default: []].append(row)
            }
        }
        
        return rowsMap
    }
    
    /// 根据 Header ID 查找对应的 Section Index
    /// - Parameter headerID: 需要查找的目标 Header ID
    /// - Returns: 如果找到则返回对应的 Index，如果列表中不存在则返回 nil
    public func getSectionIndex(byHeaderID headerID: String) -> Int? {
        // 1. 获取当前唯一真实的数据快照
        let snapshot = self.diffableDataSource.snapshot()
        
        // 2. snapshot.sectionIdentifiers 是一个包含当前所有 PTSection 模型的数组
        // 3. 使用 firstIndex(where:) 遍历数组，找出内部属性与目标 ID 匹配的那个元素的下标
        let index = snapshot.sectionIdentifiers.firstIndex { sectionModel in
            // 注意：这里请将 headerReuseID 替换为你模型中真实代表 header id 的属性名
            return sectionModel.headerReuseID == headerID
        }
        
        return index
    }
}
