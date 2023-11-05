//
//  PTCollectionView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if POOTOOLS_SCROLLREFRESH
import MJRefresh
#endif

#if POOTOOLS_LISTEMPTYDATA
import LXFProtocolTool
import AttributedString
#endif

//MARK: CollectionView展示的样式类型
public enum PTCollectionViewType {
    case Normal
    case Gird
    case WaterFall
    case Custom
}

//MARK: Collection展示的Section底部样式类型
public enum PTCollectionViewDecorationItemsType {
    case Corner
    case NoCorner
    case NoItems
}

///ReusableView回调
/// - Parameters:
///   - kind: header的头部kind
///   - collectionView: collectionView
///   - sectionModel: Section的model
///   - indexPath: 坐标
///  - Return: UICollectionReusableView
public typealias PTReusableViewHandler = (_ kind: String,_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath: IndexPath) -> UICollectionReusableView

///Cell设置
/// - Parameters:
///   - collectionView: collectionView
///   - sectionModel: Section的model
///   - index: 坐标
///  - Return: UICollectionViewCell
public typealias PTCellInCollectionHandler = (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> UICollectionViewCell

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

//MARK: Collection展示的基本配置参数设置
public class PTCollectionViewConfig:PTBaseModel {
    ///CollectionView展示的样式类型
    public var viewType:PTCollectionViewType = .Normal
    ///每行多少个(仅在瀑布流和Gird样式中使用)
    public var rowCount:Int = 3
    ///item高度
    public var itemHeight:CGFloat = PTAppBaseConfig.share.baseCellHeight
    ///item起始坐标X
    public var itemOriginalX:CGFloat = 0
    ///item的展示距离顶部和底部的高度
    public var contentTopAndBottom:CGFloat = 0
    ///每个item的间隔(左右)
    public var cellLeadingSpace:CGFloat = 0
    ///每个item的间隔(上下)
    public var cellTrailingSpace:CGFloat = 0
    ///是否开启头部刷新
    public var topRefresh:Bool = false
#if POOTOOLS_SCROLLREFRESH
    ///是否开启底部刷新
    public var footerRefresh:Bool = false
#endif
    ///section偏移
    public var sectionEdges:NSDirectionalEdgeInsets = .zero
    ///头部长度偏移
    public var headerWidthOffset:CGFloat = 0
    ///底部长度偏移
    public var footerWidthOffset:CGFloat = 0
    
#if POOTOOLS_LISTEMPTYDATA
    ///是否开启空数据展示
    public var showEmptyAlert:Bool = false
    ///空数据展示参数设置
    public var emptyViewConfig:[LXFEmptyDataSetAttributeKeyType : Any]?
    ///空数据展示按钮富文本设置
    public var buttonAtt:ASAttributedString?
#endif
    ///Collection展示的Section底部样式类型
    public var decorationItemsType:PTCollectionViewDecorationItemsType = .NoItems
    ///Collection展示的Section底部样式偏移
    public var decorationItemsEdges:NSDirectionalEdgeInsets = .zero
    ///Collection展示的Section底部样式偏移
    public var collectionViewBehavior:UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous
}

//MARK: 界面展示
public class PTCollectionView: UIView {
    
    let decorationViewOfKindCorner = "background"
    let decorationViewOfKindNormal = "background_no"
    
    fileprivate var mSections = [PTSection]()
    fileprivate func comboLayout()->UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout.init { section, environment in
            self.generateSection(section: section)
        }
        layout.register(PTBaseDecorationView_Corner.self, forDecorationViewOfKind: decorationViewOfKindCorner)
        layout.register(PTBaseDecorationView.self, forDecorationViewOfKind: decorationViewOfKindNormal)
        return layout
    }
    
    fileprivate func generateSection(section:NSInteger)->NSCollectionLayoutSection {
        
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
            let bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(0), heightDimension: NSCollectionLayoutDimension.absolute(0))
            group = NSCollectionLayoutGroup.init(layoutSize: bannerGroupSize)
        }
        
        let sectionInsets = viewConfig.sectionEdges
        let laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets
        
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
        
        switch viewConfig.decorationItemsType {
        case .Corner,.NoCorner:
            var itemKind = ""
            switch viewConfig.decorationItemsType {
            case .Corner:
                itemKind = decorationViewOfKindCorner
            case .NoCorner:
                itemKind = decorationViewOfKindNormal
            default:
                break
            }
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: itemKind)
            backItem.contentInsets = viewConfig.decorationItemsEdges
            laySection.decorationItems = [backItem]
            
            laySection.supplementariesFollowContentInsets = false
        default:
            break
        }
        return laySection
    }
    
    fileprivate lazy var collectionView : UICollectionView = {
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: self.comboLayout())
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
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
    public var headerInCollection:PTReusableViewHandler?
    ///底部设置
    public var footerInCollection:PTReusableViewHandler?
    ///item设置
    public var cellInCollection:PTCellInCollectionHandler!
    
    //MARK: Cell delegate handler
    ///item点击事件
    public var collectionDidSelect:PTCellDidSelectedHandler?
    ///item将要展示事件
    public var collectionWillDisplay:PTCellDisplayHandler?
    ///item消失事件
    public var collectionDidEndDisplay:PTCellDisplayHandler?
    ///UICollectionView的Scroll事件
    public var collectionViewDidScrol:((UICollectionView)->Void)?

    ///头部刷新事件
    public var headerRefreshTask:((UIRefreshControl)->Void)?
    ///底部刷新事件
    public var footRefreshTask:PTActionTask?
    
    //MARK: Cell layout (仅仅限于在瀑布流或者自定义的情况下使用)
    ///瀑布流item高度设置
    public var waterFallLayout:((Int, AnyObject) -> CGFloat)?
    
    ///自定义情况下调用该设置
    ///其中Config中只会生效headerWidthOffset和footerWidthOffset唯一配置,其他位移配置和item高度不会生效
    public var customerLayout:((PTSection) -> NSCollectionLayoutGroup)?
    
