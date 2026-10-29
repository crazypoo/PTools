import Foundation
#if SWIFT_PACKAGE
import PToolsStudioProtocolCore
import PToolsLogging
#endif

/// Privacy-scoped adapter for existing PToolsLogging and PTInstruments producers.
/// It never installs log interception or Instruments sampling automatically.
public actor PTStudioTelemetryInspector {
    private let logSource: PTMemoryLogDestination?
    private var samples: [PTStudioDiagnosticEntry] = []
    public var allowedLogCategories: Set<String>
    public var permitsMetrics = false
    public let maximumSamples: Int

    /// Pass an existing memory destination; or opt in to the installed PToolsLogging one.
    public init(logSource: PTMemoryLogDestination? = nil,
                allowedLogCategories: Set<String> = [],
                maximumSamples: Int = 500) {
        self.logSource = logSource
        self.allowedLogCategories = allowedLogCategories
        self.maximumSamples = max(1, min(5_000, maximumSamples))
    }

    /// PTInstruments can feed value samples through this adapter without importing Debug UI.
    public func recordMetric(name: String, value: Double, unit: String,
                             timestamp: Date = .now, attributes: [String: String] = [:]) {
        guard permitsMetrics, value.isFinite,
              name.count <= 96, unit.count <= 32 else { return }
        let safeAttributes = attributes.filter { key, value in
            key.count <= 48 && value.count <= 120 &&
            !["token", "secret", "password", "cookie", "authorization"].contains(key.lowercased())
        }
        samples.append(.init(id: UUID().uuidString, kind: "metric", name: name,
                             detail: unit, attributes:
                                safeAttributes.merging(["value": String(value),
                                    "timestamp": String(timestamp.timeIntervalSince1970)]) { _, new in new }))
        if samples.count > maximumSamples { samples.removeFirst(samples.count - maximumSamples) }
    }

    public func handle(_ command: PTStudioDiagnosticCommand) async -> PTStudioDiagnosticReply {
        guard command.schemaVersion == PTStudioDiagnosticCommand.schemaVersion else {
            return .init(id: command.id, sessionID: command.sessionID,
                         success: false, message: "Unknown diagnostic schema")
        }
        switch (command.domain, command.operation) {
        case (.logging, "list"):
            guard let logSource, !allowedLogCategories.isEmpty else {
                return .init(id: command.id, sessionID: command.sessionID,
                             success: false, message: "Host has not approved log categories")
            }
            let records = await logSource.snapshot()
            let entries = records.suffix(300).filter {
                allowedLogCategories.contains($0.category.rawValue)
            }.map { record in
                PTStudioDiagnosticEntry(
                    id: String(record.sequence), kind: "log",
                    name: record.category.rawValue,
                    detail: String(record.message.prefix(1024)),
                    attributes: [
                        "level": String(record.level.rawValue),
                        "timestamp": String(record.timestamp.timeIntervalSince1970),
                        "subsystem": String(record.subsystem.prefix(96))
                    ])
            }
            return .init(id: command.id, sessionID: command.sessionID, success: true, entries: entries)
        case (.performance, "list"):
            guard permitsMetrics else {
                return .init(id: command.id, sessionID: command.sessionID,
                             success: false, message: "Metrics sharing not enabled")
            }
            return .init(id: command.id, sessionID: command.sessionID,
                         success: true, entries: samples)
        default:
            return .init(id: command.id, sessionID: command.sessionID,
                         success: false, message: "Telemetry is read-only")
        }
    }
}
