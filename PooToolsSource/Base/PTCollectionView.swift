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
import Photos
import SwifterSwift

private let kPTCollectionIndexViewAnimationDuration: Double = 0.25


private struct DiffThreshold {
    static let smallItem = 200      // 完整 diff
    static let mediumItem = 500     // 只 section diff
    static let largeItem = 1000     // 直接 reload
}

private struct WaterfallCache {
    var items: [NSCollectionLayoutGroupCustomItem] = []
    var contentHeight: CGFloat = 0
}

private struct WaterfallCacheKey: Hashable {
    let section: Int
    let width: CGFloat
    let version: Int
}

// 1. 定义一个基于 NSCache 的强类型缓存
@MainActor
public class PTLRUCache<Key: Hashable & Sendable, Value: AnyObject> {
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

@MainActor
private final class PTSkeletonOverlayView: UIView {
    private static let animationKey = "PTCollectionView.skeletonShimmer"

    private struct LayoutSignature: Equatable {
        let rects: [CGRect]
        let cornerRadius: CGFloat
    }

    private let baseLayer = CAShapeLayer()
    private let shimmerLayer = CAGradientLayer()
    private let shimmerMask = CAShapeLayer()
    private var layoutSignature: LayoutSignature?
    private var wantsShimmer = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        clipsToBounds = true
        backgroundColor = .clear

        shimmerLayer.mask = shimmerMask
        layer.addSublayer(baseLayer)
        layer.addSublayer(shimmerLayer)
        updateColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: PTSkeletonOverlayView, _) in
            view.updateColors()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusDidChange),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        return nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        baseLayer.frame = bounds
        shimmerLayer.frame = bounds
        shimmerMask.frame = bounds
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateShimmerState()
    }

    func update(rects: [CGRect], cornerRadius: CGFloat) {
        let radius = max(0, cornerRadius)
        let signature = LayoutSignature(rects: rects, cornerRadius: radius)
        guard signature != layoutSignature else { return }
        layoutSignature = signature

        let path = UIBezierPath()
        for rect in rects {
            path.append(UIBezierPath(roundedRect: rect, cornerRadius: radius))
        }
        baseLayer.path = path.cgPath
        shimmerMask.path = path.cgPath
    }

    func startShimmerIfNeeded() {
        wantsShimmer = true
        updateShimmerState()
    }

    func stopShimmer() {
        wantsShimmer = false
        updateShimmerState()
    }

    @objc private func reduceMotionStatusDidChange() {
        updateShimmerState()
    }

    private func updateShimmerState() {
        let reduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        shimmerLayer.isHidden = reduceMotionEnabled
        guard wantsShimmer, window != nil, !isHidden, !reduceMotionEnabled else {
            shimmerLayer.removeAnimation(forKey: Self.animationKey)
            return
        }

        guard shimmerLayer.animation(forKey: Self.animationKey) == nil else { return }

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.2
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmerLayer.add(animation, forKey: Self.animationKey)
    }

    private func updateColors() {
        let baseColor = UIColor.secondarySystemBackground.resolvedColor(with: traitCollection)
        let highlightColor = UIColor.tertiarySystemBackground.resolvedColor(with: traitCollection)
        baseLayer.fillColor = baseColor.cgColor
        shimmerLayer.colors = [baseColor.cgColor, highlightColor.cgColor, baseColor.cgColor]
        shimmerLayer.locations = [0, 0.5, 1]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }
}

//MARK: 界面展示
@objcMembers
@MainActor
public class PTCollectionView: UIView {
    private var boundsChangeTask: Task<Void, Never>?
    
    // 声明一个节流任务
    private var scrollDebounceTask: Task<Void, Never>?
    /// 原生 Diffable 数据源
    private var diffableDataSource: PTDataSource!
    ///Photos
    let imageManager = PHCachingImageManager()
    var photoAssets: [PHAsset] = []

