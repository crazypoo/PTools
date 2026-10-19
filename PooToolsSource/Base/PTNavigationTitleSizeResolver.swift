//
//  PTNavigationTitleSizeResolver.swift
//  PooTools
//
//  English: Resolve title-view size without inventing a universal width.
//  Español: Resuelve el tamaño del título sin inventar un ancho universal.
//  中文：统一解析标题视图尺寸，不臆造通用固定宽度。
//

import UIKit

@MainActor
enum PTNavigationTitleSizeResolver {
    // English: Keep UIKit measurement on MainActor because intrinsic content and fitting are view operations.
    // Español: Mantiene la medición de UIKit en MainActor porque intrinsic y fitting son operaciones de View.
    // 中文：Intrinsic 和 fitting 都属于 View 操作，因此统一在 MainActor 测量。
    static func resolve(view: UIView,
                        availableHeight: CGFloat,
                        fixedWidth: CGFloat? = nil) -> CGSize {
        let maximumHeight = validDimension(availableHeight)
        let explicitWidth = fixedWidth.flatMap(validDimension)
        let bounds = view.bounds.size
        let intrinsic = view.intrinsicContentSize

        var width = explicitWidth ?? validDimension(bounds.width) ?? validDimension(intrinsic.width)
        var height = validDimension(bounds.height) ?? validDimension(intrinsic.height)

        if width == nil || height == nil {
            let fitting = view.systemLayoutSizeFitting(
                UIView.layoutFittingCompressedSize,
                withHorizontalFittingPriority: .fittingSizeLevel,
                verticalFittingPriority: .fittingSizeLevel
            )
            width = width ?? validDimension(fitting.width)
            height = height ?? validDimension(fitting.height)
        }

        let resolvedHeight = min(height ?? maximumHeight ?? 0, maximumHeight ?? height ?? 0)
        return CGSize(width: max(0, width ?? 0),
                      height: max(0, resolvedHeight))
    }

    private static func validDimension(_ value: CGFloat) -> CGFloat? {
        guard value.isFinite, value > 0, value <= 100_000 else { return nil }
        return value
    }
}
