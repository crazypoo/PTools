// English: SSE parser and reconnecting realtime client; WebSocket remains delegated to SocketKit.
// Español: Parser SSE y cliente realtime con reconexión; WebSocket sigue delegado a SocketKit.
// 中文：SSE 解析器与可重连实时客户端，WebSocket 继续复用 SocketKit。

import Foundation
#if SWIFT_PACKAGE
import PToolsRealtimeCore
import PooToolsSocketKit
#endif

public actor PTRealtimeClient {
    private let configuration: PTRealtimeConfiguration
    private var task: Task<Void, Never>?
    private var continuation: AsyncStream<PTRealtimeEvent>.Continuation?
    private var statusContinuation: AsyncStream<PTRealtimeStatus>.Continuation?
    private var lastEventID: String?
    private var serverReconnectDelay: Duration?
    private var reconnectAttempt = 0
    private var subscriptions: [PTRealtimeSubscriptionID: PTRealtimeSubscription] = [:]

    public init(configuration: PTRealtimeConfiguration) {
        self.configuration = configuration
        self.lastEventID = configuration.lastEventID
    }

    public func events() -> AsyncStream<PTRealtimeEvent> {
        AsyncStream { continuation in self.continuation = continuation }
    }

    public func statuses() -> AsyncStream<PTRealtimeStatus> {
        AsyncStream { continuation in self.statusContinuation = continuation }
    }

    public func start() {
        guard task == nil else { return }
        guard configuration.transport == .serverSentEvents else { return }
        statusContinuation?.yield(.connecting)
        task = Task { [weak self] in await self?.runSSE() }
    }

    public func stop() {
        task?.cancel()
        task = nil
        continuation?.finish()
        continuation = nil
        statusContinuation?.yield(.stopped)
        statusContinuation?.finish()
        statusContinuation = nil
    }

    public func reconnectNow() {
        guard configuration.transport == .serverSentEvents else { return }
        task?.cancel()
        task = nil
        task = Task { [weak self] in await self?.runSSE() }
    }

    public func notifyConnectivityRestored() {
        reconnectNow()
    }

    public func notifyAppDidBecomeActive() {
        reconnectNow()
    }

    public func lastReceivedEventID() -> String? {
        lastEventID
    }

    public func subscribe(_ subscription: PTRealtimeSubscription) throws {
        guard !subscription.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PTRealtimeError.invalidSubscription
        }
        subscriptions[subscription.id] = subscription
    }

    public func unsubscribe(_ id: PTRealtimeSubscriptionID) {
        subscriptions[id] = nil
    }

    public func activeSubscriptions() -> [PTRealtimeSubscription] {
        Array(subscriptions.values).sorted { $0.id.rawValue < $1.id.rawValue }
    }

    private func runSSE() async {
        while !Task.isCancelled {
            do {
                var request = URLRequest(url: configuration.url)
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                if let lastEventID { request.setValue(lastEventID, forHTTPHeaderField: "Last-Event-ID") }
                let (bytes, response) = try await URLSession.shared.bytes(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) else {
                    let httpResponse = response as? HTTPURLResponse
                    throw PTRealtimeError.invalidResponse(statusCode: httpResponse?.statusCode ?? 0,
                                                          contentType: httpResponse?.value(forHTTPHeaderField: "Content-Type"))
                }
                let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased()
                guard contentType?.contains("text/event-stream") == true else {
                    throw PTRealtimeError.invalidResponse(statusCode: httpResponse.statusCode,
                                                          contentType: contentType)
                }
                reconnectAttempt = 0
                statusContinuation?.yield(.connected)
                var parser = PTSSEParser()
                for try await line in bytes.lines {
                    if let event = parser.consume(line) {
                        lastEventID = event.id ?? lastEventID
                        if let retryAfter = event.retryAfter { serverReconnectDelay = retryAfter }
                        continuation?.yield(event)
                    }
                }
                if let retryAfter = parser.reconnectDelay { serverReconnectDelay = retryAfter }
                if let event = parser.finish() { continuation?.yield(event) }
            } catch is CancellationError {
                return
            } catch {
                reconnectAttempt += 1
                if configuration.maxReconnectAttempts > 0,
                   reconnectAttempt > configuration.maxReconnectAttempts {
                    statusContinuation?.yield(.failed(.retryLimitReached))
                    return
                }
                let delay = nextReconnectDelay(for: reconnectAttempt)
                statusContinuation?.yield(.reconnecting(attempt: reconnectAttempt, delay: delay))
                do { try await Task.sleep(for: delay) } catch { return }
            }
        }
    }

    private func nextReconnectDelay(for attempt: Int) -> Duration {
        if let serverReconnectDelay { return min(serverReconnectDelay, configuration.maxReconnectDelay) }
        let base = max(0.05, Self.seconds(configuration.reconnectDelay))
        let seconds = min(Self.seconds(configuration.maxReconnectDelay),
                          base * pow(2, Double(max(0, attempt - 1))))
        return .seconds(seconds)
    }

    private static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds)
            + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
    }
}