    private lazy var skeletonOverlayView = PTSkeletonOverlayView()
    private var activeSkeletonItemCount: Int?
    public private(set) var isSkeletonVisible = false
    
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
        return max(0, floor(floorValue) / 2)
    }
    
    fileprivate var isTouched: Bool = false
    
    fileprivate var touchedIndex: Int = 0 {
        didSet {
            if touchedIndex != oldValue {
                impactFeedbackGenerator.prepare()
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
    private var lastPrefetchItemCount: Int?
    private var indexPanGesture: UIPanGestureRecognizer?
    
    private var heightCache = PTLRUCache<HeightCacheKey, NSNumber>(countLimit: 1000)
    private var waterfallCache: [WaterfallCacheKey: WaterfallCache] = [:]
    private var layoutCache =  PTLRUCache<LayoutCacheKey, NSCollectionLayoutSection>(countLimit: 100)
    
    private var fallbackLayouts: [Int: NSCollectionLayoutSection] = [:]
    private var didReportFallbackLayout = false
    
    fileprivate lazy var collectionView : PTBaseCollectionView = {
        var view = PTBaseCollectionView(frame: .zero, collectionViewLayout: self.comboLayout())
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
            view.pt.header = PTRefreshHeader { [weak self] in
                self?.headerRefreshTask?()
            }
        }

        view.registerSupplementaryView(classs: [NSStringFromClass(PTBaseCollectionReusableView.self):PTBaseCollectionReusableView.self], kind: UICollectionView.elementKindSectionHeader)
        view.registerSupplementaryView(classs: [NSStringFromClass(PTBaseCollectionReusableView.self):PTBaseCollectionReusableView.self], kind: UICollectionView.elementKindSectionFooter)
        if self.viewConfig.footerRefresh {
            let footerRefresh = PTRefreshAutoFooter{ [weak self] in
                self?.footRefreshTask?()
            }
            footerRefresh.setTitle(self.viewConfig.footerRefreshIdle, for: .idle)
            footerRefresh.setTitle(self.viewConfig.footerRefreshPulling, for: .pulling)
            footerRefresh.setTitle(self.viewConfig.footerRefreshRefreshing, for: .refreshing)
            footerRefresh.setTitle(self.viewConfig.footerRefreshWillRefresh, for: .willRefresh)
            footerRefresh.setTitle(self.viewConfig.footerRefreshNoMoreData, for: .noMoreData)
            footerRefresh.setFont(self.viewConfig.footerRefreshTextFont)
            footerRefresh.setTextColor(self.viewConfig.footerRefreshTextColor)
            footerRefresh.triggerAutomaticallyRefreshPercent = self.viewConfig.triggerAutomaticallyRefreshPercent
            footerRefresh.setAutomaticallyHidden(self.viewConfig.isAutomaticallyRefresh)
            footerRefresh.ignoredContentInsetBottom = self.viewConfig.ignoredScrollViewContentInsetBottom
            view.pt.autoFooter = footerRefresh
        }
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
    
    //MARK: Cell datasource handler
    open var headerInCollection: PTReusableViewHandler?
    open var footerInCollection: PTReusableViewHandler?
    open var cellInCollection: PTCellInCollectionHandler?
    
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
    
    //MARK: Orthogonal Scroll handler (正交滚动专用)
    /// 正交滚动 (横向滑动) 的实时偏移量回调: (SectionIndex, CGPoint)
    open var orthogonalDidScroll:  ((Int, CGPoint) -> Void)?
    /// 正交滚动 (横向滑动) 翻页改变时的回调: (SectionIndex, 当前页码 CurrentPage)
    open var orthogonalPageDidChange: ((Int, Int) -> Void)?
    
    // 🌟 新增：无感知触底预加载回调
    /// 无感知触底预加载事件触发回调
    /// ⚠️ 注意：外部收到此回调后，务必自行进行 isLoading 状态拦截，防止重复触发请求
    open var collectionWillReachBottomTask: PTActionTask?
    
    ///头部刷新事件
    open var headerRefreshTask: PTActionTask?
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
    /// 数据输入无法用于创建合法快照时的错误回调。
    open var collectionUpdateError: PTCollectionViewUpdateErrorHandler?

    public var viewConfig: PTCollectionViewConfig! {
        didSet {
            guard let config = viewConfig else { return }
            // 配置对象被替换后，滚动方向和交互能力必须同步到内部列表。
            let view = collectionView
            view.showsVerticalScrollIndicator = config.showsVerticalScrollIndicator
            view.showsHorizontalScrollIndicator = config.showsHorizontalScrollIndicator
            view.contentOffSetZero = config.contentOffSetZero
            view.dragInteractionEnabled = config.canMoveItem
            view.prefetchDataSource = config.viewForPhoto ? self : nil

            switch config.viewType {
            case .Normal, .Gird, .WaterFall, .Tag:
                view.alwaysBounceHorizontal = false
                view.alwaysBounceVertical = true
            case .Custom:
                view.alwaysBounceHorizontal = config.alwaysBounceHorizontal
                view.alwaysBounceVertical = config.alwaysBounceVertical
            case .Horizontal, .HorizontalLayoutSystem:
                view.alwaysBounceHorizontal = true
                view.alwaysBounceVertical = false
            }

            if config.canMoveItem {
                view.allowsMoveItem()
            }
            
            if config.sideIndexTitles?.isEmpty == false && config.indexConfig != nil {
                if view.superview == nil {
                    addSubview(view)
                    view.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                }
                setIndexViews()
            } else {
                indicator.removeFromSuperview()
                indexContainerView.removeFromSuperview()
            }
            
            if view.superview != nil {
                view.collectionViewLayout.invalidateLayout()
            }

            if isSkeletonVisible {
                updateSkeletonLayout()
            }
        }
    }
    
    private var registeredCells: Set<String> = []
    private var registeredSupplementary: Set<String> = []
    
    //MARK: 界面展示
    public init(viewConfig: PTCollectionViewConfig!) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig ?? PTCollectionViewConfig()
        setupCollectionView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewConfig = PTCollectionViewConfig()
        setupCollectionView()
    }

    private func setupCollectionView() {
        isUserInteractionEnabled = true
        self.registerClassCells(classs: ["CELL":UICollectionViewCell.self])

        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if viewConfig.canMoveItem {
            collectionView.allowsMoveItem()
        }
        setIndexViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        setupDiffableDataSource()
        setiOS17EmptyDataView()

        skeletonOverlayView.isHidden = true
        addSubview(skeletonOverlayView)
        skeletonOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didReceiveMemoryWarning() {
        layoutCache.removeAll()
        heightCache.removeAll()
        waterfallCache.removeAll()
        fallbackLayouts.removeAll()
    }
    
    ///展示界面
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateSkeletonLayout()
    }

    /// 显示独立的骨架覆盖层，不改变当前 Diffable snapshot。
    public func showSkeleton(itemCount: Int? = nil) {
        let requestedCount = itemCount ?? viewConfig.skeletonItemCount
        activeSkeletonItemCount = min(max(requestedCount, 1), 50)
        isSkeletonVisible = true
        skeletonOverlayView.isHidden = false
        bringSubviewToFront(skeletonOverlayView)
        updateSkeletonLayout()
        skeletonOverlayView.startShimmerIfNeeded()
    }

    /// 隐藏骨架覆盖层，不改变当前空状态或内容状态。
    public func hideSkeleton() {
        guard isSkeletonVisible || !skeletonOverlayView.isHidden else { return }
        isSkeletonVisible = false
        activeSkeletonItemCount = nil
        skeletonOverlayView.stopShimmer()
        skeletonOverlayView.isHidden = true
    }
}

private extension PTCollectionView {
    func reportUpdateError(_ error: PTCollectionViewUpdateError) {
        collectionUpdateError?(error)
    }

    func validateSections(_ sections: [PTSection], against snapshot: PTSnapshot? = nil) -> Bool {
        var sectionIdentifiers = Set(snapshot?.sectionIdentifiers.map(\.identifier) ?? [])
        var rowIdentifiers = Set(snapshot?.itemIdentifiers.map(\.diffId) ?? [])

        for section in sections {
            guard !section.identifier.isEmpty else {
                reportUpdateError(.emptySectionIdentifier)
                return false
            }
            guard sectionIdentifiers.insert(section.identifier).inserted else {
                reportUpdateError(.duplicateSectionIdentifier(section.identifier))
                return false
            }

            for row in section.rows ?? [] {
                guard rowIdentifiers.insert(row.diffId).inserted else {
                    reportUpdateError(.duplicateRowIdentifier(row.diffId))
                    return false
                }
            }
        }
        return true
    }

    func validateRows(_ rows: [PTRows], against snapshot: PTSnapshot) -> Bool {
        var rowIdentifiers = Set(snapshot.itemIdentifiers.map(\.diffId))
        for row in rows {
            guard rowIdentifiers.insert(row.diffId).inserted else {
                reportUpdateError(.duplicateRowIdentifier(row.diffId))
                return false
            }
        }
        return true
    }

    func updateSkeletonLayout() {
        guard isSkeletonVisible else { return }
        bringSubviewToFront(skeletonOverlayView)
        let count = activeSkeletonItemCount ?? viewConfig.skeletonItemCount
        skeletonOverlayView.update(rects: skeletonFrames(itemCount: count), cornerRadius: viewConfig.skeletonCornerRadius)
    }

    func skeletonFrames(itemCount: Int) -> [CGRect] {
        let count = min(max(itemCount, 1), 50)
        guard let config = viewConfig else { return [] }
        let bounds = skeletonOverlayView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return [] }

        let leading = max(0, config.itemOriginalX)
        let trailing = max(0, config.itemOriginalX)
        let verticalSpacing = max(0, config.cellTrailingSpace)
        let contentTop = max(0, config.contentTopSpace)
        let contentBottom = max(0, config.contentBottomSpace)
        let contentWidth = max(1, bounds.width - leading - trailing)
        let baseHeight = max(1, config.itemHeight)
        let columnCount = max(1, config.rowCount)
        let columnSpacing = max(0, config.cellLeadingSpace)
        let availableColumnWidth = max(1, (contentWidth - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount))

        func photoHeight(for width: CGFloat, fallback: CGFloat) -> CGFloat {
            guard config.viewForPhoto,
                  config.previewImageSize.width > 0,
                  config.previewImageSize.height > 0 else {
                return fallback
            }
            return max(1, width * config.previewImageSize.height / config.previewImageSize.width)
        }

        switch config.viewType {
        case .Normal, .Custom:
            let width = max(1, bounds.width - leading - trailing)
            let height = photoHeight(for: width, fallback: baseHeight)
            return (0..<count).map { index in
                CGRect(x: leading,
                       y: contentTop + CGFloat(index) * (height + verticalSpacing),
                       width: width,
                       height: height)
            }

        case .Gird, .Tag:
            let height = photoHeight(for: availableColumnWidth, fallback: baseHeight)
            return (0..<count).map { index in
                let row = index / columnCount
                let column = index % columnCount
                return CGRect(x: leading + CGFloat(column) * (availableColumnWidth + columnSpacing),
                              y: contentTop + CGFloat(row) * (height + verticalSpacing),
                              width: availableColumnWidth,
                              height: height)
            }

        case .WaterFall:
            var columnHeights = Array(repeating: contentTop, count: columnCount)
            let heightMultipliers: [CGFloat] = [0.82, 1.0, 1.18]
            return (0..<count).map { index in
                let column = index % columnCount
                let width = availableColumnWidth
                let height = photoHeight(for: width, fallback: baseHeight) * heightMultipliers[index % heightMultipliers.count]
                let frame = CGRect(x: leading + CGFloat(column) * (width + columnSpacing),
                                   y: columnHeights[column],
                                   width: width,
                                   height: max(1, height))
                columnHeights[column] = frame.maxY + verticalSpacing
                return frame
            }

        case .Horizontal, .HorizontalLayoutSystem:
            let width = max(1, config.itemWidth)
            let height = min(baseHeight, max(1, bounds.height - contentTop - contentBottom))
            let y = max(contentTop, (bounds.height - height) / 2)
            return (0..<count).map { index in
                CGRect(x: leading + CGFloat(index) * (width + columnSpacing),
                       y: y,
                       width: width,
                       height: height)
            }
        }
    }
}

