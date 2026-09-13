// English: PTInstruments provides an opt-in, app-local diagnostics timeline for the Debug product.
// Español: PTInstruments proporciona una línea de tiempo de diagnóstico local y opcional para el producto Debug.
// 中文：PTInstruments 为 Debug 产品提供可选启用的应用内诊断时间线。

import Foundation
import UIKit
import QuartzCore
import Darwin

// English: Tracks are value types so recorded data can cross actor boundaries without UIKit or Foundation mutable state.
// Español: Las pistas son tipos de valor para cruzar actores sin estado mutable de UIKit o Foundation.
// 中文：轨道使用值类型，跨 actor 时不携带 UIKit 或 Foundation 可变状态。
public enum PTInstrumentKind: String, Codable, CaseIterable, Sendable {
    case fps
    case frameTime
    case hitch
    case cpu
    case memory
    case mainThreadStall
    case network
    case lifecycle
    case logs
    case leak
    case crash
    case appLifecycle
    case sceneLifecycle
    case custom
}

public protocol PTInstrument: Sendable {
    var kind: PTInstrumentKind { get }
}

public struct PTBuiltInInstrument: PTInstrument, Codable, Sendable, Equatable {
    public let kind: PTInstrumentKind

    public init(kind: PTInstrumentKind) {
        self.kind = kind
    }
}

// English: Sampling limits are intentionally configurable and conservative to keep diagnostics from becoming the workload.
// Español: Los límites de muestreo son configurables y conservadores para que el diagnóstico no se convierta en la carga principal.
// 中文：采样限制可配置且默认保守，避免诊断工具本身成为主要负载。
public struct PTInstrumentSamplingPolicy: Codable, Sendable, Equatable {
    public var cpuMemoryInterval: TimeInterval
    public var fpsSampleInterval: TimeInterval
    public var mainThreadStallInterval: TimeInterval
    public var mainThreadStallThreshold: TimeInterval
    public var maxEventCount: Int
    public var maxSampleCount: Int
    public var maxSessionDuration: TimeInterval
    public var maxTraceSizeBytes: Int
    public var captureNetworkBodies: Bool
    public var logRetention: Int

    public init(cpuMemoryInterval: TimeInterval = 1,
                fpsSampleInterval: TimeInterval = 0.25,
                mainThreadStallInterval: TimeInterval = 0.25,
                mainThreadStallThreshold: TimeInterval = 0.1,
                maxEventCount: Int = 10_000,
                maxSampleCount: Int = 10_000,
                maxSessionDuration: TimeInterval = 300,
                maxTraceSizeBytes: Int = 10 * 1024 * 1024,
                captureNetworkBodies: Bool = false,
                logRetention: Int = 1_000) {
        self.cpuMemoryInterval = max(0.1, cpuMemoryInterval)
        self.fpsSampleInterval = max(0.05, fpsSampleInterval)
        self.mainThreadStallInterval = max(0.1, mainThreadStallInterval)
        self.mainThreadStallThreshold = max(0.01, mainThreadStallThreshold)
        self.maxEventCount = max(1, maxEventCount)
        self.maxSampleCount = max(1, maxSampleCount)
        self.maxSessionDuration = max(1, maxSessionDuration)
        self.maxTraceSizeBytes = max(1_024, maxTraceSizeBytes)
        self.captureNetworkBodies = captureNetworkBodies
        self.logRetention = max(1, logRetention)
    }
}

public struct PTInstrumentSessionMetadata: Codable, Sendable, Equatable {
    public let bundleIdentifier: String
    public let appVersion: String
    public let operatingSystem: String
    public let deviceModel: String
    public let screenRefreshRate: Double

    public init(bundleIdentifier: String,
                appVersion: String,
                operatingSystem: String,
                deviceModel: String,
                screenRefreshRate: Double) {
        self.bundleIdentifier = bundleIdentifier
        self.appVersion = appVersion
        self.operatingSystem = operatingSystem
        self.deviceModel = deviceModel
        self.screenRefreshRate = screenRefreshRate
    }

    @MainActor
    public static func current(window: UIWindow? = nil) -> PTInstrumentSessionMetadata {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let screen = window?.windowScene?.screen ?? UIScreen.main
        return PTInstrumentSessionMetadata(
            bundleIdentifier: bundle.bundleIdentifier ?? "unknown",
            appVersion: version,
            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: UIDevice.current.model,
            screenRefreshRate: Double(screen.maximumFramesPerSecond)
        )
    }
}

public struct PTInstrumentSample: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let kind: PTInstrumentKind
    public let timestamp: Date
    public let value: Double
    public let unit: String
    public let duration: TimeInterval?
    public let metadata: [String: String]

    public init(id: UUID = UUID(),
                kind: PTInstrumentKind,
                timestamp: Date = Date(),
                value: Double,
                unit: String,
                duration: TimeInterval? = nil,
                metadata: [String: String] = [:]) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
        self.value = value
        self.unit = unit
        self.duration = duration
        self.metadata = metadata
    }
}

public struct PTInstrumentEvent: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let kind: PTInstrumentKind
    public let timestamp: Date
    public let name: String
    public let duration: TimeInterval?
    public let severity: String?
    public let metadata: [String: String]
    public let parentID: UUID?

    public init(id: UUID = UUID(),
                kind: PTInstrumentKind,
                timestamp: Date = Date(),
                name: String,
                duration: TimeInterval? = nil,
                severity: String? = nil,
                metadata: [String: String] = [:],
                parentID: UUID? = nil) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
        self.name = name
        self.duration = duration
        self.severity = severity
        self.metadata = metadata
        self.parentID = parentID
    }
}

