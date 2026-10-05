// English: Privacy-aware, Sendable observability contracts shared by all PTools modules.
// Español: Contratos de observabilidad Sendable y conscientes de la privacidad compartidos por PTools.
// 中文：所有 PTools 模块共享的隐私友好、Sendable 可观测性契约。

import Foundation

public struct PTTraceID: Codable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String = UUID().uuidString.lowercased()) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

public struct PTSpanID: Codable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String = UUID().uuidString.lowercased()) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

public struct PTSpanContext: Codable, Hashable, Sendable {
    public let traceID: PTTraceID
    public let spanID: PTSpanID
    public let parentSpanID: PTSpanID?

    public init(traceID: PTTraceID = .init(),
                spanID: PTSpanID = .init(),
                parentSpanID: PTSpanID? = nil) {
        self.traceID = traceID
        self.spanID = spanID
        self.parentSpanID = parentSpanID
    }
}

// English: Keep the observability value type distinct from the existing Debug tracing facade.
// Español: Mantiene este valor de observabilidad separado de la fachada de trazas Debug existente.
// 中文：让可观测性值类型与现有 Debug 追踪门面保持不同名称，避免模块内符号冲突。
public struct PTObservabilityTrace: Codable, Hashable, Sendable {
    public let traceID: PTTraceID
    public let sessionID: String?
    public init(traceID: PTTraceID = .init(), sessionID: String? = nil) {
        self.traceID = traceID
        self.sessionID = sessionID
    }
}

public struct PTUserContext: Codable, Hashable, Sendable {
    public let userID: String?
    public init(userID: String? = nil) { self.userID = userID }
}

public struct PTDeviceContext: Codable, Hashable, Sendable {
    public let family: String
    public let osVersion: String
    public init(family: String, osVersion: String) {
        self.family = family
        self.osVersion = osVersion
    }
}

public struct PTNetworkContext: Codable, Hashable, Sendable {
    public let requestID: String?
    public let statusCode: Int?
    public let duration: TimeInterval?
    public init(requestID: String? = nil, statusCode: Int? = nil, duration: TimeInterval? = nil) {
        self.requestID = requestID
        self.statusCode = statusCode
        self.duration = duration
    }
}

public struct PTSessionContext: Codable, Hashable, Sendable {
    public let sessionID: String
    public let startedAt: Date
    public init(sessionID: String = UUID().uuidString, startedAt: Date = .now) {
        self.sessionID = sessionID
        self.startedAt = startedAt
    }
}

public struct PTObservabilityContext: Codable, Hashable, Sendable {
    public let values: [String: String]
    public init(values: [String: String] = [:]) { self.values = values }
}

public struct PTObservabilityEvent: Codable, Hashable, Sendable {
    public let name: String
    public let timestamp: Date
    public let attributes: [String: String]
    public let context: PTObservabilityContext
    public let spanContext: PTSpanContext?

    public init(name: String,
                attributes: [String: String] = [:],
                context: PTObservabilityContext = .init(),
                spanContext: PTSpanContext? = nil,
                timestamp: Date = .now) {
        self.name = name
        self.attributes = attributes
        self.context = context
        self.spanContext = spanContext
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
    public let context: PTSpanContext
    public init(name: String,
                duration: TimeInterval,
                attributes: [String: String] = [:],
                context: PTSpanContext = .init()) {
        self.name = name
        self.duration = duration
        self.attributes = attributes
        self.context = context
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
    public let samplingPolicy: PTObservabilitySamplingPolicy
    public let redactedKeys: Set<String>
    public let bufferLimit: Int
    public let maximumPayloadBytes: Int
    public init(sampleRate: Double = 1,
                samplingPolicy: PTObservabilitySamplingPolicy = .init(),
                redactedKeys: Set<String> = ["authorization", "cookie", "token", "password"],
                bufferLimit: Int = 200,
                maximumPayloadBytes: Int = 64 * 1024) {
        self.sampleRate = min(max(sampleRate, 0), 1)
        self.samplingPolicy = samplingPolicy
        self.redactedKeys = redactedKeys
        self.bufferLimit = max(bufferLimit, 1)
        self.maximumPayloadBytes = max(1, maximumPayloadBytes)
    }
}

public enum PTObservabilityRecordKind: String, Codable, Hashable, Sendable {
    case event
    case metric
    case breadcrumb
    case span
    case error
}

public struct PTObservabilitySamplingPolicy: Codable, Hashable, Sendable, Equatable {
    public let errorRate: Double
    public let traceRate: Double
    public let networkRate: Double
    public let debugRate: Double
    public let deterministic: Bool

    public init(errorRate: Double = 1,
                traceRate: Double = 1,
                networkRate: Double = 1,
                debugRate: Double = 1,
                deterministic: Bool = false) {
        self.errorRate = min(max(errorRate, 0), 1)
        self.traceRate = min(max(traceRate, 0), 1)
        self.networkRate = min(max(networkRate, 0), 1)
        self.debugRate = min(max(debugRate, 0), 1)
        self.deterministic = deterministic
    }

    public func rate(for kind: PTObservabilityRecordKind, fallback: Double) -> Double {
        switch kind {
        case .error: return errorRate
        case .span: return traceRate
        case .event: return networkRate
        case .metric, .breadcrumb: return min(max(fallback, 0), 1)
        }
    }
}

public enum PTObservabilityRecord: Codable, Hashable, Sendable {
    case event(PTObservabilityEvent)
    case metric(PTObservabilityMetric)
    case breadcrumb(PTObservabilityBreadcrumb)
    case span(PTObservabilitySpan)
    case error(PTObservabilityErrorSnapshot)

    public var kind: PTObservabilityRecordKind {
        switch self {
        case .event: return .event
        case .metric: return .metric
        case .breadcrumb: return .breadcrumb
        case .span: return .span
        case .error: return .error
        }
    }
}

public protocol PTObservabilitySink: Sendable {
    func receive(_ record: PTObservabilityRecord) async
}
