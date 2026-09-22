//
//  PTLoggerInternalDiagnostics.swift
//  PToolsLogging
//
// English: Reports logging-backend failures directly to OSLog without re-entering PTLogger.
// Español: Informa los fallos del backend directamente a OSLog sin volver a entrar en PTLogger.
// 中文：将日志后端错误直接写入 OSLog，避免再次进入 PTLogger 造成递归。
//

import OSLog

enum PTLoggerInternalDiagnostics {
    private static let logger = Logger(subsystem: "com.crazypoo.PTools", category: "Logging")

    static func report(_ error: Error, operation: String) {
        logger.error("File logging failed during \(operation, privacy: .public): \(String(reflecting: error), privacy: .public)")
    }

    static func report(_ message: String) {
        logger.error("File logging diagnostic: \(message, privacy: .public)")
    }
}
