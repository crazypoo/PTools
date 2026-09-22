//
//  PTLogFileWriter.swift
//  PToolsLogging
//
// English: Serializes buffered file output, rotation and retention on one actor.
// Español: Serializa la salida en búfer, la rotación y la retención en un solo actor.
// 中文：在单个 actor 中串行处理缓冲写入、文件轮转和保留清理。
//

import Foundation

// English: Isolate one flush waiter so bounded backpressure can resolve it safely.
// Español: Aísla un único waiter de flush para resolverlo con seguridad ante presión acotada.
// 中文：用 actor 隔离单个 flush 等待方，安全处理有界背压下的完成通知。
actor PTFileFlushRequest {
    private var continuation: CheckedContinuation<Void, Never>?
    private var resolved = false

    func wait() async {
        await withCheckedContinuation { continuation in
            if resolved {
                continuation.resume()
            } else {
                self.continuation = continuation
            }
        }
    }

    func resolve() {
        let continuation = self.continuation
        self.continuation = nil
        resolved = true
        continuation?.resume()
    }
}

enum PTFileLogEvent: Sendable {
    case record(PTLogRecord, flushAfter: Bool)
    case flush(PTFileFlushRequest?)
}

actor PTLogFileWriter {
    private let configuration: PTLogFileConfiguration
    private let fileManager = FileManager.default
    private let dateFormatter: ISO8601DateFormatter

    private var fileHandle: FileHandle?
    private var currentFileURL: URL?
    private var currentFileSize: UInt64 = 0
    private var fileOpenedAt: Date?
    private var nextFileNumber: UInt64 = 0
    private var buffer = Data()
    private var disabled = false

    init(configuration: PTLogFileConfiguration) {
        self.configuration = configuration
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.dateFormatter = formatter
    }

    // English: Consume one bounded stream so append never creates a task per record.
    // Español: Consume un único flujo acotado para que append no cree una tarea por registro.
    // 中文：由单个有界流消费者处理事件，避免每条日志创建一个 Task。
    func consume(_ stream: AsyncStream<PTFileLogEvent>) async {
        for await event in stream {
            switch event {
            case let .record(record, flushAfter):
                append(record)
                if flushAfter {
                    flush()
                }
            case let .flush(request):
                flush()
                if let request {
                    await request.resolve()
                }
            }
        }
        flush()
        closeCurrentFile()
    }

    func flush() {
        guard !disabled else { return }
        do {
            try flushBuffer()
        } catch {
            disable(error: error, operation: "flush")
        }
    }

    private func append(_ record: PTLogRecord) {
        guard !disabled else { return }

        let line = formattedLine(for: record)
        guard let data = line.data(using: .utf8) else {
            PTLoggerInternalDiagnostics.report("Unable to encode a log record as UTF-8")
            return
        }

        do {
            try prepareFile(for: data.count)
            buffer.append(data)
            if buffer.count >= configuration.bufferSize {
                try flushBuffer()
            }
        } catch {
            disable(error: error, operation: "append")
        }
    }

    private func prepareFile(for incomingByteCount: Int) throws {
        let now = Date()
        if fileHandle == nil {
            try openNewFile(at: now)
        } else if let fileOpenedAt,
                  now.timeIntervalSince(fileOpenedAt) >= configuration.maximumFileAge {
            try rollover(at: now)
        } else if currentFileSize + UInt64(buffer.count) + UInt64(incomingByteCount) > configuration.maximumFileSize {
            try rollover(at: now)
        }
    }

    private func openNewFile(at date: Date) throws {
        try fileManager.createDirectory(at: configuration.directoryURL,
                                        withIntermediateDirectories: true,
                                        attributes: nil)

        let fileURL = nextFileURL(for: date)
        guard fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSURLErrorKey: fileURL])
        }

        fileHandle = try FileHandle(forWritingTo: fileURL)
        currentFileURL = fileURL
        currentFileSize = 0
        fileOpenedAt = date
        cleanupFiles(excluding: fileURL)
    }

    private func rollover(at date: Date) throws {
        try flushBuffer()
        closeCurrentFile()
        try openNewFile(at: date)
    }

    private func flushBuffer() throws {
        guard !buffer.isEmpty else {
            return
        }
        guard let fileHandle else {
            throw CocoaError(.fileNoSuchFile)
        }

        try fileHandle.seekToEnd()
        try fileHandle.write(contentsOf: buffer)
        currentFileSize += UInt64(buffer.count)
        buffer.removeAll(keepingCapacity: true)
    }

    private func closeCurrentFile() {
        try? fileHandle?.close()
        fileHandle = nil
        currentFileURL = nil
        currentFileSize = 0
        fileOpenedAt = nil
    }

    private func disable(error: Error, operation: String) {
        disabled = true
        buffer.removeAll(keepingCapacity: false)
        closeCurrentFile()
        PTLoggerInternalDiagnostics.report(error, operation: operation)
    }

    private func nextFileURL(for date: Date) -> URL {
        nextFileNumber &+= 1
        let timestamp = dateFormatter.string(from: date)
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        let filename = String(format: "ptools-%@-%03llu.log",
                              timestamp,
                              nextFileNumber)
        return configuration.directoryURL.appendingPathComponent(filename)
    }

    private func formattedLine(for record: PTLogRecord) -> String {
        let metadata = PTLogRedactor.formatMetadata(record.metadata, privacy: record.privacy)
        let metadataSuffix = metadata.isEmpty ? "" : " metadata={\(metadata)}"
        let message = PTLogRedactor.redact(message: record.message, privacy: record.privacy)
        return "\(dateFormatter.string(from: record.timestamp)) [\(record.sequence)] \(record.level.name) [\(record.category.rawValue)] \(record.file):\(record.line) \(record.function) \(message)\(metadataSuffix)\n"
    }

    private func cleanupFiles(excluding currentURL: URL?) {
        do {
            try fileManager.createDirectory(at: configuration.directoryURL,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey]
            let urls = try fileManager.contentsOfDirectory(at: configuration.directoryURL,
                                                            includingPropertiesForKeys: Array(keys),
                                                            options: [.skipsHiddenFiles])
                .filter { $0.lastPathComponent.hasPrefix("ptools-") && $0.pathExtension == "log" }

            var files = urls.compactMap { url -> (url: URL, date: Date, size: UInt64)? in
                let values = try? url.resourceValues(forKeys: keys)
                guard let date = values?.contentModificationDate,
                      let fileSize = values?.fileSize else { return nil }
                return (url, date, UInt64(max(0, fileSize)))
            }.sorted { $0.date < $1.date }

            let cutoff = Date().addingTimeInterval(-configuration.retentionDays)
            for file in files where file.date < cutoff && file.url != currentURL {
                remove(file.url)
            }

            files = existingFiles(in: configuration.directoryURL)
            while files.count > configuration.maximumFiles {
                guard let file = files.first(where: { $0.url != currentURL }) else { break }
                remove(file.url)
                files.removeFirst()
            }

            files = existingFiles(in: configuration.directoryURL)
            var totalSize = files.reduce(UInt64(0)) { $0 + $1.size }
            while totalSize > configuration.maximumTotalSize {
                guard let file = files.first(where: { $0.url != currentURL }) else { break }
                remove(file.url)
                totalSize = totalSize >= file.size ? totalSize - file.size : 0
                files.removeFirst()
            }
        } catch {
            PTLoggerInternalDiagnostics.report(error, operation: "cleanup")
        }
    }

    private func existingFiles(in directoryURL: URL) -> [(url: URL, date: Date, size: UInt64)] {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey]
        let urls = (try? fileManager.contentsOfDirectory(at: directoryURL,
                                                          includingPropertiesForKeys: Array(keys),
                                                          options: [.skipsHiddenFiles])) ?? []
        return urls.compactMap { url -> (url: URL, date: Date, size: UInt64)? in
            let values = try? url.resourceValues(forKeys: keys)
            guard let date = values?.contentModificationDate,
                  let fileSize = values?.fileSize,
                  url.lastPathComponent.hasPrefix("ptools-"),
                  url.pathExtension == "log" else { return nil }
            return (url, date, UInt64(max(0, fileSize)))
        }.sorted { $0.date < $1.date }
    }

    private func remove(_ url: URL) {
        do {
            try fileManager.removeItem(at: url)
        } catch {
            PTLoggerInternalDiagnostics.report(error, operation: "remove \(url.lastPathComponent)")
        }
    }
}

private extension PTLogLevel {
    var name: String {
        switch self {
        case .trace: return "TRACE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .notice: return "NOTICE"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        }
    }
}
