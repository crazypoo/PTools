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

public enum PTCollectionViewType {
    case Normal
    case Gird
    case WaterFall
}

public enum PTCollectionViewDecorationItemsType {
    case Corner
    case NoCorner
    case NoItems
}

public class PTCollectionViewConfig:PTBaseModel {
    public var viewType:PTCollectionViewType = .Normal
    public var rowCount:Int = 3
    public var itemHeight:CGFloat = PTAppBaseConfig.share.baseCellHeight
    public var itemOriginalX:CGFloat = 0
    public var contentTopAndBottom:CGFloat = 0
    public var cellLeadingSpace:CGFloat = 0
    public var cellTrailingSpace:CGFloat = 0
    public var topRefresh:Bool = false
#if POOTOOLS_SCROLLREFRESH
    public var footerRefresh:Bool = false
#endif
    public var sectionEdges:NSDirectionalEdgeInsets = .zero
    public var headerWidthOffset:CGFloat = 0
    public var footerWidthOffset:CGFloat = 0

#if POOTOOLS_LISTEMPTYDATA
    public var showEmptyAlert:Bool = false
    public var emptyViewConfig:[LXFEmptyDataSetAttributeKeyType : Any]?
    public var buttonAtt:ASAttributedString?
#endif
    public var decorationItemsType:PTCollectionViewDecorationItemsType = .NoItems
    public var decorationItemsEdges:NSDirectionalEdgeInsets = .zero
}

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
        let sectionModel = mSections[section]

        var group : NSCollectionLayoutGroup
        let behavior : UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous
        
        switch self.viewConfig.viewType {
        case .Gird:
            group = UICollectionView.girdCollectionLayout(data: sectionModel.rows,groupWidth: self.frame.size.width,itemHeight: self.viewConfig.itemHeight,cellRowCount: self.viewConfig.rowCount,originalX: self.viewConfig.itemOriginalX,contentTopAndBottom: self.viewConfig.contentTopAndBottom,cellLeadingSpace: self.viewConfig.cellLeadingSpace,cellTrailingSpace: self.viewConfig.cellTrailingSpace)
        case .Normal:
            group = UICollectionView.girdCollectionLayout(data: sectionModel.rows,groupWidth: self.frame.size.width,itemHeight: self.viewConfig.itemHeight,cellRowCount: 1,originalX: self.viewConfig.itemOriginalX,contentTopAndBottom: self.viewConfig.contentTopAndBottom,cellTrailingSpace: self.viewConfig.cellTrailingSpace)
        case .WaterFall:
            group = UICollectionView.waterFallLayout(data: sectionModel.rows, rowCount: self.viewConfig.rowCount,itemOriginalX:self.viewConfig.itemOriginalX, itemOriginalY: self.viewConfig.contentTopAndBottom,itemSpace: self.viewConfig.cellLeadingSpace, itemHeight: self.waterFallLayout!)
        }
        
        let sectionInsets = self.viewConfig.sectionEdges
        let laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets

        let headerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(self.frame.size.width - self.viewConfig.headerWidthOffset), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel.headerHeight ?? CGFloat.leastNormalMagnitude))
        let footerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(self.frame.size.width - self.viewConfig.footerWidthOffset), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel.footerHeight ?? CGFloat.leastNormalMagnitude))
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topTrailing)
        let footerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottomTrailing)
        var supplementarys = [NSCollectionLayoutBoundarySupplementaryItem]()
        if !(sectionModel.headerID ?? "").stringIsEmpty() {
            supplementarys.append(headerItem)
        }
        if !(sectionModel.footerID ?? "").stringIsEmpty() {
            supplementarys.append(footerItem)
        }
        laySection.boundarySupplementaryItems = supplementarys

        switch self.viewConfig.decorationItemsType {
        case .Corner,.NoCorner:
            var itemKind = ""
            switch self.viewConfig.decorationItemsType {
            case .Corner:
                itemKind = decorationViewOfKindCorner
            case .NoCorner:
                itemKind = decorationViewOfKindNormal
            default:
                break
            }
            let backItem = NSCollectionLayoutDecorationItem.background(elementKind: itemKind)
            backItem.contentInsets = self.viewConfig.decorationItemsEdges
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
    
    public var headerInCollection:((_ kind: String,_ collectionView:UICollectionView,_ sectionModel:PTSection,_ index: IndexPath) -> (UICollectionReusableView))?
    public var footerInCollection:((_ kind: String,_ collectionView:UICollectionView,_ sectionModel:PTSection,_ index: IndexPath) -> (UICollectionReusableView))?
    public var cellInCollection:((_ collectionView:UICollectionView,_ sectionModel:PTSection,_ index:IndexPath) -> (UICollectionViewCell))!
        
    public var collectionDidSelect:((_ index:IndexPath,_ sectionModel:PTSection)->Void)?
    
    public var headerRefreshTask:((UIRefreshControl)->Void)?
    public var footRefreshTask:PTActionTask?

    public var waterFallLayout:((Int, AnyObject) -> CGFloat)?
    
#if POOTOOLS_LISTEMPTYDATA
    public var emptyTap:((UIView)->Void)?
#endif

    fileprivate var viewConfig:PTCollectionViewConfig = PTCollectionViewConfig()
    
    public init(viewConfig: PTCollectionViewConfig!) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
#if POOTOOLS_LISTEMPTYDATA
        if self.viewConfig.showEmptyAlert {
            self.showEmptyDataSet(currentScroller: self.collectionView)
            self.lxf_tapEmptyView(self.collectionView) { sender in
                if self.emptyTap != nil {
                    self.emptyTap!(sender)
                }
            }
        }
#endif
    }
    
    public func showCollectionDetail(collectionData:[PTSection]) {
        mSections.removeAll()
        
        mSections = collectionData
        
        collectionView.pt_register(by: mSections)
        collectionView.reloadData()
    }
    
    public func endRefresh() {
#if POOTOOLS_SCROLLREFRESH
        if self.viewConfig.footerRefresh {
            self.collectionView.pt_endMJRefresh()
        }
#endif
        
        if self.viewConfig.topRefresh {
            self.refreshControl.endRefreshing()
        }
    }
    