public struct PTInstrumentTrack: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let kind: PTInstrumentKind
    public var isVisible: Bool
    public var samples: [PTInstrumentSample]
    public var events: [PTInstrumentEvent]

    public init(kind: PTInstrumentKind,
                isVisible: Bool = true,
                samples: [PTInstrumentSample] = [],
                events: [PTInstrumentEvent] = []) {
        self.id = kind.rawValue
        self.kind = kind
        self.isVisible = isVisible
        self.samples = samples
        self.events = events
    }
}

public struct PTInstrumentCorrelation: Codable, Sendable, Equatable {
    public let event: PTInstrumentEvent
    public let relatedEvents: [PTInstrumentEvent]
    public let relatedSamples: [PTInstrumentSample]

    public init(event: PTInstrumentEvent,
                relatedEvents: [PTInstrumentEvent],
                relatedSamples: [PTInstrumentSample]) {
        self.event = event
        self.relatedEvents = relatedEvents
        self.relatedSamples = relatedSamples
    }
}

public struct PTInstrumentTimeline: Codable, Sendable, Equatable {
    public let startDate: Date
    public let endDate: Date
    public let tracks: [PTInstrumentTrack]

    public init(startDate: Date, endDate: Date, tracks: [PTInstrumentTrack]) {
        self.startDate = startDate
        self.endDate = max(startDate, endDate)
        self.tracks = tracks.sorted { $0.kind.rawValue < $1.kind.rawValue }
    }

    public var duration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }

    public func events(in range: DateInterval? = nil,
                      kinds: Set<PTInstrumentKind>? = nil,
                      query: String? = nil) -> [PTInstrumentEvent] {
        let normalizedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return tracks
            .filter { kinds?.contains($0.kind) ?? true }
            .flatMap(\.events)
            .filter { event in
                let matchesRange = range.map { $0.contains(event.timestamp) } ?? true
                let matchesQuery = normalizedQuery.map {
                    let query = $0
                    return event.name.lowercased().contains(query)
                        || event.metadata.values.contains { $0.lowercased().contains(query) }
                } ?? true
                return matchesRange && matchesQuery
            }
            .sorted { $0.timestamp < $1.timestamp }
    }

    public func samples(in range: DateInterval? = nil,
                       kinds: Set<PTInstrumentKind>? = nil) -> [PTInstrumentSample] {
        tracks
            .filter { kinds?.contains($0.kind) ?? true }
            .flatMap(\.samples)
            .filter { range?.contains($0.timestamp) ?? true }
            .sorted { $0.timestamp < $1.timestamp }
    }

    public func correlation(for eventID: UUID,
                            tolerance: TimeInterval = 0.25) -> PTInstrumentCorrelation? {
        guard let event = tracks.flatMap(\.events).first(where: { $0.id == eventID }) else { return nil }
        let distance = max(0, tolerance)
        let relatedEvents = tracks
            .flatMap(\.events)
            .filter { $0.id != event.id && abs($0.timestamp.timeIntervalSince(event.timestamp)) <= distance }
            .sorted { $0.timestamp < $1.timestamp }
        let relatedSamples = tracks
            .flatMap(\.samples)
            .filter { abs($0.timestamp.timeIntervalSince(event.timestamp)) <= distance }
            .sorted { $0.timestamp < $1.timestamp }
        return PTInstrumentCorrelation(event: event,
                                       relatedEvents: relatedEvents,
                                       relatedSamples: relatedSamples)
    }
}

public struct PTInstrumentSessionSnapshot: Codable, Sendable, Equatable {
    public let formatVersion: Int
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let metadata: PTInstrumentSessionMetadata
    public let selectedInstruments: [PTInstrumentKind]
    public let timeline: PTInstrumentTimeline
    public let summary: [String: Double]

    public init(formatVersion: Int = 1,
                id: UUID,
                startDate: Date,
                endDate: Date,
                metadata: PTInstrumentSessionMetadata,
                selectedInstruments: [PTInstrumentKind],
                timeline: PTInstrumentTimeline,
                summary: [String: Double]) {
        self.formatVersion = formatVersion
        self.id = id
        self.startDate = startDate
        self.endDate = max(startDate, endDate)
        self.metadata = metadata
        self.selectedInstruments = selectedInstruments
        self.timeline = timeline
        self.summary = summary
    }
}

// English: Network records are immutable summaries, so the Network module does not depend on the Debug module.
// Español: Los registros de red son resúmenes inmutables para que Network no dependa del módulo Debug.
// 中文：网络记录是不可变摘要，因此 Network 模块不需要依赖 Debug 模块。
public struct PTInstrumentNetworkRecord: Codable, Sendable, Equatable {
    public let requestID: String?
    public let method: String
    public let url: String
    public let statusCode: Int?
    public let requestBytes: Int64?
    public let responseBytes: Int64?
    public let duration: TimeInterval
    public let dnsDuration: TimeInterval?
    public let connectDuration: TimeInterval?
    public let tlsDuration: TimeInterval?
    public let timeToFirstByte: TimeInterval?
    public let retryCount: Int
    public let fromCache: Bool
    public let cancelled: Bool

