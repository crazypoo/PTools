//
//  PTFPSTool.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTFPSTool: NSObject {
    public static let shared = PTFPSTool.init()
    
    var fpsValue:NSInteger = 0
    open var fpsHandle:((_ fps:NSInteger)->Void)?
    open var closed:Bool = true
    
    private var displayLink : CADisplayLink?
    private var lastTime:TimeInterval? = 0
    private var count:NSInteger? = 0
    
    deinit {
        displayLink?.isPaused = true
        displayLink?.remove(from:  RunLoop.main, forMode: .common)
        displayLink?.invalidate()
    }
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func createUI() {
        if displayLink == nil {
            displayLink = CADisplayLink.init(target: self, selector: #selector(displayLinkTick(link:)))
            displayLink?.isPaused = false
            displayLink?.add(to: RunLoop.current, forMode: .common)
        }
        closed = false
    }
    
    func displayLinkTick(link:CADisplayLink) {
        if lastTime == 0 {
            lastTime = link.timestamp
            return
        }
        
        count! += 1
        let interval:Double = link.timestamp - lastTime!
        if interval < 1 {
            return
        }
        lastTime = link.timestamp
        let fps:Double = Double(count!) / interval
        count = 0
              
        fpsValue = NSInteger(fps)
        fpsHandle?(NSInteger(round(fps)))
    }
    
    ///开启
    public func open() {
        createUI()
        displayLink?.isPaused = false
    }
    
    ///关闭
    public func close() {
        displayLink?.isPaused = true
        closed = true
    }
    
    func applicationDidBecomeActiveNotification() {
        if displayLink != nil {
            displayLink!.isPaused = false
        }
    }
    
    func applicationWillResignActiveNotification() {
        if displayLink != nil {
            displayLink!.isPaused = true
        }
    }
}
