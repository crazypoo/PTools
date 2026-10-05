// English: Offline mutation queue with actor isolation, retries, and conflict policy.
// Español: Cola de mutaciones offline con aislamiento por actor, reintentos y política de conflictos.
// 中文：使用 actor 隔离、重试和冲突策略的离线变更队列。

import Foundation
#if SWIFT_PACKAGE
import PToolsSyncCore
import PToolsDatabase
import PToolsDatabaseCore
import PToolsConnectivity
#endif

public actor PTSyncMemoryStore: PTSyncMutationStore {
    private var values: [UUID: PTSyncMutation] = [:]
    public init() {}
    public func append(_ mutation: PTSyncMutation) { values[mutation.id] = mutation }
    public func pending() -> [PTSyncMutation] { values.values.sorted { $0.createdAt < $1.createdAt } }
    public func remove(_ id: UUID) { values[id] = nil }
}

// English: SQLite-backed mutation storage survives process termination without coupling SyncCore to SQLite.
// Español: El almacenamiento SQLite de mutaciones sobrevive al proceso sin acoplar SyncCore a SQLite.
// 中文：SQLite 变更存储可跨进程重启保留数据，同时不让 SyncCore 依赖 SQLite。
public actor PTSyncDatabaseStore: PTSyncMutationStore {
    private let database: PTDatabase

    public init(database: PTDatabase) async throws {
        self.database = database
        try await database.execute("CREATE TABLE IF NOT EXISTS ptools_sync_mutations (id TEXT PRIMARY KEY, key TEXT NOT NULL, payload BLOB NOT NULL, idempotency_key TEXT NOT NULL, created_at REAL NOT NULL, retry_count INTEGER NOT NULL DEFAULT 0, next_retry_at REAL, last_error TEXT, state TEXT NOT NULL DEFAULT 'pending')")
        // English: Add new queue columns without breaking databases created by the first 5.62 release.
        // Español: Añade columnas nuevas sin romper bases creadas por la primera versión 5.62.
        // 中文：补充新队列字段，同时兼容 5.62 首版已创建的数据库。
        for statement in [
            "ALTER TABLE ptools_sync_mutations ADD COLUMN retry_count INTEGER NOT NULL DEFAULT 0",
            "ALTER TABLE ptools_sync_mutations ADD COLUMN next_retry_at REAL",
            "ALTER TABLE ptools_sync_mutations ADD COLUMN last_error TEXT",
            "ALTER TABLE ptools_sync_mutations ADD COLUMN state TEXT NOT NULL DEFAULT 'pending'"
        ] {
            try? await database.execute(statement)
        }
    }

    public func append(_ mutation: PTSyncMutation) async throws {
        let payload = try JSONEncoder().encode(mutation.payload)
        try await database.execute(PTDatabaseQuery("INSERT OR REPLACE INTO ptools_sync_mutations (id, key, payload, idempotency_key, created_at, retry_count, next_retry_at, last_error, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                                                   arguments: [.text(mutation.id.uuidString),
                                                               .text(mutation.key),
                                                               .blob(payload),
                                                               .text(mutation.idempotencyKey),
                                                               .real(mutation.createdAt.timeIntervalSince1970),
                                                               .integer(Int64(mutation.retryCount)),
                                                               mutation.nextRetryAt.map { .real($0.timeIntervalSince1970) } ?? .null,
                                                               mutation.lastError.map(PTDatabaseValue.text) ?? .null,
                                                               .text(Self.stateValue(mutation.state))]))
    }

    public func pending() async throws -> [PTSyncMutation] {
        let rows = try await database.query("SELECT id, key, payload, idempotency_key, created_at, retry_count, next_retry_at, last_error, state FROM ptools_sync_mutations ORDER BY created_at ASC")
        return try rows.compactMap { row in
            guard case .text(let idString) = row["id"],
                  let id = UUID(uuidString: idString),
                  case .text(let key) = row["key"],
                  case .blob(let payload) = row["payload"],
                  case .text(let idempotencyKey) = row["idempotency_key"],
                  case .real(let createdAt) = row["created_at"] else { return nil }
            let retryCount: Int
            if case .integer(let value) = row["retry_count"] { retryCount = Int(value) } else { retryCount = 0 }
            let nextRetryAt: Date?
            if case .real(let value) = row["next_retry_at"] { nextRetryAt = Date(timeIntervalSince1970: value) } else { nextRetryAt = nil }
            let lastError: String?
            if case .text(let value) = row["last_error"] { lastError = value } else { lastError = nil }
            let state = Self.state(from: row["state"])
            return PTSyncMutation(id: id,
                                  key: key,
                                  payload: try JSONDecoder().decode(Data.self, from: payload),
                                  idempotencyKey: idempotencyKey,
                                  createdAt: Date(timeIntervalSince1970: createdAt),
                                  retryCount: retryCount,
                                  nextRetryAt: nextRetryAt,
                                  lastError: lastError,
                                  state: state)
        }
    }

    public func remove(_ id: UUID) async throws {
        try await database.execute(PTDatabaseQuery("DELETE FROM ptools_sync_mutations WHERE id = ?",
                                                   arguments: [.text(id.uuidString)]))
    }

    private static func stateValue(_ state: PTSyncMutationState) -> String {
        switch state {
        case .pending: return "pending"
        case .syncing: return "syncing"
        case .completed: return "completed"
        case .failed: return "failed"
        }
    }

    private static func state(from value: PTDatabaseValue?) -> PTSyncMutationState {
        guard case .text(let value) = value else { return .pending }
        switch value {
        case "syncing": return .syncing
        case "completed": return .completed
        case "failed": return .failed("Persisted failure")
        default: return .pending
        }
    }
}

