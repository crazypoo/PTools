import XCTest
import PooToolsDEBUG

@MainActor
final class PTInspectorStandaloneCompatibilityTests: XCTestCase {
    func testLegacyDebugImportResolvesInspectorPublicAPI() {
        let entry: Inspector.Type = Inspector.self
        let original = entry.keyCommands
        XCTAssertNotNil(original)
        // API compile test only: do not start UIKit Inspector or swizzle a test runner.
        XCTAssertNotNil(entry.setConfiguration as Any)
        XCTAssertNotNil(entry.present as Any)
    }
}
