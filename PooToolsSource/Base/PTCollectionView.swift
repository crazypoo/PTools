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

#if POOTOOLS_LISTEMPTYDATA
import EmptyDataSet_Swift
#endif
import Photos

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
}

public class PTTextLayer: CATextLayer {
    open var index: Int = 0
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

//MARK: 界面展示
@objcMembers
public class PTCollectionView: UIView {
    
    ///Photos
    let imageManager = PHCachingImageManager()
    var photoAssets: [PHAsset] = []
    
    ///索引
    fileprivate var textLayerArray = [PTTextLayer]()
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
                impactFeedbackGenerator.impactOccurred()
            }
        }
    }
    
    // 懒加载震动反馈（替换原 Any? 强转的做法）
    fileprivate lazy var impactFeedbackGenerator : UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()
    
    // 使用 NSKeyValueObservation 替代手动 KVO
    private var contentOffsetObservation: NSKeyValueObservation?
        
    fileprivate var mSections = [PTSection]()
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
    
    fileprivate func generateSection(section: NSInteger, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        
        guard mSections.count > 0 else {
            let bannerGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(1), heightDimension: .absolute(1))
            return NSCollectionLayoutSection(group: NSCollectionLayoutGroup(layoutSize: bannerGroupSize))
        }
        
        let sectionModel = mSections[section]
        
        let screenWidth = frame.size.width
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
                group = UICollectionView.waterFallLayout(
                    data: sectionModel.rows,
                    screenWidth: screenWidth,
                    rowCount: viewConfig.rowCount,
                    itemOriginalX: viewConfig.itemOriginalX,
                    topContentSpace: viewConfig.contentTopSpace,
                    bottomContentSpace: viewConfig.contentBottomSpace,
                    itemSpace: viewConfig.cellLeadingSpace,
                    itemTrailingSpace: viewConfig.cellTrailingSpace,
                    itemHeight: waterFall
                )
            } else {
                PTNSLogConsole("Warning: WaterFallLayout is nil. Fallback to 1x1 group.")
                let size = NSCollectionLayoutSize(widthDimension: .absolute(1), heightDimension: .absolute(1))
                group = NSCollectionLayoutGroup(layoutSize: size)
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
                PTNSLogConsole("Warning: Tag viewType requires PTTagLayoutModel. Fallback to 1x1 group.")
                let size = NSCollectionLayoutSize(widthDimension: .absolute(1), heightDimension: .absolute(1))
                group = NSCollectionLayoutGroup(layoutSize: size)
            }
        case .Custom:
            if let customerLayout {
                group = customerLayout(section, sectionModel)
            } else {
                PTNSLogConsole("Warning: CustomerLayout is nil. Fallback to 1x1 group.")
                let size = NSCollectionLayoutSize(widthDimension: .absolute(1), heightDimension: .absolute(1))
                group = NSCollectionLayoutGroup(layoutSize: size)
            }
        }
        
        var sectionInsets = viewConfig.sectionEdges
        let sectionWidth: CGFloat
        switch viewConfig.decorationItemsType {
        case .Normal,.Corner,.NoItems:
            sectionInsets = NSDirectionalEdgeInsets(top: (sectionModel.headerHeight ?? .leastNormalMagnitude) + viewConfig.contentTopSpace + viewConfig.decorationItemsEdges.top, leading: sectionInsets.leading, bottom: viewConfig.contentBottomSpace, trailing: sectionInsets.trailing)
        default:
            sectionInsets = decorationCustomLayoutInsetReset?(section, sectionModel) ?? .zero
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
        
        if viewConfig.customReuseViews {
            let items = customerReuseViews?(section,sectionModel) ?? [NSCollectionLayoutBoundarySupplementaryItem]()
            laySection.boundarySupplementaryItems = items
        } else {
            laySection.boundarySupplementaryItems = generateSupplementaryItems(section: section, sectionModel: sectionModel, sectionWidth: sectionWidth, screenWidth: screenWidth)
        }
        
        laySection.decorationItems = generateDecorationItems(section: section, sectionModel: sectionModel)
        
        return laySection
    }

    private func generateSupplementaryItems(section: NSInteger, sectionModel: PTSection, sectionWidth: CGFloat, screenWidth: CGFloat) -> [NSCollectionLayoutBoundarySupplementaryItem] {
        var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
        
        if !(sectionModel.headerID ?? "").stringIsEmpty() {
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
            supplementaryItems.append(headerItem)
        }
        
        if !(sectionModel.footerID ?? "").stringIsEmpty() {
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
            supplementaryItems.append(footerItem)
        }
        
        return supplementaryItems
    }

    private func generateDecorationItems(section: NSInteger, sectionModel: PTSection) -> [NSCollectionLayoutDecorationItem] {
        switch viewConfig.decorationItemsType {
        case .Custom:
            guard mSections.count > 0 else { return [] }
            if let decorationInCollectionView {
                return decorationInCollectionView(section, sectionModel)
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

    fileprivate lazy var collectionView : PTBaseCollectionView = {
        let view = PTBaseCollectionView(frame: .zero, collectionViewLayout: self.comboLayout())
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.isUserInteractionEnabled = true
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
            let footerRefresh = PTRefreshAutoStateFooter(refreshingBlock: {
                self.footRefreshTask?()
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
    
    fileprivate lazy var indexView: UIView = {
        let view = UIView()
        view.backgroundColor = viewConfig.indexConfig?.indexViewBackgroundColor
        return view
    }()
    
    private(set) lazy var refreshControl:UIRefreshControl = {
        let control = UIRefreshControl()
        control.addRefreshHandlers { sender in
            PTGCDManager.gcdMain {
                self.headerRefreshTask?(sender)
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
    public var collectionSectionDatas:[PTSection] { mSections }
    
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
                indicator.removeFromSuperview()
                indexView.removeFromSuperview()
                clearTextLayers()
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

        // 使用 NSKeyValueObservation 监听 contentOffset
        contentOffsetObservation = collectionView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
            guard let self else { return }
            guard isTouched == false else { return }
            let indexPathArray = self.collectionView.indexPathsForVisibleItems
            let minIndexPath = indexPathArray.min { one, two in
                one.section <= two.section
            }
            if let temp = minIndexPath?.section {
                self.updateTextLayers(forSelectedIndex: temp)
            }
        }

#if POOTOOLS_LISTEMPTYDATA
        if self.viewConfig.showEmptyAlert {
            switch viewConfig.emptyShowType {
            case .Auto:
                if #unavailable(iOS 17.0) {
                    self.below17EmptyDataSet()
                } else {
                    self.iOS17EmptyDataSet()
                }
            case .ThirtyParty:
                self.below17EmptyDataSet()
            case .System:
                self.iOS17EmptyDataSet()
            }
        }
#else
        if self.viewConfig.showEmptyAlert {
            switch viewConfig.emptyShowType {
            case .Auto:
                self.iOS17EmptyDataSet()
            case .ThirtyParty:
                break
            case .System:
                self.iOS17EmptyDataSet()
            }
        }
#endif
        
        if self.viewConfig.showEmptyAlert {
            switch viewConfig.emptyShowType {
            case .Auto:
                self.iOS17EmptyTapCallback()
            case .ThirtyParty:
                break
            case .System:
                self.iOS17EmptyTapCallback()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // NSKeyValueObservation 自动释放，无需手动 removeObserver
        contentOffsetObservation = nil
    }
    
    ///展示界面
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func iOS17EmptyTapCallback() {
        if #available(iOS 17.0, *) {
            if self.viewConfig.showEmptyAlert {
                PTUnavailableFunction.shared.emptyTap = {
                    PTGCDManager.gcdMain {
                        self.showEmptyLoading()
                    }

                    PTGCDManager.gcdAfter(time: 0.1) {
                        self.emptyTap?(nil)
                    }
                }
            }
        }
    }
    
    func iOS17EmptyDataSet() {
        if #available(iOS 17.0, *) {
            PTGCDManager.gcdAfter(time: 0.1) {
                if let emptyConfig = self.viewConfig.emptyViewConfig {
                    let share = PTUnavailableFunction.shared
                    share.emptyViewConfig = emptyConfig
                    self.showEmptyConfig()
                }
            }
        }
    }
    
    func clearTextLayers() {
        // 仅清理索引相关的图层，避免误删其他 layer
        textLayerArray.forEach { $0.removeFromSuperlayer() }
        textLayerArray.removeAll()
    }
    
    func setIndexViews() {
        if (viewConfig.sideIndexTitles?.count ?? 0) > 0 && viewConfig.indexConfig != nil {
            PTGCDManager.gcdAfter(time: 0.1) {
                self.setupUI()
            }
            
            addSubview(indexView)
            indexView.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(7.5)
                make.top.bottom.equalToSuperview()
                make.width.equalTo(viewConfig.indexConfig!.itemSize.width)
            }
        }
    }
    
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
    
    ///加载数据并且刷新界面
    public func showCollectionDetail(collectionData:[PTSection],finishTask:PTCollectionCallback? = nil) {
        PTGCDManager.gcdMain {
            self.mSections.removeAll()
            self.mSections = collectionData
            if self.viewConfig.refreshWithoutAnimation {
                self.collectionView.reloadDataWithOutAnimation {
                    self.setiOS17EmptyDataView()
                    finishTask?(self.collectionView)
                }
            } else {
                self.collectionView.reloadData {
                    self.setiOS17EmptyDataView()
                    finishTask?(self.collectionView)
                }
            }
        }
    }
    
    public func clearAllData(finishTask:PTCollectionCallback? = nil) {
        PTGCDManager.gcdMain {
            self.mSections.removeAll()
            if self.viewConfig.refreshWithoutAnimation {
                self.collectionView.reloadDataWithOutAnimation {
                    self.setiOS17EmptyDataView()
                    finishTask?(self.collectionView)
                }
            } else {
                self.collectionView.reloadData {
                    self.setiOS17EmptyDataView()
                    finishTask?(self.collectionView)
                }
            }
        }
    }
    
    fileprivate func setiOS17EmptyDataView() {
        switch self.viewConfig.emptyShowType {
        case .Auto:
            if #available(iOS 17.0, *) {
                self.showEmptyConfig()
            }
        case .ThirtyParty:
            break
        case .System:
            if #available(iOS 17.0, *) {
                self.showEmptyConfig()
            }
        }
    }
    
    public func insertRows(_ rows:[PTRows],section:Int,completion:PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            // 🟢 1. 在主線程更新數據源
            let startIndex = self.mSections[section].rows?.count ?? 0
            self.mSections[section].rows?.append(contentsOf: rows)
            let endIndex = (self.mSections[section].rows?.count ?? 0) - 1
            let indexPaths = (startIndex...endIndex).map { IndexPath(item: $0, section: section) }

            // 🟢 2. 再在主線程執行 UI 更新
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: indexPaths)
            }, completion: { _ in
                // 🟢 3. 插入後可無效化布局（保持原有邏輯）
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
                completion?()
            })
        }
    }
    
    public func insertSection(_ sections:[PTSection],completion:PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            let startIndex = self.mSections.count
            self.mSections.append(contentsOf: sections)
            let indexPaths = IndexSet(startIndex..<startIndex + sections.count)
            self.collectionView.performBatchUpdates {
                self.collectionView.insertSections(indexPaths)
            } completion: { _ in
                // 仅在瀑布流且存在动态高度回调时才全局无效化布局
                if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
                completion?()
            }
        }
    }
    
    public func deleteRows(_ rows: [PTRows], from section: Int, completion: PTActionTask? = nil) {
        PTGCDManager.gcdMain {
            if let first = rows.first, let startIndex = self.mSections[section].rows?.firstIndex(of: first) {
                let endIndex = startIndex + rows.count - 1
                let indexPaths = (startIndex...endIndex).map { IndexPath(item: $0, section: section) }
                self.mSections[section].rows?.removeSubrange(startIndex...endIndex)
                self.collectionView.performBatchUpdates {
                    self.collectionView.deleteItems(at: indexPaths)
                } completion: { _ in
                    // 仅在瀑布流且存在动态高度回调时才全局无效化布局
                    if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                        self.collectionView.collectionViewLayout.invalidateLayout()
                    }
                    completion?()
                }
            } else {
                PTNSLogConsole("Error: Can't find the row in section \(section)")
            }
        }
    }
    
    public func deleteSections(_ sections: [PTSection], completion: PTActionTask? = nil) {
        PTGCDManager.gcdGobal {
            guard let startIndex = self.mSections.firstIndex(of: sections.first!) else {
                PTNSLogConsole("Error: Can't find the section to delete")
                return
            }
            let endIndex = startIndex + sections.count - 1
            let indexSet = IndexSet(startIndex...endIndex)
            self.mSections.removeSubrange(startIndex...endIndex)
            PTGCDManager.gcdMain {
                self.collectionView.performBatchUpdates {
                    self.collectionView.deleteSections(indexSet)
                } completion: { _ in
                    // 仅在瀑布流且存在动态高度回调时才全局无效化布局
                    if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                        self.collectionView.collectionViewLayout.invalidateLayout()
                    }
                    completion?()
                }
            }
        }
    }
    
    //MARK: 刷新相关
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
    
