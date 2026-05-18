//
//  KeyboardAnimation.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

/// Contains information about the keyboard animation.
@MainActor
public struct KeyboardAnimation {
        
    let animation: KeyboardAnimations
        
    let completion: KeyboardCompletion?
    
    // 3. （可选）显式提供初始化方法，确保在严格并发模式下跨模块调用的可见性
    public init(animation: @escaping KeyboardAnimations, completion: KeyboardCompletion? = nil) {
        self.animation = animation
        self.completion = completion
    }
}