// English: Reuse the existing PTools WebSocket actor instead of introducing a second socket implementation.
// Español: Reutiliza el actor WebSocket existente de PTools en lugar de introducir otra implementación de sockets.
// 中文：复用 PTools 现有 WebSocket actor，不再创建第二套 Socket 实现。
public actor PTWebSocketRealtimeAdapter {
    private let client: PTWebSocketClient
    private let heartbeatInterval: Duration?
    private let heartbeatTimeout: Duration
    private var heartbeatTask: Task<Void, Never>?
    private var subscriptions: [PTRealtimeSubscriptionID: PTRealtimeSubscription] = [:]

    public init(client: PTWebSocketClient,
                heartbeatInterval: Duration? = nil,
                heartbeatTimeout: Duration = .seconds(15)) {
        self.client = client
        self.heartbeatInterval = heartbeatInterval
        self.heartbeatTimeout = heartbeatTimeout
    }

    public func start() async throws {
        try await client.connect()
        startHeartbeatIfNeeded()
    }

    public func stop() async {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        await client.disconnect(clearQueue: false)
    }

    public func send(_ event: PTRealtimeEvent) async throws {
        try await client.send(.text(event.data))
    }

    public func subscribe(_ subscription: PTRealtimeSubscription) async throws {
        guard !subscription.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PTRealtimeError.invalidSubscription
        }
        subscriptions[subscription.id] = subscription
        let payload = "{\"type\":\"subscribe\",\"topic\":\(jsonLiteral(subscription.topic))}"
        try await client.send(.text(payload))
    }

    public func unsubscribe(_ id: PTRealtimeSubscriptionID) async throws {
        guard let subscription = subscriptions.removeValue(forKey: id) else { return }
        let payload = "{\"type\":\"unsubscribe\",\"topic\":\(jsonLiteral(subscription.topic))}"
        try await client.send(.text(payload))
    }

    public func activeSubscriptions() -> [PTRealtimeSubscription] {
        Array(subscriptions.values).sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public func events() -> AsyncStream<PTRealtimeEvent> {
        let messages = client.messages
        return AsyncStream { continuation in
            Task {
                for await message in messages {
                    switch message {
                    case .text(let value): continuation.yield(PTRealtimeEvent(data: value))
                    case .data(let value):
                        continuation.yield(PTRealtimeEvent(data: String(decoding: value, as: UTF8.self)))
                    }
                }
                continuation.finish()
            }
        }
    }

    private func startHeartbeatIfNeeded() {
        guard heartbeatTask == nil, let heartbeatInterval else { return }
        let timeout = heartbeatTimeout
        heartbeatTask = Task { [weak self, client] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: heartbeatInterval)
                    _ = try await withThrowingTaskGroup(of: Duration.self) { group in
                        group.addTask { try await client.ping() }
                        group.addTask {
                            try await Task.sleep(for: timeout)
                            throw PTRealtimeError.heartbeatTimeout
                        }
                        defer { group.cancelAll() }
                        guard let result = try await group.next() else {
                            throw PTRealtimeError.heartbeatTimeout
                        }
                        return result
                    }
                } catch is CancellationError {
                    return
                } catch {
                    await self?.stop()
                    return
                }
            }
        }
    }

    private func jsonLiteral(_ value: String) -> String {
        let data = (try? JSONEncoder().encode(value)) ?? Data("\"\"".utf8)
        return String(data: data, encoding: .utf8) ?? "\"\""
    }
}
