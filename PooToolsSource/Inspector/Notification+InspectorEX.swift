//
//  Notification+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension Notification {
    
    /// This property contains information about the keyboard animation, if applicable.
    var keyboardAnimationInfo: KeyboardAnimationInfo? {
        guard
            userInfo?[.keyboardIsLocalKey] as? Bool == true,
            let duration = userInfo?[.durationKey] as? Double,
            let keyboardFrame = userInfo?[.frameKey] as? CGRect,
            let curveValue = userInfo?[.curveKey] as? Int,
            let curve = UIView.AnimationCurve(rawValue: curveValue)
        else {
            return nil
        }
        
        return KeyboardAnimationInfo(
            duration: duration,
            keyboardFrame: keyboardFrame,
            curve: curve
        )
    }
    
}