#if POOTOOLS_LISTEMPTYDATA
    ///空数据点击事件
    public var emptyTap:((UIView)->Void)?
#endif
    
    fileprivate var viewConfig:PTCollectionViewConfig = PTCollectionViewConfig()
    
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
            self.showEmptyDataSet(currentScroller: collectionView)
            self.lxf_tapEmptyView(collectionView) { sender in
                if self.emptyTap != nil {
                    self.emptyTap!(sender)
                }
            }
        }
#endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///展示界面
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
    }
    
    ///加载数据并且刷新界面
    public func showCollectionDetail(collectionData:[PTSection],finishTask:((UICollectionView)->Void)? = nil) {
        mSections.removeAll()
        
        mSections = collectionData
        
        collectionView.pt_register(by: mSections)
        self.collectionView.reloadData {
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
        self.collectionView.mj_footer?.endRefreshingWithNoMoreData()
    }
#endif
    
#if POOTOOLS_PAGINGCONTROL
    ///用于SegmentView上
    public func segmentScrolView() -> UIScrollView {
        self.collectionView
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
}

//MARK: UICollectionViewDelegate && UICollectionViewDataSource
extension PTCollectionView:UICollectionViewDelegate,UICollectionViewDataSource {

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
            return cellInCollection(collectionView,itemSec,indexPath)
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
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if collectionViewDidScrol != nil {
            collectionViewDidScrol!(self.collectionView)
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
}

#if POOTOOLS_LISTEMPTYDATA
//MARK: LXFEmptyDataSetable
extension PTCollectionView:LXFEmptyDataSetable {
    public func showEmptyDataSet(currentScroller: UIScrollView) {
        self.lxf_EmptyDataSet(currentScroller) { () -> [LXFEmptyDataSetAttributeKeyType : Any] in
            self.viewConfig.emptyViewConfig!
        }
    }
    
    open func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        self.viewConfig.buttonAtt?.value
    }
}
#endif
