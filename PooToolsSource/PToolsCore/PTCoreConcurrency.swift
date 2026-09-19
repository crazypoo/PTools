//
//  PTCoreConcurrency.swift
//  PToolsCore
//
// English: Foundation-only synchronization and cancellation primitives for the Core boundary.
// Español: Primitivas de sincronización y cancelación basadas solo en Foundation para el límite Core.
// 中文：为 Core 边界提供仅依赖 Foundation 的同步与取消基础设施。
//

import Foundation
import os.lock

// English: Protect a Sendable value with a small synchronous critical section.
// Español: Protege un valor Sendable mediante una sección crítica síncrona y pequeña.
// 中文：使用小型同步临界区保护 Sendable 值。
public struct PTLocked<Value: Sendable>: Sendable {
    private let storage: OSAllocatedUnfairLock<Value>

    public init(_ value: Value) {
        storage = OSAllocatedUnfairLock(initialState: value)
    }

    @discardableResult
    public func withLock<Result: Sendable>(_ body: @Sendable (inout Value) throws -> Result) rethrows -> Result {
        try storage.withLock(body)
    }

    public var value: Value {
        storage.withLock { $0 }
    }

    public func replace(with value: Value) {
        storage.withLock { $0 = value }
    }
}

// English: Provide compare-and-exchange semantics without exposing the lock implementation.
// Español: Proporciona semántica de comparación e intercambio sin exponer la implementación del bloqueo.
// 中文：提供比较交换语义，同时不暴露底层锁实现。
public struct PTAtomic<Value: Equatable & Sendable>: Sendable {
    private let storage: PTLocked<Value>

    public init(_ value: Value) {
        storage = PTLocked(value)
    }

    public var value: Value {
        get { storage.value }
        set { storage.replace(with: newValue) }
    }

    @discardableResult
    public func compareExchange(expected: Value, desired: Value) -> Bool {
        storage.withLock { value in
            guard value == expected else { return false }
            value = desired
            return true
        }
    }
}

private struct PTCancellationState: Sendable {
    var isCancelled = false
    var handlers: [UUID: @Sendable () -> Void] = [:]
}

// English: A synchronous cancellation source that runs each observer at most once.
// Español: Una fuente de cancelación síncrona que ejecuta cada observador como máximo una vez.
// 中文：同步取消源，保证每个观察者最多执行一次。
public final class PTCancellationToken: Sendable, PTCancellable {
    private let state = PTLocked(PTCancellationState())

    public init() {}

    public var isCancelled: Bool {
        state.withLock { $0.isCancelled }
    }

    @discardableResult
    public func cancel() -> Bool {
        let cancellation = state.withLock { state -> (didCancel: Bool, handlers: [@Sendable () -> Void]) in
            guard !state.isCancelled else { return (false, []) }
            state.isCancelled = true
            let handlers = Array(state.handlers.values)
            state.handlers.removeAll(keepingCapacity: false)
            return (true, handlers)
        }

        cancellation.handlers.forEach { $0() }
        return cancellation.didCancel
    }

    @discardableResult
    public func observe(_ handler: @escaping @Sendable () -> Void) -> PTCancellationRegistration {
        let identifier = UUID()
        let invokeImmediately = state.withLock { state -> Bool in
            guard !state.isCancelled else { return true }
            state.handlers[identifier] = handler
            return false
        }

        if invokeImmediately {
            handler()
            return PTCancellationRegistration {}
        }

        return PTCancellationRegistration { [weak self] in
            self?.removeHandler(identifier)
        }
    }

    private func removeHandler(_ identifier: UUID) {
        state.withLock { state in
            state.handlers.removeValue(forKey: identifier)
        }
    }

    public func invalidate() {
        cancel()
    }
}

