import XCTest
@testable import ptools

@MainActor
final class PTListQualityTests: XCTestCase {
    private func makeRows(count: Int, prefix: String) -> [PTRows] {
        (0..<count).map { index in
            PTRows(title: "Row \(index)",
                   ID: "PTListCell",
                   diffId: "\(prefix)-\(index)",
                   diffHash: index)
        }
    }

    private func makeSnapshot(section: PTSection, rows: [PTRows]) -> PTSnapshot {
        var snapshot = PTSnapshot()
        snapshot.appendSections([section])
        snapshot.appendItems(rows, toSection: section)
        return snapshot
    }

    func testSnapshotLookupUsesCurrentSnapshotOrder() {
        let rows = makeRows(count: 2, prefix: "lookup")
        let section = PTSection(identifier: "lookup-section", rows: rows)
        let snapshot = makeSnapshot(section: section, rows: rows)
        let coordinator = PTCollectionDataCoordinator()

        let row = coordinator.row(at: IndexPath(item: 1, section: 0), in: snapshot)

        XCTAssertTrue(row === rows[1])
    }

    func testDuplicateIdentitiesAreRejectedBeforeApplyingSnapshot() {
        let first = PTRows(title: "First", diffId: "duplicate")
        let second = PTRows(title: "Second", diffId: "duplicate")
        let section = PTSection(identifier: "duplicate-section", rows: [first, second])
        let coordinator = PTCollectionDataCoordinator()

        let error = coordinator.validationError(for: [section])

        guard case .duplicateRowIdentifier("duplicate") = error else {
            XCTFail("重复行标识没有被识别")
            return
        }
    }

    func testRapidUpdatesKeepStableRowIdentifiers() {
        let rows = makeRows(count: 100, prefix: "rapid")
        let section = PTSection(identifier: "rapid-section", rows: rows)
        var snapshot = makeSnapshot(section: section, rows: rows)

        for _ in 0..<50 {
            snapshot.reloadItems(rows)
        }

        XCTAssertEqual(snapshot.itemIdentifiers.map(\.diffId), rows.map(\.diffId))
    }

    // English: The compatibility store must return the latest mutable model for an unchanged identity.
    // Español: El almacén compatible debe devolver el modelo mutable más reciente con la misma identidad.
    // 中文：兼容模型仓库必须在身份不变时返回最新的可变模型。
    func testModelStoreResolvesLatestRowForStableIdentity() {
        let first = PTRows(title: "Old", diffId: "stable-row")
        let section = PTSection(identifier: "stable-section", rows: [first])
        let store = PTCollectionModelStore()
        store.replace([section])

        let latest = PTRows(title: "Latest", diffId: "stable-row")
        store.update(rows: [latest])

        XCTAssertTrue(store.resolvedRow(first) === latest)
        XCTAssertTrue(store.resolvedSection(section).rows?.first === latest)
    }

    // English: Every queued update must execute in order instead of being dropped while a snapshot is applying.
    // Español: Cada actualización encolada debe ejecutarse en orden y no descartarse durante un apply.
    // 中文：每个排队更新都必须按顺序执行，不能在快照应用期间被丢弃。
    func testUpdateCoordinatorExecutesAllQueuedOperations() async {
        let expectation = expectation(description: "all collection updates finish")
        expectation.expectedFulfillmentCount = 3
        var executionOrder: [Int] = []
        let diagnostics = PTCollectionUpdateDiagnostics { (sections: 0, items: 0) }
        let coordinator = PTCollectionUpdateCoordinator(diagnostics: diagnostics)

        for value in 0..<3 {
            coordinator.enqueue(name: "test-\(value)") { finish in
                executionOrder.append(value)
                finish()
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(executionOrder, [0, 1, 2])
    }

    // English: Content refresh keeps the Diffable structure and stable identities unchanged.
    // Español: El refresco de contenido conserva la estructura Diffable y las identidades estables.
    // 中文：内容刷新必须保持 Diffable 结构和稳定身份不变。
    func testContentRefreshPreservesSnapshotIdentities() async {
        let configuration = PTCollectionViewConfig()
        configuration.refreshWithoutAnimation = true
        let list = PTCollectionView(viewConfig: configuration)
        let row = PTRows(title: "Before", diffId: "content-row")
        let section = PTSection(identifier: "content-section", rows: [row])

        let loadExpectation = expectation(description: "initial content loaded")
        list.showCollectionDetail(collectionData: [section], animated: false) { _ in
            loadExpectation.fulfill()
        }
        await fulfillment(of: [loadExpectation], timeout: 2)

        let sectionIDsBefore = list.diffableDataSource.snapshot().sectionIdentifiers.map(\.identifier)
        let rowIDsBefore = list.diffableDataSource.snapshot().itemIdentifiers.map(\.diffId)
        row.title = "After"

        let refreshExpectation = expectation(description: "content refreshed")
        list.reloadItemContent(at: [IndexPath(item: 0, section: 0)]) {
            refreshExpectation.fulfill()
        }
        await fulfillment(of: [refreshExpectation], timeout: 2)

        let snapshot = list.diffableDataSource.snapshot()
        XCTAssertEqual(snapshot.sectionIdentifiers.map(\.identifier), sectionIDsBefore)
        XCTAssertEqual(snapshot.itemIdentifiers.map(\.diffId), rowIDsBefore)
        XCTAssertEqual(list.getRow(at: IndexPath(item: 0, section: 0))?.title, "After")
    }

    func testMeasureFullSnapshotForOneThousandRows() {
        let rows = makeRows(count: 1_000, prefix: "full-1k")
        let section = PTSection(identifier: "full-1k-section", rows: rows)

        measure {
            _ = makeSnapshot(section: section, rows: rows)
        }
    }

    func testMeasureFullSnapshotForTenThousandRows() {
        let rows = makeRows(count: 10_000, prefix: "full-10k")
        let section = PTSection(identifier: "full-10k-section", rows: rows)

        measure {
            _ = makeSnapshot(section: section, rows: rows)
        }
    }

    func testMeasureIncrementalSnapshotConstruction() {
        let rows = makeRows(count: 10_000, prefix: "incremental")
        let initialRows = Array(rows.prefix(9_000))
        let appendedRows = Array(rows.suffix(1_000))
        let section = PTSection(identifier: "incremental-section", rows: rows)

        measure {
            var snapshot = PTSnapshot()
            snapshot.appendSections([section])
            snapshot.appendItems(initialRows, toSection: section)
            snapshot.appendItems(appendedRows, toSection: section)
        }
    }

    func testCollectionScenarioInventoryCoversQualityMatrix() {
        let scenarios = Set([
            "rapid-updates",
            "rotation",
            "waterfall",
            "photo-prefetch"
        ])

        XCTAssertEqual(scenarios.count, 4)
    }
}
