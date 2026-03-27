//
//  PTGCDManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTGCDManager: NSObject {
    
    public static let shared = PTGCDManager()
    
    lazy var timerContainer = NSCache<NSString, DispatchSourceTimer>()
    
    // 用于控制任务是否应该继续执行的标志
    private var cancelFlag: Bool = false
    private var dispatchSemaphore: DispatchSemaphore?
    private var dispatchGroup: DispatchGroup?
    
    // 任务取消完成后的回调
    private var cancelCompletionHandler: PTActionTask?
    
    //MARK: GCD定时器
    @MainActor public func scheduledDispatchTimer(WithTimerName name: String?,
                                                  timeInterval: Double,
                                                  queue: DispatchQueue,
                                                  repeats: Bool,
                                                  action: @escaping @Sendable PTActionTask) {
        
        guard let name = name else { return }
        
        var timer = timerContainer.object(forKey: name as NSString)
        if timer == nil {
            timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
            timer?.resume()
            timerContainer.setObject(timer!, forKey: name as NSString)
        }
        
        // 精度10毫秒，减少频繁调度
        timer?.schedule(deadline: .now(), repeating: timeInterval, leeway: DispatchTimeInterval.milliseconds(10))
        timer?.setEventHandler(handler: { [weak self] in
            action()
            if !repeats {
                self?.cancleTimer(WithTimerName: name)
            }
        })
    }
    
    //MARK: 取消定时器
    public func cancleTimer(WithTimerName name: String?) {
        guard let name = name, let timer = timerContainer.object(forKey: name as NSString) else { return }
        timer.cancel()
        timerContainer.removeObject(forKey: name as NSString)
    }
    
    //MARK: 检查定时器是否已存在
    public func isExistTimer(WithTimerName name: String?) -> Bool {
        if let findName = name,!findName.stringIsEmpty() {
            return timerContainer.object(forKey: findName.nsString) != nil
        } else {
            return false
        }
    }

    //MARK: GCD线程组
    @MainActor public class func gcdGroupUtility(label: String,
                                                 semaphoreCount: Int = 3,
                                                 threadCount: Int,
                                                 doSomeThing: @escaping @Sendable (_ dispatchSemaphore: DispatchSemaphore, _ dispatchGroup: DispatchGroup, _ currentIndex: Int) -> Void,
                                                 allRequestsFinished: @escaping PTActionTask,
                                                 cancelCompletion: @escaping PTActionTask) {
        
        let dispatchGroup = DispatchGroup()
        let dispatchSemaphore = DispatchSemaphore(value: semaphoreCount)
        let concurrentQueue = DispatchQueue.global(qos: .utility)
        
        var tasksCompleted = 0
        
        for i in 0..<threadCount {
            concurrentQueue.async(group: dispatchGroup) {
                dispatchSemaphore.wait()
                
                // 如果标志是取消状态，则直接退出
                if self.shared.cancelFlag {
                    dispatchGroup.leave()
                    tasksCompleted += 1
                    return
                }
                
                dispatchGroup.enter()
                doSomeThing(dispatchSemaphore, dispatchGroup, i)
                tasksCompleted += 1
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            allRequestsFinished()
            if self.shared.cancelFlag && tasksCompleted == threadCount {
                cancelCompletion()
            }
        }
    }
    
    //MARK: GCD延时执行
    public class func gcdAfter(time: TimeInterval, block: @escaping PTActionTask) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: block)
    }
    
    //MARK: 在后台执行任务
    public class func gcdBackground(block: @escaping PTActionTask) {
        DispatchQueue.global(qos: .background).async {
            Task { @MainActor in
                block()
            }
        }
    }
    
    //MARK: 计时器倒计时基础方法
    public class func timeRun(timeInterval: TimeInterval,
                               finishBlock: @escaping @Sendable (_ finish: Bool, _ time: Int) -> Void) -> DispatchSourceTimer {
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
    
    //MARK: 任务组执行工具
    public struct PTTaskGroupUtils {
        
        /// 执行一组 async 任务并收集结果与错误
        ///
        /// - Parameters:
        ///   - concurrent: 是否并行执行
        ///   - tasks: 非同步任务数组（使用 closure 传入）
        /// - Returns: 所有成功结果与错误集合
        public static func performTaskGroup<T>(concurrent: Bool = true,
                                               tasks: [() async throws -> T]) async -> (results: [T], errors: [Error]) {
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
    
    //MARK: 在主线程执行异步任务
    @MainActor public class func runOnMainAsync(_ block: @escaping PTActionAsyncTask) {
#if swift(>=6.0)
        Task { @MainActor in
            await block()
        }
#else
        DispatchQueue.main.async {
            Task {
                await block()
            }
        }
#endif
    }
    
    public class func gcdMain(block: @escaping PTActionTask) {
#if swift(>=6.0)
        Task { @MainActor in
            block()
        }
#else
        DispatchQueue.main.async(execute: block)
#endif
    }
    
    public class func gcdGobal(qosCls: DispatchQoS.QoSClass = .default,
                               block: @escaping PTActionTask) {
        DispatchQueue.global(qos: qosCls).async {
            Task { @MainActor in
                block()
            }
        }
    }
    
    public class func gcdGobalNormal(block: @escaping PTActionTask) {
        DispatchQueue.global().async {
            Task { @MainActor in
                block()
            }
        }
    }
    
    //MARK: GCD倒计时
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
