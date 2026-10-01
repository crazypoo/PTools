// English: Small typed support objects keep presentation state separate from capture state.
// Español: Los pequeños objetos tipados mantienen separado el estado de presentación del estado de captura.
// 中文：小型类型化支持对象将展示状态与抓包状态分离。

import Foundation

public struct PTNetworkTimelinePhase: Sendable, Codable, Equatable {
    public let name: String
    public let duration: Duration?
    public let relativeStart: Double?

    public init(name: String, duration: Duration?, relativeStart: Double? = nil) {
        self.name = name
        self.duration = duration
        self.relativeStart = relativeStart
    }
}

public enum PTNetworkTimelineInsight: String, Sendable, Codable {
    case slowDNS
    case slowTLS
    case slowTTFB
    case largeDownload
    case redirectHeavy
}

public struct PTNetworkTimeline: Sendable, Codable, Equatable {
    public let phases: [PTNetworkTimelinePhase]
    public let insights: [PTNetworkTimelineInsight]

    public init(metrics: PTNetworkTaskMetricsSnapshot?, responseBytes: Int64 = 0) {
        guard let metrics else {
            phases = []
            insights = responseBytes > 2 * 1024 * 1024 ? [.largeDownload] : []
            return
        }
        let values: [(String, Duration?)] = [
            ("DNS", metrics.dnsDuration),
            ("TCP", metrics.connectDuration),
            ("TLS", metrics.secureConnectionDuration),
            ("Upload", metrics.requestDuration),
            ("TTFB", metrics.ttfb),
            ("Download", metrics.responseDuration)
        ]
        phases = values.map { PTNetworkTimelinePhase(name: $0.0, duration: $0.1) }
        var result: [PTNetworkTimelineInsight] = []
        if Self.milliseconds(metrics.dnsDuration) ?? 0 > 500 { result.append(.slowDNS) }
        if Self.milliseconds(metrics.secureConnectionDuration) ?? 0 > 500 { result.append(.slowTLS) }
        if Self.milliseconds(metrics.ttfb) ?? 0 > 1000 { result.append(.slowTTFB) }
        if responseBytes > 2 * 1024 * 1024 { result.append(.largeDownload) }
        if metrics.redirectCount > 2 { result.append(.redirectHeavy) }
        insights = result
    }

    private static func milliseconds(_ duration: Duration?) -> Double? {
        guard let duration else { return nil }
        let components = duration.components
        return (Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000) * 1000
    }
}

public enum PTNetworkCaptureCapability: String, Codable, Sendable {
    case supported
    case limited
    case notSupported
}

public struct PTNetworkCaptureCapabilityEntry: Codable, Sendable, Equatable {
    public let transport: String
    public let capability: PTNetworkCaptureCapability
    public let note: String

    public init(transport: String, capability: PTNetworkCaptureCapability, note: String) {
        self.transport = transport
        self.capability = capability
        self.note = note
    }
}

@MainActor
public final class PTDebugHookRegistryStore {
    public static let shared = PTDebugHookRegistryStore()
    public struct Entry: Sendable, Equatable {
        public let owner: String
        public let kind: String
        public let activation: String
        public let ownerCount: Int
        public let installed: Bool

        public init(owner: String, kind: String, activation: String, ownerCount: Int, installed: Bool) {
            self.owner = owner
            self.kind = kind
            self.activation = activation
            self.ownerCount = ownerCount
            self.installed = installed
        }
    }

    private var owners: [String: Set<String>] = [:]
    private var kinds: [String: (kind: String, activation: String)] = [:]

    @discardableResult
    public func register(owner: String,
                         kind: String,
                         activation: String,
                         hookID: String) -> Entry {
        owners[hookID, default: []].insert(owner)
        kinds[hookID] = (kind, activation)
        return entry(for: hookID)
    }

    @discardableResult
    public func unregister(owner: String, hookID: String) -> Entry? {
        owners[hookID]?.remove(owner)
        return owners[hookID]?.isEmpty == true ? nil : entry(for: hookID)
    }

    public func entries() -> [Entry] {
        owners.keys.sorted().map(entry(for:))
    }

    private func entry(for hookID: String) -> Entry {
        let metadata = kinds[hookID] ?? ("unknown", "runtime")
        return Entry(owner: hookID,
                     kind: metadata.kind,
                     activation: metadata.activation,
                     ownerCount: owners[hookID]?.count ?? 0,
                     installed: !(owners[hookID]?.isEmpty ?? true))
    }
}

@MainActor
public final class PTNetworkDebugPresentationSession {
    public var filter = PTNetworkCaptureFilter()
    public var searchText = ""
    public var selectedID: UUID?
    public private(set) var isVisible = false

    public init() {}

    public func begin() { isVisible = true }
    public func end() { isVisible = false; selectedID = nil }
}
