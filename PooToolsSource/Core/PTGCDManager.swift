//
//  PTGCDManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import os.lock

#if POOTOOLS_SPLIT_PERMISSION_CORE
import PToolsPermissionCore
// English: Reuse the permission-core callback type so SwiftPM and feature targets share one ABI-level contract.
// Español: Reutiliza el tipo de callback del núcleo de permisos para que SwiftPM y los targets de funciones compartan un único contrato.
// 中文：复用权限 Core 的回调类型，让 SwiftPM 与功能 target 共享同一套契约。
public typealias PTActionTask = PToolsPermissionCore.PTActionTask
#else
// English: Keep the legacy callback type available to the CocoaPods/Xcode source set.
// Español: Mantiene disponible el tipo de callback heredado para el conjunto de fuentes de CocoaPods/Xcode.
// 中文：为 CocoaPods/Xcode 旧源码集合保留回调类型。
public typealias PTActionTask = @Sendable () -> Void
#endif
public typealias PTActionAsyncTask = @Sendable () async -> Void

private struct PTGCDOnce: Sendable {
    private let didRun = OSAllocatedUnfairLock(initialState: false)

    func run(_ action: @Sendable () -> Void) {
        let shouldRun = didRun.withLock { didRun in
            guard !didRun else { return false }
            didRun = true
            return true
        }
        guard shouldRun else { return }
        action()
    }
}

private struct PTGCDContinuationState: Sendable {
    var continuation: CheckedContinuation<Void, Never>?
    var isCancelled = false
    var isFinished = false
}

