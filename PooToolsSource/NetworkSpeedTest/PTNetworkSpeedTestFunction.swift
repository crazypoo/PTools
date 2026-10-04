// English: Typed and cancellable network speed measurement shared by the legacy facade and new clients.
// Español: Medición de velocidad de red tipada y cancelable compartida por la fachada heredada y los clientes nuevos.
// 中文：由旧门面和新调用方共用的类型化、可取消网络测速实现。

import Foundation
import UIKit

public enum PTNetworkSpeedTestPhase: Sendable, Equatable {
    case latency
    case download
    case upload
    case finished
}

public struct PTNetworkSpeedTestConfiguration: Sendable, Equatable {
    public let downloadURL: URL?
    public let uploadURL: URL?
    public let uploadPayloadSize: Int
    public let timeout: TimeInterval

    public init(downloadURL: URL? = nil,
                uploadURL: URL? = nil,
                uploadPayloadSize: Int = 10 * 1024 * 1024,
                timeout: TimeInterval = 30) {
        self.downloadURL = downloadURL
        self.uploadURL = uploadURL
        self.uploadPayloadSize = max(1, uploadPayloadSize)
        self.timeout = timeout.isFinite && timeout > 0 ? timeout : 30
    }
}

public struct PTNetworkSpeedSnapshot: Sendable, Equatable {
    public let phase: PTNetworkSpeedTestPhase
    public let bytes: Int64
    public let megabitsPerSecond: Double
    public let elapsed: TimeInterval
    public let latency: TimeInterval?

    public init(phase: PTNetworkSpeedTestPhase,
                bytes: Int64 = 0,
                megabitsPerSecond: Double = 0,
                elapsed: TimeInterval = 0,
                latency: TimeInterval? = nil) {
        self.phase = phase
        self.bytes = bytes
        self.megabitsPerSecond = megabitsPerSecond
        self.elapsed = elapsed
        self.latency = latency
    }
}

public enum PTNetworkSpeedTestError: Error, LocalizedError, Sendable, Equatable {
    case missingEndpoint
    case invalidEndpoint
    case invalidResponse
    case invalidStatusCode(Int)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .missingEndpoint: return "未配置网络测速地址"
        case .invalidEndpoint: return "网络测速地址无效"
        case .invalidResponse: return "网络测速响应无效"
        case .invalidStatusCode(let status): return "网络测速响应状态异常：\(status)"
        case .cancelled: return "网络测速已取消"
        }
    }
}

