import XCTest
import UIKit
@testable import PToolsInspectorRuntime
import PToolsStudioProtocolCore

@MainActor
final class PToolsStudioInspectorRuntimeTests: XCTestCase {
    func testSnapshotHasStableUUIDAndPrivateTextIsWithheldByDefault() throws {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
        let label = UILabel(frame: CGRect(x: 10, y: 20, width: 180, height: 40))
        label.accessibilityLabel = "private-authentication-code"
        label.accessibilityIdentifier = "user-secret"
        root.addSubview(label)
        let inspector = PTStudioUIKitInspector()
        let first = inspector.capture(roots: [root])
        XCTAssertEqual(first.count, 2)
        XCTAssertTrue(first[1].parentID == first[0].id)
        XCTAssertEqual(first[1].name, "UILabel")
        XCTAssertNil(first[1].detail)
        XCTAssertEqual(first[1].id, inspector.capture(roots: [root])[1].id)
        inspector.permitsAccessibilityMetadata = true
        XCTAssertEqual(inspector.capture(roots: [root])[1].name, "private-authentication-code")
    }

    func testRemoteMutationAlwaysRequiresHostPermission() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let inspector = PTStudioUIKitInspector()
        let id = inspector.capture(roots: [root])[0].id
        let command = PTStudioDiagnosticCommand(
            sessionID: UUID(), domain: .inspector, operation: "setProperty",
            targetID: id, arguments: ["key": "alpha", "value": "0.3"])
        XCTAssertFalse(inspector.handle(command).success)
        XCTAssertEqual(root.alpha, 1)
        inspector.permitsRemoteMutation = true
        XCTAssertTrue(inspector.handle(command).success)
        XCTAssertEqual(root.alpha, 0.3, accuracy: 0.001)
        let revert = PTStudioDiagnosticCommand(
            sessionID: command.sessionID, domain: .inspector, operation: "revert",
            arguments: ["undoID": command.id.uuidString])
        XCTAssertTrue(inspector.handle(revert).success)
        XCTAssertEqual(root.alpha, 1, accuracy: 0.001)
    }
}
