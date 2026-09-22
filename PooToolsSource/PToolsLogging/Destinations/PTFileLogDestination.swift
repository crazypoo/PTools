//
//  PTFileLogDestination.swift
//  PToolsLogging
//
// English: Provides an opt-in, bounded and privacy-aware file destination for PTLogger.
// Español: Proporciona un destino de archivos opcional, acotado y respetuoso con la privacidad para PTLogger.
// 中文：为 PTLogger 提供可选启用、有界且具备隐私保护的文件日志目标。
//

import Foundation

public final class PTFileLogDestination: PTLogDestination, Sendable {
    public let identifier: String

    private let continuation: AsyncStream<PTFileLogEvent>.Continuation
    private let writer: PTLogFileWriter
    private let worker: Task<Void, Never>
    private let timer: Task<Void, Never>
    private let configuration: PTLogFileConfiguration

    // English: Resolve a displaced flush request so bounded backpressure never strands an awaiter.
    // Español: Resuelve una solicitud de flush desplazada para que la presión acotada nunca deje un awaiter bloqueado.
    // 中文：解析被有界背压淘汰的 flush 请求，避免等待方永久悬挂。
    private static func yield(_ event: PTFileLogEvent,
                              to continuation: AsyncStream<PTFileLogEvent>.Continuation) {
        switch continuation.yield(event) {
        case let .dropped(displaced):
            if case let .flush(request) = displaced {
                resolve(request)
            }
        case .terminated:
            if case let .flush(request) = event {
                resolve(request)
            }
        case .enqueued:
            break
        @unknown default:
            if case let .flush(request) = event {
                resolve(request)
            }
        }
    }

    // English: Exceptional queue states resolve only the affected waiter asynchronously.
    // Español: Los estados excepcionales de la cola resuelven solo el waiter afectado de forma asíncrona.
    // 中文：仅在队列异常状态下异步解析受影响的等待方。
    private static func resolve(_ request: PTFileFlushRequest?) {
        guard let request else { return }
        Task {
            await request.resolve()
        }
    }

    public init(identifier: String = "ptools.file",
                configuration: PTLogFileConfiguration = PTLogFileConfiguration()) {
        self.identifier = identifier
        self.configuration = configuration
        let writer = PTLogFileWriter(configuration: configuration)
        let streamPair = AsyncStream<PTFileLogEvent>.makeStream(
            of: PTFileLogEvent.self,
            bufferingPolicy: .bufferingNewest(configuration.bufferCapacity)
        )
        self.continuation = streamPair.continuation
        self.writer = writer
        self.worker = Task.detached(priority: .utility) {
            await writer.consume(streamPair.stream)
        }
        self.timer = Task.detached(priority: .utility) { [continuation = streamPair.continuation] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(configuration.flushInterval * 1_000_000_000))
                } catch {
                    return
                }
                Self.yield(.flush(nil), to: continuation)
            }
        }
    }

    deinit {
        timer.cancel()
        continuation.finish()
    }

    public func append(_ record: PTLogRecord) {
        let flushAfter = record.level >= .warning
        Self.yield(.record(record, flushAfter: flushAfter), to: continuation)
    }

    public func flush() async {
        let request = PTFileFlushRequest()
        Self.yield(.flush(request), to: continuation)
        await request.wait()
    }

    public static func logFiles(configuration: PTLogFileConfiguration = PTLogFileConfiguration()) async -> [URL] {
        let directoryURL = configuration.directoryURL
        return await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            let urls = (try? fileManager.contentsOfDirectory(at: directoryURL,
                                                             includingPropertiesForKeys: [.contentModificationDateKey],
                                                             options: [.skipsHiddenFiles])) ?? []
            return urls.filter {
                $0.lastPathComponent.hasPrefix("ptools-") && $0.pathExtension == "log"
            }.sorted { lhs, rhs in
                let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return leftDate > rightDate
            }
        }.value
    }
}
