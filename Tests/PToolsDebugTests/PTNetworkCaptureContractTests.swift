import XCTest
@testable import PooToolsDEBUG

final class PTNetworkCaptureContractTests: XCTestCase {
    func testBodyCaptureIsBoundedAndPreservesTotalSize() {
        let policy = PTNetworkBodyCapturePolicy(memoryPreviewLimit: 4,
                                                fileThreshold: 8,
                                                absoluteCaptureLimit: 8,
                                                totalStoreMemoryBudget: 16)
        let body = PTNetworkBodyCapture.make(data: Data(repeating: 1, count: 10),
                                             policy: policy)
        XCTAssertEqual(body.totalBytes, 10)
        XCTAssertEqual(body.previewData?.count, 4)
    }

    func testRedactionProtectsHeaderQueryAndJSON() {
        let policy = PTNetworkPrivacyPolicy.default
        let url = URL(string: "https://example.com/items?token=secret&visible=yes")!
        let request = PTNetworkRequestSnapshot(url: url,
                                                headers: ["Authorization": "Bearer secret", "Content-Type": "application/json"],
                                                body: .complete(data: Data(#"{"password":"secret","ok":true}"#.utf8), totalBytes: 31))
        let record = PTNetworkCaptureRecord(request: request, source: .importedHAR)
        let redacted = record.redacted(using: policy)
        XCTAssertFalse(redacted.request.url.absoluteString.contains("secret"))
        XCTAssertEqual(redacted.request.headers["Authorization"], policy.replacement)
        XCTAssertFalse(String(data: redacted.request.body.previewData ?? Data(), encoding: .utf8)?.contains("secret") == true)
    }

    func testStoreSequencesAndFinalizesOnce() async {
        let store = PTNetworkCaptureStore(maxRecords: 10, bodyMemoryBudget: 1024, diskBudget: 1024)
        let first = PTNetworkCaptureRecord(request: PTNetworkRequestSnapshot(url: URL(string: "https://example.com/1")!), source: .urlProtocol)
        let inserted = await store.insert(first)
        XCTAssertEqual(inserted.sequence, 0)
        let didFinalize = await store.finalize(id: inserted.id,
                                               response: nil,
                                               timing: PTNetworkTiming(startedAt: inserted.timing.startedAt, endedAt: .now),
                                               metrics: nil,
                                               error: nil,
                                               completion: .completed)
        XCTAssertTrue(didFinalize)
        let secondFinalize = await store.finalize(id: inserted.id,
                                                  response: nil,
                                                  timing: inserted.timing,
                                                  metrics: nil,
                                                  error: nil,
                                                  completion: .completed)
        XCTAssertFalse(secondFinalize)
    }

    func testFilterMatchesFailureAndHost() {
        let request = PTNetworkRequestSnapshot(url: URL(string: "https://example.com/error")!, method: "GET")
        let record = PTNetworkCaptureRecord(request: request,
                                            error: PTNetworkCaptureError(domain: "test", code: 1, description: "failed"),
                                            source: .urlProtocol,
                                            completion: .failed,
                                            phase: .finalized)
        let filter = PTNetworkCaptureFilter(host: "example.com", onlyFailures: true)
        XCTAssertTrue(filter.matches(PTNetworkCaptureSummary(record: record)))
    }

    func testRegressionMatrixCoversGovernanceScenarios() {
        XCTAssertEqual(Set(PTNetworkRegressionMatrix.capture), Set(PTNetworkRegressionScenario.allCases))
        XCTAssertEqual(Set(PTNetworkRegressionMatrix.bodyAndStore), Set(PTNetworkBodyStoreScenario.allCases))
        XCTAssertTrue(PTNetworkRegressionMatrix.capture.contains(.debugOnOffParity))
        XCTAssertTrue(PTNetworkRegressionMatrix.capture.contains(.realHost))
        XCTAssertTrue(PTNetworkRegressionMatrix.bodyAndStore.contains(.oneThousandRecords))
    }
}
