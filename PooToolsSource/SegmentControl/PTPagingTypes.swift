//
//  PTPagingTypes.swift
//
// English: Public paging value types are kept separate from the page-container implementation.
// Español: Los tipos públicos de paginación están separados de la implementación del contenedor.
// 中文：将分页公开值类型与页面容器实现物理拆分。
//

import UIKit

/// English: Dimension model for fixed or Auto Layout measured headers.
/// Español: Modelo de dimensión para cabeceras fijas o medidas por Auto Layout.
/// 中文：支持固定高度和 Auto Layout 自动测量的 Header 尺寸模型。
@MainActor
public enum PTPagingDimension {
    case fixed(CGFloat)
    case automatic
    case custom(@MainActor (CGFloat) -> CGFloat)
}

/// English: Header configuration used by PTPagingView.
/// Español: Configuración de cabecera usada por PTPagingView.
/// 中文：PTPagingView 使用的 Header 配置。
@MainActor
public struct PTPagingHeader {
    public let viewProvider: @MainActor () -> UIView
    public var height: PTPagingDimension

    public init(height: PTPagingDimension = .automatic,
                viewProvider: @escaping @MainActor () -> UIView) {
        self.height = height
        self.viewProvider = viewProvider
    }
}

/// English: Pinned header configuration.
/// Español: Configuración de cabecera fijada.
/// 中文：固定 Header 配置。
@MainActor
public struct PTPagingPinnedHeader {
    public let viewProvider: @MainActor () -> UIView
    public var height: CGFloat

    public init(height: CGFloat = 44,
                viewProvider: @escaping @MainActor () -> UIView) {
        self.height = height
        self.viewProvider = viewProvider
    }
}

/// English: Single layout calculation point for safe-area-aware paging geometry.
/// Español: Punto único de cálculo para la geometría de paginación consciente del área segura.
/// 中文：集中计算安全区相关分页几何尺寸。
@MainActor
public struct PTPagingLayoutEngine {
    public var safeAreaTop: CGFloat
    public var headerHeight: CGFloat
    public var pinnedHeight: CGFloat
    public var pageHeight: CGFloat

    public init(safeAreaTop: CGFloat = 0,
                headerHeight: CGFloat = 0,
                pinnedHeight: CGFloat = 0,
                pageHeight: CGFloat = 0) {
        self.safeAreaTop = safeAreaTop
        self.headerHeight = headerHeight
        self.pinnedHeight = pinnedHeight
        self.pageHeight = pageHeight
    }

    public var contentHeight: CGFloat { headerHeight + pinnedHeight + pageHeight }
    public var collapseLimit: CGFloat { max(0, headerHeight) }
}

/// English: Scroll ownership states used to prevent outer and inner scroll views fighting each other.
/// Español: Estados de propiedad usados para evitar conflictos entre scroll externo e interno.
/// 中文：防止外层和内层滚动互相抢占的滚动所有权状态。
@MainActor
public enum PTScrollOwnership {
    case outer
    case inner(pageID: AnyHashable)
    case transitioning
}

/// English: Refresh ownership policy for outer and page scroll views.
/// Español: Política de propiedad de refresco para el scroll externo y las páginas.
/// 中文：外层和页面滚动视图的刷新所有权策略。
@MainActor
public enum PTPagingRefreshPolicy {
    case outerOnly
    case innerOnly
    case perPage
    case custom
}

/// English: Refresh adapter keeps paging independent from any refresh library.
/// Español: El adaptador mantiene la paginación independiente de cualquier biblioteca de refresco.
/// 中文：刷新适配器让分页组件不依赖具体刷新库。
@MainActor
public protocol PTRefreshAdapter: AnyObject {
    var isRefreshing: Bool { get }
    func beginRefreshing()
    func endRefreshing()
}

/// English: Basic UIRefreshControl adapter.
/// Español: Adaptador básico para UIRefreshControl.
/// 中文：UIRefreshControl 的基础适配器。
@MainActor
public final class PTUIRefreshAdapter: PTRefreshAdapter {
    public let control: UIRefreshControl

    public init(control: UIRefreshControl = UIRefreshControl()) {
        self.control = control
    }

    public var isRefreshing: Bool { control.isRefreshing }
    public func beginRefreshing() { control.beginRefreshing() }
    public func endRefreshing() { control.endRefreshing() }
}

