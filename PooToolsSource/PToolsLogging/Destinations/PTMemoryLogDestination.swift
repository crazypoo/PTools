//
//  PTMemoryLogDestination.swift
//  PToolsLogging
//
// English: Provides a bounded in-memory log destination for Debug UI and Instruments consumers.
// Español: Proporciona un destino de logs en memoria y acotado para consumidores de Debug e Instruments.
// 中文：为 Debug UI 和 Instruments 消费者提供有界的内存日志目标。
//

import Foundation
import os.lock

private actor PTMemoryFlushRequest {
    private var continuation: CheckedContinuation<Void, Never>?
    private var resolved = false

    func wait() async {
        await withCheckedContinuation { continuation in
            if resolved {
                continuation.resume()
            } else {
                self.continuation = continuation
            }
        }
    }

    func resolve() {
        resolved = true
        let continuation = continuation
        self.continuation = nil
        continuation?.resume()
    }
}

private enum PTMemoryLogEvent: Sendable {
    case record(PTLogRecord)
    case flush(PTMemoryFlushRequest)
}

private struct PTMemoryRingBuffer: Sendable {
    private let capacity: Int
    private var values: [PTLogRecord?]
    private var head = 0
    private var count = 0

    init(capacity: Int) {
        self.capacity = max(1, capacity)
        self.values = Array(repeating: nil, count: max(1, capacity))
    }

    mutating func append(_ record: PTLogRecord, policy: PTLogDropPolicy) -> Bool {
        guard count == capacity else {
            values[(head + count) % capacity] = record
            count += 1
            return false
        }

        switch policy {
        case .dropNewest:
            return true
        case .dropOldest:
            values[head] = record
            head = (head + 1) % capacity
            return true
        case .preferImportant:
            if let removableIndex = firstLowPriorityIndex() {
                removeLogicalValue(at: removableIndex)
            } else if record.level < .warning {
                return true
            } else {
                removeLogicalValue(at: 0)
            }
            values[(head + count) % capacity] = record
            count += 1
            return true
        }
    }

    func orderedValues() -> [PTLogRecord] {
        (0..<count).compactMap { values[(head + $0) % capacity] }
    }

    private func firstLowPriorityIndex() -> Int? {
        (0..<count).first { index in
            guard let value = values[(head + index) % capacity] else { return true }
            return value.level < .warning
        }
    }

    private mutating func removeLogicalValue(at index: Int) {
        guard index >= 0, index < count else { return }
        if index < count - 1 {
            for offset in index..<(count - 1) {
                let current = (head + offset) % capacity
                let next = (head + offset + 1) % capacity
                values[current] = values[next]
            }
        }
        values[(head + count - 1) % capacity] = nil
        count -= 1
    }
}

// English: The actor owns the ring buffer and broadcasts immutable records to any number of UI consumers.
// Español: El actor posee el buffer circular y difunde registros inmutables a cualquier número de consumidores UI.
// 中文：actor 独占环形缓冲，并把不可变日志记录广播给任意数量的 UI 消费者。
public actor PTMemoryLogStore {
    private let capacity: Int
    private let dropPolicy: PTLogDropPolicy
    private var buffer: PTMemoryRingBuffer
    private var droppedCount: UInt64 = 0
    private var subscribers: [UUID: AsyncStream<PTLogRecord>.Continuation] = [:]

    public init(capacity: Int = 2_000, dropPolicy: PTLogDropPolicy = .preferImportant) {
        self.capacity = max(1, capacity)
        self.dropPolicy = dropPolicy
        self.buffer = PTMemoryRingBuffer(capacity: max(1, capacity))
    }

    func append(_ record: PTLogRecord) {
        if buffer.append(record, policy: dropPolicy) {
            droppedCount &+= 1
        }
        for continuation in subscribers.values {
            switch continuation.yield(record) {
            case .enqueued, .dropped:
                break
            case .terminated:
                break
            @unknown default:
                break
            }
        }
    }

    func recordExternalDrop() {
        droppedCount &+= 1
    }

    public func snapshot() -> [PTLogRecord] {
        buffer.orderedValues()
    }

    public func clear() {
        buffer = PTMemoryRingBuffer(capacity: capacity)
        droppedCount = 0
    }

    public func backpressureSnapshot() -> PTLogBackpressureSnapshot {
        PTLogBackpressureSnapshot(bufferDroppedCount: droppedCount)
    }

    public func subscribe() -> AsyncStream<PTLogRecord> {
        let identifier = UUID()
        let pair = AsyncStream<PTLogRecord>.makeStream(
            of: PTLogRecord.self,
            bufferingPolicy: .bufferingNewest(5_000)
        )
        subscribers[identifier] = pair.continuation
        pair.continuation.onTermination = { @Sendable [weak self] _ in
            Task { await self?.removeSubscriber(identifier) }
        }
        return pair.stream
    }

    func removeSubscriber(_ identifier: UUID) {
        subscribers.removeValue(forKey: identifier)
    }
}

