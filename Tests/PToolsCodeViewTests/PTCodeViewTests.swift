import XCTest
import UIKit
@testable import PooToolsCodeView

@MainActor
final class PTCodeViewTests: XCTestCase {

    func testLegacyZeroIntervalIsSafe() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 3, changeTimes: 0)
        codeView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        codeView.setNeedsDisplay()
        codeView.layoutIfNeeded()
        codeView.changeCode()
    }

    func testLocalRefreshUsesCodeBlockOnly() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 0, changeTimes: 0)
        var codes = [String]()
        var requestedReasons = [PTCodeRefreshReason]()
        codeView.codeBlock = { _, code in codes.append(code) }
        codeView.onRefreshRequested = { _, reason in requestedReasons.append(reason) }

        codeView.requestRefresh()

        XCTAssertEqual(codes.count, 1)
        XCTAssertTrue(requestedReasons.isEmpty)
        XCTAssertEqual(codes.first?.count, 4)
    }

    func testDefaultLocalCharacterTypeIsAlphanumeric() {
        let codeView = PTCodeView(numberOfCodes: 16, numberOfLines: 0, changeTimes: 0)
        XCTAssertEqual(codeView.characterType, .alphanumeric)

        let allowed = Set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        var receivedCodes = [String]()
        codeView.codeBlock = { _, code in receivedCodes.append(code) }

        for _ in 0..<30 {
            codeView.requestRefresh()
        }

        XCTAssertEqual(receivedCodes.count, 30)
        XCTAssertTrue(receivedCodes.allSatisfy { code in
            code.count == 16 && code.allSatisfy { allowed.contains($0) }
        })
    }

    func testNumericLocalCodeContainsOnlyDigits() {
        let codeView = PTCodeView(numberOfCodes: 12, numberOfLines: 0, changeTimes: 0, characterType: .numeric)
        let allowed = Set("0123456789")
        var receivedCodes = [String]()
        codeView.codeBlock = { _, code in receivedCodes.append(code) }

        for _ in 0..<30 {
            codeView.requestRefresh()
        }

        XCTAssertEqual(codeView.characterType, .numeric)
        XCTAssertEqual(receivedCodes.count, 30)
        XCTAssertTrue(receivedCodes.allSatisfy { code in
            code.count == 12 && code.allSatisfy { allowed.contains($0) }
        })
    }

    func testAlphabeticLocalCodeContainsOnlyLetters() {
        let codeView = PTCodeView(numberOfCodes: 12, numberOfLines: 0, changeTimes: 0, characterType: .alphabetic)
        let allowed = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        var receivedCodes = [String]()
        codeView.codeBlock = { _, code in receivedCodes.append(code) }

        for _ in 0..<30 {
            codeView.requestRefresh()
        }

        XCTAssertEqual(receivedCodes.count, 30)
        XCTAssertTrue(receivedCodes.allSatisfy { code in
            code.count == 12 && code.allSatisfy { allowed.contains($0) }
        })
    }

    func testChangingTypeRegeneratesOnlyLocalContent() {
        let codeView = PTCodeView(numberOfCodes: 8, numberOfLines: 0, changeTimes: 0)
        var generatedCodes = [String]()
        var requestedReasons = [PTCodeRefreshReason]()
        codeView.codeBlock = { _, code in generatedCodes.append(code) }
        codeView.onRefreshRequested = { _, reason in requestedReasons.append(reason) }

        codeView.characterType = .numeric
        XCTAssertEqual(generatedCodes.count, 1)
        let allowedDigits = Set("0123456789")
        XCTAssertTrue(generatedCodes[0].allSatisfy { allowedDigits.contains($0) })

        codeView.characterType = .numeric
        XCTAssertEqual(generatedCodes.count, 1)

        codeView.setCode("SERVER-ABC123")
        codeView.characterType = .alphabetic
        XCTAssertEqual(generatedCodes.count, 1)
        codeView.requestRefresh()
        XCTAssertEqual(requestedReasons, [.programmatic])

        codeView.useLocalGeneratedCode()
        XCTAssertEqual(generatedCodes.count, 2)
        let allowedLetters = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        XCTAssertTrue(generatedCodes[1].allSatisfy { allowedLetters.contains($0) })
        XCTAssertEqual(requestedReasons, [.programmatic])
    }

    func testCharacterTypeDoesNotReplaceExternallySuppliedImage() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 0, changeTimes: 0)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 6, height: 6)).image { _ in }
        codeView.setCodeImage(image)
        let imageView = codeView.subviews.compactMap { $0 as? UIImageView }.first

        codeView.characterType = .numeric

        XCTAssertIdentical(imageView?.image, image)
        XCTAssertFalse(imageView?.isHidden ?? true)
    }

    func testExternalTextDoesNotCallbackUntilRefresh() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 2, changeTimes: 0)
        var reasons = [PTCodeRefreshReason]()
        codeView.onRefreshRequested = { _, reason in reasons.append(reason) }

        codeView.setCode("line one\nline two")
        XCTAssertTrue(reasons.isEmpty)

        codeView.requestRefresh()

        XCTAssertEqual(reasons, [.programmatic])
    }

    func testExternalCallbackCanReplaceContentSynchronously() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 0, changeTimes: 0)
        var callbackCount = 0
        codeView.setCode("before")
        codeView.onRefreshRequested = { view, reason in
            XCTAssertEqual(reason, .programmatic)
            callbackCount += 1
            view.setCode("after")
        }

        codeView.requestRefresh()

        XCTAssertEqual(callbackCount, 1)
    }

    func testProgrammaticRefreshIgnoresTapPolicy() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 0, changeTimes: 0)
        var reasons = [PTCodeRefreshReason]()
        codeView.setCode("external")
        codeView.allowsTapToRefresh = false
        codeView.onRefreshRequested = { _, reason in reasons.append(reason) }

        codeView.requestRefresh()

        XCTAssertEqual(reasons, [.programmatic])
    }

    func testImageModeReusesImageViewAndClearsText() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 2, changeTimes: 0)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }

        codeView.setCode("external")
        codeView.setCodeImage(image)

        let imageViews = codeView.subviews.compactMap { $0 as? UIImageView }
        XCTAssertEqual(imageViews.count, 1)
        XCTAssertIdentical(imageViews.first?.image, image)
        XCTAssertFalse(imageViews.first?.isHidden ?? true)

        codeView.setCode("again")
        XCTAssertTrue(imageViews.first?.isHidden ?? false)
        XCTAssertNil(imageViews.first?.image)
    }

    func testImageRefreshAndTapPolicy() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 0, changeTimes: 0)
        var reasons = [PTCodeRefreshReason]()
        codeView.onRefreshRequested = { _, reason in reasons.append(reason) }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.systemRed.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        codeView.setCodeImage(image)

        codeView.touchesEnded([], with: nil)
        codeView.touchesEnded([], with: nil)
        XCTAssertEqual(reasons, [.tap])

        codeView.allowsTapToRefresh = false
        codeView.touchesEnded([], with: nil)
        XCTAssertEqual(reasons, [.tap])
    }

    func testClearContentIsAnEmptyExternalMode() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 2, changeTimes: 0)
        var reasons = [PTCodeRefreshReason]()
        codeView.onRefreshRequested = { _, reason in reasons.append(reason) }

        codeView.clearCodeContent()
        XCTAssertTrue(reasons.isEmpty)
        codeView.requestRefresh()
        XCTAssertEqual(reasons, [.programmatic])
    }

    func testCanSwitchBackToLocalGeneratedMode() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 0, changeTimes: 0)
        var generatedCodes = [String]()
        var externalRefreshes = 0
        codeView.setCode("external")
        codeView.codeBlock = { _, code in generatedCodes.append(code) }
        codeView.onRefreshRequested = { _, _ in externalRefreshes += 1 }

        codeView.useLocalGeneratedCode()

        XCTAssertEqual(generatedCodes.count, 1)
        XCTAssertEqual(generatedCodes.first?.count, 4)
        XCTAssertEqual(externalRefreshes, 0)
    }

    func testTimerRefreshesExternalContentOnAttachedView() async {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let rootViewController = UIViewController()
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 0, changeTimes: 0)
        codeView.setCode("server")
        let expectation = expectation(description: "timer refresh")
        codeView.onRefreshRequested = { _, reason in
            if reason == .timer {
                expectation.fulfill()
            }
        }
        rootViewController.view.addSubview(codeView)
        codeView.frame = rootViewController.view.bounds
        codeView.setRefreshInterval(0.01)

        await fulfillment(of: [expectation], timeout: 1)

        codeView.removeFromSuperview()
        window.isHidden = true
    }

    func testAccessibilityRefreshActionIsExposed() {
        let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 0, changeTimes: 0)

        XCTAssertEqual(codeView.accessibilityCustomActions?.count, 1)
        XCTAssertEqual(codeView.accessibilityCustomActions?.first?.name, "刷新验证码")
    }
}
