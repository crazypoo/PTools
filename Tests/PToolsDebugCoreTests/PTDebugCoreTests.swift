import Dispatch
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
    @MainActor
    func testConsoleEventObserversAreTokenScoped() {
        let center = PTDebugEventCenter.shared
        var seen: [String] = []
        let token = center.addObserver { seen.append($0.name) }
        center.publish(PTDebugEvent(name: "ping", source: "unit"))
        center.removeObserver(token)
        center.publish(PTDebugEvent(name: "ignored", source: "unit"))
        XCTAssertEqual(seen, ["ping"])
    }

    func testMetricsTimelineGeometryRemainsBoundedAndPositionStable() {
        let geometry = PTDebugTimelineGeometry(
            viewportWidth: 300, duration: 10, zoom: 1,
            visibleTrackCount: 3)
        XCTAssertEqual(geometry.contentWidth, 1_240)
        XCTAssertEqual(geometry.contentHeight, 144)
        XCTAssertEqual(PTDebugTimelineGeometry.xPosition(
            elapsed: 5, contentWidth: 1_240, duration: 10), 620)
        let zero = PTDebugTimelineGeometry(
            viewportWidth: 300, duration: 0, zoom: .nan,
            visibleTrackCount: 0)
        XCTAssertEqual(zero.contentWidth, 300)
        XCTAssertEqual(zero.contentHeight, 48)
    }

    // PR42: a non-gating, reproducible 100/500/1000 ring/geometry
    // microbenchmark. It is not an on-device FPS or Mac Studio UI result.
    func testDebugMetricsBoundedWorkloadMatrix() {
        for capacity in [100, 500, 1_000] {
            var elapsedMS: [Double] = []
            for _ in 0..<5 {
                let start = DispatchTime.now().uptimeNanoseconds
                var ring = PTDebugRingBuffer<Int>(capacity: capacity)
                for value in 0..<(capacity + 64) { ring.append(value) }
                let geometry = PTDebugTimelineGeometry(
                    viewportWidth: 320,
                    duration: TimeInterval(capacity) / 10,
                    zoom: 1,
                    visibleTrackCount: 3)
                XCTAssertEqual(ring.count, capacity)
                XCTAssertEqual(ring.latestValue, capacity + 63)
                XCTAssertEqual(ring.orderedValues.first, 64)
                XCTAssertEqual(geometry.contentHeight, 144)
                let end = DispatchTime.now().uptimeNanoseconds
                elapsedMS.append(Double(end - start) / 1_000_000)
            }
            let ordered = elapsedMS.sorted()
            print("PR42_METRICS_CORE capacity=\(capacity) medianMS=\(ordered[2]) p95MS=\(ordered[4])")
        }
    }

}
