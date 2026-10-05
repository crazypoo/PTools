// English: Actor-backed transfer queue with cancellation, progress events, and checksums.
// Español: Cola de transferencias basada en actor con cancelación, eventos de progreso y checksums.
// 中文：基于 actor 的传输队列，支持取消、进度事件和校验和。

import Foundation
import CryptoKit
#if SWIFT_PACKAGE
import PToolsTransferCore
#endif

public struct PTBackgroundTransferCapability: Sendable, Equatable {
    public let identifier: String
    public init(identifier: String) { self.identifier = identifier }

    #if os(iOS)
    public func makeConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.waitsForConnectivity = true
        configuration.sessionSendsLaunchEvents = true
        return configuration
    }
    #endif
}

public actor PTTransferQueue: PTTransferService {
    private var tasks: [PTTransferID: Task<URL, Error>] = [:]
    private var states: [PTTransferID: PTTransferState] = [:]
    private var continuations: [UUID: AsyncStream<PTTransferEvent>.Continuation] = [:]

    public init() {}

    public func enqueue(_ request: PTTransferRequest) async throws -> PTTransferID {
        switch request.source {
        case .download where request.destination == nil, .upload where request.destination == nil:
            if case .download = request.source { break }
            throw PTTransferError.invalidRequest
        default:
            break
        }
        states[request.id] = .queued
        publish(.stateChanged(request.id, .queued))
        let task = Task { [request] in try await Self.perform(request) }
        tasks[request.id] = task
        states[request.id] = .running
        publish(.stateChanged(request.id, .running))
        publish(.progress(request.id, PTTransferProgress(completed: 0, fraction: 0)))
        return request.id
    }

    public func wait(for id: PTTransferID) async throws -> URL {
        guard let task = tasks[id] else { throw PTTransferError.destinationUnavailable }
        do {
            let url = try await task.value
            states[id] = .completed(url)
            publish(.stateChanged(id, .completed(url)))
            publish(.progress(id, PTTransferProgress(completed: 1, fraction: 1)))
            tasks[id] = nil
            return url
        } catch is CancellationError {
            states[id] = .cancelled
            publish(.stateChanged(id, .cancelled))
            tasks[id] = nil
            throw PTTransferError.cancelled
        } catch {
            states[id] = .failed(String(describing: error))
            publish(.stateChanged(id, .failed(String(describing: error))))
            tasks[id] = nil
            throw PTTransferError.failed(String(describing: error))
        }
    }

    public func cancel(_ id: PTTransferID) async {
        tasks[id]?.cancel()
        states[id] = .cancelled
        publish(.stateChanged(id, .cancelled))
    }

    public func state(for id: PTTransferID) -> PTTransferState? { states[id] }

    public func events() async -> AsyncStream<PTTransferEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    private func publish(_ event: PTTransferEvent) { continuations.values.forEach { $0.yield(event) } }
    private func removeContinuation(_ id: UUID) { continuations[id] = nil }

    private static func perform(_ request: PTTransferRequest) async throws -> URL {
        let session = makeSession(for: request.executionMode)
        let output: URL
        switch request.source {
        case .download(let url):
            let (temporary, _) = try await session.download(from: url)
            output = request.destination ?? temporary
            if output != temporary {
                let parent = output.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
                if FileManager.default.fileExists(atPath: output.path) { try FileManager.default.removeItem(at: output) }
                try FileManager.default.moveItem(at: temporary, to: output)
            }
        case .upload(let fileURL, let endpoint):
            var uploadRequest = URLRequest(url: endpoint)
            uploadRequest.httpMethod = "POST"
            _ = try await session.upload(for: uploadRequest, fromFile: fileURL)
            output = fileURL
        }
        if let checksum = request.checksum {
            let sourceURL: URL
            if case .upload(let fileURL, _) = request.source { sourceURL = fileURL }
            else { sourceURL = output }
            let data = try Data(contentsOf: sourceURL)
            let calculated = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard calculated.caseInsensitiveCompare(checksum) == .orderedSame else {
                throw PTTransferError.checksumMismatch
            }
        }
        return output
    }

    private static func makeSession(for mode: PTTransferExecutionMode) -> URLSession {
        #if os(iOS)
        if case .background(let identifier) = mode {
            return URLSession(configuration: PTBackgroundTransferCapability(identifier: identifier).makeConfiguration())
        }
        #endif
        return .shared
    }
}
