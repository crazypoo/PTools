// English: Connect PTLayout diagnostics to the existing PTools console without coupling the standalone product.
// Español: Conecta los diagnósticos de PTLayout con la consola existente de PTools sin acoplar el producto independiente.
// 中文：将 PTLayout 诊断接入现有 PTools 控制台，同时不让独立产品反向依赖 PTools。

#if canImport(PToolsConstraintLayout) || POOTOOLS_COCOAPODS
import Foundation
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif

@MainActor
public enum PTLayoutConsoleBridge {
    private static var isInstalled = false

    /// English: Install once so layout failures are visible in PTNSLogConsole.
    /// Español: Instala una sola vez para que los fallos de layout sean visibles en PTNSLogConsole.
    /// 中文：只安装一次，让布局失败可以在 PTNSLogConsole 中看到。
    public static func install() {
        guard !isInstalled else { return }
        isInstalled = true
        PTLayoutDiagnostics.onFailure = { issue in
            PTNSLogConsole(issue.message,
                           isWriteLog: false,
                           file: issue.fileID as NSString,
                           line: Int(issue.line),
                           fn: issue.function,
                           levelType: .warning,
                           loggerType: .other)
        }
    }
}
#endif
