//
//  Notification.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension Notification.Name {
    
    /// Posted immediately prior to the display of the keyboard.
    ///
    /// The notification `keyboardAnimationInfo` contains information about the keyboard's location, size, and animations.
    static let keyboardWillShow: Notification.Name = UIResponder.keyboardWillShowNotification
    
    /// Posted immediately after the display of the keyboard.
    ///
    /// The notification `keyboardAnimationInfo` contains information about the keyboard's location, size, and animations.
    static let keyboardDidShow: Notification.Name = UIResponder.keyboardDidShowNotification
    
    /// Posted immediately prior to the dismissal of the keyboard.
    ///
    /// The notification `keyboardAnimationInfo` contains information about the keyboard's location, size, and animations.
    static let keyboardWillHide: Notification.Name = UIResponder.keyboardWillHideNotification
    
    /// Posted immediately after the dismissal of the keyboard.
    ///
    /// The notification `keyboardAnimationInfo` contains information about the keyboard's location, size, and animations.
    static let keyboardDidHide: Notification.Name = UIResponder.keyboardDidHideNotification
    
    /// Posted immediately prior to a change in the keyboard’s frame.
    ///
    /// The notification `keyboardAnimationInfo` contains information about the keyboard's location, size, and animations.
    static let keyboardWillChangeFrame: Notification.Name = UIResponder.keyboardWillChangeFrameNotification
    
    /// Posted immediately after a change in the keyboard’s frame.
    ///
    /// The notification `keyboardAnimationInfo` contains information about the keyboard's location, size, and animations.
    static let keyboardDidChangeFrame: Notification.Name = UIResponder.keyboardDidChangeFrameNotification
    
}
