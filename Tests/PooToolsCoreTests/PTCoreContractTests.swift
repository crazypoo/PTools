import XCTest
@testable import PToolsCore

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
}
