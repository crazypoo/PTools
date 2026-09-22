import Foundation

#if canImport(PToolsLogging)
import PToolsLogging
#endif

#if !canImport(PToolsLogging) && !POOTOOLS_LOGGING
import os
#endif

// English: Keep the historical symbol as a thin adapter backed only by PTLogger.
// Español: Conserva el símbolo histórico como un adaptador delgado respaldado únicamente por PTLogger.
// 中文：保留历史符号，并将实现收敛为仅由 PTLogger 支持的轻量适配器。
public actor PTLogFileManager {
    public static let shared = PTLogFileManager()

    private init() {}

    public func append(logText: String) {
#if canImport(PToolsLogging) || POOTOOLS_LOGGING
        PTLogger.installFileDestinationIfNeeded()
        PTLogger.log(
            logText,
            level: .info,
            category: .general,
            privacy: .privateData,
            source: PTLogSource(
                file: "PTLogFileManager",
                function: "append(logText:)",
                line: 0
            )
        )
#else
        // English: Native OSLog keeps direct Example builds usable when the package logging target is not part of the target.
        // Español: OSLog nativo mantiene utilizables las compilaciones directas de Example cuando el target de logging no está incluido.
        // 中文：当直接 Example target 未包含日志包 target 时，使用系统 OSLog 保证其仍可用。
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ptools.example",
                            category: "PTools.File")
        logger.info("\(logText, privacy: .private)")
#endif
    }
}
