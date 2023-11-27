//
//  PTCopying.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

/**
    Custom protocol for make copy of objects.
 */
public protocol PTCopying {
    
    init(instance: Self)
}

extension PTCopying {
    
    /**
        Make copy of object.
     */
    public func copyObject() -> Self {
        Self.init(instance: self)
    }
}

extension Array where Element: PTCopying {
    
    /**
        Make copy of array objects.
     */
    public func copy() -> [Element] {
        self.map {
            $0.copyObject()
        }
    }
}
