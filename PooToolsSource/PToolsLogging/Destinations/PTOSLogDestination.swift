//
//  PTOSLogDestination.swift
//  PToolsLogging
//
// English: Sends immutable log records to Apple's OSLog with a cached Logger per subsystem and category.
// Español: Envía registros inmutables a OSLog de Apple con un Logger en caché por subsistema y categoría.
// 中文：将不可变日志记录发送到 Apple OSLog，并按 subsystem 和 category 缓存 Logger。
//

import Foundation
import OSLog
import os.lock

public struct PTOSLogDestination: PTLogDestination {
    public static let defaultIdentifier = "ptools.oslog"

    public let identifier: String

    public init(identifier: String = PTOSLogDestination.defaultIdentifier) {
        self.identifier = identifier
    }

    public func append(_ record: PTLogRecord) {
        let logger = Self.logger(for: record.subsystem, category: record.category)
        let message = Self.message(for: record)

        Self.write(message, level: record.level, to: logger, privacy: record.privacy)
    }

    public func flush() async {}

    private struct LoggerKey: Hashable, Sendable {
        let subsystem: String
        let category: String
    }

    private static let loggerCache = OSAllocatedUnfairLock(initialState: [LoggerKey: Logger]())

    // English: Cache OSLog Logger instances so high-frequency logging does not recreate them.
    // Español: Almacena en caché los Logger de OSLog para no recrearlos en logs de alta frecuencia.
    // 中文：缓存 OSLog Logger，避免高频日志反复创建实例。
    private static func logger(for subsystem: String, category: PTLogCategory) -> Logger {
        let key = LoggerKey(subsystem: subsystem, category: category.rawValue)
        return loggerCache.withLock { cache in
            if let logger = cache[key] {
                return logger
            }
            let logger = Logger(subsystem: subsystem, category: category.rawValue)
            cache[key] = logger
            return logger
        }
    }

    private static func message(for record: PTLogRecord) -> String {
        let metadata = PTLogRedactor.formatMetadata(record.metadata, privacy: record.privacy)
        let source = "\(record.file):\(record.line) \(record.function)"
        let metadataSuffix = metadata.isEmpty ? "" : " metadata={\(metadata)}"
        let message = PTLogRedactor.redact(message: record.message, privacy: record.privacy)
        return "[\(record.sequence)] \(source) \(message)\(metadataSuffix)"
    }

    private static func write(_ message: String,
                              level: PTLogLevel,
                              to logger: Logger,
                              privacy: PTLogPrivacy) {
        switch privacy {
        case .privateData:
            switch level {
            case .trace, .debug:
                logger.debug("\(message, privacy: .private(mask: .hash))")
            case .info:
                logger.info("\(message, privacy: .private(mask: .hash))")
            case .notice, .warning:
                logger.log("\(message, privacy: .private(mask: .hash))")
            case .error:
                logger.error("\(message, privacy: .private(mask: .hash))")
            case .fault:
                logger.fault("\(message, privacy: .private(mask: .hash))")
            }
        case .public, .sensitive:
            switch level {
            case .trace, .debug:
                logger.debug("\(message, privacy: .public)")
            case .info:
                logger.info("\(message, privacy: .public)")
            case .notice, .warning:
                logger.log("\(message, privacy: .public)")
            case .error:
                logger.error("\(message, privacy: .public)")
            case .fault:
                logger.fault("\(message, privacy: .public)")
            }
        }
    }
}
