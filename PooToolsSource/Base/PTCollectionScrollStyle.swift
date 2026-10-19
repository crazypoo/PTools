//
//  PTCollectionScrollStyle.swift
//  PooTools
//
// English: Value-based scroll contracts shared by PTCollectionView and PTBannerView.
// Español: Contratos de desplazamiento basados en valores compartidos por PTCollectionView y PTBannerView.
// 中文：PTCollectionView 与 PTBannerView 共享的值类型滚动契约。
//

import UIKit

/// English: The main-axis scroll behavior of a PTCollectionView.
/// Español: El comportamiento de desplazamiento del eje principal de PTCollectionView.
/// 中文：PTCollectionView 主滚动轴的行为类型。
@objc public enum PTCollectionScrollStyle: Int, CaseIterable, Sendable {
    case normal
    case horizontalPaging
    case verticalPaging
    case horizontalInfinite
    case verticalInfinite

    var isPaging: Bool {
        switch self {
        case .horizontalPaging, .verticalPaging: return true
        case .normal, .horizontalInfinite, .verticalInfinite: return false
        }
    }

    var isInfinite: Bool {
        switch self {
        case .horizontalInfinite, .verticalInfinite: return true
        case .normal, .horizontalPaging, .verticalPaging: return false
        }
    }

    var isHorizontal: Bool {
        switch self {
        case .horizontalPaging, .horizontalInfinite: return true
        case .normal, .verticalPaging, .verticalInfinite: return false
        }
    }
}

public enum PTCollectionPageSnapMode: String, Sendable {
    case viewport
    case item
}

public enum PTCollectionPageAlignment: String, Sendable {
    case leading
    case center
}

public struct PTCollectionPagingConfiguration: Sendable, Equatable {
    public var snapMode: PTCollectionPageSnapMode
    public var itemAlignment: PTCollectionPageAlignment
    public var initialPage: Int
    public var allowsSkippingPages: Bool
    public var preservesVisibleRowOnUpdates: Bool

    public init(snapMode: PTCollectionPageSnapMode = .viewport,
                itemAlignment: PTCollectionPageAlignment = .leading,
                initialPage: Int = 0,
                allowsSkippingPages: Bool = false,
                preservesVisibleRowOnUpdates: Bool = true) {
        self.snapMode = snapMode
        self.itemAlignment = itemAlignment
        self.initialPage = max(0, initialPage)
        self.allowsSkippingPages = allowsSkippingPages
        self.preservesVisibleRowOnUpdates = preservesVisibleRowOnUpdates
    }
}

public struct PTCollectionInfiniteConfiguration: Sendable, Equatable {
    public var maxProjectedItems: Int

    public init(maxProjectedItems: Int = 600) {
        self.maxProjectedItems = max(7, maxProjectedItems)
    }
}

public struct PTCollectionAutoScrollConfiguration: Sendable, Equatable {
    public var isEnabled: Bool
    public var interval: TimeInterval
    public var pausesWhileInteracting: Bool
    public var pausesWhenNotVisible: Bool
    public var respectsReduceMotion: Bool

    public init(isEnabled: Bool = false,
                interval: TimeInterval = 3,
                pausesWhileInteracting: Bool = true,
                pausesWhenNotVisible: Bool = true,
                respectsReduceMotion: Bool = true) {
        self.isEnabled = isEnabled
        self.interval = interval.isFinite ? min(max(interval, 0.1), 86_400) : 3
        self.pausesWhileInteracting = pausesWhileInteracting
        self.pausesWhenNotVisible = pausesWhenNotVisible
        self.respectsReduceMotion = respectsReduceMotion
    }
}

public struct PTCollectionScrollConfiguration: Sendable, Equatable {
    public var style: PTCollectionScrollStyle
    public var paging: PTCollectionPagingConfiguration
    public var infinite: PTCollectionInfiniteConfiguration
    public var autoScroll: PTCollectionAutoScrollConfiguration

    public init(style: PTCollectionScrollStyle = .normal,
                paging: PTCollectionPagingConfiguration = .init(),
                infinite: PTCollectionInfiniteConfiguration = .init(),
                autoScroll: PTCollectionAutoScrollConfiguration = .init()) {
        self.style = style
        self.paging = paging
        self.infinite = infinite
        self.autoScroll = autoScroll
    }
}

