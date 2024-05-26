//
//  Color+PTcmykEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif

// MARK: HSB Color Space

extension DynamicColor {
  
    convenience init(cmykData:[CGFloat]) {
        if cmykData.count < 4 {
            self.init(r: 0, g: 0, b: 0,a:0)
            return
        }
        
        var C:CGFloat = cmykData[0]
        var M:CGFloat = cmykData[1]
        var Y:CGFloat = cmykData[2]
        let K:CGFloat = cmykData[3]

        let cmyTransform = { (x: inout CGFloat) -> Void in
                x = x * (1 - K) + K
        }
        cmyTransform(&C)
        cmyTransform(&M)
        cmyTransform(&Y)
        
        let R = 1 - C
        let G = 1 - M
        let B = 1 - Y
        
        self.init(r: R, g: G, b: B, a: 1)
    }
}
