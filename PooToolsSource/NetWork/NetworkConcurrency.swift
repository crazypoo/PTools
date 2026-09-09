import Foundation
import Alamofire
import os.lock

// English: Keep concurrency support types separate from the legacy Network facade.
// Español: Mantiene los tipos de soporte de concurrencia separados de la fachada heredada Network.
// 中文：将并发支撑类型与旧版 Network 外观层分离。
public actor RequestDeduplicator {
    public static let shared = RequestDeduplicator()

    private struct RunningTask {
        let id: UUID
        let task: Any
        var waiterCount: Int
    }

    // English: Type erasure stays inside this actor; callers only receive Sendable results.
    // Español: La eliminación de tipos permanece dentro de este actor; los llamadores reciben solo resultados Sendable.
    // 中文：类型擦除只存在于 actor 内部，调用方只会收到 Sendable 结果。
    private var runningTasks: [RequestKey: RunningTask] = [:]

    private init() {}

    public func execute<T: Sendable>(
        request: URLRequest,
        policy: PTNetworkDedupPolicy,
        task: @escaping @Sendable () async throws -> PTBaseStructModel<T>
    ) async throws -> PTBaseStructModel<T> {
        switch policy {
        case .none:
            return try await task()
        default:
            let key = RequestKey(request: request, responseType: T.self)
            let taskID: UUID
            let sharedTask: Task<PTBaseStructModel<T>, Error>

            if var entry = runningTasks[key],
               let existingTask = entry.task as? Task<PTBaseStructModel<T>, Error> {
                entry.waiterCount += 1
                runningTasks[key] = entry
                taskID = entry.id
                sharedTask = existingTask
            } else {
                let newID = UUID()
                let newTask = Task { try await task() }
                runningTasks[key] = RunningTask(id: newID,
                                                task: newTask,
                                                waiterCount: 1)
                taskID = newID
                sharedTask = newTask
            }

            let releaseWaiter: @Sendable () -> Void = {
                Task {
                    let shouldCancel = await self.releaseWaiter(key: key, id: taskID)
                    if shouldCancel {
                        sharedTask.cancel()
                    }
                }
            }
            let releaseGate = PTNetworkOnceGate()
            let releaseOnce: @Sendable () -> Void = {
                releaseGate.run(releaseWaiter)
            }

            do {
                let result = try await withTaskCancellationHandler(operation: {
                    try await sharedTask.value
                }, onCancel: releaseOnce)
                releaseOnce()
                try Task.checkCancellation()
                return result
            } catch {
                releaseOnce()
                throw error
            }
        }
    }

    internal func executeRaw(
        request: URLRequest,
        policy: PTNetworkDedupPolicy,
        task: @escaping @Sendable () async throws -> PTNetworkResponseSnapshot
    ) async throws -> PTNetworkResponseSnapshot {
        switch policy {
        case .none:
            return try await task()
        default:
            let key = RequestKey(request: request, responseType: PTNetworkResponseSnapshot.self)
            let taskID: UUID
            let sharedTask: Task<PTNetworkResponseSnapshot, Error>

            if var entry = runningTasks[key],
               let existingTask = entry.task as? Task<PTNetworkResponseSnapshot, Error> {
                entry.waiterCount += 1
                runningTasks[key] = entry
                taskID = entry.id
                sharedTask = existingTask
            } else {
                let newID = UUID()
                let newTask = Task { try await task() }
                runningTasks[key] = RunningTask(id: newID,
                                                task: newTask,
                                                waiterCount: 1)
                taskID = newID
                sharedTask = newTask
            }

            let releaseWaiter: @Sendable () -> Void = {
                Task {
                    let shouldCancel = await self.releaseWaiter(key: key, id: taskID)
                    if shouldCancel {
                        sharedTask.cancel()
                    }
                }
            }
            let releaseGate = PTNetworkOnceGate()
            let releaseOnce: @Sendable () -> Void = {
                releaseGate.run(releaseWaiter)
            }

            do {
                let result = try await withTaskCancellationHandler(operation: {
                    try await sharedTask.value
                }, onCancel: releaseOnce)
                releaseOnce()
                try Task.checkCancellation()
                return result
            } catch {
                releaseOnce()
                throw error
            }
        }
    }

    private func releaseWaiter(key: RequestKey, id: UUID) -> Bool {
        guard var entry = runningTasks[key], entry.id == id else { return false }
        entry.waiterCount -= 1
        guard entry.waiterCount <= 0 else {
            runningTasks[key] = entry
            return false
        }
        runningTasks.removeValue(forKey: key)
        return true
    }
}

