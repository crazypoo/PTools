//
//  PTAdaptiveVisibleRegionResolver.swift
//  PooTools
//
//  English: Resolve interactive frames from one host view's local geometry.
//  Español: Resuelve los frames interactivos usando la geometría local de una sola vista anfitriona.
//  中文：使用单个宿主视图的局部几何计算交互控件的安全位置。
//

import UIKit

public struct PTAdaptiveVisibleRegion: Sendable, Equatable {
    public let visibleRect: CGRect
    public let availablePanes: [CGRect]
    public let reservedRects: [CGRect]
    public let signature: String

    public init(visibleRect: CGRect,
                availablePanes: [CGRect] = [],
                reservedRects: [CGRect],
                signature: String) {
        self.visibleRect = visibleRect
        self.availablePanes = availablePanes.isEmpty && !visibleRect.isEmpty ? [visibleRect] : availablePanes
        self.reservedRects = reservedRects
        self.signature = signature
    }
}

public enum PTAdaptiveVisibleRegionResolver {
    // English: Build a host-local region; never use a global screen or window as the source of truth.
    // Español: Construye una región local del host; nunca usa una pantalla o ventana global como fuente.
    // 中文：构建宿主局部可视区域，不以全局屏幕或 Window 作为数据来源。
    @MainActor
    public static func region(for view: UIView,
                              additionalReservedRects: [CGRect] = [],
                              minimumMargin: CGFloat = 0) -> PTAdaptiveVisibleRegion {
        let context = PTAdaptiveBarLayoutContext.make(for: view)
        return region(for: context,
                      additionalReservedRects: additionalReservedRects,
                      minimumMargin: minimumMargin)
    }

    public static func region(for context: PTAdaptiveBarLayoutContext,
                              additionalReservedRects: [CGRect] = [],
                              minimumMargin: CGFloat = 0) -> PTAdaptiveVisibleRegion {
        let safeRect = context.bounds.inset(by: normalizedInsets(context.safeAreaInsets))
        let activeRegions = context.reservedRegions.filter(\.isActive)
        // English: Both divisions and occlusions remove usable content space; only active regions participate.
        // Español: Las divisiones y las oclusiones eliminan espacio utilizable; solo participan regiones activas.
        // 中文：分割区和遮挡区都会减少可用内容空间，只有激活的区域参与计算。
        let excludedRects = activeRegions
            .filter { $0.kind == .division || $0.kind == .occlusion }
            .map { expandedFrame($0.frame, margins: $0.margins, extra: minimumMargin) }
            + additionalReservedRects.map {
                expandedFrame($0, margins: .zero, extra: minimumMargin)
            }
        let reserved = (context.reservedRegions + additionalReservedRects.map {
            PTAdaptiveReservedRegion(frame: $0,
                                      kind: .occlusion,
                                      isActive: true)
        })
        .filter(\.isActive)
        .map { expandedFrame($0.frame, margins: $0.margins, extra: minimumMargin) }
        .filter { !$0.isNull && !$0.isEmpty }

        // English: Keep the largest pane that is not covered by a system reserved region.
        // Español: Conserva el panel más grande que no esté cubierto por una región reservada del sistema.
        // 中文：选择没有被系统保留区域覆盖的最大内容面板。
        let panes = availablePanes(in: safeRect, excluding: excludedRects)
        let visible = panes.max { $0.width * $0.height < $1.width * $1.height } ?? .zero
        let signature = [
            String(describing: context.bounds.integral),
            String(describing: context.safeAreaInsets),
            context.layoutDirection.rawValue,
            context.verticalBarEdge.rawValue,
            panes.map { String(describing: $0.integral) }.joined(separator: ";"),
            reserved.map { String(describing: $0.integral) }.joined(separator: ";")
        ].joined(separator: "|")
        return PTAdaptiveVisibleRegion(visibleRect: visible,
                                       availablePanes: panes,
                                       reservedRects: reserved,
                                       signature: signature)
    }

    public static func clamped(_ frame: CGRect,
                               to region: PTAdaptiveVisibleRegion,
                               minimumMargin: CGFloat = 0) -> CGRect {
        let area = region.visibleRect.insetBy(dx: max(0, minimumMargin), dy: max(0, minimumMargin))
        guard !area.isEmpty else { return .zero }
        var result = frame
        if result.width > area.width { result.size.width = area.width }
        if result.height > area.height { result.size.height = area.height }
        result.origin.x = min(max(result.minX, area.minX), area.maxX - result.width)
        result.origin.y = min(max(result.minY, area.minY), area.maxY - result.height)
        return result
    }

