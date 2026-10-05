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
    public let retryCount: Int
    public let nextRetryAt: Date?
    public let lastError: String?
    public let state: PTSyncMutationState

    public init(id: UUID = UUID(),
                key: String,
                payload: Data,
                idempotencyKey: String? = nil,
                createdAt: Date = .now,
                retryCount: Int = 0,
                nextRetryAt: Date? = nil,
                lastError: String? = nil,
                state: PTSyncMutationState = .pending) {
        self.id = id
        self.key = key
        self.payload = payload
        self.idempotencyKey = idempotencyKey ?? id.uuidString
        self.createdAt = createdAt
        self.retryCount = max(0, retryCount)
        self.nextRetryAt = nextRetryAt
        self.lastError = lastError
        self.state = state
    }
}

public enum PTSyncConflictPolicy: Sendable, Equatable {
    case serverWins
    case clientWins
    case latestWins
    case fail
}

public enum PTSyncMutationState: Codable, Sendable, Equatable, Hashable {
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

public struct PTSyncConflict: Sendable, Equatable {
    public let local: PTSyncMutation
    public let message: String
    public init(local: PTSyncMutation, message: String = "Conflict") {
        self.local = local
        self.message = message
    }
}

public protocol PTSyncConflictResolver: Sendable {
    func resolve(_ conflict: PTSyncConflict) async throws -> PTSyncMutation?
}

public enum PTSyncError: Error, Sendable, Equatable {
    case conflict
    case retryAfter(Duration)
    case retryLimitReached
    case remoteFailed(String)
    case storageFailed
    case transportFailed(String)
}

public struct PTSyncRetryPolicy: Sendable, Equatable {
    public let maxAttempts: Int
    public let baseDelay: Duration
    public let maxDelay: Duration
    public let jitterRatio: Double
    public init(maxAttempts: Int = 3,
                baseDelay: Duration = .milliseconds(250),
                maxDelay: Duration = .seconds(8),
                jitterRatio: Double = 0.2) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitterRatio = min(max(jitterRatio, 0), 1)
    }
}

public struct PTSyncPullPage: Sendable, Equatable {
    public let mutations: [PTSyncMutation]
    public let nextCursor: String?
    public let hasMore: Bool
    public let pageToken: String?
    public let etag: String?
    public let deltaToken: String?
    public let receivedAt: Date
    public init(mutations: [PTSyncMutation],
                nextCursor: String? = nil,
                hasMore: Bool = false,
                pageToken: String? = nil,
                etag: String? = nil,
                deltaToken: String? = nil,
                receivedAt: Date = .now) {
        self.mutations = mutations
        self.nextCursor = nextCursor
        self.hasMore = hasMore
        self.pageToken = pageToken
        self.etag = etag
        self.deltaToken = deltaToken
        self.receivedAt = receivedAt
    }
}

public struct PTSyncCheckpoint: Codable, Sendable, Equatable {
    public let cursor: String?
    public let pageToken: String?
    public let etag: String?
    public let deltaToken: String?
    public let updatedAt: Date

    public init(cursor: String? = nil,
                pageToken: String? = nil,
                etag: String? = nil,
                deltaToken: String? = nil,
                updatedAt: Date = .now) {
        self.cursor = cursor
        self.pageToken = pageToken
        self.etag = etag
        self.deltaToken = deltaToken
        self.updatedAt = updatedAt
    }
}

public enum PTSyncEvent: Sendable, Equatable {
    case enqueued(PTSyncMutation)
    case queueChanged(Int)
    case syncStarted
    case stateChanged(UUID, PTSyncMutationState)
    case pulled(PTSyncPullPage)
    case checkpointUpdated(PTSyncCheckpoint)
    case retryScheduled(UUID, Date)
    case conflict(PTSyncConflict)
    case completed(PTSyncResult)
    case failed(UUID, String)
}

public protocol PTSyncRemoteAdapter: Sendable {
    func push(_ mutation: PTSyncMutation) async throws
    func pull(cursor: String?) async throws -> PTSyncPullPage
}

public extension PTSyncRemoteAdapter {
    func pull(cursor: String?) async throws -> PTSyncPullPage {
        PTSyncPullPage(mutations: [], nextCursor: cursor, hasMore: false)
    }
}

public protocol PTSyncMutationStore: Sendable {
    func append(_ mutation: PTSyncMutation) async throws
    func pending() async throws -> [PTSyncMutation]
    func remove(_ id: UUID) async throws
}
