//
//  PTTabBarLayoutEngine.swift
//  PooTools
//
// English: Keep tab-bar width calculations pure and safe before UIKit layout is complete.
// Español: Mantiene puras y seguras las mediciones de ancho antes de completar el layout de UIKit.
// 中文：将 TabBar 宽度计算保持为纯逻辑，并安全处理 UIKit 尚未完成布局的阶段。
//

import UIKit

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
}
