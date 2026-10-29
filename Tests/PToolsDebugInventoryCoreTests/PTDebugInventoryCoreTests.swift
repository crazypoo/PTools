import XCTest
@testable import PToolsDebugInventoryCore

final class PTDebugInventoryCoreTests: XCTestCase {
    func testInventoryBoundedAndPathsNeverPublished() throws {
        let records = PTDebugInventoryCore.files(maximum: 1)
        XCTAssertLessThanOrEqual(records.count, 1)
        for item in records {
            XCTAssertFalse(item.name.hasPrefix("/"))
            XCTAssertFalse(item.identity.contains("/private/"))
            let value = try JSONEncoder().encode(item)
            let recovered = try JSONDecoder().decode(PTDebugInventoryRecord.self, from: value)
            XCTAssertEqual(recovered, item)
        }
    }

    func testDefaultsAreMetadataOnlyAndSensitiveKeysNeverExposed() {
        let sampleKey = "PTStudio.test.secretSessionToken"
        let safeKey = "PTStudio.test.publicSetting"
        UserDefaults.standard.set("test", forKey: sampleKey)
        UserDefaults.standard.set(123, forKey: safeKey)
        defer {
            UserDefaults.standard.removeObject(forKey: sampleKey)
            UserDefaults.standard.removeObject(forKey: safeKey)
        }
        let records = PTDebugInventoryCore.defaults()
        XCTAssertFalse(records.contains(where: { $0.key == sampleKey }))
        // Values are never part of the inventory contract.
        XCTAssertTrue(records.allSatisfy { !$0.type.contains("123") })
        XCTAssertLessThanOrEqual(records.count, 400)
    }
}
