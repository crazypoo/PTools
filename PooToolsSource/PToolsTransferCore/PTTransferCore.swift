// English: Foundation-only transfer contracts for foreground and background queues.
// Español: Contratos solo de Foundation para colas de transferencia en primer y segundo plano.
// 中文：前台与后台传输队列的 Foundation-only 契约。

import Foundation

public struct PTTransferID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: UUID
    public init(_ rawValue: UUID = UUID()) { self.rawValue = rawValue }
    public var description: String { rawValue.uuidString }
}

public enum PTTransferState: Codable, Sendable, Equatable {
    case queued
    case preparing
    case running
    case pausing
    case paused
    case resuming
    case retrying(attempt: Int)
    case completed(URL)
    case failed(String)
    case cancelled
}

public struct PTTransferProgress: Sendable, Equatable {
    public let completed: Int64
    public let total: Int64?
    public let fraction: Double
    public let bytesPerSecond: Double?
    public let estimatedRemaining: Duration?

    public init(completed: Int64,
                total: Int64? = nil,
                fraction: Double,
                bytesPerSecond: Double? = nil,
                estimatedRemaining: Duration? = nil) {
        self.completed = completed
        self.total = total
        self.fraction = min(max(fraction, 0), 1)
        self.bytesPerSecond = bytesPerSecond
        self.estimatedRemaining = estimatedRemaining
    }
}

public enum PTTransferPriority: Int, Sendable, Codable, Comparable {
    case low = 0
    case normal = 50
    case high = 100

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct PTTransferRetryPolicy: Sendable, Codable, Equatable {
    public let maxAttempts: Int
    public let baseDelay: Duration
    public let maxDelay: Duration
    public init(maxAttempts: Int = 3,
                baseDelay: Duration = .milliseconds(250),
                maxDelay: Duration = .seconds(8)) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }
}

public struct PTTransferPolicy: Sendable, Codable, Equatable {
    public let maxConcurrent: Int
    public let allowsCellular: Bool
    public let waitsForConnectivity: Bool
    public let allowsExpensiveNetwork: Bool
    public let allowsConstrainedNetwork: Bool
    public let pausesInLowPowerMode: Bool

    public init(maxConcurrent: Int = 3,
                allowsCellular: Bool = true,
                waitsForConnectivity: Bool = true,
                allowsExpensiveNetwork: Bool = true,
                allowsConstrainedNetwork: Bool = true,
                pausesInLowPowerMode: Bool = false) {
        self.maxConcurrent = min(max(1, maxConcurrent), 32)
        self.allowsCellular = allowsCellular
        self.waitsForConnectivity = waitsForConnectivity
        self.allowsExpensiveNetwork = allowsExpensiveNetwork
        self.allowsConstrainedNetwork = allowsConstrainedNetwork
        self.pausesInLowPowerMode = pausesInLowPowerMode
    }
}

public enum PTTransferDestination: Sendable, Equatable, Codable {
    case file(URL)
    case temporary
}

public struct PTTransferMultipartPart: Sendable, Equatable {
    public let name: String
    public let filename: String?
    public let contentType: String?
    public let data: Data
    public init(name: String, filename: String? = nil, contentType: String? = nil, data: Data) {
        self.name = name
        self.filename = filename
        self.contentType = contentType
        self.data = data
    }
}

public enum PTTransferExecutionMode: Sendable, Equatable, Codable {
    case foreground
    case background(identifier: String)
}

public enum PTTransferSource: Sendable, Equatable {
    case download(URL)
    case upload(fileURL: URL, endpoint: URL)
    case uploadData(data: Data, endpoint: URL)
    case uploadMultipart(parts: [PTTransferMultipartPart], endpoint: URL)
}

public struct PTTransferRequest: Sendable, Equatable {
    public let id: PTTransferID
    public let source: PTTransferSource
    public let destination: URL?
    public let checksum: String?
    public let executionMode: PTTransferExecutionMode
    public let priority: PTTransferPriority
    public let retryPolicy: PTTransferRetryPolicy
    public let policy: PTTransferPolicy

    public init(id: PTTransferID = .init(),
                source: PTTransferSource,
                destination: URL? = nil,
                checksum: String? = nil,
                executionMode: PTTransferExecutionMode = .foreground,
                priority: PTTransferPriority = .normal,
                retryPolicy: PTTransferRetryPolicy = .init(),
                policy: PTTransferPolicy = .init()) {
        self.id = id
        self.source = source
        self.destination = destination
        self.checksum = checksum
        self.executionMode = executionMode
        self.priority = priority
        self.retryPolicy = retryPolicy
        self.policy = policy
    }
}

public struct PTTransferSnapshot: Sendable, Equatable {
    public let request: PTTransferRequest
    public let state: PTTransferState
    public let progress: PTTransferProgress
    public let updatedAt: Date
    public init(request: PTTransferRequest,
                state: PTTransferState,
                progress: PTTransferProgress = .init(completed: 0, fraction: 0),
                updatedAt: Date = .now) {
        self.request = request
        self.state = state
        self.progress = progress
        self.updatedAt = updatedAt
    }
}

public struct PTTransferRuntimeSnapshot: Sendable, Equatable {
    public let id: PTTransferID
    public let state: PTTransferState
    public let progress: PTTransferProgress
    public let retryCount: Int
    public let canResume: Bool
    public let updatedAt: Date

    public init(id: PTTransferID,
                state: PTTransferState,
                progress: PTTransferProgress,
                retryCount: Int = 0,
                canResume: Bool = false,
                updatedAt: Date = .now) {
        self.id = id
        self.state = state
        self.progress = progress
        self.retryCount = max(0, retryCount)
        self.canResume = canResume
        self.updatedAt = updatedAt
    }
}

public enum PTTransferEvent: Sendable, Equatable {
    case stateChanged(PTTransferID, PTTransferState)
    case progress(PTTransferID, PTTransferProgress)
}

public enum PTTransferError: Error, Sendable, Equatable {
    case invalidRequest
    case destinationUnavailable
    case checksumMismatch
    case failed(String)
    case cancelled
    case paused
    case retryLimitReached
    case invalidResumeData
    case backgroundUnavailable
}

public protocol PTTransferResumeStore: Sendable {
    func load(for id: PTTransferID) async throws -> Data?
    func save(_ data: Data, for id: PTTransferID) async throws
    func remove(for id: PTTransferID) async throws
}

public protocol PTTransferService: Sendable {
    func enqueue(_ request: PTTransferRequest) async throws -> PTTransferID
    func cancel(_ id: PTTransferID) async
    func events() async -> AsyncStream<PTTransferEvent>
}

public extension PTTransferService {
    func pause(_ id: PTTransferID) async {}
    func resume(_ id: PTTransferID) async throws { throw PTTransferError.paused }
}
