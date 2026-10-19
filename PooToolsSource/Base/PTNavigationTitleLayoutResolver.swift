//
//  PTNavigationTitleLayoutResolver.swift
//  PooTools
//
//  English: Resolve title-view geometry from local value types only.
//  Español: Resuelve la geometría del título usando únicamente tipos de valor locales.
//  中文：只使用宿主局部值类型计算标题视图几何布局。
//

import CoreGraphics
import Foundation

// English: Keep the three legacy title-view behaviors explicit inside the shared resolver.
// Español: Mantiene explícitos dentro del resolver los tres comportamientos heredados del título.
// 中文：在统一 Resolver 内明确保留三种旧标题行为。
enum PTNavigationTitleLayoutMode: Equatable, Sendable {
    case fillAvailable
    case centerMeasured
    case centerFixed(CGFloat)
}

struct PTNavigationTitleLayoutInput: Equatable, Sendable {
    let visibleRect: CGRect
    let leftOccupiedRect: CGRect?
    let rightOccupiedRect: CGRect?
    let desiredTitleSize: CGSize
    let minimumEdgeInset: CGFloat
    let itemSpacing: CGFloat
    let mode: PTNavigationTitleLayoutMode

    init(visibleRect: CGRect,
         leftOccupiedRect: CGRect?,
         rightOccupiedRect: CGRect?,
         desiredTitleSize: CGSize,
         minimumEdgeInset: CGFloat,
         itemSpacing: CGFloat,
         mode: PTNavigationTitleLayoutMode) {
        self.visibleRect = visibleRect
        self.leftOccupiedRect = leftOccupiedRect
        self.rightOccupiedRect = rightOccupiedRect
        self.desiredTitleSize = desiredTitleSize
        self.minimumEdgeInset = minimumEdgeInset
        self.itemSpacing = itemSpacing
        self.mode = mode
    }
}

struct PTNavigationTitleLayoutResult: Equatable, Sendable {
    let titleFrame: CGRect
    let shouldDisplay: Bool
    let isWidthCompressed: Bool
}

enum PTNavigationTitleLayoutResolver {
    // English: Build physical left and right occupied rectangles in the same local coordinate space as visibleRect.
    // Español: Construye las ocupaciones físicas izquierda y derecha en el mismo espacio local que visibleRect.
    // 中文：在与 visibleRect 相同的局部坐标系中构造物理左右占位区域。
    static func makeInput(visibleRect: CGRect,
                          leftWidth: CGFloat,
                          rightWidth: CGFloat,
                          desiredTitleSize: CGSize,
                          minimumEdgeInset: CGFloat,
                          itemSpacing: CGFloat,
                          mode: PTNavigationTitleLayoutMode) -> PTNavigationTitleLayoutInput {
        let visible = normalizedRect(visibleRect)
        let inset = normalizedNonNegative(minimumEdgeInset)
        let left = normalizedWidth(leftWidth)
        let right = normalizedWidth(rightWidth)
        let spacing = normalizedNonNegative(itemSpacing)
        let leftRect = left > 0 && !visible.isEmpty
            ? CGRect(x: visible.minX + inset, y: visible.minY, width: left, height: visible.height)
            : nil
        let rightRect = right > 0 && !visible.isEmpty
            ? CGRect(x: visible.maxX - inset - right, y: visible.minY, width: right, height: visible.height)
            : nil
        return PTNavigationTitleLayoutInput(visibleRect: visible,
                                            leftOccupiedRect: leftRect,
                                            rightOccupiedRect: rightRect,
                                            desiredTitleSize: normalizedSize(desiredTitleSize),
                                            minimumEdgeInset: inset,
                                            itemSpacing: spacing,
                                            mode: mode)
    }