#if POOTOOLS_SCROLLREFRESH
    public func footerRefreshNoMore () {
        self.collectionView.mj_footer?.endRefreshingWithNoMoreData()
    }
#endif
}

extension PTCollectionView:UICollectionViewDelegate,UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        mSections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mSections[section].rows.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let itemSec = mSections[indexPath.section]
        if !(itemSec.headerID ?? "").stringIsEmpty() || !(itemSec.footerID ?? "").stringIsEmpty() {
            if kind == UICollectionView.elementKindSectionHeader {
                return self.headerInCollection?(kind,collectionView,itemSec,indexPath) ?? UICollectionReusableView()
            } else if kind == UICollectionView.elementKindSectionFooter {
                return self.footerInCollection?(kind,collectionView,itemSec,indexPath) ?? UICollectionReusableView()
            } else {
                return UICollectionReusableView()
            }
        } else {
            return UICollectionReusableView()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemSec = mSections[indexPath.section]
        return self.cellInCollection(collectionView,itemSec,indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemSec = mSections[indexPath.section]
        if self.collectionDidSelect != nil {
            self.collectionDidSelect!(indexPath,itemSec)
        }
    }
}

#if POOTOOLS_LISTEMPTYDATA
//MARK: LXFEmptyDataSetable
extension PTCollectionView:LXFEmptyDataSetable {
    public func showEmptyDataSet(currentScroller: UIScrollView) {
        self.lxf_EmptyDataSet(currentScroller) { () -> ([LXFEmptyDataSetAttributeKeyType : Any]) in
            return self.viewConfig.emptyViewConfig!
        }
    }
    
    open func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        return self.viewConfig.buttonAtt?.value
    }
}
#endif
