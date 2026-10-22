//
//  PTNavigationContentRowResolver.swift
//  PooTools
//
// English: Resolve one host-local navigation content row without UIKit state.
// Español: Resuelve una única fila de contenido local del host sin estado de UIKit.
// 中文：不依赖 UIKit 状态，解析导航宿主局部坐标中的唯一内容行。
//

import CoreGraphics

// English: Keep navigation-row inputs as immutable values so geometry can be tested independently.
// Español: Mantiene las entradas de la fila como valores inmutables para probar la geometría por separado.
// 中文：将内容行输入保持为不可变值，便于独立测试几何逻辑。
struct PTNavigationContentRowInput: Equatable, Sendable {
    let hostBounds: CGRect
    let hostSafeRect: CGRect
    let systemContentRect: CGRect?
    let isLargeTitleExpanded: Bool
    let compactRowHeight: CGFloat?

    init(hostBounds: CGRect,
         hostSafeRect: CGRect,
         systemContentRect: CGRect? = nil,
         isLargeTitleExpanded: Bool = false,
         compactRowHeight: CGFloat? = nil) {
        self.hostBounds = hostBounds
        self.hostSafeRect = hostSafeRect
        self.systemContentRect = systemContentRect
        self.isLargeTitleExpanded = isLargeTitleExpanded
        self.compactRowHeight = compactRowHeight
    }
}

// English: Return the single bounded content rectangle used by left, title and right items.
// Español: Devuelve el único rectángulo acotado usado por los elementos izquierdo, título y derecho.
// 中文：返回供左侧、标题和右侧内容共同使用的单一有效矩形。
struct PTNavigationContentRowResult: Equatable, Sendable {
    let contentRect: CGRect
}

enum PTNavigationContentRowResolver {
    // English: Prefer an observable system row, then a local safe rect, and never cache an invalid zero rect.
    // Español: Prioriza la fila observable del sistema, después el rect seguro local y nunca guarda un rect cero inválido.
    // 中文：优先采用可观测的系统内容行，其次使用局部安全区域，且不缓存无效的零矩形。
    static func resolve(_ input: PTNavigationContentRowInput) -> PTNavigationContentRowResult? {
        guard let host = normalizedRect(input.hostBounds), !host.isEmpty else { return nil }

        let safeRect = bounded(input.hostSafeRect, in: host) ?? host
        if let systemRect = input.systemContentRect,
           let contentRect = bounded(systemRect, in: host),
           !contentRect.isEmpty {
            return PTNavigationContentRowResult(contentRect: contentRect)
        }

        guard input.isLargeTitleExpanded else {
            return PTNavigationContentRowResult(contentRect: safeRect)
        }

        guard let compactHeight = normalizedLength(input.compactRowHeight), compactHeight > 0 else {
            return nil
        }

        let rowY = max(host.minY, safeRect.minY)
        let availableHeight = min(compactHeight, max(0, host.maxY - rowY))
        guard availableHeight > 0 else { return nil }

        return PTNavigationContentRowResult(
            contentRect: CGRect(x: safeRect.minX,
                                y: rowY,
                                width: safeRect.width,
                                height: availableHeight)
        )
    }

    private static func bounded(_ candidate: CGRect, in host: CGRect) -> CGRect? {
        guard let normalized = normalizedRect(candidate) else { return nil }
        let intersection = normalized.intersection(host)
        return intersection.isNull || intersection.isEmpty ? nil : intersection
    }

    private static func normalizedRect(_ rect: CGRect) -> CGRect? {
        guard rect.origin.x.isFinite,
              rect.origin.y.isFinite,
              rect.width.isFinite,
              rect.height.isFinite,
              rect.width >= 0,
              rect.height >= 0,
              rect.width <= 100_000,
              rect.height <= 100_000 else {
            return nil
        }
        return rect.standardized
    }

    private static func normalizedLength(_ value: CGFloat?) -> CGFloat? {
        guard let value,
              value.isFinite,
              value > 0,
              value <= 100_000 else {
            return nil
        }
        return value
    }
}
