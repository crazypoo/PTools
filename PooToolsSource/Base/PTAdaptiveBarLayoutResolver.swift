//
//  PTAdaptiveBarLayoutResolver.swift
//  PooTools
//
//  English: Resolve adaptive bar geometry as a pure value transformation.
//  Español: Resuelve la geometría de las barras adaptativas como una transformación pura de valores.
//  中文：将自适应 Bar 几何布局实现为纯值转换，便于稳定测试。
//

import UIKit

public enum PTAdaptiveBarLayoutResolver {
    public static func resolve(context: PTAdaptiveBarLayoutContext,
                               configuration: PTAdaptiveBarConfiguration,
                               navigationActionCount: Int,
                               tabItemIDs: [String],
                               selectedTabID: String?,
                               accessoryHeight: CGFloat = 0) -> PTAdaptiveBarGeometry {
        let safeInsets = UIEdgeInsets(top: max(0, context.safeAreaInsets.top),
                                      left: max(0, context.safeAreaInsets.left),
                                      bottom: max(0, context.safeAreaInsets.bottom),
                                      right: max(0, context.safeAreaInsets.right))
        let safeRect = context.bounds.inset(by: safeInsets)
        let useVertical = shouldUseVertical(context: context,
                                             policy: configuration.presentationPolicy)
        let renderer = resolvedRenderer(policy: configuration.presentationPolicy,
                                         vertical: useVertical)
        guard useVertical else {
            let classicTabHeight = max(configuration.minimumTouchTarget, 49)
            let tabRect = CGRect(x: safeRect.minX,
                                 y: max(safeRect.minY, safeRect.maxY - classicTabHeight),
                                 width: safeRect.width,
                                 height: min(classicTabHeight, safeRect.height))
            return PTAdaptiveBarGeometry(axis: .horizontalClassic,
                                         renderer: renderer,
                                         edge: .unspecified,
                                         contentSafeRect: safeRect,
                                         customRailRect: .zero,
                                         navItemsRect: CGRect(x: safeRect.minX,
                                                              y: safeRect.minY,
                                                              width: safeRect.width,
                                                              height: 0),
                                         tabItemsRect: tabRect,
                                         accessoryRect: .zero,
                                         reservedRegionFrames: activeReservedFrames(in: context),
                                         visibleTabItemIDs: tabItemIDs,
                                         overflowTabItemIDs: [])
        }

        let minimumTarget = max(44, configuration.minimumTouchTarget.isFinite ? configuration.minimumTouchTarget : 44)
        let railWidth = min(max(56, safeRect.width * 0.16), 88)
        let requestedRail = CGRect(x: context.verticalBarEdge == .trailing ? safeRect.maxX - railWidth : safeRect.minX,
                                   y: safeRect.minY,
                                   width: railWidth,
                                   height: safeRect.height)
        let rail = avoidingReservedRegions(requestedRail,
                                           context: context,
                                           safeRect: safeRect,
                                           edge: context.verticalBarEdge)
        let usableRail = rail.intersection(safeRect)
        guard !usableRail.isNull, usableRail.width > 0, usableRail.height > 0 else {
            return PTAdaptiveBarGeometry(axis: .verticalEdge,
                                         renderer: renderer,
                                         edge: context.verticalBarEdge,
                                         contentSafeRect: safeRect,
                                         customRailRect: .zero,
                                         navItemsRect: .zero,
                                         tabItemsRect: .zero,
                                         accessoryRect: .zero,
                                         reservedRegionFrames: activeReservedFrames(in: context),
                                         visibleTabItemIDs: [],
                                         overflowTabItemIDs: tabItemIDs)
        }

        let navCount = max(1, navigationActionCount)
        let navHeight = min(usableRail.height * 0.38,
                            max(minimumTarget, CGFloat(navCount) * minimumTarget + 8))
        let accessory = max(0, accessoryHeight.isFinite ? accessoryHeight : 0)
        let availableTabs = max(0, usableRail.height - navHeight - accessory)
        let maxVisibleCount = max(1, Int(floor(availableTabs / minimumTarget)))
        let (visibleIDs, overflowIDs) = visibleTabs(tabItemIDs,
                                                     selectedTabID: selectedTabID,
                                                     maxCount: maxVisibleCount)
        let tabHeight = visibleIDs.isEmpty ? 0 : min(minimumTarget * 1.25,
                                                       availableTabs / CGFloat(max(visibleIDs.count, 1)))
        let tabRect = CGRect(x: usableRail.minX,
                             y: usableRail.maxY - tabHeight * CGFloat(visibleIDs.count),
                             width: usableRail.width,
                             height: tabHeight * CGFloat(visibleIDs.count))
        let accessoryRect: CGRect
        if accessory > 0 {
            accessoryRect = CGRect(x: usableRail.minX,
                                   y: tabRect.minY - accessory,
                                   width: usableRail.width,
                                   height: accessory)
        } else {
            accessoryRect = .zero
        }
        let navRect = CGRect(x: usableRail.minX,
                             y: usableRail.minY,
                             width: usableRail.width,
                             height: max(0, usableRail.height - tabRect.height - accessory))
        let contentRect = contentRect(safeRect: safeRect,
                                      rail: usableRail,
                                      edge: context.verticalBarEdge)

        return PTAdaptiveBarGeometry(axis: .verticalEdge,
                                     renderer: renderer,
                                     edge: context.verticalBarEdge,
                                     contentSafeRect: contentRect,
                                     customRailRect: usableRail,
                                     navItemsRect: navRect,
                                     tabItemsRect: tabRect,
                                     accessoryRect: accessoryRect,
                                     reservedRegionFrames: activeReservedFrames(in: context),
                                     visibleTabItemIDs: visibleIDs,
                                     overflowTabItemIDs: overflowIDs)
    }

