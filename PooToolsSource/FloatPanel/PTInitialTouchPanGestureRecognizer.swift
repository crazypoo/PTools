//
//  PTInitialTouchPanGestureRecognizer.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

/// 自定义的拖拽手势识别器，用于记录手指初始触摸的位置
class PTInitialTouchPanGestureRecognizer: UIPanGestureRecognizer {
    
    /// 记录手势开始时的初始触摸点
    /// [优化] 使用 private(set) 保证外部只能读取，不能篡改，提升代码安全性
    private(set) var initialTouchLocation: CGPoint?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        // 获取并记录第一根手指的触摸位置
        initialTouchLocation = touches.first?.location(in: view)
    }
    
    // [优化] 在手势结束或取消被系统重置时，清理内部状态
    override func reset() {
        super.reset()
        initialTouchLocation = nil
    }
}
#endif // os(iOS) || os(tvOS) || os(watchOS)