extension PTCollectionView {
    
    private func setupDiffableDataSource() {
        // 1. 配置 Cell
        diffableDataSource = PTDataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, rowModel) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            
            let snapshot = self.diffableDataSource.snapshot()
            
            guard indexPath.section < snapshot.sectionIdentifiers.count else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath)
            }

            let sectionModel = snapshot.sectionIdentifiers[indexPath.section]
            
            let cell: UICollectionViewCell
            if let configuredCell = self.cellInCollection?(collectionView, sectionModel, indexPath) {
                cell = configuredCell
            } else if let cellClass = rowModel.cellClass,
                      !rowModel.reuseID.isEmpty {
                self.registerCellIfNeeded(cellClass, reuseID: rowModel.reuseID)
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: rowModel.reuseID, for: indexPath)

                if let fusionCell = cell as? PTFusionCellProtocol,
                   let fusionModel = rowModel.dataModel as? PTFusionCellModel {
                    fusionCell.cellModel = fusionModel
                } else if let bindableCell = cell as? PTAnyCellBindable,
                          let dataModel = rowModel.dataModel {
                    bindableCell.pt_bindAny(dataModel)
                }
            } else {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath)
            }

            self.configureSwipeCell(cell,
                                    collectionView: collectionView,
                                    sectionModel: sectionModel,
                                    indexPath: indexPath)
            return cell
        }
        
        // 2. 配置 Header 和 Footer
        diffableDataSource.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) -> UICollectionReusableView? in
            guard let self = self else { return nil }
            
            let snapshot = self.diffableDataSource.snapshot()
            
            guard indexPath.section < snapshot.sectionIdentifiers.count else {
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
        
        let initialSnapshot = PTSnapshot()
        diffableDataSource.apply(initialSnapshot, animatingDifferences: false)
    }

    private func configureSwipeCell(_ cell: UICollectionViewCell,
                                    collectionView: UICollectionView,
                                    sectionModel: PTSection,
                                    indexPath: IndexPath) {
        guard let swipeCell = cell as? PTBaseSwipeCell else { return }

        let canSwipe = indexPathSwipe?(sectionModel, indexPath) ?? false
        swipeCell.cellCanSwipe = canSwipe
        swipeCell.resetSwipeActions()
        guard canSwipe else { return }

        if let actions = swipeRightHandler?(collectionView, sectionModel, indexPath) {
            swipeCell.configureRightActions(actions)
        }
        if let actions = swipeLeftHandler?(collectionView, sectionModel, indexPath) {
            swipeCell.configureLeftActions(actions)
        }
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
    
    public func hideIndicator() {
        UIView.animate(withDuration: 0.2) {
            self.indicator.alpha = 0
        }
    }
    
    public func clearLayoutCaches() {
        self.layoutCache.removeAll()
        self.heightCache.removeAll()
        self.waterfallCache.removeAll()
        self.fallbackLayouts.removeAll()
    }
}

//MARK: UICollectionViewDelegate
extension PTCollectionView:UICollectionViewDelegate,UIScrollViewDelegate {
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
        
