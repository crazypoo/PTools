//
//  PTCheckAppStatus.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

/*
 FPS检测
 */
@objcMembers
public class PCheckAppStatus: NSObject {
    public static let shared = PCheckAppStatus.init()
    
    open var fpsHandle:((_ fps:NSInteger)->Void)?
    open var closed:Bool = true
    
    open var avatar : PFloatingButton?
    private var displayLink : CADisplayLink?
    private var lastTime:TimeInterval? = 0
    private var count:NSInteger? = 0
    private lazy var fpsLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = .black
        label.textAlignment = .center
        return label
    }()
    
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
        if avatar == nil {
            avatar = PFloatingButton.init(view: AppWindows as Any, frame: CGRect(x: 0, y: CGFloat.statusBarHeight(), width: 100, height: 30))
            avatar?.adjustsImageWhenHighlighted = false
            avatar?.tag = 9999
            
            displayLink = CADisplayLink.init(target: self, selector: #selector(displayLinkTick(link:)))
            displayLink?.isPaused = false
            displayLink?.add(to: RunLoop.current, forMode: .common)
            
            avatar?.addSubview(fpsLabel)
            fpsLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
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
        
        let text = String.init(format: "FPS:%02.0f", round(fps))
        fpsLabel.text = text
        avatar!.frame = CGRect(x: avatar!.frame.origin.x, y: avatar!.frame.origin.y, width: fpsLabel.sizeFor(height: 30).width + 20, height: avatar!.frame.size.height)
        
        if fpsHandle != nil {
            fpsHandle!(NSInteger(round(fps)))
        }
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
        avatar?.removeFromSuperview()
        avatar = nil
    }
    
    func applicationDidBecomeActiveNotification() {
        if avatar != nil {
            displayLink!.isPaused = false
        }
    }
    
    func applicationWillResignActiveNotification() {
        if avatar != nil {
            displayLink!.isPaused = true
        }
    }
}
