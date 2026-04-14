//
//  PTEmptyDataSetSource.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import Foundation
import UIKit

/// The object that acts as the data source of the empty datasets.
/// @discussion All data source methods are optional.
@MainActor // 🌟 优化1：强约束所有获取 UI 元素的操作必须在主线程，避免异步线程返回视图导致崩溃
public protocol PTEmptyDataSetSource: AnyObject { // 🌟 优化2：必须继承 AnyObject，防止循环引用
    
    /// Asks the data source for the title of the dataset.
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString?
    
    /// Asks the data source for the description of the dataset.
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString?
    
    /// Asks the data source for the image of the dataset.
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage?
    
    /// Asks the data source for a tint color of the image dataset. Default is nil.
    func imageTintColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor?

    /// Asks the data source for the image animation of the dataset.
    func imageAnimation(forEmptyDataSet scrollView: UIScrollView) -> CAAnimation?
    
    /// Asks the data source for the title to be used for the specified button state.
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString?
    
    /// Asks the data source for the image to be used for the specified button state.
    func buttonImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> UIImage?
    
    /// Asks the data source for a background image to be used for the specified button state.
    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> UIImage?

    /// Asks the data source for the background color of the dataset. Default is clear color.
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor?

    /// Asks the data source for a custom view to be displayed instead of the default views such as labels, imageview and button.
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView?

    /// Asks the data source for a offset for vertical alignment of the content. Default is 0.
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat

    /// Asks the data source for a vertical space between elements. Default is 11 pts.
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat
}

// MARK: - Default Implementations (默认实现)
public extension PTEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return nil
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return nil
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return nil
    }
    
    func imageTintColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return nil
    }
    
    func imageAnimation(forEmptyDataSet scrollView: UIScrollView) -> CAAnimation? {
        return nil
    }
 
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        return nil
    }
    
    func buttonImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> UIImage? {
        return nil
    }

    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> UIImage? {
        return nil
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return nil
    }
    
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        return nil
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 0
    }
 
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 11
    }
}
