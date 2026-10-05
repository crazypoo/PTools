// English: Actor-isolated observability recorder with redaction, sampling, and bounded memory.
// Español: Registrador de observabilidad aislado por actor con redacción, muestreo y memoria limitada.
// 中文：基于 actor 的可观测性记录器，支持脱敏、采样和有界内存。

import Foundation
#if SWIFT_PACKAGE
import PToolsObservabilityCore
#endif

public actor PTObservabilityRecorder {
    public let configuration: PTObservabilityConfiguration
    private var records: [PTObservabilityRecord] = []
    private var sinks: [any PTObservabilitySink] = []
    private var continuations: [UUID: AsyncStream<PTObservabilityRecord>.Continuation] = [:]

    public init(configuration: PTObservabilityConfiguration = .init()) {
        self.configuration = configuration
    }

    public func addSink(_ sink: any PTObservabilitySink) { sinks.append(sink) }

    public func record(_ record: PTObservabilityRecord) async {
        guard Double.random(in: 0...1) <= configuration.sampleRate else { return }
        let redacted = redact(record)
        records.append(redacted)
        if records.count > configuration.bufferLimit { records.removeFirst(records.count - configuration.bufferLimit) }
        continuations.values.forEach { $0.yield(redacted) }
        for sink in sinks { await sink.receive(redacted) }
    }

    public func record(event: PTObservabilityEvent) async { await record(.event(event)) }
    public func record(metric: PTObservabilityMetric) async { await record(.metric(metric)) }
    public func record(breadcrumb: PTObservabilityBreadcrumb) async { await record(.breadcrumb(breadcrumb)) }
    public func record(span: PTObservabilitySpan) async { await record(.span(span)) }

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

    private func redact(_ record: PTObservabilityRecord) -> PTObservabilityRecord {
        func redact(_ attributes: [String: String]) -> [String: String] {
            attributes.reduce(into: [String: String]()) { result, item in
                result[item.key] = configuration.redactedKeys.contains(item.key.lowercased()) ? "[REDACTED]" : item.value
            }
        }
        switch record {
        case .event(let event):
            return .event(PTObservabilityEvent(name: event.name,
                                               attributes: redact(event.attributes),
                                               context: event.context,
                                               timestamp: event.timestamp))
        case .metric, .breadcrumb:
            return record
        case .span(let span):
            return .span(PTObservabilitySpan(name: span.name,
                                             duration: span.duration,
                                             attributes: redact(span.attributes)))
        case .error(let error):
            return .error(PTObservabilityErrorSnapshot(domain: error.domain,
                                                       code: error.code,
                                                       message: error.message,
                                                       context: PTObservabilityContext(values: redact(error.context.values))))
        }
    }

    private func removeContinuation(_ id: UUID) { continuations[id] = nil }
}
