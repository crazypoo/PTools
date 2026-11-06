//
//  PTNavigationRendererReconciliationTests.swift
//  PTools
//
// English: Verify renderer ownership decisions without depending on UIKit's private Duo behavior.
// Español: Verifica las decisiones de propiedad sin depender del comportamiento privado de Duo en UIKit.
// 中文：不依赖 UIKit 私有 Duo 行为，验证导航渲染器所有权决策。
//

import XCTest
import UIKit
@testable import ptools

// English: Model the minimum renderer owner state needed to exercise repeated lifecycle signals.
// Español: Modela el estado mínimo del propietario del renderizador para probar señales repetidas del ciclo de vida.
// 中文：用最小渲染器所有权状态模拟重复生命周期信号。
private struct FakeNavigationRendererOwner {
    var mode: PTNavigationRendererMode?
    var visibleControllerID = "root"
    var itemAttached = true
    var geometrySignature = "initial"

    mutating func reconcile(target: PTNavigationRendererMode,
                            visibleControllerID: String,
                            geometrySignature: String,
                            transitionActive: Bool) -> PTNavigationRendererReconciliationDecision {
        let geometryChanged = self.geometrySignature != geometrySignature
        let decision = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: mode,
            targetMode: target,
            itemAttached: itemAttached && self.visibleControllerID == visibleControllerID,
            geometryChanged: geometryChanged,
            transitionActive: transitionActive
        ))
        guard decision == .reconcile else { return decision }
        mode = target
        self.visibleControllerID = visibleControllerID
        self.geometrySignature = geometrySignature
        itemAttached = true
        return decision
    }
}

@MainActor
private final class RequestedSizeNavigationButton: UIView, PTNavigationItemSizeProviding {
    var ptPreferredNavigationItemSize: CGSize

    init(width: CGFloat) {
        ptPreferredNavigationItemSize = CGSize(width: width, height: 32)
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: 32))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

