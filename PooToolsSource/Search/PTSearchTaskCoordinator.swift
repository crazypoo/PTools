//
//  PTSearchTaskCoordinator.swift
//  PooTools
//
// English: One MainActor owner cancels all search-related tasks consistently.
// Español: Un único propietario MainActor cancela de forma consistente todas las tareas de búsqueda.
// 中文：由一个 MainActor 所有者统一取消所有搜索相关任务。
//

import Foundation

@MainActor
public final class PTSearchTaskCoordinator {
    public enum Key: Hashable, Sendable {
        case debounce
        case search
        case suggestion
        case pagination
        case refresh
        case history
    }

    private var tasks: [Key: Task<Void, Never>] = [:]

    public init() {}

    public func replace(_ task: Task<Void, Never>, for key: Key) {
        tasks[key]?.cancel()
        tasks[key] = task
    }

    public func cancel(_ key: Key) {
        tasks.removeValue(forKey: key)?.cancel()
    }

    public func cancel<S: Sequence>(_ keys: S) where S.Element == Key {
        for key in keys { cancel(key) }
    }

    public func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll(keepingCapacity: true)
    }

    deinit {
        tasks.values.forEach { $0.cancel() }
    }
}