// 使用 actor 来保证内部状态的绝对线程安全，完美契合 Swift 6
public actor PTGCDManager {
    
    public static let shared = PTGCDManager()
    
    // 用于保存定时器的 Task 引用，替代原有的 NSCache 和 DispatchSourceTimer
    private var activeTimers: [String: Task<Void, Never>] = [:]

    // English: A generation prevents an old one-shot task from removing a newer task with the same name.
    // Español: Una generación evita que una tarea antigua elimine otra nueva con el mismo nombre.
    // 中文：使用生成标识，避免旧的一次性任务误删同名的新任务。
    private var timerGenerations: [String: UUID] = [:]
    
    // 内部的取消标志，无需 NSLock，actor 自动保证读写安全
    public var cancelFlag: Bool = false
    
    // 确保单例纯粹性
    private init() {}
    
    // MARK: - Swift 6 异步定时器
    public func scheduledTimer(withName name: String,
                               timeInterval: TimeInterval,
                               repeats: Bool,
                               action: @escaping @MainActor @Sendable () -> Void) {
        
        // 如果已存在同名任务，先取消，防止内存泄漏或重复执行
        cancelTimer(withName: name)

        guard timeInterval.isFinite,
              timeInterval >= 0,
              !repeats || timeInterval > 0 else { return }

        // English: Use an Int64-sized nanosecond ceiling so floating-point rounding cannot overflow UInt64.
        // Español: Usa un límite de nanosegundos basado en Int64 para que el redondeo no desborde UInt64.
        // 中文：使用 Int64 大小的纳秒上限，避免浮点舍入导致 UInt64 溢出。
        let maxNanoseconds = UInt64(Int64.max)
        let maxInterval = TimeInterval(Int64.max) / 1_000_000_000
        let boundedInterval = min(timeInterval, maxInterval)
        let generation = UUID()
        timerGenerations[name] = generation
        
        let task = Task {
            let nanoseconds = min(UInt64((boundedInterval * 1_000_000_000).rounded(.down)), maxNanoseconds)
            
            repeat {
                // 检查任务是否被取消，协作式退出
                if Task.isCancelled { break }
                
                do {
                    // 非阻塞式休眠
                    try await Task.sleep(nanoseconds: nanoseconds)
                } catch {
                    // Task 被取消时会抛出 CancellationError，直接退出循环
                    break
                }
                
                if Task.isCancelled { break }
                
                // 确保 action 在主线程执行
                await MainActor.run {
                    action()
                }
                
            } while repeats && !Task.isCancelled
            
            // 执行完毕后清理字典中的自身引用
            if !repeats {
                removeTimerRef(name: name, generation: generation)
            }
        }
        
        activeTimers[name] = task
    }
    
    public func cancelTimer(withName name: String) {
        activeTimers[name]?.cancel()
        activeTimers.removeValue(forKey: name)
        timerGenerations.removeValue(forKey: name)
    }
    
    public func isExistTimer(withName name: String) -> Bool {
        return activeTimers[name] != nil
    }
    
    // 仅供内部清理使用
    private func removeTimerRef(name: String, generation: UUID) {
        guard timerGenerations[name] == generation else { return }
        activeTimers.removeValue(forKey: name)
        timerGenerations.removeValue(forKey: name)
    }
    
    // MARK: - 结构化并发组 (替代 DispatchGroup & DispatchSemaphore)
    public func taskGroupUtility(semaphoreCount: Int = 3,
                                 threadCount: Int,
                                 doSomeThing: @escaping @Sendable (_ currentIndex: Int, _ finishTask: @escaping @Sendable () -> Void) -> Void,
                                 allRequestsFinished: @escaping @MainActor @Sendable () -> Void) async {
        guard semaphoreCount > 0, threadCount > 0 else {
            await MainActor.run {
                allRequestsFinished()
            }
            return
        }
        
        await withTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            
            for i in 0..<threadCount {
                if self.cancelFlag { break }
                
                // 并发数控制机制
                if activeTasks >= semaphoreCount {
                    _ = await group.next()
                    activeTasks -= 1
                }
                
                group.addTask {
                    // English: Resume the bridge on either completion or cancellation, never both.
                    // Español: Reanuda el puente al completar o cancelar, pero nunca en ambos casos.
                    // 中文：在完成或取消时恢复桥接，但绝不会重复恢复。
                    let state = OSAllocatedUnfairLock(initialState: PTGCDContinuationState(continuation: nil))

                    await withTaskCancellationHandler(operation: {
                        await withCheckedContinuation { continuation in
                            let finishImmediately = state.withLock { state -> Bool in
                                guard !state.isFinished else { return true }
                                guard !state.isCancelled else {
                                    state.isFinished = true
                                    return true
                                }
                                state.continuation = continuation
                                return false
                            }

                            if finishImmediately {
                                continuation.resume()
                                return
                            }

                            doSomeThing(i) {
                                let continuation = state.withLock { state -> CheckedContinuation<Void, Never>? in
                                    guard !state.isFinished else { return nil }
                                    state.isFinished = true
                                    let continuation = state.continuation
                                    state.continuation = nil
                                    return continuation
                                }
                                continuation?.resume()
                            }
                        }
                    }, onCancel: {
                        let continuation = state.withLock { state -> CheckedContinuation<Void, Never>? in
                            state.isCancelled = true
                            guard !state.isFinished else { return nil }
                            state.isFinished = true
                            let continuation = state.continuation
                            state.continuation = nil
                            return continuation
                        }
                        continuation?.resume()
                    })
                }
                activeTasks += 1
            }
            
            await group.waitForAll()
        }
        
        await MainActor.run {
            allRequestsFinished()
        }
    }

    // MARK: - 现代化的快捷调度 (nonisolated)
    // nonisolated 关键字允许在 actor 外部不使用 await 直接调用这些无需访问 actor 内部状态的方法
    
    @discardableResult
    public nonisolated func delayOnMain(time: TimeInterval, block: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        PTMainActorBridge.after(time, operation: block)
    }
    
    /// 在后台执行任务，支持指定优先级 (等同于以前的 QoS)
    /// - Parameters:
    ///   - priority: 任务优先级，默认是 .background。相当于以前的 qosCls
    ///   - block: 要执行的后台任务闭包
    @discardableResult
    public nonisolated func runOnBackground(priority: TaskPriority? = nil,
                                            block: @escaping PTActionTask) -> Task<Void, Never> {
        // detached 用于明确脱离调用方 Actor；它不承诺固定线程，只承诺不继承 MainActor。
        Task.detached(priority: priority) {
            block()
        }
    }
    
    @discardableResult
    public nonisolated func runOnBackground(block: @escaping PTActionTask) -> Task<Void, Never> {
        Task.detached(priority: .background) {
            block()
        }
    }
    
    @discardableResult
    public nonisolated func runOnMain(block: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        PTMainActorBridge.perform(block)
    }
    
    // MARK: - 倒计时任务
    @discardableResult
    public nonisolated func countdown(timeInterval: TimeInterval,
                                      progressBlock: @escaping @MainActor @Sendable (_ isFinished: Bool, _ remainingTime: Int) -> Void) -> Task<Void, Never> {
        return Task {
            guard timeInterval.isFinite, timeInterval >= 0 else { return }
            var remaining = Int(timeInterval) + 1
            
            while remaining > 0 {
                if Task.isCancelled { break }
                
                remaining -= 1
                let currentRemaining = remaining
                
                await MainActor.run {
                    progressBlock(false, currentRemaining)
                }
                
                if currentRemaining > 0 {
                    do {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    } catch {
                        return
                    }
                }
            }
            
            if !Task.isCancelled {
                await MainActor.run {
                    progressBlock(true, 0)
                }
            }
        }
    }
}

public extension MainActor {
    @_unavailableFromAsync
    static func gcdRunUnsafely<T: Sendable>(_ body: @MainActor () throws -> T) rethrows -> T {
        return try MainActor.assumeIsolated(body)
    }
}