        // 1. 抛出原有的正常展示回调
        collectionWillDisplay?(collectionView, cell, itemSec, indexPath)
        
        // 🌟 修复注入：无感知触底预加载验证逻辑
        if viewConfig.enableSmartPrefetch, let collectionWillReachBottomTask = collectionWillReachBottomTask {
            let snapshot = diffableDataSource.snapshot()
            let totalItems = snapshot.numberOfItems
            let threshold = max(0, viewConfig.prefetchThreshold)
            
            guard totalItems > threshold else { return }

            if let currentItem = diffableDataSource.itemIdentifier(for: indexPath),
               let currentIndex = snapshot.indexOfItem(currentItem) {
                if (totalItems - 1) - currentIndex <= threshold {
                    guard lastPrefetchItemCount != totalItems else { return }
                    lastPrefetchItemCount = totalItems
                    collectionWillReachBottomTask()
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        switch viewConfig.decorationItemsType {
        case .Custom:
            decorationViewReset?(collectionView,view,elementKind,indexPath,itemSec)
        case .Normal,.Corner:
            if let decorationView = view as? PTBaseDecorationView {
                decorationView.configure(
                    backgroundColor: itemSec.decorationBackgroundColor ?? PTAppBaseConfig.share.decorationBackgroundColor,
                    cornerRadius: viewConfig.decorationItemsType == .Normal ? 0 : itemSec.decorationCornerRadius,
                    shadowOpacity: itemSec.decorationShadowOpacity,
                    backgroundImage: itemSec.decorationBackgroundImage
                )
            }
        default:break
        }
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
        guard let cv = scrollView as? UICollectionView else { return }
        collectionWillBeginDecelerating?(cv)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionViewDidScroll?(cv)
        throttleScrollUpdate()
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionWillBeginDragging?(cv)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionDidEndDragging?(cv,decelerate)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionWillEndDraging?(cv,velocity,targetContentOffset)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionDidEndDecelerating?(cv)
        hideIndicator()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionDidEndScrollingAnimation?(cv)
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
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
        
        let itemProvider = NSItemProvider(object: rowModel.diffId as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = rowModel
        
        return [dragItem]
    }
    
    // MARK: - Drop Delegate
    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard viewConfig.canMoveItem else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard viewConfig.canMoveItem,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else { return }

        var snapshot = diffableDataSource.snapshot()
        guard sourceIndexPath.section >= 0,
              sourceIndexPath.section < snapshot.sectionIdentifiers.count,
              let sourceItem = diffableDataSource.itemIdentifier(for: sourceIndexPath) else { return }

        let destinationSectionIndex = coordinator.destinationIndexPath?.section ?? sourceIndexPath.section
        guard destinationSectionIndex >= 0,
              destinationSectionIndex < snapshot.sectionIdentifiers.count else { return }

        let sourceSection = snapshot.sectionIdentifiers[sourceIndexPath.section]
        let destinationSection = snapshot.sectionIdentifiers[destinationSectionIndex]
        let sourceItems = snapshot.itemIdentifiers(inSection: sourceSection)
        var destinationItems = snapshot.itemIdentifiers(inSection: destinationSection)
        guard let sourceItemIndex = sourceItems.firstIndex(of: sourceItem) else { return }

        let requestedDestinationIndex = coordinator.destinationIndexPath?.item ?? destinationItems.count
        let destinationIndex = min(max(requestedDestinationIndex, 0), destinationItems.count)
        let isSameSection = sourceSection.identifier == destinationSection.identifier
        var insertionIndex = destinationIndex

        if isSameSection {
            destinationItems.remove(at: sourceItemIndex)
            let adjustedIndex = min(max(destinationIndex - (sourceItemIndex < destinationIndex ? 1 : 0), 0), destinationItems.count)
            guard adjustedIndex != sourceItemIndex else {
                coordinator.drop(item.dragItem, toItemAt: sourceIndexPath)
                return
            }
            insertionIndex = adjustedIndex

            var updatedRows = sourceSection.rows ?? []
            updatedRows.removeAll { $0.diffId == sourceItem.diffId }
            updatedRows.insert(sourceItem, at: min(adjustedIndex, updatedRows.count))
            sourceSection.rows = updatedRows
        } else {
            var sourceRows = sourceSection.rows ?? []
            sourceRows.removeAll { $0.diffId == sourceItem.diffId }
            sourceSection.rows = sourceRows

            var destinationRows = destinationSection.rows ?? []
            destinationRows.insert(sourceItem, at: min(destinationIndex, destinationRows.count))
            destinationSection.rows = destinationRows
        }

        snapshot.deleteItems([sourceItem])
        let remainingItems = destinationItems
        if let anchorItem = remainingItems[safe: insertionIndex] {
            snapshot.insertItems([sourceItem], beforeItem: anchorItem)
        } else {
            snapshot.appendItems([sourceItem], toSection: destinationSection)
        }

        layoutCache.removeAll()
        heightCache.remove(forKey: HeightCacheKey(id: sourceItem.diffId, width: collectionView.bounds.width))
        sourceSection.layoutVersion += 1
        if !isSameSection {
            destinationSection.layoutVersion += 1
        }

        if viewConfig.viewType == .WaterFall, waterFallLayout != nil {
            clearWaterfallCache(section: sourceIndexPath.section)
            clearWaterfallCache(section: destinationSectionIndex)
        }

        let finalIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: destinationIndex, section: destinationSectionIndex)
        let animated = !viewConfig.refreshWithoutAnimation
        diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self else { return }
            self.itemMoveTo?(collectionView, sourceIndexPath, finalIndexPath)
        }

        coordinator.drop(item.dragItem, toItemAt: finalIndexPath)
    }
}

//MARK: For Photos
extension PTCollectionView:UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let assets = photoAssets(for: indexPaths)
        if !assets.isEmpty {
            imageManager.startCachingImages(for: assets, targetSize: viewConfig.previewImageSize, contentMode: .aspectFill, options: nil)
        }
    }
        
    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let assets = photoAssets(for: indexPaths)
        if !assets.isEmpty {
            imageManager.stopCachingImages(for: assets, targetSize: viewConfig.previewImageSize, contentMode: .aspectFill, options: nil)
        }
    }
}

