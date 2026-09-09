import XCTest
@testable import ptools

final class PTCoreContractTests: XCTestCase {
    func testProgressSnapshotKeepsImmutableValues() {
        let snapshot = PTProgressSnapshot(completedUnitCount: 5,
                                          totalUnitCount: 10,
                                          fractionCompleted: 0.5)

        XCTAssertEqual(snapshot.completedUnitCount, 5)
        XCTAssertEqual(snapshot.totalUnitCount, 10)
        XCTAssertEqual(snapshot.fractionCompleted, 0.5)
        XCTAssertEqual(snapshot, PTProgressSnapshot(completedUnitCount: 5,
                                                    totalUnitCount: 10,
                                                    fractionCompleted: 0.5))
    }

    func testResponseMetadataKeepsOnlySendableValues() {
        let metadata = PTResponseMetadata(statusCode: 200,
                                          headers: ["Content-Type": "application/json"],
                                          isDegraded: false,
                                          isCancelled: false)

        XCTAssertEqual(metadata.statusCode, 200)
        XCTAssertEqual(metadata.headers["Content-Type"], "application/json")
        XCTAssertFalse(metadata.isDegraded)
        XCTAssertFalse(metadata.isCancelled)
    }
}