    // English: Convert the measured input into one finite frame without creating conflicting required constraints.
    // Español: Convierte la entrada medida en un único frame finito sin crear restricciones required conflictivas.
    // 中文：将测量输入转换为有限几何结果，避免生成互相冲突的 required 约束。
    static func resolve(_ input: PTNavigationTitleLayoutInput) -> PTNavigationTitleLayoutResult {
        let visible = normalizedRect(input.visibleRect)
        guard !visible.isEmpty else { return hiddenResult }

        let edgeInset = normalizedNonNegative(input.minimumEdgeInset)
        let spacing = normalizedNonNegative(input.itemSpacing)
        let leftOccupiedBound = normalizedOccupiedRect(input.leftOccupiedRect).map { $0.maxX + spacing }
            ?? -CGFloat.greatestFiniteMagnitude
        let rightOccupiedBound = normalizedOccupiedRect(input.rightOccupiedRect).map { $0.minX - spacing }
            ?? CGFloat.greatestFiniteMagnitude
        let leftBound = max(visible.minX + edgeInset, leftOccupiedBound)
        let rightBound = min(visible.maxX - edgeInset, rightOccupiedBound)
        guard leftBound.isFinite, rightBound.isFinite, rightBound > leftBound else {
            return hiddenResult
        }

        let desiredSize = normalizedSize(input.desiredTitleSize)
        let desiredHeight = min(desiredSize.height, visible.height)
        guard desiredHeight > 0, desiredHeight.isFinite else {
            return hiddenResult
        }

        switch input.mode {
        case .fillAvailable:
            let width = rightBound - leftBound
            guard width > 0, width.isFinite else { return hiddenResult }
            return PTNavigationTitleLayoutResult(
                titleFrame: CGRect(x: leftBound,
                                   y: visible.midY - desiredHeight / 2,
                                   width: width,
                                   height: desiredHeight),
                shouldDisplay: true,
                isWidthCompressed: false
            )

        case .centerMeasured:
            return centeredResult(desiredWidth: desiredSize.width,
                                  desiredHeight: desiredHeight,
                                  visible: visible,
                                  leftBound: leftBound,
                                  rightBound: rightBound)

        case .centerFixed(let fixedWidth):
            let width = normalizedWidth(fixedWidth)
            guard width > 0 else { return hiddenResult }
            return centeredResult(desiredWidth: width,
                                  desiredHeight: desiredHeight,
                                  visible: visible,
                                  leftBound: leftBound,
                                  rightBound: rightBound)
        }
    }

    private static func centeredResult(desiredWidth: CGFloat,
                                       desiredHeight: CGFloat,
                                       visible: CGRect,
                                       leftBound: CGFloat,
                                       rightBound: CGFloat) -> PTNavigationTitleLayoutResult {
        let center = visible.midX
        let availableHalfWidth = max(0, min(center - leftBound, rightBound - center))
        let maximumWidth = availableHalfWidth * 2
        let width = min(normalizedWidth(desiredWidth), maximumWidth)
        guard width > 0, width.isFinite else { return hiddenResult }
        return PTNavigationTitleLayoutResult(
            titleFrame: CGRect(x: center - width / 2,
                               y: visible.midY - desiredHeight / 2,
                               width: width,
                               height: desiredHeight),
            shouldDisplay: true,
            isWidthCompressed: width < normalizedWidth(desiredWidth)
        )
    }

    private static let hiddenResult = PTNavigationTitleLayoutResult(titleFrame: .zero,
                                                                      shouldDisplay: false,
                                                                      isWidthCompressed: false)

    private static func normalizedRect(_ rect: CGRect) -> CGRect {
        guard rect.origin.x.isFinite,
              rect.origin.y.isFinite,
              rect.size.width.isFinite,
              rect.size.height.isFinite,
              rect.size.width >= 0,
              rect.size.height >= 0,
              rect.size.width <= 100_000,
              rect.size.height <= 100_000 else {
            return .zero
        }
        return rect
    }

    private static func normalizedOccupiedRect(_ rect: CGRect?) -> CGRect? {
        guard let rect else { return nil }
        let normalized = normalizedRect(rect)
        return normalized.width > 0 && normalized.height > 0 ? normalized : nil
    }

    private static func normalizedSize(_ size: CGSize) -> CGSize {
        CGSize(width: normalizedWidth(size.width), height: normalizedWidth(size.height))
    }

    private static func normalizedWidth(_ value: CGFloat) -> CGFloat {
        guard value.isFinite, value > 0, value <= 100_000 else { return 0 }
        return value
    }

    private static func normalizedNonNegative(_ value: CGFloat) -> CGFloat {
        guard value.isFinite, value >= 0, value <= 100_000 else { return 0 }
        return value
    }
}
