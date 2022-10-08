//
//  PTCheckAppStatus.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

@objcMembers
public class PCheckAppStatus: NSObject {
    public static let shared = PCheckAppStatus.init()

    public var fpsHandle:((_ fps:NSInteger)->Void)?
    public var closed:Bool = true
    
    public var avatar : PFloatingButton?
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
    
    public override init()
    {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func createUI()
    {
        if avatar == nil
        {
            avatar = PFloatingButton.init(view: AppWindows as Any, frame: .zero)
            avatar?.adjustsImageWhenHighlighted = false
            avatar?.tag = 9999
            avatar!.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.width.equalTo(50)
                make.height.equalTo(30)
                make.top.equalToSuperview().inset(kStatusBarHeight)
            }

            displayLink = CADisplayLink.init(target: self, selector: #selector(self.displayLinkTick(link:)))
            displayLink?.isPaused = false
            displayLink?.add(to: RunLoop.current, forMode: .common)
            
            avatar?.addSubview(fpsLabel)
            fpsLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        closed = false
    }
    
    @objc func displayLinkTick(link:CADisplayLink)
    {
        if lastTime == 0
        {
            lastTime = link.timestamp
            return
        }
                
        count! += 1
        let interval:Double = link.timestamp - lastTime!
        if interval < 1
        {
            return
        }
        lastTime = link.timestamp
        let fps:Double = Double(count!) / interval
        count = 0
        
        let text = String.init(format: "FPS:%02.0f", round(fps))
        fpsLabel.text = text
        avatar?.snp.updateConstraints { make in
            make.width.equalTo(PTUtils.sizeFor(string: text, font: fpsLabel.font, height: 30, width: CGFloat(MAXFLOAT)).width + 20)
        }
        
        if fpsHandle != nil
        {
            fpsHandle!(NSInteger(round(fps)))
        }
    }
    
    public func open()
    {
        createUI()
        displayLink?.isPaused = false
    }
    
    public func close()
    {
        displayLink?.isPaused = true
        closed = true
        avatar?.removeFromSuperview()
        avatar = nil
    }
    
    @objc func applicationDidBecomeActiveNotification()
    {
        if avatar != nil
        {
            displayLink!.isPaused = false
        }
    }

    @objc func applicationWillResignActiveNotification()
    {
        if avatar != nil
        {
            displayLink!.isPaused = true
        }
    }
}
