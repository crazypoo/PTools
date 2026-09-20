//
//  PTSearchHistoryProvider.swift
//  PooTools
//
// English: History storage is actor-isolated so UserDefaults never crosses the UI task boundary unsafely.
// Español: El almacenamiento del historial está aislado por actor para que UserDefaults no cruce el límite de UI de forma insegura.
// 中文：历史记录存储通过 actor 隔离，避免 UserDefaults 不安全跨越 UI 任务边界。
//

import Foundation

public protocol PTSearchHistoryProvider: Sendable {
    func loadHistory() async -> [String]
    func save(keyword: String) async
    func delete(keyword: String) async
    func clear() async
}

public actor PTUserDefaultsSearchHistoryProvider: PTSearchHistoryProvider {
    private let suiteName: String?
    private let key: String
    public let maximumCount: Int

    public init(suiteName: String? = nil,
                key: String = "PTools.Search.History",
                maximumCount: Int = 20) {
        self.suiteName = suiteName
        self.key = key
        self.maximumCount = max(1, maximumCount)
    }

    public func loadHistory() async -> [String] {
        values()
    }

    public func save(keyword: String) async {
        let value = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        var history = values()
        history.removeAll { $0.caseInsensitiveCompare(value) == .orderedSame }
        history.insert(value, at: 0)
        defaults().set(Array(history.prefix(maximumCount)), forKey: key)
    }

    public func delete(keyword: String) async {
        let history = values().filter { $0.caseInsensitiveCompare(keyword) != .orderedSame }
        defaults().set(history, forKey: key)
    }

    public func clear() async {
        defaults().removeObject(forKey: key)
    }

    private func defaults() -> UserDefaults {
        guard let suiteName, !suiteName.isEmpty else { return .standard }
        return UserDefaults(suiteName: suiteName) ?? .standard
    }

    private func values() -> [String] {
        let raw = defaults().stringArray(forKey: key) ?? []
        var seen = Set<String>()
        return raw.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { return nil }
            return trimmed
        }
    }
}
