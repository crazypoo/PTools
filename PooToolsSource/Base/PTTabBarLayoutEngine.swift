//
//  PTTabBarLayoutEngine.swift
//  PooTools
//
// English: Keep tab-bar width calculations pure and safe before UIKit layout is complete.
// Español: Mantiene puras y seguras las mediciones de ancho antes de completar el layout de UIKit.
// 中文：将 TabBar 宽度计算保持为纯逻辑，并安全处理 UIKit 尚未完成布局的阶段。
//

import UIKit

@MainActor
enum PTTabBarLayoutEngine {
    static func itemWidth(
        containerWidth: CGFloat,
        itemCount: Int,
        layoutStyle: PTTabBarLayoutStyle,
        appearance: PTTabBarLayoutAppearance
    ) -> CGFloat {
        guard itemCount > 0, containerWidth.isFinite, containerWidth > 0 else { return 0 }

        let sideSpacing = appearance.tab26Mode
            ? appearance.tabbarBar26LRSpacing * 2
            : 0
        let centerSize: CGFloat
        switch layoutStyle {
        case .normal:
            centerSize = 0
        case .centerRaised:
            centerSize = appearance.tabbarCenterButtonSize
        }

        let availableWidth = max(0, containerWidth - sideSpacing - centerSize)
        return availableWidth / CGFloat(itemCount)
    }

    // English: Calculate icon height from legacy slot spacing only; selection and content insets stay out.
    // Español: Calcula la altura del icono solo con el espaciado heredado; excluye selección y contenido.
    // 中文：图标高度只使用旧的 Slot 间距计算，选中背景和内容内边距不参与。
    static func itemImageSize(
        barHeight: CGFloat,
        safeAreaHeight: CGFloat,
        titleHeight: CGFloat,
        appearance: PTTabBarLayoutAppearance
    ) -> CGFloat {
        let values = [barHeight, safeAreaHeight, titleHeight,
                      appearance.tabTopSpacing, appearance.tabContentSpacing,
                      appearance.tabBottomSpacing]
        guard values.allSatisfy(\.isFinite) else { return 0 }
        return max(0,
                   barHeight
                   - safeAreaHeight
                   - appearance.tabTopSpacing
                   - appearance.tabContentSpacing
                   - titleHeight
                   - appearance.tabBottomSpacing)
    }

    // English: Clamp selection insets so malformed values cannot create negative or non-finite frames.
    // Español: Limita los insets de selección para impedir marcos negativos o no finitos.
    // 中文：限制选中背景内缩，避免非法值生成负数或非有限 Frame。
    static func selectionFrame(frame: CGRect, insets: UIEdgeInsets) -> CGRect {
        guard frame.origin.x.isFinite,
              frame.origin.y.isFinite,
              frame.width.isFinite,
              frame.height.isFinite else { return .zero }

        let width = max(frame.width, 0)
        let height = max(frame.height, 0)
        let left = min(max(insets.left.isFinite ? insets.left : 0, 0), width)
        let right = min(max(insets.right.isFinite ? insets.right : 0, 0), max(width - left, 0))
        let top = min(max(insets.top.isFinite ? insets.top : 0, 0), height)
        let bottom = min(max(insets.bottom.isFinite ? insets.bottom : 0, 0), max(height - top, 0))

        return CGRect(x: frame.minX + left,
                      y: frame.minY + top,
                      width: max(width - left - right, 0),
                      height: max(height - top - bottom, 0))
    }

    // English: Normalize item padding and keep it safe for Auto Layout.
    // Español: Normaliza el relleno del elemento y lo mantiene seguro para Auto Layout.
    // 中文：规范化项目内边距，确保 Auto Layout 使用安全值。
    static func safeContentInsets(_ insets: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(top: insets.top.isFinite ? max(0, insets.top) : 0,
                     left: insets.left.isFinite ? max(0, insets.left) : 0,
                     bottom: insets.bottom.isFinite ? max(0, insets.bottom) : 0,
                     right: insets.right.isFinite ? max(0, insets.right) : 0)
    }

    // English: Normalize content translation without allowing NaN or infinity into constraints.
    // Español: Normaliza la traslación del contenido sin permitir NaN o infinito en las restricciones.
    // 中文：规范化内容偏移，避免 NaN 或无穷值进入约束。
    static func safeContentOffset(_ offset: UIOffset) -> UIOffset {
        UIOffset(horizontal: offset.horizontal.isFinite ? offset.horizontal : 0,
                 vertical: offset.vertical.isFinite ? offset.vertical : 0)
    }
}
