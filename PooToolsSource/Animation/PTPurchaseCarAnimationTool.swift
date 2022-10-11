//
//  PTPurchaseCarAnimationTool.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public typealias AnimationFinishBlock = (_ finish:Bool) -> Void

public class PTPurchaseCarAnimationTool: NSObject {
    public static let shared = PTPurchaseCarAnimationTool.init()
    public var block:AnimationFinishBlock?
    public var layer:CALayer?
    
    public func startAnimationand(view:UIView,rect:CGRect,finishPoint:CGPoint,handle: AnimationFinishBlock?)
    {
        var newRect = rect
        layer = CALayer()
        layer?.contents = view.layer.contents
        layer?.contentsGravity = .resizeAspectFill
        newRect.size.width = 60
        newRect.size.height = 60
        layer?.bounds = newRect
        layer?.cornerRadius = newRect.size.width/2
        layer?.masksToBounds = true
        
        let keyWindow = AppWindows!
        keyWindow.layer.addSublayer(layer!)
        layer?.position = CGPoint.init(x: newRect.origin.x + view.frame.size.width / 2, y: newRect.midY)
        self.createAnimation(rect: newRect, finishPoint: finishPoint)
        block = handle
    }
    
    public class func shakeAnimation(view:UIView)
    {
        let animation = CABasicAnimation.init(keyPath: "transform.translation.y")
        animation.duration = 0.25
        animation.fromValue = -5
        animation.toValue = 5
        animation.autoreverses = true
        view.layer.add(animation, forKey: nil)
    }
    
    public func createAnimation(rect:CGRect,finishPoint:CGPoint)
    {
        let path = UIBezierPath()
        path.move(to: layer!.position)
        path.addQuadCurve(to: finishPoint, controlPoint: CGPoint.init(x: kSCREEN_WIDTH/2, y: rect.origin.y - 80))
        let pathAnimation = CAKeyframeAnimation.init(keyPath: "position")
        pathAnimation.path = path.cgPath
        
        let rotateAnimation = CABasicAnimation.init(keyPath: "transform.rotation")
        rotateAnimation.isRemovedOnCompletion = true
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = 12
        rotateAnimation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeIn)
        
        let groups = CAAnimationGroup()
        groups.animations = [pathAnimation,rotateAnimation]
        groups.duration = 1.2
        groups.isRemovedOnCompletion = false
        groups.fillMode = .forwards
        groups.delegate = self
        layer?.add(groups, forKey: "group")
    }
}

extension PTPurchaseCarAnimationTool:CAAnimationDelegate
{
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim == layer?.animation(forKey: "group")
        {
            layer!.removeFromSuperlayer()
            layer = nil
            
            if block != nil
            {
                block!(true)
            }
        }
    }
}
