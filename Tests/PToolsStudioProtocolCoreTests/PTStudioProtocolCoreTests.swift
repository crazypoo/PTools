import XCTest
@testable import PToolsStudioProtocolCore

final class PTStudioProtocolCoreTests: XCTestCase {
    func testRoundTripPreservesSessionAndHierarchy() throws {
        let session = UUID()
        let command = PTStudioDiagnosticCommand(sessionID: session, domain: .inspector, operation: "snapshot")
        let entry = PTStudioDiagnosticEntry(id: "node-1", kind: "UIView",
                                            name: "Root", frame: .init(x: 1, y: 2, width: 3, height: 4))
        let reply = PTStudioDiagnosticReply(id: command.id, sessionID: session, success: true, entries: [entry])
        XCTAssertEqual(try JSONDecoder().decode(PTStudioDiagnosticCommand.self,
                                               from: JSONEncoder().encode(command)), command)
        XCTAssertEqual(try JSONDecoder().decode(PTStudioDiagnosticReply.self,
                                               from: JSONEncoder().encode(reply)), reply)
    }
}
