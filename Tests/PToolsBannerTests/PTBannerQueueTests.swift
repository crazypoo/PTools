// English: Queue regression tests for the native banner module.
// Español: Pruebas de regresión de la cola del módulo de banners nativo.
// 中文：原生 Banner 模块队列回归测试。

import XCTest
@testable import PooToolsBanner

@MainActor
final class PTBannerQueueTests: XCTestCase {
    func testPriorityWinsBeforeFrontBackOrdering() {
        let queue = PTBannerQueue(configuration: PTBannerQueueConfiguration())
        var low = PTBanner.info(title: "low")
        var high = PTBanner.info(title: "high")
        low.priority = .low
        high.priority = .high
        let lowHandle = PTBannerHandle(id: low.id)
        let highHandle = PTBannerHandle(id: high.id)

        _ = queue.enqueue(low, handle: lowHandle, position: .front)
        _ = queue.enqueue(high, handle: highHandle, position: .back)

        XCTAssertEqual(queue.dequeue()?.banner.id, high.id)
        XCTAssertEqual(queue.dequeue()?.banner.id, low.id)
    }

    func testDuplicateContentIsDroppedWithinConfiguredWindow() {
        let configuration = PTBannerQueueConfiguration(deduplication: .byContent(window: 60))
        let queue = PTBannerQueue(configuration: configuration)
        let first = PTBanner.info(title: "same")
        let duplicate = PTBanner.info(title: "same")
        let firstHandle = PTBannerHandle(id: first.id)
        let duplicateHandle = PTBannerHandle(id: duplicate.id)

        XCTAssertTrue(queue.enqueue(first, handle: firstHandle, position: .back).isEmpty)
        let dropped = queue.enqueue(duplicate, handle: duplicateHandle, position: .back)

        XCTAssertEqual(dropped.map(\.id), [duplicate.id])
        XCTAssertEqual(queue.dequeue()?.banner.id, first.id)
    }

    func testOverflowDropsOldestQueuedEntry() {
        let configuration = PTBannerQueueConfiguration(maxQueueCount: 2, overflow: .dropOldest)
        let queue = PTBannerQueue(configuration: configuration)
        let banners = (0..<3).map { PTBanner.info(title: "\($0)") }
        let handles = banners.map { PTBannerHandle(id: $0.id) }

        for (banner, handle) in zip(banners, handles) {
            _ = queue.enqueue(banner, handle: handle, position: .back)
        }

        XCTAssertEqual(queue.dequeue()?.banner.id, banners[1].id)
        XCTAssertEqual(queue.dequeue()?.banner.id, banners[2].id)
    }
}
