//
//  PTNavigationRendererReconciliationTests.swift
//  PTools
//
// English: Verify renderer ownership decisions without depending on UIKit's private Duo behavior.
// Español: Verifica las decisiones de propiedad sin depender del comportamiento privado de Duo en UIKit.
// 中文：不依赖 UIKit 私有 Duo 行为，验证导航渲染器所有权决策。
//

import XCTest
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
