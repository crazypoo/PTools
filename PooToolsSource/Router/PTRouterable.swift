//
//  PTRouterable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public protocol PTRouterable {
    
    static var patternString: [String] { get }
    
    static var priority: UInt { get }
}

extension PTRouterable {
    public static var priority: UInt {
        1000
    }
}