    public init(requestID: String? = nil,
                method: String = "GET",
                url: String,
                statusCode: Int? = nil,
                requestBytes: Int64? = nil,
                responseBytes: Int64? = nil,
                duration: TimeInterval,
                dnsDuration: TimeInterval? = nil,
                connectDuration: TimeInterval? = nil,
                tlsDuration: TimeInterval? = nil,
                timeToFirstByte: TimeInterval? = nil,
                retryCount: Int = 0,
                fromCache: Bool = false,
                cancelled: Bool = false) {
        self.requestID = requestID
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.requestBytes = requestBytes
        self.responseBytes = responseBytes
        self.duration = max(0, duration)
        self.dnsDuration = dnsDuration
        self.connectDuration = connectDuration
        self.tlsDuration = tlsDuration
        self.timeToFirstByte = timeToFirstByte
        self.retryCount = max(0, retryCount)
        self.fromCache = fromCache
        self.cancelled = cancelled
    }
}

public enum PTInstrumentSessionError: LocalizedError, Sendable {
    case invalidDestination
    case archiveTooLarge
    case invalidArchive

    public var errorDescription: String? {
        switch self {
        case .invalidDestination:
            return "诊断归档目标路径无效"
        case .archiveTooLarge:
            return "诊断归档超过采样策略限制"
        case .invalidArchive:
            return "诊断归档格式无效"
        }
    }
}

// English: Export always redacts credentials and URL query values, even when the in-memory recording captured them.
// Español: La exportación siempre oculta credenciales y consultas URL, aunque la grabación en memoria las haya capturado.
// 中文：导出时始终脱敏凭据和 URL 查询参数，即使内存录制暂时捕获了这些内容。
public enum PTInstrumentRedactor {
    private static let sensitiveKeys = [
        "authorization", "proxy-authorization", "cookie", "set-cookie", "token",
        "access-token", "refresh-token", "password", "secret", "credential", "body"
    ]

    public static func redactURL(_ value: String) -> String {
        guard var components = URLComponents(string: value), components.host != nil else {
            return value
        }
        components.query = nil
        components.fragment = nil
        return components.string ?? "[REDACTED_URL]"
    }

    public static func redactText(_ value: String) -> String {
        var result = value
        let markers = ["Bearer ", "bearer ", "token=", "access_token=", "refresh_token=", "Authorization:"]
        for marker in markers {
            guard let range = result.range(of: marker, options: .caseInsensitive) else { continue }
            let valueStart = range.upperBound
            let end = result[valueStart...].firstIndex(where: { $0 == " " || $0 == "\n" || $0 == "&" }) ?? result.endIndex
            result.replaceSubrange(valueStart..<end, with: "[REDACTED]")
        }
        return result
    }

    public static func redactMetadata(_ metadata: [String: String]) -> [String: String] {
        metadata.reduce(into: [String: String]()) { result, pair in
            let key = pair.key
            let normalized = key.lowercased().replacingOccurrences(of: "_", with: "-")
            if sensitiveKeys.contains(where: { normalized.contains($0) }) {
                result[key] = "[REDACTED]"
            } else if normalized.contains("url") || normalized.contains("endpoint") {
                result[key] = redactURL(pair.value)
            } else {
                result[key] = redactText(pair.value)
            }
        }
    }

    public static func redact(_ snapshot: PTInstrumentSessionSnapshot) -> PTInstrumentSessionSnapshot {
        let tracks = snapshot.timeline.tracks.map { track in
            PTInstrumentTrack(
                kind: track.kind,
                isVisible: track.isVisible,
                samples: track.samples.map {
                    PTInstrumentSample(id: $0.id,
                                       kind: $0.kind,
                                       timestamp: $0.timestamp,
                                       value: $0.value,
                                       unit: $0.unit,
                                       duration: $0.duration,
                                       metadata: redactMetadata($0.metadata))
                },
                events: track.events.map {
                    PTInstrumentEvent(id: $0.id,
                                      kind: $0.kind,
                                      timestamp: $0.timestamp,
                                      name: redactText($0.name),
                                      duration: $0.duration,
                                      severity: $0.severity,
                                      metadata: redactMetadata($0.metadata),
                                      parentID: $0.parentID)
                }
            )
        }
        return PTInstrumentSessionSnapshot(
            formatVersion: snapshot.formatVersion,
            id: snapshot.id,
            startDate: snapshot.startDate,
            endDate: snapshot.endDate,
            metadata: snapshot.metadata,
            selectedInstruments: snapshot.selectedInstruments,
            timeline: PTInstrumentTimeline(startDate: snapshot.timeline.startDate,
                                           endDate: snapshot.timeline.endDate,
                                           tracks: tracks),
            summary: snapshot.summary
        )
    }
}

public struct PTInstrumentTraceDocument: Codable, Sendable, Equatable {
    public let schemaVersion: Int
    public let exportedAt: Date
    public let session: PTInstrumentSessionSnapshot

    public init(schemaVersion: Int = 1,
                exportedAt: Date = Date(),
                session: PTInstrumentSessionSnapshot) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.session = session
    }
}

public enum PTInstrumentTraceStore {
    public static func directoryURL(fileManager: FileManager = .default) -> URL? {
        guard let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        return base.appendingPathComponent("PTools/PTTraces", isDirectory: true)
    }

