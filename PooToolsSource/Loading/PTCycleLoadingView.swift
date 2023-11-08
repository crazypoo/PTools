//
//  PTCycleLoadingView.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/2.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTCycleLoadingView: UIView {

    public var lineWidth:CGFloat! = 1
    public var lineColor:UIColor! = .lightGray
    public var isAnimation:Bool! = false

    fileprivate var anglePer:CGFloat? = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    fileprivate var timer:Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func startAnimation() {
        if isAnimation {
            stopAnimation() {
                self.layer.removeAllAnimations()
            }
        }
        isAnimation = false
        
        anglePer = 0
        timer = Timer.scheduledTimer(timeInterval: 0.02, repeats: true, block: { timer in
            self.drawPathAnimation(timer: timer)
        })
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    public func stopAnimation(handle:PTActionTask? = nil) {
        isAnimation = false
        if timer != nil {
            if timer!.isValid {
                timer!.invalidate()
                timer = nil
            }
        }
        stopRotateAnimation(handle:handle)
    }
    
    func drawPathAnimation(timer:Timer) {
        anglePer! += 0.03
        if anglePer! >= 1 {
            anglePer = 1
            timer.invalidate()
            self.timer = nil
            startRotateAnimation()
        }
    }
    
    func startRotateAnimation() {
        let animation = CABasicAnimation.init(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = (2 * Double.pi)
        animation.duration = 1
        animation.repeatCount = Float(INT_MAX)
        layer.add(animation, forKey: "keyFrameAnimation")
    }
    
    func stopRotateAnimation(handle:PTActionTask?) {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { finish in
            self.anglePer = 0
            self.layer.removeAllAnimations()
            self.alpha = 1
            handle?()
        }
    }
    
    public override func draw(_ rect: CGRect) {
        if anglePer! <= 0 {
            anglePer! = 0
        }
        
        let context = UIGraphicsGetCurrentContext()
        context!.setLineWidth(lineWidth)
        context!.setStrokeColor(lineColor.cgColor)
        context!.addArc(center: CGPoint(x: bounds.midX, y: bounds.midY), radius: bounds.width / 2 - lineWidth, startAngle: angle(float: 120), endAngle: angle(float: 120) + angle(float: 330) * anglePer!, clockwise: false)
        context!.strokePath()
    }
    
    func angle(float:CGFloat)->CGFloat {
        2 * Double.pi / 360 * float
    }
}