#if POOTOOLS_PAGINGCONTROL
    public func segmentScrolView() -> UIScrollView {
        collectionView
    }
#endif
    
    public func visibleCells() -> [UICollectionViewCell] {
        collectionView.visibleCells
    }
    
    public func scrolToItem(indexPath:IndexPath,position:UICollectionView.ScrollPosition) {
        collectionView.scrollToItem(at: indexPath, at: position, animated: true)
    }
    
    public func mtSelectItem(indexPath:IndexPath,animated:Bool,scrollPosition:UICollectionView.ScrollPosition) {
        collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
    }
        
    //MARK: 空白頁
    @available(iOS 17, *)
    private func showEmptyConfig() {
        if viewConfig.showEmptyAlert && (mSections.first?.rows?.count ?? 0) == 0 {
            PTUnavailableFunction.shared.hideUnavailableView(showIn: self) {
                PTUnavailableFunction.shared.showEmptyView(showIn: self)
            }
        } else {
            PTUnavailableFunction.shared.hideUnavailableView(showIn: self) {
            }
        }
    }
    
    @available(iOS 17, *)
    public func hideEmptyLoading(task: PTActionTask?) {
        PTUnavailableFunction.shared.hideUnavailableView(showIn: self,task: task)
    }
    
    @available(iOS 17, *)
    public func showEmptyLoading() {
        PTUnavailableFunction.shared.showEmptyLoadingView(showIn: self)
    }
    
