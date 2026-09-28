// English: Regression coverage for the 5.56.2 Form, Documents, Feedback and button-loading closure.
// Español: Cobertura de regresión para el cierre 5.56.2 de Form, Documents, Feedback y carga de botones.
// 中文：覆盖 5.56.2 Form、Documents、Feedback 和按钮 loading 收口能力的回归测试。

import XCTest
import UIKit
import UniformTypeIdentifiers
@testable import ptools
@testable import PToolsDocuments
@testable import PToolsForm

@MainActor
final class PTFormDocumentsFeedbackTests: XCTestCase {
    func testFormRegistryUsesCanonicalControls() {
        let registry = PTFormFieldRendererRegistry()
        let toggle = PTFormField(id: "toggle", kind: .toggle, title: "Toggle", value: .boolean(true))
        let toggleView = registry.renderer(for: .toggle).makeView(for: toggle) { _ in }
        XCTAssertTrue(toggleView is PTSwitch)

        let action = PTFormField(id: "action", kind: .custom, title: "Submit")
        let actionView = PTFormActionButtonRenderer().makeView(for: action) { _ in }
        XCTAssertTrue(actionView is PTActionLayoutButton)
    }

    func testButtonLoadingStateIsSharedWithoutChangingInheritance() {
        let baseButton = PTBaseButton(frame: .zero)
        baseButton.startLoading()
        XCTAssertTrue(baseButton.isLoading)
        baseButton.stopLoading()
        XCTAssertFalse(baseButton.isLoading)

        let actionButton = PTActionLayoutButton(frame: .zero)
        XCTAssertTrue(type(of: actionButton).isSubclass(of: UIControl.self))
        actionButton.startLoading()
        XCTAssertTrue(actionButton.isLoading)
        actionButton.stopLoading()
        XCTAssertFalse(actionButton.isLoading)
    }

    func testDocumentsPDFBridgeAndShareRequestContracts() {
        let pdfURL = URL(fileURLWithPath: "/tmp/report.PDF")
        let textURL = URL(fileURLWithPath: "/tmp/report.txt")
        XCTAssertTrue(PTDocumentPDFBridge.isPDF(pdfURL))
        XCTAssertFalse(PTDocumentPDFBridge.isPDF(textURL))

        let request = PTDocumentRequest(allowedContentTypes: [.pdf],
                                        allowsMultipleSelection: true,
                                        shouldCopyImportedFiles: true)
        XCTAssertEqual(request.allowedContentTypes, [.pdf])
        XCTAssertTrue(request.allowsMultipleSelection)
        XCTAssertTrue(request.shouldCopyImportedFiles)
    }
}
