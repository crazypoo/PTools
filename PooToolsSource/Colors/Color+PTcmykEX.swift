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
        // 直接使用标准转换公式，代码更清晰，且避免了 inout 闭包的开销
        let r = (1.0 - c) * (1.0 - k)
        let g = (1.0 - m) * (1.0 - k)
        let b = (1.0 - y) * (1.0 - k)
        
        // 假设 self.init(r:g:b:a:) 是你在其他地方定义的便利构造器
        // 如果是原生方法，应该是 self.init(red: r, green: g, blue: b, alpha: alpha)
        self.init(r: r, g: g, b: b, a: alpha)
    }
    
    // 如果你依然非常需要支持数组传入，可以保留一个包装方法，但内部调用上面的安全方法：
    convenience init(cmykData: [CGFloat]) {
        guard cmykData.count >= 4 else {
            self.init(r: 0, g: 0, b: 0, a: 0) // 或者返回 .clear
            return
        }
        self.init(c: cmykData[0], m: cmykData[1], y: cmykData[2], k: cmykData[3])
    }
}