public actor PTNetworkSpeedTester {
    public static let shared = PTNetworkSpeedTester()

    private var runningTask: Task<Void, Never>?

    public init() {}

    public func start(configuration: PTNetworkSpeedTestConfiguration) -> AsyncThrowingStream<PTNetworkSpeedSnapshot, Error> {
        runningTask?.cancel()
        return AsyncThrowingStream { continuation in
            let task = Task { [weak self] in
                do {
                    try await self?.run(configuration: configuration, continuation: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            self.runningTask = task
            continuation.onTermination = { @Sendable _ in
                task.cancel()
                Task { await self.cancel() }
            }
        }
    }

    public func cancel() {
        runningTask?.cancel()
        runningTask = nil
    }

    private func store(task: Task<Void, Never>) {
        runningTask = task
    }

    private func run(configuration: PTNetworkSpeedTestConfiguration,
                     continuation: AsyncThrowingStream<PTNetworkSpeedSnapshot, Error>.Continuation) async throws {
        guard let downloadURL = configuration.downloadURL,
              let uploadURL = configuration.uploadURL else {
            throw PTNetworkSpeedTestError.missingEndpoint
        }
        guard Self.isValidEndpoint(downloadURL), Self.isValidEndpoint(uploadURL) else {
            throw PTNetworkSpeedTestError.invalidEndpoint
        }

        let latencyStart = Date()
        var latencyRequest = URLRequest(url: downloadURL)
        latencyRequest.httpMethod = "HEAD"
        latencyRequest.cachePolicy = .reloadIgnoringLocalCacheData
        latencyRequest.timeoutInterval = configuration.timeout
        let (_, latencyResponse) = try await URLSession.shared.data(for: latencyRequest)
        guard let latencyHTTPResponse = latencyResponse as? HTTPURLResponse else {
            throw PTNetworkSpeedTestError.invalidResponse
        }
        guard (200..<500).contains(latencyHTTPResponse.statusCode) else {
            throw PTNetworkSpeedTestError.invalidStatusCode(latencyHTTPResponse.statusCode)
        }
        let latency = Date().timeIntervalSince(latencyStart)
        continuation.yield(PTNetworkSpeedSnapshot(phase: .latency,
                                                  elapsed: latency,
                                                  latency: latency))

        var downloadRequest = URLRequest(url: downloadURL)
        downloadRequest.cachePolicy = .reloadIgnoringLocalCacheData
        downloadRequest.timeoutInterval = configuration.timeout
        let downloadStart = Date()
        let (bytes, response) = try await URLSession.shared.bytes(for: downloadRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PTNetworkSpeedTestError.invalidResponse
        }
        guard (200..<400).contains(httpResponse.statusCode) else {
            throw PTNetworkSpeedTestError.invalidStatusCode(httpResponse.statusCode)
        }

        var totalBytes: Int64 = 0
        var pendingBytes = 0
        for try await _ in bytes {
            try Task.checkCancellation()
            totalBytes += 1
            pendingBytes += 1
            if pendingBytes >= 64 * 1024 {
                let elapsed = max(Date().timeIntervalSince(downloadStart), 0.001)
                continuation.yield(PTNetworkSpeedSnapshot(phase: .download,
                                                          bytes: totalBytes,
                                                          megabitsPerSecond: Self.megabits(bytes: totalBytes, elapsed: elapsed),
                                                          elapsed: elapsed))
                pendingBytes = 0
            }
        }
        let downloadElapsed = max(Date().timeIntervalSince(downloadStart), 0.001)
        continuation.yield(PTNetworkSpeedSnapshot(phase: .download,
                                                  bytes: totalBytes,
                                                  megabitsPerSecond: Self.megabits(bytes: totalBytes, elapsed: downloadElapsed),
                                                  elapsed: downloadElapsed))

        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "POST"
        uploadRequest.cachePolicy = .reloadIgnoringLocalCacheData
        uploadRequest.timeoutInterval = configuration.timeout
        uploadRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let uploadData = Data(repeating: 0, count: configuration.uploadPayloadSize)
        let uploadStart = Date()
        let (_, uploadResponse) = try await URLSession.shared.upload(for: uploadRequest, from: uploadData)
        guard let uploadHTTPResponse = uploadResponse as? HTTPURLResponse else {
            throw PTNetworkSpeedTestError.invalidResponse
        }
        guard (200..<500).contains(uploadHTTPResponse.statusCode) else {
            throw PTNetworkSpeedTestError.invalidStatusCode(uploadHTTPResponse.statusCode)
        }
        let uploadElapsed = max(Date().timeIntervalSince(uploadStart), 0.001)
        continuation.yield(PTNetworkSpeedSnapshot(phase: .upload,
                                                  bytes: Int64(uploadData.count),
                                                  megabitsPerSecond: Self.megabits(bytes: Int64(uploadData.count), elapsed: uploadElapsed),
                                                  elapsed: uploadElapsed))
        continuation.yield(PTNetworkSpeedSnapshot(phase: .finished,
                                                  bytes: Int64(uploadData.count),
                                                  megabitsPerSecond: Self.megabits(bytes: Int64(uploadData.count), elapsed: uploadElapsed),
                                                  elapsed: uploadElapsed,
                                                  latency: latency))
    }

    private static func megabits(bytes: Int64, elapsed: TimeInterval) -> Double {
        Double(bytes) * 8 / max(elapsed, 0.001) / 1_000_000
    }

    private static func isValidEndpoint(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              let host = url.host,
              !host.isEmpty else { return false }
        return scheme == "https" || scheme == "http"
    }
}

@objc public enum PTNetworkSpeedTestStateType: Int {
    case Download
    case Upload
    case Free
}

@objc public enum PTNetworkSpeedTestType: Int {
    case Download
    case Upload
    case Latency
}

@MainActor
@objcMembers
public class PTNetworkSpeedTestFunction: NSObject {
    public static let shared = PTNetworkSpeedTestFunction()

    public var netSpeedStateType: PTNetworkSpeedTestStateType = .Free
    public lazy var netWorkName: String = ""
    public lazy var downloadValueArrs: [CGFloat] = []
    public lazy var uploadValueArrs: [CGFloat] = []

    public var downloadCurrentTask: ((CGFloat) -> Void)?
    public var uploadCurrentTask: ((CGFloat) -> Void)?
    public var valueUpdateTask: ((PTNetworkSpeedTestType, CGFloat) -> Void)?
    public var testDone: PTActionTask?

    // English: These string properties remain as compatibility inputs for existing clients.
    // Español: Estas propiedades de texto se mantienen como entradas compatibles para clientes existentes.
    // 中文：保留这两个字符串属性，兼容现有调用方的配置方式。
    public var downloadTestURL = ""
    public var uploadTestURL = ""

    private let tester = PTNetworkSpeedTester.shared
    private var testTask: Task<Void, Never>?
    private var downloadValue: CGFloat = 0
    private var uploadValue: CGFloat = 0
    private var latencyValue: CGFloat = 0
    private var runIdentifier = UUID()

    public func readyTest() {
        testTask?.cancel()
        let identifier = UUID()
        runIdentifier = identifier
        downloadValueArrs.removeAll(keepingCapacity: true)
        uploadValueArrs.removeAll(keepingCapacity: true)
        downloadValue = 0
        uploadValue = 0
        latencyValue = 0
        netSpeedStateType = .Download

        guard let downloadURL = URL(string: downloadTestURL),
              let uploadURL = URL(string: uploadTestURL) else {
            finish(error: PTNetworkSpeedTestError.missingEndpoint, runIdentifier: identifier)
            return
        }

        let configuration = PTNetworkSpeedTestConfiguration(downloadURL: downloadURL,
                                                            uploadURL: uploadURL)
        testTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = await self.tester.start(configuration: configuration)
                for try await snapshot in stream {
                    guard !Task.isCancelled else { return }
                    self.consume(snapshot)
                }
                self.finish(error: nil, runIdentifier: identifier)
            } catch {
                guard !Task.isCancelled else { return }
                self.finish(error: error, runIdentifier: identifier)
            }
        }
    }

    public func suspendTest() {
        testTask?.cancel()
        testTask = nil
        runIdentifier = UUID()
        Task { await tester.cancel() }
        netSpeedStateType = .Free
    }

    public func saveHistory(jsonString:String) {
        let userHistoryModelString = PTCoreUserDefaultsWrapper.shared.NetworkSpeedTestFunctionHistoria
        if !userHistoryModelString.stringIsEmpty() {
            var userModelsStringArr = userHistoryModelString.components(separatedBy: "[,]")
            userModelsStringArr.append(jsonString)
            PTCoreUserDefaultsWrapper.shared.NetworkSpeedTestFunctionHistoria = userModelsStringArr.joined(separator: "[,]")
        } else {
            PTCoreUserDefaultsWrapper.shared.NetworkSpeedTestFunctionHistoria = jsonString
        }
    }

    // English: Keep the old URLSession delegate-shaped callbacks as inert compatibility hooks.
    // Español: Conserva las devoluciones con forma de delegado URLSession como hooks de compatibilidad inertes.
    // 中文：保留旧的 URLSession 委托回调形状，作为不改变新 actor 流程的兼容钩子。
    @available(*, deprecated, message: "Use PTNetworkSpeedTester and its typed AsyncThrowingStream instead.")
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        _ = session
        _ = task
        _ = metrics
    }

    @available(*, deprecated, message: "Use PTNetworkSpeedTester and its typed progress snapshots instead.")
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        _ = session
        _ = dataTask
        _ = data
    }

    @available(*, deprecated, message: "Use PTNetworkSpeedTester and its typed progress snapshots instead.")
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        _ = session
        _ = task
        _ = bytesSent
        _ = totalBytesSent
        _ = totalBytesExpectedToSend
    }

    private func consume(_ snapshot: PTNetworkSpeedSnapshot) {
        switch snapshot.phase {
        case .latency:
            latencyValue = CGFloat(snapshot.latency ?? snapshot.elapsed) * 1000
            valueUpdateTask?(.Latency, latencyValue)
        case .download:
            netSpeedStateType = .Download
            downloadValue = CGFloat(snapshot.megabitsPerSecond)
            downloadValueArrs.append(downloadValue)
            downloadCurrentTask?(downloadValue)
        case .upload:
            netSpeedStateType = .Upload
            uploadValue = CGFloat(snapshot.megabitsPerSecond)
            uploadValueArrs.append(uploadValue)
            uploadCurrentTask?(uploadValue)
        case .finished:
            break
        }
    }

    private func finish(error: Error?, runIdentifier: UUID) {
        guard self.runIdentifier == runIdentifier else { return }
        if let error {
            PTNSLogConsole(error.localizedDescription, levelType: .error, loggerType: .network)
        }
        valueUpdateTask?(.Download, downloadValue)
        valueUpdateTask?(.Upload, uploadValue)
        if error == nil {
            let historyModel = PTNetworkSpeedHistoriaModel()
            historyModel.download = String(format: "%.2f", downloadValue)
            historyModel.upload = String(format: "%.2f", uploadValue)
            historyModel.latency = String(format: "%.2f", latencyValue)
            historyModel.networkType = netWorkName
            historyModel.date = Date().dateFormat(formatString: "yyyy-MM-dd HH:mm:ss")
            if let data = try? JSONEncoder().encode(historyModel) {
                let jsonString = String(decoding: data, as: UTF8.self)
                PTNSLogConsole(jsonString, levelType: .notice, loggerType: .network)
                saveHistory(jsonString: jsonString)
            }
        }
        netSpeedStateType = .Free
        testDone?()
        testTask = nil
    }
}
