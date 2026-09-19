//
//  PTMainActorBridge.swift
//  PToolsCore
//
// English: Provide one Foundation-only bridge for UI work owned by MainActor.
// Español: Proporciona un único puente basado en Foundation para el trabajo de UI propiedad de MainActor.
// 中文：提供仅依赖 Foundation 的统一 MainActor UI 调度桥接。
//

import Foundation

public enum PTMainActorBridge {
    @discardableResult
    public static func perform(_ operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            guard !Task.isCancelled else { return }
            operation()
        }
    }

    @discardableResult
    public static func after(_ delay: TimeInterval,
                             operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            guard delay.isFinite, delay >= 0 else { return }

            let maxDelay = TimeInterval(Int64.max) / 1_000_000_000
            let boundedDelay = min(delay, maxDelay)
            let nanoseconds = UInt64((boundedDelay * 1_000_000_000).rounded(.down))

            do {
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            operation()
        }
    }

    @discardableResult
    public static func cancellableAfter(_ delay: TimeInterval,
                                        operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        after(delay, operation: operation)
    }
}

public extension MainActor {
    @_unavailableFromAsync
    static func gcdRunUnsafely<T: Sendable>(_ body: @MainActor () throws -> T) rethrows -> T {
        try MainActor.assumeIsolated(body)
    }
}
