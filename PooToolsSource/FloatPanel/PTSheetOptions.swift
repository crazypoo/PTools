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
    
    /// 默认的配置实例
    public static var `default` = PTSheetOptions()
    
    public enum TransitionOverflowType {
        case color(color: UIColor)
        case view(view: UIView)
        case none
        case automatic
    }
    
    // MARK: - UI Configuration (UI 配置)
    
    /// 顶部拖拽条的高度
    public var pullBarHeight: CGFloat = 24
    /// 展示界面的圆角半径
    public var presentingViewCornerRadius: CGFloat = 12
    /// 是否允许背景延伸
    public var shouldExtendBackground = true
    /// 水平方向的内边距
    public var horizontalPadding: CGFloat = 0
    /// 面板的最大宽度。如果设为 0，将被自动转换为 nil（即不限制宽度）
    public var maxWidth: CGFloat?
    
    // MARK: - Behavior Configuration (行为配置)
    
    /// 是否在导航控制器上设置内置高度
    public var setIntrinsicHeightOnNavigationControllers = true
    /// 如果一直拉到顶部，是否允许面板全屏显示（不超过 maxWidth 指定的大小）
    public var useFullScreenMode = true
    /// 被弹出的底层控制器界面是否用抽屉式缩放显示
    public var shrinkPresentingViewController = true
    /// 是否将 sheet view controller 作为普通子视图使用，而不是模态弹出
    public var useInlineMode = false
    /// 是否开启橡皮筋拉伸效果
    public var isRubberBandEnabled: Bool = false
    
    // MARK: - Animation Configuration (动画配置)
    
    /// 转场动画选项
    public var transitionAnimationOptions: UIView.AnimationOptions = [.curveEaseOut]
    /// 转场阻尼系数
    public var transitionDampening: CGFloat = 0.7
    /// 转场持续时间
    public var transitionDuration: TimeInterval = 0.4
    /// 转场基础速度。会根据 sheet 的初始大小自动调整
    public var transitionVelocity: CGFloat = 0.8
    /// 转场溢出类型
    public var transitionOverflowType: TransitionOverflowType = .automatic
    /// 下拉消失的阈值。默认值 500，值越大需要越大的速度才能滑动取消，反之亦然。
    public var pullDismissThreshod: CGFloat = 500.0
    
    // MARK: - Experimental (实验性功能)
    
    /// [实验性标志] 每次呈现新的 sheet 时，尝试进一步缩小嵌套的呈现视图。必须在呈现任何 sheet 之前设置。
    public static var shrinkingNestedPresentingViewControllers = false
    
    // MARK: - Initialization
    
    /// 基础初始化
    public init() { }
    
    /// 自定义配置初始化
    /// 使用了 Swift 参数默认值特性，调用时只需传入需要修改的参数即可
    public init(pullBarHeight: CGFloat = 24,
                presentingViewCornerRadius: CGFloat = 12,
                shouldExtendBackground: Bool = true,
                setIntrinsicHeightOnNavigationControllers: Bool = true,
                useFullScreenMode: Bool = true,
                shrinkPresentingViewController: Bool = true,
                useInlineMode: Bool = false,
                horizontalPadding: CGFloat = 0,
                maxWidth: CGFloat? = nil,
                isRubberBandEnabled: Bool = false) {
        
        self.pullBarHeight = pullBarHeight
        self.presentingViewCornerRadius = presentingViewCornerRadius
        self.shouldExtendBackground = shouldExtendBackground
        self.setIntrinsicHeightOnNavigationControllers = setIntrinsicHeightOnNavigationControllers
        self.useFullScreenMode = useFullScreenMode
        self.shrinkPresentingViewController = shrinkPresentingViewController
        self.useInlineMode = useInlineMode
        self.horizontalPadding = horizontalPadding
        self.maxWidth = maxWidth == 0 ? nil : maxWidth
        self.isRubberBandEnabled = isRubberBandEnabled
    }
    
    // MARK: - Deprecated / Unavailable
    
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
        // 这个方法由于标记了 unavailable，实际上代码体并不会被执行，留空或保留默认初始化即可。
        // 为了兼容旧版 API 占位，只需调用基础 init。
        self.init()
    }
}
#endif // os(iOS) || os(tvOS) || os(watchOS)