    public static func save(_ snapshot: PTInstrumentSessionSnapshot,
                            policy: PTInstrumentSamplingPolicy = PTInstrumentSamplingPolicy(),
                            to destination: URL? = nil) throws -> URL {
        let document = PTInstrumentTraceDocument(session: PTInstrumentRedactor.redact(snapshot))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(document)
        guard data.count <= policy.maxTraceSizeBytes else { throw PTInstrumentSessionError.archiveTooLarge }

        let fileManager = FileManager.default
        let target: URL
        if let destination {
            guard !destination.path.isEmpty else { throw PTInstrumentSessionError.invalidDestination }
            target = destination.pathExtension.isEmpty ? destination.appendingPathExtension("pttrace") : destination
        } else {
            guard let directory = directoryURL(fileManager: fileManager) else {
                throw PTInstrumentSessionError.invalidDestination
            }
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            target = directory.appendingPathComponent("\(snapshot.id.uuidString).pttrace")
        }
        try fileManager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: target, options: .atomic)
        return target
    }

    public static func load(from url: URL) throws -> PTInstrumentSessionSnapshot {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let document = try? decoder.decode(PTInstrumentTraceDocument.self, from: data),
              document.schemaVersion == 1 else {
            throw PTInstrumentSessionError.invalidArchive
        }
        return document.session
    }

    public static func history() -> [URL] {
        guard let directory = directoryURL() else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: directory,
                                                               includingPropertiesForKeys: [.contentModificationDateKey],
                                                               options: [.skipsHiddenFiles]))?
            .filter { $0.pathExtension == "pttrace" }
            .sorted { lhs, rhs in
                let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? nil
                let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? nil
                return (leftDate ?? .distantPast) > (rightDate ?? .distantPast)
            } ?? []
    }
}

// English: The session actor is the single mutable owner for samples, events, limits, and export snapshots.
// Español: El actor de sesión es el único propietario mutable de muestras, eventos, límites y snapshots exportables.
// 中文：Session actor 是采样、事件、限制和导出快照的唯一可变所有者。
public actor PTInstrumentSession {
    public enum State: String, Sendable {
        case recording
        case stopped
    }

    public let id: UUID
    public let selectedInstruments: [PTInstrumentKind]
    public let metadata: PTInstrumentSessionMetadata
    public let policy: PTInstrumentSamplingPolicy

    private let startDate: Date
    private var endDate: Date?
    private var state: State = .recording
    private var tracks: [PTInstrumentKind: PTInstrumentTrack] = [:]
    private var eventCount = 0
    private var sampleCount = 0
    private var droppedCount = 0

    public init(id: UUID = UUID(),
                selectedInstruments: [PTInstrumentKind] = PTInstrumentKind.allCases,
                metadata: PTInstrumentSessionMetadata,
                policy: PTInstrumentSamplingPolicy = PTInstrumentSamplingPolicy()) {
        self.id = id
        self.selectedInstruments = Array(Set(selectedInstruments)).sorted { $0.rawValue < $1.rawValue }
        self.metadata = metadata
        self.policy = policy
        self.startDate = Date()
    }

    public func start() {
        if state == .stopped {
            state = .recording
            endDate = nil
        }
    }

    @discardableResult
    public func stop() -> PTInstrumentSessionSnapshot {
        state = .stopped
        endDate = endDate ?? Date()
        return makeSnapshot()
    }

    public func currentState() -> State {
        state
    }

    public func recordSample(_ sample: PTInstrumentSample) {
        guard shouldRecord(kind: sample.kind) else { return }
        let track = tracks[sample.kind] ?? PTInstrumentTrack(kind: sample.kind)
        guard sampleCount < policy.maxSampleCount else {
            droppedCount += 1
            return
        }
        var updated = track
        updated.samples.append(sample)
        tracks[sample.kind] = updated
        sampleCount += 1
    }

    public func recordEvent(_ event: PTInstrumentEvent) {
        guard shouldRecord(kind: event.kind) else { return }
        let track = tracks[event.kind] ?? PTInstrumentTrack(kind: event.kind)
        let trackLimit = event.kind == .logs ? policy.logRetention : policy.maxEventCount
        guard eventCount < policy.maxEventCount else {
            droppedCount += 1
            return
        }
        var updated = track
        updated.events.append(event)
        if updated.events.count > trackLimit {
            updated.events = Array(updated.events.suffix(trackLimit))
        }
        tracks[event.kind] = updated
        eventCount += 1
    }

    public func snapshot() -> PTInstrumentSessionSnapshot {
        makeSnapshot()
    }

    public func timeline() -> PTInstrumentTimeline {
        makeSnapshot().timeline
    }

    public func export(to destination: URL? = nil) throws -> URL {
        try PTInstrumentTraceStore.save(makeSnapshot(), policy: policy, to: destination)
    }

    private func shouldRecord(kind: PTInstrumentKind) -> Bool {
        guard state == .recording, selectedInstruments.contains(kind) else { return false }
        guard Date().timeIntervalSince(startDate) <= policy.maxSessionDuration else {
            state = .stopped
            endDate = Date()
            return false
        }
        return true
    }

    private func makeSnapshot() -> PTInstrumentSessionSnapshot {
        let end = endDate ?? Date()
        let timeline = PTInstrumentTimeline(startDate: startDate, endDate: end, tracks: Array(tracks.values))
        let cpuSamples = timeline.samples(kinds: [.cpu])
        let memorySamples = timeline.samples(kinds: [.memory])
        let fpsSamples = timeline.samples(kinds: [.fps])
        let frameTimeSamples = timeline.samples(kinds: [.frameTime])
        var summary: [String: Double] = [
            "duration": timeline.duration,
            "eventCount": Double(eventCount),
            "sampleCount": Double(sampleCount),
            "droppedCount": Double(droppedCount)
        ]
        if let cpuPeak = cpuSamples.map(\.value).max() {
            summary["cpuPeakPercent"] = cpuPeak
        }
        if let memoryPeak = memorySamples.map(\.value).max() {
            summary["memoryPeakMB"] = memoryPeak
        }
        if let firstMemory = memorySamples.first?.value,
           let lastMemory = memorySamples.last?.value {
            summary["memoryGrowthMB"] = lastMemory - firstMemory
        }
        if !fpsSamples.isEmpty {
            summary["fpsAverage"] = fpsSamples.map(\.value).reduce(0, +) / Double(fpsSamples.count)
        }
        if !frameTimeSamples.isEmpty {
            summary["frameTimeAverageMs"] = frameTimeSamples.map(\.value).reduce(0, +) / Double(frameTimeSamples.count)
        }
        summary["hitchCount"] = Double(timeline.events(kinds: [.hitch]).count)
        summary["mainThreadStallCount"] = Double(timeline.events(kinds: [.mainThreadStall]).count)
        return PTInstrumentSessionSnapshot(
            id: id,
            startDate: startDate,
            endDate: end,
            metadata: metadata,
            selectedInstruments: selectedInstruments,
            timeline: timeline,
            summary: summary
        )
    }
}

