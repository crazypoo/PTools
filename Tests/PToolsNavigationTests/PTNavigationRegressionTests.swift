import UIKit
import XCTest
@testable import ptools
import PooToolsSplitView

@MainActor
final class PTNavigationRegressionTests: XCTestCase {
    private final class CompactSplitViewController: PTSplitViewController {
        override var traitCollection: UITraitCollection {
            UITraitCollection(horizontalSizeClass: .compact)
        }
    }

    private final class RegularSplitViewController: PTSplitViewController {
        override var traitCollection: UITraitCollection {
            UITraitCollection(horizontalSizeClass: .regular)
        }
    }

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

    func testSplitViewSupportsDoubleAndTripleColumnStyles() {
        let double = PTSplitViewController(configuration: PTSplitConfiguration(style: .doubleColumn))
        let triple = PTSplitViewController(configuration: PTSplitConfiguration(style: .tripleColumn))

        if case .doubleColumn = double.style {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected double-column split style")
        }

        if case .tripleColumn = triple.style {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected triple-column split style")
        }
    }

    func testCompactColumnWrapsOnceAndExposesItsNavigationController() {
        let split = PTSplitViewController(configuration: PTSplitConfiguration(navigationPolicy: .wrapCompact))
        let root = UIViewController()

        split.setCompact(root)

        XCTAssertTrue(split.compactViewController is UINavigationController)
        XCTAssertNotNil(split.navigationController(for: .compact))

        let navigationController = PTBaseNavControl(rootViewController: UIViewController())
        split.setCompact(navigationController)

        XCTAssertTrue(split.compactViewController === navigationController)
    }

    func testAutomaticCompactPresentationPushesIntoCompactStack() {
        let split = CompactSplitViewController(configuration: PTSplitConfiguration(navigationPolicy: .none))
        let compactNavigationController = PTBaseNavControl(rootViewController: UIViewController())
        let secondaryNavigationController = PTBaseNavControl(rootViewController: UIViewController())
        let detail = UIViewController()

        split.setCompact(compactNavigationController)
        split.setSecondary(secondaryNavigationController)
        split.show(detail, target: .automatic, animated: false)

        XCTAssertTrue(split.isCompactPresentation)
        XCTAssertTrue(compactNavigationController.topViewController === detail)
        XCTAssertEqual(secondaryNavigationController.viewControllers.count, 1)
    }

    func testAutomaticRegularPresentationReplacesSecondary() {
        let split = RegularSplitViewController(configuration: PTSplitConfiguration(navigationPolicy: .none))
        let initialDetail = UIViewController()
        let nextDetail = UIViewController()

        split.setSecondary(initialDetail)
        split.show(nextDetail, target: .automatic, animated: false)

        XCTAssertFalse(split.isCompactPresentation)
        XCTAssertTrue(split.secondaryViewController === nextDetail)
    }

    func testExplicitNavigationPushUsesTheActiveVisibleStack() {
        let split = RegularSplitViewController(configuration: PTSplitConfiguration(navigationPolicy: .none))
        let navigationController = PTBaseNavControl(rootViewController: UIViewController())
        let detail = UIViewController()

        split.setSecondary(navigationController)
        split.show(detail, target: .navigationPush, animated: false)

        XCTAssertTrue(split.activeNavigationController === navigationController)
        XCTAssertTrue(navigationController.topViewController === detail)
    }

    func testSplitStateRoundTripIncludesCompactSelection() throws {
        let state = PTSplitState(selectedPrimaryIdentifier: "primary",
                                 selectedSupplementaryIdentifier: "supplementary",
                                 selectedSecondaryIdentifier: "secondary",
                                 selectedCompactIdentifier: "compact",
                                 inspectorVisible: true)

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(PTSplitState.self, from: data)

        XCTAssertEqual(decoded, state)
    }

    func testSplitStateRestoresAllColumnFactoriesWithoutControllerPersistence() {
        let split = RegularSplitViewController(configuration: PTSplitConfiguration(navigationPolicy: .none))
        let primary = UIViewController()
        let supplementary = UIViewController()
        let secondary = UIViewController()
        let compact = UIViewController()
        split.setPrimary(primary)
        split.setSupplementary(supplementary)
        split.setSecondary(secondary)
        split.setCompact(compact)

        let state = split.makeState { controller in
            if controller === primary { return "primary" }
            if controller === supplementary { return "supplementary" }
            if controller === secondary { return "secondary" }
            if controller === compact { return "compact" }
            return nil
        }

        let restored = RegularSplitViewController(configuration: PTSplitConfiguration(navigationPolicy: .none))
        let resolved: [String: UIViewController] = [
            "primary": UIViewController(),
            "supplementary": UIViewController(),
            "secondary": UIViewController(),
            "compact": UIViewController()
        ]
        restored.restore(state: state) { resolved[$0] }

        XCTAssertTrue(restored.primaryViewController === resolved["primary"])
        XCTAssertTrue(restored.supplementaryViewController === resolved["supplementary"])
        XCTAssertTrue(restored.secondaryViewController === resolved["secondary"])
        XCTAssertTrue(restored.compactViewController === resolved["compact"])
    }

    func testRouterAdaptiveContractUsesRegularSecondaryDestination() {
        let split = RegularSplitViewController(configuration: PTSplitConfiguration(navigationPolicy: .none))
        let detail = UIViewController()
        let container: PTAdaptiveNavigationContainer = split

        container.pt_showAdaptive(detail)

        XCTAssertTrue(split.secondaryViewController === detail)
    }
}
