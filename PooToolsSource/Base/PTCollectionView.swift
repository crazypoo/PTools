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
import LXFProtocolTool
#endif

#if POOTOOLS_SWIPECELL
import SwipeCellKit
#endif

private let kPTCollectionIndexViewAnimationDuration: Double = 0.25
private var kPTCollectionIndexViewContent: CChar = 0
private let kPTCollectionIndexViewContentOffsetKeyPath = #keyPath(UICollectionView.contentOffset)

//MARK: CollectionView展示的样式类型
@objc public enum PTCollectionViewType:Int {
    case Normal
    case Gird
    case WaterFall
    case Custom
    case Horizontal
}

//MARK: Collection展示的Section底部样式类型
@objc public enum PTCollectionViewDecorationItemsType:Int {
    case NoItems
    case Custom
    case Normal
    case Corner
}

@objc public class PTDecorationItemModel:NSObject {
    ///Collection展示的Section底部Class
    open var decorationClass:AnyClass!
    ///Collection展示的Section底部ID
    open var decorationID:String!
}

///ReusableView回调
/// - Parameters:
///   - kind: header的头部kind
///   - collectionView: collectionView
///   - sectionModel: Section的model
///   - indexPath: 坐标
///  - Return: UICollectionReusableView
public typealias PTReusableViewHandler = (_ kind: String,_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath: IndexPath) -> UICollectionReusableView?

