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
        let text = PTFormField(id: "text", kind: .text, title: "Text")
        let textView = registry.renderer(for: .text).makeView(for: text) { _ in }
        XCTAssertTrue(textView is UITextField)

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

    func testFormEnginePreservesMultipleSections() async {
        let fields = [
            PTFormField(id: "email", kind: .text, title: "Email"),
            PTFormField(id: "name", kind: .text, title: "Name"),
            PTFormField(id: "unused", kind: .text, title: "Unused")
        ]
        let sections = [
            PTFormSection(id: "account", title: "Account", fieldIDs: ["email"]),
            PTFormSection(id: "profile", title: "Profile", fieldIDs: ["name"])
        ]
        let engine = PTFormEngine(fields: fields, sections: sections)
        let snapshot = await engine.makeSnapshot()

        XCTAssertEqual(snapshot.sections.map { $0.section.id }, ["account", "profile", "__pt_form_implicit_section__"])
        XCTAssertEqual(snapshot.sections.flatMap(\.fields).map(\.id), ["email", "name", "unused"])

        let adapter = PTFormCollectionAdapter()
        let mapped = adapter.makeSections(from: snapshot,
                                          configuration: .grouped,
                                          themeAdapter: PTFormThemeAdapter())
        XCTAssertEqual(mapped.map(\.identifier), ["account", "profile", "__pt_form_implicit_section__"])
        XCTAssertEqual(mapped.flatMap { $0.rows ?? [] }.map(\.diffId), ["email", "name", "unused"])
    }

    func testFormVisibilityDirtyResetAndCrossValidation() async throws {
        let fields = [
            PTFormField(id: "enabled", kind: .toggle, title: "Enabled", value: .boolean(false)),
            PTFormField(id: "detail", kind: .text, title: "Detail",
                        visibility: .equals(field: "enabled", value: .boolean(true))),
            PTFormField(id: "confirm", kind: .text, title: "Confirm", value: .string("one")),
            PTFormField(id: "source", kind: .text, title: "Source", value: .string("two"))
        ]
        let validator = PTFormCrossValidator(fieldIDs: ["confirm", "source"]) { context in
            guard context.value(for: "confirm") == context.value(for: "source") else {
                return [PTFormValidationIssue(fieldID: "confirm", message: "Values differ")]
            }
            return []
        }
        let engine = PTFormEngine(fields: fields, crossValidators: [validator])
        let initialSnapshot = await engine.makeSnapshot()
        XCTAssertEqual(initialSnapshot.fields.map(\.id), ["enabled", "confirm", "source"])

        try await engine.setValue(.boolean(true), for: "enabled")
        let enabledSnapshot = await engine.makeSnapshot()
        XCTAssertEqual(enabledSnapshot.fields.map(\.id), ["enabled", "detail", "confirm", "source"])
        let dirty = await engine.isDirty
        XCTAssertTrue(dirty)

        let invalid = await engine.validateAll()
        XCTAssertEqual(invalid.issues.first?.fieldID, "confirm")
        await engine.reset()
        let resetIsDirty = await engine.isDirty
        XCTAssertFalse(resetIsDirty)
        let resetSnapshot = await engine.makeSnapshot()
        XCTAssertEqual(resetSnapshot.fields.map(\.id), ["enabled", "confirm", "source"])
    }

    func testFormSnapshotLargeRegression() async {
        let fields = (0..<1_000).map { index in
            PTFormField(id: PTFormFieldID(rawValue: "field-\(index)"), kind: .text, title: "Field \(index)")
        }
        let engine = PTFormEngine(fields: fields)
        let snapshot = await engine.makeSnapshot()
        XCTAssertEqual(snapshot.fields.count, 1_000)
        XCTAssertEqual(snapshot.sections.first?.section.id, "__pt_form_implicit_section__")
    }
}
