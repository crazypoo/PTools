// English: Exercise body thresholds and actor-store budgets with real records.
// Español: Ejecuta umbrales de cuerpo y presupuestos del almacén actor con registros reales.
// 中文：用真实记录执行正文阈值和 Actor 存储预算测试。

import XCTest
@testable import PooToolsDEBUG

final class PTDebugNetworkBodyStoreTests: XCTestCase {
    func testBodyThresholdsAndTemporaryCleanup() async {
        let policy = PTNetworkBodyCapturePolicy(memoryPreviewLimit: 4,
                                                fileThreshold: 8,
                                                absoluteCaptureLimit: 10,
                                                totalStoreMemoryBudget: 16)
        let exact = PTNetworkBodyCapture.make(data: Data(repeating: 1, count: 4), policy: policy)
        XCTAssertEqual(exact.totalBytes, 4)
        XCTAssertEqual(exact.previewData?.count, 4)

        let plusOne = PTNetworkBodyCapture.make(data: Data(repeating: 1, count: 5), policy: policy)
        XCTAssertEqual(plusOne.totalBytes, 5)
        XCTAssertEqual(plusOne.previewData?.count, 4)

        let fileBody = PTNetworkBodyCapture.make(data: Data(repeating: 2, count: 9),
                                                 policy: policy,
                                                 fileNamespace: "body-store-test")
        guard let fileURL = fileBody.diskURL else {
            XCTFail("file threshold did not create a file-backed capture")
            return
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let truncated = PTNetworkBodyCapture.make(data: Data(repeating: 3, count: 11), policy: policy)
        XCTAssertEqual(truncated.totalBytes, 11)
        XCTAssertEqual(truncated.previewData?.count, 4)

        let store = PTNetworkCaptureStore(maxRecords: 1, bodyMemoryBudget: 4, diskBudget: 1_024 * 1_024)
        let first = record(body: fileBody)
        _ = await store.insert(first)
        _ = await store.finalize(id: first.id,
                                 response: nil,
                                 timing: first.timing,
                                 metrics: nil,
                                 error: nil,
                                 completion: .completed)
        let second = record(body: exact)
        _ = await store.insert(second)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testFiveHundredAndOneThousandRecordEviction() async {
        let store = PTNetworkCaptureStore(maxRecords: 500, bodyMemoryBudget: 1_000_000, diskBudget: 1_000_000)
        for index in 0..<1_000 {
            let value = record(index: index)
            _ = await store.insert(value)
            _ = await store.finalize(id: value.id,
                                     response: nil,
                                     timing: value.timing,
                                     metrics: nil,
                                     error: nil,
                                     completion: .completed)
        }
        XCTAssertEqual((await store.records()).count, 500)
    }

    func testConcurrentInsertAndFinalizeAreExactlyOnce() async {
        let store = PTNetworkCaptureStore(maxRecords: 1_000, bodyMemoryBudget: 1_000_000, diskBudget: 1_000_000)
        let records = (0..<100).map { record(index: $0) }
        await withTaskGroup(of: Void.self) { group in
            for value in records {
                group.addTask { _ = await store.insert(value) }
            }
        }
        await withTaskGroup(of: Bool.self) { group in
            for value in records {
                group.addTask {
                    await store.finalize(id: value.id,
                                         response: nil,
                                         timing: value.timing,
                                         metrics: nil,
                                         error: nil,
                                         completion: .completed)
                }
            }
            var finalized = 0
            for await didFinalize in group where didFinalize {
                finalized += 1
            }
            XCTAssertEqual(finalized, records.count)
        }

        let duplicate = records[0]
        XCTAssertFalse(await store.finalize(id: duplicate.id,
                                             response: nil,
                                             timing: duplicate.timing,
                                             metrics: nil,
                                             error: nil,
                                             completion: .completed))
    }

    private func record(index: Int = 0, body: PTNetworkBodyCapture = .none) -> PTNetworkCaptureRecord {
        let request = PTNetworkRequestSnapshot(url: URL(string: "https://ptools.fixture/record/\(index)")!,
                                                method: "POST",
                                                body: body)
        return PTNetworkCaptureRecord(request: request,
                                      timing: PTNetworkTiming(startedAt: .now),
                                      source: .urlProtocol,
                                      phase: .created)
    }
}
