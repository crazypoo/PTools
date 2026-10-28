import XCTest
@testable import PToolsCore
@testable import PToolsVariantCore

final class PTCoreContractTests: XCTestCase {
    func testProgressSnapshotKeepsImmutableValues() {
        let snapshot = PTProgressSnapshot(completedUnitCount: 5,
                                          totalUnitCount: 10,
                                          fractionCompleted: 0.5)

        XCTAssertEqual(snapshot.completedUnitCount, 5)
        XCTAssertEqual(snapshot.totalUnitCount, 10)
        XCTAssertEqual(snapshot.fractionCompleted, 0.5)
        XCTAssertEqual(snapshot, PTProgressSnapshot(completedUnitCount: 5,
                                                    totalUnitCount: 10,
                                                    fractionCompleted: 0.5))
    }

    func testResponseMetadataKeepsOnlySendableValues() {
        let metadata = PTResponseMetadata(statusCode: 200,
                                          headers: ["Content-Type": "application/json"],
                                          isDegraded: false,
                                          isCancelled: false)

        XCTAssertEqual(metadata.statusCode, 200)
        XCTAssertEqual(metadata.headers["Content-Type"], "application/json")
        XCTAssertFalse(metadata.isDegraded)
        XCTAssertFalse(metadata.isCancelled)
    }

    func testBaseStructModelKeepsTypedPayload() {
        var model = PTBaseStructModel<String>()
        model.originalString = "ok"
        model.customerModel = "payload"
        model.resultData = Data("{}".utf8)

        XCTAssertEqual(model.originalString, "ok")
        XCTAssertEqual(model.customerModel, "payload")
        XCTAssertEqual(model.resultData, Data("{}".utf8))
    }

    // English: Verify that the cancellation source invokes an observer only once.
    // Español: Verifica que la fuente de cancelación invoque un observador solo una vez.
    // 中文：验证取消源只会调用观察者一次。
    func testCancellationTokenIsExactlyOnce() {
        let token = PTCancellationToken()
        let lock = PTLocked(0)
        let registration = token.observe {
            lock.withLock { $0 += 1 }
        }

        XCTAssertTrue(token.cancel())
        XCTAssertFalse(token.cancel())
        XCTAssertEqual(lock.value, 1)

        registration.cancel()
        XCTAssertEqual(lock.value, 1)
    }

    // English: Verify that the actor cache exposes only typed asynchronous storage operations.
    // Español: Verifica que la caché actorizada exponga solo operaciones asíncronas de almacenamiento tipado.
    // 中文：验证 actor 缓存只暴露类型化异步存储操作。
    func testMemoryCacheStoresAndRemovesValue() async {
        let cache = PTMemoryCache<String>()

        await cache.insert("value", forKey: "key")
        let storedValue = await cache.value(forKey: "key")
        XCTAssertEqual(storedValue, "value")

        await cache.removeValue(forKey: "key")
        let removedValue = await cache.value(forKey: "key")
        XCTAssertNil(removedValue)
    }

    // English: Verify that typed JSON values round-trip without crossing the Any boundary.
    // Español: Verifica que los valores JSON tipados se conserven sin cruzar el límite de Any.
    // 中文：验证类型化 JSON 值可以往返编解码且不会跨越 Any 边界。
    func testJSONValueRoundTrip() throws {
        let value: PTJSONValue = .object([
            "name": .string("PTools"),
            "count": .integer(5),
            "enabled": .bool(true),
            "items": .array([.null, .number(2.5)])
        ])

        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(PTJSONValue.self, from: data)
        XCTAssertEqual(decoded, value)
    }

    // English: Verify that the common result surface keeps success and failure typed.
    // Español: Verifica que el resultado común mantenga tipificados el éxito y el fallo.
    // 中文：验证通用结果类型同时保持成功值和失败错误的明确类型。
    func testCoreResultIsTyped() {
        let success: PTResult<String> = .success("ok")
        let failure: PTResult<String> = .failure(.cancelled)

        XCTAssertEqual(success.successValue, "ok")
        XCTAssertEqual(failure.failureError, .cancelled)
    }

    // English: Verify that a refresh invalidates an older pagination response.
    // Español: Verifica que una actualización invalide una respuesta de paginación anterior.
    // 中文：验证刷新会让旧分页回包失效。
    func testPaginationMachineRejectsStaleRefreshResponse() {
        var machine = PTPaginationMachine(configuration: .init(firstPage: 1, pageSize: 10))
        let oldToken = machine.beginRefresh()
        let newToken = machine.beginRefresh()

        XCTAssertFalse(machine.isCurrent(oldToken))
        XCTAssertTrue(machine.isCurrent(newToken))
        XCTAssertFalse(machine.applySuccess(oldToken, itemCount: 10))
        XCTAssertTrue(machine.applySuccess(newToken, itemCount: 10, hasMore: true))
        XCTAssertEqual(machine.currentPage, 1)
        XCTAssertTrue(machine.hasMore)
    }

    // English: Verify failure rolls a serialized page back so it can be retried.
    // Español: Verifica que un fallo retroceda una página serializada para permitir reintentarla.
    // 中文：验证串行分页失败后会回退并允许重试。
    func testPaginationMachineRetriesFailedPage() {
        var machine = PTPaginationMachine(configuration: .init(firstPage: 0, pageSize: 20))
        let first = machine.beginRefresh()
        XCTAssertTrue(machine.applySuccess(first, itemCount: 20, hasMore: true))
        let next = machine.beginNextPage()
        XCTAssertNotNil(next)
        XCTAssertTrue(machine.applyFailure(next!))
        let retry = machine.beginNextPage()
        XCTAssertEqual(retry?.requestedPage, 1)
    }

