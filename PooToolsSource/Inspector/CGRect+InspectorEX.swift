//
//  CGRect+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import CoreGraphics

extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: self))
    }
}