// English: The active session lookup is actor-isolated so PTTrace can be called from any task safely.
// Español: La sesión activa se consulta dentro de un actor para que PTTrace pueda llamarse desde cualquier tarea con seguridad.
// 中文：活动 Session 通过 actor 隔离，PTTrace 可以从任意任务安全调用。
private actor PTTraceRuntime {
    static let shared = PTTraceRuntime()
    private var session: PTInstrumentSession?

    func set(_ session: PTInstrumentSession?) {
        self.session = session
    }

    func current() -> PTInstrumentSession? {
        session
    }
}

private actor PTTraceEndState {
    private var didEnd = false

    func markEnded() -> Bool {
        guard !didEnd else { return false }
        didEnd = true
        return true
    }
}

private enum PTTraceTaskContext {
    @TaskLocal static var parentID: UUID?
}

public struct PTTraceToken: Sendable {
    public let id: UUID
    public let name: String

    private let startedAt: UInt64
    private let startedDate: Date
    private let initialMetadata: [String: String]
    private let parentID: UUID?
    private let explicitSession: PTInstrumentSession?
    private let lookupTask: Task<PTInstrumentSession?, Never>?
    private let endState: PTTraceEndState

    fileprivate init(name: String,
                     session: PTInstrumentSession?,
                     metadata: [String: String]) {
        self.id = UUID()
        self.name = name
        self.startedAt = DispatchTime.now().uptimeNanoseconds
        self.startedDate = Date()
        self.initialMetadata = metadata
        self.parentID = PTTraceTaskContext.parentID
        self.explicitSession = session
        self.lookupTask = session == nil ? Task { await PTTraceRuntime.shared.current() } : nil
        self.endState = PTTraceEndState()
    }

    public func end(metadata: [String: String] = [:]) {
        let endDate = Date()
        let endNanos = DispatchTime.now().uptimeNanoseconds
        let elapsed = Double(endNanos >= startedAt ? endNanos - startedAt : 0) / 1_000_000_000
        let mergedMetadata = initialMetadata.merging(metadata) { _, new in new }
        let state = endState
        let explicitSession = explicitSession
        let lookupTask = lookupTask
        let event = PTInstrumentEvent(id: id,
                                      kind: .custom,
                                      timestamp: endDate,
                                      name: name,
                                      duration: elapsed,
                                      metadata: PTInstrumentRedactor.redactMetadata(mergedMetadata),
                                      parentID: parentID)
        Task {
            guard await state.markEnded() else { return }
            let session: PTInstrumentSession?
            if let explicitSession {
                session = explicitSession
            } else if let lookupTask {
                session = await lookupTask.value
            } else {
                session = await PTTraceRuntime.shared.current()
            }
            await session?.recordEvent(event)
        }
    }
}

public enum PTTrace {
    public static func begin(_ name: String,
                             session: PTInstrumentSession? = nil,
                             metadata: [String: String] = [:]) -> PTTraceToken {
        PTTraceToken(name: name, session: session, metadata: metadata)
    }

    @discardableResult
    public static func measure<T>(_ name: String,
                                 session: PTInstrumentSession? = nil,
                                 metadata: [String: String] = [:],
                                 _ operation: () throws -> T) rethrows -> T {
        let token = begin(name, session: session, metadata: metadata)
        defer { token.end() }
        return try operation()
    }

    @discardableResult
    public static func measure<T>(_ name: String,
                                 session: PTInstrumentSession? = nil,
                                 metadata: [String: String] = [:],
                                 _ operation: () async throws -> T) async rethrows -> T {
        let token = begin(name, session: session, metadata: metadata)
        defer { token.end() }
        return try await PTTraceTaskContext.$parentID.withValue(token.id) {
            try await operation()
        }
    }
}

