//
//  PTEyeTrackingExtensions.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SceneKit
import ImageIO

internal extension SCNVector3 {
    func length() -> Float {
        sqrtf(x * x + y * y + z * z)
    }
}

internal func / (l: SCNVector3, r: Float) -> SCNVector3 {
    SCNVector3Make(l.x / r, l.y / r, l.z / r)
}

internal func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z)
}

internal func + (l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    SCNVector3Make(l.x + r.x, l.y + r.y, l.z + r.z)
}

internal extension Collection where Element == CGFloat, Index == Int {
    var average: CGFloat? {
        guard !isEmpty else { return nil }
        
        let sum = reduce(CGFloat(0)) { current, next -> CGFloat in
            current + next
        }
        
        return sum / CGFloat(count)
    }
}

internal extension Collection where Element == simd_float4x4, Index == Int {
    var isAllEqual: Bool? {
        guard !isEmpty else { return nil }
        var isEqual:Bool = true
        var prev = self[0]
        for current in self {
            isEqual = isEqual && simd_equal(prev, current)
            prev = current
        }

        return isEqual
    }
}
