//
//  PTCollectionViewTypes.swift
//  PooTools
//
//  Public value types used by PTCollectionView's layout and update pipeline.
//

import UIKit

public typealias PTCollectionCallback = @MainActor (UICollectionView) -> Void

/// 列表数据更新失败时返回的结构化错误，避免 Diffable 在异常输入下直接触发断言。
public enum PTCollectionViewUpdateError: Error, Equatable, LocalizedError, Sendable {
    case emptySectionIdentifier
    case duplicateSectionIdentifier(String)
    case duplicateRowIdentifier(String)
    case invalidSectionIndex(Int)

    public var errorDescription: String? {
        switch self {
        case .emptySectionIdentifier:
            return "Section 标识不能为空"
        case .duplicateSectionIdentifier(let identifier):
            return "Section 标识重复：\(identifier)"
        case .duplicateRowIdentifier(let identifier):
            return "Row 标识重复：\(identifier)"
        case .invalidSectionIndex(let index):
            return "Section 下标无效：\(index)"
        }
    }
}

public typealias PTCollectionViewUpdateErrorHandler = @MainActor (PTCollectionViewUpdateError) -> Void

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
@MainActor
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

    // 🌟 新增：无感触底预加载配置
    /// 是否开启无感触底预加载 (Smart Prefetch)
    open var enableSmartPrefetch: Bool = false
    /// 触发预加载的阈值：距离底部还有多少个 Item 时触发（默认距离最后 5 个时触发）
    open var prefetchThreshold: Int = 5
    /// 骨架加载时默认展示的占位数量
    open var skeletonItemCount: Int = 6
    /// 骨架占位块的圆角半径
    open var skeletonCornerRadius: CGFloat = 8
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
    let version: Int
}

struct HeightCacheKey: Hashable {
    let id: String
    let width: CGFloat
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
