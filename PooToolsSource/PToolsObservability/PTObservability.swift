// English: Actor-isolated observability recorder with redaction, sampling, and bounded memory.
// Español: Registrador de observabilidad aislado por actor con redacción, muestreo y memoria limitada.
// 中文：基于 actor 的可观测性记录器，支持脱敏、采样和有界内存。

import Foundation
#if canImport(OSLog)
import OSLog
#endif
#if SWIFT_PACKAGE
import PToolsObservabilityCore
#if canImport(PToolsLogging)
import PToolsLogging
#endif
#endif

public actor PTObservabilityRecorder {
    public let configuration: PTObservabilityConfiguration
    private let persistentBuffer: PTPersistentObservabilityBuffer?
    private var records: [PTObservabilityRecord] = []
    private var sinks: [any PTObservabilitySink] = []
    private var continuations: [UUID: AsyncStream<PTObservabilityRecord>.Continuation] = [:]
    private var sampleCounter: UInt64 = 0

    public init(configuration: PTObservabilityConfiguration = .init(),
                persistentBuffer: PTPersistentObservabilityBuffer? = nil) {
        self.configuration = configuration
        self.persistentBuffer = persistentBuffer
    }

    public func addSink(_ sink: any PTObservabilitySink) { sinks.append(sink) }

    public func record(_ record: PTObservabilityRecord) async {
        guard shouldSample(record) else { return }
        let redacted = redact(record)
        if let encoded = try? JSONEncoder().encode(redacted),
           encoded.count > configuration.maximumPayloadBytes {
            return
        }
        records.append(redacted)
        if records.count > configuration.bufferLimit { records.removeFirst(records.count - configuration.bufferLimit) }
        continuations.values.forEach { $0.yield(redacted) }
        if sinks.isEmpty {
            await persistentBuffer?.append(redacted)
        } else {
            for sink in sinks { await sink.receive(redacted) }
        }
    }

    public func record(event: PTObservabilityEvent) async { await record(.event(event)) }
    public func record(metric: PTObservabilityMetric) async { await record(.metric(metric)) }
    public func record(breadcrumb: PTObservabilityBreadcrumb) async { await record(.breadcrumb(breadcrumb)) }
    public func record(span: PTObservabilitySpan) async { await record(.span(span)) }

    public func beginSpan(name: String,
                          parent: PTSpanContext? = nil) -> PTSpanContext {
        PTSpanContext(traceID: parent?.traceID ?? .init(),
                      spanID: .init(),
                      parentSpanID: parent?.spanID)
    }

    public func endSpan(name: String,
                        context: PTSpanContext,
                        startedAt: Date,
                        attributes: [String: String] = [:],
                        endedAt: Date = .now) async {
        let duration = max(0, endedAt.timeIntervalSince(startedAt))
        await record(span: PTObservabilitySpan(name: name,
                                               duration: duration,
                                               attributes: attributes,
                                               context: context))
    }

    public func record(error: Error,
                       context: PTObservabilityContext = .init()) async {
        let nsError = error as NSError
        await record(.error(PTObservabilityErrorSnapshot(domain: nsError.domain,
                                                          code: nsError.code,
                                                          message: nsError.localizedDescription,
                                                          context: context)))
    }

    public func snapshot() -> [PTObservabilityRecord] { records }

    public func stream() -> AsyncStream<PTObservabilityRecord> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    public func flushPersistentBuffer() async -> Int {
        guard let persistentBuffer else { return 0 }
        return await persistentBuffer.flush(to: sinks)
    }

    // English: Return an actor-backed span handle so duration and end state cannot be forgotten by callers.
    // Español: Devuelve un handle de span aislado por actor para no olvidar duración ni cierre.
    // 中文：返回 actor 隔离的 Span Handle，避免调用方遗漏时长和结束状态。
    public func startSpan(name: String, parent: PTSpanContext? = nil) -> PTSpanHandle {
        PTSpanHandle(name: name, parent: parent, recorder: self)
    }

    private func shouldSample(_ record: PTObservabilityRecord) -> Bool {
        let rate = configuration.samplingPolicy.rate(for: record.kind,
                                                     fallback: configuration.sampleRate)
        guard rate > 0 else { return false }
        guard rate < 1 else { return true }
        if configuration.samplingPolicy.deterministic {
            sampleCounter &+= 1
            let bucket = Double(sampleCounter % 10_000) / 10_000
            return bucket < rate
        }
        return Double.random(in: 0...1) < rate
    }

    private func redact(_ record: PTObservabilityRecord) -> PTObservabilityRecord {
        func redact(_ attributes: [String: String]) -> [String: String] {
            attributes.reduce(into: [String: String]()) { result, item in
                let key = item.key.lowercased()
                result[item.key] = configuration.redactedKeys.contains(key) ? "[REDACTED]" : item.value
            }
        }
        switch record {
        case .event(let event):
            return .event(PTObservabilityEvent(name: event.name,
                                               attributes: redact(event.attributes),
                                               context: event.context,
                                               spanContext: event.spanContext,
                                               timestamp: event.timestamp))
        case .metric:
            return record
        case .breadcrumb(let breadcrumb):
            return .breadcrumb(PTObservabilityBreadcrumb(message: redactText(breadcrumb.message),
                                                         category: breadcrumb.category))
        case .span(let span):
            return .span(PTObservabilitySpan(name: span.name,
                                             duration: span.duration,
                                             attributes: redact(span.attributes),
                                             context: span.context))
        case .error(let error):
            return .error(PTObservabilityErrorSnapshot(domain: error.domain,
                                                       code: error.code,
                                                       message: redactText(error.message),
                                                       context: PTObservabilityContext(values: redact(error.context.values))))
        }
    }

    private func redactText(_ value: String) -> String {
        var result = value
        for key in configuration.redactedKeys {
            let pattern = "(?i)(\(NSRegularExpression.escapedPattern(for: key))\\s*[=:]\\s*)[^&\\s,;]+"
            if let expression = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(result.startIndex..<result.endIndex, in: result)
                result = expression.stringByReplacingMatches(in: result,
                                                              options: [],
                                                              range: range,
                                                              withTemplate: "$1[REDACTED]")
            }
        }
        return result
    }

    private func removeContinuation(_ id: UUID) { continuations[id] = nil }
}

