// English: Privacy-aware, Sendable observability contracts shared by all PTools modules.
// Español: Contratos de observabilidad Sendable y conscientes de la privacidad compartidos por PTools.
// 中文：所有 PTools 模块共享的隐私友好、Sendable 可观测性契约。

import Foundation

public struct PTObservabilityContext: Codable, Hashable, Sendable {
    public let values: [String: String]
    public init(values: [String: String] = [:]) { self.values = values }
}

public struct PTObservabilityEvent: Codable, Hashable, Sendable {
    public let name: String
    public let timestamp: Date
    public let attributes: [String: String]
    public let context: PTObservabilityContext

    public init(name: String,
                attributes: [String: String] = [:],
                context: PTObservabilityContext = .init(),
                timestamp: Date = .now) {
        self.name = name
        self.attributes = attributes
        self.context = context
        self.timestamp = timestamp
    }
}

public struct PTObservabilityMetric: Codable, Hashable, Sendable {
    public let name: String
    public let value: Double
    public let unit: String
    public init(name: String, value: Double, unit: String = "") {
        self.name = name; self.value = value; self.unit = unit
    }
}

public struct PTObservabilityBreadcrumb: Codable, Hashable, Sendable {
    public let message: String
    public let category: String
    public init(message: String, category: String = "default") {
        self.message = message; self.category = category
    }
}

public struct PTObservabilitySpan: Codable, Hashable, Sendable {
    public let name: String
    public let duration: TimeInterval
    public let attributes: [String: String]
    public init(name: String, duration: TimeInterval, attributes: [String: String] = [:]) {
        self.name = name; self.duration = duration; self.attributes = attributes
    }
}

public struct PTObservabilityErrorSnapshot: Codable, Hashable, Sendable {
    public let domain: String
    public let code: Int
    public let message: String
    public let context: PTObservabilityContext

    public init(domain: String, code: Int = 0, message: String, context: PTObservabilityContext = .init()) {
        self.domain = domain
        self.code = code
        self.message = message
        self.context = context
    }
}

public struct PTObservabilityConfiguration: Sendable, Equatable {
    public let sampleRate: Double
    public let redactedKeys: Set<String>
    public let bufferLimit: Int
    public init(sampleRate: Double = 1,
                redactedKeys: Set<String> = ["authorization", "cookie", "token", "password"],
                bufferLimit: Int = 200) {
        self.sampleRate = min(max(sampleRate, 0), 1)
        self.redactedKeys = redactedKeys
        self.bufferLimit = max(bufferLimit, 1)
    }
}

public enum PTObservabilityRecord: Codable, Hashable, Sendable {
    case event(PTObservabilityEvent)
    case metric(PTObservabilityMetric)
    case breadcrumb(PTObservabilityBreadcrumb)
    case span(PTObservabilitySpan)
    case error(PTObservabilityErrorSnapshot)
}

public protocol PTObservabilitySink: Sendable {
    func receive(_ record: PTObservabilityRecord) async
}