///Cell设置
/// - Parameters:
///   - collectionView: collectionView
///   - sectionModel: Section的model
///   - index: 坐标
///  - Return: UICollectionViewCell
public typealias PTCellInCollectionHandler = (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> UICollectionViewCell?

///Cell点击事件
/// - Parameters:
///   - collectionView: collectionView
///   - sectionModel: Section的model
///   - indexPath: 坐标
///  - Return: 事件
public typealias PTCellDidSelectedHandler = (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> Void

///Cell将要
/// - Parameters:
///   - collectionView: collectionView
///   - sectionModel: Section的model
///   - indexPath: 坐标
///  - Return: 事件
public typealias PTCellDisplayHandler = (_ collectionView:UICollectionView,_ cell:UICollectionViewCell,_ sectionModel:PTSection,_ indexPath:IndexPath) -> Void

///CollectionView的Scroll回调
/// - Parameters:
///   - collectionView: collectionView
///  - Return: 事件
public typealias PTCollectionViewScrollHandler = (_ collectionView:UICollectionView) -> Void

#if POOTOOLS_SWIPECELL
///CollectionView的Swipe回调
/// - Parameters:
///   - collectionView: collectionView
///   - sectionModel: Section的model
///   - indexPath: 坐标
///  - Return: 事件
public typealias PTCollectionViewSwipeHandler = (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> [SwipeAction]
#endif

public typealias PTCollectionViewCanSwipeHandler = (_ sectionModel:PTSection,_ indexPath:IndexPath) -> Bool

public typealias PTDecorationInCollectionHandler = (_ index:Int,_ sectionModel:PTSection) -> [NSCollectionLayoutDecorationItem]

public typealias PTViewInDecorationResetHandler = (_ collectionView: UICollectionView, _ view: UICollectionReusableView, _ elementKind: String, _ indexPath: IndexPath,_ sectionModel: PTSection) -> Void

//MARK: Collection展示的基本配置参数设置
@objcMembers
public class PTCollectionViewConfig:NSObject {
    ///CollectionView上下滑动条
    open var showsVerticalScrollIndicator:Bool = true
    ///CollectionView水平滑动条
    open var showsHorizontalScrollIndicator:Bool = true
    ///CollectionView展示的样式类型
    open var viewType:PTCollectionViewType = .Normal
    ///每行多少个(仅在瀑布流和Gird样式中使用)
    open var rowCount:Int = 3
    ///item高度
    open var itemHeight:CGFloat = PTAppBaseConfig.share.baseCellHeight
    ///item宽度(Horizontal下使用)
    open var itemWidth:CGFloat = 100
    ///item起始坐标X
    open var itemOriginalX:CGFloat = 0
    ///item的展示距离顶部的高度
    open var contentTopSpace:CGFloat = 0
    ///item的展示距离底部的高度
    open var contentBottomSpace:CGFloat = 0
    ///每个item的间隔(左右)
    open var cellLeadingSpace:CGFloat = 0
    ///每个item的间隔(上下)
    open var cellTrailingSpace:CGFloat = 0
    ///是否开启头部刷新
    open var topRefresh:Bool = false
#if POOTOOLS_SCROLLREFRESH
    ///是否开启底部刷新
    open var footerRefresh:Bool = false
    open var footerRefreshTextColor:UIColor = .white
    open var footerRefreshTextFont:UIFont = .appfont(size: 14)
    open var footerRefreshIdle:String = ""
    open var footerRefreshPulling:String = "鬆開即可刷新"
    open var footerRefreshRefreshing:String = "正在刷新中"
    open var footerRefreshWillRefresh:String = "即將刷新"
    open var footerRefreshNoMoreData:String = "已經全部加載完畢"
#endif
    ///section偏移
    open var sectionEdges:NSDirectionalEdgeInsets = .zero
    ///头部长度偏移
    open var headerWidthOffset:CGFloat = 0
    ///底部长度偏移
    open var footerWidthOffset:CGFloat = 0
    ///是否开启空数据展示
    open var showEmptyAlert:Bool = false
    ///空数据展示参数设置
    open var emptyViewConfig:PTEmptyDataViewConfig?
    ///Collection展示的Section底部样式类型
    open var decorationItemsType:PTCollectionViewDecorationItemsType = .NoItems
    ///Collection展示的Section底部样式偏移
    open var decorationItemsEdges:NSDirectionalEdgeInsets = .zero
    ///Collection展示的Section底部Model
    open var decorationModel: [PTDecorationItemModel]?
    ///Collection展示的Section底部样式偏移
    open var collectionViewBehavior:UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous
    ///是否开启自定义Header和Footer
    open var customReuseViews:Bool = false
    ///首是否开启刷新动画
    open var refreshWithoutAnimation:Bool = false
#if POOTOOLS_SWIPECELL
    ///设置Swipe的样式
    open var swipeButtonStyle:ButtonStyle = .circular
#endif
    ///索引
    open var sideIndexTitles:[String]?
    ///索引设置
    open var indexConfig:PTCollectionIndexViewConfiguration?
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
    open var indexViewBackgroundColor:UIColor = .clear
    ///索引字体
    open var indexViewFont:UIFont = .appfont(size: 12)
    ///放大索引字体,这个属性只会使用字体名字
    open var indexViewHudFont:UIFont = .appfont(size: 18)
}

//MARK: 界面展示
@objcMembers
public class PTCollectionView: UIView {
                    
    fileprivate var textLayerArray = [PTTextLayer]()
    fileprivate lazy var indicator: UIView = {
        let indicatorRadius = viewConfig.indexConfig!.indicatorRadius
        let indicator = UIView()
        indicator.frame = CGRect(x: 0, y: 0, width: indicatorRadius * 3, height: indicatorRadius * 2)
        indicator.backgroundColor = viewConfig.indexConfig!.indicatorBackgroundColor
        indicator.alpha = 0
        indicator.addSubview(bigTextLabel)
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = indicator.frame
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 2.414 * indicatorRadius, y: indicatorRadius))
        path.addLine(to: CGPoint(x: 1.707 * indicatorRadius, y: 1.707 * indicatorRadius))
        // 注意，这个画线的方法与数学中的坐标系不一样，0在3点钟方向，pi/2在6点钟方向，pi在9点钟方向。。。具体可以看文档
        // 这里是以圆的0.25pi处和1.75pi处的切线的交点为箭头位置
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
        let indicatorRadius = viewConfig.indexConfig!.indicatorRadius
        let label = UILabel()
        label.frame = CGRect(x: 0, y: 0, width: indicatorRadius * 2, height: indicatorRadius * 2)
        label.backgroundColor = viewConfig.indexConfig!.indicatorBackgroundColor
        label.font = UIFont.appCustomFont(size: ceil(indicatorRadius * 1.414),customFont: viewConfig.indexConfig!.indexViewHudFont.fontName)
        label.textAlignment = .center
        label.layer.cornerRadius = indicatorRadius
        label.layer.masksToBounds = true
        label.textColor = viewConfig.indexConfig!.indicatorTextColor
        return label
    }()
    
    fileprivate var layerTopSpacing: CGFloat {
        let count = CGFloat(viewConfig.sideIndexTitles!.count)
        return floor(self.bounds.height - count * viewConfig.indexConfig!.itemSize.height - viewConfig.indexConfig!.itemSpacing * (count - 1)) / 2
    }
    
    fileprivate var isTouched: Bool = false
    
    fileprivate var touchedIndex: Int = 0 {
        didSet {
            if touchedIndex != oldValue {
                self.impactFeedbackGenerator.impactOccurred()
            }
        }
    }
    
    private var _impactFeedbackGenerator: Any? = nil
    fileprivate var impactFeedbackGenerator: UIImpactFeedbackGenerator {
        if _impactFeedbackGenerator == nil {
            _impactFeedbackGenerator = UIImpactFeedbackGenerator()
        }
        return _impactFeedbackGenerator as! UIImpactFeedbackGenerator
    }

    fileprivate var mSections = [PTSection]()
    fileprivate func comboLayout()->UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout.init { section, environment in
            self.generateSection(section: section,environment:environment)
        }
        switch viewConfig.decorationItemsType {
        case .Custom:
            viewConfig.decorationModel?.enumerated().forEach({ index,value in
                layout.register(value.decorationClass, forDecorationViewOfKind: value.decorationID)
            })
        case .Corner:
            layout.register(PTBaseDecorationView_Corner.self, forDecorationViewOfKind: PTBaseDecorationView_Corner.ID)
        case .Normal:
            layout.register(PTBaseDecorationView.self, forDecorationViewOfKind: PTBaseDecorationView.ID)
        default:break
        }
        return layout
    }
    
    fileprivate func generateSection(section:NSInteger,environment:NSCollectionLayoutEnvironment)->NSCollectionLayoutSection {
        
        var group : NSCollectionLayoutGroup
        let behavior : UICollectionLayoutSectionOrthogonalScrollingBehavior = viewConfig.collectionViewBehavior
        
        var sectionModel:PTSection?
        let screenWidth:CGFloat = frame.size.width
        if  mSections.count > 0 {
            sectionModel = mSections[section]
        
            switch viewConfig.viewType {
            case .Gird:
                group = UICollectionView.girdCollectionLayout(data: sectionModel!.rows,groupWidth: screenWidth,itemHeight: viewConfig.itemHeight,cellRowCount: viewConfig.rowCount,originalX: viewConfig.itemOriginalX,topContentSpace: viewConfig.contentTopSpace,bottomContentSpace: viewConfig.contentBottomSpace,cellLeadingSpace: viewConfig.cellLeadingSpace,cellTrailingSpace: viewConfig.cellTrailingSpace)
            case .Normal:
                group = UICollectionView.girdCollectionLayout(data: sectionModel!.rows,groupWidth: screenWidth,itemHeight: viewConfig.itemHeight,cellRowCount: 1,originalX: viewConfig.itemOriginalX,topContentSpace: viewConfig.contentTopSpace,bottomContentSpace: viewConfig.contentBottomSpace,cellTrailingSpace: viewConfig.cellTrailingSpace)
            case .WaterFall:
                group = UICollectionView.waterFallLayout(data: sectionModel!.rows,screenWidth: screenWidth, rowCount: viewConfig.rowCount,itemOriginalX: viewConfig.itemOriginalX, topContentSpace: viewConfig.contentTopSpace,bottomContentSpace: viewConfig.contentBottomSpace,itemSpace: viewConfig.cellLeadingSpace, itemHeight: waterFallLayout!)
            case .Horizontal:
                group = UICollectionView.horizontalLayout(data: sectionModel!.rows,itemOriginalX: viewConfig.itemOriginalX,itemWidth: viewConfig.itemWidth,itemHeight: viewConfig.itemHeight,topContentSpace: viewConfig.contentTopSpace,bottomContentSpace: viewConfig.contentBottomSpace,itemLeadingSpace: viewConfig.cellLeadingSpace)
            case .Custom:
                group = customerLayout!(sectionModel!)
            }
        } else {
            let bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(1), heightDimension: NSCollectionLayoutDimension.absolute(1))
            group = NSCollectionLayoutGroup.init(layoutSize: bannerGroupSize)
        }
        
        var sectionInsets = viewConfig.sectionEdges
        var sectionWidth:CGFloat = 0
        switch viewConfig.decorationItemsType {
        case .Normal,.Corner:
            sectionInsets = NSDirectionalEdgeInsets.init(top: ((sectionModel?.headerHeight ?? CGFloat.leastNormalMagnitude) + viewConfig.contentTopSpace + self.viewConfig.decorationItemsEdges.top),
                                                         leading: sectionInsets.leading,
                                                         bottom: (sectionModel?.footerHeight ?? CGFloat.leastNormalMagnitude) + viewConfig.contentBottomSpace,
                                                         trailing: sectionInsets.trailing)
            sectionWidth = (self.viewConfig.decorationItemsEdges.leading + self.viewConfig.decorationItemsEdges.trailing)
        case .Custom:
            sectionInsets = self.decorationCustomLayoutInsetReset?(section,sectionModel!) ?? NSDirectionalEdgeInsets.zero
        default:
            break
        }
        
        let laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets
        
        switch viewConfig.decorationItemsType {
        case .Custom,.Corner,.Normal:
            if viewConfig.customReuseViews {
                let items = customerReuseViews?(section,sectionModel!) ?? [NSCollectionLayoutBoundarySupplementaryItem]()
                laySection.boundarySupplementaryItems = items
            } else {
                let headerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenWidth - viewConfig.headerWidthOffset - sectionWidth), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel?.headerHeight ?? CGFloat.leastNormalMagnitude + (self.viewConfig.decorationItemsEdges.top * 2 + sectionInsets.top)))
                let footerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenWidth - viewConfig.footerWidthOffset - sectionWidth), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel?.footerHeight ?? CGFloat.leastNormalMagnitude + (self.viewConfig.decorationItemsEdges.top * 2 + sectionInsets.top)))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topTrailing, absoluteOffset: CGPoint(x: -(self.viewConfig.decorationItemsEdges.leading), y:((sectionModel?.headerHeight ?? CGFloat.leastNormalMagnitude) + self.viewConfig.decorationItemsEdges.top * 1)))
                headerItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                let footerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottomTrailing, absoluteOffset: CGPoint(x: -(self.viewConfig.decorationItemsEdges.leading), y:-(sectionInsets.top)))

                var supplementarys = [NSCollectionLayoutBoundarySupplementaryItem]()
                if !(sectionModel?.headerID ?? "").stringIsEmpty() {
                    supplementarys.append(headerItem)
                }
                if !(sectionModel?.footerID ?? "").stringIsEmpty() {
                    supplementarys.append(footerItem)
                }
                laySection.boundarySupplementaryItems = supplementarys
            }
        default:
            let headerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(frame.size.width - viewConfig.headerWidthOffset), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel?.headerHeight ?? CGFloat.leastNormalMagnitude))
            let footerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(frame.size.width - viewConfig.footerWidthOffset), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel?.footerHeight ?? CGFloat.leastNormalMagnitude))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topTrailing)
            let footerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottomTrailing)

            var supplementarys = [NSCollectionLayoutBoundarySupplementaryItem]()
            if !(sectionModel?.headerID ?? "").stringIsEmpty() {
                supplementarys.append(headerItem)
            }
            if !(sectionModel?.footerID ?? "").stringIsEmpty() {
                supplementarys.append(footerItem)
            }
            laySection.boundarySupplementaryItems = supplementarys
        }
                
        switch viewConfig.decorationItemsType {
        case .Custom:
            if  mSections.count > 0 {
                laySection.decorationItems = decorationInCollectionView(section,sectionModel!)
            }
        case .Normal:
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: PTBaseDecorationView.ID)
            backItem.contentInsets = viewConfig.decorationItemsEdges
            laySection.decorationItems = [backItem]
            if #available(iOS 16.0, *) {
                laySection.supplementaryContentInsetsReference = .automatic
            } else {
                laySection.supplementariesFollowContentInsets = true
            }
        case .Corner:
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: PTBaseDecorationView_Corner.ID)
            backItem.contentInsets = viewConfig.decorationItemsEdges
            laySection.decorationItems = [backItem]
            if #available(iOS 16.0, *) {
                laySection.supplementaryContentInsetsReference = .automatic
            } else {
                laySection.supplementariesFollowContentInsets = true
            }
        default:
            break
        }
        
        return laySection
    }
    
    fileprivate lazy var collectionView : UICollectionView = {
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: self.comboLayout())
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.isUserInteractionEnabled = true
        view.showsVerticalScrollIndicator = self.viewConfig.showsVerticalScrollIndicator
        view.showsHorizontalScrollIndicator = self.viewConfig.showsHorizontalScrollIndicator
        if self.viewConfig.topRefresh {
            view.refreshControl = self.refreshControl
        }
