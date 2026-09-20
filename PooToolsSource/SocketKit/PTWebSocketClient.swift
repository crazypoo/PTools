// English: Native WebSocket transport for iOS 17+ with an actor-owned lifecycle.
// Español: Transporte WebSocket nativo para iOS 17+ con un ciclo de vida propiedad de un actor.
// 中文：面向 iOS 17+ 的原生 WebSocket 传输，由 actor 统一持有生命周期。

import Foundation
import Network
import UIKit

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

public enum PTWebSocketError: Error, LocalizedError, Sendable {
    case invalidURL
    case notConnected
    case queueFull
    case connectionFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "WebSocket URL 无效 / Invalid WebSocket URL / URL WebSocket no válida"
        case .notConnected: return "WebSocket 尚未连接 / WebSocket is not connected / WebSocket no está conectado"
        case .queueFull: return "WebSocket 发送队列已满 / WebSocket send queue is full / La cola de envío WebSocket está llena"
        case .connectionFailed(let message): return message
        case .cancelled: return "WebSocket 操作已取消 / WebSocket operation cancelled / Operación WebSocket cancelada"
        }
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

    public init(url: URL,
                headers: [String: String] = [:],
                heartbeatInterval: TimeInterval = 30,
                heartbeatTimeout: TimeInterval = 15,
                maxReconnectAttempts: Int = 10,
                reconnectBaseDelay: TimeInterval = 1,
                maxQueuedMessages: Int = 1000,
                automaticallyReconnect: Bool = true) {
        self.url = url
        self.headers = headers
        self.heartbeatInterval = max(1, heartbeatInterval)
        self.heartbeatTimeout = max(1, heartbeatTimeout)
        self.maxReconnectAttempts = max(0, maxReconnectAttempts)
        self.reconnectBaseDelay = max(0, reconnectBaseDelay)
        self.maxQueuedMessages = max(1, maxQueuedMessages)
        self.automaticallyReconnect = automaticallyReconnect
    }
}

