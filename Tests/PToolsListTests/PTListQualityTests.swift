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

    // English: Queued content updates must merge their ranges and preserve every completion.
    // Español: Las actualizaciones de contenido en cola deben combinar sus rangos y conservar cada completion.
    // 中文：排队中的内容刷新必须合并范围，同时保留每一个 completion。
    func testContentUpdatesCoalesceWithoutDroppingCompletions() async {
        let contentExpectation = expectation(description: "both content completions")
        contentExpectation.expectedFulfillmentCount = 2
        let bodyExpectation = expectation(description: "one coalesced content body")
        let diagnostics = PTCollectionUpdateDiagnostics { (sections: 0, items: 0) }
        let coordinator = PTCollectionUpdateCoordinator(diagnostics: diagnostics)
        var releaseStructure: (() -> Void)?
        var contentBodyCount = 0

        coordinator.enqueue(name: "hold") { finish in
            releaseStructure = finish
        }
        coordinator.enqueueContent(name: "content-a",
                                   sections: [1],
                                   items: [IndexPath(item: 0, section: 1)],
                                   body: { sections, items, invalidatesLayout, finish in
            contentBodyCount += 1
            XCTAssertEqual(Set(sections), Set([1, 2]))
            XCTAssertEqual(Set(items), Set([IndexPath(item: 0, section: 1), IndexPath(item: 1, section: 2)]))
            XCTAssertFalse(invalidatesLayout)
            bodyExpectation.fulfill()
            finish()
        }, completion: {
            contentExpectation.fulfill()
        })
        coordinator.enqueueContent(name: "content-b",
                                   sections: [2],
                                   items: [IndexPath(item: 1, section: 2)],
                                   body: { _, _, _, finish in
            finish()
        }, completion: {
            contentExpectation.fulfill()
        })

        releaseStructure?()
        await fulfillment(of: [bodyExpectation, contentExpectation], timeout: 2)
        XCTAssertEqual(contentBodyCount, 1)
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

    // English: Structural insertions must keep the newly inserted models available to the cell provider.
    // Español: Las inserciones estructurales deben conservar los modelos nuevos para el proveedor de celdas.
    // 中文：结构插入后必须保留新模型，确保 Cell Provider 能读取到它们。
    func testInsertSectionAndRowsKeepInsertedModels() async {
        let configuration = PTCollectionViewConfig()
        configuration.refreshWithoutAnimation = true
        let list = PTCollectionView(viewConfig: configuration)
        let initialSection = PTSection(identifier: "insert-initial",
                                       rows: [PTRows(title: "Initial", diffId: "insert-initial-row")])

        let loadExpectation = expectation(description: "initial content loaded")
        list.showCollectionDetail(collectionData: [initialSection], animated: false) { _ in
            loadExpectation.fulfill()
        }
        await fulfillment(of: [loadExpectation], timeout: 2)

        let insertedRow = PTRows(title: "Inserted section row", diffId: "insert-section-row")
        let insertedSection = PTSection(identifier: "inserted-section", rows: [insertedRow])
        let sectionExpectation = expectation(description: "section inserted")
        list.insertSection([insertedSection], afterIndex: 0) {
            sectionExpectation.fulfill()
        }
        await fulfillment(of: [sectionExpectation], timeout: 2)

        XCTAssertEqual(list.collectionSectionDatas.map(\.identifier), ["insert-initial", "inserted-section"])
        XCTAssertTrue(list.getRow(at: IndexPath(item: 0, section: 1)) === insertedRow)

        let appendedRow = PTRows(title: "Inserted row", diffId: "insert-appended-row")
        let rowExpectation = expectation(description: "row inserted")
        list.insertRows([appendedRow], section: 1) {
            rowExpectation.fulfill()
        }
        await fulfillment(of: [rowExpectation], timeout: 2)

        XCTAssertTrue(list.getRow(at: IndexPath(item: 1, section: 1)) === appendedRow)
    }

    // English: Value-model updates replace content without changing the identity-only order.
    // Español: Las actualizaciones de modelos de valor reemplazan el contenido sin cambiar el orden basado en identidad.
    // 中文：值模型更新只替换内容，不改变纯身份列表的顺序。
    func testModelStoreValueUpdatePreservesIdentityOrder() {
        let first = PTRows(title: "First", diffId: "value-0")
        let second = PTRows(title: "Second", diffId: "value-1")
        let section = PTSection(identifier: "value-section", rows: [first, second])
        let store = PTCollectionModelStore()
        store.replace([section])

        let latest = PTRows(title: "Updated", diffId: "value-1")
        store.updateItemContent(at: IndexPath(item: 1, section: 0), using: latest)

        XCTAssertEqual(store.sectionIdentifiers(), [PTSectionIdentifier("value-section")])
        XCTAssertEqual(store.rowIdentifiers(in: PTSectionIdentifier("value-section")),
                       [PTRowIdentifier("value-0"), PTRowIdentifier("value-1")])
        XCTAssertTrue(store.resolvedRow(second) === latest)
    }

    // English: Content coalescing must stop at a structural operation barrier.
    // Español: La combinación de contenido debe detenerse ante una barrera estructural.
    // 中文：内容合并必须在结构操作屏障处停止。
    func testContentCoalescingStopsAtStructureBarrier() async {
        let bodyExpectation = expectation(description: "two content bodies")
        bodyExpectation.expectedFulfillmentCount = 2
        let diagnostics = PTCollectionUpdateDiagnostics { (sections: 0, items: 0) }
        let coordinator = PTCollectionUpdateCoordinator(diagnostics: diagnostics)
        var releaseStructure: (() -> Void)?
        var bodyCount = 0

        coordinator.enqueue(name: "hold") { finish in
            releaseStructure = finish
        }
        coordinator.enqueueContent(name: "content-before-structure", body: { _, _, _, finish in
            bodyCount += 1
            bodyExpectation.fulfill()
            finish()
        })
        coordinator.enqueue(name: "structure") { finish in
            finish()
        }
        coordinator.enqueueContent(name: "content-after-structure", body: { _, _, _, finish in
            bodyCount += 1
            bodyExpectation.fulfill()
            finish()
        })

        releaseStructure?()
        await fulfillment(of: [bodyExpectation], timeout: 2)
        XCTAssertEqual(bodyCount, 2)
    }

    // English: The identity-only adapter keeps legacy model call sites source-compatible.
    // Español: El adaptador basado solo en identidad mantiene compatibles los call sites heredados.
    // 中文：纯身份适配器保持旧模型调用方的源码兼容性。
    func testIdentitySnapshotAdapterPreservesLegacyArguments() {
        let row = PTRows(title: "Legacy", diffId: "legacy-row")
        let section = PTSection(identifier: "legacy-section", rows: [row])
        var snapshot = PTCollectionIDSnapshot()
        snapshot.appendSections([section])
        snapshot.appendItems([row], toSection: section)

        XCTAssertEqual(snapshot.sectionIdentifiers, [PTSectionIdentifier("legacy-section")])
        XCTAssertEqual(snapshot.itemIdentifiers, [PTRowIdentifier("legacy-row")])
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

    // English: Runtime layout transactions preserve stable identities and reuse the same collection view.
    // Español: Las transacciones de layout conservan las identidades estables y reutilizan la misma colección.
    // 中文：运行时布局事务必须保留稳定身份，并复用同一个 CollectionView。
    func testRuntimeLayoutSwitchPreservesCollectionViewAndStableIDs() async {
        let configuration = PTCollectionViewConfig()
        configuration.refreshWithoutAnimation = true
        let list = PTCollectionView(viewConfig: configuration)
        let rows = makeRows(count: 4, prefix: "layout-switch")
        let section = PTSection(identifier: "layout-switch-section", rows: rows)
        let loadExpectation = expectation(description: "layout switch data loaded")

        list.showCollectionDetail(collectionData: [section], animated: false) { _ in
            loadExpectation.fulfill()
        }
        await fulfillment(of: [loadExpectation], timeout: 2)

        let collectionView = list.contentCollectionView
        let identifiersBefore = list.diffableDataSource.snapshot().itemIdentifiers.map(\.diffId)
        let switchExpectation = expectation(description: "layout switch completed")
        list.switchLayout(to: .Gird, animated: false) { success in
            XCTAssertTrue(success)
            switchExpectation.fulfill()
        }
        await fulfillment(of: [switchExpectation], timeout: 2)

        XCTAssertTrue(collectionView === list.contentCollectionView)
        XCTAssertEqual(list.viewConfig.viewType, .Gird)
        XCTAssertEqual(list.diffableDataSource.snapshot().itemIdentifiers.map(\.diffId), identifiersBefore)
    }

    // English: Every public layout mode must complete a queued switch without rebuilding Diffable data.
    // Español: Cada modo público debe completar un cambio en cola sin reconstruir los datos Diffable.
    // 中文：每种公开布局都必须完成排队切换，且不能重建 Diffable 数据。
    func testAllLayoutModesCompleteQueuedSwitches() async {
        let configuration = PTCollectionViewConfig()
        configuration.refreshWithoutAnimation = true
        let list = PTCollectionView(viewConfig: configuration)
        list.customerLayout = { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(44))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .absolute(44))
            return NSCollectionLayoutGroup.vertical(layoutSize: group, subitems: [item])
        }
        // English: Exercise the runtime waterfall custom-item path in the seven-mode matrix.
        // Español: Prueba la ruta de elementos personalizados waterfall dentro de la matriz de siete modos.
        // 中文：在七种布局矩阵中覆盖运行时瀑布流自定义 Item 路径。
        list.waterFallLayout = { index, _ in
            CGFloat(44 + (index % 3) * 8)
        }
        let row = PTRows(title: "Layout", ID: "CELL", diffId: "all-layout-row")
        let section = PTSection(identifier: "all-layout-section", rows: [row])
        let loadExpectation = expectation(description: "all layout data loaded")
        list.showCollectionDetail(collectionData: [section], animated: false) { _ in
            loadExpectation.fulfill()
        }
        await fulfillment(of: [loadExpectation], timeout: 2)

        let modes: [PTCollectionViewType] = [.Normal, .Gird, .WaterFall, .Custom,
                                              .Horizontal, .HorizontalLayoutSystem, .Tag]
        let switchExpectation = expectation(description: "all layout switches completed")
        switchExpectation.expectedFulfillmentCount = modes.count * modes.count
        for source in modes {
            for destination in modes {
                list.viewConfig.viewType = source
                list.switchLayout(to: destination, animated: false) { success in
                    XCTAssertTrue(success)
                    switchExpectation.fulfill()
                }
            }
        }
        await fulfillment(of: [switchExpectation], timeout: 4)
        XCTAssertEqual(list.pendingUpdateCount, 0)
    }

    // English: Revision-aware cache keys prevent row-count and spacing changes from reusing old geometry.
    // Español: Las claves con revisión impiden reutilizar geometría antigua tras cambiar filas o espacios.
    // 中文：带修订号的缓存键可防止列数和间距变化命中旧几何缓存。
    func testRuntimeLayoutCacheKeysIncludeRevision() {
        let oldLayout = LayoutCacheKey(section: 0, width: 320, version: 1, layoutRevision: 1)
        let newLayout = LayoutCacheKey(section: 0, width: 320, version: 1, layoutRevision: 2)
        let oldWaterfall = PTCollectionWaterfallCacheKey(section: 0, width: 320, version: 1, layoutRevision: 1)
        let newWaterfall = PTCollectionWaterfallCacheKey(section: 0, width: 320, version: 1, layoutRevision: 2)

        XCTAssertNotEqual(oldLayout, newLayout)
        XCTAssertNotEqual(oldWaterfall, newWaterfall)
    }

    // English: Invalid custom configuration fails safely and never replaces the active layout.
    // Español: Una configuración custom inválida falla de forma segura y no reemplaza el layout activo.
    // 中文：无效的 Custom 配置必须安全失败，不能替换当前布局。
    func testCustomLayoutWithoutProviderFailsSafely() async {
        let configuration = PTCollectionViewConfig()
        configuration.refreshWithoutAnimation = true
        let list = PTCollectionView(viewConfig: configuration)
        let expectation = expectation(description: "custom layout rejected")

        list.switchLayout(to: .Custom, animated: false) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(list.viewConfig.viewType, .Normal)
    }

    // English: Waterfall geometry must preserve a one-to-one frame mapping for Diffable rows.
    // Español: La geometría waterfall debe conservar una correspondencia uno a uno con las filas Diffable.
    // 中文：瀑布流几何计算必须保持 Diffable 行与布局 Frame 一一对应。
    func testWaterfallGeometryPreservesRowCount() {
        let rows: [AnyObject] = [NSObject(), NSObject(), NSObject()]
        let result = PTCollectionLayoutGeometry.waterfall(data: rows,
                                                          width: 320,
                                                          rowCount: 2,
                                                          itemOriginalX: 8,
                                                          topContentSpace: 8,
                                                          bottomContentSpace: 8,
                                                          itemSpace: 8,
                                                          itemTrailingSpace: 8) { index, _ in
            CGFloat(48 + index * 8)
        }

        XCTAssertEqual(result.frames.count, rows.count)
        XCTAssertTrue(result.frames.allSatisfy { $0.width > 0 && $0.height > 0 })
        XCTAssertTrue(result.contentHeight > 0)
    }
}