// English: The display link uses the active screen refresh rate and never assumes a 60 Hz frame budget.
// Español: El display link usa la frecuencia real de la pantalla activa y nunca supone un presupuesto de 60 Hz.
// 中文：DisplayLink 使用当前屏幕真实刷新率，不假定 60 Hz 的帧预算。
@MainActor
private final class PTInstrumentDisplayLinkSampler: NSObject {
    private let session: PTInstrumentSession
    private let policy: PTInstrumentSamplingPolicy
    private let refreshRate: Double
    private var displayLink: CADisplayLink?
    private var windowStart: CFTimeInterval?
    private var frameCount = 0

    init(session: PTInstrumentSession, policy: PTInstrumentSamplingPolicy, window: UIWindow?) {
        self.session = session
        self.policy = policy
        let screen = window?.windowScene?.screen ?? UIScreen.main
        self.refreshRate = Double(screen.maximumFramesPerSecond)
        super.init()
    }

    func start() {
        guard displayLink == nil, refreshRate > 0 else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.preferredFramesPerSecond = Int(refreshRate)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        windowStart = nil
        frameCount = 0
    }

    @objc private func tick(_ link: CADisplayLink) {
        guard let start = windowStart else {
            windowStart = link.timestamp
            return
        }
        frameCount += 1
        let elapsed = link.timestamp - start
        guard elapsed >= policy.fpsSampleInterval else { return }
        let fps = Double(frameCount) / elapsed
        let frameTime = elapsed / Double(max(1, frameCount))
        let frameBudget = 1 / refreshRate
        let date = Date()
        let session = session
        Task {
            await session.recordSample(PTInstrumentSample(kind: .fps,
                                                          timestamp: date,
                                                          value: fps,
                                                          unit: "frames/s",
                                                          metadata: ["refreshRate": String(refreshRate)]))
            await session.recordSample(PTInstrumentSample(kind: .frameTime,
                                                          timestamp: date,
                                                          value: frameTime * 1_000,
                                                          unit: "ms",
                                                          metadata: ["refreshRate": String(refreshRate)]))
            if frameTime > frameBudget * 2 {
                let severity = frameTime > frameBudget * 4 ? "severe" : "hitch"
                await session.recordEvent(PTInstrumentEvent(kind: .hitch,
                                                            timestamp: date,
                                                            name: severity,
                                                            duration: frameTime,
                                                            metadata: ["refreshRate": String(refreshRate)]))
            }
        }
        windowStart = link.timestamp
        frameCount = 0
    }
}

// English: Resource sampling runs off the main actor and records only cheap process snapshots.
// Español: El muestreo de recursos se ejecuta fuera de MainActor y solo registra snapshots baratos del proceso.
// 中文：资源采样在 MainActor 之外执行，只记录低成本的进程快照。
private enum PTInstrumentResourceReader {
    static func memoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1_048_576 : 0
    }

    static func cpuPercent() -> Double {
        var threads: thread_act_array_t?
        var threadCount = mach_msg_type_number_t(0)
        guard task_threads(mach_task_self_, &threads, &threadCount) == KERN_SUCCESS,
              let threads else { return 0 }
        defer {
            vm_deallocate(mach_task_self_,
                          vm_address_t(UInt(bitPattern: threads)),
                          vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride))
        }
        var total = 0.0
        for index in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threads[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            guard result == KERN_SUCCESS, info.flags & TH_FLAGS_IDLE == 0 else { continue }
            total += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
        }
        return total / Double(max(1, ProcessInfo.processInfo.activeProcessorCount))
    }
}

