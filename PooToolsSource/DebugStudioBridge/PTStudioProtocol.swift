// PTNetwork Studio wire contract. This target is opt-in and never installs a network hook.
import Foundation
#if SWIFT_PACKAGE
import PooToolsDEBUG
#endif

public enum PTStudioSupport: String, Codable, Sendable {
    case supported, limited, notSupported
}

public struct PTNetworkStudioCapabilities: Codable, Sendable, Equatable {
    public let captureHTTP: PTStudioSupport
    public let observeTaskMetrics: PTStudioSupport
    public let observeWebSocketMessages: PTStudioSupport
    public let supportsBackgroundSession: PTStudioSupport
    public let observeWKWebView: PTStudioSupport
    public let observeNetworkFramework: PTStudioSupport

    public init(captureHTTP: PTStudioSupport = .limited,
                observeTaskMetrics: PTStudioSupport = .limited,
                observeWebSocketMessages: PTStudioSupport = .notSupported,
                supportsBackgroundSession: PTStudioSupport = .notSupported,
                observeWKWebView: PTStudioSupport = .notSupported,
                observeNetworkFramework: PTStudioSupport = .notSupported) {
        self.captureHTTP = captureHTTP
        self.observeTaskMetrics = observeTaskMetrics
        self.observeWebSocketMessages = observeWebSocketMessages
        self.supportsBackgroundSession = supportsBackgroundSession
        self.observeWKWebView = observeWKWebView
        self.observeNetworkFramework = observeNetworkFramework
    }

    public static let current = PTNetworkStudioCapabilities()
}

public enum PTStudioMessageKind: String, Codable, Sendable {
    case hello, capabilities, recordUpsert, recordFinalize, recordDelete
    case sessionReset, heartbeat, ack, error
}

public struct PTStudioBodySnapshot: Codable, Sendable, Equatable {
    public let totalBytes: Int64
    public let preview: String?
    public let truncated: Bool
    public let redacted: Bool

    public init(totalBytes: Int64, preview: String?, truncated: Bool, redacted: Bool = true) {
        self.totalBytes = totalBytes
        self.preview = preview
        self.truncated = truncated
        self.redacted = redacted
    }
}

public struct PTStudioCaptureSnapshot: Codable, Sendable, Equatable {
    public let method: String
    public let url: String
    public let requestHeaders: [String: String]
    public let responseHeaders: [String: String]
    public let requestBody: PTStudioBodySnapshot
    public let responseBody: PTStudioBodySnapshot?
    public let status: Int?
    public let durationSeconds: Double?
    public let completion: String?
    public let errorDomain: String?
    public let errorCode: Int?
    public let redirectCount: Int
    public let fetchSource: String?
    public let recordSequence: UInt64
    public let startedAt: Date

    public init(method: String, url: String, requestHeaders: [String: String],
                responseHeaders: [String: String], requestBody: PTStudioBodySnapshot,
                responseBody: PTStudioBodySnapshot?, status: Int?, durationSeconds: Double?,
                completion: String?, errorDomain: String?, errorCode: Int?, redirectCount: Int,
                fetchSource: String?, recordSequence: UInt64, startedAt: Date) {
        self.method = method
        self.url = url
        self.requestHeaders = requestHeaders
        self.responseHeaders = responseHeaders
        self.requestBody = requestBody
        self.responseBody = responseBody
        self.status = status
        self.durationSeconds = durationSeconds
        self.completion = completion
        self.errorDomain = errorDomain
        self.errorCode = errorCode
        self.redirectCount = redirectCount
        self.fetchSource = fetchSource
        self.recordSequence = recordSequence
        self.startedAt = startedAt
    }
}

public struct PTStudioPayload: Codable, Sendable, Equatable {
    public var record: PTStudioCaptureSnapshot?
    public var capabilities: PTNetworkStudioCapabilities?
    public var message: String?
    public var droppedEvents: UInt64?

    public init(record: PTStudioCaptureSnapshot? = nil,
                capabilities: PTNetworkStudioCapabilities? = nil,
                message: String? = nil,
                droppedEvents: UInt64? = nil) {
        self.record = record
        self.capabilities = capabilities
        self.message = message
        self.droppedEvents = droppedEvents
    }
}

public struct PTStudioEnvelope: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = 1
    public let schemaVersion: Int
    public let sessionID: UUID
    public let deviceID: UUID
    public let eventID: UUID
    public let requestID: UUID?
    public let sequence: UInt64
    public let monotonicTime: TimeInterval
    public let wallTime: Date
    public let source: String
    public let kind: PTStudioMessageKind
    public let payload: PTStudioPayload

    public init(sessionID: UUID, deviceID: UUID, eventID: UUID = UUID(),
                requestID: UUID?, sequence: UInt64, monotonicTime: TimeInterval,
                wallTime: Date = .now, source: String,
                kind: PTStudioMessageKind, payload: PTStudioPayload = .init()) {
        self.schemaVersion = Self.currentSchemaVersion
        self.sessionID = sessionID
        self.deviceID = deviceID
        self.eventID = eventID
        self.requestID = requestID
        self.sequence = sequence
        self.monotonicTime = monotonicTime
        self.wallTime = wallTime
        self.source = source
        self.kind = kind
        self.payload = payload
    }
}

public struct PTStudioAcknowledgement: Codable, Sendable, Equatable {
    public let schemaVersion: Int
    public let sessionID: UUID
    public let acceptedSequence: UInt64

    public init(schemaVersion: Int = PTStudioEnvelope.currentSchemaVersion,
                sessionID: UUID, acceptedSequence: UInt64) {
        self.schemaVersion = schemaVersion
        self.sessionID = sessionID
        self.acceptedSequence = acceptedSequence
    }
}

public enum PTStudioBridgeError: Error, Sendable, Equatable {
    case disabledInRelease
    case alreadyRunning
    case unsupportedScheme
    case invalidCredentials
    case transportRejected
    case invalidAcknowledgement
}
