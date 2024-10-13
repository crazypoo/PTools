//
//  KeyboardAnimatable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public typealias KeyboardAnimationInfo = (duration: TimeInterval, keyboardFrame: CGRect, curve: UIView.AnimationCurve)

@objc public protocol KeyboardAnimatable {
    
    typealias Animations = ((KeyboardAnimationInfo) -> Void)
    
    typealias Completion = ((UIViewAnimatingPosition) -> Void)
}

// MARK: - KeyboardAnimationStorable Extension

public extension KeyboardAnimatable {
    
    private var notificationCenter: NotificationCenter { NotificationCenter.default }
    
    func animateWhenKeyboard(_ notificationName: KeyboardNotificationName,
                             animations: @escaping Animations,
                             completion: Completion? = nil) {
        
        notificationCenter.addObserver(
            forName: notificationName.rawValue,
            object: .none,
            queue: .main
        ) { notification in
            let keyboardAnimation = KeyboardAnimation(
                animation: animations,
                completion: completion
            )
            
            UIView.animate(
                withKeyboardNotification: notification,
                animations: keyboardAnimation.animation,
                completion: keyboardAnimation.completion
            )
        }
    }
    
    func stopAnimatingWhenKeyboard(_ notificationNames: KeyboardNotificationName...) {
        notificationNames.forEach { notificationName in
            notificationCenter.removeObserver(self, name: notificationName.rawValue, object: nil)
        }
    }
}
