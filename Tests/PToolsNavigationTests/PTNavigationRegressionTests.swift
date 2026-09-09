import UIKit
import XCTest
@testable import ptools

@MainActor
final class PTNavigationRegressionTests: XCTestCase {
    private func makeNavigationController() -> PTBaseNavControl {
        PTBaseNavControl(rootViewController: UIViewController())
    }

    func testPushAndPopPreserveNavigationStack() {
        let navigationController = makeNavigationController()
        let detail = UIViewController()

        navigationController.pushViewController(detail, animated: false)

        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssertTrue(navigationController.topViewController === detail)

        let popped = navigationController.popViewController(animated: false)

        XCTAssertTrue(popped === detail)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    func testMultipleNavigationControllersKeepIndependentStacks() {
        let first = makeNavigationController()
        let second = makeNavigationController()
        let firstDetail = UIViewController()
        let secondDetail = UIViewController()

        first.pushViewController(firstDetail, animated: false)
        second.pushViewController(secondDetail, animated: false)

        XCTAssertTrue(first.topViewController === firstDetail)
        XCTAssertTrue(second.topViewController === secondDetail)
        XCTAssertFalse(first === second)
    }

    func testNavigationControllerExposesInteractivePopGestureAfterPush() {
        let navigationController = makeNavigationController()
        navigationController.pushViewController(UIViewController(), animated: false)

        XCTAssertNotNil(navigationController.interactivePopGestureRecognizer)
    }

    func testHostDelegateCanRemainAttachedToNavigationController() {
        final class HostDelegate: NSObject, UINavigationControllerDelegate {}

        let navigationController = makeNavigationController()
        let hostDelegate = HostDelegate()
        navigationController.delegate = hostDelegate

        XCTAssertTrue(navigationController.delegate === hostDelegate)
    }

    func testPushedControllerCanControlTabBarVisibility() {
        let navigationController = makeNavigationController()
        let detail = UIViewController()
        detail.hidesBottomBarWhenPushed = true

        navigationController.pushViewController(detail, animated: false)

        XCTAssertTrue(detail.hidesBottomBarWhenPushed)
    }
}