public actor PTPersistentObservabilityBuffer {
    public let fileURL: URL
    public let maximumBytes: Int
    public let maximumRecords: Int
    public let maximumAge: Duration?

    public init(fileURL: URL,
                maximumBytes: Int = 2 * 1024 * 1024,
                maximumRecords: Int = 1_000,
                maximumAge: Duration? = .seconds(7 * 24 * 60 * 60)) {
        self.fileURL = fileURL
        self.maximumBytes = max(1, maximumBytes)
        self.maximumRecords = max(1, maximumRecords)
        self.maximumAge = maximumAge
    }

    public func append(_ record: PTObservabilityRecord) {
        guard let encoded = try? JSONEncoder().encode(record) else { return }
        var lines = readLines()
        lines.append(encoded)
        writeLines(Array(lines.suffix(maximumRecords)))
    }

    public func pending() -> [PTObservabilityRecord] {
        let cutoff = maximumAge.map { Date.now.addingTimeInterval(-Self.seconds($0)) }
        return readLines().compactMap { line in
            guard let record = try? JSONDecoder().decode(PTObservabilityRecord.self, from: line) else { return nil }
            guard let cutoff else { return record }
            return Self.date(of: record) >= cutoff ? record : nil
        }
    }

    public func removeAll() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    public func flush(to sinks: [any PTObservabilitySink]) async -> Int {
        let records = pending()
        guard !records.isEmpty, !sinks.isEmpty else { return 0 }
        for record in records {
            for sink in sinks { await sink.receive(record) }
        }
        removeAll()
        return records.count
    }

    private func readLines() -> [Data] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return data.split(separator: 0x0A, omittingEmptySubsequences: true).map(Data.init)
    }

    private func writeLines(_ lines: [Data]) {
        var output = Data()
        for line in lines {
            output.append(line)
            output.append(0x0A)
        }
        if output.count > maximumBytes { output = output.suffix(maximumBytes) }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true)
            try output.write(to: fileURL, options: [.atomic])
        } catch {
            return
        }
    }

    private static func date(of record: PTObservabilityRecord) -> Date {
        switch record {
        case .event(let value): return value.timestamp
        case .breadcrumb: return .now
        case .metric, .span, .error: return .now
        }
    }

    private static func seconds(_ duration: Duration) -> TimeInterval {
        TimeInterval(duration.components.seconds)
            + TimeInterval(duration.components.attoseconds) / 1_000_000_000_000_000_000
    }
}

