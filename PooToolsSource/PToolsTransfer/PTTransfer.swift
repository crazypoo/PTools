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
    private var downloadControllers: [PTTransferID: PTTransferDownloadController] = [:]
    private var states: [PTTransferID: PTTransferState] = [:]
    private var requests: [PTTransferID: PTTransferRequest] = [:]
    private var progress: [PTTransferID: PTTransferProgress] = [:]
    private var continuations: [UUID: AsyncStream<PTTransferEvent>.Continuation] = [:]
    private let resumeStore: (any PTTransferResumeStore)?
    private var progressStartedAt: [PTTransferID: Date] = [:]

    public init(resumeStore: (any PTTransferResumeStore)? = nil) {
        self.resumeStore = resumeStore
    }

    public func enqueue(_ request: PTTransferRequest) async throws -> PTTransferID {
        if case .download = request.source {
            // English: Download destinations may be omitted so URLSession can own the temporary file.
            // Español: El destino de una descarga puede omitirse para que URLSession gestione el temporal.
            // 中文：下载可以不指定目标路径，让 URLSession 管理临时文件。
        } else if request.destination == nil {
            throw PTTransferError.invalidRequest
        }
        requests[request.id] = request
        states[request.id] = .queued
        publish(.stateChanged(request.id, .queued))
        states[request.id] = .preparing
        publish(.stateChanged(request.id, .preparing))
        let task: Task<URL, Error>
        if case .download = request.source {
            let storedResumeData = try? await resumeStore?.load(for: request.id)
            let controller = PTTransferDownloadController(request: request,
                                                           resumeData: storedResumeData ?? nil,
                                                           session: Self.makeSession(for: request.executionMode,
                                                                                     policy: request.policy)) { [weak self] written, completed, expected in
                Task { await self?.updateProgress(id: request.id,
                                                  written: written,
                                                  completed: completed,
                                                  expected: expected) }
            }
            downloadControllers[request.id] = controller
            controller.start()
            task = Task(priority: request.priority.taskPriority) { try await controller.value() }
        } else {
            task = Task(priority: request.priority.taskPriority) { [request] in try await Self.perform(request) }
        }
        tasks[request.id] = task
        states[request.id] = .running
        publish(.stateChanged(request.id, .running))
        let initial = PTTransferProgress(completed: 0, fraction: 0)
        progress[request.id] = initial
        publish(.progress(request.id, initial))
        return request.id
    }

    public func wait(for id: PTTransferID) async throws -> URL {
        guard let task = tasks[id] else { throw PTTransferError.destinationUnavailable }
        do {
            let url = try await task.value
            states[id] = .completed(url)
            publish(.stateChanged(id, .completed(url)))
            let final = PTTransferProgress(completed: 1, fraction: 1)
            progress[id] = final
            publish(.progress(id, final))
            tasks[id] = nil
            downloadControllers[id] = nil
            progressStartedAt[id] = nil
            try? await resumeStore?.remove(for: id)
            return url
        } catch is CancellationError {
            if states[id] != .paused {
                states[id] = .cancelled
                publish(.stateChanged(id, .cancelled))
                downloadControllers[id] = nil
                progressStartedAt[id] = nil
                try? await resumeStore?.remove(for: id)
            }
            tasks[id] = nil
            throw states[id] == .paused ? PTTransferError.paused : PTTransferError.cancelled
        } catch {
            states[id] = .failed(String(describing: error))
            publish(.stateChanged(id, .failed(String(describing: error))))
            tasks[id] = nil
            downloadControllers[id] = nil
            progressStartedAt[id] = nil
            throw PTTransferError.failed(String(describing: error))
        }
    }

    public func cancel(_ id: PTTransferID) async {
        downloadControllers[id]?.cancel()
        tasks[id]?.cancel()
        states[id] = .cancelled
        try? await resumeStore?.remove(for: id)
        publish(.stateChanged(id, .cancelled))
    }

    public func pause(_ id: PTTransferID) async {
        guard tasks[id] != nil, states[id] == .running else { return }
        states[id] = .pausing
        publish(.stateChanged(id, .pausing))
        if let controller = downloadControllers[id] {
            if let data = await controller.pause() {
                try? await resumeStore?.save(data, for: id)
            } else {
                try? await resumeStore?.remove(for: id)
            }
        } else {
            tasks[id]?.cancel()
        }
        states[id] = .paused
        publish(.stateChanged(id, .paused))
    }

    public func resume(_ id: PTTransferID) async throws {
        guard let request = requests[id], states[id] == .paused else { throw PTTransferError.invalidRequest }
        states[id] = .resuming
        publish(.stateChanged(id, .resuming))
        let task: Task<URL, Error>
        if let controller = downloadControllers[id] {
            controller.resume()
            task = Task(priority: request.priority.taskPriority) { try await controller.value() }
        } else {
            task = Task(priority: request.priority.taskPriority) { [request] in try await Self.perform(request) }
        }
        tasks[id] = task
        states[id] = .running
        publish(.stateChanged(id, .running))
    }

    public func pauseAll() async {
        for id in tasks.keys { await pause(id) }
    }

    public func resumeAll() async {
        for id in requests.keys where states[id] == .paused {
            try? await resume(id)
        }
    }

    public func cancelAll() async {
        for id in tasks.keys { await cancel(id) }
    }

    public func retry(_ id: PTTransferID) async throws {
        guard let request = requests[id], states[id].map({ if case .failed = $0 { true } else { false } }) == true else {
            throw PTTransferError.invalidRequest
        }
        states[id] = .retrying(attempt: 1)
        publish(.stateChanged(id, .retrying(attempt: 1)))
        let task = Task(priority: request.priority.taskPriority) { [request] in try await Self.perform(request) }
        tasks[id] = task
        states[id] = .running
        publish(.stateChanged(id, .running))
    }

    public func state(for id: PTTransferID) -> PTTransferState? { states[id] }

    public func snapshot(for id: PTTransferID) -> PTTransferSnapshot? {
        guard let request = requests[id], let state = states[id] else { return nil }
        return PTTransferSnapshot(request: request,
                                  state: state,
                                  progress: progress[id] ?? .init(completed: 0, fraction: 0))
    }

    public func runtimeSnapshot(for id: PTTransferID) -> PTTransferRuntimeSnapshot? {
        guard let state = states[id] else { return nil }
        return PTTransferRuntimeSnapshot(id: id,
                                         state: state,
                                         progress: progress[id] ?? .init(completed: 0, fraction: 0),
                                         canResume: state == .paused)
    }

    private func updateProgress(id: PTTransferID,
                                written: Int64,
                                completed: Int64,
                                expected: Int64) {
        let startedAt = progressStartedAt[id] ?? .now
        progressStartedAt[id] = startedAt
        let total = expected > 0 ? expected : nil
        let fraction = total.map { Double(completed) / Double($0) } ?? 0
        let elapsed = max(0.001, Date.now.timeIntervalSince(startedAt))
        let rate = Double(completed) / elapsed
        let remaining = total.flatMap { rate > 0 ? Duration.seconds(Double(max(0, $0 - completed)) / rate) : nil }
        let value = PTTransferProgress(completed: completed,
                                       total: total,
                                       fraction: fraction,
                                       bytesPerSecond: rate,
                                       estimatedRemaining: remaining)
        progress[id] = value
        publish(.progress(id, value))
        _ = written
    }

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
        var attempt = 0
        while true {
            do {
                return try await performOnce(request)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                attempt += 1
                guard attempt < request.retryPolicy.maxAttempts else { throw error }
                let multiplier = pow(2, Double(attempt - 1))
                let base = seconds(request.retryPolicy.baseDelay) * multiplier
                let delay = min(base, seconds(request.retryPolicy.maxDelay))
                try await Task.sleep(for: .seconds(delay))
            }
        }
    }

    private static func performOnce(_ request: PTTransferRequest) async throws -> URL {
        let session = makeSession(for: request.executionMode, policy: request.policy)
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
            guard let destination = request.destination else { throw PTTransferError.destinationUnavailable }
            output = destination
        case .uploadData(let data, let endpoint):
            var uploadRequest = URLRequest(url: endpoint)
            uploadRequest.httpMethod = "POST"
            _ = try await session.upload(for: uploadRequest, from: data)
            guard let destination = request.destination else { throw PTTransferError.destinationUnavailable }
            try data.write(to: destination, options: .atomic)
            output = destination
        case .uploadMultipart(let parts, let endpoint):
            var uploadRequest = URLRequest(url: endpoint)
            uploadRequest.httpMethod = "POST"
            let boundary = "PTools-\(UUID().uuidString)"
            uploadRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            let body = multipartBody(parts: parts, boundary: boundary)
            _ = try await session.upload(for: uploadRequest, from: body)
            guard let destination = request.destination else { throw PTTransferError.destinationUnavailable }
            try body.write(to: destination, options: .atomic)
            output = destination
        }
        if let checksum = request.checksum {
            let sourceURL: URL
            if case .upload(fileURL: let fileURL, endpoint: _) = request.source { sourceURL = fileURL }
            else { sourceURL = output }
            let calculated = try streamingChecksum(for: sourceURL)
            guard calculated.caseInsensitiveCompare(checksum) == .orderedSame else {
                throw PTTransferError.checksumMismatch
            }
        }
        return output
    }

    // English: Apply network and Low Data Mode policy at session construction time.
    // Español: Aplica la política de red y Low Data Mode al crear la sesión.
    // 中文：在创建 URLSession 时一次性应用网络和低数据模式策略。
    static func makeSession(for mode: PTTransferExecutionMode,
                            policy: PTTransferPolicy) -> URLSession {
        #if os(iOS)
        if case .background(let identifier) = mode {
            let configuration = PTBackgroundTransferCapability(identifier: identifier).makeConfiguration()
            configuration.allowsCellularAccess = policy.allowsCellular
            configuration.waitsForConnectivity = policy.waitsForConnectivity
            if #available(iOS 13.0, *) {
                configuration.allowsExpensiveNetworkAccess = policy.allowsExpensiveNetwork
                configuration.allowsConstrainedNetworkAccess = policy.allowsConstrainedNetwork
            }
            return URLSession(configuration: configuration)
        }
        #endif
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = policy.allowsCellular
        configuration.waitsForConnectivity = policy.waitsForConnectivity
        if #available(iOS 13.0, macOS 10.15, *) {
            configuration.allowsExpensiveNetworkAccess = policy.allowsExpensiveNetwork
            configuration.allowsConstrainedNetworkAccess = policy.allowsConstrainedNetwork
        }
        return URLSession(configuration: configuration)
    }

    private static func streamingChecksum(for url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            let chunk = try handle.read(upToCount: 64 * 1024) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func multipartBody(parts: [PTTransferMultipartPart], boundary: String) -> Data {
        var body = Data()
        for part in parts {
            body.append(Data("--\(boundary)\r\n".utf8))
            var disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let filename = part.filename { disposition += "; filename=\"\(filename)\"" }
            body.append(Data("\(disposition)\r\n".utf8))
            if let contentType = part.contentType { body.append(Data("Content-Type: \(contentType)\r\n".utf8)) }
            body.append(Data("\r\n".utf8))
            body.append(part.data)
            body.append(Data("\r\n".utf8))
        }
        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }

    private static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
    }
}

private extension PTTransferPriority {
    var taskPriority: TaskPriority {
        switch self {
        case .low: return .low
        case .normal: return .medium
        case .high: return .high
        }
    }
}
