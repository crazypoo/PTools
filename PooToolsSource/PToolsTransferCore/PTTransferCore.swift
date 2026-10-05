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
    case running
    case paused
    case completed(URL)
    case failed(String)
    case cancelled
}

public struct PTTransferProgress: Sendable, Equatable {
    public let completed: Int64
    public let total: Int64?
    public let fraction: Double

    public init(completed: Int64, total: Int64? = nil, fraction: Double) {
        self.completed = completed
        self.total = total
        self.fraction = min(max(fraction, 0), 1)
    }
}

public enum PTTransferExecutionMode: Sendable, Equatable, Codable {
    case foreground
    case background(identifier: String)
}

public enum PTTransferSource: Sendable, Equatable {
    case download(URL)
    case upload(fileURL: URL, endpoint: URL)
}

public struct PTTransferRequest: Sendable, Equatable {
    public let id: PTTransferID
    public let source: PTTransferSource
    public let destination: URL?
    public let checksum: String?
    public let executionMode: PTTransferExecutionMode

    public init(id: PTTransferID = .init(),
                source: PTTransferSource,
                destination: URL? = nil,
                checksum: String? = nil,
                executionMode: PTTransferExecutionMode = .foreground) {
        self.id = id
        self.source = source
        self.destination = destination
        self.checksum = checksum
        self.executionMode = executionMode
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
}

public protocol PTTransferService: Sendable {
    func enqueue(_ request: PTTransferRequest) async throws -> PTTransferID
    func cancel(_ id: PTTransferID) async
    func events() async -> AsyncStream<PTTransferEvent>
}
