import XCTest
@testable import PooToolsPhotoPicker

@MainActor
final class PTMediaSelectionProjectionTests: XCTestCase {
    func testProjectionClearsUnselectedOrder() {
        let projection = PTMediaSelectionProjection(identifier: "asset-b", selectedIndexMap: [:])

        XCTAssertFalse(projection.isSelected)
        XCTAssertNil(projection.order)
    }

    func testProjectionUsesStoreOrderPlusOne() {
        let projection = PTMediaSelectionProjection(identifier: "asset-b",
                                                     selectedIndexMap: ["asset-a": 0, "asset-b": 1])

        XCTAssertTrue(projection.isSelected)
        XCTAssertEqual(projection.order, 2)
    }
}
