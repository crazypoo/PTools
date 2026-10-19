// English: Foundation-only file downloading is the single foreground executor for Network and media caches.
// Español: La descarga de archivos basada solo en Foundation es el único ejecutor de primer plano para Network y las cachés multimedia.
// 中文：仅依赖 Foundation 的文件下载器是 Network 与媒体缓存共用的前台唯一执行器。

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public typealias PTTransferProgressHandler = @Sendable (PTTransferProgress) async -> Void

public struct PTTransferDownloadResult: Sendable, Equatable {
    public let fileURL: URL
    public let statusCode: Int?
    public let headers: [String: String]

    public init(fileURL: URL,
                statusCode: Int? = nil,
                headers: [String: String] = [:]) {
        self.fileURL = fileURL
        self.statusCode = statusCode
        self.headers = headers
    }
}

/// The shared foreground file executor. Each subscriber owns cancellation independently.
/// El ejecutor compartido de archivos en primer plano. Cada suscriptor posee su propia cancelación.
/// 共享的前台文件执行器，每个订阅者独立拥有取消权。
public actor PTTransferFileDownloadService {
    public static let shared = PTTransferFileDownloadService()

    private struct DownloadKey: Hashable, Sendable {
        let source: URL
        let destination: URL
        let headers: [String: String]
        let allowsResume: Bool
        let retryPolicy: PTTransferRetryPolicy
        let policy: PTTransferPolicy
        let configuration: PTTransferDownloadConfiguration
    }

    private struct ActiveDownload {
        let task: Task<PTTransferDownloadResult, Error>
        var subscribers: [UUID: PTTransferProgressHandler]
    }

    private struct HTTPStatusError: Error, Sendable {
        let statusCode: Int
    }

    private var activeDownloads: [DownloadKey: ActiveDownload] = [:]
    private let concurrencyLimiter = PTTransferConcurrencyLimiter()

    public init() {}

    public func download(from sourceURL: URL,
                         to destinationURL: URL,
                         headers: [String: String] = [:],
                         allowsResume: Bool = true,
                         retryPolicy: PTTransferRetryPolicy = .init(),
                         policy: PTTransferPolicy = .init(),
                         configuration: PTTransferDownloadConfiguration = .init(),
                         progress: PTTransferProgressHandler? = nil) async throws -> URL {
        try await downloadResult(from: sourceURL,
                                 to: destinationURL,
                                 headers: headers,
                                 allowsResume: allowsResume,
                                 retryPolicy: retryPolicy,
                                 policy: policy,
                                 configuration: configuration,
                                 progress: progress).fileURL
    }

    public func downloadResult(from sourceURL: URL,
                               to destinationURL: URL,
                               headers: [String: String] = [:],
                               allowsResume: Bool = true,
                               retryPolicy: PTTransferRetryPolicy = .init(),
                               policy: PTTransferPolicy = .init(),
                               configuration: PTTransferDownloadConfiguration = .init(),
                               progress: PTTransferProgressHandler? = nil) async throws -> PTTransferDownloadResult {
        guard sourceURL.scheme != nil, !destinationURL.path.isEmpty else {
            throw PTTransferError.invalidRequest
        }

        let key = DownloadKey(source: sourceURL,
                              destination: destinationURL,
                              headers: headers,
                              allowsResume: allowsResume,
                              retryPolicy: retryPolicy,
                              policy: policy,
                              configuration: configuration)
        let subscriberID = UUID()
        let handler = progress ?? { _ in }
        let task: Task<PTTransferDownloadResult, Error>

        if var active = activeDownloads[key] {
            active.subscribers[subscriberID] = handler
            activeDownloads[key] = active
            task = active.task
        } else {
            let request = PTTransferRequest(source: .download(sourceURL),
                                            destination: destinationURL,
                                            executionMode: .foreground,
                                            retryPolicy: retryPolicy,
                                            policy: policy,
                                            headers: headers,
                                            allowsResume: allowsResume,
                                            downloadConfiguration: configuration)
            let service = self
            let concurrencyLimiter = self.concurrencyLimiter
            task = Task(priority: .utility) { [service, concurrencyLimiter] in
                let permit = try await concurrencyLimiter.acquire(maxConcurrent: request.policy.maxConcurrent)
                do {
                    let result = try await Self.perform(request: request) { snapshot in
                        await service.publish(snapshot, for: key)
                    }
                    await concurrencyLimiter.release(permit)
                    return result
                } catch {
                    await concurrencyLimiter.release(permit)
                    throw error
                }
            }
            activeDownloads[key] = ActiveDownload(task: task,
                                                  subscribers: [subscriberID: handler])
        }

        let initial = PTTransferProgress(completed: 0, fraction: 0)
        Task { await handler(initial) }

        do {
            let result = try await Self.waitForResult(task)
            removeSubscriber(subscriberID, from: key)
            return result
        } catch {
            removeSubscriber(subscriberID, from: key)
            throw error
        }
    }

    private func publish(_ progress: PTTransferProgress, for key: DownloadKey) {
        let handlers = activeDownloads[key].map { Array($0.subscribers.values) } ?? []
        for handler in handlers {
            Task { await handler(progress) }
        }
    }

    private func removeSubscriber(_ id: UUID, from key: DownloadKey) {
        guard var active = activeDownloads[key] else { return }
        active.subscribers[id] = nil
        if active.subscribers.isEmpty {
            active.task.cancel()
            activeDownloads[key] = nil
        } else {
            activeDownloads[key] = active
        }
    }

    private static func waitForResult(_ task: Task<PTTransferDownloadResult, Error>) async throws -> PTTransferDownloadResult {
        let cancellationSignal = PTTransferCancellationSignal()
        return try await withThrowingTaskGroup(of: PTTransferDownloadResult.self) { group in
            group.addTask { try await task.value }
            group.addTask {
                try await withTaskCancellationHandler(operation: {
                    try await cancellationSignal.wait()
                    throw CancellationError()
                }, onCancel: {
                    Task { await cancellationSignal.cancel() }
                })
            }
            defer {
                group.cancelAll()
                Task { await cancellationSignal.cancel() }
            }
            guard let result = try await group.next() else {
                throw PTTransferError.destinationUnavailable
            }
            return result
        }
    }

    private static func perform(request: PTTransferRequest,
                                progress: @escaping PTTransferProgressHandler) async throws -> PTTransferDownloadResult {
        guard case .download = request.source, let destination = request.destination else {
            throw PTTransferError.invalidRequest
        }

        var attempt = 0
        while true {
            do {
                return try await performOnce(request: request,
                                             destination: destination,
                                             progress: progress)
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as HTTPStatusError {
                guard isRetryableStatus(error.statusCode), attempt + 1 < request.retryPolicy.maxAttempts else {
                    throw PTTransferError.failed("HTTP status \(error.statusCode)")
                }
                attempt += 1
                try await sleepBeforeRetry(attempt: attempt, policy: request.retryPolicy)
            } catch {
                guard isRetryable(error), attempt + 1 < request.retryPolicy.maxAttempts else {
                    throw error
                }
                attempt += 1
                try await sleepBeforeRetry(attempt: attempt, policy: request.retryPolicy)
            }
        }
    }

    private static func performOnce(request: PTTransferRequest,
                                    destination: URL,
                                    progress: @escaping PTTransferProgressHandler) async throws -> PTTransferDownloadResult {
        guard case .download(let sourceURL) = request.source else {
            throw PTTransferError.invalidRequest
        }

        let fileManager = FileManager.default
        let directory = destination.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let temporaryURL: URL
        if request.allowsResume {
            temporaryURL = destination.appendingPathExtension("part")
        } else {
            temporaryURL = directory.appendingPathComponent(".\(destination.lastPathComponent).\(UUID().uuidString).pt-download")
        }

        if !fileManager.fileExists(atPath: temporaryURL.path) {
            guard fileManager.createFile(atPath: temporaryURL.path, contents: nil) else {
                throw PTTransferError.destinationUnavailable
            }
        }

        var existingBytes: Int64 = 0
        if request.allowsResume,
           let attributes = try? fileManager.attributesOfItem(atPath: temporaryURL.path),
           let size = attributes[.size] as? NSNumber {
            existingBytes = max(0, size.int64Value)
        }

        defer {
            if !request.allowsResume {
                try? fileManager.removeItem(at: temporaryURL)
            }
        }

        var urlRequest = URLRequest(url: sourceURL)
        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        if existingBytes > 0 {
            urlRequest.setValue("bytes=\(existingBytes)-", forHTTPHeaderField: "Range")
        }

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = request.downloadConfiguration.requestTimeout
        sessionConfiguration.timeoutIntervalForResource = request.downloadConfiguration.resourceTimeout
        sessionConfiguration.waitsForConnectivity = request.policy.waitsForConnectivity
        sessionConfiguration.allowsCellularAccess = request.policy.allowsCellular
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            sessionConfiguration.allowsExpensiveNetworkAccess = request.policy.allowsExpensiveNetwork
            sessionConfiguration.allowsConstrainedNetworkAccess = request.policy.allowsConstrainedNetwork
        }
        let session = URLSession(configuration: sessionConfiguration)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw HTTPStatusError(statusCode: statusCode)
        }

        let shouldAppend = request.allowsResume && existingBytes > 0 && httpResponse.statusCode == 206
        if existingBytes > 0 && !shouldAppend {
            existingBytes = 0
            try fileManager.removeItem(at: temporaryURL)
            guard fileManager.createFile(atPath: temporaryURL.path, contents: nil) else {
                throw PTTransferError.destinationUnavailable
            }
        }

        let contentLength = max(0, response.expectedContentLength)
        let totalBytes = shouldAppend ? existingBytes + contentLength : contentLength
        let fileHandle = try FileHandle(forWritingTo: temporaryURL)
        var isClosed = false
        defer {
            if !isClosed { try? fileHandle.close() }
        }
        if shouldAppend { try fileHandle.seekToEnd() }
        else { try fileHandle.truncate(atOffset: 0) }

        var receivedBytes = shouldAppend ? existingBytes : 0
        var buffer = Data()
        buffer.reserveCapacity(64 * 1024)
        var lastProgressAt = -Double.infinity
        var lastFraction = shouldAppend && totalBytes > 0 ? Double(receivedBytes) / Double(totalBytes) : 0

        for try await byte in bytes {
            try Task.checkCancellation()
            buffer.append(byte)
            if buffer.count >= 64 * 1024 {
                try fileHandle.write(contentsOf: buffer)
                receivedBytes += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                let now = ProcessInfo.processInfo.systemUptime
                if now - lastProgressAt >= 0.1 {
                    let fraction = totalBytes > 0 ? max(lastFraction, Double(receivedBytes) / Double(totalBytes)) : lastFraction
                    lastFraction = min(1, fraction)
                    await progress(.init(completed: receivedBytes,
                                         total: totalBytes > 0 ? totalBytes : nil,
                                         fraction: lastFraction))
                    lastProgressAt = now
                }
            }
        }

        if !buffer.isEmpty {
            try fileHandle.write(contentsOf: buffer)
            receivedBytes += Int64(buffer.count)
        }
        try fileHandle.close()
        isClosed = true

        guard receivedBytes > 0 else { throw URLError(.zeroByteResource) }
        try? fileManager.removeItem(at: destination)
        try fileManager.moveItem(at: temporaryURL, to: destination)
        await progress(.init(completed: receivedBytes,
                             total: totalBytes > 0 ? totalBytes : receivedBytes,
                             fraction: 1))

        let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, entry in
            guard let key = entry.key as? String else { return }
            result[key] = String(describing: entry.value)
        }
        return PTTransferDownloadResult(fileURL: destination,
                                        statusCode: httpResponse.statusCode,
                                        headers: headers)
    }

    private static func sleepBeforeRetry(attempt: Int,
                                         policy: PTTransferRetryPolicy) async throws {
        let multiplier = pow(2, Double(max(0, attempt - 1)))
        let base = seconds(policy.baseDelay) * multiplier
        try await Task.sleep(for: .seconds(min(base, seconds(policy.maxDelay))))
    }

    private static func isRetryable(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet,
             .dnsLookupFailed, .cannotFindHost, .resourceUnavailable:
            return true
        default:
            return false
        }
    }

    private static func isRetryableStatus(_ statusCode: Int) -> Bool {
        statusCode == 408 || statusCode == 429 || (500..<600).contains(statusCode)
    }

    private static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
    }
}