    static func shouldUseVertical(context: PTAdaptiveBarLayoutContext,
                                  policy: PTAdaptiveBarPresentationPolicy) -> Bool {
        guard context.verticalBarEdge != .unspecified else { return false }
        switch policy {
        case .legacyClassic:
            return false
        case .preferClassicBarsForWideContent:
            return !(context.isHorizontalRegular && context.isVerticalRegular)
        case .automatic, .preferSystemAdaptive, .customAdaptive:
            return true
        }
    }

    static func resolvedRenderer(policy: PTAdaptiveBarPresentationPolicy,
                                 vertical: Bool) -> PTAdaptiveBarRenderer {
        guard vertical else { return .legacyClassic }
        switch policy {
        case .preferSystemAdaptive:
            return .systemAdaptive
        case .customAdaptive, .preferClassicBarsForWideContent:
            return .customAdaptive
        case .automatic:
            // English: Automatic mode gives UIKit one geometry owner when vertical bars are available.
            // Español: El modo automático entrega una única autoridad geométrica a UIKit cuando existen barras verticales.
            // 中文：具备垂直 Bar 能力时，automatic 交给 UIKit 统一拥有几何布局，避免自定义和系统重叠。
            return .systemAdaptive
        case .legacyClassic:
            return .legacyClassic
        }
    }

    private static func visibleTabs(_ ids: [String],
                                   selectedTabID: String?,
                                   maxCount: Int) -> ([String], [String]) {
        guard ids.count > maxCount else { return (ids, []) }
        var visible: [String] = []
        if let selectedTabID, ids.contains(selectedTabID) {
            visible.append(selectedTabID)
        }
        for id in ids where visible.count < maxCount {
            if id != selectedTabID { visible.append(id) }
        }
        let visibleSet = Set(visible)
        return (visible, ids.filter { !visibleSet.contains($0) })
    }

    private static func contentRect(safeRect: CGRect,
                                    rail: CGRect,
                                    edge: PTAdaptiveBarEdge) -> CGRect {
        switch edge {
        case .leading:
            return CGRect(x: rail.maxX,
                          y: safeRect.minY,
                          width: max(0, safeRect.maxX - rail.maxX),
                          height: safeRect.height)
        case .trailing:
            return CGRect(x: safeRect.minX,
                          y: safeRect.minY,
                          width: max(0, rail.minX - safeRect.minX),
                          height: safeRect.height)
        case .unspecified:
            return safeRect
        }
    }

    private static func avoidingReservedRegions(_ rail: CGRect,
                                                 context: PTAdaptiveBarLayoutContext,
                                                 safeRect: CGRect,
                                                 edge: PTAdaptiveBarEdge) -> CGRect {
        var result = rail
        for region in context.reservedRegions where region.isActive {
            let reserved = region.frame.inset(by: UIEdgeInsets(top: -region.margins.top,
                                                                left: -region.margins.left,
                                                                bottom: -region.margins.bottom,
                                                                right: -region.margins.right))
            guard result.intersects(reserved) else { continue }
            switch edge {
            case .leading:
                result.origin.x = reserved.maxX
            case .trailing:
                result.origin.x = reserved.minX - result.width
            case .unspecified:
                return .zero
            }
        }
        return result.intersection(safeRect)
    }

    private static func activeReservedFrames(in context: PTAdaptiveBarLayoutContext) -> [CGRect] {
        context.reservedRegions.filter(\.isActive).map(\.frame)
    }
}
