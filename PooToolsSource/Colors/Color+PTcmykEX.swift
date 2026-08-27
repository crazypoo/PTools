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
    
    /// 从 CMYK 数值初始化颜色
    /// - Parameters:
    ///   - c: Cyan (青色) 0.0 ~ 1.0
    ///   - m: Magenta (品红) 0.0 ~ 1.0
    ///   - y: Yellow (黄色) 0.0 ~ 1.0
    ///   - k: Key/Black (黑色) 0.0 ~ 1.0
    ///   - alpha: 透明度，默认为 1.0
    convenience init(c: CGFloat, m: CGFloat, y: CGFloat, k: CGFloat, alpha: CGFloat = 1.0) {
        let cyan = clip(c.isFinite ? c : 0, 0, 1)
        let magenta = clip(m.isFinite ? m : 0, 0, 1)
        let yellow = clip(y.isFinite ? y : 0, 0, 1)
        let key = clip(k.isFinite ? k : 0, 0, 1)
        let components = PTRGBAComponents(red: (1.0 - cyan) * (1.0 - key),
                                           green: (1.0 - magenta) * (1.0 - key),
                                           blue: (1.0 - yellow) * (1.0 - key),
                                           alpha: alpha)
        self.init(red: components.red,
                  green: components.green,
                  blue: components.blue,
                  alpha: components.alpha)
    }
    
    convenience init(cmykData: [CGFloat]) {
        guard cmykData.count >= 4 else {
            self.init(red: 0, green: 0, blue: 0, alpha: 0)
            return
        }
        self.init(c: cmykData[0], m: cmykData[1], y: cmykData[2], k: cmykData[3])
    }
}
