// English: Native URLSession WebSocket contracts for iOS 17+ and Swift 6.
// Español: Contratos WebSocket nativos de URLSession para iOS 17+ y Swift 6.
// 中文：面向 iOS 17+ 与 Swift 6 的原生 URLSession WebSocket 契约。

import Foundation
import Security

#if SWIFT_PACKAGE
import ptools
#endif

public enum PTWebSocketState: Sendable, Equatable {
    case idle
    case connecting
    case connected
    case reconnecting
    case disconnecting
    case disconnected
    case failed
}

public enum PTWebSocketMessage: Sendable, Equatable {
    case text(String)
    case data(Data)
}

public enum PTWebSocketCloseCode: Sendable, Equatable {
    case normal
    case goingAway
    case protocolError
    case policyViolation
    case messageTooBig
    case other(Int)

    fileprivate var rawValue: Int {
        switch self {
        case .normal: return 1000
        case .goingAway: return 1001
        case .protocolError: return 1002
        case .policyViolation: return 1008
        case .messageTooBig: return 1009
        case .other(let value): return value
        }
    }

    fileprivate init(rawValue: Int) {
        switch rawValue {
        case 1000: self = .normal
        case 1001: self = .goingAway
        case 1002: self = .protocolError
        case 1008: self = .policyViolation
        case 1009: self = .messageTooBig
        default: self = .other(rawValue)
        }
    }
}

public struct PTWebSocketCloseContext: Sendable, Equatable {
    public let code: PTWebSocketCloseCode?
    public let reason: String?
    public let wasClean: Bool

    public init(code: PTWebSocketCloseCode?, reason: String?, wasClean: Bool) {
        self.code = code
        self.reason = reason
        self.wasClean = wasClean
    }
}

public struct PTWebSocketPongContext: Sendable, Equatable {
    public let roundTripTime: Duration?
    public let receivedAt: Date

    public init(roundTripTime: Duration?, receivedAt: Date = Date()) {
        self.roundTripTime = roundTripTime
        self.receivedAt = receivedAt
    }
}

public struct PTWebSocketReconnectContext: Sendable, Equatable {
    public let attempt: Int
    public let delay: Duration

    public init(attempt: Int, delay: Duration) {
        self.attempt = attempt
        self.delay = delay
    }
}

public enum PTWebSocketEvent: Sendable, Equatable {
    case connecting
    case connected(protocolName: String?)
    case message(PTWebSocketMessage)
    case pong(PTWebSocketPongContext)
    case reconnecting(PTWebSocketReconnectContext)
    case disconnected(PTWebSocketCloseContext)
    case failed(PTWebSocketError)
}

public enum PTWebSocketError: Error, LocalizedError, Sendable, Equatable {
    case invalidURL
    case notConnected
    case queueFull
    case connectionFailed(String)
    case transport(String)
    case send(String)
    case receive(String)
    case pingTimeout
    case trustEvaluationFailed
    case messageTooLarge
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "WebSocket URL 无效 / Invalid WebSocket URL / URL WebSocket no válida"
        case .notConnected: return "WebSocket 尚未连接 / WebSocket is not connected / WebSocket no está conectado"
        case .queueFull: return "WebSocket 发送队列已满 / WebSocket send queue is full / La cola de envío WebSocket está llena"
        case .connectionFailed(let message), .transport(let message), .send(let message), .receive(let message): return message
        case .pingTimeout: return "WebSocket 心跳超时 / WebSocket heartbeat timed out / Tiempo de espera del heartbeat agotado"
        case .trustEvaluationFailed: return "WebSocket 信任校验失败 / WebSocket trust evaluation failed / Falló la validación de confianza"
        case .messageTooLarge: return "WebSocket 消息过大 / WebSocket message is too large / El mensaje WebSocket es demasiado grande"
        case .cancelled: return "WebSocket 操作已取消 / WebSocket operation cancelled / Operación WebSocket cancelada"
        }
    }
}

public enum PTWebSocketPin: Sendable, Equatable {
    case certificate(Data)
    case publicKey(Data)
}

public enum PTWebSocketTrustPolicy: Sendable, Equatable {
    case systemDefault
    case pinnedCertificates([PTWebSocketPin])
    case pinnedPublicKeys([PTWebSocketPin])
}

public enum PTWebSocketReconnectPolicy: Sendable, Equatable {
    case disabled
    case exponential(maxAttempts: Int,
                     initialDelay: Duration,
                     multiplier: Double,
                     maxDelay: Duration,
                     jitter: Double)