// English: URLSessionWebSocketTask is isolated inside this actor; callers exchange only value snapshots.
// Español: URLSessionWebSocketTask queda aislado dentro de este actor; los llamadores solo intercambian valores.
// 中文：URLSessionWebSocketTask 只存在于 actor 内部，调用方只交换值类型快照。
public actor PTWebSocketClient {
    public let messages: AsyncStream<PTWebSocketMessage>

    private var streamContinuation: AsyncStream<PTWebSocketMessage>.Continuation?
    private var configuration: PTWebSocketConfiguration
    private let authRefreshProvider: (any PTNetworkAuthRefreshProvider)?
    private var session: URLSession?
    private var socket: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var lifecycleTask: Task<Void, Never>?
    private var foregroundLifecycleTask: Task<Void, Never>?
    private var pathMonitor: NWPathMonitor?
    private var pathQueue: DispatchQueue?
    private var queuedMessages: [PTWebSocketMessage] = []
    private var reconnectAttempt = 0
    private var isInBackground = false
    private var connectionState: PTWebSocketState = .idle

    public var state: PTWebSocketState { connectionState }

    public init(configuration: PTWebSocketConfiguration,
                authRefreshProvider: (any PTNetworkAuthRefreshProvider)? = nil) {
        self.configuration = configuration
        self.authRefreshProvider = authRefreshProvider
        var continuation: AsyncStream<PTWebSocketMessage>.Continuation?
        self.messages = AsyncStream { continuation = $0 }
        self.streamContinuation = continuation
        Task { [weak self] in
            await self?.startMonitors()
        }
    }

    deinit {
        receiveTask?.cancel()
        heartbeatTask?.cancel()
        reconnectTask?.cancel()
        lifecycleTask?.cancel()
        foregroundLifecycleTask?.cancel()
        pathMonitor?.cancel()
        session?.invalidateAndCancel()
        streamContinuation?.finish()
    }

    public func update(headers: [String: String]) {
        configuration.headers = headers
    }

    public func connect() async throws {
        guard !isInBackground else { return }
        switch connectionState {
        case .connecting, .connected:
            return
        case .disconnecting:
            throw PTWebSocketError.connectionFailed("WebSocket 正在断开 / WebSocket is disconnecting / WebSocket se está desconectando")
        case .idle, .reconnecting, .disconnected, .failed:
            break
        }

        connectionState = .connecting
        let request = try makeRequest()
        let session = URLSession(configuration: .default)
        let socket = session.webSocketTask(with: request)
        self.session = session
        self.socket = socket
        socket.resume()
        connectionState = .connected
        reconnectAttempt = 0
        startReceiveLoop()
        startHeartbeat()
        try await flushQueuedMessages()
    }

    public func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        receiveTask?.cancel()
        heartbeatTask?.cancel()
        receiveTask = nil
        heartbeatTask = nil
        connectionState = .disconnecting
        socket?.cancel(with: .normalClosure, reason: nil)
        session?.invalidateAndCancel()
        socket = nil
        session = nil
        connectionState = .disconnected
    }

    public func reconnect() async throws {
        connectionState = .reconnecting
        disconnect()
        connectionState = .reconnecting
        try await connect()
    }

    public func send(_ message: PTWebSocketMessage) async throws {
        guard connectionState == .connected, socket != nil else {
            guard queuedMessages.count < configuration.maxQueuedMessages else {
                throw PTWebSocketError.queueFull
            }
            queuedMessages.append(message)
            return
        }
        try await sendImmediately(message)
    }

    public func enterBackground() {
        isInBackground = true
        disconnect()
    }

    public func enterForeground() async {
        isInBackground = false
        guard configuration.automaticallyReconnect else { return }
        try? await reconnect()
    }

    private func makeRequest() throws -> URLRequest {
        guard configuration.url.scheme?.lowercased() == "ws" || configuration.url.scheme?.lowercased() == "wss" else {
            throw PTWebSocketError.invalidURL
        }
        var request = URLRequest(url: configuration.url)
        configuration.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return request
    }

    private func sendImmediately(_ message: PTWebSocketMessage) async throws {
        guard let socket else { throw PTWebSocketError.notConnected }
        let taskMessage: URLSessionWebSocketTask.Message
        switch message {
        case .text(let value): taskMessage = .string(value)
        case .data(let value): taskMessage = .data(value)
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            socket.send(taskMessage) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }

    private func flushQueuedMessages() async throws {
        let pending = queuedMessages
        queuedMessages.removeAll(keepingCapacity: true)
        for message in pending {
            do {
                try await sendImmediately(message)
            } catch {
                queuedMessages.insert(message, at: 0)
                throw error
            }
        }
    }

    private func startReceiveLoop() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    let message = try await self.receiveOnce()
                    await self.publish(message)
                } catch {
                    await self.handleConnectionFailure(error)
                    return
                }
            }
        }
    }

    private func receiveOnce() async throws -> PTWebSocketMessage {
        guard let socket else { throw PTWebSocketError.notConnected }
        let message = try await socket.receive()
        switch message {
        case .string(let value): return .text(value)
        case .data(let value): return .data(value)
        @unknown default: throw PTWebSocketError.connectionFailed("未知 WebSocket 消息 / Unknown WebSocket message / Mensaje WebSocket desconocido")
        }
    }

    private func publish(_ message: PTWebSocketMessage) {
        streamContinuation?.yield(message)
    }

    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(self.configuration.heartbeatInterval))
                    guard !Task.isCancelled else { return }
                    let success = await self.sendPingWithTimeout()
                    if !success {
                        await self.handleConnectionFailure(PTWebSocketError.connectionFailed("WebSocket 心跳超时 / WebSocket heartbeat timed out / Tiempo de espera del heartbeat WebSocket agotado"))
                        return
                    }
                } catch {
                    return
                }
            }
        }
    }

    private func sendPingWithTimeout() async -> Bool {
        guard let socket else { return false }
        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    socket.sendPing { error in continuation.resume(returning: error == nil) }
                }
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(self.configuration.heartbeatTimeout))
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }
    }

    private func handleConnectionFailure(_ error: Error) {
        guard connectionState != .disconnecting, connectionState != .disconnected else { return }
        connectionState = .failed
        receiveTask?.cancel()
        heartbeatTask?.cancel()
        if configuration.automaticallyReconnect && !isInBackground {
            scheduleReconnect()
        }
        PTNSLogConsole("PTWebSocketClient: \(error.localizedDescription)", levelType: .error, loggerType: .network)
    }

    private func scheduleReconnect() {
        guard reconnectTask == nil else { return }
        guard reconnectAttempt < configuration.maxReconnectAttempts else { return }
        reconnectAttempt += 1
        let delay = min(configuration.reconnectBaseDelay * pow(2, Double(reconnectAttempt - 1)), 60)
        reconnectTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            if let provider = self.authRefreshProvider {
                if let token = try? await provider.refreshToken() {
                    await self.updateToken(token)
                }
            }
            try? await self.reconnect()
            await self.clearReconnectTask()
        }
    }

    private func clearReconnectTask() {
        reconnectTask = nil
    }

    private func updateToken(_ token: String) {
        if configuration.headers.keys.contains(where: { $0.caseInsensitiveCompare("Authorization") == .orderedSame }) {
            configuration.headers["Authorization"] = "Bearer \(token)"
        }
        if configuration.headers.keys.contains(where: { $0.caseInsensitiveCompare("token") == .orderedSame }) {
            configuration.headers["token"] = token
        }
    }

    private func startPathMonitoring() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.ptools.websocket.path")
        monitor.pathUpdateHandler = { [weak self] path in
            let isSatisfied = path.status == .satisfied
            Task { [weak self] in await self?.pathChanged(isSatisfied) }
        }
        monitor.start(queue: queue)
        pathMonitor = monitor
        pathQueue = queue
    }

    private func pathChanged(_ isSatisfied: Bool) {
        guard isSatisfied, connectionState == .failed, configuration.automaticallyReconnect else { return }
        scheduleReconnect()
    }

    private func startLifecycleMonitoring() {
        lifecycleTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
                guard !Task.isCancelled else { return }
                await self?.enterBackground()
            }
        }
        foregroundLifecycleTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                guard !Task.isCancelled else { return }
                await self?.enterForeground()
            }
        }
    }

    private func startMonitors() {
        startPathMonitoring()
        startLifecycleMonitoring()
    }
}
