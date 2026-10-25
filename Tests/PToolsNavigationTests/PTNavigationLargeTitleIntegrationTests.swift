import UIKit
import XCTest
@testable import ptools

@MainActor
final class PTNavigationLargeTitleIntegrationTests: XCTestCase {
    private final class FixtureViewController: PTBaseViewController {
        override func prefersLargeTitle() -> Bool { true }
    }

    // English: Exercise real UIKit push, Large Title collapse/expand and resize geometry in one scene-local fixture.
    // Español: Prueba push de UIKit, colapso/expansión de Large Title y resize en un fixture de una sola escena.
    // 中文：在单 Scene fixture 中串联 UIKit push、大标题收起/展开和尺寸变化，验证真实布局几何。
    func testPushExpandCollapseResizeExpandKeepsNavigationFramesUsable() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let root = FixtureViewController()
        root.title = "Root"
        let navigationController = PTBaseNavControl(rootViewController: root)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        let left = UIButton(type: .system)
        left.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        let right = UIButton(type: .system)
        right.frame = CGRect(x: 0, y: 0, width: 52, height: 44)
        let titleView = IntrinsicIntegrationTitleView(preferredSize: CGSize(width: 120, height: 32))
        root.setLeftButtons(views: [left])
        root.setCustomRightButtons(buttons: [right])
        root.setCustomTitleView(titleView, fillSpace: false)
        PTNavigationBarManager.shared.installIfNeeded(in: navigationController)
        PTNavigationBarManager.shared.refreshGeometry(in: navigationController)
        navigationController.navigationBar.layoutIfNeeded()

        let second = FixtureViewController()
        second.title = "Second"
        let secondRight = UIButton(type: .system)
        secondRight.frame = CGRect(x: 0, y: 0, width: 48, height: 44)
        let secondTitle = IntrinsicIntegrationTitleView(preferredSize: CGSize(width: 140, height: 32))
        second.setCustomRightButtons(buttons: [secondRight])
        second.setCustomTitleView(secondTitle, fillSpace: false)
        navigationController.pushViewController(second, animated: false)
        window.layoutIfNeeded()
        PTNavigationBarManager.shared.refreshGeometry(in: navigationController)

        let container = try XCTUnwrap(navigationController.navigationBar.subviews.compactMap { $0 as? PTNavigationBarContainer }.first)
        container.updateLargeTitle(progress: 0)
        window.layoutIfNeeded()
        assertNavigationFrames(container, host: navigationController.navigationBar,
                               interactiveItems: [secondRight, secondTitle])

        container.updateLargeTitle(progress: 1)
        window.layoutIfNeeded()
        assertNavigationFrames(container, host: navigationController.navigationBar,
                               interactiveItems: [secondRight, secondTitle])

        window.bounds = CGRect(x: 0, y: 0, width: 844, height: 390)
        window.layoutIfNeeded()
        PTNavigationBarManager.shared.refreshGeometry(in: navigationController)
        container.updateLargeTitle(progress: 0)
        window.layoutIfNeeded()
        assertNavigationFrames(container, host: navigationController.navigationBar,
                               interactiveItems: [secondRight, secondTitle])

        XCTAssertTrue(container.leftContainer.isUserInteractionEnabled)
        XCTAssertTrue(container.rightContainer.isUserInteractionEnabled)
        XCTAssertTrue(container.titleContainer.isUserInteractionEnabled)
        window.isHidden = true
    }

    private func assertNavigationFrames(_ container: PTNavigationBarContainer,
                                        host: UINavigationBar,
                                        interactiveItems: [UIView]) {
        let row = container.topBarContainer.bounds
        XCTAssertTrue(row.width.isFinite && row.height.isFinite)
        XCTAssertGreaterThan(row.height, 0)
        for view in [container.leftContainer, container.titleContainer, container.rightContainer] {
            XCTAssertTrue(view.frame.origin.x.isFinite && view.frame.origin.y.isFinite)
            XCTAssertTrue(view.frame.width.isFinite && view.frame.height.isFinite)
            XCTAssertTrue(row.contains(view.frame) || view.isHidden)
        }
        for view in interactiveItems {
            XCTAssertGreaterThan(view.bounds.width, 1)
            XCTAssertGreaterThan(view.bounds.height, 1)
            XCTAssertTrue(view.point(inside: CGPoint(x: view.bounds.midX, y: view.bounds.midY), with: nil))
        }
        XCTAssertTrue(host.bounds.contains(container.frame) || container.frame.intersects(host.bounds))
    }
}

@MainActor
private final class IntrinsicIntegrationTitleView: UIView {
    let preferredSize: CGSize

    init(preferredSize: CGSize) {
        self.preferredSize = preferredSize
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize { preferredSize }
}
