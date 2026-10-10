//
//  PTAdaptiveBarLayoutContext.swift
//  PooTools
//
//  English: Snapshot only the local host geometry consumed by adaptive bars.
//  Español: Captura únicamente la geometría local que consumen las barras adaptativas.
//  中文：只快照自适应 Bar 所使用的当前宿主局部几何信息。
//

import UIKit

public enum PTAdaptiveReservedRegionKind: String, Sendable, Equatable {
    case occlusion
    case division
}

public struct PTAdaptiveReservedRegion: Sendable, Equatable {
    public let frame: CGRect
    public let margins: UIEdgeInsets
    public let kind: PTAdaptiveReservedRegionKind
    public let isActive: Bool

    public init(frame: CGRect,
                margins: UIEdgeInsets = .zero,
                kind: PTAdaptiveReservedRegionKind,
                isActive: Bool) {
        self.frame = frame
        self.margins = margins
        self.kind = kind
        self.isActive = isActive
    }
}

public enum PTAdaptiveLayoutDirection: String, Sendable, Equatable {
    case leftToRight
    case rightToLeft
}

public struct PTAdaptiveBarLayoutContext: Sendable, Equatable {
    public let bounds: CGRect
    public let safeAreaInsets: UIEdgeInsets
    public let verticalBarEdge: PTAdaptiveBarEdge
    public let reservedRegions: [PTAdaptiveReservedRegion]
    public let layoutDirection: PTAdaptiveLayoutDirection
    public let isHorizontalRegular: Bool
    public let isVerticalRegular: Bool

    public init(bounds: CGRect,
                safeAreaInsets: UIEdgeInsets,
                verticalBarEdge: PTAdaptiveBarEdge = .unspecified,
                reservedRegions: [PTAdaptiveReservedRegion] = [],
                layoutDirection: PTAdaptiveLayoutDirection = .leftToRight,
                isHorizontalRegular: Bool = false,
                isVerticalRegular: Bool = false) {
        self.bounds = bounds
        self.safeAreaInsets = safeAreaInsets
        self.verticalBarEdge = verticalBarEdge
        self.reservedRegions = reservedRegions
        self.layoutDirection = layoutDirection
        self.isHorizontalRegular = isHorizontalRegular
        self.isVerticalRegular = isVerticalRegular
    }

    // English: Read every value from the consuming view and never from UIScreen or a cached window.
    // Español: Lee cada valor desde la vista consumidora y nunca desde UIScreen o una ventana en caché.
    // 中文：所有值都从实际使用布局的 View 读取，不读取 UIScreen 或缓存 Window。
    @MainActor
    public static func make(for view: UIView) -> Self {
        var edge: PTAdaptiveBarEdge = .unspecified
        var regions: [PTAdaptiveReservedRegion] = []

        if #available(iOS 27.1, *) {
            switch view.traitCollection.verticalBarEdge {
            case .leading:
                edge = .leading
            case .trailing:
                edge = .trailing
            default:
                edge = .unspecified
            }

            regions.append(contentsOf: view.reservedRegions(kind: .occlusion).map {
                PTAdaptiveReservedRegion(frame: $0.frame,
                                          margins: $0.margins,
                                          kind: .occlusion,
                                          isActive: $0.isActive)
            })
            regions.append(contentsOf: view.reservedRegions(kind: .division).map {
                PTAdaptiveReservedRegion(frame: $0.frame,
                                          margins: $0.margins,
                                          kind: .division,
                                          isActive: $0.isActive)
            })
        }

        return Self(bounds: view.bounds,
                    safeAreaInsets: view.safeAreaInsets,
                    verticalBarEdge: edge,
                    reservedRegions: regions,
                    layoutDirection: view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .rightToLeft : .leftToRight,
                    isHorizontalRegular: view.traitCollection.horizontalSizeClass == .regular,
                    isVerticalRegular: view.traitCollection.verticalSizeClass == .regular)
    }
}

public struct PTAdaptiveBarGeometry: Sendable, Equatable {
    public let axis: PTAdaptiveBarAxis
    public let renderer: PTAdaptiveBarRenderer
    public let edge: PTAdaptiveBarEdge
    public let contentSafeRect: CGRect
    public let customRailRect: CGRect
    public let navItemsRect: CGRect
    public let tabItemsRect: CGRect
    public let accessoryRect: CGRect
    public let reservedRegionFrames: [CGRect]
    public let visibleTabItemIDs: [String]
    public let overflowTabItemIDs: [String]

    public init(axis: PTAdaptiveBarAxis,
                renderer: PTAdaptiveBarRenderer,
                edge: PTAdaptiveBarEdge,
                contentSafeRect: CGRect,
                customRailRect: CGRect,
                navItemsRect: CGRect,
                tabItemsRect: CGRect,
                accessoryRect: CGRect,
                reservedRegionFrames: [CGRect] = [],
                visibleTabItemIDs: [String] = [],
                overflowTabItemIDs: [String] = []) {
        self.axis = axis
        self.renderer = renderer
        self.edge = edge
        self.contentSafeRect = contentSafeRect
        self.customRailRect = customRailRect
        self.navItemsRect = navItemsRect
        self.tabItemsRect = tabItemsRect
        self.accessoryRect = accessoryRect
        self.reservedRegionFrames = reservedRegionFrames
        self.visibleTabItemIDs = visibleTabItemIDs
        self.overflowTabItemIDs = overflowTabItemIDs
    }

    // English: Keep the debug table derived from value geometry so it never reads live UIKit objects.
    // Español: Mantiene la tabla de depuración derivada de geometría de valor sin leer objetos UIKit vivos.
    // 中文：调试坐标表只从值类型几何生成，不读取实时 UIKit 对象。
    public var debugSummary: String {
        "axis=\(axis.rawValue) renderer=\(renderer.rawValue) edge=\(edge.rawValue) "
            + "content=\(contentSafeRect.integral) nav=\(navItemsRect.integral) "
            + "tabs=\(tabItemsRect.integral) accessory=\(accessoryRect.integral) "
            + "reserved=\(reservedRegionFrames.map(\.integral))"
    }
}
