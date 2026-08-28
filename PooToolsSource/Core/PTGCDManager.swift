//
//  PTGCDManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import os.lock

// 闭包类型定义：添加 @Sendable 以满足跨边界传递的安全要求
public typealias PTActionTask = @Sendable () -> Void
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

// 使用 actor 来保证内部状态的绝对线程安全，完美契合 Swift 6
public actor PTGCDManager {
    
    public static let shared = PTGCDManager()
    
    // 用于保存定时器的 Task 引用，替代原有的 NSCache 和 DispatchSourceTimer
    private var activeTimers: [String: Task<Void, Never>] = [:]
    
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

        guard timeInterval.isFinite, timeInterval >= 0 else { return }
        
        let task = Task {
            let nanoseconds = UInt64(timeInterval * 1_000_000_000)
            
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
                removeTimerRef(name: name)
            }
        }
        
        activeTimers[name] = task
    }
    
    public func cancelTimer(withName name: String) {
        activeTimers[name]?.cancel()
        activeTimers.removeValue(forKey: name)
    }
    
    public func isExistTimer(withName name: String) -> Bool {
        return activeTimers[name] != nil
    }
    
    // 仅供内部清理使用
    private func removeTimerRef(name: String) {
        activeTimers.removeValue(forKey: name)
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
                    // 技能培训：withCheckedContinuation 是连接旧时代回调和新时代 async 的桥梁
                    // 它会挂起当前 Task，直到 continuation.resume() 被调用
                    await withCheckedContinuation { continuation in
                        let finishGate = PTGCDOnce()
                        
                        // 派发任务给外部，并提供一个 finishTask 闭包给外部调用
                        doSomeThing(i) {
                            // 当外部调用 finishTask() 时，我们恢复协程，系统此时才知道任务真正完成
                            finishGate.run {
                                continuation.resume()
                            }
                        }
                    }
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
        PTMainActorBridge.cancellableAfter(time, operation: block)
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
        PTGCDManager.shared.runOnBackground(priority: .background, block: block)
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

extension MainActor {
    @_unavailableFromAsync
    static func gcdRunUnsafely<T: Sendable>(_ body: @MainActor () throws -> T) rethrows -> T {
        return try MainActor.assumeIsolated(body)
    }
}