private extension PTCollectionView {
    func photoAssets(for indexPaths: [IndexPath]) -> [PHAsset] {
        guard let config = viewConfig,
              config.viewForPhoto,
              !photoAssets.isEmpty else { return [] }

        let dataSource = diffableDataSource
        let snapshot = dataSource?.snapshot()
        var identifiers = Set<String>()

        return indexPaths.compactMap { indexPath in
            let fallbackIndex = indexPath.item
            let snapshotIndex: Int?
            if let dataSource,
               let row = dataSource.itemIdentifier(for: indexPath) {
                snapshotIndex = snapshot?.indexOfItem(row)
            } else {
                snapshotIndex = nil
            }

            let assetIndex = snapshotIndex ?? fallbackIndex
            guard photoAssets.indices.contains(assetIndex) else { return nil }

            let asset = photoAssets[assetIndex]
            guard identifiers.insert(asset.localIdentifier).inserted else { return nil }
            return asset
        }
    }
}

//MARK: 索引设置
private extension PTCollectionView {
    func setIndexViews() {
        if let indexPanGesture {
            indexContainerView.removeGestureRecognizer(indexPanGesture)
            self.indexPanGesture = nil
        }
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        indicator.removeFromSuperview()
        indexContainerView.removeFromSuperview()
        guard viewConfig.sideIndexTitles?.isEmpty == false,
              viewConfig.indexConfig != nil else { return }
        
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
        indexPanGesture = pan
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
        let snapshot = diffableDataSource.snapshot()
        guard section >= 0, section < snapshot.sectionIdentifiers.count else { return }
        let sectionModel = snapshot.sectionIdentifiers[section]
        guard !snapshot.itemIdentifiers(inSection: sectionModel).isEmpty else {
            isTouched = false
            return
        }
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
                let targetFrame = targetView.convert(targetView.bounds, to: self)
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
        
        // 取消之前的任务
        scrollDebounceTask?.cancel()
        
        // 创建新的 Task
        scrollDebounceTask = Task { @MainActor [weak self] in
            do {
                // 延迟 0.05 秒 (50 毫秒 = 50,000,000 纳秒)
                try await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled else { return }
                self?.handleScrollUpdate()
            } catch {
                // 任务被取消会抛出 CancellationError，直接忽略
            }
        }
    }
}