#if POOTOOLS_SCROLLREFRESH
        if self.viewConfig.footerRefresh {
            let footerRefresh = PTRefreshAutoStateFooter(refreshingBlock: {
                if self.footRefreshTask != nil {
                    self.footRefreshTask!()
                }
            })
            footerRefresh.setTitle(self.viewConfig.footerRefreshIdle, for: .idle)
            footerRefresh.setTitle(self.viewConfig.footerRefreshPulling, for: .pulling)
            footerRefresh.setTitle(self.viewConfig.footerRefreshRefreshing, for: .refreshing)
            footerRefresh.setTitle(self.viewConfig.footerRefreshWillRefresh, for: .willRefresh)
            footerRefresh.setTitle(self.viewConfig.footerRefreshNoMoreData, for: .noMoreData)
            footerRefresh.stateLabel?.font = self.viewConfig.footerRefreshTextFont
            footerRefresh.stateLabel?.textColor = self.viewConfig.footerRefreshTextColor
            footerRefresh.triggerAutomaticallyRefreshPercent = 0.5
            view.mj_footer = footerRefresh
        }
#endif
        return view
    }()
    
    fileprivate lazy var indexView:UIView = {
        let view = UIView()
        view.backgroundColor = viewConfig.indexConfig?.indexViewBackgroundColor
        return view
    }()
    
    private(set) lazy var refreshControl:UIRefreshControl = {
        let control = UIRefreshControl()
        control.addRefreshHandlers { sender in
            if self.headerRefreshTask != nil {
                self.headerRefreshTask!(sender)
            }
        }
        return control
    }()
    
    //MARK: Cell datasource handler
    ///头部设置
    open var headerInCollection:PTReusableViewHandler?
    ///底部设置
    open var footerInCollection:PTReusableViewHandler?
    ///item设置
    open var cellInCollection:PTCellInCollectionHandler?
    
    //MARK: Cell delegate handler
    ///item点击事件
    open var collectionDidSelect:PTCellDidSelectedHandler?
    ///item将要展示事件
    open var collectionWillDisplay:PTCellDisplayHandler?
    ///item消失事件
    open var collectionDidEndDisplay:PTCellDisplayHandler?
    
    //MARK: UIScrollView call back
    ///UICollectionView的Scroll事件
    open var collectionViewDidScroll:PTCollectionViewScrollHandler?
    open var collectionWillBeginDragging:PTCollectionViewScrollHandler?
    open var collectionDidEndDragging:((UICollectionView,Bool)->Void)?
    open var collectionDidEndDecelerating:PTCollectionViewScrollHandler?
    open var collectionDidEndScrollingAnimation:PTCollectionViewScrollHandler?
    open var collectionDidScrolltoTop:PTCollectionViewScrollHandler?

    ///头部刷新事件
    open var headerRefreshTask:((UIRefreshControl)->Void)?
    ///底部刷新事件
    open var footRefreshTask:PTActionTask?
    
    //MARK: Cell layout (仅仅限于在瀑布流或者自定义的情况下使用)
    ///瀑布流item高度设置
    open var waterFallLayout:((Int, AnyObject) -> CGFloat)?
    
    ///自定义情况下调用该设置
    ///其中Config中只会生效headerWidthOffset和footerWidthOffset唯一配置,其他位移配置和item高度不会生效
    open var customerLayout:((PTSection) -> NSCollectionLayoutGroup)?
    
    ///自定义情况下调用该设置
    ///这个是用来设置Header跟Footer的
    open var customerReuseViews:((Int,PTSection) -> [NSCollectionLayoutBoundarySupplementaryItem])?

    ///当空数据View展示的时候,点击回调
    open var emptyTap:((UIView?)->Void)?
    
    ///CollectionView的DecorationItem囘調(自定義模式下使用)
    open var decorationInCollectionView:PTDecorationInCollectionHandler!
    
    ///CollectionView的DecorationItem重新設置囘調(自定義模式下使用)
    open var decorationViewReset:PTViewInDecorationResetHandler?
    
    ///CollectionView的DecorationItem内的Item与Header&Footer重新設置囘調(自定義模式下使用)
    open var decorationCustomLayoutInsetReset:((Int,PTSection) ->NSDirectionalEdgeInsets)?
    
    public var contentCollectionView:UICollectionView {
        get {
            collectionView
        }
    }
    
    //MARK: Swipe handler(Cell须要引用SwipeCellKit)
