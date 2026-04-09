//
//  PTBaseViewController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension PTBaseViewController: UIGestureRecognizerDelegate {
    
    /// 决定当前手势识别器是否需要强制“另一个手势识别器”失败后，自己才能识别成功。
    ///
    /// - Parameters:
    ///   - gestureRecognizer: 当前正在评估的手势识别器
    ///   - otherGestureRecognizer: 另一个与之发生冲突的手势识别器
    /// - Returns: 默认返回 false，表示不强制要求其他手势失败，允许它们和平共处或通过其他代理方法（如 shouldRecognizeSimultaneouslyWith）来进一步裁定。
    /// - Note: 作为一个基类 (BaseViewController) 的默认实现，保留此 `open` 方法方便子类在处理悬浮面板拖拽与内部 UIScrollView 滚动冲突时进行重写。
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}
#endif // os(iOS) || os(tvOS) || os(watchOS)
