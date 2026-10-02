// English: Keep the performance check bounded and deterministic for CI.
// Español: Mantén la comprobación de rendimiento acotada y determinista para CI.
// 中文：让 CI 性能检查保持有界且确定。

import XCTest
@testable import PooToolsDEBUG

final class PTDebugNetworkPerformanceTests: XCTestCase {
    func testBodySnapshotHandlesBurstAndLargePayloads() {
        let payload = Data(repeating: 0x5A, count: 128 * 1024)
        let policy = PTNetworkBodyCapturePolicy(memoryPreviewLimit: 1_024,
                                                fileThreshold: 8 * 1024,
                                                absoluteCaptureLimit: 64 * 1024,
                                                totalStoreMemoryBudget: 64 * 1024)
        measure {
            for _ in 0..<100 {
                let body = PTNetworkBodyCapture.make(data: payload,
                                                     policy: policy,
                                                     fileNamespace: "performance")
                XCTAssertEqual(body.totalBytes, Int64(payload.count))
                if let url = body.diskURL {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
    }

    func testStoreAcceptsOneThousandConcurrentRecords() async {
        let store = PTNetworkCaptureStore(maxRecords: 1_000,
                                          bodyMemoryBudget: 4 * 1024 * 1024,
                                          diskBudget: 4 * 1024 * 1024)
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<1_000 {
                group.addTask {
                    let request = PTNetworkRequestSnapshot(url: URL(string: "https://ptools.fixture/burst/\(index)")!)
                    let value = PTNetworkCaptureRecord(request: request,
                                                       timing: PTNetworkTiming(startedAt: .now),
                                                       source: .urlProtocol,
                                                       completion: .completed,
                                                       phase: .finalized)
                    _ = await store.insert(value)
                }
            }
        }
        XCTAssertEqual((await store.records()).count, 1_000)
    }
}
