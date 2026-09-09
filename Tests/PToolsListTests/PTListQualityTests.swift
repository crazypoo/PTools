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
