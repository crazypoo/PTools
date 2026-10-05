// English: Foundation-only offline synchronization contracts with idempotency metadata.
// Español: Contratos solo de Foundation para sincronización offline con metadatos de idempotencia.
// 中文：带幂等元数据的离线同步 Foundation-only 契约。

import Foundation

public struct PTSyncMutation: Codable, Hashable, Sendable {
    public let id: UUID
    public let key: String
    public let payload: Data
    public let idempotencyKey: String
    public let createdAt: Date

    public init(id: UUID = UUID(), key: String, payload: Data, idempotencyKey: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.key = key
        self.payload = payload
        self.idempotencyKey = idempotencyKey ?? id.uuidString
        self.createdAt = createdAt
    }
}

public enum PTSyncConflictPolicy: Sendable, Equatable {
    case serverWins
    case clientWins
    case fail
}

public enum PTSyncMutationState: Sendable, Equatable {
    case pending
    case syncing
    case completed
    case failed(String)
}

public struct PTSyncResult: Sendable, Equatable {
    public let mutationID: UUID
    public let state: PTSyncMutationState
    public init(mutationID: UUID, state: PTSyncMutationState) {
        self.mutationID = mutationID
        self.state = state
    }
}

public enum PTSyncError: Error, Sendable, Equatable {
    case conflict
    case retryLimitReached
    case remoteFailed(String)
    case storageFailed
}

public protocol PTSyncRemoteAdapter: Sendable {
    func push(_ mutation: PTSyncMutation) async throws
}

public protocol PTSyncMutationStore: Sendable {
    func append(_ mutation: PTSyncMutation) async throws
    func pending() async throws -> [PTSyncMutation]
    func remove(_ id: UUID) async throws
}
