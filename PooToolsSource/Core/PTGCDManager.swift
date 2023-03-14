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
    
    //MARK: GCD延時執行
    ///GCD延時執行
    public class func gcdAfter(time:TimeInterval,
                             block:@escaping (()->Void))
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: block)
    }
    
    //MARK: gcdMain是用於在背景執行非同步任務的，它可以在多個不同的系統線程上執行任務。
    ///gcdMain是用於在背景執行非同步任務的，它可以在多個不同的系統線程上執行任務。
    public class func gcdMain(block:@escaping (()->Void))
    {
        DispatchQueue.main.async(execute: block)
    }
    
    //MARK: gcdGobal是用於在主執行緒上執行非同步任務的，通常用於更新UI或進行其他與用戶交互有關的操作。
    ///gcdGobal是用於在主執行緒上執行非同步任務的，通常用於更新UI或進行其他與用戶交互有關的操作。
    public class func gcdGobal(block:@escaping (()->Void))
    {
        DispatchQueue.global(qos: .userInitiated).async(execute: block)
    }
    
    //MARK: gcdBackground
    //gcdBackground
    public class func gcdBackground(block:@escaping (()->Void))
    {
        DispatchQueue.global(qos: .background).async(execute: block)
    }
    
    //MARK: GCD倒計時基礎方法
    ///GCD倒計時基礎方法
    /// - Parameters:
    ///   - timeInterval: 時間
    ///   - finishBlock: 回調
    public class func timeRunWithTime_base(timeInterval:TimeInterval,
                                           finishBlock:@escaping ((_ finish:Bool,_ time:Int)->Void))
    {
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