    fileprivate var maxAttempts: Int {
        switch self {
        case .disabled: return 0
        case .exponential(let attempts, _, _, _, _): return max(0, attempts)
        }
    }

    fileprivate func delay(for attempt: Int, randomUnit: Double = 0.5) -> Duration {
        guard case .exponential(_, let initialDelay, let multiplier, let maxDelay, let jitter) = self else {
            return .zero
        }
        let exponent = max(0, attempt - 1)
        let base = min(maxDelay.ptSeconds, initialDelay.ptSeconds * pow(max(1, multiplier), Double(exponent)))
        let boundedJitter = min(1, max(0, jitter))
        let offset = (min(1, max(0, randomUnit)) * 2 - 1) * boundedJitter
        return .seconds(max(0, base * (1 + offset)))
    }
}

public struct PTWebSocketHeartbeatConfiguration: Sendable, Equatable {
    public let interval: Duration
    public let timeout: Duration
    public let enabled: Bool

    public init(interval: Duration = .seconds(30), timeout: Duration = .seconds(15), enabled: Bool = true) {
        self.interval = interval
        self.timeout = timeout
        self.enabled = enabled
    }
}

public enum PTWebSocketQueueOverflowPolicy: Sendable, Equatable {
    case rejectNewest
    case dropOldest
}

public struct PTWebSocketSendBufferConfiguration: Sendable, Equatable {
    public let capacity: Int
    public let overflowPolicy: PTWebSocketQueueOverflowPolicy

    public init(capacity: Int = 1000, overflowPolicy: PTWebSocketQueueOverflowPolicy = .rejectNewest) {
        self.capacity = max(1, capacity)
        self.overflowPolicy = overflowPolicy
    }
}

public struct PTWebSocketConfiguration: Sendable, Equatable {
    public let url: URL
    public var headers: [String: String]
    public var heartbeatInterval: TimeInterval
    public var heartbeatTimeout: TimeInterval
    public var maxReconnectAttempts: Int
    public var reconnectBaseDelay: TimeInterval
    public var maxQueuedMessages: Int
    public var automaticallyReconnect: Bool
    public var subprotocols: [String]
    public var reconnectPolicy: PTWebSocketReconnectPolicy
    public var heartbeat: PTWebSocketHeartbeatConfiguration
    public var sendBuffer: PTWebSocketSendBufferConfiguration
    public var trustPolicy: PTWebSocketTrustPolicy
    public var connectionTimeout: TimeInterval
    public var waitsForConnectivity: Bool
    public var maximumMessageSize: Int?
    public var stabilityThreshold: TimeInterval

    public init(url: URL,
                headers: [String: String] = [:],
                heartbeatInterval: TimeInterval = 30,
                heartbeatTimeout: TimeInterval = 15,
                maxReconnectAttempts: Int = 10,
                reconnectBaseDelay: TimeInterval = 1,
                maxQueuedMessages: Int = 1000,
                automaticallyReconnect: Bool = true,
                subprotocols: [String] = [],
                reconnectPolicy: PTWebSocketReconnectPolicy? = nil,
                heartbeat: PTWebSocketHeartbeatConfiguration? = nil,
                sendBuffer: PTWebSocketSendBufferConfiguration? = nil,
                trustPolicy: PTWebSocketTrustPolicy = .systemDefault,
                connectionTimeout: TimeInterval = 15,
                waitsForConnectivity: Bool = true,
                maximumMessageSize: Int? = nil,
                stabilityThreshold: TimeInterval = 10) {
        self.url = url
        self.headers = headers
        self.heartbeatInterval = max(1, heartbeatInterval)
        self.heartbeatTimeout = max(1, heartbeatTimeout)
        self.maxReconnectAttempts = max(0, maxReconnectAttempts)
        self.reconnectBaseDelay = max(0, reconnectBaseDelay)
        self.maxQueuedMessages = max(1, maxQueuedMessages)
        self.automaticallyReconnect = automaticallyReconnect
        self.subprotocols = subprotocols
        self.reconnectPolicy = reconnectPolicy ?? (automaticallyReconnect
            ? .exponential(maxAttempts: maxReconnectAttempts,
                          initialDelay: .seconds(max(0, reconnectBaseDelay)),
                          multiplier: 2,
                          maxDelay: .seconds(60),
                          jitter: 0.2)
            : .disabled)
        self.heartbeat = heartbeat ?? PTWebSocketHeartbeatConfiguration(interval: .seconds(self.heartbeatInterval), timeout: .seconds(self.heartbeatTimeout))
        self.sendBuffer = sendBuffer ?? PTWebSocketSendBufferConfiguration(capacity: self.maxQueuedMessages)
        self.trustPolicy = trustPolicy
        self.connectionTimeout = max(1, connectionTimeout)
        self.waitsForConnectivity = waitsForConnectivity
        self.maximumMessageSize = maximumMessageSize.map { max(1, $0) }
        self.stabilityThreshold = max(0, stabilityThreshold)
    }
}

