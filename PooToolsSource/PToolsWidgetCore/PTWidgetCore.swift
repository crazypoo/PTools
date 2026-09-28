// English: Foundation-first shared state, timelines, reloads, and deep links for WidgetKit hosts.
// Español: Estado compartido, timelines, recargas y deep links basados primero en Foundation para hosts de WidgetKit.
// 中文：为 WidgetKit 宿主提供 Foundation 优先的共享状态、时间线、刷新和深链能力。

import Foundation

#if SWIFT_PACKAGE
import PToolsStorage
import PToolsStorageCore
import PToolsDeepLink
import PToolsRouteCore
#endif

#if canImport(WidgetKit)
import WidgetKit
#endif

public struct PTWidgetSnapshot<Value: Codable & Sendable>: Codable, Sendable {
    public let value: Value
    public let updatedAt: Date

    public init(value: Value, updatedAt: Date = .now) {
        self.value = value
        self.updatedAt = updatedAt
    }
}

public struct PTWidgetTimelinePayload<Value: Codable & Sendable>: Codable, Sendable {
    public let entries: [PTWidgetSnapshot<Value>]
    public let reloadPolicy: PTWidgetReloadPolicy

    public init(entries: [PTWidgetSnapshot<Value>],
                reloadPolicy: PTWidgetReloadPolicy = .after(seconds: 900)) {
        self.entries = entries
        self.reloadPolicy = reloadPolicy
    }
}

public enum PTWidgetReloadPolicy: Codable, Hashable, Sendable {
    case manual
    case immediate
    case after(seconds: TimeInterval)
}

public enum PTWidgetStoreError: Error, Sendable, Equatable {
    case emptyAppGroupIdentifier
}

public actor PTWidgetSharedStore {
    public let appGroupIdentifier: String
    private let storage: PTStorage

    public init(appGroupIdentifier: String,
                namespace: String = "widget") throws {
        guard !appGroupIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PTWidgetStoreError.emptyAppGroupIdentifier
        }
        self.appGroupIdentifier = appGroupIdentifier
        let backend = PTUserDefaultsStorage(suiteName: appGroupIdentifier)
        self.storage = PTStorage(namespace: PTStorageNamespace(module: "PTools",
                                                               feature: namespace,
                                                               environment: "app-group"),
                                  backend: backend)
    }

    public func read<Value: Codable & Sendable>(_ key: PTStorageKey<Value>) async throws -> Value? {
        try await storage.value(for: key)
    }

    public func write<Value: Codable & Sendable>(_ value: Value,
                                                for key: PTStorageKey<Value>) async throws {
        try await storage.set(value, for: key)
    }

    public func remove<Value: Codable & Sendable>(_ key: PTStorageKey<Value>) async throws {
        try await storage.remove(for: key)
    }
}

public struct PTWidgetDeepLink: Codable, Hashable, Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func route(using configuration: PTDeepLinkConfiguration = .init()) throws -> PTRouteRequest {
        try PTDeepLinkParser.request(from: url, configuration: configuration)
    }
}

@MainActor
public final class PTWidgetReloadCoordinator {
    public static let shared = PTWidgetReloadCoordinator()

    private var pendingKinds = Set<String>()
    private var debounceTask: Task<Void, Never>?

    public init() {}

    deinit {
        debounceTask?.cancel()
    }

    public func requestReload(kind: String,
                              policy: PTWidgetReloadPolicy = .after(seconds: 0.25)) {
        guard !kind.isEmpty else { return }
        switch policy {
        case .manual:
            return
        case .immediate:
            reload(kind: kind)
        case .after(let seconds):
            pendingKinds.insert(kind)
            debounceTask?.cancel()
            let delay = UInt64(max(seconds, 0) * 1_000_000_000)
            debounceTask = Task { @MainActor [weak self] in
                if delay > 0 { try? await Task.sleep(nanoseconds: delay) }
                guard !Task.isCancelled, let self else { return }
                let kinds = self.pendingKinds
                self.pendingKinds.removeAll()
                kinds.forEach(self.reload(kind:))
            }
        }
    }

    public func reloadAll() {
#if canImport(WidgetKit)
        importWidgetKitReloadAll()
#endif
    }

    private func reload(kind: String) {
#if canImport(WidgetKit)
        importWidgetKitReload(kind: kind)
#else
        _ = kind
#endif
    }

#if canImport(WidgetKit)
    private func importWidgetKitReload(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    private func importWidgetKitReloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
#endif
}
