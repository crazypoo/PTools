//
//  PTCollectionViewTypes.swift
//  PooTools
//
//  Public value types used by PTCollectionView's layout and update pipeline.
//

import UIKit

// English: Keep the reusable cache type separate from PTCollectionView's facade and layout code.
// Español: Mantiene el tipo de caché reutilizable separado de la fachada y el layout de PTCollectionView.
// 中文：将可复用缓存类型从 PTCollectionView 门面和布局代码中独立出来。
@MainActor
public class PTLRUCache<Key: Hashable & Sendable, Value: AnyObject> {
    private let cache = NSCache<WrappedKey, Value>()

    public init(countLimit: Int = 1000) {
        cache.countLimit = max(0, countLimit)
    }

    public func set(_ value: Value, forKey key: Key) {
        cache.setObject(value, forKey: WrappedKey(key))
    }

    public func get(forKey key: Key) -> Value? {
        cache.object(forKey: WrappedKey(key))
    }

    public func remove(forKey key: Key) {
        cache.removeObject(forKey: WrappedKey(key))
    }

    public func removeAll() {
        cache.removeAllObjects()
    }

    private final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) {
            self.key = key
        }

        override var hash: Int {
            key.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? WrappedKey else { return false }
            return key == other.key
        }
    }
}

public typealias PTCollectionCallback = @MainActor (UICollectionView) -> Void

/// 列表数据更新失败时返回的结构化错误，避免 Diffable 在异常输入下直接触发断言。
public enum PTCollectionViewUpdateError: Error, Equatable, LocalizedError, Sendable {
    case emptySectionIdentifier
    case emptyRowIdentifier
    case duplicateSectionIdentifier(String)
    case duplicateRowIdentifier(String)
    case invalidSectionIndex(Int)
    case snapshotApplyInProgress

    public var errorDescription: String? {
        switch self {
        case .emptySectionIdentifier:
            return "Section 标识不能为空"
        case .emptyRowIdentifier:
            return "Row 标识不能为空"
        case .duplicateSectionIdentifier(let identifier):
            return "Section 标识重复：\(identifier)"
        case .duplicateRowIdentifier(let identifier):
            return "Row 标识重复：\(identifier)"
        case .invalidSectionIndex(let index):
            return "Section 下标无效：\(index)"
        case .snapshotApplyInProgress:
            return "列表正在更新，请等待当前更新完成"
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

// English: Pass the latest section and row together so custom cells do not have to read stale snapshot objects.
// Español: Pasa la sección y la fila más recientes juntas para que las celdas no lean objetos obsoletos del snapshot.
// 中文：同时传递最新 Section 和 Row，避免自定义 Cell 读取过期快照对象。
@MainActor
public struct PTCollectionCellContext {
    public let section: PTSection
    public let row: PTRows
    public let indexPath: IndexPath

    public init(section: PTSection, row: PTRows, indexPath: IndexPath) {
        self.section = section
        self.row = row
        self.indexPath = indexPath
    }
}

// English: New row-aware provider; the legacy handler remains source-compatible.
// Español: Nuevo proveedor consciente de la fila; el handler heredado conserva compatibilidad de código.
// 中文：新增带 Row 上下文的 Provider，同时保留旧 Handler 的源码兼容性。
public typealias PTCellInCollectionV2Handler = @MainActor (_ collectionView: UICollectionView, _ context: PTCollectionCellContext) -> UICollectionViewCell?

// English: Configure a created or visible cell without forcing Diffable to replace it.
// Español: Configura una celda creada o visible sin obligar a Diffable a reemplazarla.
// 中文：配置已创建或可见的 Cell，不强制 Diffable 替换 Cell。
public typealias PTCellConfigurationHandler = @MainActor (_ collectionView: UICollectionView, _ cell: UICollectionViewCell, _ context: PTCollectionCellContext) -> Void

// English: Separate structural transactions from content and layout work.
// Español: Separa las transacciones estructurales del contenido y del layout.
// 中文：将结构事务与内容刷新、布局刷新分开。
public enum PTCollectionUpdateKind: String, Sendable {
    case structure
    case content
    case layout
}

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
    // English: Let edge-to-edge callers opt out of UIKit's automatic safe-area content inset.
    // Español: Permite que los consumidores edge-to-edge desactiven el inset automático del área segura de UIKit.
    // 中文：允许全屏边缘布局调用方关闭 UIKit 自动添加的安全区内容 inset。
    open var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic
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
    // English: Structure and content have different animation semantics; content defaults to immediate updates.
    // Español: La estructura y el contenido tienen semánticas de animación distintas; el contenido se actualiza de inmediato.
    // 中文：结构和内容的动画语义不同；内容刷新默认立即完成。
    open var structureUpdateAnimationEnabled: Bool = true
    open var contentUpdateAnimationEnabled: Bool = false
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

// English: Own list layout caches outside PTCollectionView so cache policy can evolve independently.
// Español: Posee las cachés de layout fuera de PTCollectionView para evolucionar la política sin tocar la fachada.
// 中文：将列表布局缓存移出 PTCollectionView，让缓存策略可以独立演进。
@MainActor
final class PTCollectionLayoutCacheCoordinator {
    let height = PTLRUCache<HeightCacheKey, NSNumber>(countLimit: 1000)
    let sections = PTLRUCache<LayoutCacheKey, NSCollectionLayoutSection>(countLimit: 100)

    func removeAll() {
        height.removeAll()
        sections.removeAll()
    }
}

// English: Multiplex scroll observers while PTCollectionView remains the sole UIKit delegate owner.
// Español: Multiplexa observadores de scroll mientras PTCollectionView conserva el único delegate de UIKit.
// 中文：在 PTCollectionView 保持 UIKit 唯一 delegate 所有者的同时复用滚动观察者。
@MainActor
final class PTCollectionScrollObserverMultiplexer {
    private var handlers: [UUID: PTCollectionViewScrollHandler] = [:]

    @discardableResult
    func add(_ handler: @escaping PTCollectionViewScrollHandler) -> UUID {
        let token = UUID()
        handlers[token] = handler
        return token
    }

    func remove(_ token: UUID) {
        handlers[token] = nil
    }

    func notify(_ collectionView: UICollectionView) {
        for handler in handlers.values {
            handler(collectionView)
        }
    }
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