public struct PTWebSocketMetrics: Sendable, Equatable {
    public let sentMessageCount: UInt64
    public let receivedMessageCount: UInt64
    public let sentByteCount: UInt64
    public let receivedByteCount: UInt64
    public let reconnectCount: UInt64
    public let lastPingRoundTripTime: Duration?

    public init(sentMessageCount: UInt64 = 0,
                receivedMessageCount: UInt64 = 0,
                sentByteCount: UInt64 = 0,
                receivedByteCount: UInt64 = 0,
                reconnectCount: UInt64 = 0,
                lastPingRoundTripTime: Duration? = nil) {
        self.sentMessageCount = sentMessageCount
        self.receivedMessageCount = receivedMessageCount
        self.sentByteCount = sentByteCount
        self.receivedByteCount = receivedByteCount
        self.reconnectCount = reconnectCount
        self.lastPingRoundTripTime = lastPingRoundTripTime
    }
}

public struct PTWebSocketStateMachine: Sendable {
    public private(set) var state: PTWebSocketState = .idle

    public init(state: PTWebSocketState = .idle) {
        self.state = state
    }

    public mutating func transition(to state: PTWebSocketState) {
        self.state = state
    }
}

public struct PTWebSocketSendBuffer: Sendable {
    private var messages: [PTWebSocketMessage] = []
    public let configuration: PTWebSocketSendBufferConfiguration

    public init(configuration: PTWebSocketSendBufferConfiguration = PTWebSocketSendBufferConfiguration()) {
        self.configuration = configuration
    }

    public var count: Int { messages.count }
    public var isEmpty: Bool { messages.isEmpty }
    public func snapshot() -> [PTWebSocketMessage] { messages }

    public mutating func enqueue(_ message: PTWebSocketMessage) throws {
        guard messages.count >= configuration.capacity else {
            messages.append(message)
            return
        }
        switch configuration.overflowPolicy {
        case .rejectNewest:
            throw PTWebSocketError.queueFull
        case .dropOldest:
            messages.removeFirst()
            messages.append(message)
        }
    }

    public mutating func removeFirst() -> PTWebSocketMessage? {
        messages.isEmpty ? nil : messages.removeFirst()
    }

    public mutating func prepend(_ message: PTWebSocketMessage) {
        messages.insert(message, at: 0)
    }

    public mutating func removeAll() {
        messages.removeAll(keepingCapacity: true)
    }
}

public enum PTWebSocketTransportEvent: Sendable, Equatable {
    case opened(protocolName: String?)
    case message(PTWebSocketMessage)
    case closed(code: PTWebSocketCloseCode, reason: String?)
    case failed(PTWebSocketError)
}

public struct PTWebSocketTransportConfiguration: Sendable, Equatable {
    public let trustPolicy: PTWebSocketTrustPolicy
    public let connectionTimeout: TimeInterval
    public let waitsForConnectivity: Bool
    public let maximumMessageSize: Int?

    public init(trustPolicy: PTWebSocketTrustPolicy,
                connectionTimeout: TimeInterval,
                waitsForConnectivity: Bool,
                maximumMessageSize: Int?) {
        self.trustPolicy = trustPolicy
        self.connectionTimeout = connectionTimeout
        self.waitsForConnectivity = waitsForConnectivity
        self.maximumMessageSize = maximumMessageSize
    }
}

public protocol PTWebSocketTransport: Actor {
    func events() -> AsyncStream<PTWebSocketTransportEvent>
    func connect(request: URLRequest, configuration: PTWebSocketTransportConfiguration) async throws
    func send(_ message: PTWebSocketMessage) async throws
    func ping() async throws -> Duration
    func close(code: PTWebSocketCloseCode, reason: String?)
}