// English: A single worker drains the bounded queue, so appending a log never creates one task per record.
// Español: Un único worker consume la cola acotada, por lo que añadir un log nunca crea una tarea por registro.
// 中文：由单个 worker 消费有界队列，追加日志不会为每条记录创建 Task。
public final class PTMemoryLogDestination: PTLogDestination, Sendable {
    public static let defaultIdentifier = "ptools.memory"

    public let identifier: String
    private let continuation: AsyncStream<PTMemoryLogEvent>.Continuation
    private let store: PTMemoryLogStore
    private let worker: Task<Void, Never>
    private let queueDropLock = OSAllocatedUnfairLock(initialState: UInt64(0))

    private static func resolve(_ request: PTMemoryFlushRequest?) {
        guard let request else { return }
        Task { await request.resolve() }
    }

    private static func yield(_ event: PTMemoryLogEvent,
                              to continuation: AsyncStream<PTMemoryLogEvent>.Continuation,
                              onDrop: @escaping @Sendable () -> Void) {
        switch continuation.yield(event) {
        case let .dropped(displaced):
            onDrop()
            if case let .flush(request) = displaced {
                resolve(request)
            }
        case .terminated:
            if case let .flush(request) = event {
                resolve(request)
            }
        case .enqueued:
            break
        @unknown default:
            if case let .flush(request) = event {
                resolve(request)
            }
        }
    }

    public init(identifier: String = PTMemoryLogDestination.defaultIdentifier,
                capacity: Int = 2_000,
                queueCapacity: Int = 5_000,
                dropPolicy: PTLogDropPolicy = .preferImportant) {
        self.identifier = identifier
        let store = PTMemoryLogStore(capacity: capacity, dropPolicy: dropPolicy)
        self.store = store
        let pair = AsyncStream<PTMemoryLogEvent>.makeStream(
            of: PTMemoryLogEvent.self,
            bufferingPolicy: .bufferingNewest(max(1, queueCapacity))
        )
        self.continuation = pair.continuation
        self.worker = Task.detached(priority: .utility) {
            for await event in pair.stream {
                switch event {
                case let .record(record):
                    await store.append(PTLogRedactor.redact(record: record))
                case let .flush(request):
                    await request.resolve()
                }
            }
        }
    }

    deinit {
        worker.cancel()
        continuation.finish()
    }

    public func append(_ record: PTLogRecord) {
        Self.yield(.record(record), to: continuation) { [queueDropLock] in
            queueDropLock.withLock { $0 &+= 1 }
        }
    }

    public func flush() async {
        let request = PTMemoryFlushRequest()
        Self.yield(.flush(request), to: continuation) { [queueDropLock] in
            queueDropLock.withLock { $0 &+= 1 }
        }
        await request.wait()
    }

    public func snapshot() async -> [PTLogRecord] {
        await store.snapshot()
    }

    public func clear() async {
        await store.clear()
    }

    public func subscribe() async -> AsyncStream<PTLogRecord> {
        await store.subscribe()
    }

    public func backpressureSnapshot() async -> PTLogBackpressureSnapshot {
        let queueDroppedCount = queueDropLock.withLock { $0 }
        let storeSnapshot = await store.backpressureSnapshot()
        return PTLogBackpressureSnapshot(queueDroppedCount: queueDroppedCount,
                                         bufferDroppedCount: storeSnapshot.bufferDroppedCount)
    }
}
