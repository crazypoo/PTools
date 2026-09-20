// English: The hook registry owns opt-in Debug hook installation and keeps teardown reversible.
// Español: El registro de hooks posee la instalación opcional de Debug y mantiene un desmontaje reversible.
// 中文：Hook Registry 统一管理可选的 Debug Hook 安装，并保证卸载过程可逆。

import Foundation

// English: A value snapshot lets the Debug UI inspect registrations without receiving hook closures.
// Español: Un snapshot de valor permite a la UI de Debug inspeccionar registros sin recibir closures de hooks.
// 中文：值类型快照让 Debug UI 可以查看注册信息，而不接触 Hook 闭包。
public struct PTDebugHookDescriptor: Sendable, Equatable, Identifiable {
    public let id: String
    public let owner: String
    public let isInstalled: Bool

    public init(id: String, owner: String, isInstalled: Bool) {
        self.id = id
        self.owner = owner
        self.isInstalled = isInstalled
    }
}

// English: MainActor isolation prevents hook state from racing with UIKit lifecycle callbacks.
// Español: El aislamiento MainActor evita carreras entre el estado de hooks y los callbacks del ciclo de vida de UIKit.
// 中文：MainActor 隔离避免 Hook 状态与 UIKit 生命周期回调发生数据竞争。
@MainActor
public final class PTDebugHookRegistry {
    public static let shared = PTDebugHookRegistry()

    private struct Entry {
        let owner: String
        let install: @MainActor () -> Void
        let uninstall: @MainActor () -> Void
        var isInstalled: Bool
    }

    private var entries: [String: Entry] = [:]

    private init() {}

    public var isInstalled: Bool {
        entries.values.contains(where: { $0.isInstalled })
    }

    public var descriptors: [PTDebugHookDescriptor] {
        entries.keys.sorted().compactMap { identifier in
            guard let entry = entries[identifier] else { return nil }
            return PTDebugHookDescriptor(id: identifier,
                                         owner: entry.owner,
                                         isInstalled: entry.isInstalled)
        }
    }

    public func isInstalled(_ identifier: String) -> Bool {
        entries[identifier]?.isInstalled == true
    }

    public func contains(_ identifier: String) -> Bool {
        entries[identifier] != nil
    }

    @discardableResult
    public func register(identifier: String,
                         owner: String,
                         install: @escaping @MainActor () -> Void,
                         uninstall: @escaping @MainActor () -> Void) -> Bool {
        guard !identifier.isEmpty, !owner.isEmpty else { return false }
        guard entries[identifier] == nil else { return false }
        entries[identifier] = Entry(owner: owner,
                                    install: install,
                                    uninstall: uninstall,
                                    isInstalled: false)
        return true
    }

    public func unregister(identifier: String) {
        uninstall(identifier: identifier)
        entries.removeValue(forKey: identifier)
    }

    public func install() {
        entries.keys.sorted().forEach { install(identifier: $0) }
    }

    public func install(identifier: String) {
        guard var entry = entries[identifier], !entry.isInstalled else { return }
        entry.install()
        entry.isInstalled = true
        entries[identifier] = entry
    }

    public func uninstall() {
        entries.keys.sorted().reversed().forEach { uninstall(identifier: $0) }
    }

    public func uninstall(identifier: String) {
        guard var entry = entries[identifier], entry.isInstalled else { return }
        entry.uninstall()
        entry.isInstalled = false
        entries[identifier] = entry
    }
}