//MARK: Waterfall相关
extension PTCollectionView {
    private func cachedHeight(for indexPath: IndexPath,
                              model: AnyObject,
                              calculator: (Int, AnyObject) -> CGFloat) -> CGFloat {
        guard let row = diffableDataSource.itemIdentifier(for: indexPath) else {
            return calculator(indexPath.section, model)
        }

        let key = HeightCacheKey(id: row.diffId, width: collectionView.bounds.width)
        
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
            if let headerClass = section.headerClass as? PTSupplementaryRegisterable.Type {
                registerSupplementaryIfNeeded(headerClass)
            }
            if let footerClass = section.footerClass as? PTSupplementaryRegisterable.Type {
                registerSupplementaryIfNeeded(footerClass)
            }
            section.rows?.forEach { row in
                if let cellClass = row.cellClass, !row.reuseID.isEmpty {
                    registerCellIfNeeded(cellClass, reuseID: row.reuseID)
                }
            }
        }
    }
    
    private func registerCellIfNeeded(_ cellClass: UICollectionViewCell.Type, reuseID: String) {
        guard !reuseID.isEmpty else { return }
        guard !registeredCells.contains(reuseID) else { return }
        collectionView.register(cellClass, forCellWithReuseIdentifier: reuseID)
        registeredCells.insert(reuseID)
    }
    
    private func registerSupplementaryIfNeeded(_ viewClass: PTSupplementaryRegisterable.Type) {
        let reuseID = viewClass.reuseID
        let registrationKey = "\(viewClass.kind)|\(reuseID)"
        guard !reuseID.isEmpty, !registeredSupplementary.contains(registrationKey),
              let reusableViewClass = viewClass as? UICollectionReusableView.Type else { return }
        collectionView.register(reusableViewClass,
                                forSupplementaryViewOfKind: viewClass.kind,
                                withReuseIdentifier: reuseID)
        registeredSupplementary.insert(registrationKey)
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
        guard validateSections(collectionData) else {
            finishTask?(collectionView)
            return
        }

        self.autoRegisterIfNeeded(sections: collectionData)
        lastPrefetchItemCount = nil
        
        self.layoutCache.removeAll()
        self.heightCache.removeAll()
        self.waterfallCache.removeAll()
        self.fallbackLayouts.removeAll()
        
        var snapshot = PTSnapshot()
        snapshot.appendSections(collectionData)
        
        for section in collectionData {
            if let rows = section.rows, !rows.isEmpty {
                snapshot.appendItems(rows, toSection: section)
            }
        }
        
        if !collectionData.isEmpty {
            PTUnavailableManager.render(.content, in: self)
        }
        
        diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self = self else { return }
            self.setiOS17EmptyDataView()
            finishTask?(self.collectionView)
        }
    }
    
    public func clearAllData(finishTask:PTCollectionCallback? = nil) {
        lastPrefetchItemCount = nil
        self.layoutCache.removeAll()
        self.heightCache.removeAll()
        self.waterfallCache.removeAll()
        self.fallbackLayouts.removeAll()
        
        var snapshot = PTSnapshot()
        snapshot.deleteAllItems()
        
        let animated = !self.viewConfig.refreshWithoutAnimation
        diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self = self else { return }
            self.setiOS17EmptyDataView()
            finishTask?(self.collectionView)
        }
    }

    /// 在指定的 IndexPath 插入新行
    /// - Parameters:
    ///   - rows: 需要插入的新数据数组
    ///   - indexPath: 目标位置 (会自动容错处理越界问题)
    ///   - completion: 动画完成后的回调
    public func insertRows(_ rows: [PTRows], at indexPath: IndexPath, completion: PTActionTask? = nil) {
        var snapshot = self.diffableDataSource.snapshot()

        guard !rows.isEmpty, validateRows(rows, against: snapshot) else {
            completion?()
            return
        }
            
        // 1. 安全校验 Section 是否存在
        guard indexPath.section >= 0, indexPath.section < snapshot.sectionIdentifiers.count else {
            completion?()
            return
        }
            
        let sectionModel = snapshot.sectionIdentifiers[indexPath.section]
        if sectionModel.rows == nil { sectionModel.rows = [] }
            
        let currentRowsCount = snapshot.itemIdentifiers(inSection: sectionModel).count
            
            // 2. 确定是要插入 (Insert) 还是追加 (Append)
        let isAppend = indexPath.item >= currentRowsCount
            
            // 找到即将被顶到后面的那个“锚点” Item
        let currentRows = snapshot.itemIdentifiers(inSection: sectionModel)
        let anchorItem = isAppend ? nil : currentRows[indexPath.item]
            
            // 🌟 3. 同步更新底层真实数据源模型 (极度重要，自定义 Layout 全靠它)
        let insertIndex = min(max(0, indexPath.item), sectionModel.rows?.count ?? 0)
        sectionModel.rows?.insert(contentsOf: rows, at: insertIndex)
            
            // 4. 炸掉缓存，强制重新计算后续所有布局和高度
        self.layoutCache.removeAll()
        if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
            self.clearWaterfallCache(section: indexPath.section)
        }
        sectionModel.layoutVersion += 1
            
            // 🌟 5. 更新 Diffable 引擎快照
        if let anchor = anchorItem {
            // 如果锚点存在，直接插入在锚点前面。
            snapshot.insertItems(rows, beforeItem: anchor)
        } else {
            // 如果是空 Section 或者给定的 item 索引超过了现有数量，直接追加到末尾。
            snapshot.appendItems(rows, toSection: sectionModel)
        }
            
            // 6. 提交动画
        let animated = !self.viewConfig.refreshWithoutAnimation
        self.diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self else { return }
            self.setiOS17EmptyDataView()
            completion?()
        }
    }

    public func insertRows(_ rows:[PTRows],section:Int,completion:PTActionTask? = nil) {
        var snapshot = self.diffableDataSource.snapshot()
        guard !rows.isEmpty, validateRows(rows, against: snapshot) else {
            completion?()
            return
        }
        guard section >= 0, section < snapshot.sectionIdentifiers.count else {
            completion?()
            return
        }
        
        let sectionModel = snapshot.sectionIdentifiers[section]
        if sectionModel.rows == nil { sectionModel.rows = [] }
        sectionModel.rows?.append(contentsOf: rows)
        
        self.layoutCache.removeAll()
        if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
            self.clearWaterfallCache(section: section)
        }
        sectionModel.layoutVersion += 1
        
        snapshot.appendItems(rows, toSection: sectionModel)
        
        let animated = !self.viewConfig.refreshWithoutAnimation
        self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
            self.setiOS17EmptyDataView()
            completion?()
        }
    }
    
    public func insertSection(_ sections:[PTSection], afterIndex:Int? = nil,completion:PTActionTask? = nil) {
        guard !sections.isEmpty else {
            completion?()
            return
        }

        var snapshot = self.diffableDataSource.snapshot()
        guard validateSections(sections, against: snapshot) else {
            completion?()
            return
        }
        if let index = afterIndex, index < 0 {
            reportUpdateError(.invalidSectionIndex(index))
            completion?()
            return
        }
        
        self.layoutCache.removeAll()
        self.heightCache.removeAll()

        var insertIndex = snapshot.sectionIdentifiers.count

        if let index = afterIndex, index < snapshot.sectionIdentifiers.count {
            insertIndex = index + 1
            let anchorSection = snapshot.sectionIdentifiers[index]
            snapshot.insertSections(sections, afterSection: anchorSection)
        } else {
            snapshot.appendSections(sections)
        }

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

    public func deleteRows(_ rows: [PTRows], from section: Int, completion: PTActionTask? = nil) {
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
        let sectionRowIDs = Set(snapshot.itemIdentifiers(inSection: sectionModel).map(\.diffId))
        let existingRows = rows.filter { sectionRowIDs.contains($0.diffId) }
        guard !existingRows.isEmpty else {
            completion?()
            return
        }
        sectionModel.layoutVersion += 1
        sectionModel.rows?.removeAll(where: { existingRows.contains($0) })

        snapshot.deleteItems(existingRows)

        if sectionModel.rows?.isEmpty ?? true {
            snapshot.deleteSections([sectionModel])
        }
        
        let animated = !self.viewConfig.refreshWithoutAnimation
        self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
            self.setiOS17EmptyDataView()
            completion?()
        }
    }
    
    public func deleteSectionsRows(_ rowsMap: [Int: [PTRows]], completion: PTActionTask? = nil) {
        self.layoutCache.removeAll()
        self.heightCache.removeAll()
        
        var allRowsToDelete: [PTRows] = []
        var sectionsToDelete: [PTSection] = []
        var snapshot = self.diffableDataSource.snapshot()
        
        for (sectionIndex, rows) in rowsMap {
            guard sectionIndex >= 0, sectionIndex < snapshot.sectionIdentifiers.count else { continue }
            
            let sectionModel = snapshot.sectionIdentifiers[sectionIndex]
            
            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.clearWaterfallCache(section: sectionIndex)
            }
            sectionModel.layoutVersion += 1
            
            let sectionRowIDs = Set(snapshot.itemIdentifiers(inSection: sectionModel).map(\.diffId))
            let existingRows = rows.filter { sectionRowIDs.contains($0.diffId) }
            sectionModel.rows?.removeAll(where: { existingRows.contains($0) })
            allRowsToDelete.append(contentsOf: existingRows)
            
            if sectionModel.rows?.isEmpty ?? true {
                sectionsToDelete.append(sectionModel)
            }
        }

        guard !allRowsToDelete.isEmpty else {
            completion?()
            return
        }

        let uniqueRows = Dictionary(grouping: allRowsToDelete, by: \.diffId).compactMap { $0.value.first }
        snapshot.deleteItems(uniqueRows)
        
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
    
    public func deleteSections(_ sections: [PTSection], completion: PTActionTask? = nil) {
        var snapshot = self.diffableDataSource.snapshot()
        let existingSections = sections.filter { snapshot.indexOfSection($0) != nil }
        guard !existingSections.isEmpty else {
            completion?()
            return
        }
                    
        for sectionModel in existingSections {
            if let index = snapshot.indexOfSection(sectionModel) {
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.clearWaterfallCache(section: index)
                }
                sectionModel.layoutVersion += 1
            }
        }

        self.layoutCache.removeAll()
        self.heightCache.removeAll()
        
        snapshot.deleteSections(existingSections)
        
        let animated = !self.viewConfig.refreshWithoutAnimation
        self.diffableDataSource.apply(snapshot, animatingDifferences: animated) {
            self.setiOS17EmptyDataView()
            completion?()
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
                guard let decorationClass = value.decorationClass,
                      let decorationID = value.decorationID,
                      !decorationID.isEmpty else { return }
                layout.register(decorationClass, forDecorationViewOfKind: decorationID)
            }
        case .Normal,.Corner:
            layout.register(PTBaseDecorationView.self, forDecorationViewOfKind: PTBaseDecorationView.ID)
        default:break
        }
        return layout
    }
    
    private func buildSection(sectionModel: PTSection,sectionIndex: NSInteger, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
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
                // English: Use the layout environment width so tags recalculate after rotation or split view changes.
                // Español: Usa el ancho del entorno de diseño para recalcular las etiquetas tras rotación o cambios de Split View.
                // 中文：使用布局环境宽度，确保旋转或分屏尺寸变化后标签重新计算。
                group = UICollectionView.tagShowLayout(
                    data: tags,
                    screenWidth: screenWidth,
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
        
        // 🌟 修复注入：监听正交滚动 (Orthogonal Scrolling)
        if behavior != .none {
            laySection.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, env in
                guard let self = self else { return }
                Task { @MainActor in
                    self.orthogonalDidScroll?(sectionIndex, offset)
                    let pageWidth = env.container.contentSize.width
                    if pageWidth > 0 {
                        let currentPage = Int(round(offset.x / pageWidth))
                        self.orthogonalPageDidChange?(sectionIndex, currentPage)
                    }
                }
            }
        }
        return laySection
    }
    
    fileprivate func generateSection(section: NSInteger, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let snapshot = self.diffableDataSource.snapshot()
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
        if !didReportFallbackLayout {
            didReportFallbackLayout = true
            // English: Report the fallback once to avoid logging during every layout pass.
            // Español: Informa del fallback una sola vez para evitar registros en cada pasada de diseño.
            // 中文：只记录一次兜底布局，避免每次布局都重复输出日志。
            PTNSLogConsole("Warning: CustomerLayout is nil. Fallback to 1x1 group.")
        }
        let size = NSCollectionLayoutSize(widthDimension: .absolute(1), heightDimension: .absolute(1))
        return NSCollectionLayoutGroup(layoutSize: size)
    }

    private func generateSupplementaryItems(section: NSInteger, sectionModel: PTSection, sectionWidth: CGFloat, screenWidth: CGFloat) -> [NSCollectionLayoutBoundarySupplementaryItem] {
        var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
        
        if !(sectionModel.headerReuseID ?? "").stringIsEmpty() {
            let headerWidth = max(1, screenWidth - viewConfig.headerWidthOffset - sectionWidth)
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .absolute(headerWidth),
                heightDimension: .absolute(sectionModel.headerHeight ?? .leastNormalMagnitude)
            )
            
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topTrailing,
                absoluteOffset: CGPoint(x: -viewConfig.decorationItemsEdges.leading, y: viewConfig.decorationItemsEdges.top + (sectionModel.headerHeight ?? .leastNormalMagnitude))
            )
            headerItem.contentInsets = .zero
            headerItem.pinToVisibleBounds = viewConfig.pinHeaderToVisibleBounds
            supplementaryItems.append(headerItem)
        }
        
        if !(sectionModel.footerReuseID ?? "").stringIsEmpty() {
            let footerWidth = max(1, screenWidth - viewConfig.footerWidthOffset - sectionWidth)
            let footerSize = NSCollectionLayoutSize(
                widthDimension: .absolute(footerWidth),
                heightDimension: .absolute(sectionModel.footerHeight ?? .leastNormalMagnitude)
            )

            let footerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom,
                absoluteOffset: CGPoint(x: -viewConfig.decorationItemsEdges.leading, y: 0)
            )
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
        case .Normal,.Corner:
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: PTBaseDecorationView.ID)
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
        
        if let cache = waterfallCache[key] {
            return (cache.items, cache.contentHeight)
        }
        
        let result = PTCollectionLayoutGeometry.waterfall(data: data,
                                                          width: width,
                                                          rowCount: config.rowCount,
                                                          itemOriginalX: config.itemOriginalX,
                                                          topContentSpace: config.contentTopSpace,
                                                          bottomContentSpace: config.contentBottomSpace,
                                                          itemSpace: config.cellLeadingSpace,
                                                          itemTrailingSpace: config.cellTrailingSpace,
                                                          itemHeight: itemHeight)
        let items = result.frames.map { NSCollectionLayoutGroupCustomItem(frame: $0) }
        waterfallCache[key] = WaterfallCache(items: items,
                                             contentHeight: result.contentHeight)
        return (items, result.contentHeight)
    }
    
    private func clearWaterfallCache(section: Int) {
        // 🌟 修复提升：原地过滤移除优化
        waterfallCache = waterfallCache.filter { $0.key.section != section }
    }
}

