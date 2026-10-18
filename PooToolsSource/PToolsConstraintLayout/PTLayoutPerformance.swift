// English: Lightweight MainActor metrics and keyboard helpers for the native layout product.
// Español: Métricas ligeras en MainActor y helpers de teclado para el producto de layout nativo.
// 中文：为原生布局产品提供轻量 MainActor 性能指标和键盘辅助能力。

#if canImport(UIKit)
import Foundation
import UIKit

@MainActor
public struct PTLayoutProfileSnapshot: Sendable {
    public let makeCount: Int
    public let updateCount: Int
    public let remakeCount: Int
    public let prepareCount: Int
    /// English: Counts constraints handed to UIKit by PTLayout; it is cumulative install-event data, not the current active total.
    /// Español: Cuenta las restricciones entregadas a UIKit por PTLayout; es un acumulado de instalaciones, no el total activo actual.
    /// 中文：统计 PTLayout 交给 UIKit 的约束数量；这是累计安装事件，不是当前激活约束总数。
    public let installedConstraintCount: Int

    public init(makeCount: Int,
                updateCount: Int,
                remakeCount: Int,
                prepareCount: Int,
                installedConstraintCount: Int) {
        self.makeCount = makeCount
        self.updateCount = updateCount
        self.remakeCount = remakeCount
        self.prepareCount = prepareCount
        self.installedConstraintCount = installedConstraintCount
    }
}

@MainActor
public enum PTLayoutProfiler {
    public static var isEnabled = false

    private static var makeCount = 0
    private static var updateCount = 0
    private static var remakeCount = 0
    private static var prepareCount = 0
    private static var installedConstraintCount = 0

    public static func reset() {
        makeCount = 0
        updateCount = 0
        remakeCount = 0
        prepareCount = 0
        installedConstraintCount = 0
    }

    public static func snapshot() -> PTLayoutProfileSnapshot {
        PTLayoutProfileSnapshot(makeCount: makeCount,
                                updateCount: updateCount,
                                remakeCount: remakeCount,
                                prepareCount: prepareCount,
                                installedConstraintCount: installedConstraintCount)
    }

    internal static func record(operation: PTLayoutOperation, count: Int) {
        guard isEnabled else { return }
        switch operation {
        case .make:
            makeCount += 1
        case .update:
            updateCount += 1
        case .remake:
            remakeCount += 1
        case .prepare:
            prepareCount += 1
        }
        installedConstraintCount += max(0, count)
    }
}

@available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
@MainActor
public enum PTLayoutKeyboardSupport {
    /// English: Configure UIKit's own tracking guide; do not stack a second inset system on top.
    /// Español: Configura la guía de seguimiento de UIKit; no apiles otro sistema de insets encima.
    /// 中文：配置 UIKit 自带的跟踪布局指南，不要再叠加第二套 inset 系统。
    public static func setFollowsUndockedKeyboard(_ follows: Bool,
                                                   on view: UIView) {
        view.keyboardLayoutGuide.followsUndockedKeyboard = follows
    }
}

#endif
