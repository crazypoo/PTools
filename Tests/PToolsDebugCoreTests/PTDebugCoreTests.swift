import XCTest
import PToolsDebugCore
import PToolsDebugMetricsCore

final class PTDebugCoreTests: XCTestCase {
    func testSceneOwnersOnlyActivateAndDeactivateAtFirstAndLastOwner() {
        var ledger = PTDebugSessionOwnerLedger()
        XCTAssertEqual(ledger.acquire(""), .unchanged)
        XCTAssertEqual(ledger.acquire("scene-A"), .activate)
        XCTAssertEqual(ledger.acquire("scene-A"), .unchanged)
        XCTAssertEqual(ledger.acquire("scene-B"), .retained)
        XCTAssertEqual(ledger.count, 2)
        XCTAssertEqual(ledger.release("scene-A"), .retained)
        XCTAssertEqual(ledger.release("scene-B"), .deactivate)
        XCTAssertEqual(ledger.release("scene-B"), .unchanged)
        XCTAssertTrue(ledger.isEmpty)
    }

    func testGlobalStopClearsAllOwners() {
        var ledger = PTDebugSessionOwnerLedger()
        _ = ledger.acquire("a")
        _ = ledger.acquire("b")
        XCTAssertTrue(ledger.reset())
        XCTAssertFalse(ledger.reset())
        XCTAssertEqual(ledger.acquire("c"), .activate)
    }

    func testRingBufferRolloverAndLatestValue() {
        var ring = PTDebugRingBuffer<Int>(capacity: 3)
        XCTAssertNil(ring.latestValue)
        XCTAssertFalse(ring.append(1))
        XCTAssertFalse(ring.append(2))
        XCTAssertFalse(ring.append(3))
        XCTAssertTrue(ring.append(4))
        XCTAssertTrue(ring.append(5))
        XCTAssertEqual(ring.count, 3)
        XCTAssertEqual(ring.latestValue, 5)
        XCTAssertEqual(ring.orderedValues, [3, 4, 5])
    }

    func testRingBufferOneElementCapacityIsBounded() {
        var ring = PTDebugRingBuffer<Int>(capacity: 0)
        XCTAssertFalse(ring.append(1))
        XCTAssertTrue(ring.append(2))
        XCTAssertEqual(ring.orderedValues, [2])
        XCTAssertEqual(ring.latestValue, 2)
    }
}
