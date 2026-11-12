// English: Platform adapters keep URL opening on the correct UI actor without leaking UIKit into the core contracts.
// Español: Los adaptadores de plataforma mantienen la apertura de URL en el actor de UI correcto sin filtrar UIKit al núcleo.
// 中文：平台适配器保证 URL 打开运行在正确的 UI actor 上，同时不让 UIKit 泄漏到核心契约。

#if canImport(UIKit) && !os(watchOS)
import UIKit

@MainActor
extension UIApplication: PTApplicationCaller {}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

/// AppKit adapter for macOS hosts.
/// Adaptador AppKit para hosts macOS.
/// macOS 宿主使用的 AppKit 适配器。
@MainActor
public final class PTWorkspaceApplicationCaller: PTApplicationCaller {
    public init() {}

    public func canOpenURL(_ url: URL) -> Bool {
        NSWorkspace.shared.urlForApplication(toOpen: url) != nil
    }

    @discardableResult
    public func openURL(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}
#endif

#if canImport(Foundation)
import Foundation

/// A deterministic no-op caller for extensions, previews, and tests.
/// Un caller determinista sin operación para extensiones, previews y tests.
/// 用于扩展、预览和测试的确定性空实现 caller。
@MainActor
public final class PTRecordingApplicationCaller: PTApplicationCaller {
    public private(set) var openedURLs: [URL] = []
    public var canOpenHandler: @MainActor (URL) -> Bool

    public init(canOpenHandler: @escaping @MainActor (URL) -> Bool = { _ in true }) {
        self.canOpenHandler = canOpenHandler
    }

    public func canOpenURL(_ url: URL) -> Bool {
        canOpenHandler(url)
    }

    @discardableResult
    public func openURL(_ url: URL) -> Bool {
        openedURLs.append(url)
        return true
    }
}
#endif
