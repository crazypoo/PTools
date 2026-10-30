import Foundation
import XCTest
@testable import PToolsDebugNetworkCore

final class PTDebugNetworkCoreTests: XCTestCase {
    private func record(_ id: UUID = UUID(), status: Int? = nil) -> PTNetworkCaptureRecord {
        let now = Date()
        return PTNetworkCaptureRecord(
            id: id,
            request: PTNetworkRequestSnapshot(
                url: URL(string: "https://example.org/path?token=secret")!,
                method: "GET",
                headers: ["Authorization": "Bearer secret"],
                startedAt: now),
            response: status.map { PTNetworkCaptureResponseSnapshot(statusCode: $0) },
            timing: PTNetworkTiming(startedAt: now),
            source: .urlProtocol,
            completion: status == nil ? nil : .completed,
            phase: status == nil ? .created : .finalized)
    }

    func testCaptureStoreDeduplicatesAndPreservesSequence() async {
        let store = PTNetworkCaptureStore(maxRecords: 3)
        let id = UUID()
        let first = await store.insert(record(id))
        let duplicate = await store.insert(record(id))
        XCTAssertEqual(first.id, duplicate.id)
        XCTAssertEqual(first.sequence, duplicate.sequence)
        XCTAssertEqual(await store.summaries().count, 1)
        _ = await store.insert(record())
        XCTAssertEqual(await store.summaries().count, 2)
    }

    func testExactlyOnceFinalizeAndClear() async {
        let store = PTNetworkCaptureStore()
        let current = await store.insert(record())
        let timing = PTNetworkTiming(startedAt: current.timing.startedAt, endedAt: Date())
        let success = await store.finalize(
            id: current.id, response: PTNetworkCaptureResponseSnapshot(statusCode: 200),
            timing: timing, metrics: nil, error: nil, completion: .completed)
        let repeated = await store.finalize(
            id: current.id, response: PTNetworkCaptureResponseSnapshot(statusCode: 500),
            timing: timing, metrics: nil, error: nil, completion: .failed)
        XCTAssertTrue(success)
        XCTAssertFalse(repeated)
        let response = await store.record(id: current.id)?.response
        XCTAssertEqual(response?.statusCode, 200)
        await store.clear()
        let empty = await store.summaries()
        XCTAssertTrue(empty.isEmpty)
    }

    func testPrivacyRedactionOccursBeforeConsumerProjection() {
        let secret = record()
        let sanitized = secret.redacted()
        XCTAssertNil(sanitized.request.headers["Authorization"])
        XCTAssertFalse(sanitized.request.url.absoluteString.contains("secret"))
    }
}