public actor PTSyncEngine {
    private let store: any PTSyncMutationStore
    private let remote: any PTSyncRemoteAdapter
    private let policy: PTSyncConflictPolicy
    private let retryPolicy: PTSyncRetryPolicy
    private let conflictResolver: (any PTSyncConflictResolver)?
    private let connectivity: (any PTConnectivityProviding)?
    private var retryCounts: [UUID: Int] = [:]
    private var cursor: String?
    private var checkpoint = PTSyncCheckpoint()
    private var continuations: [UUID: AsyncStream<PTSyncEvent>.Continuation] = [:]

    public init(store: any PTSyncMutationStore = PTSyncMemoryStore(),
                remote: any PTSyncRemoteAdapter,
                policy: PTSyncConflictPolicy = .serverWins,
                retryLimit: Int = 3,
                retryPolicy: PTSyncRetryPolicy? = nil,
                conflictResolver: (any PTSyncConflictResolver)? = nil,
                connectivity: (any PTConnectivityProviding)? = nil) {
        self.store = store
        self.remote = remote
        self.policy = policy
        self.retryPolicy = retryPolicy ?? PTSyncRetryPolicy(maxAttempts: max(1, retryLimit))
        self.conflictResolver = conflictResolver
        self.connectivity = connectivity
    }

    public func enqueue(_ mutation: PTSyncMutation) async throws {
        try await store.append(mutation)
        publish(.enqueued(mutation))
        publish(.stateChanged(mutation.id, .pending))
        let queueCount = (try? await store.pending())?.count ?? 0
        publish(.queueChanged(queueCount))
    }

    public func sync() async -> [PTSyncResult] {
        if let connectivity, !(await connectivity.current().isReachable) { return [] }
        publish(.syncStarted)
        let pending = ((try? await store.pending()) ?? []).filter { mutation in
            guard let nextRetryAt = mutation.nextRetryAt else { return true }
            return nextRetryAt <= .now
        }
        var results: [PTSyncResult] = []
        for mutation in pending {
            publish(.stateChanged(mutation.id, .syncing))
            do {
                try await pushWithRetry(mutation)
                try await store.remove(mutation.id)
                retryCounts[mutation.id] = nil
                let result = PTSyncResult(mutationID: mutation.id, state: .completed)
                results.append(result)
                publish(.completed(result))
            } catch let error as PTSyncError where error == .conflict {
                let conflict = PTSyncConflict(local: mutation)
                publish(.conflict(conflict))
                if let conflictResolver,
                   let resolved = try? await conflictResolver.resolve(conflict) {
                    try? await store.remove(mutation.id)
                    try? await store.append(resolved)
                    publish(.stateChanged(mutation.id, .pending))
                    continue
                }
                switch policy {
                case .serverWins:
                    try? await store.remove(mutation.id)
                    let result = PTSyncResult(mutationID: mutation.id, state: .completed)
                    results.append(result)
                    publish(.completed(result))
                case .clientWins:
                    let result = PTSyncResult(mutationID: mutation.id, state: .failed("Conflict requires client-wins remote support"))
                    results.append(result)
                    publish(.completed(result))
                case .latestWins:
                    let result = PTSyncResult(mutationID: mutation.id, state: .failed("Latest-wins requires a server revision"))
                    results.append(result)
                    publish(.completed(result))
                case .fail:
                    let result = PTSyncResult(mutationID: mutation.id, state: .failed(String(describing: error)))
                    results.append(result)
                    publish(.completed(result))
                }
            } catch {
                let count = max(mutation.retryCount, retryCounts[mutation.id, default: 0]) + 1
                retryCounts[mutation.id] = count
                let state: PTSyncMutationState = count >= retryPolicy.maxAttempts ? .failed(String(describing: error)) : .pending
                let nextRetryAt = count >= retryPolicy.maxAttempts ? nil : Date.now.addingTimeInterval(retryDelay(attempt: count, error: error))
                let updated = PTSyncMutation(id: mutation.id,
                                             key: mutation.key,
                                             payload: mutation.payload,
                                             idempotencyKey: mutation.idempotencyKey,
                                             createdAt: mutation.createdAt,
                                             retryCount: count,
                                             nextRetryAt: nextRetryAt,
                                             lastError: String(describing: error),
                                             state: state)
                try? await store.append(updated)
                let result = PTSyncResult(mutationID: mutation.id, state: state)
                results.append(result)
                publish(.stateChanged(mutation.id, state))
                if let nextRetryAt { publish(.retryScheduled(mutation.id, nextRetryAt)) }
                else { publish(.failed(mutation.id, String(describing: error))) }
                publish(.completed(result))
            }
        }
        return results
    }

    public func pull() async throws -> PTSyncPullPage {
        let page = try await remote.pull(cursor: cursor)
        cursor = page.nextCursor ?? cursor
        checkpoint = PTSyncCheckpoint(cursor: cursor,
                                      pageToken: page.pageToken,
                                      etag: page.etag,
                                      deltaToken: page.deltaToken,
                                      updatedAt: page.receivedAt)
        publish(.pulled(page))
        publish(.checkpointUpdated(checkpoint))
        for mutation in page.mutations { try await store.append(mutation) }
        return page
    }

    public func syncAndPull() async throws -> [PTSyncResult] {
        _ = try await pull()
        return await sync()
    }

    public func events() -> AsyncStream<PTSyncEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    public func currentCursor() -> String? { cursor }

    public func currentCheckpoint() -> PTSyncCheckpoint { checkpoint }

    public func syncWhenReachable() async -> [PTSyncResult] {
        guard let connectivity else { return await sync() }
        let snapshots = await connectivity.snapshots()
        for await snapshot in snapshots {
            guard !Task.isCancelled else { return [] }
            if snapshot.isReachable { return await sync() }
        }
        return []
    }

    private func pushWithRetry(_ mutation: PTSyncMutation) async throws {
        var attempt = 0
        while true {
            do {
                try await remote.push(mutation)
                return
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                attempt += 1
                guard attempt < retryPolicy.maxAttempts else { throw error }
                let delay = retryDelay(attempt: attempt, error: error)
                try await Task.sleep(for: .seconds(delay))
            }
        }
    }

    private func publish(_ event: PTSyncEvent) {
        continuations.values.forEach { $0.yield(event) }
    }

    private func removeContinuation(_ id: UUID) { continuations[id] = nil }

    private func retryDelay(attempt: Int, error: Error) -> Double {
        if case let PTSyncError.retryAfter(duration) = error {
            return min(seconds(duration), seconds(retryPolicy.maxDelay))
        }
        let multiplier = pow(2, Double(max(0, attempt - 1)))
        let base = min(seconds(retryPolicy.baseDelay) * multiplier, seconds(retryPolicy.maxDelay))
        let jitter = base * retryPolicy.jitterRatio
        return max(0, base + Double.random(in: -jitter...jitter))
    }

    private func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
    }
}
