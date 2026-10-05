// English: Foundation-only realtime contracts for WebSocket and Server-Sent Events.
// Español: Contratos solo de Foundation para WebSocket y Server-Sent Events.
// 中文：WebSocket 与 Server-Sent Events 的 Foundation-only 实时通信契约。

import Foundation

public enum PTRealtimeTransport: Sendable, Equatable {
    case webSocket
    case serverSentEvents
}

public struct PTRealtimeEvent: Sendable, Codable, Equatable {
    public let event: String?
    public let data: String
    public let id: String?
    public let retryAfter: Duration?
    public init(event: String? = nil,
                data: String,
                id: String? = nil,
                retryAfter: Duration? = nil) {
        self.event = event
        self.data = data
        self.id = id
        self.retryAfter = retryAfter
    }
}

public struct PTRealtimeConfiguration: Sendable, Equatable {
    public let url: URL
    public let transport: PTRealtimeTransport
    public let reconnectDelay: Duration
    public let maxReconnectDelay: Duration
    public let maxReconnectAttempts: Int
    public let heartbeatInterval: Duration?
    public let heartbeatTimeout: Duration
    public let lastEventID: String?
    public init(url: URL,
                transport: PTRealtimeTransport,
                reconnectDelay: Duration = .seconds(1),
                lastEventID: String? = nil,
                maxReconnectDelay: Duration = .seconds(60),
                maxReconnectAttempts: Int = 0,
                heartbeatInterval: Duration? = nil,
                heartbeatTimeout: Duration = .seconds(15)) {
        self.url = url
        self.transport = transport
        self.reconnectDelay = reconnectDelay
        self.lastEventID = lastEventID
        self.maxReconnectDelay = maxReconnectDelay
        self.maxReconnectAttempts = max(0, maxReconnectAttempts)
        self.heartbeatInterval = heartbeatInterval
        self.heartbeatTimeout = heartbeatTimeout
    }
}

public struct PTRealtimeSubscriptionID: Codable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

public struct PTRealtimeSubscription: Codable, Hashable, Sendable {
    public let id: PTRealtimeSubscriptionID
    public let topic: String

    public init(topic: String, id: PTRealtimeSubscriptionID? = nil) {
        self.topic = topic
        self.id = id ?? PTRealtimeSubscriptionID(topic)
    }
}

public enum PTRealtimeError: Error, Sendable, Equatable {
    case invalidURL
    case disconnected
    case parseFailed
    case retryLimitReached
    case invalidResponse(statusCode: Int, contentType: String?)
    case heartbeatTimeout
    case invalidSubscription
    case failed(String)
}

public enum PTRealtimeStatus: Sendable, Equatable {
    case idle
    case connecting
    case connected
    case reconnecting(attempt: Int, delay: Duration)
    case stopped
    case failed(PTRealtimeError)
}

// English: Keep SSE framing in the Foundation-only core so parsing can be tested without UIKit or SocketKit.
// Español: Mantiene el framing SSE en el core solo de Foundation para probarlo sin UIKit ni SocketKit.
// 中文：将 SSE 帧解析放在 Foundation-only Core，避免测试依赖 UIKit 或 SocketKit。
public struct PTSSEParser: Sendable {
    private var event: String?
    private var id: String?
    private var dataLines: [String] = []
    private var retryAfter: Duration?

    public var reconnectDelay: Duration? { retryAfter }

    public init() {}

    public mutating func consume(_ line: String) -> PTRealtimeEvent? {
        if line.isEmpty || line == "\r" {
            guard !dataLines.isEmpty else { reset(); return nil }
            let result = PTRealtimeEvent(event: event,
                                         data: dataLines.joined(separator: "\n"),
                                         id: id,
                                         retryAfter: retryAfter)
            reset()
            return result
        }
        let value = line.hasPrefix("data:") ? String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces) : nil
        if let value { dataLines.append(value); return nil }
        if line.hasPrefix("event:") { event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces); return nil }
        if line.hasPrefix("id:") { id = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces); return nil }
        if line.hasPrefix("retry:") {
            let milliseconds = Int(String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)) ?? 0
            retryAfter = milliseconds > 0 ? .milliseconds(milliseconds) : nil
            return nil
        }
        return nil
    }

    public mutating func finish() -> PTRealtimeEvent? { consume("") }

    private mutating func reset() {
        event = nil
        id = nil
        dataLines.removeAll(keepingCapacity: true)
    }
}
