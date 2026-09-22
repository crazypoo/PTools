//
//  PTLogger.swift
//  PToolsLogging
//
// English: Provides a synchronous, lazy and Sendable logging facade for PTools.
// Español: Proporciona una fachada de logging síncrona, perezosa y Sendable para PTools.
// 中文：为 PTools 提供同步、惰性且符合 Sendable 的日志门面。
//

import Foundation
import os.lock

public enum PTLogger {
    private struct RuntimeState: Sendable {
        var configuration = PTLogConfiguration()
        var sequence: UInt64 = 0
        var destinations: [String: any PTLogDestination] = [
            PTOSLogDestination.defaultIdentifier: PTOSLogDestination()
        ]
    }

    private static let state = OSAllocatedUnfairLock(initialState: RuntimeState())

    public static var configuration: PTLogConfiguration {
        state.withLock { $0.configuration }
    }

    public static var latestSequence: UInt64 {
        state.withLock { $0.sequence }
    }

    public static var logDirectory: URL {
        PTLogFileConfiguration().directoryURL
    }

    public static func configure(_ update: @Sendable (inout PTLogConfiguration) -> Void) {
        state.withLock { update(&$0.configuration) }
    }

    public static func addDestination(_ destination: any PTLogDestination) {
        state.withLock { $0.destinations[destination.identifier] = destination }
    }

    public static func removeDestination(identifier: String) {
        state.withLock { _ = $0.destinations.removeValue(forKey: identifier) }
    }

    // English: Install file logging explicitly so disk I/O remains opt-in for host applications.
    // Español: Instala el logging de archivos de forma explícita para que la E/S de disco sea opcional.
    // 中文：显式安装文件日志，让磁盘 I/O 默认保持可选。
    @discardableResult
    public static func installFileDestination(configuration: PTLogFileConfiguration = PTLogFileConfiguration()) -> String {
        let destination = PTFileLogDestination(configuration: configuration)
        addDestination(destination)
        return destination.identifier
    }

    // English: Reuse the existing file destination so toggling legacy file logging cannot duplicate writers.
    // Español: Reutiliza el destino de archivos existente para que activar el logging heredado no duplique writers.
    // 中文：复用已有文件日志目标，避免旧开关反复创建重复 writer。
    @discardableResult
    public static func installFileDestinationIfNeeded(configuration: PTLogFileConfiguration = PTLogFileConfiguration()) -> String {
        state.withLock { state in
            if state.destinations["ptools.file"] is PTFileLogDestination {
                return "ptools.file"
            }
            let destination = PTFileLogDestination(configuration: configuration)
            state.destinations[destination.identifier] = destination
            return destination.identifier
        }
    }

    // English: Install one shared memory destination for LocalConsole and Instruments without duplicating log pipelines.
    // Español: Instala un único destino de memoria compartido para LocalConsole e Instruments sin duplicar tuberías de logs.
    // 中文：为 LocalConsole 和 Instruments 安装共享的内存日志目标，避免重复日志管线。
    @discardableResult
    public static func installMemoryDestination(capacity: Int = 2_000,
                                                queueCapacity: Int = 5_000,
                                                dropPolicy: PTLogDropPolicy = .preferImportant) -> PTMemoryLogDestination {
        state.withLock { state in
            if let destination = state.destinations[PTMemoryLogDestination.defaultIdentifier] as? PTMemoryLogDestination {
                return destination
            }
            let destination = PTMemoryLogDestination(capacity: capacity,
                                                     queueCapacity: queueCapacity,
                                                     dropPolicy: dropPolicy)
            state.destinations[destination.identifier] = destination
            return destination
        }
    }

    public static func memoryDestination() -> PTMemoryLogDestination? {
        state.withLock { $0.destinations[PTMemoryLogDestination.defaultIdentifier] as? PTMemoryLogDestination }
    }

    public static func logFiles(configuration: PTLogFileConfiguration = PTLogFileConfiguration()) async -> [URL] {
        await PTFileLogDestination.logFiles(configuration: configuration)
    }

    // English: Flush persistent destinations before returning files suitable for sharing or export.
    // Español: Vacía los destinos persistentes antes de devolver archivos aptos para compartir o exportar.
    // 中文：返回可分享或导出的文件前，先刷新所有持久化日志目标。
    public static func exportLogFiles(configuration: PTLogFileConfiguration = PTLogFileConfiguration()) async -> [URL] {
        await flush()
        return await logFiles(configuration: configuration)
    }

    public static func isEnabled(level: PTLogLevel,
                                 category: PTLogCategory = .general) -> Bool {
        state.withLock { level >= $0.configuration.minimumLevel(for: category) }
    }

    public static func trace(_ message: @autoclosure () -> String,
                             category: PTLogCategory = .general,
                             metadata: PTLogMetadata = [:],
                             privacy: PTLogPrivacy = .public,
                             file: StaticString = #fileID,
                             function: StaticString = #function,
                             line: UInt = #line) {
        write(message, level: .trace, category: category, metadata: metadata, privacy: privacy,
              file: String(describing: file), function: String(describing: function), line: line)
    }

    public static func debug(_ message: @autoclosure () -> String,
                             category: PTLogCategory = .general,
                             metadata: PTLogMetadata = [:],
                             privacy: PTLogPrivacy = .public,
                             file: StaticString = #fileID,
                             function: StaticString = #function,
                             line: UInt = #line) {
        write(message, level: .debug, category: category, metadata: metadata, privacy: privacy,
              file: String(describing: file), function: String(describing: function), line: line)
    }

