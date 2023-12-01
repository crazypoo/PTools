//
//  PTCameraAnimationUtils.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

class PTCameraAnimationUtils: NSObject {
    enum AnimationType: String {
        case fade = "opacity"
        case scale = "transform.scale"
        case rotate = "transform.rotation"
    }
    
    class func animation(
        type: PTCameraAnimationUtils.AnimationType,
        fromValue: CGFloat,
        toValue: CGFloat,
        duration: TimeInterval
    ) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: type.rawValue)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }
    
    class func springAnimation() -> CAKeyframeAnimation {
        let animate = CAKeyframeAnimation(keyPath: "transform")
        animate.duration = PTCameraFilterConfig.share.selectBtnAnimationDuration
        animate.isRemovedOnCompletion = true
        animate.fillMode = .forwards
        
        animate.values = [
            CATransform3DMakeScale(0.7, 0.7, 1),
            CATransform3DMakeScale(1.15, 1.15, 1),
            CATransform3DMakeScale(0.9, 0.9, 1),
            CATransform3DMakeScale(1, 1, 1)
        ]
        return animate
    }
}
