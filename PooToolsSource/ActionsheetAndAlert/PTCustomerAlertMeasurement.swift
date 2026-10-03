// English: Measure the alert body using its real Auto Layout hierarchy and a bounded fallback height.
// Español: Mide el cuerpo de la alerta con su jerarquía Auto Layout real y una altura de reserva acotada.
// 中文：基于真实 Auto Layout 层级测量 Alert 内容，并提供有界兜底高度。

import UIKit
import SnapKit

@MainActor
extension PTCustomerAlertController {

    /// 获取 Auto Layout 的真实 Body 高度。
    ///
    /// 与旧方案不同：
    /// - 不再手工计算 title 高度；
    /// - 不再把最小高度加到 UILabel 本身；
    /// - 最小视觉高度由 bodyHeaderView 的约束承担；
    /// - headerContentView 垂直居中，因此短内容的留白上下对称。
    func resolvedBodyHeight(for width: CGFloat) -> CGFloat {
        guard hasTitle || hasCustomContent else { return 0 }

        bodyHeaderMinimumHeightConstraint?.update(offset: minimumBodyHeight)

        let safeWidth = max(1, width)
        bodyHeaderView.bounds.size.width = safeWidth
        bodyHeaderView.setNeedsLayout()
        bodyHeaderView.layoutIfNeeded()

        let fittingSize = CGSize(
            width: safeWidth,
            height: UIView.layoutFittingCompressedSize.height
        )

        let size = bodyHeaderView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        guard size.height.isFinite else {
            return minimumBodyHeight
        }

        return ceil(max(minimumBodyHeight, size.height))
    }
}
