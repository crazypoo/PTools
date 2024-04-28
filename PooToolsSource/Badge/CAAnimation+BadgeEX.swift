//
//  CAAnimation+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public enum PTAxisType:Int {
    case AxisX
    case AxisY
    case AxisZ
}

extension CAAnimation {
    public class func opacityForeverAnimation(time:CFTimeInterval) ->CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.1
        animation.autoreverses = true
        animation.duration = time
        animation.repeatCount = Float.greatestFiniteMagnitude
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.fillMode = .forwards
        return animation
    }
    
    public class func opacityTimesAnimation(repeatTimes:Float,time:CFTimeInterval) ->CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.4
        animation.repeatCount = repeatTimes
        animation.duration = time
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.fillMode = .forwards
        animation.autoreverses = true
        return animation
    }
    
    public class func rotation(duration:CFTimeInterval,degree:Float,direction:PTAxisType,repeatCount:Float) ->CABasicAnimation {
        let axisArr = ["transform.rotation.x","transform.rotation.y","transform.rotation.z"]
        let animation = CABasicAnimation(keyPath: axisArr[direction.rawValue])
        animation.fromValue = 0
        animation.toValue = degree
        animation.duration = duration
        animation.autoreverses = false
        animation.isCumulative = true
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.repeatCount = repeatCount
        return animation
    }
    
    public class func scale(fromScale:Float,toScale:Float,duration:CFTimeInterval,repeatCount:Float) ->CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = fromScale
        animation.toValue = toScale
        animation.duration = duration
        animation.autoreverses = true
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.repeatCount = repeatCount
        return animation
    }
    
    public class func shakeAnimation(repeatTimes:Float,duration:CFTimeInterval,forObj:CALayer) -> CAKeyframeAnimation {
        let originPos:CGPoint = forObj.position
        let originSize:CGSize = forObj.bounds.size
        let hOffset = originSize.width / 4
        let anim = CAKeyframeAnimation(keyPath: "position")
        anim.values = [NSValue(cgPoint: originPos),NSValue(cgPoint: CGPoint(x: originPos.x - hOffset, y: originPos.y)),NSValue(cgPoint: originPos),NSValue(cgPoint: CGPoint(x: originPos.x + hOffset, y: originPos.y)),NSValue(cgPoint: originPos)]
        anim.repeatCount = repeatTimes
        anim.duration = duration
        anim.fillMode = .forwards
        return anim
    }
    
    public class func bounceAnimation(repeatTimes:Float,duration:CFTimeInterval,forObj:CALayer) -> CAKeyframeAnimation {
        let originPos:CGPoint = forObj.position
        let originSize:CGSize = forObj.bounds.size
        let hOffset = originSize.height / 4
        let anim = CAKeyframeAnimation(keyPath: "position")
        anim.values = [NSValue(cgPoint: originPos),NSValue(cgPoint: CGPoint(x: originPos.x, y: originPos.y - hOffset)),NSValue(cgPoint: originPos),NSValue(cgPoint: CGPoint(x: originPos.x, y: originPos.y + hOffset)),NSValue(cgPoint: originPos)]
        anim.repeatCount = repeatTimes
        anim.duration = duration
        anim.fillMode = .forwards
        return anim
    }
}
