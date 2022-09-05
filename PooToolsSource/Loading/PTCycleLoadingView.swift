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

    fileprivate var anglePer:CGFloat? = 0
    {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    fileprivate var timer:Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func startAnimation()
    {
        if self.isAnimation
        {
            self.stopAnimation()
            self.layer.removeAllAnimations()
        }
        self.isAnimation = false
        
        self.anglePer = 0
        self.timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(self.drawPathAnimation(timer:)), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer!, forMode: .common)
    }
    
    public func stopAnimation()
    {
        self.isAnimation = false
        if self.timer != nil
        {
            if self.timer!.isValid
            {
                self.timer!.invalidate()
                self.timer = nil
            }
        }
        self.stopRotateAnimation()
    }
    
    func drawPathAnimation(timer:Timer)
    {
        self.anglePer! += 0.03
        if self.anglePer! >= 1
        {
            self.anglePer = 1
            timer.invalidate()
            self.timer = nil
            self.startRotateAnimation()
        }
    }
    
    func startRotateAnimation()
    {
        let animation = CABasicAnimation.init(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = (2 * Double.pi)
        animation.duration = 1
        animation.repeatCount = Float(INT_MAX)
        self.layer.add(animation, forKey: "keyFrameAnimation")
    }
    
    func stopRotateAnimation()
    {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { finish in
            self.anglePer = 0
            self.layer.removeAllAnimations()
            self.alpha = 1
        }
    }
    
    public override func draw(_ rect: CGRect) {
        if self.anglePer! <= 0
        {
            self.anglePer! = 0
        }
        
        let context = UIGraphicsGetCurrentContext()
        context!.setLineWidth(self.lineWidth)
        context!.setStrokeColor(self.lineColor.cgColor)
        context!.addArc(center: CGPoint(x: self.bounds.midX, y: self.bounds.midY), radius: self.bounds.width / 2 - self.lineWidth, startAngle: self.angle(float: 120), endAngle: self.angle(float: 120) + self.angle(float: 330) * self.anglePer!, clockwise: false)
        context!.strokePath()
    }
    
    func angle(float:CGFloat)->CGFloat
    {
        return 2 * Double.pi / 360 * float
    }
}