    public static func controlFrame(size: CGSize,
                                    in region: PTAdaptiveVisibleRegion,
                                    preferred: PTAdaptiveBarEdge = .trailing,
                                    margin: CGFloat = 10) -> CGRect {
        let width = max(0, size.width)
        let height = max(0, size.height)
        guard width.isFinite, height.isFinite else { return .zero }

        let panes = region.availablePanes.isEmpty ? [region.visibleRect] : region.availablePanes
        let orderedPanes: [CGRect]
        switch preferred {
        case .leading:
            orderedPanes = panes.sorted { $0.minX < $1.minX }
        case .trailing, .unspecified:
            orderedPanes = panes.sorted { $0.maxX > $1.maxX }
        }

        for pane in orderedPanes {
            let paneArea = pane.insetBy(dx: max(0, margin), dy: max(0, margin))
            guard !paneArea.isEmpty, paneArea.width >= width, paneArea.height >= height else { continue }
            let candidates = preferred == .leading
                ? [
                    CGRect(x: paneArea.minX, y: paneArea.minY, width: width, height: height),
                    CGRect(x: paneArea.maxX - width, y: paneArea.minY, width: width, height: height),
                    CGRect(x: paneArea.midX - width / 2, y: paneArea.minY, width: width, height: height)
                ]
                : [
                    CGRect(x: paneArea.maxX - width, y: paneArea.minY, width: width, height: height),
                    CGRect(x: paneArea.minX, y: paneArea.minY, width: width, height: height),
                    CGRect(x: paneArea.midX - width / 2, y: paneArea.minY, width: width, height: height)
                ]
            for candidate in candidates {
                // English: Keep the candidate inside its own pane; clamping to the largest pane could cross a hinge.
                // Español: Mantén el candidato dentro de su propio panel; limitarlo al panel mayor podría cruzar la bisagra.
                // 中文：候选框必须保持在所属 pane 内，不能再裁剪到最大 pane 后跨过折叠区。
                if !region.reservedRects.contains(where: { $0.intersects(candidate) }) {
                    return candidate
                }
            }
        }
        return .zero
    }

    private static func normalizedInsets(_ insets: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(top: max(0, insets.top),
                     left: max(0, insets.left),
                     bottom: max(0, insets.bottom),
                     right: max(0, insets.right))
    }

    private static func expandedFrame(_ frame: CGRect,
                                      margins: UIEdgeInsets,
                                      extra: CGFloat) -> CGRect {
        frame.inset(by: UIEdgeInsets(top: -(max(0, margins.top) + extra),
                                     left: -(max(0, margins.left) + extra),
                                     bottom: -(max(0, margins.bottom) + extra),
                                     right: -(max(0, margins.right) + extra)))
    }

    private static func availablePanes(in safeRect: CGRect,
                                       excluding divisions: [CGRect]) -> [CGRect] {
        guard !divisions.isEmpty else { return safeRect.isEmpty ? [] : [safeRect] }
        var panes = [safeRect]
        for division in divisions {
            var next: [CGRect] = []
            for pane in panes {
                guard pane.intersects(division) else {
                    next.append(pane)
                    continue
                }
                if division.width >= division.height {
                    let upper = CGRect(x: pane.minX, y: pane.minY, width: pane.width,
                                       height: max(0, division.minY - pane.minY))
                    let lower = CGRect(x: pane.minX, y: division.maxY, width: pane.width,
                                       height: max(0, pane.maxY - division.maxY))
                    if !upper.isEmpty { next.append(upper) }
                    if !lower.isEmpty { next.append(lower) }
                } else {
                    let leading = CGRect(x: pane.minX, y: pane.minY,
                                         width: max(0, division.minX - pane.minX), height: pane.height)
                    let trailing = CGRect(x: division.maxX, y: pane.minY,
                                          width: max(0, pane.maxX - division.maxX), height: pane.height)
                    if !leading.isEmpty { next.append(leading) }
                    if !trailing.isEmpty { next.append(trailing) }
                }
            }
            panes = next
        }
        return panes.filter { !$0.isEmpty }
    }
}
