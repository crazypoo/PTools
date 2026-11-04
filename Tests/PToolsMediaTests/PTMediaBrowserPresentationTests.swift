import UIKit
import XCTest
@testable import ptools
@testable import PooToolsMediaViewer

@MainActor
final class PTMediaBrowserPresentationTests: XCTestCase {
    func testRegularPresenterPreservesFullScreenSemantics() {
        let source = UIViewController()
        let context = PTMediaBrowserController.mediaPresentationContext(from: source)

        XCTAssertTrue(context.presenter === source)
        XCTAssertFalse(context.isSheetHosted)
    }

    func testSheetPresenterUsesVisibleChildWithoutDismissingSheet() {
        let child = UIViewController()
        let navigationController = UINavigationController(rootViewController: child)
        let sheet = PTSheetViewController(controller: navigationController, sizes: [.fullscreen])

        let context = PTMediaBrowserController.mediaPresentationContext(from: sheet)

        XCTAssertTrue(context.presenter === child)
        XCTAssertTrue(context.isSheetHosted)
        XCTAssertNil(sheet.presentedViewController)
    }

    func testControllerInsideSheetIsDetectedAfterContainment() {
        let child = UIViewController()
        let sheet = PTSheetViewController(controller: child, sizes: [.fullscreen])
        sheet.loadViewIfNeeded()

        let context = PTMediaBrowserController.mediaPresentationContext(from: child)

        XCTAssertTrue(context.presenter === child)
        XCTAssertTrue(context.isSheetHosted)
    }

    func testMediaBrowserOwnsNavigationAndRetainsCompletionAPI() {
        let browser = PTMediaBrowserController(mediaData: [])
        XCTAssertFalse(browser.allowControlNavBar())

        // Compile-time compatibility of the completion-bearing instance method.
        let show = browser.mediasShow(completion:)
        _ = show
    }
}
