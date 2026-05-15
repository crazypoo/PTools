//
//  PTGCDManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias PTActionUncheckTask = () -> Void
public typealias PTActionTask = @Sendable () -> Void
public typealias PTActionAsyncTask = @Sendable () async -> Void

@objcMembers
public final class PTGCDManager: NSObject, @unchecked Sendable {
    
    public static let shared = PTGCDManager()
    
    // 使用 NSLock 保护多线程共享的可变状态，满足 Swift 6 并发安全要求
    private let lock = NSLock()
    
    // 定时器容器，统一在主线程操作以保证线程安全
    @MainActor lazy var timerContainer = NSCache<NSString, DispatchSourceTimer>()
    
    // 内部存储的取消标志
    private var _cancelFlag: Bool = false
    
    // 线程安全的计算属性
    public var cancelFlag: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _cancelFlag
        }
        set {
            lock.lock()
            _cancelFlag = newValue
            lock.unlock()
        }
    }
    
    private var dispatchSemaphore: DispatchSemaphore?
    private var dispatchGroup: DispatchGroup?
    private var cancelCompletionHandler: PTActionTask?
    
    // 私有化初始化方法，确保单例纯粹性
    private override init() {
        super.init()
    }
    
    // MARK: - GCD定时器 (统一在主线程调度)
    @MainActor public func scheduledDispatchTimer(WithTimerName name: String?,
                                                  timeInterval: Double,
                                                  queue: DispatchQueue = .main,
                                                  repeats: Bool,
                                                  action: @escaping PTActionTask) {
        
        guard let name = name else { return }
        
        var timer = timerContainer.object(forKey: name as NSString)
        if timer == nil {
            timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
            timer?.resume()
            timerContainer.setObject(timer!, forKey: name as NSString)
        }
        
        // 精度10毫秒，减少频繁调度
        timer?.schedule(deadline: .now(), repeating: timeInterval, leeway: .milliseconds(10))
        
        // 闭包中捕获的内容必须安全。此处调用 action 并检查是否重复
        timer?.setEventHandler(handler: { [weak self] in
            action()
            if !repeats {
                // 回到主线程移除定时器缓存
                Task { @MainActor in
                    self?.cancleTimer(WithTimerName: name)
                }
            }
        })
    }
    
    // MARK: 取消定时器
    @MainActor public func cancleTimer(WithTimerName name: String?) {
        guard let name = name, let timer = timerContainer.object(forKey: name as NSString) else { return }
        timer.cancel()
        timerContainer.removeObject(forKey: name as NSString)
    }
    
    // MARK: 检查定时器是否已存在
    @MainActor public func isExistTimer(WithTimerName name: String?) -> Bool {
        guard let findName = name, !findName.isEmpty else { return false }
        return timerContainer.object(forKey: findName as NSString) != nil
    }

    // MARK: - GCD线程组
    public class func gcdGroupUtility(label: String,
                                      semaphoreCount: Int = 3,
                                      threadCount: Int,
                                      doSomeThing: @escaping @Sendable (_ dispatchSemaphore: DispatchSemaphore, _ dispatchGroup: DispatchGroup, _ currentIndex: Int) -> Void,
                                      allRequestsFinished: @escaping PTActionTask,
                                      cancelCompletion: @escaping PTActionTask) {
        
        let dispatchGroup = DispatchGroup()
        let dispatchSemaphore = DispatchSemaphore(value: semaphoreCount)
        let concurrentQueue = DispatchQueue.global(qos: .utility)
        
        // 使用一个保护并发计数的类，或者依赖串行队列更新。这里使用简单的并发机制
        let lock = NSLock()
        var tasksCompleted = 0
        
        for i in 0..<threadCount {
            concurrentQueue.async(group: dispatchGroup) {
                dispatchSemaphore.wait()
                
                // 线程安全地读取 cancelFlag
                if PTGCDManager.shared.cancelFlag {
                    lock.lock()
                    tasksCompleted += 1
                    lock.unlock()
                    
                    dispatchGroup.leave()
                    dispatchSemaphore.signal()
                    return
                }
                
                dispatchGroup.enter()
                doSomeThing(dispatchSemaphore, dispatchGroup, i)
                
                lock.lock()
                tasksCompleted += 1
                lock.unlock()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            allRequestsFinished()
            if PTGCDManager.shared.cancelFlag && tasksCompleted == threadCount {
                cancelCompletion()
            }
        }
    }
    
    // MARK: - GCD延时执行
    public class func gcdAfter(time: TimeInterval, block: @escaping PTActionTask) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: block)
    }
    
    // MARK: 在后台执行任务
    public class func gcdBackground(block: @escaping PTActionTask) {
        // 修正：真正地在后台执行，而不是切到后台又强制包一层 @MainActor
        DispatchQueue.global(qos: .background).async {
            block()
        }
    }
    
    // MARK: 计时器倒计时基础方法
    public class func timeRun(timeInterval: TimeInterval,
                              finishBlock: @escaping @Sendable (_ finish: Bool, _ time: Int) -> Void) -> DispatchSourceTimer {
        // 使用局部可变状态封装，避免外部并发修改
        var newCount = Int(timeInterval) + 1
        let timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
        
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler {
            newCount -= 1
            finishBlock(newCount <= 0, newCount)
            if newCount <= 0 {
                timer.cancel()
            }
        }
        
        timer.resume()
        return timer
    }
    
    // MARK: - 任务组执行工具 (完全采用 Swift 结构化并发)
    public struct PTTaskGroupUtils {
        
        /// 执行一组 async 任务并收集结果与错误
        /// - 注意：Swift 6 要求泛型 T 必须符合 Sendable，以跨线程安全传递
        public static func performTaskGroup<T: Sendable>(concurrent: Bool = true,
                                                         tasks: [@Sendable () async throws -> T]) async -> (results: [T], errors: [Error]) {
            var results: [T] = []
            var errors: [Error] = []
            
            if concurrent {
                await withTaskGroup(of: Result<T, Error>.self) { group in
                    for task in tasks {
                        group.addTask {
                            do {
                                let result = try await task()
                                return .success(result)
                            } catch {
                                return .failure(error)
                            }
                        }
                    }
                    
                    for await result in group {
                        switch result {
                        case .success(let value):
                            results.append(value)
                        case .failure(let error):
                            errors.append(error)
                        }
                    }
                }
            } else {
                // 顺序执行
                for task in tasks {
                    do {
                        let result = try await task()
                        results.append(result)
                    } catch {
                        errors.append(error)
                    }
                }
            }
            
            return (results, errors)
        }
    }
    
    // MARK: - 快速队列调度
    // 在主线程执行异步任务
    @MainActor public class func runOnMainAsync(_ block: @escaping PTActionAsyncTask) {
        Task { @MainActor in
            await block()
        }
    }
    
    public class func gcdUncheckMain(block: @escaping PTActionTask) {
        Task { @MainActor in
            block()
        }
    }

    public class func gcdMain(block: @escaping PTActionTask) {
        Task { @MainActor in
            block()
        }
    }
    
    public class func gcdUncheckGobal(qosCls: DispatchQoS.QoSClass = .default,
                                      block: @escaping PTActionTask) {
        // 修正：既然是 Global 后台任务，使用 Task.detached 或直接派发，去掉 @MainActor
        Task.detached {
            block()
        }
    }
    
    public class func gcdGobal(qosCls: DispatchQoS.QoSClass = .default,
                               block: @escaping PTActionTask) {
        Task.detached {
            block()
        }
    }
    
    public class func gcdUncheckGobalNormal(block: @escaping PTActionTask) {
        Task.detached {
            block()
        }
    }
    
    public class func gcdGobalNormal(block: @escaping PTActionTask) {
        Task.detached {
            block()
        }
    }
    
    // MARK: - GCD倒计时
    public class func timeRunWithTime_base(timeInterval: TimeInterval,
                                           finishBlock: @escaping @Sendable (_ finish: Bool, _ time: Int) -> Void) {
        var newCount = Int(timeInterval) + 1
        let timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler {
            newCount -= 1
            finishBlock(false, newCount)
            if newCount < 1 {
                timer.cancel()
                finishBlock(true, 0)
            }
        }
        timer.resume()
    }
}