// English: This bridge makes an async download continuation finish exactly once.
// Español: Este puente garantiza que la continuación de una descarga asíncrona termine una sola vez.
// 中文：这个桥接器保证异步下载 continuation 只结束一次。
@MainActor
final class PTDownloadCancellationBridge {
    private var didFinish = false
    private var cancellationRequested = false
    private var cancelUnderlying: (() -> Void)?
    private var resumeCancellation: (() -> Void)?

    func install(resumeCancellation: @escaping () -> Void) {
        guard !didFinish else { return }
        self.resumeCancellation = resumeCancellation
        if cancellationRequested {
            finishCancellation()
        }
    }

    func install(cancelUnderlying: @escaping () -> Void) {
        if didFinish {
            if cancellationRequested {
                cancelUnderlying()
            }
            return
        }
        self.cancelUnderlying = cancelUnderlying
        if cancellationRequested {
            cancelUnderlying()
        }
    }

    func finish() -> Bool {
        guard !didFinish else { return false }
        didFinish = true
        cancelUnderlying = nil
        resumeCancellation = nil
        return true
    }

    func cancel() {
        cancellationRequested = true
        cancelUnderlying?()
        finishCancellation()
    }

    private func finishCancellation() {
        guard !didFinish else { return }
        didFinish = true
        cancelUnderlying = nil
        let resumeCancellation = resumeCancellation
        self.resumeCancellation = nil
        resumeCancellation?()
    }
}

// English: This gate releases one deduplicated waiter exactly once.
// Español: Esta compuerta libera exactamente una vez a cada espera deduplicada.
// 中文：这个闸门保证去重请求的每个等待者只释放一次。
private struct PTNetworkOnceGate: Sendable {
    private let didRun = OSAllocatedUnfairLock(initialState: false)

    func run(_ action: @escaping @Sendable () -> Void) {
        let shouldRun = didRun.withLock { didRun in
            guard !didRun else { return false }
            didRun = true
            return true
        }
        if shouldRun {
            action()
        }
    }
}

// English: This bridge cancels upload preparation and the Alamofire request from stream termination.
// Español: Este puente cancela la preparación y la solicitud de Alamofire al terminar el stream.
// 中文：这个桥接器在流结束时同时取消上传准备任务和 Alamofire 请求。
final class PTNetworkUploadCancellation: Sendable {
    private struct State: Sendable {
        var preparationTask: Task<Void, Never>?
        var request: UploadRequest?
        var isCancelled = false
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func install(preparationTask: Task<Void, Never>) {
        let shouldCancel = state.withLock { state -> Bool in
            guard !state.isCancelled else { return true }
            state.preparationTask = preparationTask
            return false
        }
        if shouldCancel {
            preparationTask.cancel()
        }
    }

    func install(request: UploadRequest) {
        let shouldCancel = state.withLock { state -> Bool in
            guard !state.isCancelled else { return true }
            state.request = request
            return false
        }
        if shouldCancel {
            request.cancel()
        }
    }

    func cancel() {
        let resources = state.withLock { state -> (Task<Void, Never>?, UploadRequest?) in
            state.isCancelled = true
            let resources = (state.preparationTask, state.request)
            state.preparationTask = nil
            state.request = nil
            return resources
        }
        resources.0?.cancel()
        resources.1?.cancel()
    }
}