#if POOTOOLS_SWIPECELL
    ///设置IndexPath是否开启向左swipe
    open var indexPathSwipe:PTCollectionViewCanSwipeHandler?
    ///设置IndexPath是否开启向右swipe
    open var indexPathSwipeRight:PTCollectionViewCanSwipeHandler?
    ///设置向左滑动作
    open var swipeLeftHandler:PTCollectionViewSwipeHandler?
    ///设置向右滑动作
    open var swipeRightHandler:PTCollectionViewSwipeHandler?
    ///设置滑动content的间隔
    open var swipeContentSpaceHandler:((_ collectionView:UICollectionView,_ orientation: SwipeActionsOrientation,_ indexPath:IndexPath) -> CGFloat)?
#endif
    
    public var viewConfig:PTCollectionViewConfig! {
        didSet {
            if viewConfig.sideIndexTitles?.count ?? 0 > 0 && viewConfig.indexConfig != nil {
                indicator.removeFromSuperview()
                indexView.removeFromSuperview()
                collectionView.removeFromSuperview()
                clearTextLayers()
                addSubview(collectionView)
                collectionView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                setIndexViews()
            }
        }
    }
    
    //MARK: 界面展示
    public init(viewConfig: PTCollectionViewConfig!) {
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        self.viewConfig = viewConfig
        self.collectionView.addObserver(self, forKeyPath: kPTCollectionIndexViewContentOffsetKeyPath, options: .new, context: &kPTCollectionIndexViewContent)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
#if POOTOOLS_LISTEMPTYDATA
        if self.viewConfig.showEmptyAlert {
            if #unavailable(iOS 17.0) {
                if self.viewConfig.emptyViewConfig != nil {
                    self.showEmptyDataSet(currentScroller: collectionView)
                    self.lxf_tapEmptyView(collectionView) { sender in
                        if self.emptyTap != nil {
                            self.emptyTap!(sender)
                        }
                    }
                }
            } else {
                PTGCDManager.gcdAfter(time: 0.1) {
                    if self.viewConfig.emptyViewConfig != nil {
                        let share = PTUnavailableFunction.share
                        share.emptyViewConfig = self.viewConfig.emptyViewConfig!
                        self.showEmptyConfig()
                    }
                }
            }
        }
