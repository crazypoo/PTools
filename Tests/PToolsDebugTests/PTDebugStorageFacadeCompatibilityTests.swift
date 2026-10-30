import XCTest
import PooToolsDEBUG

@MainActor
final class PTDebugStorageFacadeCompatibilityTests: XCTestCase {
    func testLegacyDebugImportResolvesStorageFacade() {
        let files: [PTDebugInventoryItem] = PTDebugFileInventory.list(maximum: 1)
        let defaults: [PTDebugDefaultMetadata] = PTDebugDefaultsInventory.list(maximum: 1)
        XCTAssertLessThanOrEqual(files.count, 1)
        XCTAssertLessThanOrEqual(defaults.count, 1)
    }
}