// English: Limit concurrent foreground downloads without blocking an actor or a URLSession worker.
// Español: Limita las descargas de primer plano sin bloquear un actor ni un trabajador de URLSession.
// 中文：限制前台下载并发数，同时不阻塞 actor 或 URLSession 工作线程。
private actor PTTransferConcurrencyLimiter {
    private var activeLimits: [UUID: Int] = [:]

    func acquire(maxConcurrent: Int) async throws -> UUID {
        let requestedLimit = max(1, maxConcurrent)
        while true {
            try Task.checkCancellation()
            let effectiveLimit = activeLimits.values.reduce(requestedLimit, min)
            if activeLimits.count < effectiveLimit {
                let permit = UUID()
                activeLimits[permit] = requestedLimit
                return permit
            }
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    func release(_ permit: UUID) {
        activeLimits[permit] = nil
    }
}

// English: AsyncStream avoids a Swift compiler diagnostic failure in the cancellation continuation.
// Español: AsyncStream evita un fallo de diagnóstico del compilador Swift en la continuación de cancelación.
// 中文：使用 AsyncStream 避免 Swift 编译器在取消 continuation 闭包上的诊断失败。
private actor PTTransferCancellationSignal {
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation
    private var isCancelled = false

    init() {
        let channel = AsyncStream<Void>.makeStream()
        stream = channel.stream
        continuation = channel.continuation
    }

    func wait() async throws {
        if isCancelled {
            throw CancellationError()
        }
        for await _ in stream {
            throw CancellationError()
        }
        throw CancellationError()
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        continuation.yield(())
        continuation.finish()
    }
}