//MARK: EmptyDataView
extension PTCollectionView {
    fileprivate func setiOS17EmptyDataView() {
        switch self.viewConfig.emptyShowType {
        case .Auto:
            self.showEmptyConfig()
        case .ThirtyParty:
            self.below17EmptyDataSet()
        case .System:
            self.showEmptyConfig()
        }
    }
    
    private func showEmptyConfig() {
        let snapshot = self.diffableDataSource.snapshot()
        let isEmpty = snapshot.numberOfItems == 0
        guard viewConfig.showEmptyAlert, isEmpty, let config = viewConfig.emptyViewConfig else {
            PTUnavailableManager.render(.content, in: self)
            return
        }

        PTUnavailableManager.render(.empty, in: self, config: config) { [weak self = self] in
            self?.showEmptyLoading()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                self?.emptyTap?(nil)
            }
        }
    }
    
    public func hideEmptyLoading(task: PTActionTask?) {
        PTUnavailableManager.hideUnavailableView(in: self, task: task)
    }
    
    public func showEmptyLoading() {
        PTUnavailableManager.render(.loading, in: self)
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
        self.collectionView.pt_endMJRefresh()
    }
    
    public func footerRefreshNoMore () {
        collectionView.pt.footer?.endRefreshingWithNoMoreData()
        collectionView.pt.autoFooter?.endRefreshingWithNoMoreData()
    }
    
    public func footerRefreshReset() {
        collectionView.pt.footer?.resetNoMoreData()
        collectionView.pt.autoFooter?.resetNoMoreData()
    }
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
        collectionView.registerSupplementaryView(classs: classs, kind: kind)
    }
}

