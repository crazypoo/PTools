//
//  PTListAnimationConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public class PTListAnimationConfig {
    /// Amount of movement in points.
    /// Depends on the Direction given to the PTListAnimationType.
    public static var offset: CGFloat = 30.0
    /// Duration of the animation.
    public static var duration: Double = 0.3
    /// Interval for animations handling multiple views that need
    /// to be animated one after the other and not at the same time.
    public static var interval: Double = 0.075
    /// Maximum zoom to be applied in animations using random PTListAnimationType.zoom.
    public static var maxZoomScale: Double = 2.0
    /// Maximum rotation (left or right) to be applied in animations using random PTListAnimationType.rotate
    public static var maxRotationAngle: CGFloat = CGFloat.pi/4
    /// The damping ratio for the spring animation as it approaches its quiescent state.
    public static var springDampingRatio: CGFloat = 1
    /// The initial spring velocity. For smooth start to the animation, match this value to the view’s velocity as it was prior to attachment.
    public static var initialSpringVelocity: CGFloat = 0
}
