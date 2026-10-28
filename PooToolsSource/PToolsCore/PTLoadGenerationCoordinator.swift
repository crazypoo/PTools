//
//  PTLoadGenerationCoordinator.swift
//  PToolsCore
//
// English: Coordinate cancellation and stale-result rejection without UIKit or a feature owner.
// Español: Coordina la cancelación y el rechazo de resultados obsoletos sin UIKit ni un propietario de función.
// 中文：不依赖 UIKit 或具体业务所有者，统一管理取消和陈旧结果拒绝。
//

import Foundation

// English: A load token is an immutable value safe to capture in an async operation.
// Español: Un token de carga es un valor inmutable seguro para capturar en una operación asíncrona.
// 中文：加载令牌是不可变值，可安全捕获到异步任务中。
public struct PTLoadGenerationToken: Sendable, Hashable {
    public let generation: UInt64
    public let id: UUID

    fileprivate init(generation: UInt64, id: UUID = UUID()) {
        self.generation = generation
        self.id = id
    }
}

private struct PTLoadGenerationState: Sendable {
    var generation: UInt64 = 0
    var currentToken: PTLoadGenerationToken?
    var task: Task<Void, Never>?
}

// English: The gate is synchronous so callers can invalidate a result before any actor hop.
// Español: La barrera es síncrona para invalidar resultados antes de cualquier salto de actor.
// 中文：门控操作是同步的，确保在跨 actor 前即可让结果失效。
public final class PTLoadGenerationCoordinator: Sendable {
    private let state = PTLocked(PTLoadGenerationState())

    public init() {}

    // English: Begin cancels the previous task and creates a fresh generation token.
    // Español: Begin cancela la tarea anterior y crea un token de generación nuevo.
    // 中文：开始新加载时取消旧任务，并创建新的代次令牌。
    @discardableResult
    public func begin() -> PTLoadGenerationToken {
        let result = state.withLock { state -> (PTLoadGenerationToken, Task<Void, Never>?) in
            let oldTask = state.task
            state.task = nil
            state.generation &+= 1
            let token = PTLoadGenerationToken(generation: state.generation)
            state.currentToken = token
            return (token, oldTask)
        }
        result.1?.cancel()
        return result.0
    }

    public func isCurrent(_ token: PTLoadGenerationToken) -> Bool {
        state.withLock { $0.currentToken == token }
    }

    // English: Replacing a task is ignored safely when its token is already stale.
    // Español: El reemplazo de tarea se ignora de forma segura cuando su token ya es obsoleto.
    // 中文：令牌已失效时安全忽略任务替换，并立即取消传入任务。
    public func replaceTask(_ task: Task<Void, Never>, for token: PTLoadGenerationToken) {
        let result = state.withLock { state -> (old: Task<Void, Never>?, reject: Bool) in
            guard state.currentToken == token else { return (nil, true) }
            let oldTask = state.task
            state.task = task
            return (oldTask, false)
        }
        result.old?.cancel()
        if result.reject { task.cancel() }
    }

    public func removeTask(for token: PTLoadGenerationToken) {
        state.withLock { state in
            guard state.currentToken == token else { return }
            state.task = nil
        }
    }

    // English: Invalidate synchronously and cancel the task outside the lock.
    // Español: Invalida de forma síncrona y cancela la tarea fuera del bloqueo.
    // 中文：同步让令牌失效，并在锁外取消任务，避免回调重入。
    public func invalidate() {
        let task = state.withLock { state -> Task<Void, Never>? in
            state.generation &+= 1
            state.currentToken = nil
            let task = state.task
            state.task = nil
            return task
        }
        task?.cancel()
    }

    public func cancelCurrent() {
        invalidate()
    }

    deinit {
        let task = state.withLock { state -> Task<Void, Never>? in
            let task = state.task
            state.task = nil
            state.currentToken = nil
            return task
        }
        task?.cancel()
    }
}

// English: Keep the shorter name available for Foundation-only consumers.
// Español: Mantiene disponible el nombre corto para consumidores basados solo en Foundation.
// 中文：为仅依赖 Foundation 的调用方保留简短名称。
public typealias PTGenerationGate = PTLoadGenerationCoordinator
