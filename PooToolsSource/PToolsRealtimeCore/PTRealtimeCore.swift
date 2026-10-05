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
    public init(event: String? = nil, data: String, id: String? = nil) {
        self.event = event; self.data = data; self.id = id
    }
}

public struct PTRealtimeConfiguration: Sendable, Equatable {
    public let url: URL
    public let transport: PTRealtimeTransport
    public let reconnectDelay: Duration
    public let lastEventID: String?
    public init(url: URL,
                transport: PTRealtimeTransport,
                reconnectDelay: Duration = .seconds(1),
                lastEventID: String? = nil) {
        self.url = url; self.transport = transport; self.reconnectDelay = reconnectDelay; self.lastEventID = lastEventID
    }
}

public enum PTRealtimeError: Error, Sendable, Equatable {
    case invalidURL
    case disconnected
    case parseFailed
    case failed(String)
}

// English: Keep SSE framing in the Foundation-only core so parsing can be tested without UIKit or SocketKit.
// Español: Mantiene el framing SSE en el core solo de Foundation para probarlo sin UIKit ni SocketKit.
// 中文：将 SSE 帧解析放在 Foundation-only Core，避免测试依赖 UIKit 或 SocketKit。
public struct PTSSEParser: Sendable {
    private var event: String?
    private var id: String?
    private var dataLines: [String] = []

    public init() {}

    public mutating func consume(_ line: String) -> PTRealtimeEvent? {
        if line.isEmpty || line == "\r" {
            guard !dataLines.isEmpty else { reset(); return nil }
            let result = PTRealtimeEvent(event: event,
                                         data: dataLines.joined(separator: "\n"),
                                         id: id)
            reset()
            return result
        }
        let value = line.hasPrefix("data:") ? String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces) : nil
        if let value { dataLines.append(value); return nil }
        if line.hasPrefix("event:") { event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces); return nil }
        if line.hasPrefix("id:") { id = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces); return nil }
        return nil
    }

    public mutating func finish() -> PTRealtimeEvent? { consume("") }

    private mutating func reset() {
        event = nil
        id = nil
        dataLines.removeAll(keepingCapacity: true)
    }
}