    public static func info(_ message: @autoclosure () -> String,
                            category: PTLogCategory = .general,
                            metadata: PTLogMetadata = [:],
                            privacy: PTLogPrivacy = .public,
                            file: StaticString = #fileID,
                            function: StaticString = #function,
                            line: UInt = #line) {
        write(message, level: .info, category: category, metadata: metadata, privacy: privacy,
              file: String(describing: file), function: String(describing: function), line: line)
    }

    public static func notice(_ message: @autoclosure () -> String,
                              category: PTLogCategory = .general,
                              metadata: PTLogMetadata = [:],
                              privacy: PTLogPrivacy = .public,
                              file: StaticString = #fileID,
                              function: StaticString = #function,
                              line: UInt = #line) {
        write(message, level: .notice, category: category, metadata: metadata, privacy: privacy,
              file: String(describing: file), function: String(describing: function), line: line)
    }

    public static func warning(_ message: @autoclosure () -> String,
                               category: PTLogCategory = .general,
                               metadata: PTLogMetadata = [:],
                               privacy: PTLogPrivacy = .public,
                               file: StaticString = #fileID,
                               function: StaticString = #function,
                               line: UInt = #line) {
        write(message, level: .warning, category: category, metadata: metadata, privacy: privacy,
              file: String(describing: file), function: String(describing: function), line: line)
    }

    public static func error(_ message: @autoclosure () -> String,
                             category: PTLogCategory = .general,
                             metadata: PTLogMetadata = [:],
                             privacy: PTLogPrivacy = .public,
                             file: StaticString = #fileID,
                             function: StaticString = #function,
                             line: UInt = #line) {
        write(message, level: .error, category: category, metadata: metadata, privacy: privacy,
              file: String(describing: file), function: String(describing: function), line: line)
    }

    public static func error(_ error: any Error,
                             category: PTLogCategory = .general,
                             metadata: PTLogMetadata = [:],
                             privacy: PTLogPrivacy = .public,
                             file: StaticString = #fileID,
                             function: StaticString = #function,
                             line: UInt = #line) {
        let nsError = error as NSError
        var errorMetadata = metadata
        errorMetadata["errorDomain"] = nsError.domain
        errorMetadata["errorCode"] = String(nsError.code)
        let message = "\(String(describing: type(of: error))): \(nsError.localizedDescription)"
        write({ message }, level: .error, category: category, metadata: errorMetadata, privacy: privacy,
              file: String(describing: file), function: String(describing: function), line: line)
    }

    public static func fault(_ message: @autoclosure () -> String,
                             category: PTLogCategory = .general,
                             metadata: PTLogMetadata = [:],
                             privacy: PTLogPrivacy = .sensitive,
                             file: StaticString = #fileID,
                             function: StaticString = #function,
                             line: UInt = #line) {
        write(message, level: .fault, category: category, metadata: metadata, privacy: privacy,
              file: String(describing: file), function: String(describing: function), line: line)
    }

    public static func log(_ message: @autoclosure () -> String,
                           level: PTLogLevel,
                           category: PTLogCategory = .general,
                           metadata: PTLogMetadata = [:],
                           privacy: PTLogPrivacy = .public,
                           file: StaticString = #fileID,
                           function: StaticString = #function,
                           line: UInt = #line) {
        write(message, level: level, category: category, metadata: metadata, privacy: privacy,
              file: String(describing: file), function: String(describing: function), line: line)
    }

    // English: Accept dynamic source snapshots from compatibility wrappers without using unsafe StaticString conversions.
    // Español: Acepta snapshots de origen dinámicos desde wrappers de compatibilidad sin conversiones inseguras de StaticString.
    // 中文：兼容包装器可传入动态来源快照，不再进行不安全的 StaticString 转换。
    public static func log(_ message: String,
                           level: PTLogLevel,
                           category: PTLogCategory = .general,
                           metadata: PTLogMetadata = [:],
                           privacy: PTLogPrivacy = .public,
                           source: PTLogSource) {
        write({ message }, level: level, category: category, metadata: metadata, privacy: privacy,
              file: source.file, function: source.function, line: source.line)
    }

    public static func flush() async {
        let destinations = state.withLock { Array($0.destinations.values) }
        for destination in destinations {
            await destination.flush()
        }
    }

    private static func write(_ message: () -> String,
                              level: PTLogLevel,
                              category: PTLogCategory,
                              metadata: PTLogMetadata,
                              privacy: PTLogPrivacy,
                              file: String,
                              function: String,
                              line: UInt) {
        let context: (sequence: UInt64, configuration: PTLogConfiguration, destinations: [any PTLogDestination])? = state.withLock { state in
            guard level >= state.configuration.minimumLevel(for: category) else { return nil }
            state.sequence &+= 1
            return (state.sequence, state.configuration, Array(state.destinations.values))
        }

        guard let context else { return }
        let record = PTLogRecord(sequence: context.sequence,
                                 level: level,
                                 subsystem: context.configuration.subsystem,
                                 category: category,
                                 message: message(),
                                 metadata: metadata,
                                 privacy: privacy,
                                 file: file,
                                 function: function,
                                 line: line)
        context.destinations.forEach { $0.append(record) }
    }
}
