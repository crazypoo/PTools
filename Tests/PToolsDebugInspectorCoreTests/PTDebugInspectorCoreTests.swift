import XCTest
import PToolsStudioProtocolCore
import PToolsDebugInspectorCore

final class PTDebugInspectorCoreTests: XCTestCase {
    func testFingerprintStableAcrossRepeatedEncodesAndPreviewChanges() {
        let node = PTStudioDiagnosticEntry(id: "node", parentID: "window",
            kind: "UIView", name: "UILabel",
            frame: PTStudioRect(x: 10, y: 20, width: 80, height: 30),
            attributes: ["alpha": "1", "hidden": "false"],
            previewBase64: "aGVsbG8=")
        let withoutPreview = PTStudioDiagnosticEntry(
            id: node.id, parentID: node.parentID, kind: node.kind,
            name: node.name, frame: node.frame, attributes: node.attributes)
        let original = PTDebugInspectorSnapshotSignature.fingerprint(entries: [node])
        XCTAssertNotNil(original)
        XCTAssertEqual(original,
            PTDebugInspectorSnapshotSignature.fingerprint(entries: [node]))
        XCTAssertEqual(original,
            PTDebugInspectorSnapshotSignature.fingerprint(entries: [withoutPreview]))
    }

    func testPropertyChangesInvalidateFingerprint() {
        let before = PTStudioDiagnosticEntry(id: "node", kind: "UIView",
            name: "UIView", attributes: ["alpha": "1.0"])
        let after = PTStudioDiagnosticEntry(id: "node", kind: "UIView",
            name: "UIView", attributes: ["alpha": "0.5"])
        XCTAssertNotEqual(
            PTDebugInspectorSnapshotSignature.fingerprint(entries: [before]),
            PTDebugInspectorSnapshotSignature.fingerprint(entries: [after]))
    }
}
