//
//  PTNavigationContentRowResolverTests.swift
//  PTools
//
// English: Verify host-local navigation rows without relying on a device-specific bar height.
// Español: Verifica las filas locales de navegación sin depender de una altura específica del dispositivo.
// 中文：验证宿主局部导航内容行，不依赖某个设备固定的导航栏高度。
//

import CoreGraphics
import XCTest
@testable import ptools

@MainActor
final class PTNavigationContentRowResolverTests: XCTestCase {
    func testCompactRowUsesTheMeasuredHostHeight() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 50),
            hostSafeRect: CGRect(x: 0, y: 0, width: 430, height: 50),
            observedSystemRowRect: CGRect(x: 0, y: 0, width: 430, height: 50),
            fallbackRowRect: CGRect(x: 0, y: 0, width: 430, height: 44),
            evidence: .observed
        )

        let result = try XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect, input.observedSystemRowRect)
        XCTAssertEqual(result.evidence, .observed)
    }

    func testAlreadyPositionedHostDoesNotAddASecondTopInset() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 390, height: 44),
            hostSafeRect: CGRect(x: 0, y: 0, width: 390, height: 44),
            observedSystemRowRect: CGRect(x: 0, y: 0, width: 390, height: 44),
            evidence: .observed
        )

        let result = try XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect.minY, 0, accuracy: 0.001)
        XCTAssertEqual(result.contentRect.midY, 22, accuracy: 0.001)
    }

    func testSafeAreaOverlapStaysInsideHostBounds() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 56),
            hostSafeRect: CGRect(x: 0, y: 8, width: 430, height: 40),
            fallbackRowRect: CGRect(x: 0, y: 8, width: 430, height: 40),
            evidence: .fallback
        )

        let result = try XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect, input.hostSafeRect)
        XCTAssertTrue(input.hostBounds.contains(result.contentRect))
    }

    func testLargeTitleUsesTheCompactRowInsteadOfTheWholeBar() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 96),
            hostSafeRect: CGRect(x: 0, y: 0, width: 430, height: 96),
            fallbackRowRect: CGRect(x: 0, y: 0, width: 430, height: 96),
            evidence: .fallback,
            isLargeTitleExpanded: true,
            compactRowHeight: 50
        )

        let result = try XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect.height, 50, accuracy: 0.001)
        XCTAssertEqual(result.contentRect.midY, 25, accuracy: 0.001)
        XCTAssertLessThan(result.contentRect.maxY, input.hostBounds.maxY)
    }

    func testInvalidHostDoesNotProduceAZeroFrameToCache() {
        let input = PTNavigationContentRowInput(
            hostBounds: .zero,
            hostSafeRect: .zero,
            evidence: .deferred
        )

        XCTAssertNil(PTNavigationContentRowResolver.resolve(input))
    }

    // English: A safe-area fallback must never be reported as an observed UIKit row.
    // Español: Un fallback del área segura nunca debe reportarse como una fila observada de UIKit.
    // 中文：安全区域回退值不能伪装成 UIKit 实测内容行。
    func testFallbackEvidenceDoesNotUseAnUnverifiedSystemRect() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 60),
            hostSafeRect: CGRect(x: 0, y: 8, width: 430, height: 44),
            fallbackRowRect: CGRect(x: 0, y: 8, width: 430, height: 44),
            evidence: .fallback
        )

        let result = try XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect, CGRect(x: 0, y: 8, width: 430, height: 44))
        XCTAssertEqual(result.evidence, .fallback)
    }

    // English: Defer while UIKit reports a zero or transitional geometry instead of caching it.
    // Español: Difiere cuando UIKit informa una geometría cero o transitoria en vez de guardarla.
    // 中文：UIKit 返回零尺寸或转场中的几何时延后处理，不缓存无效结果。
    func testDeferredEvidenceReturnsNoRow() {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 60),
            hostSafeRect: CGRect(x: 0, y: 0, width: 430, height: 60),
            evidence: .deferred
        )

        XCTAssertNil(PTNavigationContentRowResolver.resolve(input))
    }

    // English: Preserve asymmetric horizontal safe areas in the host-local fallback.
    // Español: Conserva las áreas seguras horizontales asimétricas en el fallback local del host.
    // 中文：保留宿主局部回退值中的非对称水平安全区。
    func testAsymmetricSafeAreaRemainsAsymmetric() throws {
        let fallback = CGRect(x: 24, y: 4, width: 390, height: 52)
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 438, height: 60),
            hostSafeRect: fallback,
            fallbackRowRect: fallback,
            evidence: .fallback
        )

        let result = try XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect.minX, 24, accuracy: 0.001)
        XCTAssertEqual(result.contentRect.maxX, 414, accuracy: 0.001)
    }

    // English: Reject an observed row that overlaps the current status-bar exclusion and choose a local fallback.
    // Español: Rechaza una fila observada que invade la exclusión de la barra de estado y usa un fallback local.
    // 中文：拒绝与当前状态栏排斥区重叠的实测内容行，并选择局部安全回退行。
    func testStatusBarOverlapRejectsObservedRow() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 60),
            hostSafeRect: CGRect(x: 0, y: 0, width: 430, height: 60),
            observedSystemRowRect: CGRect(x: 0, y: 0, width: 430, height: 44),
            fallbackRowRect: CGRect(x: 0, y: 0, width: 430, height: 60),
            exclusionRects: [CGRect(x: 0, y: 0, width: 430, height: 24)],
            evidence: .observed
        )

        let result = try XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.evidence, .fallback)
        XCTAssertGreaterThanOrEqual(result.contentRect.minY, 24)
        XCTAssertFalse(result.contentRect.intersects(input.exclusionRects[0]))
    }

    // English: A host already below the status bar must not receive a second top offset.
    // Español: Un host que ya está debajo de la barra de estado no debe recibir otro desplazamiento superior.
    // 中文：宿主已经位于状态栏下方时，不应再次增加顶部偏移。
    func testHostBelowStatusBarKeepsObservedRow() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 44),
            hostSafeRect: CGRect(x: 0, y: 0, width: 430, height: 44),
            observedSystemRowRect: CGRect(x: 0, y: 0, width: 430, height: 44),
            exclusionRects: [CGRect(x: 0, y: -24, width: 430, height: 20)],
            evidence: .observed
        )

        let result = try XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.evidence, .observed)
        XCTAssertEqual(result.contentRect.minY, 0, accuracy: 0.001)
    }

    // English: Return no row when an exclusion consumes the complete host instead of caching a misleading frame.
    // Español: Devuelve ninguna fila cuando una exclusión consume todo el host, en vez de guardar un frame engañoso.
    // 中文：排斥区占满宿主时返回空结果，避免缓存误导性的内容行。
    func testInsufficientHostHeightDefersInsteadOfOverlapping() {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 30),
            hostSafeRect: CGRect(x: 0, y: 0, width: 430, height: 30),
            fallbackRowRect: CGRect(x: 0, y: 0, width: 430, height: 30),
            exclusionRects: [CGRect(x: 0, y: 0, width: 430, height: 30)],
            evidence: .fallback
        )

        XCTAssertNil(PTNavigationContentRowResolver.resolve(input))
    }

    // English: Active reserved regions use the same collision path as the status bar.
    // Español: Las regiones reservadas activas usan la misma ruta de colisión que la barra de estado.
    // 中文：激活的 reserved region 与状态栏使用同一套碰撞校验路径。
    func testActiveReservedRegionIsExcluded() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 80),
            hostSafeRect: CGRect(x: 0, y: 0, width: 430, height: 80),
            observedSystemRowRect: CGRect(x: 0, y: 0, width: 430, height: 44),
            fallbackRowRect: CGRect(x: 0, y: 0, width: 430, height: 80),
            exclusionRects: [CGRect(x: 0, y: 0, width: 430, height: 32)],
            evidence: .observed
        )

        let result = try XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.evidence, .fallback)
        XCTAssertGreaterThanOrEqual(result.contentRect.minY, 32)
    }

    func testContainerUsesAHostHeightDifferentFromTheLegacyEstimate() {
        let navigationController = PTBaseNavControl(rootViewController: UIViewController())
        navigationController.loadViewIfNeeded()
        navigationController.navigationBar.frame = CGRect(x: 0, y: 0, width: 430, height: 50)

        PTNavigationBarManager.shared.installIfNeeded(in: navigationController)
        PTNavigationBarManager.shared.refreshGeometry(in: navigationController)
        navigationController.navigationBar.layoutIfNeeded()

        let container = navigationController.navigationBar.subviews
            .compactMap { $0 as? PTNavigationBarContainer }
            .first
        XCTAssertNotNil(container)
        XCTAssertEqual(container?.topBarContainer.bounds.height ?? 0, 50, accuracy: 0.5)
    }

    // English: Verify that a live top inset follows the navigation-bar frame in the target view.
    // Español: Verifica que el inset superior vivo siga el frame de la barra en la vista destino.
    // 中文：验证实时顶部偏移跟随目标 View 中导航栏的实际 frame。
    func testLiveTopInsetUsesTheNavigationBarBottom() {
        let navigationController = PTBaseNavControl(rootViewController: UIViewController())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 430, height: 932))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        let topInset = PTNavigationBarManager.shared.currentNavigationTopInset(
            in: navigationController.view,
            navigationController: navigationController
        )
        let barRect = navigationController.navigationBar.convert(
            navigationController.navigationBar.bounds,
            to: navigationController.view
        )
        XCTAssertEqual(topInset, barRect.maxY, accuracy: 0.5)
        window.isHidden = true
    }

    // English: Verify that the legacy total-height call site adopts a live scene value when one is available.
    // Español: Verifica que el punto de llamada heredado adopte el valor vivo de la escena cuando está disponible.
    // 中文：验证活动场景可用时，旧版总高度调用会自动采用实时值。
    func testLegacyTotalHeightUsesTheLiveSceneValue() {
        let navigationController = PTBaseNavControl(rootViewController: UIViewController())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 430, height: 932))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        PTNavigationBarManager.shared.installIfNeeded(in: navigationController)
        PTNavigationBarManager.shared.refreshGeometry(in: navigationController)
        let expected = PTNavigationBarManager.shared.currentNavigationTopInset(
            in: window,
            navigationController: navigationController
        )

        XCTAssertEqual(CGFloat.kNavBarHeight_Total, expected, accuracy: 0.5)
        window.isHidden = true
    }
}