// English: Foundation delegate callbacks are the only unchecked bridge; all data crossing it is immutable.
// Español: Los callbacks del delegado de Foundation son el único puente unchecked; todos los datos son inmutables.
// 中文：Foundation 委托回调是唯一的 unchecked 桥接点，跨越边界的数据全部是不可变值。
private final class PTURLSessionWebSocketDelegateProxy: NSObject, URLSessionWebSocketDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    private let trustPolicy: PTWebSocketTrustPolicy
    private let emit: @Sendable (PTWebSocketTransportEvent) -> Void

    init(trustPolicy: PTWebSocketTrustPolicy, emit: @escaping @Sendable (PTWebSocketTransportEvent) -> Void) {
        self.trustPolicy = trustPolicy
        self.emit = emit
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        emit(.opened(protocolName: `protocol`))
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reason = reason.flatMap { String(data: $0, encoding: .utf8) }
        emit(.closed(code: PTWebSocketCloseCode(rawValue: closeCode.rawValue), reason: reason))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        emit(.failed(.transport(Self.message(for: error))))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        switch trustPolicy {
        case .systemDefault:
            completionHandler(.performDefaultHandling, nil)
        case .pinnedCertificates(let pins):
            if Self.validate(trust: trust, pins: pins, publicKeys: false) {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        case .pinnedPublicKeys(let pins):
            if Self.validate(trust: trust, pins: pins, publicKeys: true) {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }

    private static func message(for error: Error) -> String {
        let nsError = error as NSError
        return "\(nsError.domain) (\(nsError.code)): \(nsError.localizedDescription)"
    }

    private static func validate(trust: SecTrust, pins: [PTWebSocketPin], publicKeys: Bool) -> Bool {
        guard SecTrustEvaluateWithError(trust, nil) else { return false }
        let certificates = (SecTrustCopyCertificateChain(trust) as? [SecCertificate]) ?? []
        return certificates.contains { certificate in
            pins.contains { pin in
                switch pin {
                case .certificate(let expected) where !publicKeys:
                    return (SecCertificateCopyData(certificate) as Data) == expected
                case .publicKey(let expected) where publicKeys:
                    guard let key = SecCertificateCopyKey(certificate),
                          let keyData = SecKeyCopyExternalRepresentation(key, nil) else { return false }
                    return (keyData as Data) == expected
                default:
                    return false
                }
            }
        }
    }
}

public actor PTURLSessionWebSocketTransport: PTWebSocketTransport {
    private let eventStream: AsyncStream<PTWebSocketTransportEvent>
    private let eventContinuation: AsyncStream<PTWebSocketTransportEvent>.Continuation
    private var session: URLSession?
    private var socket: URLSessionWebSocketTask?
    private var proxy: PTURLSessionWebSocketDelegateProxy?
    private var receiveTask: Task<Void, Never>?
    private var openContinuation: CheckedContinuation<Void, Error>?

    public init() {
        let pair = AsyncStream<PTWebSocketTransportEvent>.makeStream()
        eventStream = pair.stream
        eventContinuation = pair.continuation
    }

    public func events() -> AsyncStream<PTWebSocketTransportEvent> {
        eventStream
    }

    public func connect(request: URLRequest, configuration: PTWebSocketTransportConfiguration) async throws {
        close(code: .goingAway, reason: nil)
        let urlConfiguration = URLSessionConfiguration.default
        urlConfiguration.waitsForConnectivity = configuration.waitsForConnectivity
        urlConfiguration.timeoutIntervalForRequest = configuration.connectionTimeout
        let proxy = PTURLSessionWebSocketDelegateProxy(trustPolicy: configuration.trustPolicy) { [weak self] event in
            Task { await self?.handle(event) }
        }
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let session = URLSession(configuration: urlConfiguration, delegate: proxy, delegateQueue: queue)
        let socket = session.webSocketTask(with: request)
        if let maximumMessageSize = configuration.maximumMessageSize {
            socket.maximumMessageSize = maximumMessageSize
        }
        self.proxy = proxy
        self.session = session
        self.socket = socket
        socket.resume()

        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                openContinuation = continuation
            }
        }, onCancel: { [weak self] in
            Task { await self?.cancelPendingOpen() }
        })
    }

    public func send(_ message: PTWebSocketMessage) async throws {
        guard let socket else { throw PTWebSocketError.notConnected }
        let taskMessage: URLSessionWebSocketTask.Message
        switch message {
        case .text(let value): taskMessage = .string(value)
        case .data(let value): taskMessage = .data(value)
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            socket.send(taskMessage) { error in
                if let error { continuation.resume(throwing: PTWebSocketError.send(Self.message(for: error))) }
                else { continuation.resume(returning: ()) }
            }
        }
    }

    public func ping() async throws -> Duration {
        guard let socket else { throw PTWebSocketError.notConnected }
        let start = ContinuousClock.now
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            socket.sendPing { error in
                if let error { continuation.resume(throwing: PTWebSocketError.transport(Self.message(for: error))) }
                else { continuation.resume(returning: ()) }
            }
        }
        return start.duration(to: .now)
    }

    public func close(code: PTWebSocketCloseCode = .normal, reason: String? = nil) {
        openContinuation?.resume(throwing: PTWebSocketError.cancelled)
        openContinuation = nil
        receiveTask?.cancel()
        receiveTask = nil
        if let socket {
            let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: code.rawValue) ?? .normalClosure
            socket.cancel(with: closeCode, reason: reason?.data(using: .utf8))
        }
        session?.invalidateAndCancel()
        socket = nil
        session = nil
        proxy = nil
    }

    private func cancelPendingOpen() {
        close(code: .goingAway, reason: nil)
    }

    private func handle(_ event: PTWebSocketTransportEvent) {
        switch event {
        case .opened:
            openContinuation?.resume(returning: ())
            openContinuation = nil
            startReceiveLoop()
        case .closed, .failed:
            openContinuation?.resume(throwing: event.error ?? PTWebSocketError.connectionFailed("WebSocket 连接失败 / WebSocket connection failed / Falló la conexión WebSocket"))
            openContinuation = nil
        case .message:
            break
        }
        eventContinuation.yield(event)
    }

    private func startReceiveLoop() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    guard let socket = await self.socket else { return }
                    let message = try await socket.receive()
                    let value: PTWebSocketMessage
                    switch message {
                    case .string(let text): value = .text(text)
                    case .data(let data): value = .data(data)
                    @unknown default: throw PTWebSocketError.receive("未知 WebSocket 消息 / Unknown WebSocket message / Mensaje WebSocket desconocido")
                    }
                    self.eventContinuation.yield(.message(value))
                } catch {
                    self.eventContinuation.yield(.failed(.receive(Self.message(for: error))))
                    return
                }
            }
        }
    }

    private static func message(for error: Error) -> String {
        let nsError = error as NSError
        return "\(nsError.domain) (\(nsError.code)): \(nsError.localizedDescription)"
    }
}

