//
//  PTEmptyDataSetDelegate.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import Foundation
import UIKit

/// The object that acts as the delegate of the empty datasets.
/// @discussion All delegate methods are optional. Use this delegate for receiving action callbacks.
@MainActor // 🌟 优化1：强约束所有 UI 回调必须在主线程，消除并发警告和闪退隐患
public protocol PTEmptyDataSetDelegate: AnyObject { // 🌟 优化2：必须继承 AnyObject，让遵守者只能是 Class，以便能够使用 weak 关键字防止内存泄漏
    
    /// Asks the delegate to know if the empty dataset should fade in when displayed. Default is true.
    func emptyDataSetShouldFadeIn(_ scrollView: UIScrollView) -> Bool
    
    /// Asks the delegate to know if the empty dataset should still be displayed when the amount of items is more than 0. Default is false.
    func emptyDataSetShouldBeForcedToDisplay(_ scrollView: UIScrollView) -> Bool

    /// Asks the delegate to know if the empty dataset should be rendered and displayed. Default is true.
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool

    /// Asks the delegate for touch permission. Default is true.
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool

    /// Asks the delegate for scroll permission. Default is false.
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool

    /// Asks the delegate for image view animation permission. Default is false.
    func emptyDataSetShouldAnimateImageView(_ scrollView: UIScrollView) -> Bool

    /// Tells the delegate that the empty dataset view was tapped.
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView)

    /// Tells the delegate that the action button was tapped.
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton)

    /// Tells the delegate that the empty data set will appear.
    func emptyDataSetWillAppear(_ scrollView: UIScrollView)

    /// Tells the delegate that the empty data set did appear.
    func emptyDataSetDidAppear(_ scrollView: UIScrollView)

    /// Tells the delegate that the empty data set will disappear.
    func emptyDataSetWillDisappear(_ scrollView: UIScrollView)

    /// Tells the delegate that the empty data set did disappear.
    func emptyDataSetDidDisappear(_ scrollView: UIScrollView)
}

// MARK: - Default Implementations (默认实现)
// 扩展协议提供默认实现，这是非常棒的 Swift 实践，让遵守者可以选择性实现需要的方法。
public extension PTEmptyDataSetDelegate {
    
    func emptyDataSetShouldFadeIn(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldBeForcedToDisplay(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func emptyDataSetShouldAnimateImageView(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapView view: UIView) {
        // 默认空实现
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        // 默认空实现
    }
    
    func emptyDataSetWillAppear(_ scrollView: UIScrollView) {
        // 默认空实现
    }
    
    func emptyDataSetDidAppear(_ scrollView: UIScrollView) {
        // 默认空实现
    }
    
    func emptyDataSetWillDisappear(_ scrollView: UIScrollView) {
        // 默认空实现
    }
    
    func emptyDataSetDidDisappear(_ scrollView: UIScrollView) {
        // 默认空实现
    }
}
