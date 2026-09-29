import UIKit
import XCTest
@testable import PooToolsPagingControl

@MainActor
private final class PTPagingFactoryState {
    private(set) var counts: [String: Int] = [:]

    func record(_ id: String) {
        counts[id, default: 0] += 1
    }

    func count(for id: String) -> Int {
        counts[id, default: 0]
    }
}

@MainActor
private final class PTPagingTestViewController: UIViewController {}

@MainActor
private final class PTPagingOtherViewController: UIViewController {}

@MainActor
final class PTPagingTests: XCTestCase {
    private let pageIDs = ["a", "b", "c", "d", "e"]

    private func makeContainer(policy: PTPageCachePolicy = .discardOffscreen) -> PTPageContainer {
        let container = PTPageContainer(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        container.cachePolicy = policy
        return container
    }

    private func makeViewPages(_ ids: [String], state: PTPagingFactoryState) -> [PTPageDescriptor] {
        ids.map { id in
            PTPageDescriptor(id: id) {
                state.record(id)
                return UIView()
            }
        }
    }

    private func makeControllerPages(_ ids: [String], state: PTPagingFactoryState) -> [PTPageDescriptor] {
        ids.map { id in
            PTPageDescriptor(id: id, viewController: {
                state.record(id)
                return PTPagingTestViewController()
            })
        }
    }

    func testLoadedPageIDsFollowDescriptorOrder() {
        let state = PTPagingFactoryState()
        let container = makeContainer(policy: .keepAllLoaded)
        container.apply(pages: makeViewPages(pageIDs, state: state), selectedID: "c")

        XCTAssertEqual(container.loadedPageIDs, pageIDs.map { AnyHashable($0) })
    }

    func testQueriesDoNotCreateUnloadedPagesOrChangeLifecycle() {
        let state = PTPagingFactoryState()
        let container = makeContainer()
        var lifecycleCount = 0
        container.onLifecycle = { _ , _ in lifecycleCount += 1 }
        container.apply(pages: makeViewPages(pageIDs, state: state), selectedID: "a")
        let beforeQueryLifecycleCount = lifecycleCount
        let beforeSelection = container.selectedID

        XCTAssertFalse(container.isPageLoaded(id: "b"))
        XCTAssertNil(container.loadedPage(for: "b"))
        XCTAssertNil(container.loadedPage(for: "b", as: PTViewPage.self))
        XCTAssertNil(container.loadedViewController(for: "b"))
        XCTAssertEqual(state.count(for: "b"), 0)
        XCTAssertEqual(container.selectedID, beforeSelection)
        XCTAssertEqual(lifecycleCount, beforeQueryLifecycleCount)
    }

    func testControllerQueriesReturnTheSameInstanceAndSupportTypedAccess() {
        let state = PTPagingFactoryState()
        let container = makeContainer()
        container.apply(pages: makeControllerPages(["a"], state: state), selectedID: "a")

        let page = container.loadedPage(for: "a", as: PTViewControllerPage.self)
        let controller = container.loadedViewController(for: "a")

        XCTAssertNotNil(page)
        XCTAssertTrue(controller is PTPagingTestViewController)
        XCTAssertIdentical(container.loadedViewController(for: "a", as: PTPagingTestViewController.self), controller)
        XCTAssertIdentical(container.currentViewController(as: PTPagingTestViewController.self), controller)
        XCTAssertEqual(container.loadedViewControllers.count, 1)
        XCTAssertEqual(container.loadedViewControllers(of: PTPagingTestViewController.self).count, 1)
    }

    func testWrongControllerTypeReturnsNil() {
        let state = PTPagingFactoryState()
        let container = makeContainer()
        container.apply(pages: makeControllerPages(["a"], state: state), selectedID: "a")

        XCTAssertNil(container.loadedViewController(for: "a", as: PTPagingOtherViewController.self))
    }

    func testViewBackedPageHasNoViewController() {
        let container = makeContainer()
        container.apply(pages: [PTPageDescriptor(id: "view") { UIView() }], selectedID: "view")

        XCTAssertNotNil(container.loadedPage(for: "view"))
        XCTAssertNil(container.loadedViewController(for: "view"))
    }

    func testDiscardOffscreenUnloadsThePreviousPage() {
        let state = PTPagingFactoryState()
        let container = makeContainer()
        let pages = makeViewPages(["a", "b"], state: state)
        container.apply(pages: pages, selectedID: "a")
        container.select(id: "b", animated: false)

        XCTAssertFalse(container.isPageLoaded(id: "a"))
        XCTAssertNil(container.loadedPage(for: "a"))
        XCTAssertTrue(container.isPageLoaded(id: "b"))
    }

    func testAdjacentCacheKeepsOnlyTheRequestedRadius() {
        let state = PTPagingFactoryState()
        let container = makeContainer(policy: .adjacent(radius: 1))
        container.apply(pages: makeViewPages(pageIDs, state: state), selectedID: "c")

        XCTAssertEqual(container.loadedPageIDs, ["b", "c", "d"].map { AnyHashable($0) })
    }

    func testKeepAllCacheLoadsEveryDescriptor() {
        let state = PTPagingFactoryState()
        let container = makeContainer(policy: .keepAllLoaded)
        container.apply(pages: makeViewPages(pageIDs, state: state), selectedID: "c")

        XCTAssertEqual(container.loadedPageIDs, pageIDs.map { AnyHashable($0) })
    }

    func testLimitCacheKeepsTheSelectedPageAndTheConfiguredCount() {
        let state = PTPagingFactoryState()
        let container = makeContainer(policy: .limit(2))
        container.apply(pages: makeViewPages(pageIDs, state: state), selectedID: "c")

        XCTAssertEqual(container.loadedPageIDs.count, 2)
        XCTAssertTrue(container.isPageLoaded(id: "c"))
    }

    func testApplyingDescriptorsRemovesDeletedPageFromQueries() {
        let state = PTPagingFactoryState()
        let container = makeContainer(policy: .keepAllLoaded)
        let pages = makeViewPages(["a", "b"], state: state)
        var didUnloadIDs: [AnyHashable] = []
        container.onLifecycle = { id, lifecycle in
            if case .didUnload = lifecycle { didUnloadIDs.append(id) }
        }
        container.apply(pages: pages, selectedID: "a")
        container.apply(pages: [pages[0]], selectedID: "a")

        XCTAssertNil(container.loadedPage(for: "b"))
        XCTAssertFalse(container.isPageLoaded(id: "b"))
        XCTAssertEqual(didUnloadIDs, [AnyHashable("b")])
    }

    func testQueriesDoNotChangeSelectionOrLifecycle() {
        let state = PTPagingFactoryState()
        let container = makeContainer(policy: .keepAllLoaded)
        var lifecycleCount = 0
        container.onLifecycle = { _ , _ in lifecycleCount += 1 }
        container.apply(pages: makeViewPages(pageIDs, state: state), selectedID: "c")
        let selectedID = container.selectedID
        let countBeforeQueries = lifecycleCount

        _ = container.loadedPageIDs
        _ = container.isPageLoaded(id: "a")
        _ = container.loadedPage(for: "a")
        _ = container.loadedViewController(for: "a")
        _ = container.loadedViewControllers
        _ = container.currentViewController

        XCTAssertEqual(container.selectedID, selectedID)
        XCTAssertEqual(lifecycleCount, countBeforeQueries)
    }
}
