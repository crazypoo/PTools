// English: Diagnostics are debug-only and never turn a missing icon into an application crash.
// Español: Los diagnósticos solo existen en Debug y nunca convierten un icono ausente en un crash.
// 中文：诊断仅在 Debug 中输出，缺失图标永远不会导致宿主应用崩溃。

import OSLog

public enum PTSymbolDiagnostics {
    private static let logger = Logger(subsystem: "com.crazypoo.PTools", category: "PTSymbol")

    public static func reportUnavailable(symbol: PTSymbol,
                                         fallback: PTSymbolFallback,
                                         attemptedNames: [String]) {
        #if DEBUG
        let fallbackName = fallback.symbols.map(\.rawValue).joined(separator: ",")
        logger.debug("PTSymbol unavailable name=\(symbol.rawValue, privacy: .public) fallback=\(fallbackName, privacy: .public) attempted=\(attemptedNames.joined(separator: ","), privacy: .public) catalog=\(PTSymbolCatalog.catalogVersion, privacy: .public)")
        #endif
    }
}