public actor PTWebSocketClient {
    public nonisolated let events: AsyncStream<PTWebSocketEvent>
    public nonisolated let messages: AsyncStream<PTWebSocketMessage>

    private let eventContinuation: AsyncStream<PTWebSocketEvent>.Continuation
    private let messageContinuation: AsyncStream<PTWebSocketMessage>.Continuation
    private var eventSubscribers: [UUID: AsyncStream<PTWebSocketEvent>.Continuation] = [:]
    private var configuration: PTWebSocketConfiguration
    private let authRefreshProvider: (any PTNetworkAuthRefreshProvider)?
    private let transport: any PTWebSocketTransport
    private var transportEventsTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var stableTask: Task<Void, Never>?
    private var buffer: PTWebSocketSendBuffer
    private var stateMachine = PTWebSocketStateMachine()
    private var currentGeneration: UInt64 = 0
    private var terminalGenerations: Set<UInt64> = []
    private var reconnectAttempt = 0
    private var manualDisconnect = false
    private var inBackground = false
    private var heartbeatEnabled: Bool
    private var metrics = PTWebSocketMetrics()

    public var state: PTWebSocketState { stateMachine.state }

    public init(configuration: PTWebSocketConfiguration,
                authRefreshProvider: (any PTNetworkAuthRefreshProvider)? = nil,
                transport: (any PTWebSocketTransport)? = nil) {
        self.configuration = configuration
        self.authRefreshProvider = authRefreshProvider
        self.transport = transport ?? PTURLSessionWebSocketTransport()
        self.buffer = PTWebSocketSendBuffer(configuration: configuration.sendBuffer)
        self.heartbeatEnabled = configuration.heartbeat.enabled
        let eventPair = AsyncStream<PTWebSocketEvent>.makeStream()
        let messagePair = AsyncStream<PTWebSocketMessage>.makeStream()
        events = eventPair.stream
        eventContinuation = eventPair.continuation
        messages = messagePair.stream
        messageContinuation = messagePair.continuation
    }

    deinit {
        transportEventsTask?.cancel()
        heartbeatTask?.cancel()
        reconnectTask?.cancel()
        stableTask?.cancel()
        eventContinuation.finish()
        messageContinuation.finish()
    }

    public func makeEventStream() -> AsyncStream<PTWebSocketEvent> {
        let pair = AsyncStream<PTWebSocketEvent>.makeStream()
        eventSubscribers[UUID()] = pair.continuation
        return pair.stream
    }

    public func update(headers: [String: String]) {
        configuration.headers = headers
    }

    public func updateConnectivity(isAvailable: Bool) {
        guard isAvailable, stateMachine.state == .failed, !manualDisconnect, !inBackground else { return }
        scheduleReconnect()
    }

    public func setHeartbeatEnabled(_ enabled: Bool) {
        heartbeatEnabled = enabled
        if enabled, stateMachine.state == .connected { startHeartbeat(generation: currentGeneration) }
        else { heartbeatTask?.cancel(); heartbeatTask = nil }
    }

    public func connect() async throws {
        guard !inBackground else { return }
        switch stateMachine.state {
        case .connecting, .connected: return
        case .disconnecting: throw PTWebSocketError.connectionFailed("WebSocket 正在断开 / WebSocket is disconnecting / WebSocket se está desconectando")
        case .idle, .reconnecting, .disconnected, .failed: break
        }
        manualDisconnect = false
        reconnectTask?.cancel()
        reconnectTask = nil
        currentGeneration &+= 1
        let generation = currentGeneration
        terminalGenerations.remove(generation)
        stateMachine.transition(to: reconnectAttempt > 0 ? .reconnecting : .connecting)
        emit(.connecting)
        let stream = await transport.events()
        transportEventsTask?.cancel()
        transportEventsTask = Task { [weak self] in
            guard let self else { return }
            for await event in stream {
                guard !Task.isCancelled else { return }
                await self.handle(event, generation: generation)
            }
        }
        do {
            try await transport.connect(request: makeRequest(), configuration: transportConfiguration())
        } catch {
            let normalized = normalize(error, fallback: PTWebSocketError.connectionFailed)
            handleTerminal(generation: generation, error: normalized, context: PTWebSocketCloseContext(code: nil, reason: normalized.localizedDescription, wasClean: false))
            throw normalized
        }
    }

    // English: Keep the original no-argument API while routing cleanup through the actor-owned async path.
    // Español: Conserva la API original sin argumentos y dirige la limpieza por la ruta async del actor.
    // 中文：保留原有无参数 API，清理统一转到 actor 管理的异步路径。
    public func disconnect() {
        Task { await disconnect(clearQueue: true) }
    }

    public func disconnect(clearQueue: Bool) async {
        manualDisconnect = true
        reconnectTask?.cancel()
        reconnectTask = nil
        heartbeatTask?.cancel()
        heartbeatTask = nil
        stableTask?.cancel()
        stableTask = nil
        transportEventsTask?.cancel()
        transportEventsTask = nil
        currentGeneration &+= 1
        stateMachine.transition(to: .disconnecting)
        await transport.close(code: .normal, reason: nil)
        if clearQueue { buffer.removeAll() }
        stateMachine.transition(to: .disconnected)
        emit(.disconnected(PTWebSocketCloseContext(code: .normal, reason: nil, wasClean: true)))
    }

    public func reconnect() async throws {
        manualDisconnect = false
        await disconnect(clearQueue: false)
        manualDisconnect = false
        try await connect()
    }

    public func send(_ message: PTWebSocketMessage) async throws {
        guard stateMachine.state == .connected else {
            try buffer.enqueue(message)
            return
        }
        do {
            try await transport.send(message)
            recordSent(message)
        } catch {
            try? buffer.enqueue(message)
            throw normalize(error, fallback: PTWebSocketError.send)
        }
    }

    public func enterBackground() {
        inBackground = true
        Task { await disconnect(clearQueue: false) }
    }

    public func enterForeground() async {
        inBackground = false
        guard configuration.automaticallyReconnect else { return }
        try? await reconnect()
    }

    public func metricsSnapshot() -> PTWebSocketMetrics {
        metrics
    }

    private func makeRequest() throws -> URLRequest {
        guard let scheme = configuration.url.scheme?.lowercased(), scheme == "ws" || scheme == "wss" else {
            throw PTWebSocketError.invalidURL
        }
        var request = URLRequest(url: configuration.url)
        configuration.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if !configuration.subprotocols.isEmpty, request.value(forHTTPHeaderField: "Sec-WebSocket-Protocol") == nil {
            request.setValue(configuration.subprotocols.joined(separator: ", "), forHTTPHeaderField: "Sec-WebSocket-Protocol")
        }
        request.timeoutInterval = configuration.connectionTimeout
        return request
    }

    private func transportConfiguration() -> PTWebSocketTransportConfiguration {
        PTWebSocketTransportConfiguration(trustPolicy: configuration.trustPolicy,
                                           connectionTimeout: configuration.connectionTimeout,
                                           waitsForConnectivity: configuration.waitsForConnectivity,
                                           maximumMessageSize: configuration.maximumMessageSize)
    }

    private func handle(_ event: PTWebSocketTransportEvent, generation: UInt64) {
        guard generation == currentGeneration else { return }
        switch event {
        case .opened(let protocolName):
            terminalGenerations.remove(generation)
            stateMachine.transition(to: .connected)
            emit(.connected(protocolName: protocolName))
            startHeartbeat(generation: generation)
            scheduleStableReset(generation: generation)
            Task { await flushBuffer() }
        case .message(let message):
            recordReceived(message)
            emit(.message(message))
        case .closed(let code, let reason):
            handleTerminal(generation: generation, error: nil, context: PTWebSocketCloseContext(code: code, reason: reason, wasClean: true))
        case .failed(let error):
            handleTerminal(generation: generation, error: error, context: PTWebSocketCloseContext(code: nil, reason: error.localizedDescription, wasClean: false))
        }
    }

    private func handleTerminal(generation: UInt64, error: PTWebSocketError?, context: PTWebSocketCloseContext) {
        guard generation == currentGeneration, terminalGenerations.insert(generation).inserted else { return }
        heartbeatTask?.cancel()
        heartbeatTask = nil
        stateMachine.transition(to: error == nil ? .disconnected : .failed)
        if let error {
            emit(.failed(error))
            log(error: error)
        }
        emit(.disconnected(context))
        if error != nil, shouldReconnect { scheduleReconnect() }
    }

    private var shouldReconnect: Bool {
        configuration.automaticallyReconnect && !manualDisconnect && !inBackground && configuration.reconnectPolicy.maxAttempts > reconnectAttempt
    }

    private func scheduleReconnect() {
        guard reconnectTask == nil, shouldReconnect else { return }
        reconnectAttempt += 1
        let delay = configuration.reconnectPolicy.delay(for: reconnectAttempt, randomUnit: Double.random(in: 0...1))
        emit(.reconnecting(PTWebSocketReconnectContext(attempt: reconnectAttempt, delay: delay)))
        metrics = PTWebSocketMetrics(sentMessageCount: metrics.sentMessageCount,
                                     receivedMessageCount: metrics.receivedMessageCount,
                                     sentByteCount: metrics.sentByteCount,
                                     receivedByteCount: metrics.receivedByteCount,
                                     reconnectCount: metrics.reconnectCount + 1,
                                     lastPingRoundTripTime: metrics.lastPingRoundTripTime)
        reconnectTask = Task { [weak self] in
            do { try await Task.sleep(for: delay) } catch { return }
            guard let self, !Task.isCancelled else { return }
            if let provider = self.authRefreshProvider, let token = try? await provider.refreshToken() {
                await self.updateToken(token)
            }
            await self.finishReconnectAttempt()
        }
    }

    private func finishReconnectAttempt() async {
        reconnectTask = nil
        guard !manualDisconnect, !inBackground else { return }
        do { try await connect() }
        catch { if shouldReconnect { scheduleReconnect() } }
    }

    private func updateToken(_ token: String) {
        if configuration.headers.keys.contains(where: { $0.caseInsensitiveCompare("Authorization") == .orderedSame }) {
            configuration.headers["Authorization"] = "Bearer \(token)"
        }
        if configuration.headers.keys.contains(where: { $0.caseInsensitiveCompare("token") == .orderedSame }) {
            configuration.headers["token"] = token
        }
    }

    private func flushBuffer() async {
        while let message = buffer.removeFirst() {
            do {
                try await transport.send(message)
                recordSent(message)
            } catch {
                buffer.prepend(message)
                return
            }
        }
    }

    private func startHeartbeat(generation: UInt64) {
        heartbeatTask?.cancel()
        guard heartbeatEnabled else { return }
        let interval = configuration.heartbeat.interval
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: interval) } catch { return }
                guard let self, !Task.isCancelled else { return }
                do {
                    let rtt = try await self.pingWithTimeout()
                    await self.recordPong(rtt)
                } catch {
                    await self.handleTerminal(generation: generation,
                                              error: .pingTimeout,
                                              context: PTWebSocketCloseContext(code: nil, reason: PTWebSocketError.pingTimeout.localizedDescription, wasClean: false))
                    return
                }
            }
        }
    }

    private func pingWithTimeout() async throws -> Duration {
        let transport = self.transport
        let timeout = configuration.heartbeat.timeout
        return try await withThrowingTaskGroup(of: Duration.self) { group in
            group.addTask { try await transport.ping() }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw PTWebSocketError.pingTimeout
            }
            defer { group.cancelAll() }
            guard let result = try await group.next() else { throw PTWebSocketError.pingTimeout }
            return result
        }
    }

    private func recordPong(_ rtt: Duration) {
        metrics = PTWebSocketMetrics(sentMessageCount: metrics.sentMessageCount,
                                     receivedMessageCount: metrics.receivedMessageCount,
                                     sentByteCount: metrics.sentByteCount,
                                     receivedByteCount: metrics.receivedByteCount,
                                     reconnectCount: metrics.reconnectCount,
                                     lastPingRoundTripTime: rtt)
        emit(.pong(PTWebSocketPongContext(roundTripTime: rtt)))
    }

    private func scheduleStableReset(generation: UInt64) {
        stableTask?.cancel()
        let threshold = configuration.stabilityThreshold
        guard threshold > 0 else { return }
        stableTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(threshold)) } catch { return }
            guard let self, !Task.isCancelled else { return }
            await self.resetReconnectBudget(generation: generation)
        }
    }

    private func resetReconnectBudget(generation: UInt64) {
        guard generation == currentGeneration, stateMachine.state == .connected else { return }
        reconnectAttempt = 0
    }

    private func emit(_ event: PTWebSocketEvent) {
        eventContinuation.yield(event)
        for continuation in eventSubscribers.values { continuation.yield(event) }
        if case .message(let message) = event { messageContinuation.yield(message) }
    }

    private func normalize(_ error: Error, fallback: (String) -> PTWebSocketError) -> PTWebSocketError {
        if let error = error as? PTWebSocketError { return error }
        let nsError = error as NSError
        return fallback("\(nsError.domain) (\(nsError.code)): \(nsError.localizedDescription)")
    }

    private func recordSent(_ message: PTWebSocketMessage) {
        metrics = PTWebSocketMetrics(sentMessageCount: metrics.sentMessageCount + 1,
                                     receivedMessageCount: metrics.receivedMessageCount,
                                     sentByteCount: metrics.sentByteCount + message.byteCount,
                                     receivedByteCount: metrics.receivedByteCount,
                                     reconnectCount: metrics.reconnectCount,
                                     lastPingRoundTripTime: metrics.lastPingRoundTripTime)
    }

    private func recordReceived(_ message: PTWebSocketMessage) {
        metrics = PTWebSocketMetrics(sentMessageCount: metrics.sentMessageCount,
                                     receivedMessageCount: metrics.receivedMessageCount + 1,
                                     sentByteCount: metrics.sentByteCount,
                                     receivedByteCount: metrics.receivedByteCount + message.byteCount,
                                     reconnectCount: metrics.reconnectCount,
                                     lastPingRoundTripTime: metrics.lastPingRoundTripTime)
    }

    private func log(error: PTWebSocketError) {
#if canImport(PToolsLogging)
        PTLogger.error(error, category: .network, metadata: ["component": "PTWebSocketClient"])
#endif
    }
}

private extension PTWebSocketMessage {
    var byteCount: UInt64 {
        switch self {
        case .text(let value): return UInt64(value.utf8.count)
        case .data(let data): return UInt64(data.count)
        }
    }
}

private extension Duration {
    var ptSeconds: Double {
        let value = components
        return Double(value.seconds) + Double(value.attoseconds) / 1_000_000_000_000_000_000
    }
}

private extension PTWebSocketTransportEvent {
    var error: PTWebSocketError? {
        if case .failed(let error) = self { return error }
        return nil
    }
}

public typealias PTWebSocketCore = PTWebSocketClient
