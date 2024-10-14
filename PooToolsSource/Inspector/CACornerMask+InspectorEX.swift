//
//  CACornerMask+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension CACornerMask {
    var rectCorner: UIRectCorner {
        var corner = UIRectCorner()
        if contains(.layerMaxXMaxYCorner) {
            corner.insert(.bottomRight)
        }
        if contains(.layerMaxXMinYCorner) {
            corner.insert(.topRight)
        }
        if contains(.layerMinXMaxYCorner) {
            corner.insert(.bottomLeft)
        }
        if contains(.layerMinXMinYCorner) {
            corner.insert(.topLeft)
        }
        return corner
    }
}
