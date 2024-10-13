//
//  KeyboardNotificationName.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

/// An alias for a type used to represent the name of a keyboard related notification.
public enum KeyboardNotificationName {
    
    /// Posted immediately prior to the display of the keyboard.
    case willShow
    
    /// Posted immediately after the display of the keyboard.
    case didShow
    
    /// Posted immediately prior to the dismissal of the keyboard.
    case willHide
    
    /// Posted immediately after the dismissal of the keyboard.
    case didHide
    
    /// Posted immediately prior to a change in the keyboard’s frame.
    case willChangeFrame
    
    /// Posted immediately after a change in the keyboard’s frame.
    case didChangeFrame
}

extension KeyboardNotificationName: RawRepresentable {
    public typealias RawValue = Notification.Name
    
    public init?(rawValue: Notification.Name) {
        switch rawValue {
        case .keyboardWillShow:
            self = .willShow
        
        case .keyboardDidShow:
            self = .didShow
        
        case .keyboardWillHide:
            self = .willHide
        
        case .keyboardDidHide:
            self = .didHide
            
        case .keyboardWillChangeFrame:
            self = .willChangeFrame
        
        case .keyboardDidChangeFrame:
            self = .didChangeFrame
            
        default:
            return nil
        }
    }
    
    public var rawValue: Notification.Name {
        switch self {
        
        case .willShow:
            return .keyboardWillShow
        
        case .didShow:
            return .keyboardDidShow
        
        case .willHide:
            return .keyboardWillHide
        
        case .didHide:
            return .keyboardDidHide
            
        case .willChangeFrame:
            return .keyboardWillChangeFrame
        
        case .didChangeFrame:
            return .keyboardDidChangeFrame
        }
    }
}
