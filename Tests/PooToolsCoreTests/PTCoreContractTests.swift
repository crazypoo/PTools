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
        XCTAssertEqual(await cache.value(forKey: "key"), "value")

        await cache.removeValue(forKey: "key")
        XCTAssertNil(await cache.value(forKey: "key"))
    }

    // English: Verify that the shared MainActor bridge remains cancellable and value-only at its boundary.
    // Español: Verifica que el puente compartido de MainActor siga siendo cancelable y basado en valores en su límite.
    // 中文：验证共享 MainActor 桥接在边界上仍可取消且只传递值类型。
    @MainActor
    func testMainActorBridgeCanBeCancelledBeforeExecution() async {
        let didRun = PTAtomic(false)
        let task = PTMainActorBridge.after(0.05) {
            didRun.value = true
        }

        task.cancel()
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(didRun.value)
    }
}