    // English: Verify cancellation synchronously invalidates the old generation gate token.
    // Español: Verifica que la cancelación invalide sincrónicamente el token antiguo de la barrera.
    // 中文：验证取消会同步让旧代次门控令牌失效。
    func testLoadGenerationCancellationInvalidatesToken() {
        let coordinator = PTLoadGenerationCoordinator()
        let token = coordinator.begin()
        XCTAssertTrue(coordinator.isCurrent(token))

        coordinator.cancelCurrent()

        XCTAssertFalse(coordinator.isCurrent(token))
    }

    // English: Verify that replacing a task cancels an earlier task from the same owner.
    // Español: Verifica que reemplazar una tarea cancele la tarea anterior del mismo propietario.
    // 中文：验证替换任务会取消同一所有者的旧任务。
    func testLoadGenerationReplacementCancelsPreviousTask() async {
        let coordinator = PTLoadGenerationCoordinator()
        let token = coordinator.begin()
        let oldTask: Task<Void, Never> = Task {
            do {
                try await Task.sleep(for: .seconds(10))
            } catch {
                // English: Cancellation is the expected completion path for the replaced task.
                // Español: La cancelación es la ruta de finalización esperada para la tarea reemplazada.
                // 中文：被替换任务以取消作为预期的结束路径。
            }
        }
        coordinator.replaceTask(oldTask, for: token)
        let newTask = Task { }
        coordinator.replaceTask(newTask, for: token)

        XCTAssertTrue(oldTask.isCancelled)
        newTask.cancel()
    }

    // English: Verify that the shared MainActor bridge remains cancellable and value-only at its boundary.
    // Español: Verifica que el puente compartido de MainActor siga siendo cancelable y basado en valores en su límite.
    // 中文：验证共享 MainActor 桥接在边界上仍可取消且只传递值类型。
    @MainActor
    func testMainActorBridgeCanBeCancelledBeforeExecution() async {
        let didRun = PTAtomic(false)
        let task = PTMainActorBridge.after(0.05) {
            didRun.compareExchange(expected: false, desired: true)
        }

        task.cancel()
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(didRun.value)
    }

    // English: Verify variant selection stays independent from UI and backend model types.
    // Español: Verifica que la selección de variantes permanezca independiente de UI y de los modelos del backend.
    // 中文：验证规格选择引擎独立于 UI 和后端模型类型。
    func testVariantSelectionProducesStableMatchAndPriceRange() {
        let options = [
            PTVariantOption(level: 1, id: "red"),
            PTVariantOption(level: 1, id: "blue"),
            PTVariantOption(level: 2, id: "small"),
            PTVariantOption(level: 2, id: "large")
        ]
        let variants = [
            PTVariant(rawKey: "color:red;size:small",
                      optionIDs: [1: "red", 2: "small"],
                      identifier: "red-small",
                      price: 10,
                      stock: 2),
            PTVariant(rawKey: "color:red;size:large",
                      optionIDs: [1: "red", 2: "large"],
                      identifier: "red-large",
                      price: 12,
                      stock: 0),
            PTVariant(rawKey: "color:blue;size:small",
                      optionIDs: [1: "blue", 2: "small"],
                      identifier: "blue-small",
                      price: 11,
                      stock: 3)
        ]

        var engine = PTVariantSelectionEngine(levels: [1, 2],
                                              options: options,
                                              variants: variants)
        _ = engine.select(level: 1, optionID: "red")
        let snapshot = engine.select(level: 2, optionID: "small")

        XCTAssertEqual(snapshot.matchedVariant?.identifier, "red-small")
        XCTAssertEqual(snapshot.priceRange, PTVariantPriceRange(minimum: 10, maximum: 10))
        XCTAssertEqual(PTVariantSelectionEngine.keyTokens(from: "color:red;size:small"),
                       ["color:red", "size:small"])
        XCTAssertEqual(snapshot.optionStates[PTVariantOptionReference(level: 2, id: "large")], .soldOut)
    }

    // English: Verify that strict conflict handling preserves the last valid selection.
    // Español: Verifica que el manejo estricto de conflictos conserve la última selección válida.
    // 中文：验证严格冲突策略会保留最近一次有效选择。
    func testVariantSelectionCanRejectConflictingOption() {
        let options = [
            PTVariantOption(level: 1, id: "red"),
            PTVariantOption(level: 1, id: "blue"),
            PTVariantOption(level: 2, id: "small"),
            PTVariantOption(level: 2, id: "large")
        ]
        let variants = [
            PTVariant(rawKey: "red-small", optionIDs: [1: "red", 2: "small"], stock: 1),
            PTVariant(rawKey: "blue-large", optionIDs: [1: "blue", 2: "large"], stock: 1)
        ]

        var engine = PTVariantSelectionEngine(levels: [1, 2],
                                              options: options,
                                              variants: variants,
                                              conflictPolicy: .rejectNewSelection)
        _ = engine.select(level: 1, optionID: "red")
        _ = engine.select(level: 2, optionID: "small")
        let snapshot = engine.select(level: 2, optionID: "large")

        XCTAssertEqual(snapshot.selected, [1: "red", 2: "small"])
        XCTAssertEqual(snapshot.matchedVariant?.rawKey, "red-small")
    }
}
