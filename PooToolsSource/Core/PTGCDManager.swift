//
//  PTGCDManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTGCDManager :NSObject {
    
    public static let shared = PTGCDManager()
    
    lazy var timerContainer = [String: DispatchSourceTimer]()
    
    //MARK: GCD定时器
    /// GCD定时器
    /// - Parameters:
    ///   - name: 定时器名字
    ///   - timeInterval: 时间间隔
    ///   - queue: 队列
    ///   - repeats: 是否重复
    ///   - action: 执行任务的闭包
    public func scheduledDispatchTimer(WithTimerName name: String?,
                                timeInterval: Double,
                                queue: DispatchQueue,
                                repeats: Bool,
                                action: @escaping PTActionTask) {
        
        if name == nil {
            return
        }
        
        var timer = timerContainer[name!]
        if timer == nil {
            timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
            timer?.resume()
            timerContainer[name!] = timer
        }
        //精度1毫秒
        timer?.schedule(deadline: .now(), repeating: timeInterval, leeway: DispatchTimeInterval.milliseconds(1))
        timer?.setEventHandler(handler: { [weak self] in
            action()
            if repeats == false {
                self?.cancleTimer(WithTimerName: name)
            }
        })
    }
    
    //MARK: 取消定时器
    /// 取消定时器
    /// - Parameter name: 定时器名字
    public func cancleTimer(WithTimerName name: String?) {
        let timer = timerContainer[name!]
        if timer == nil {
            return
        }
        timerContainer.removeValue(forKey: name!)
        timer?.cancel()
    }
    
    //MARK: 检查定时器是否已存在
    /// 检查定时器是否已存在
    /// - Parameter name: 定时器名字
    /// - Returns: 是否已经存在定时器
    public func isExistTimer(WithTimerName name: String?) -> Bool {
        if timerContainer[name!] != nil {
            return true
        }
        return false
    }

    /*
     在Swift中，DispatchSemaphore是一种用于管理并发代码的同步机制。它允许您限制可以同时执行的线程或操作的数量。

     在创建DispatchSemaphore对象时，您需要传入一个整数值，表示可以同时访问临界区的线程或操作的数量。这个整数值通常被称为“计数器”或“信号量值”。

     例如，如果您创建了一个DispatchSemaphore对象，并将初始值设置为0，那么在没有调用signal()方法的情况下，任何对wait()方法的调用都将被阻塞，因为初始值为0表示临界区内不允许同时执行的线程或操作的数量为0。

     当您在某个线程中调用signal()方法时，DispatchSemaphore对象的计数器将增加1。如果此时有任何被阻塞的wait()方法调用，则其中一个将被允许继续执行，因为此时临界区内的线程或操作的数量不再为0。

     因此，value参数表示DispatchSemaphore对象的初始计数器值。如果将其设置为0，则表示在初始状态下，不允许同时执行任何线程或操作。
     */
    //MARK: GCD線程組
    ///GCD線程組
    /// - Parameters:
    ///   - label: 隊列名稱
    ///   - semaphoreCount: 量值(默認0)
    ///   - threadCount: 執行任務的數量
    ///   - doSomeThing: 須要執行的任務(如果該任務執行完畢,須要調用dispatchSemaphore的.signal()方法,和dispatchGroup的.leave()方法,來處理後續事情)
    ///   - jobDoneBlock: 任務完成
    public class func gcdGroup(label:String,
                               semaphoreCount:Int? = nil,
                               threadCount:Int,
                               doSomeThing: @escaping (_ dispatchSemaphore:DispatchSemaphore, _ dispatchGroup:DispatchGroup, _ currentIndex:Int)->Void,
                               jobDoneBlock: @escaping PTActionTask) {
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: label)
        let dispatchSemaphore = DispatchSemaphore(value: semaphoreCount ?? 0)
        dispatchQueue.async {
            for i in 0..<threadCount {
                dispatchGroup.enter()
                doSomeThing(dispatchSemaphore,dispatchGroup,i)
                dispatchSemaphore.wait()
            }
        }
        dispatchGroup.notify(queue: dispatchQueue) {
            jobDoneBlock()
        }
    }
    
    //MARK: GCD延時執行
    ///GCD延時執行
    public class func gcdAfter(qosCls:DispatchQoS.QoSClass,
                               time:TimeInterval,
                               block: @escaping PTActionTask) {
        DispatchQueue.global(qos: qosCls).asyncAfter(deadline: .now() + time, execute: block)
    }
    
    public class func gcdAfter(time:TimeInterval,
                             block: @escaping PTActionTask) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: block)
    }
    
    //MARK: gcdMain是用於在背景執行非同步任務的，它可以在多個不同的系統線程上執行任務。
    ///gcdMain是用於在背景執行非同步任務的，它可以在多個不同的系統線程上執行任務。
    public class func gcdMain(block: @escaping PTActionTask) {
        DispatchQueue.main.async(execute: block)
    }
    
    public class func gcdGobal(qosCls:DispatchQoS.QoSClass,
                               block: @escaping PTActionTask) {
        DispatchQueue.global(qos: qosCls).async(execute: block)
    }
    
    //MARK: gcdGobal是用於在主執行緒上執行非同步任務的，通常用於更新UI或進行其他與用戶交互有關的操作。
    ///gcdGobal是用於在主執行緒上執行非同步任務的，通常用於更新UI或進行其他與用戶交互有關的操作。
    public class func gcdGobal(block: @escaping PTActionTask) {
        DispatchQueue.global(qos: .userInitiated).async(execute: block)
    }
    
    public class func gcdGobalNormal(block: @escaping PTActionTask) {
        DispatchQueue.global().async(execute: block)
    }
    //MARK: gcdBackground
    //gcdBackground
    public class func gcdBackground(block: @escaping PTActionTask) {
        DispatchQueue.global(qos: .background).async(execute: block)
    }
    
    //MARK: GCD倒計時基礎方法
    ///GCD倒計時基礎方法
    /// - Parameters:
    ///   - timeInterval: 時間
    ///   - finishBlock: 回調
    public class func timeRunWithTime_base(timeInterval:TimeInterval,
                                           finishBlock: @escaping (_ finish:Bool, _ time:Int)->Void) {
        let semaphore = DispatchSemaphore(value: 1)
        var newCount = Int(timeInterval) + 1
        let timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler {
            semaphore.wait()
            PTGCDManager.gcdMain {
                newCount -= 1
                finishBlock(false,newCount)
                semaphore.signal()
                if newCount < 1 {
                    PTGCDManager.gcdMain {
                        finishBlock(true,0)
                    }
                    timer.cancel()
                    semaphore.signal()
                }
            }
        }
        timer.resume()
    }
}
