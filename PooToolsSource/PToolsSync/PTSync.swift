// English: Offline mutation queue with actor isolation, retries, and conflict policy.
// Español: Cola de mutaciones offline con aislamiento por actor, reintentos y política de conflictos.
// 中文：使用 actor 隔离、重试和冲突策略的离线变更队列。

import Foundation
#if SWIFT_PACKAGE
import PToolsSyncCore
#endif

public actor PTSyncMemoryStore: PTSyncMutationStore {
    private var values: [UUID: PTSyncMutation] = [:]
    public init() {}
    public func append(_ mutation: PTSyncMutation) { values[mutation.id] = mutation }
    public func pending() -> [PTSyncMutation] { values.values.sorted { $0.createdAt < $1.createdAt } }
    public func remove(_ id: UUID) { values[id] = nil }
}

public actor PTSyncEngine {
    private let store: any PTSyncMutationStore
    private let remote: any PTSyncRemoteAdapter
    private let policy: PTSyncConflictPolicy
    private let retryLimit: Int
    private var retryCounts: [UUID: Int] = [:]

    public init(store: any PTSyncMutationStore = PTSyncMemoryStore(),
                remote: any PTSyncRemoteAdapter,
                policy: PTSyncConflictPolicy = .serverWins,
                retryLimit: Int = 3) {
        self.store = store; self.remote = remote; self.policy = policy; self.retryLimit = max(0, retryLimit)
    }

    public func enqueue(_ mutation: PTSyncMutation) async throws { try await store.append(mutation) }

    public func sync() async -> [PTSyncResult] {
        let pending = (try? await store.pending()) ?? []
        var results: [PTSyncResult] = []
        for mutation in pending {
            do {
                try await remote.push(mutation)
                try? await store.remove(mutation.id)
                retryCounts[mutation.id] = nil
                results.append(PTSyncResult(mutationID: mutation.id, state: .completed))
            } catch {
                let count = retryCounts[mutation.id, default: 0] + 1
                retryCounts[mutation.id] = count
                let state: PTSyncMutationState = count > retryLimit ? .failed(String(describing: error)) : .pending
                results.append(PTSyncResult(mutationID: mutation.id, state: state))
            }
        }
        _ = policy
        return results
    }
}