public enum PTCollectionPageChangeReason: String, Sendable {
    case userScroll
    case programmatic
    case dataUpdated
    case geometryChanged
    case initial
}

/// English: Logical selection information that never exposes an infinite projection index.
/// Español: Información de selección lógica que nunca expone un índice de proyección infinita.
/// 中文：逻辑选择信息，不向业务层暴露无限投影的物理下标。
@MainActor
public struct PTCollectionLogicalSelectionContext {
    public let rowID: PTRowIdentifier
    public let logicalIndexPath: IndexPath

    public init(rowID: PTRowIdentifier, logicalIndexPath: IndexPath) {
        self.rowID = rowID
        self.logicalIndexPath = logicalIndexPath
    }
}

/// English: Page context is MainActor-bound because its model references are UIKit-facing objects.
/// Español: El contexto de página está ligado a MainActor porque sus modelos pertenecen a UIKit.
/// 中文：页面上下文绑定 MainActor，因为其中的模型引用属于 UIKit 展示边界。
@MainActor
public struct PTCollectionPageContext {
    public let page: Int
    public let pageCount: Int
    public let sectionID: PTSectionIdentifier?
    public let rowID: PTRowIdentifier?
    public let logicalIndexPath: IndexPath?
    public let reason: PTCollectionPageChangeReason

    public init(page: Int,
                pageCount: Int,
                sectionID: PTSectionIdentifier?,
                rowID: PTRowIdentifier?,
                logicalIndexPath: IndexPath?,
                reason: PTCollectionPageChangeReason) {
        self.page = page
        self.pageCount = pageCount
        self.sectionID = sectionID
        self.rowID = rowID
        self.logicalIndexPath = logicalIndexPath
        self.reason = reason
    }
}

public enum PTCollectionScrollError: Error, Equatable, LocalizedError, Sendable {
    case unsupportedLayout
    case invalidPageGeometry
    case incompatibleFeature(String)
    case legacyProviderNotLoopSafe
    case projectionCapacityExceeded
    case invalidConfiguration(String)
    case transitionInProgress

    public var errorDescription: String? {
        switch self {
        case .unsupportedLayout:
            return "当前列表布局不支持该滚动模式"
        case .invalidPageGeometry:
            return "当前列表没有有效的页面尺寸"
        case .incompatibleFeature(let feature):
            return "滚动模式与功能冲突：\(feature)"
        case .legacyProviderNotLoopSafe:
            return "旧版 Cell Provider 未提供稳定的循环身份"
        case .projectionCapacityExceeded:
            return "无限循环投影超过配置容量"
        case .invalidConfiguration(let message):
            return "滚动配置无效：\(message)"
        case .transitionInProgress:
            return "滚动布局正在切换，请稍后重试"
        }
    }
}

@MainActor
enum PTCollectionScrollValidator {
    static func validate(_ configuration: PTCollectionScrollConfiguration,
                         viewConfig: PTCollectionViewConfig) -> PTCollectionScrollError? {
        guard configuration.infinite.maxProjectedItems >= 7 else {
            return .invalidConfiguration("maxProjectedItems 必须至少为 7")
        }

        guard configuration.autoScroll.interval.isFinite,
              configuration.autoScroll.interval >= 0.1 else {
            return .invalidConfiguration("autoScroll.interval 必须大于等于 0.1 秒")
        }

        if configuration.paging.snapMode == .item && configuration.style.isInfinite {
            return .incompatibleFeature("无限循环只支持 viewport 吸附")
        }

        guard configuration.style == .normal || viewConfig.viewType == .Normal else {
            return .unsupportedLayout
        }

        if configuration.style.isInfinite {
            if viewConfig.canMoveItem { return .incompatibleFeature("拖放") }
            if viewConfig.topRefresh || viewConfig.footerRefresh { return .incompatibleFeature("刷新控件") }
            if viewConfig.enableSmartPrefetch { return .incompatibleFeature("Smart Prefetch") }
            if viewConfig.contentOffSetZero { return .incompatibleFeature("contentOffSetZero") }
            if viewConfig.customReuseViews { return .incompatibleFeature("自定义 Header/Footer") }
        }

        return nil
    }
}

