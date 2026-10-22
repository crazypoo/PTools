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
            systemContentRect: CGRect(x: 0, y: 0, width: 430, height: 50)
        )

        let result = XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect, input.systemContentRect)
    }

    func testAlreadyPositionedHostDoesNotAddASecondTopInset() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 390, height: 44),
            hostSafeRect: CGRect(x: 0, y: 0, width: 390, height: 44),
            systemContentRect: CGRect(x: 0, y: 0, width: 390, height: 44)
        )

        let result = XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect.minY, 0, accuracy: 0.001)
        XCTAssertEqual(result.contentRect.midY, 22, accuracy: 0.001)
    }

    func testSafeAreaOverlapStaysInsideHostBounds() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 56),
            hostSafeRect: CGRect(x: 0, y: 8, width: 430, height: 40),
            systemContentRect: nil
        )

        let result = XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect, input.hostSafeRect)
        XCTAssertTrue(input.hostBounds.contains(result.contentRect))
    }

    func testLargeTitleUsesTheCompactRowInsteadOfTheWholeBar() throws {
        let input = PTNavigationContentRowInput(
            hostBounds: CGRect(x: 0, y: 0, width: 430, height: 96),
            hostSafeRect: CGRect(x: 0, y: 0, width: 430, height: 96),
            isLargeTitleExpanded: true,
            compactRowHeight: 50
        )

        let result = XCTUnwrap(PTNavigationContentRowResolver.resolve(input))
        XCTAssertEqual(result.contentRect.height, 50, accuracy: 0.001)
        XCTAssertEqual(result.contentRect.midY, 25, accuracy: 0.001)
        XCTAssertLessThan(result.contentRect.maxY, input.hostBounds.maxY)
    }

    func testInvalidHostDoesNotProduceAZeroFrameToCache() {
        let input = PTNavigationContentRowInput(
            hostBounds: .zero,
            hostSafeRect: .zero,
            systemContentRect: nil
        )

        XCTAssertNil(PTNavigationContentRowResolver.resolve(input))
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
