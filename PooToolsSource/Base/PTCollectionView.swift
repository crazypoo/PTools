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

//MARK: CollectionView展示的样式类型
@objc public enum PTCollectionViewType:Int {
    case Normal
    case Gird
    case WaterFall
    case Custom
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

public typealias PTCollectionViewCanSwipeHandler = (_ indexPath:IndexPath) -> Bool

public typealias PTDecorationInCollectionHandler = (_ index:Int,_ sectionModel:PTSection) -> [NSCollectionLayoutDecorationItem]

public typealias PTViewInDecorationResetHandler = (_ collectionView: UICollectionView, _ view: UICollectionReusableView, _ elementKind: String, _ indexPath: IndexPath,_ sectionModel: PTSection) -> Void

//MARK: Collection展示的基本配置参数设置
@objcMembers
public class PTCollectionViewConfig:NSObject {
    open var showsVerticalScrollIndicator:Bool = true
    open var showsHorizontalScrollIndicator:Bool = true
    ///CollectionView展示的样式类型
    open var viewType:PTCollectionViewType = .Normal
    ///每行多少个(仅在瀑布流和Gird样式中使用)
    open var rowCount:Int = 3
    ///item高度
    open var itemHeight:CGFloat = PTAppBaseConfig.share.baseCellHeight
    ///item起始坐标X
    open var itemOriginalX:CGFloat = 0
    ///item的展示距离顶部和底部的高度
    open var contentTopAndBottom:CGFloat = 0
    ///每个item的间隔(左右)
    open var cellLeadingSpace:CGFloat = 0
    ///每个item的间隔(上下)
    open var cellTrailingSpace:CGFloat = 0
    ///是否开启头部刷新
    open var topRefresh:Bool = false
#if POOTOOLS_SCROLLREFRESH
    ///是否开启底部刷新
    open var footerRefresh:Bool = false
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
    
#if POOTOOLS_SWIPECELL
    ///设置Swipe的样式
    open var swipeButtonStyle:ButtonStyle = .circular
#endif
}

//MARK: 界面展示
@objcMembers
public class PTCollectionView: UIView {
            
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
        if  mSections.count > 0 {
            sectionModel = mSections[section]
            switch viewConfig.viewType {
            case .Gird:
                group = UICollectionView.girdCollectionLayout(data: sectionModel!.rows,groupWidth: frame.size.width,itemHeight: viewConfig.itemHeight,cellRowCount: viewConfig.rowCount,originalX: viewConfig.itemOriginalX,contentTopAndBottom: viewConfig.contentTopAndBottom,cellLeadingSpace: viewConfig.cellLeadingSpace,cellTrailingSpace: viewConfig.cellTrailingSpace)
            case .Normal:
                group = UICollectionView.girdCollectionLayout(data: sectionModel!.rows,groupWidth: frame.size.width,itemHeight: viewConfig.itemHeight,cellRowCount: 1,originalX: viewConfig.itemOriginalX,contentTopAndBottom: viewConfig.contentTopAndBottom,cellTrailingSpace: viewConfig.cellTrailingSpace)
            case .WaterFall:
                group = UICollectionView.waterFallLayout(data: sectionModel!.rows, rowCount: viewConfig.rowCount,itemOriginalX: viewConfig.itemOriginalX, itemOriginalY: viewConfig.contentTopAndBottom,itemSpace: viewConfig.cellLeadingSpace, itemHeight: waterFallLayout!)
            case .Custom:
                group = customerLayout!(sectionModel!)
            }
        } else {
            let bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(1), heightDimension: NSCollectionLayoutDimension.absolute(1))
            group = NSCollectionLayoutGroup.init(layoutSize: bannerGroupSize)
        }
        
        let sectionInsets = viewConfig.sectionEdges
        
        let laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets
        
        if viewConfig.customReuseViews {
            let items = customerReuseViews?(sectionModel!) ?? [NSCollectionLayoutBoundarySupplementaryItem]()
            laySection.boundarySupplementaryItems = items
        } else {
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
            footerRefresh.triggerAutomaticallyRefreshPercent = 0.5
            view.mj_footer = footerRefresh
        }
#endif
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
    open var customerReuseViews:((PTSection) -> [NSCollectionLayoutBoundarySupplementaryItem])?

    ///当空数据View展示的时候,点击回调
    open var emptyTap:((UIView?)->Void)?
    
    ///CollectionView的DecorationItem囘調(自定義模式下使用)
    open var decorationInCollectionView:PTDecorationInCollectionHandler!
    
    ///CollectionView的DecorationItem重新設置囘調(自定義模式下使用)
    open var decorationViewReset:PTViewInDecorationResetHandler?
    
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
    
    public var viewConfig:PTCollectionViewConfig = PTCollectionViewConfig()
    
    //MARK: 界面展示
    public init(viewConfig: PTCollectionViewConfig!) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
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
    
    ///展示界面
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    ///加载数据并且刷新界面
    public func showCollectionDetail(collectionData:[PTSection],finishTask:((UICollectionView)->Void)? = nil) {
        mSections.removeAll()
        
        mSections = collectionData
        
        collectionView.pt_register(by: mSections)
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
    
    public func clearAllData(finishTask:((UICollectionView)->Void)? = nil) {
        mSections.removeAll()
        collectionView.pt_register(by: mSections)
        PTGCDManager.gcdAfter(time: 0.1) {
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
            if !(itemSec.headerID ?? "").stringIsEmpty() || !(itemSec.footerID ?? "").stringIsEmpty() {
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
                    let swipe = indexPathSwipe!(indexPath)
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
}

#if POOTOOLS_LISTEMPTYDATA
//MARK: LXFEmptyDataSetable
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
                let swipeRight = indexPathSwipeRight!(indexPath)
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