final class PTNavigationRendererReconciliationTests: XCTestCase {
    func testCustomToSystemReconciles() {
        let decision = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: .customHorizontal,
            targetMode: .systemVertical,
            itemAttached: true,
            geometryChanged: false,
            transitionActive: false
        ))

        XCTAssertEqual(decision, .reconcile)
    }

    func testSystemToCustomReconciles() {
        let decision = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: .systemVertical,
            targetMode: .customHorizontal,
            itemAttached: true,
            geometryChanged: false,
            transitionActive: false
        ))

        XCTAssertEqual(decision, .reconcile)
    }

    func testSameRendererAndGeometryIsNoOp() {
        let decision = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: .customHorizontal,
            targetMode: .customHorizontal,
            itemAttached: true,
            geometryChanged: false,
            transitionActive: false
        ))

        XCTAssertEqual(decision, .noOp)
    }

    @MainActor
    func testExplicitItemWidthOverridesStaleStackConstraintAndNativeWrapper() {
        let button = RequestedSizeNavigationButton(width: 100)
        let item = PTNavBarItem()
        item.rightViews = [button]
        let container = PTNavigationBarContainer(frame: CGRect(x: 0, y: 0, width: 390, height: 54))

        let initialWidth = container.configureNavigationBarItems(
            [button], in: container.rightContainer, spacing: 8)
        XCTAssertEqual(initialWidth, 100, accuracy: 0.01)

        // The previous stack width remains 100 until the navigation layout is reapplied.
        button.ptPreferredNavigationItemSize = CGSize(width: 50, height: 32)
        XCTAssertEqual(button.bounds.width, 100, accuracy: 0.01)
        let changed = PTNavigationItemLayoutSignature(item: item)
        XCTAssertEqual(changed.right[0].size.width, 50, accuracy: 0.01)

        let updatedWidth = container.configureNavigationBarItems(
            [button], in: container.rightContainer, spacing: 8)
        XCTAssertEqual(updatedWidth, 50, accuracy: 0.01)

        // Duo's UIKit-managed bar item must use the same requested size.
        let native = PTNativeNavigationItemView(contentView: button)
        XCTAssertEqual(native.intrinsicContentSize.width, 50, accuracy: 0.01)
    }

    // Changing the text width of an existing custom navigation button must
    // invalidate the item layout without changing view identity or host geometry.
    @MainActor
    func testSameNavigationButtonResizesWithoutRendererChange() {
        let button = UIView(frame: CGRect(x: 0, y: 0, width: 68, height: 32))
        let item = PTNavBarItem()
        item.rightViews = [button]
        item.rightItemSpacing = 8
        let initial = PTNavigationItemLayoutSignature(item: item)

        button.bounds.size.width = 104
        let resized = PTNavigationItemLayoutSignature(item: item)
        XCTAssertNotEqual(initial, resized)
        XCTAssertEqual(initial.right[0].identity, resized.right[0].identity)

        let decision = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: .customHorizontal,
            targetMode: .customHorizontal,
            itemAttached: true,
            geometryChanged: false,
            transitionActive: false,
            itemLayoutChanged: initial != resized
        ))
        XCTAssertEqual(decision, .reconcile)

        let stable = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: .customHorizontal,
            targetMode: .customHorizontal,
            itemAttached: true,
            geometryChanged: false,
            transitionActive: false,
            itemLayoutChanged: resized != PTNavigationItemLayoutSignature(item: item)
        ))
        XCTAssertEqual(stable, .noOp)
    }

    @MainActor
    func testNavigationItemSpacingChangeAndTransitionDeferral() {
        let item = PTNavBarItem()
        item.rightViews = [UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 32))]
        item.rightItemSpacing = 4
        let original = PTNavigationItemLayoutSignature(item: item)
        item.rightItemSpacing = 12
        XCTAssertNotEqual(original, PTNavigationItemLayoutSignature(item: item))

        let decision = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: .systemVertical,
            targetMode: .systemVertical,
            itemAttached: true,
            geometryChanged: false,
            transitionActive: true,
            itemLayoutChanged: true
        ))
        XCTAssertEqual(decision, .deferUntilTransitionCompletes)
    }

    func testDetachedItemReconcilesWithoutRendererChange() {
        let decision = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: .customHorizontal,
            targetMode: .customHorizontal,
            itemAttached: false,
            geometryChanged: false,
            transitionActive: false
        ))

        XCTAssertEqual(decision, .reconcile)
    }

    func testGeometryChangeReconcilesWithoutRendererChange() {
        let decision = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: .systemVertical,
            targetMode: .systemVertical,
            itemAttached: true,
            geometryChanged: true,
            transitionActive: false
        ))

        XCTAssertEqual(decision, .reconcile)
    }

    func testActiveTransitionDefersUntilFinalVisibleController() {
        let decision = PTNavigationRendererReconciliationPlanner.decision(for: .init(
            currentMode: .customHorizontal,
            targetMode: .systemVertical,
            itemAttached: false,
            geometryChanged: true,
            transitionActive: true
        ))

        XCTAssertEqual(decision, .deferUntilTransitionCompletes)
    }

    // English: Verify a repeated custom/system/custom sequence never leaves the fake owner in an intermediate mode.
    // Español: Verifica que una secuencia repetida custom/system/custom nunca deje al propietario simulado en un modo intermedio.
    // 中文：验证 custom/system/custom 连续切换不会让模拟所有权停留在中间状态。
    func testRepeatedRendererSwitchRestoresTheFinalOwner() {
        var owner = FakeNavigationRendererOwner(mode: .customHorizontal)

        XCTAssertEqual(owner.reconcile(target: .systemVertical,
                                       visibleControllerID: "root",
                                       geometrySignature: "expanded",
                                       transitionActive: false),
                       .reconcile)
        XCTAssertEqual(owner.reconcile(target: .customHorizontal,
                                       visibleControllerID: "root",
                                       geometrySignature: "expanded",
                                       transitionActive: false),
                       .reconcile)
        XCTAssertEqual(owner.mode, .customHorizontal)
        XCTAssertTrue(owner.itemAttached)
    }

    // English: A visible-controller change invalidates the old item even when the renderer stays custom.
    // Español: Un cambio del controlador visible invalida el elemento anterior aunque el renderizador siga siendo custom.
    // 中文：即使渲染器不变，可见控制器变化也必须使旧导航项失效并重新挂载。
    func testVisibleControllerChangeReattachesTheCurrentItem() {
        var owner = FakeNavigationRendererOwner(mode: .customHorizontal,
                                                 visibleControllerID: "first",
                                                 itemAttached: true,
                                                 geometrySignature: "same")

        XCTAssertEqual(owner.reconcile(target: .customHorizontal,
                                       visibleControllerID: "second",
                                       geometrySignature: "same",
                                       transitionActive: false),
                       .reconcile)
        XCTAssertEqual(owner.visibleControllerID, "second")
        XCTAssertTrue(owner.itemAttached)
    }

    // English: A cancelled transition defers ownership and commits only after the final visible controller is known.
    // Español: Una transición cancelada aplaza la propiedad y solo confirma después de conocer el controlador visible final.
    // 中文：取消转场时延后切换所有权，等最终可见控制器确定后再提交。
    func testCancelledTransitionCommitsAfterTheTransitionEnds() {
        var owner = FakeNavigationRendererOwner(mode: .customHorizontal,
                                                 visibleControllerID: "from",
                                                 itemAttached: true,
                                                 geometrySignature: "before")

        XCTAssertEqual(owner.reconcile(target: .systemVertical,
                                       visibleControllerID: "to",
                                       geometrySignature: "during",
                                       transitionActive: true),
                       .deferUntilTransitionCompletes)
        XCTAssertEqual(owner.mode, .customHorizontal)

        XCTAssertEqual(owner.reconcile(target: .customHorizontal,
                                       visibleControllerID: "from",
                                       geometrySignature: "after-cancel",
                                       transitionActive: false),
                       .reconcile)
        XCTAssertEqual(owner.visibleControllerID, "from")
        XCTAssertEqual(owner.mode, .customHorizontal)
    }

    // English: Once the owner and geometry are stable, duplicate lifecycle callbacks are no-ops.
    // Español: Cuando la propiedad y la geometría son estables, los callbacks duplicados no hacen nada.
    // 中文：所有权和几何稳定后，重复生命周期回调应为 no-op。
    func testRepeatedStableCallbacksAreNoOps() {
        var owner = FakeNavigationRendererOwner(mode: .systemVertical,
                                                 visibleControllerID: "root",
                                                 itemAttached: true,
                                                 geometrySignature: "stable")

        XCTAssertEqual(owner.reconcile(target: .systemVertical,
                                       visibleControllerID: "root",
                                       geometrySignature: "stable",
                                       transitionActive: false),
                       .noOp)
        XCTAssertEqual(owner.reconcile(target: .systemVertical,
                                       visibleControllerID: "root",
                                       geometrySignature: "stable",
                                       transitionActive: false),
                       .noOp)
    }
}