#else
        PTGCDManager.gcdAfter(time: 0.1) {
            if #available(iOS 17.0, *) {
                if self.viewConfig.emptyViewConfig != nil {
                    let share = PTUnavailableFunction.share
                    share.emptyViewConfig = self.viewConfig.emptyViewConfig!
                    self.showEmptyConfig()
                }
            }
        }
#endif
        
        if #available(iOS 17.0, *) {
            if self.viewConfig.showEmptyAlert {
                PTUnavailableFunction.share.emptyTap = {
                    PTGCDManager.gcdMain {
                        self.showEmptyLoading()
                    }

                    PTGCDManager.gcdAfter(time: 0.1) {
                        if self.emptyTap != nil {
                            self.emptyTap!(nil)
                        }
                    }
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        collectionView.removeObserver(self, forKeyPath: kPTCollectionIndexViewContentOffsetKeyPath)
    }
    
    ///展示界面
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func clearTextLayers() {
        if let sublayers = self.layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    func setIndexViews() {
        if viewConfig.sideIndexTitles?.count ?? 0 > 0 && viewConfig.indexConfig != nil {
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
    
    ///加载数据并且刷新界面
    public func showCollectionDetail(collectionData:[PTSection],finishTask:((UICollectionView)->Void)? = nil) {
        mSections.removeAll()
        
        mSections = collectionData
        
        collectionView.pt_register(by: mSections)
        if viewConfig.refreshWithoutAnimation {
            collectionView.reloadDataWithOutAnimation {
                if #available(iOS 17.0, *) {
                    self.showEmptyConfig()
                }

                PTGCDManager.gcdAfter(time: 0.1) {
                    if finishTask != nil {
                        finishTask!(self.collectionView)
                    }
                }
            }
        } else {
            collectionView.reloadData {
                if #available(iOS 17.0, *) {
                    self.showEmptyConfig()
                }

                PTGCDManager.gcdAfter(time: 0.1) {
                    if finishTask != nil {
                        finishTask!(self.collectionView)
                    }
                }
            }
        }
    }
    
    public func clearAllData(finishTask:((UICollectionView)->Void)? = nil) {
        mSections.removeAll()
        collectionView.pt_register(by: mSections)
        PTGCDManager.gcdAfter(time: 0.1) {
            if self.viewConfig.refreshWithoutAnimation {
                self.collectionView.reloadDataWithOutAnimation {
                    if #available(iOS 17.0, *) {
                        self.showEmptyConfig()
                    }
                    PTGCDManager.gcdAfter(time: 0.35) {
                        if finishTask != nil {
                            finishTask!(self.collectionView)
                        }
                    }
                }
            } else {
                self.collectionView.reloadData {
                    if #available(iOS 17.0, *) {
                        self.showEmptyConfig()
                    }
                    PTGCDManager.gcdAfter(time: 0.35) {
                        if finishTask != nil {
                            finishTask!(self.collectionView)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: 刷新相关
    ///停止头部或者底部的刷新控件使用
    public func endRefresh() {
#if POOTOOLS_SCROLLREFRESH
        if viewConfig.footerRefresh {
            collectionView.pt_endMJRefresh()
        }
#endif
        
        if viewConfig.topRefresh {
            refreshControl.endRefreshing()
        }
    }
    
#if POOTOOLS_SCROLLREFRESH
    ///展示底部已经没有更多数据
    public func footerRefreshNoMore () {
        collectionView.mj_footer?.endRefreshingWithNoMoreData()
    }
    
    public func footerRefreshReset() {
        collectionView.mj_footer?.resetNoMoreData()
    }
#endif
    
#if POOTOOLS_PAGINGCONTROL
    ///用于SegmentView上
    public func segmentScrolView() -> UIScrollView {
        collectionView
    }
#endif
    
    ///用户获取CollectionView的可视cell
    public func visibleCells() -> [UICollectionViewCell] {
        collectionView.visibleCells
    }
    
    ///滚动到某一个Item
    public func scrolToItem(indexPath:IndexPath,position:UICollectionView.ScrollPosition) {
        collectionView.scrollToItem(at: indexPath, at: position, animated: true)
    }
    
    public func mtSelectItem(indexPath:IndexPath,animated:Bool,scrollPosition:UICollectionView.ScrollPosition) {
        collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
    }
        
    @available(iOS 17, *)
    private func showEmptyConfig() {
        if viewConfig.showEmptyAlert && (mSections.first?.rows.count ?? 0) == 0 {
            PTUnavailableFunction.share.hideUnavailableView(showIn: self) {
                PTUnavailableFunction.share.showEmptyView(showIn: self)
            }
        } else {
            PTUnavailableFunction.share.hideUnavailableView(showIn: self) {
            }
        }
    }
    
    @available(iOS 17, *)
    public func hideEmptyLoading(task: PTActionTask?) {
        PTUnavailableFunction.share.hideUnavailableView(showIn: self,task: task)
    }
    
    @available(iOS 17, *)
    public func showEmptyLoading() {
        PTUnavailableFunction.share.showEmptyLoadingView(showIn: self)
    }
}

//MARK: UICollectionViewDelegate && UICollectionViewDataSource
extension PTCollectionView:UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        mSections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mSections.count == 0 ? 0 : mSections[section].rows.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            if (!(itemSec.headerID ?? "").stringIsEmpty() && itemSec.headerCls != nil) || (!(itemSec.footerID ?? "").stringIsEmpty() && itemSec.footerCls != nil) {
                if kind == UICollectionView.elementKindSectionHeader {
                    return headerInCollection?(kind,collectionView,itemSec,indexPath) ?? UICollectionReusableView()
                } else if kind == UICollectionView.elementKindSectionFooter {
                    return footerInCollection?(kind,collectionView,itemSec,indexPath) ?? UICollectionReusableView()
                } else {
                    return UICollectionReusableView()
                }
            } else {
                return UICollectionReusableView()
            }
        } else {
            return UICollectionReusableView()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            
            let cell = cellInCollection?(collectionView,itemSec,indexPath) ?? UICollectionViewCell()
#if POOTOOLS_SWIPECELL
            if let swipeCell = cell as? SwipeCollectionViewCell {
                if indexPathSwipe != nil {
                    let swipe = indexPathSwipe!(itemSec,indexPath)
                    if swipe {
                        swipeCell.delegate = self
                    } else {
                        swipeCell.delegate = nil
                    }
                } else {
                    swipeCell.delegate = nil
                }
                return swipeCell
            } else {
                return cell
            }
#else
            return cell
#endif
        } else {
            return UICollectionViewCell()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemSec = mSections[indexPath.section]
        if collectionDidSelect != nil {
            collectionDidSelect!(collectionView,itemSec,indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            if collectionDidEndDisplay != nil {
                collectionDidEndDisplay!(collectionView,cell,itemSec,indexPath)
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            if collectionWillDisplay != nil {
                collectionWillDisplay!(collectionView,cell,itemSec,indexPath)
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if mSections.count > 0 {
            let itemSec = mSections[indexPath.section]
            if decorationViewReset != nil {
                decorationViewReset!(collectionView,view,elementKind,indexPath,itemSec)
            }
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if collectionViewDidScroll != nil {
            collectionViewDidScroll!(scrollView as! UICollectionView)
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if collectionWillBeginDragging != nil {
            collectionViewDidScroll!(scrollView as! UICollectionView)
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if collectionDidEndDragging != nil {
            collectionDidEndDragging!(scrollView as! UICollectionView,decelerate)
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if collectionDidEndDecelerating != nil {
            collectionDidEndDecelerating!(scrollView as! UICollectionView)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if collectionDidEndScrollingAnimation != nil {
            collectionDidEndScrollingAnimation!(scrollView as! UICollectionView)
        }
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        if collectionDidScrolltoTop != nil {
            collectionDidScrolltoTop!(scrollView as! UICollectionView)
        }
    }
}

//MARK: LXFEmptyDataSetable
#if POOTOOLS_LISTEMPTYDATA
extension PTCollectionView:LXFEmptyDataSetable {
    
    public func showEmptyDataSet(currentScroller: UIScrollView) {
        
        var font:UIFont = .appfont(size: 15)
        var textColor:UIColor = .black

        let range = NSRange(location:0,length:self.viewConfig.emptyViewConfig?.mainTitleAtt?.value.length ?? 0)
        self.viewConfig.emptyViewConfig?.mainTitleAtt?.value.enumerateAttributes(in: range, options: [], using: { att,range,_ in
            if let attFont = att[NSAttributedString.Key.font] as? UIFont {
                font = attFont
            }
            
            if let attColor = att[NSAttributedString.Key.foregroundColor] as? UIColor {
                textColor = attColor
            }
        })
        
        let firstString = self.viewConfig.emptyViewConfig?.mainTitleAtt?.value.string ?? ""
        let secondary = self.viewConfig.emptyViewConfig?.secondaryEmptyAtt?.value.string ?? ""
        
        var total = ""
        if !firstString.stringIsEmpty() && secondary.stringIsEmpty() {
            total = firstString
        } else if !firstString.stringIsEmpty() && !secondary.stringIsEmpty() {
            total = firstString + "\n" + secondary
        } else if firstString.stringIsEmpty() && secondary.stringIsEmpty() {
            total = ""
        } else if firstString.stringIsEmpty() && !secondary.stringIsEmpty() {
            total = secondary
        }
        
        self.lxf_EmptyDataSet(currentScroller) { () -> [LXFEmptyDataSetAttributeKeyType : Any] in
            [
                .tipStr: total,
                .tipColor: textColor,
                .tipFont:font,
                .verticalOffset: 0,
                .tipImage: self.viewConfig.emptyViewConfig?.image as Any
            ]
        }
    }
    
    open func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        let buttonAtt:ASAttributedString = """
                    \(wrap: .embedding("""
                    \(self.viewConfig.emptyViewConfig?.buttonTitle ?? "",.font(self.viewConfig.emptyViewConfig?.buttonFont ?? .appfont(size: 14)),.paragraph(.alignment(.center),.lineSpacing(7.5)),.foreground(self.viewConfig.emptyViewConfig?.buttonTextColor ?? PTAppBaseConfig.share.viewDefaultTextColor))
                    """))
                    """
        return buttonAtt.value
    }
}
#endif

//MARK: 滑动Cell设置
#if POOTOOLS_SWIPECELL
extension PTCollectionView:SwipeCollectionViewCellDelegate {
    
    func swipe_cell_configure_action(swipeType:SwipeActionStyle = .destructive,
                                     title:String,
                                     titleFont:UIFont = UIFont.appfont(size: 13),
                                     with descriptor: ActionDescriptor,
                                     buttonDisplayMode: ButtonDisplayMode? = .imageOnly,
                                     customImage:Any? = nil,
                                     customColor:UIColor? = .clear,
                                     handler: ((SwipeAction, IndexPath) -> Void)?) -> SwipeAction {
        var titleAction:String? = ""
        switch buttonDisplayMode {
        case .imageOnly:
            titleAction = nil
        case .titleAndImage:
            titleAction = title
        case .titleOnly:
            titleAction = title
        default:break
        }
        let action = SwipeAction(style: swipeType, title: titleAction, handler: handler)
        
        let cellHeight = viewConfig.itemHeight == 0 ? PTAppBaseConfig.share.baseCellHeight : viewConfig.itemHeight
        
        var actionImage:UIImage?
        switch buttonDisplayMode {
        case .imageOnly,.titleAndImage:
            switch descriptor {
            case .custom:
                if customImage == nil {
                    actionImage = nil
                } else {
                    PTLoadImageFunction.loadImage(contentData: customImage as Any) { images, image in
                        if (images?.count ?? 0 ) > 1 {
                            actionImage = UIImage.animatedImage(with: images!, duration: 2)
                        } else if (images?.count ?? 0 ) == 1 {
                            actionImage = image
                        } else {
                            actionImage = PTAppBaseConfig.share.defaultEmptyImage
                        }
                    }
                    
                    var circularIconSize:CGSize = .zero
                    switch buttonDisplayMode {
                    case .imageOnly:
                        circularIconSize = CGSize(width: cellHeight - 10, height: cellHeight - 10)
                    default:
                        circularIconSize = CGSize(width: cellHeight - 30, height: cellHeight - 30)
                    }
                    actionImage = actionImage!.transformImage(size: circularIconSize)
                }
            default:
                actionImage = descriptor.image(forStyle: viewConfig.swipeButtonStyle, displayMode: buttonDisplayMode!,cellHeight: cellHeight)
            }
        default:break
        }
        
        switch buttonDisplayMode {
        case .imageOnly:
            action.image = actionImage
        case .titleAndImage:
            action.image = actionImage
            action.font = titleFont
        case .titleOnly:
            action.font = titleFont
        default:break
        }
        action.hidesWhenSelected = true
        
        switch viewConfig.swipeButtonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color(forStyle: viewConfig.swipeButtonStyle,customColor: customColor)
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color(forStyle: viewConfig.swipeButtonStyle,customColor: customColor)
            action.transitionDelegate = ScaleTransition.default
        }
        return action
   }
   
    public func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = orientation == .left ? .selection : .destructive(automaticallyDelete: false)
        options.transitionStyle = .border

        if swipeContentSpaceHandler != nil {
            options.buttonSpacing = swipeContentSpaceHandler!(collectionView,orientation,indexPath)
        } else {
            options.buttonSpacing = 0
        }
        return options
   }
   
    public func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if orientation == .right {

            if swipeLeftHandler != nil {
                let itemSec = mSections[indexPath.section]
                return swipeLeftHandler!(collectionView,itemSec,indexPath)
            }
            
            return []
        } else {
            if indexPathSwipeRight != nil {
                let itemSec = mSections[indexPath.section]
                let swipeRight = indexPathSwipeRight!(itemSec,indexPath)
                if swipeRight {
                    if swipeRightHandler != nil {
                        let itemSec = mSections[indexPath.section]
                        return swipeRightHandler!(collectionView,itemSec,indexPath)
                    }
                    return []
                } else {
                    return []
                }
            } else {
                return []
            }
        }
    }
}
#endif

//MARK: 索引设置
private extension PTCollectionView {
    
    func setupUI() {
        var layerArray = [PTTextLayer]()
        for i in 0 ..< viewConfig.sideIndexTitles!.count {
            let title = viewConfig.sideIndexTitles![i]
            let textLayer = PTTextLayer()
            textLayer.index = i
            textLayer.font = CTFontCreateWithName(viewConfig.indexConfig!.indexViewFont.fontName as CFString, viewConfig.indexConfig!.indexViewFont.pointSize, nil)
            textLayer.fontSize = viewConfig.indexConfig!.indexViewFont.pointSize
            textLayer.alignmentMode = CATextLayerAlignmentMode.center
            textLayer.string = title
            textLayer.frame = self.frame(forTextLayer: textLayer)
            textLayer.cornerRadius = viewConfig.indexConfig!.itemSize.width / 2
            textLayer.masksToBounds = true
            textLayer.position = self.frame(forTextLayer: textLayer).origin
            self.layer.zPosition = CGFloat.greatestFiniteMagnitude
            self.layer.insertSublayer(textLayer, above: nil)
            layerArray.append(textLayer)
        }
        self.textLayerArray = layerArray
        self.updateTextLayers(forSelectedIndex: 0)
        
        self.addSubview(self.indicator)
    }
    
    func frame(forTextLayer textLayer: PTTextLayer) -> CGRect {
        let width = viewConfig.indexConfig!.itemSize.width
        let height = viewConfig.indexConfig!.itemSize.height
        return CGRect(x: self.bounds.width - width, y: layerTopSpacing + CGFloat(textLayer.index) * height + viewConfig.indexConfig!.itemSpacing * CGFloat(textLayer.index), width: width, height: height)
    }
    
    func showIndicator(forTextLayer textLayer: PTTextLayer) {
        //直接修改calayer属性是有默认的隐式动画的，可以用CATransaction关闭隐式动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        indicator.center = CGPoint(x: self.frame.size.width - indicator.frame.size.width / 2 - viewConfig.indexConfig!.itemSize.width, y: textLayer.position.y)
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
            // 用这种计算方法可以不考虑layout的sectionHeadersPinToVisibleBounds属性
            // 如果直接用attributes的frame需要考虑sectionHeadersPinToVisibleBounds
            collectionView.setContentOffset(targetPoint, animated: animated)
        } else {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
        }
    }
    
    func updateTextLayers(forSelectedIndex index: Int) {
        for textLayer in textLayerArray {
            if textLayer.index == index {
                textLayer.backgroundColor = viewConfig.indexConfig!.itemSelectedBackgroundColor.cgColor
                textLayer.foregroundColor = viewConfig.indexConfig!.itemSelectedTextColor.cgColor
            } else {
                textLayer.backgroundColor = viewConfig.indexConfig!.itemBackgroundColor.cgColor
                textLayer.foregroundColor = viewConfig.indexConfig!.itemTextColor.cgColor
            }
        }
    }
}

//MARK: KVO
extension PTCollectionView {
        
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let context = context, context == &kPTCollectionIndexViewContent,
            let keyPath = keyPath, keyPath == kPTCollectionIndexViewContentOffsetKeyPath {
            guard isTouched == false else { return }
            let indexPathArray = self.collectionView.indexPathsForVisibleItems
            let minIndexPath = indexPathArray.min { (one, two) -> Bool in
                return one.section <= two.section
            }
            if let temp = minIndexPath?.section {
                updateTextLayers(forSelectedIndex: temp)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

//MARK: 触摸事件
extension PTCollectionView {
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        if view == self {
            let rect = CGRect(x: self.frame.size.width - viewConfig.indexConfig!.itemSize.width, y: layerTopSpacing, width: viewConfig.indexConfig!.itemSize.width, height: self.frame.size.height - layerTopSpacing * 2)
            if rect.contains(point) {
                return self
            } else {
                return nil
            }
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
        
        /// 为了达到微信的效果，即开始后就算滑动到非索引区域也行，这里不能用frame的包含，用了一条横线是否与textLayer相交来判断
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
