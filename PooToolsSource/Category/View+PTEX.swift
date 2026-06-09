//
//  View+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import SwiftUI

public extension View {
    
    /// SwiftUI 风格的弹窗调用
    /// - Parameters:
    ///   - isPresent: 绑定状态，控制弹窗显示与隐藏
    ///   - createAlert: 使用闭包延迟创建 Controller，避免不必要的内存开销
    ///   - completion: 弹窗消失后的回调
    func alert( isPresent: Binding<Bool>,
                createAlert: @escaping () -> PTAlertController,
                completion: PTActionTask? = nil) -> some View {
        // 使用 onChange 监听状态变化，这是 SwiftUI 中触发外部 UI 副作用的标准做法
        self.onChange(of: isPresent.wrappedValue) { oldValue, newValue in
            // newValue 代表了状态改变后的最新布尔值（等同于以前的 show）
            if newValue {
                // 1. 创建弹窗控制器 (比如 PTAlertTipsViewController)
                let alertVC = createAlert()
                
                // 2. 包装回调：在弹窗真正消失时，同步重置 SwiftUI 的状态
                let wrapperCompletion: PTActionTask = {
                    isPresent.wrappedValue = false
                    completion?()
                }
                
                // 3. 通过你的中枢管理器展示它
                PTAlertManager.show(alertVC, completion: wrapperCompletion)
            } else {
                // 4. 如果开发者在外部通过代码把 isPresent 设为 false，主动关闭它
                PTAlertManager.dismissAll()
            }
        }
    }
}
