import Foundation
import XCTest
@testable import PToolsStudioStorageRuntime
import PToolsStudioProtocolCore

@MainActor
final class PToolsStudioStorageRuntimeTests: XCTestCase {
    func testDirectoryTraversalIsDeniedAndDefaultsRequireAllowlist() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let defaults = UserDefaults(suiteName: "ptools.studio.test.\(UUID().uuidString)")!
        defaults.set("allowed", forKey: "example")
        defaults.set("secret", forKey: "private")
        let inspector = PTStudioStorageInspector(
            allowedRoot: root, allowedDefaultKeys: ["example"], defaults: defaults)
        let id = UUID()
        XCTAssertFalse(inspector.handle(.init(sessionID: id, domain: .storage,
                                               operation: "list", arguments: ["path": "../"])).success)
        let reply = inspector.handle(.init(sessionID: id, domain: .defaults, operation: "list"))
        XCTAssertEqual(reply.entries.map(\.name), ["example"])
        let forbiddenWrite = PTStudioDiagnosticCommand(
            sessionID: id, domain: .defaults, operation: "set", targetID: "example",
            arguments: ["type": "string", "value": "changed"])
        XCTAssertFalse(inspector.handle(forbiddenWrite).success)
        XCTAssertEqual(defaults.string(forKey: "example"), "allowed")
        inspector.permitsDefaultWrites = true
        XCTAssertTrue(inspector.handle(forbiddenWrite).success)
        XCTAssertEqual(defaults.string(forKey: "example"), "changed")
    }
}
