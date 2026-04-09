//
//  PTSheetView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

class PTSheetView: UIView {
    
    /// 触摸事件拦截闭包。
    /// 返回 true 表示视图响应该触摸点，返回 false 表示透传给底层视图。
    var sheetPointHandler: ((CGPoint, UIEvent?) -> Bool)?
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // [优化] 如果外部设置了 handler，以 handler 的结果为准；
        // 如果外部没有设置，切勿直接返回 true，而是降级走系统默认的父类逻辑。
        if let handler = sheetPointHandler {
            return handler(point, event)
        }
        return super.point(inside: point, with: event)
    }
}
#endif // os(iOS) || os(tvOS) || os(watchOS)
