import Foundation
import XCTest
import PToolsDebugStorageCore

final class PTDebugStorageCoreTests: XCTestCase {
    func testInventoryBoundsAndUniqueItemIdentifiers() {
        let files = PTDebugFileInventory.list(maximum: 10)
        XCTAssertLessThanOrEqual(files.count, 10)
        XCTAssertEqual(Set(files.map(\.id)).count, files.count)
    }

    func testDefaultsMetadataDoesNotReadValues() {
        let result = PTDebugDefaultsInventory.list(maximum: 10)
        XCTAssertLessThanOrEqual(result.count, 10)
        XCTAssertTrue(result.allSatisfy { !$0.key.isEmpty && !$0.type.isEmpty })
    }
}
