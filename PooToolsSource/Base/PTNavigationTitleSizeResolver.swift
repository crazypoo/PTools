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

        // English: Ignore a 0/1-point transition bound when UIKit still exposes a useful preferred size.
        // Español: Ignora un bounds de 0/1 punto durante la transición si UIKit aún ofrece un tamaño preferido útil.
        // 中文：如果 UIKit 仍提供有效首选尺寸，就不要让转场中的 0/1 点 bounds 覆盖它。
        var width = explicitWidth ?? preferredDimension(bounds.width) ?? validDimension(intrinsic.width)
        var height = preferredDimension(bounds.height) ?? validDimension(intrinsic.height)

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

    private static func preferredDimension(_ value: CGFloat) -> CGFloat? {
        guard let value = validDimension(value), value > 1 else { return nil }
        return value
    }
}
