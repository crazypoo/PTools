//
//  PTAnimationFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import pop

public let PTAnimationDuration = 0.35

public class PTAnimationFunction: NSObject {
    public class func animationIn(animationView:UIView,
                                  animationType:PTAlertAnimationType,
                                  transformValue:CGFloat) {
        var propertyNamed = ""
        var transform = CATransform3DMakeTranslation(0, 0, 0)
        
        switch animationType {
        case .Top:
            propertyNamed = kPOPLayerTranslationY
            transform = CATransform3DMakeTranslation(0, -abs(transformValue), 0)
        case .Bottom:
            propertyNamed = kPOPLayerTranslationY
            transform = CATransform3DMakeTranslation(0, transformValue, 0)
        case .Left:
            propertyNamed = kPOPLayerTranslationX
            transform = CATransform3DMakeTranslation(-abs(transformValue), 0, 0)
        case .Right:
            propertyNamed = kPOPLayerTranslationX
            transform = CATransform3DMakeTranslation(transformValue, 0, 0)
        default:
            propertyNamed = kPOPLayerTranslationX
            transform = CATransform3DMakeTranslation(0, 0, 0)
        }
        
        let animation = POPSpringAnimation.init(propertyNamed: propertyNamed)
        animationView.layer.transform = transform
        animation?.toValue = 0
        animation?.springBounciness = 1
        animationView.layer.pop_add(animation, forKey: "AlertAnimation")
    }
    
    public class func animationOut(animationView:UIView,
                                   animationType:PTAlertAnimationType,
                                   toValue:CGFloat? = 0,
                                   duration:CGFloat? = PTAnimationDuration,
                                   animation:@escaping PTActionTask,
                                   completion: @escaping (Bool)->Void) {
        var propertyNamed = ""
        var offsetValue : CGFloat = 0
        
        switch animationType {
        case .Top:
            propertyNamed = kPOPLayerTranslationY
            if toValue! > 0 {
                offsetValue = toValue!
            } else {
                offsetValue = -animationView.layer.position.y
            }
        case .Bottom:
            propertyNamed = kPOPLayerTranslationY
            if toValue! > 0 {
                offsetValue = toValue!
            } else {
                offsetValue = animationView.layer.position.y + animationView.frame.size.height
            }
        case .Left:
            propertyNamed = kPOPLayerTranslationX
            if toValue! > 0 {
                offsetValue = toValue!
            } else {
                offsetValue = -animationView.layer.position.x - animationView.frame.size.width / 2
            }
        case .Right:
            propertyNamed = kPOPLayerTranslationX
            if toValue! > 0 {
                offsetValue = toValue!
            } else {
                offsetValue = animationView.layer.position.x + animationView.frame.size.width / 2
            }
        default:
            propertyNamed = kPOPLayerTranslationX
            offsetValue = -animationView.layer.position.x
        }
        
        let offscreenAnimation = POPBasicAnimation.easeOut()
        offscreenAnimation?.property = (POPAnimatableProperty.property(withName: propertyNamed) as! POPAnimatableProperty)
        offscreenAnimation?.toValue = offsetValue
        offscreenAnimation?.duration = duration!
        offscreenAnimation?.completionBlock = { (anim,finish) in
            UIView.animate(withDuration: duration!, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.7, options: [.curveEaseOut,.beginFromCurrentState,.layoutSubviews]) {
                animation()
            } completion: { ok in
                completion(ok)
            }
        }
        animationView.layer.pop_add(offscreenAnimation, forKey: "offscreenAnimation")

    }
}