#if POOTOOLS_LISTEMPTYDATA
    private func below17EmptyDataSet() {
        if self.viewConfig.showEmptyAlert {
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
            }
        }
    }
    
    public func reloadEmptyConfig() {
        if self.viewConfig.showEmptyAlert {
            below17EmptyDataSet()
            collectionView.reloadEmptyDataSet()
        }
    }
#endif
}

//MARK: UICollectionViewDelegate && UICollectionViewDataSource
extension PTCollectionView:UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate {
        
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        mSections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mSections.count == 0 ? 0 : (mSections[section].rows?.count ?? 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            if kind == UICollectionView.elementKindSectionHeader {
                if !(itemSec.headerID ?? "").stringIsEmpty() {
                    if let headerHeight = itemSec.headerHeight,headerHeight != CGFloat.leastNormalMagnitude {
                        return headerInCollection?(kind,collectionView,itemSec,indexPath) ?? UICollectionReusableView()
                    }
                }
            } else if kind == UICollectionView.elementKindSectionFooter {
                if !(itemSec.footerID ?? "").stringIsEmpty() {
                    if let footerHeight = itemSec.footerHeight,footerHeight != CGFloat.leastNormalMagnitude {
                        return footerInCollection?(kind,collectionView,itemSec,indexPath) ?? UICollectionReusableView()
                    }
                }
            }
        }
        let reuseView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(PTBaseCollectionReusableView.self), for: indexPath) as! PTBaseCollectionReusableView
        return reuseView
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            let cell = cellInCollection?(collectionView,itemSec,indexPath) ?? collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath)
            if let swipeCell = cell as? PTBaseSwipeCell {
                if let indexPathSwipe {
                    let swipe = indexPathSwipe(itemSec,indexPath)
                    swipeCell.cellCanSwipe = swipe
                    if swipe {
                        if let actions = swipeRightHandler?(collectionView,itemSec,indexPath) {
                            swipeCell.configureRightActions(actions)
                        } else if let actions = swipeLeftHandler?(collectionView,itemSec,indexPath) {
                            swipeCell.configureLeftActions(actions)
                        }
                    }
                }
                return swipeCell
            } else {
                return cell
            }
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemSec = mSections[indexPath.section]
        collectionDidSelect?(collectionView,itemSec,indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            collectionDidEndDisplay?(collectionView,cell,itemSec,indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            collectionWillDisplay?(collectionView,cell,itemSec,indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            decorationViewReset?(collectionView,view,elementKind,indexPath,itemSec)
        }
    }
    
    // MARK: 能否移动
    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return viewConfig.canMoveItem
    }
    
    // MARK: 移动cell结束
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        itemMoveTo?(collectionView,sourceIndexPath,destinationIndexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let itemSec = self.mSections[indexPath.section]
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: {
            let preview = self.forceController?(collectionView,indexPath,itemSec)
            return preview
        }, actionProvider: { suggestedActions in
            if let actions = self.forceActions?(collectionView,indexPath,itemSec) {
                return UIMenu(title: "", children: actions)
            }
            return nil
        })
    }
            
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        collectionWillBeginDecelerating?(scrollView as! UICollectionView)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        collectionViewDidScroll?(scrollView as! UICollectionView)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        collectionWillBeginDragging?(scrollView as! UICollectionView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        collectionDidEndDragging?(scrollView as! UICollectionView,decelerate)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        collectionWillEndDraging?(scrollView as! UICollectionView,velocity,targetContentOffset)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        collectionDidEndDecelerating?(scrollView as! UICollectionView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        collectionDidEndScrollingAnimation?(scrollView as! UICollectionView)
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        collectionDidScrolltoTop?(scrollView as! UICollectionView)
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
    
    func setupUI() {
        var layerArray = [PTTextLayer]()
        for i in 0 ..< (viewConfig.sideIndexTitles?.count ?? 0) {
            guard let title = viewConfig.sideIndexTitles?[i], let indexCfg = viewConfig.indexConfig else { continue }
            let textLayer = PTTextLayer()
            textLayer.index = i
            textLayer.font = CTFontCreateWithName(indexCfg.indexViewFont.fontName as CFString, indexCfg.indexViewFont.pointSize, nil)
            textLayer.fontSize = indexCfg.indexViewFont.pointSize
            textLayer.alignmentMode = CATextLayerAlignmentMode.center
            textLayer.string = title
            let frame = self.frame(forTextLayer: textLayer)
            textLayer.frame = frame
            textLayer.cornerRadius = indexCfg.itemSize.width / 2
            textLayer.masksToBounds = true
            textLayer.position = frame.origin
            self.layer.zPosition = CGFloat.greatestFiniteMagnitude
            self.layer.insertSublayer(textLayer, above: nil)
            layerArray.append(textLayer)
        }
        self.textLayerArray = layerArray
        self.updateTextLayers(forSelectedIndex: 0)
        
        self.addSubview(self.indicator)
    }
    
    func frame(forTextLayer textLayer: PTTextLayer) -> CGRect {
        guard let indexCfg = viewConfig.indexConfig else { return .zero }
        let width = indexCfg.itemSize.width
        let height = indexCfg.itemSize.height
        return CGRect(x: self.bounds.width - width, y: layerTopSpacing + CGFloat(textLayer.index) * height + indexCfg.itemSpacing * CGFloat(textLayer.index), width: width, height: height)
    }
    
    func showIndicator(forTextLayer textLayer: PTTextLayer) {
        guard let indexCfg = viewConfig.indexConfig else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        indicator.center = CGPoint(x: self.frame.size.width - indicator.frame.size.width / 2 - indexCfg.itemSize.width, y: textLayer.position.y)
        bigTextLabel.text = textLayer.string as? String
        indicator.alpha = 1
        CATransaction.commit()
    }
    
    func hideIndicator() {
        indicator.alpha = 0
    }
    
    func scrollCollectionView(toTextLayer textLayer: PTTextLayer, animated: Bool) {
        let indexPath = IndexPath(item: 0, section: textLayer.index)
        if let attributes = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath),
           let cellAttributes = collectionView.layoutAttributesForItem(at: indexPath) {
            var targetPoint = cellAttributes.frame.origin
            targetPoint.y = targetPoint.y - attributes.frame.size.height
            collectionView.setContentOffset(targetPoint, animated: animated)
        } else {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
        }
    }
    
    func updateTextLayers(forSelectedIndex index: Int) {
        guard let cfg = viewConfig.indexConfig else { return }
        for textLayer in textLayerArray {
            if textLayer.index == index {
                textLayer.backgroundColor = cfg.itemSelectedBackgroundColor.cgColor
                textLayer.foregroundColor = cfg.itemSelectedTextColor.cgColor
            } else {
                textLayer.backgroundColor = cfg.itemBackgroundColor.cgColor
                textLayer.foregroundColor = cfg.itemTextColor.cgColor
            }
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
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouched = true
        showChanges(forTouches: touches)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        hideIndicator()
        isTouched = false
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouched = true
        showChanges(forTouches: touches)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        hideIndicator()
        isTouched = false
    }
    
    func textLayer(forTouches touches: Set<UITouch>) -> PTTextLayer? {
        guard let touch = touches.first else { return nil }
        let touchPoint = touch.location(in: self)
        let touchLine = CGRect(x: 0, y: touchPoint.y, width: self.frame.size.width, height: 1)
        for textLayer in textLayerArray {
            if touchLine.intersects(textLayer.frame) {
                return textLayer
            }
        }
        return nil
    }
    
    func showChanges(forTouches touches: Set<UITouch>) {
        guard let touchedLayer = textLayer(forTouches: touches) else { return }
        if touchedIndex == touchedLayer.index { return }
        updateTextLayers(forSelectedIndex: touchedLayer.index)
        touchedIndex = touchedLayer.index
        showIndicator(forTextLayer: touchedLayer)
        scrollCollectionView(toTextLayer: touchedLayer, animated: false)
    }
}
