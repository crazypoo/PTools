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
enum PTNavigationContentRowEvidence: String, Equatable, Sendable {
    case observed
    case fallback
    case deferred
}

struct PTNavigationContentRowInput: Equatable, Sendable {
    let hostBounds: CGRect
    let hostSafeRect: CGRect
    let observedSystemRowRect: CGRect?
    let fallbackRowRect: CGRect?
    let evidence: PTNavigationContentRowEvidence
    let isLargeTitleExpanded: Bool
    let compactRowHeight: CGFloat?

    init(hostBounds: CGRect,
         hostSafeRect: CGRect,
         observedSystemRowRect: CGRect? = nil,
         fallbackRowRect: CGRect? = nil,
         evidence: PTNavigationContentRowEvidence = .fallback,
         isLargeTitleExpanded: Bool = false,
         compactRowHeight: CGFloat? = nil) {
        self.hostBounds = hostBounds
        self.hostSafeRect = hostSafeRect
        self.observedSystemRowRect = observedSystemRowRect
        self.fallbackRowRect = fallbackRowRect
        self.evidence = evidence
        self.isLargeTitleExpanded = isLargeTitleExpanded
        self.compactRowHeight = compactRowHeight
    }

    // English: Preserve the old internal initializer while routing it through explicit row evidence.
    // Español: Conserva el inicializador interno anterior y lo dirige mediante evidencia explícita.
    // 中文：保留旧的内部初始化方式，同时统一转换到明确的内容行证据。
    init(hostBounds: CGRect,
         hostSafeRect: CGRect,
         systemContentRect: CGRect?,
         isLargeTitleExpanded: Bool = false,
         compactRowHeight: CGFloat? = nil) {
        self.init(hostBounds: hostBounds,
                  hostSafeRect: hostSafeRect,
                  observedSystemRowRect: systemContentRect,
                  fallbackRowRect: hostSafeRect,
                  evidence: systemContentRect == nil ? .fallback : .observed,
                  isLargeTitleExpanded: isLargeTitleExpanded,
                  compactRowHeight: compactRowHeight)
    }
}

// English: Return the single bounded content rectangle used by left, title and right items.
// Español: Devuelve el único rectángulo acotado usado por los elementos izquierdo, título y derecho.
// 中文：返回供左侧、标题和右侧内容共同使用的单一有效矩形。
struct PTNavigationContentRowResult: Equatable, Sendable {
    let contentRect: CGRect
    let evidence: PTNavigationContentRowEvidence
}

enum PTNavigationContentRowResolver {
    // English: Use UIKit observations only when valid; otherwise use a host-local fallback or defer.
    // Español: Usa observaciones de UIKit solo cuando son válidas; si no, usa un fallback local o difiere.
    // 中文：仅在 UIKit 观测值有效时使用，否则使用宿主局部回退或延后布局。
    static func resolve(_ input: PTNavigationContentRowInput) -> PTNavigationContentRowResult? {
        guard let host = normalizedRect(input.hostBounds), !host.isEmpty else { return nil }

        guard input.evidence != .deferred else { return nil }

        let safeRect = bounded(input.hostSafeRect, in: host) ?? host
        if input.evidence == .observed,
           let systemRect = input.observedSystemRowRect,
           let contentRect = bounded(systemRect, in: host),
           !contentRect.isEmpty {
            return PTNavigationContentRowResult(contentRect: contentRect, evidence: .observed)
        }

        let fallbackRect = bounded(input.fallbackRowRect ?? safeRect, in: host) ?? safeRect
        guard input.isLargeTitleExpanded else {
            guard !fallbackRect.isEmpty else { return nil }
            return PTNavigationContentRowResult(contentRect: fallbackRect, evidence: .fallback)
        }

        let compactRect: CGRect
        if let compactHeight = normalizedLength(input.compactRowHeight), compactHeight > 0 {
            let rowY = max(host.minY, fallbackRect.minY)
            let availableHeight = min(compactHeight, max(0, host.maxY - rowY))
            guard availableHeight > 0 else { return nil }
            compactRect = CGRect(x: fallbackRect.minX,
                                 y: rowY,
                                 width: fallbackRect.width,
                                 height: availableHeight)
        } else {
            compactRect = fallbackRect
        }
        guard !compactRect.isEmpty else { return nil }
        return PTNavigationContentRowResult(contentRect: compactRect, evidence: .fallback)
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
