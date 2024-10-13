//
//  NSObject+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension NSObjectProtocol where Self: NSObject {
    func debounce(_ aSelector: Selector, after delay: TimeInterval, object: Any? = nil) {
        Self.cancelPreviousPerformRequests(
            withTarget: self,
            selector: aSelector,
            object: object
        )
        
        perform(aSelector, with: object, afterDelay: delay)
    }
}