// English: Keep cancellation observer removal explicit and idempotent.
// Español: Mantiene explícita e idempotente la eliminación del observador de cancelación.
// 中文：让取消观察者的移除操作显式且幂等。
public final class PTCancellationRegistration: Sendable {
    private let cancellation: @Sendable () -> Void
    private let didCancel = PTAtomic(false)

    fileprivate init(_ cancellation: @escaping @Sendable () -> Void) {
        self.cancellation = cancellation
    }

    public func cancel() {
        guard didCancel.compareExchange(expected: false, desired: true) else { return }
        cancellation()
    }

    deinit {
        cancel()
    }
}

// English: Group cancellation sources owned by one lifecycle boundary.
// Español: Agrupa las fuentes de cancelación pertenecientes a un mismo límite de ciclo de vida.
// 中文：聚合一个生命周期边界所拥有的多个取消源。
public final class PTCancellationBag: Sendable {
    private let tokens = PTLocked([UUID: PTCancellationToken]())

    public init() {}

    @discardableResult
    public func insert(_ token: PTCancellationToken) -> UUID {
        let identifier = UUID()
        tokens.withLock { $0[identifier] = token }
        return identifier
    }

    public func remove(_ identifier: UUID, cancel: Bool = false) {
        let token = tokens.withLock { $0.removeValue(forKey: identifier) }
        if cancel {
            token?.cancel()
        }
    }

    public func cancelAll() {
        let currentTokens = tokens.withLock { tokens -> [PTCancellationToken] in
            let currentTokens = Array(tokens.values)
            tokens.removeAll(keepingCapacity: false)
            return currentTokens
        }
        currentTokens.forEach { $0.cancel() }
    }

    deinit {
        cancelAll()
    }
}

// English: Represent the invalidation point of a short-lived service or UI owner.
// Español: Representa el punto de invalidación de un servicio o propietario de UI de corta duración.
// 中文：表示短生命周期服务或 UI 所有者的失效节点。
public final class PTLifecycleToken: Sendable, PTCancellable {
    private let cancellationToken = PTCancellationToken()

    public init() {}

    public var isCancelled: Bool {
        cancellationToken.isCancelled
    }

    public func observe(_ handler: @escaping @Sendable () -> Void) -> PTCancellationRegistration {
        cancellationToken.observe(handler)
    }

    public func invalidate() {
        cancellationToken.cancel()
    }

    deinit {
        cancellationToken.cancel()
    }
}

// English: Retain cancellable tasks without making a feature own a second task registry.
// Español: Conserva tareas cancelables sin que cada función mantenga otro registro de tareas.
// 中文：统一持有可取消任务，避免每个功能模块重复实现任务注册表。
public final class PTTaskStore: Sendable {
    private let tasks = PTLocked([UUID: Task<Void, Never>]())

    public init() {}

    @discardableResult
    public func insert(_ task: Task<Void, Never>) -> UUID {
        let identifier = UUID()
        tasks.withLock { $0[identifier] = task }
        return identifier
    }

    public func remove(_ identifier: UUID) {
        tasks.withLock { $0.removeValue(forKey: identifier) }
    }

    public func cancel(_ identifier: UUID) {
        let task = tasks.withLock { $0.removeValue(forKey: identifier) }
        task?.cancel()
    }

    public func cancelAll() {
        let currentTasks = tasks.withLock { tasks -> [Task<Void, Never>] in
            let currentTasks = Array(tasks.values)
            tasks.removeAll(keepingCapacity: false)
            return currentTasks
        }
        currentTasks.forEach { $0.cancel() }
    }

    deinit {
        cancelAll()
    }
}

// English: The protocol keeps lifecycle cleanup independent from UIKit and feature implementations.
// Español: El protocolo mantiene la limpieza del ciclo de vida independiente de UIKit y de las funciones concretas.
// 中文：该协议让生命周期清理独立于 UIKit 和具体功能实现。
public protocol PTInvalidating {
    func invalidate()
}

public protocol PTCancellable: PTInvalidating {
    var isCancelled: Bool { get }
}
