import XCTest
@testable import PToolsStudioProtocolCore

final class PTStudioDiagnosticPrivacyTests: XCTestCase {
    func testSensitiveLogValueAndEmailRedaction() {
        let value = PTStudioDiagnosticPrivacy.scrub(
            "Bearer ABCDEF123 password=hunter2 alice@example.com https://example.com/api?token=123")
        XCTAssertFalse(value.contains("ABCDEF123"))
        XCTAssertFalse(value.contains("hunter2"))
        XCTAssertFalse(value.contains("alice@example.com"))
        XCTAssertFalse(value.contains("token=123"))
        XCTAssertTrue(value.contains("example.com/api"))
    }

    func testReplyHasStableIdentityButRemovesSensitiveAttributes() {
        let id = UUID(), sid = UUID()
        let entry = PTStudioDiagnosticEntry(
            id: "node-1", parentID: "root", kind: "UIView", name: "UILabel",
            detail: "Authorization: secret123",
            attributes: ["alpha": "0.5", "api_key": "raw", "note": "token=xyz"])
        let result = PTStudioDiagnosticPrivacy.sanitize(
            PTStudioDiagnosticReply(id: id, sessionID: sid, success: true, entries: [entry]))
        XCTAssertEqual(result.id, id)
        XCTAssertEqual(result.sessionID, sid)
        XCTAssertEqual(result.entries[0].parentID, "root")
        XCTAssertNil(result.entries[0].attributes["api_key"])
        XCTAssertEqual(result.entries[0].attributes["alpha"], "0.5")
        XCTAssertFalse(result.entries[0].detail?.contains("secret123") ?? true)
        XCTAssertFalse(result.entries[0].attributes["note"]?.contains("xyz") ?? true)
    }

    func testEntryLimitAndNoGeneratedCredentials() {
        let values = (0..<1_220).map {
            PTStudioDiagnosticEntry(id: "n\($0)", kind: "UIView", name: "UIView")
        }
        let reply = PTStudioDiagnosticReply(id: UUID(), sessionID: UUID(),
                                            success: true, entries: values)
        XCTAssertEqual(PTStudioDiagnosticPrivacy.sanitize(reply).entries.count, 1_200)
    }
}