public actor PTSpanHandle {
    private let name: String
    private let context: PTSpanContext
    private let startedAt: Date
    private let recorder: PTObservabilityRecorder
    private var attributes: [String: String] = [:]
    private var ended = false

    public init(name: String,
                parent: PTSpanContext? = nil,
                startedAt: Date = .now,
                recorder: PTObservabilityRecorder) {
        self.name = name
        self.context = PTSpanContext(traceID: parent?.traceID ?? .init(),
                                     spanID: .init(),
                                     parentSpanID: parent?.spanID)
        self.startedAt = startedAt
        self.recorder = recorder
    }

    public func addEvent(_ name: String, attributes: [String: String] = [:]) async {
        guard !ended else { return }
        await recorder.record(event: PTObservabilityEvent(name: name,
                                                          attributes: attributes,
                                                          spanContext: context))
    }

    public func setAttribute(_ value: String, for key: String) {
        guard !ended else { return }
        attributes[key] = value
    }

    public func end(at date: Date = .now) async {
        guard !ended else { return }
        ended = true
        await recorder.endSpan(name: name,
                               context: context,
                               startedAt: startedAt,
                               attributes: attributes,
                               endedAt: date)
    }
}

// English: Forward typed observability records to the existing PTools logging pipeline.
// Español: Reenvía registros tipados de observabilidad al pipeline de logging existente de PTools.
// 中文：将类型化可观测性记录转发到现有 PTools 日志管线。
public struct PTLoggingObservabilitySink: PTObservabilitySink {
    public let identifier: String
    public init(identifier: String = "ptools.observability.logging") {
        self.identifier = identifier
    }

    public func receive(_ record: PTObservabilityRecord) async {
        PTLogger.log(String(describing: record), level: .info, category: .general)
    }
}

#if canImport(OSLog)
// English: Use Apple's native Logger without recreating a second logging configuration.
// Español: Usa el Logger nativo de Apple sin recrear una segunda configuración de logging.
// 中文：使用 Apple 原生 Logger，不重复创建第二套日志配置。
public struct PTOSLogObservabilitySink: PTObservabilitySink {
    public let identifier: String
    private let logger: Logger

    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "PooTools",
                category: String = "Observability",
                identifier: String = "ptools.observability.oslog") {
        self.identifier = identifier
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func receive(_ record: PTObservabilityRecord) async {
        logger.info("\(String(describing: record), privacy: .public)")
    }
}
#endif

// English: Bounded JSON-lines persistence keeps observability useful after a relaunch without unbounded disk growth.
// Español: La persistencia JSONL acotada conserva la observabilidad tras un relanzamiento sin crecimiento ilimitado del disco.
// 中文：有界 JSON Lines 持久化让重启后仍可查看观测记录，同时避免磁盘无限增长。
public actor PTFileObservabilitySink: PTObservabilitySink {
    public let identifier: String
    private let fileURL: URL
    private let maximumBytes: Int

    public init(fileURL: URL,
                maximumBytes: Int = 2 * 1024 * 1024,
                identifier: String = "ptools.observability.file") {
        self.fileURL = fileURL
        self.maximumBytes = max(1, maximumBytes)
        self.identifier = identifier
    }

    public func receive(_ record: PTObservabilityRecord) async {
        guard let data = try? JSONEncoder().encode(record) else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true)
            var existing = (try? Data(contentsOf: fileURL)) ?? Data()
            existing.append(data)
            existing.append(0x0A)
            if existing.count > maximumBytes {
                existing = existing.suffix(maximumBytes)
            }
            try existing.write(to: fileURL, options: [.atomic])
        } catch {
            return
        }
    }
}

// English: Sends redacted observability batches through URLSession and never blocks the recorder actor.
// Español: Envía lotes de observabilidad redactados mediante URLSession sin bloquear el actor registrador.
// 中文：通过 URLSession 发送已脱敏的观测批次，不阻塞 recorder actor。
public struct PTHTTPObservabilitySink: PTObservabilitySink {
    public let identifier: String
    public let endpoint: URL
    public let session: URLSession

    public init(endpoint: URL,
                session: URLSession = .shared,
                identifier: String = "ptools.observability.http") {
        self.endpoint = endpoint
        self.session = session
        self.identifier = identifier
    }

    public func receive(_ record: PTObservabilityRecord) async {
        guard let body = try? JSONEncoder().encode(record) else { return }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try? await session.data(for: request)
    }
}