private actor PTInstrumentResourceSampler {
    private var task: Task<Void, Never>?

    func start(session: PTInstrumentSession,
               policy: PTInstrumentSamplingPolicy,
               instruments: Set<PTInstrumentKind>) {
        guard task == nil else { return }
        task = Task {
            while !Task.isCancelled {
                let timestamp = Date()
                if instruments.contains(.cpu) {
                    await session.recordSample(PTInstrumentSample(kind: .cpu,
                                                                   timestamp: timestamp,
                                                                   value: PTInstrumentResourceReader.cpuPercent(),
                                                                   unit: "%"))
                }
                if instruments.contains(.memory) {
                    await session.recordSample(PTInstrumentSample(kind: .memory,
                                                                   timestamp: timestamp,
                                                                   value: PTInstrumentResourceReader.memoryMB(),
                                                                   unit: "MB"))
                }
                do {
                    try await Task.sleep(nanoseconds: Self.nanoseconds(policy.cpuMemoryInterval))
                } catch {
                    break
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private static func nanoseconds(_ interval: TimeInterval) -> UInt64 {
        UInt64(max(1, min(interval, 86_400)) * 1_000_000_000)
    }
}

// English: The stall sampler measures the time required to execute a no-op on MainActor and is fully cancellable.
// Español: El muestreador de bloqueos mide el tiempo de ejecutar una operación vacía en MainActor y se puede cancelar por completo.
// 中文：卡顿采样器测量 MainActor 执行空操作所需的时间，并支持完整取消。
private actor PTMainThreadStallSampler {
    private var task: Task<Void, Never>?

    func start(session: PTInstrumentSession, policy: PTInstrumentSamplingPolicy) {
        guard task == nil else { return }
        task = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: Self.nanoseconds(policy.mainThreadStallInterval))
                } catch {
                    break
                }
                let begin = DispatchTime.now().uptimeNanoseconds
                await MainActor.run { () }
                let end = DispatchTime.now().uptimeNanoseconds
                let duration = Double(end >= begin ? end - begin : 0) / 1_000_000_000
                guard duration >= policy.mainThreadStallThreshold else { continue }
                let date = Date()
                await session.recordSample(PTInstrumentSample(kind: .mainThreadStall,
                                                              timestamp: date,
                                                              value: duration * 1_000,
                                                              unit: "ms",
                                                              duration: duration))
                await session.recordEvent(PTInstrumentEvent(kind: .mainThreadStall,
                                                            timestamp: date,
                                                            name: "main-thread-stall",
                                                            duration: duration))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private static func nanoseconds(_ interval: TimeInterval) -> UInt64 {
        UInt64(max(1, min(interval, 86_400)) * 1_000_000_000)
    }
}

// English: Recorder consumes existing Debug events and log sinks; it never installs another swizzle or collector.
// Español: Recorder consume eventos y sumideros de logs existentes; nunca instala otro swizzle ni collector.
// 中文：Recorder 消费现有 Debug 事件和日志 sink，不重复安装 swizzle 或 Collector。
@MainActor
public final class PTInstrumentRecorder: NSObject {
    public static let shared = PTInstrumentRecorder()

    public private(set) var session: PTInstrumentSession?
    public private(set) var isRecording = false

    private var selectedInstruments: Set<PTInstrumentKind> = []
    private var policy = PTInstrumentSamplingPolicy()
    private var displayLinkSampler: PTInstrumentDisplayLinkSampler?
    private let resourceSampler = PTInstrumentResourceSampler()
    private let stallSampler = PTMainThreadStallSampler()
    private var eventObserverToken: UUID?
    private var logSinkIdentifier: String?
    private var durationTask: Task<Void, Never>?

    public override init() {
        super.init()
    }

    @discardableResult
    public func start(instruments: [PTInstrumentKind] = PTInstrumentKind.allCases,
                     policy: PTInstrumentSamplingPolicy = PTInstrumentSamplingPolicy(),
                     window: UIWindow? = nil) -> PTInstrumentSession {
        if isRecording, let session {
            return session
        }
        let instrumentSet = Set(instruments)
        let metadata = PTInstrumentSessionMetadata.current(window: window)
        let session = PTInstrumentSession(selectedInstruments: instruments,
                                          metadata: metadata,
                                          policy: policy)
        self.session = session
        self.selectedInstruments = instrumentSet
        self.policy = policy
        self.isRecording = true

        Task { await PTTraceRuntime.shared.set(session) }
        installEventBridgeIfNeeded()
        installLogBridgeIfNeeded()

        if instrumentSet.contains(.fps) || instrumentSet.contains(.frameTime) || instrumentSet.contains(.hitch) {
            let sampler = PTInstrumentDisplayLinkSampler(session: session, policy: policy, window: window)
            sampler.start()
            displayLinkSampler = sampler
        }
        if instrumentSet.contains(.cpu) || instrumentSet.contains(.memory) {
            Task { await resourceSampler.start(session: session, policy: policy, instruments: instrumentSet) }
        }
        if instrumentSet.contains(.mainThreadStall) {
            Task { await stallSampler.start(session: session, policy: policy) }
        }
        installLifecycleBridgeIfNeeded()
        durationTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: Self.nanoseconds(policy.maxSessionDuration))
            } catch {
                return
            }
            guard let self, self.isRecording else { return }
            _ = await self.stop()
        }
        return session
    }

    public func stop() async -> PTInstrumentSessionSnapshot? {
        guard let session else { return nil }
        durationTask?.cancel()
        durationTask = nil
        displayLinkSampler?.stop()
        displayLinkSampler = nil
        await resourceSampler.stop()
        await stallSampler.stop()
        removeBridges()
        await PTTraceRuntime.shared.set(nil)
        isRecording = false
        self.session = nil
        return await session.stop()
    }

    private func installEventBridgeIfNeeded() {
        guard eventObserverToken == nil,
              selectedInstruments.contains(where: { [.network, .lifecycle, .leak, .crash, .appLifecycle, .sceneLifecycle].contains($0) }) else { return }
        eventObserverToken = PTDebugEventCenter.shared.addObserver { [weak self] event in
            self?.record(event: event)
        }
    }

    private func installLogBridgeIfNeeded() {
        guard logSinkIdentifier == nil, selectedInstruments.contains(.logs) else { return }
        let identifier = "ptools.instruments.logs.\(UUID().uuidString)"
        logSinkIdentifier = identifier
        PTLogSinkCenter.shared.install(PTLogSink(identifier: identifier) { [weak self] event in
            self?.record(log: event)
        })
    }

    private func installLifecycleBridgeIfNeeded() {
        guard selectedInstruments.contains(.appLifecycle) || selectedInstruments.contains(.sceneLifecycle) else { return }
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(sceneDidActivate(_:)), name: UIScene.didActivateNotification, object: nil)
        center.addObserver(self, selector: #selector(sceneWillDeactivate(_:)), name: UIScene.willDeactivateNotification, object: nil)
        center.addObserver(self, selector: #selector(sceneDidDisconnect(_:)), name: UIScene.didDisconnectNotification, object: nil)
    }

    private func removeBridges() {
        if let eventObserverToken {
            PTDebugEventCenter.shared.removeObserver(eventObserverToken)
            self.eventObserverToken = nil
        }
        if let logSinkIdentifier {
            PTLogSinkCenter.shared.remove(identifier: logSinkIdentifier)
            self.logSinkIdentifier = nil
        }
        NotificationCenter.default.removeObserver(self)
    }

    private func record(event: PTDebugEvent) {
        guard let session else { return }
        let kind = Self.instrumentKind(for: event.name)
        guard selectedInstruments.contains(kind) else { return }
        Task {
            await session.recordEvent(PTInstrumentEvent(id: event.id,
                                                        kind: kind,
                                                        timestamp: event.date,
                                                        name: event.name,
                                                        metadata: PTInstrumentRedactor.redactMetadata(event.payload)))
        }
    }

    private func record(log: PTLogEvent) {
        guard let session, selectedInstruments.contains(.logs) else { return }
        let message = PTInstrumentRedactor.redactText(log.message)
        Task {
            await session.recordEvent(PTInstrumentEvent(kind: .logs,
                                                        timestamp: Date(),
                                                        name: message,
                                                        severity: log.severity.rawValue,
                                                        metadata: ["category": log.category]))
        }
    }

    public func record(network: PTInstrumentNetworkRecord) {
        guard let session, selectedInstruments.contains(.network) else { return }
        var metadata: [String: String] = [
            "method": network.method,
            "url": network.url,
            "fromCache": String(network.fromCache),
            "cancelled": String(network.cancelled),
            "retryCount": String(network.retryCount)
        ]
        if let requestID = network.requestID { metadata["requestID"] = requestID }
        if let statusCode = network.statusCode { metadata["statusCode"] = String(statusCode) }
        if let requestBytes = network.requestBytes { metadata["requestBytes"] = String(requestBytes) }
        if let responseBytes = network.responseBytes { metadata["responseBytes"] = String(responseBytes) }
        if let dnsDuration = network.dnsDuration { metadata["dnsDuration"] = String(dnsDuration) }
        if let connectDuration = network.connectDuration { metadata["connectDuration"] = String(connectDuration) }
        if let tlsDuration = network.tlsDuration { metadata["tlsDuration"] = String(tlsDuration) }
        if let timeToFirstByte = network.timeToFirstByte { metadata["timeToFirstByte"] = String(timeToFirstByte) }
        Task {
            await session.recordEvent(PTInstrumentEvent(kind: .network,
                                                        timestamp: Date(),
                                                        name: "network.request",
                                                        duration: network.duration,
                                                        metadata: PTInstrumentRedactor.redactMetadata(metadata)))
        }
    }

    // English: Crash markers are explicit, safe snapshots; signal handlers never call the recorder.
    // Español: Los marcadores de crash son snapshots explícitos y seguros; los handlers de señales nunca llaman al recorder.
    // 中文：崩溃标记是显式且安全的快照；信号处理器不会调用 Recorder。
    public func recordCrashMarker(_ name: String = "crash-marker",
                                  metadata: [String: String] = [:]) {
        guard let session, selectedInstruments.contains(.crash) else { return }
        let safeName = PTInstrumentRedactor.redactText(name)
        let safeMetadata = PTInstrumentRedactor.redactMetadata(metadata)
        Task {
            await session.recordEvent(PTInstrumentEvent(kind: .crash,
                                                        timestamp: Date(),
                                                        name: safeName,
                                                        metadata: safeMetadata))
        }
    }

    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        recordLifecycle(name: "application-did-become-active", kind: .appLifecycle, notification: notification)
    }

    @objc private func applicationWillResignActive(_ notification: Notification) {
        recordLifecycle(name: "application-will-resign-active", kind: .appLifecycle, notification: notification)
    }

    @objc private func sceneDidActivate(_ notification: Notification) {
        recordLifecycle(name: "scene-did-activate", kind: .sceneLifecycle, notification: notification)
    }

    @objc private func sceneWillDeactivate(_ notification: Notification) {
        recordLifecycle(name: "scene-will-deactivate", kind: .sceneLifecycle, notification: notification)
    }

    @objc private func sceneDidDisconnect(_ notification: Notification) {
        recordLifecycle(name: "scene-did-disconnect", kind: .sceneLifecycle, notification: notification)
    }

    private func recordLifecycle(name: String, kind: PTInstrumentKind, notification: Notification) {
        guard let session, selectedInstruments.contains(kind) else { return }
        var metadata: [String: String] = [:]
        if let scene = notification.object as? UIScene {
            metadata["sceneID"] = scene.session.persistentIdentifier
            metadata["sceneActivationState"] = String(scene.activationState.rawValue)
        }
        Task {
            await session.recordEvent(PTInstrumentEvent(kind: kind,
                                                        timestamp: Date(),
                                                        name: name,
                                                        metadata: metadata))
        }
    }

    private static func instrumentKind(for eventName: String) -> PTInstrumentKind {
        let name = eventName.lowercased()
        if name.hasPrefix("network") { return .network }
        if name.hasPrefix("lifecycle") || name.contains("viewdid") { return .lifecycle }
        if name.hasPrefix("leak") { return .leak }
        if name.hasPrefix("crash") { return .crash }
        return .custom
    }

    private static func nanoseconds(_ interval: TimeInterval) -> UInt64 {
        UInt64(max(1, min(interval, 86_400)) * 1_000_000_000)
    }
}
