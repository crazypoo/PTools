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
    let exclusionRects: [CGRect]
    let evidence: PTNavigationContentRowEvidence
    let isLargeTitleExpanded: Bool
    let compactRowHeight: CGFloat?

    init(hostBounds: CGRect,
         hostSafeRect: CGRect,
         observedSystemRowRect: CGRect? = nil,
         fallbackRowRect: CGRect? = nil,
         exclusionRects: [CGRect] = [],
         evidence: PTNavigationContentRowEvidence = .fallback,
         isLargeTitleExpanded: Bool = false,
         compactRowHeight: CGFloat? = nil) {
        self.hostBounds = hostBounds
        self.hostSafeRect = hostSafeRect
        self.observedSystemRowRect = observedSystemRowRect
        self.fallbackRowRect = fallbackRowRect
        self.exclusionRects = exclusionRects
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
                  exclusionRects: [],
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

// English: Keep horizontal edge avoidance as a value so custom navigation bars can share the same collision result.
// Español: Mantiene la evitación horizontal de los bordes como un valor para que las barras personalizadas compartan el mismo resultado de colisión.
// 中文：将横向边缘避让保持为值类型，让自定义导航栏共享同一套碰撞结果。
struct PTNavigationContentEdgeInsets: Equatable, Sendable {
    let leading: CGFloat
    let trailing: CGFloat
}

enum PTNavigationContentRowResolver {
    // English: Move an edge item group away from an exclusion that overlaps its current host-local slot.
    // Español: Aleja el grupo de elementos del borde de una exclusión que invade su posición local actual.
    // 中文：当排斥区侵入按钮当前的宿主局部位置时，将按钮组向内容区域内移动。
    static func resolveEdgeInsets(rowBounds: CGRect,
                                  leadingItemWidth: CGFloat,
                                  trailingItemWidth: CGFloat,
                                  minimumLeading: CGFloat,
                                  minimumTrailing: CGFloat,
                                  exclusionRects: [CGRect]) -> PTNavigationContentEdgeInsets {
        guard let row = normalizedRect(rowBounds), !row.isEmpty else {
            return PTNavigationContentEdgeInsets(leading: max(0, minimumLeading),
                                                 trailing: max(0, minimumTrailing))
        }

        let leadingWidth = normalizedLength(leadingItemWidth) ?? 0
        let trailingWidth = normalizedLength(trailingItemWidth) ?? 0
        let leadingMinimum = normalizedLength(minimumLeading) ?? 0
        let trailingMinimum = normalizedLength(minimumTrailing) ?? 0
        var leading = leadingMinimum
        var trailing = trailingMinimum
        let leadingSlot = CGRect(x: row.minX + leadingMinimum,
                                 y: row.minY,
                                 width: leadingWidth,
                                 height: row.height)
        let trailingSlot = CGRect(x: row.maxX - trailingMinimum - trailingWidth,
                                  y: row.minY,
                                  width: trailingWidth,
                                  height: row.height)

        for exclusion in exclusionRects.compactMap({ bounded($0, in: row) }) {
            if !leadingSlot.isEmpty, leadingSlot.intersects(exclusion) {
                leading = max(leading,
                              exclusion.maxX - row.minX + leadingMinimum)
            }
            if !trailingSlot.isEmpty, trailingSlot.intersects(exclusion) {
                trailing = max(trailing,
                               row.maxX - exclusion.minX + trailingMinimum)
            }
        }

        // English: Never create impossible constraints when an exclusion consumes nearly the whole row.
        // Español: Nunca crea restricciones imposibles cuando una exclusión consume casi toda la fila.
        // 中文：当排斥区几乎占满内容行时，不创建不可能满足的约束。
        let availableForLeading = max(leadingMinimum,
                                      row.width - trailingWidth - trailingMinimum)
        leading = min(leading, availableForLeading)
        let availableForTrailing = max(trailingMinimum,
                                       row.width - leadingWidth - leading)
        trailing = min(trailing, availableForTrailing)

        return PTNavigationContentEdgeInsets(leading: max(leadingMinimum, leading),
                                             trailing: max(trailingMinimum, trailing))
    }

    // English: Use UIKit observations only when valid; otherwise use a host-local fallback or defer.
    // Español: Usa observaciones de UIKit solo cuando son válidas; si no, usa un fallback local o difiere.
    // 中文：仅在 UIKit 观测值有效时使用，否则使用宿主局部回退或延后布局。
    static func resolve(_ input: PTNavigationContentRowInput) -> PTNavigationContentRowResult? {
        guard let host = normalizedRect(input.hostBounds), !host.isEmpty else { return nil }

        guard input.evidence != .deferred else { return nil }

        let safeRect = bounded(input.hostSafeRect, in: host) ?? host
        let exclusions = input.exclusionRects.compactMap { bounded($0, in: host) }
        if input.evidence == .observed,
           let systemRect = input.observedSystemRowRect,
           let contentRect = bounded(systemRect, in: host),
           !contentRect.isEmpty,
           !intersectsAny(contentRect, exclusions) {
            return PTNavigationContentRowResult(contentRect: contentRect, evidence: .observed)
        }

        let fallbackRect = bounded(input.fallbackRowRect ?? safeRect, in: host) ?? safeRect
        guard let safeFallbackRect = fallbackRectAvoidingExclusions(fallbackRect,
                                                                    in: host,
                                                                    exclusions: exclusions) else {
            return nil
        }
        guard input.isLargeTitleExpanded else {
            guard !safeFallbackRect.isEmpty else { return nil }
            return PTNavigationContentRowResult(contentRect: safeFallbackRect, evidence: .fallback)
        }

        let compactRect: CGRect
        if let compactHeight = normalizedLength(input.compactRowHeight), compactHeight > 0 {
            let rowY = max(host.minY, safeFallbackRect.minY)
            let availableHeight = min(compactHeight, max(0, safeFallbackRect.maxY - rowY))
            guard availableHeight > 0 else { return nil }
            compactRect = CGRect(x: safeFallbackRect.minX,
                                 y: rowY,
                                 width: safeFallbackRect.width,
                                 height: availableHeight)
        } else {
            compactRect = safeFallbackRect
        }
        guard !compactRect.isEmpty,
              !intersectsAny(compactRect, exclusions) else { return nil }
        return PTNavigationContentRowResult(contentRect: compactRect, evidence: .fallback)
    }

    // English: Reject an observed row that intersects a real status or occlusion region.
    // Español: Rechaza una fila observada que intersecta una región real de estado u oclusión.
    // 中文：拒绝与真实状态栏或遮挡区域相交的实测内容行。
    private static func intersectsAny(_ rect: CGRect, _ exclusions: [CGRect]) -> Bool {
        exclusions.contains { rect.intersects($0) }
    }

    // English: Keep the row inside the host while choosing the largest usable vertical segment.
    // Español: Mantiene la fila dentro del host y elige el mayor segmento vertical utilizable.
    // 中文：让内容行保持在宿主内，并选择最大的可用垂直区域。
    private static func fallbackRectAvoidingExclusions(_ rect: CGRect,
                                                       in host: CGRect,
                                                       exclusions: [CGRect]) -> CGRect? {
        guard !intersectsAny(rect, exclusions) else {
            let relevantExclusions = exclusions.filter {
                $0.minX < rect.maxX && $0.maxX > rect.minX
            }
            var segments = [CGRect(x: host.minX,
                                   y: host.minY,
                                   width: host.width,
                                   height: host.height)]
            for exclusion in relevantExclusions {
                var nextSegments: [CGRect] = []
                for segment in segments {
                    guard segment.intersects(exclusion) else {
                        nextSegments.append(segment)
                        continue
                    }

                    let upper = CGRect(x: segment.minX,
                                       y: segment.minY,
                                       width: segment.width,
                                       height: max(0, min(segment.maxY, exclusion.minY) - segment.minY))
                    let lower = CGRect(x: segment.minX,
                                       y: max(segment.minY, exclusion.maxY),
                                       width: segment.width,
                                       height: max(0, segment.maxY - max(segment.minY, exclusion.maxY)))
                    if !upper.isEmpty { nextSegments.append(upper) }
                    if !lower.isEmpty { nextSegments.append(lower) }
                }
                segments = nextSegments
            }

            guard let usableSegment = segments
                .filter({ !$0.isEmpty })
                .max(by: { lhs, rhs in
                    let lhsDistance = abs(lhs.midY - rect.midY)
                    let rhsDistance = abs(rhs.midY - rect.midY)
                    if lhs.height == rhs.height { return lhsDistance > rhsDistance }
                    return lhs.height < rhs.height
                }) else {
                return nil
            }

            let height = min(rect.height, usableSegment.height)
            guard height > 0 else { return nil }
            let y = min(max(rect.midY - height / 2,
                            usableSegment.minY),
                        usableSegment.maxY - height)
            let adjusted = CGRect(x: min(max(rect.minX, host.minX), host.maxX - rect.width),
                                  y: y,
                                  width: min(rect.width, host.width),
                                  height: height)
            return intersectsAny(adjusted, exclusions) ? nil : adjusted
        }
        return rect
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
