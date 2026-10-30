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
    func testReadOnlyConstraintMetadataChangesFingerprintWithoutChangingWireShape() throws {
        let id = "view-123"
        let oldEntry = PTStudioDiagnosticEntry(
            id: id, kind: "UIView", name: "UILabel",
            frame: .init(x: 10, y: 20, width: 90, height: 30),
            attributes: ["ownActiveConstraints": "0",
                         "translatesAutoresizingMaskIntoConstraints": "false"])
        var changed = oldEntry
        changed.attributes["ownActiveConstraints"] = "2"
        let before = PTDebugInspectorSnapshotSignature.fingerprint(entries: [oldEntry])
        let after = PTDebugInspectorSnapshotSignature.fingerprint(entries: [changed])
        XCTAssertNotEqual(before, after)
        let data = try JSONEncoder().encode(changed)
        let decoded = try JSONDecoder().decode(PTStudioDiagnosticEntry.self, from: data)
        XCTAssertEqual(decoded.id, id)
        XCTAssertEqual(decoded.attributes["ownActiveConstraints"], "2")
    }

}
