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
    private var lastEventID: String?

    public init(configuration: PTRealtimeConfiguration) {
        self.configuration = configuration
        self.lastEventID = configuration.lastEventID
    }

    public func events() -> AsyncStream<PTRealtimeEvent> {
        AsyncStream { continuation in self.continuation = continuation }
    }

    public func start() {
        task?.cancel()
        guard configuration.transport == .serverSentEvents else { return }
        task = Task { [weak self] in await self?.runSSE() }
    }

    public func stop() {
        task?.cancel(); task = nil; continuation?.finish(); continuation = nil
    }

    private func runSSE() async {
        while !Task.isCancelled {
            do {
                var request = URLRequest(url: configuration.url)
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                if let lastEventID { request.setValue(lastEventID, forHTTPHeaderField: "Last-Event-ID") }
                let (bytes, _) = try await URLSession.shared.bytes(for: request)
                var parser = PTSSEParser()
                for try await line in bytes.lines {
                    if let event = parser.consume(line) {
                        lastEventID = event.id ?? lastEventID
                        continuation?.yield(event)
                    }
                }
                if let event = parser.finish() { continuation?.yield(event) }
            } catch is CancellationError {
                return
            } catch {
                try? await Task.sleep(for: configuration.reconnectDelay)
            }
        }
    }
}

#if SWIFT_PACKAGE
// English: Reuse the existing PTools WebSocket actor instead of introducing a second socket implementation.
// Español: Reutiliza el actor WebSocket existente de PTools en lugar de introducir otra implementación de sockets.
// 中文：复用 PTools 现有 WebSocket actor，不再创建第二套 Socket 实现。
public actor PTWebSocketRealtimeAdapter {
    private let client: PTWebSocketClient

    public init(client: PTWebSocketClient) {
        self.client = client
    }

    public func start() async throws {
        try await client.connect()
    }

    public func stop() async {
        await client.disconnect(clearQueue: false)
    }

    public func send(_ event: PTRealtimeEvent) async throws {
        try await client.send(.text(event.data))
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
}
#endif
