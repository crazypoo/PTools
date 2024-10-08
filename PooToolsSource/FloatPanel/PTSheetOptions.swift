//
//  PTSheetOptions.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

public struct PTSheetOptions {
    public static var `default` = PTSheetOptions()
    
    public enum TransitionOverflowType {
        case color(color: UIColor)
        case view(view: UIView)
        case none
        case automatic
    }
    
    public var pullBarHeight: CGFloat = 24
    /// 展示界面的圓角
    public var presentingViewCornerRadius: CGFloat = 12
    public var shouldExtendBackground = true
    public var setIntrinsicHeightOnNavigationControllers = true

    public var transitionAnimationOptions: UIView.AnimationOptions = [.curveEaseOut]
    public var transitionDampening: CGFloat = 0.7
    public var transitionDuration: TimeInterval = 0.4
    /// Transition velocity base value. Automatically adjusts based on the initial size of the sheet.
    public var transitionVelocity: CGFloat = 0.8
    public var transitionOverflowType: TransitionOverflowType = .automatic
    
    /// Default value 500, greater value will require more velocity to dismiss. Lesser values will do opposite.
    public var pullDismissThreshod: CGFloat = 500.0
    
    /// Allow the sheet to become full screen if pulled all the way to the top and not larger than the maximum size specified in sizes. Defaults to false.
    public var useFullScreenMode = true
    /// 被彈出界面是否用抽屜式顯示,默認開啟
    public var shrinkPresentingViewController = true
    /// Set true to be able to use the sheet view controller as a subview instead of a modal. Defaults to false.
    public var useInlineMode = false
    
    public var horizontalPadding: CGFloat = 0
    public var maxWidth: CGFloat?

    public var isRubberBandEnabled: Bool = false
        
    /// Experimental flag that attempts to shrink the nested presentations more each time a new sheet is presented. This must be set before any sheet is presented.
    public static var shrinkingNestedPresentingViewControllers = false
    
    public init() { }
    public init(pullBarHeight: CGFloat? = nil,
                presentingViewCornerRadius: CGFloat? = nil,
                shouldExtendBackground: Bool? = nil,
                setIntrinsicHeightOnNavigationControllers: Bool? = nil,
                useFullScreenMode: Bool? = nil,
                shrinkPresentingViewController: Bool? = nil,
                useInlineMode: Bool? = nil,
                horizontalPadding: CGFloat? = nil,
                maxWidth: CGFloat? = nil,
                isRubberBandEnabled: Bool? = nil) {
        let defaultOptions = PTSheetOptions.default
        self.pullBarHeight = pullBarHeight ?? defaultOptions.pullBarHeight
        self.presentingViewCornerRadius = presentingViewCornerRadius ?? defaultOptions.presentingViewCornerRadius
        self.shouldExtendBackground = shouldExtendBackground ?? defaultOptions.shouldExtendBackground
        self.setIntrinsicHeightOnNavigationControllers = setIntrinsicHeightOnNavigationControllers ?? defaultOptions.setIntrinsicHeightOnNavigationControllers
        self.useFullScreenMode = useFullScreenMode ?? defaultOptions.useFullScreenMode
        self.shrinkPresentingViewController = shrinkPresentingViewController ?? defaultOptions.shrinkPresentingViewController
        self.useInlineMode = useInlineMode ?? defaultOptions.useInlineMode
        self.horizontalPadding = horizontalPadding ?? defaultOptions.horizontalPadding
        let maxWidth = maxWidth ?? defaultOptions.maxWidth
        self.maxWidth = maxWidth == 0 ? nil : maxWidth
        self.isRubberBandEnabled = isRubberBandEnabled ?? false
    }
    
    @available(*, unavailable, message: "cornerRadius, minimumSpaceAbovePullBar, gripSize and gripColor are now properties on SheetViewController. Use them instead.")
    public init(pullBarHeight: CGFloat? = nil,
                gripSize: CGSize? = nil,
                gripColor: UIColor? = nil,
                cornerRadius: CGFloat? = nil,
                presentingViewCornerRadius: CGFloat? = nil,
                shouldExtendBackground: Bool? = nil,
                setIntrinsicHeightOnNavigationControllers: Bool? = nil,
                useFullScreenMode: Bool? = nil,
                shrinkPresentingViewController: Bool? = nil,
                useInlineMode: Bool? = nil,
                minimumSpaceAbovePullBar: CGFloat? = nil) {
        let defaultOptions = PTSheetOptions.default
        self.pullBarHeight = pullBarHeight ?? defaultOptions.pullBarHeight
        self.presentingViewCornerRadius = presentingViewCornerRadius ?? defaultOptions.presentingViewCornerRadius
        self.shouldExtendBackground = shouldExtendBackground ?? defaultOptions.shouldExtendBackground
        self.setIntrinsicHeightOnNavigationControllers = setIntrinsicHeightOnNavigationControllers ?? defaultOptions.setIntrinsicHeightOnNavigationControllers
        self.useFullScreenMode = useFullScreenMode ?? defaultOptions.useFullScreenMode
        self.shrinkPresentingViewController = shrinkPresentingViewController ?? defaultOptions.shrinkPresentingViewController
        self.useInlineMode = useInlineMode ?? defaultOptions.useInlineMode
    }
}
#endif
