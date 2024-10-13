//
//  AnyHashable+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension AnyHashable {
    
    /// The key for an `NSNumber` object containing a double that identifies the duration of the animation in seconds.
    static var durationKey: AnyHashable { UIResponder.keyboardAnimationDurationUserInfoKey }
    
    /// The key for an `NSValue` object containing a `CGRect` that identifies the ending frame rectangle of the keyboard in screen coordinates. The frame rectangle reflects the current orientation of the device.
    static var frameKey: AnyHashable { UIResponder.keyboardFrameEndUserInfoKey }
    
    /// The key for an `NSNumber` object containing a UIView.AnimationCurve constant that defines how the keyboard will be animated onto or off the screen.
    static var curveKey: AnyHashable { UIResponder.keyboardAnimationCurveUserInfoKey }
    
    /// The key for an `NSNumber` object containing a Boolean that identifies whether the keyboard belongs to the current app. With multitasking on iPad, all visible apps are notified when the keyboard appears and disappears. The value of this key is true for the app that caused the keyboard to appear and false for any other apps.
    static var keyboardIsLocalKey: AnyHashable { UIResponder.keyboardIsLocalUserInfoKey }
    
}
