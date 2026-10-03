// English: Pure geometry calculations for safe-area-aware paging layouts.
// Español: Cálculos geométricos puros para layouts de paginación conscientes del área segura.
// 中文：安全区感知分页布局的纯几何计算。

import UIKit

/// English: Single layout calculation point for safe-area-aware paging geometry.
/// Español: Punto único de cálculo para la geometría de paginación consciente del área segura.
/// 中文：集中计算安全区相关分页几何尺寸。
@MainActor
public struct PTPagingLayoutEngine {
    public var safeAreaTop: CGFloat
    public var headerHeight: CGFloat
    public var pinnedHeight: CGFloat
    public var pageHeight: CGFloat

    public init(safeAreaTop: CGFloat = 0,
                headerHeight: CGFloat = 0,
                pinnedHeight: CGFloat = 0,
                pageHeight: CGFloat = 0) {
        self.safeAreaTop = safeAreaTop
        self.headerHeight = headerHeight
        self.pinnedHeight = pinnedHeight
        self.pageHeight = pageHeight
    }

    public var contentHeight: CGFloat { headerHeight + pinnedHeight + pageHeight }
    public var collapseLimit: CGFloat { max(0, headerHeight) }
}