extension PTCollectionView {
    public func reloadSections(at indexes: [Int], animated: Bool = true, completion: PTActionTask? = nil) {
        var snapshot = diffableDataSource.snapshot()
        var seenIndexes = Set<Int>()
        let validIndexes = indexes.filter { index in
            index >= 0 && index < snapshot.sectionIdentifiers.count && seenIndexes.insert(index).inserted
        }
        let validSections = validIndexes.map { snapshot.sectionIdentifiers[$0] }

        guard !validSections.isEmpty else {
            completion?()
            return
        }

        for index in validIndexes {
            if viewConfig.viewType == .WaterFall, waterFallLayout != nil {
                clearWaterfallCache(section: index)
            }
            markSectionDirty(index)
        }

        snapshot.reloadSections(validSections)
        diffableDataSource.apply(snapshot, animatingDifferences: animated) {
            completion?()
        }
    }
    
    public func reloadRows(_ rows: [PTRows], in section: Int, completion: PTActionTask? = nil) {
        var snapshot = diffableDataSource.snapshot()
        guard section >= 0, section < snapshot.sectionIdentifiers.count else {
            completion?()
            return
        }

        let sectionModel = snapshot.sectionIdentifiers[section]
        let sectionRowIDs = Set(snapshot.itemIdentifiers(inSection: sectionModel).map(\.diffId))
        var seenRows = Set<String>()
        let existingRows = rows.filter {
            sectionRowIDs.contains($0.diffId) && seenRows.insert($0.diffId).inserted
        }
        guard !existingRows.isEmpty else {
            completion?()
            return
        }

        let width = collectionView.bounds.width
        for row in existingRows {
            heightCache.remove(forKey: HeightCacheKey(id: row.diffId, width: width))
        }
        layoutCache.remove(forKey: LayoutCacheKey(section: section, width: width, version: sectionModel.layoutVersion))
        if viewConfig.viewType == .WaterFall, waterFallLayout != nil {
            clearWaterfallCache(section: section)
        }
        markSectionDirty(section)

        snapshot.reloadItems(existingRows)
        let animated = !viewConfig.refreshWithoutAnimation
        diffableDataSource.apply(snapshot, animatingDifferences: animated) {
            completion?()
        }
    }
    
    public func reloadSectionsRows(_ rowsMap: [Int: [PTRows]], completion: PTActionTask? = nil) {
        var snapshot = diffableDataSource.snapshot()
        let containerWidth = collectionView.bounds.width
        var allRowsToReload: [PTRows] = []
        var seenRows = Set<String>()

        for (sectionIndex, rows) in rowsMap {
            guard sectionIndex >= 0, sectionIndex < snapshot.sectionIdentifiers.count else { continue }
            let sectionModel = snapshot.sectionIdentifiers[sectionIndex]
            let sectionRowIDs = Set(snapshot.itemIdentifiers(inSection: sectionModel).map(\.diffId))
            let existingRows = rows.filter {
                sectionRowIDs.contains($0.diffId) && seenRows.insert($0.diffId).inserted
            }
            guard !existingRows.isEmpty else { continue }

            for row in existingRows {
                heightCache.remove(forKey: HeightCacheKey(id: row.diffId, width: containerWidth))
            }
            layoutCache.remove(forKey: LayoutCacheKey(section: sectionIndex,
                                                       width: containerWidth,
                                                       version: sectionModel.layoutVersion))
            if viewConfig.viewType == .WaterFall, waterFallLayout != nil {
                clearWaterfallCache(section: sectionIndex)
            }
            sectionModel.layoutVersion += 1
            allRowsToReload.append(contentsOf: existingRows)
        }

        guard !allRowsToReload.isEmpty else {
            completion?()
            return
        }

        snapshot.reloadItems(allRowsToReload)
        let animated = !viewConfig.refreshWithoutAnimation
        diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self else {
                completion?()
                return
            }
            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            completion?()
        }
    }
    
    public func reloadAllData(animated: Bool = true, completion: PTActionTask? = nil) {
        layoutCache.removeAll()
        heightCache.removeAll()
        waterfallCache.removeAll()
        fallbackLayouts.removeAll()

        var snapshot = diffableDataSource.snapshot()
        let allSections = snapshot.sectionIdentifiers
        guard !allSections.isEmpty else {
            completion?()
            return
        }

        for section in allSections {
            section.layoutVersion += 1
        }
        snapshot.reloadSections(allSections)

        let allExistingItems = snapshot.itemIdentifiers
        if !allExistingItems.isEmpty {
            snapshot.reloadItems(allExistingItems)
        }

        diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self else {
                completion?()
                return
            }
            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            completion?()
        }
    }
    
    public func softReloadAllData(animated: Bool = false, completion: PTActionTask? = nil) {
        var snapshot = diffableDataSource.snapshot()
        let allItems = snapshot.itemIdentifiers
        guard !allItems.isEmpty else {
            completion?()
            return
        }

        snapshot.reconfigureItems(allItems)
        diffableDataSource.apply(snapshot, animatingDifferences: animated) {
            completion?()
        }
    }
}

//MARK: Get Models (Data Query)
extension PTCollectionView {
    
    public func getRow(at indexPath: IndexPath) -> PTRows? {
        return diffableDataSource.itemIdentifier(for: indexPath)
    }
    
    public func getRows(at indexPaths: [IndexPath]) -> [PTRows] {
        return indexPaths.compactMap { getRow(at: $0) }
    }
    
    public func getRow(by diffId: String) -> PTRows? {
        let snapshot = diffableDataSource.snapshot()
        return snapshot.itemIdentifiers.first { $0.diffId == diffId }
    }
    
    public func getAllRows(in section: Int) -> [PTRows] {
        let snapshot = diffableDataSource.snapshot()
        let sectionIdentifiers = snapshot.sectionIdentifiers
        guard section >= 0 && section < sectionIdentifiers.count else { return [] }
        let targetSection = sectionIdentifiers[section]
        return snapshot.itemIdentifiers(inSection: targetSection)
    }
    
    public func getSectionRowsMap(from indexPaths: [IndexPath]) -> [Int: [PTRows]] {
        var rowsMap: [Int: [PTRows]] = [:]
        for indexPath in indexPaths {
            if let row = self.getRow(at: indexPath) {
                rowsMap[indexPath.section, default: []].append(row)
            }
        }
        return rowsMap
    }
    
    public func getSectionIndex(byHeaderID headerID: String) -> Int? {
        let snapshot = self.diffableDataSource.snapshot()
        let index = snapshot.sectionIdentifiers.firstIndex { sectionModel in
            return sectionModel.headerReuseID == headerID
        }
        return index
    }
}
