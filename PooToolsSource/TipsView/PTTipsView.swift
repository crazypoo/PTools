//
//  PTTipsView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/10/7.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
#if !(os(iOS) && (arch(i386) || arch(arm)))
import SwiftUI
#endif

fileprivate struct CornerPoint {
    var center: CGPoint
    var startAngle: CGFloat
    var endAngle: CGFloat
}

fileprivate extension UIEdgeInsets {
    var horizontal: CGFloat {
        return self.left + self.right
    }

    var vertical: CGFloat {
        return self.top + self.bottom
    }
}

/// 指定气泡提示（PopTip）弹出方向的枚举
public enum PopTipDirection {
    /// 向上：气泡在元素上方，箭头朝下
    case up
    /// 向下：气泡在元素下方，箭头朝上
    case down
    /// 向左：气泡在元素左侧，箭头朝右
    case left
    /// 向右：气泡在元素右侧，箭头朝左
    case right
    /// 自动：根据可用空间自动决定弹出位置
    case auto
    /// 水平自动：在左右两侧检查可用空间来决定弹出位置
    case autoHorizontal
    /// 垂直自动：在上下两侧检查可用空间来决定弹出位置
    case autoVertical
    /// 无：气泡显示在元素中心，无箭头
    case none

    var isAuto: Bool {
        return self == .autoVertical || self == .autoHorizontal || self == .auto
    }
}

/// 指定气泡出现时的入场动画类型
public enum PopTipEntranceAnimation {
    /// 缩放：从 0% 放大到 100%
    case scale
    /// 平移：从屏幕边缘平移进入
    case transition
    /// 淡入：透明度渐变出现
    case fadeIn
    /// 自定义：用户提供动画闭包
    case custom
    /// 无动画
    case none
}

/// 指定气泡消失时的退场动画类型
public enum PopTipExitAnimation {
    /// 缩放：从 100% 缩小到 0%
    case scale
    /// 淡出：透明度渐变消失
    case fadeOut
    /// 自定义：用户提供动画闭包
    case custom
    /// 无动画
    case none
}

/// 指定气泡在显示状态下持续执行的动作动画
public enum PopTipActionAnimation {
    /// 弹跳动画：顺着箭头方向弹跳。可提供可选的偏移量
    case bounce(CGFloat?)
    /// 漂浮动画：在原地上下/左右漂浮。可提供可选的 X/Y 偏移量 (默认 8pt)
    case float(offsetX: CGFloat?, offsetY: CGFloat?)
    /// 脉冲动画：大小缩放跳动。可提供最大放大倍数 (默认 1.1倍)
    case pulse(CGFloat?)
    /// 无持续动画
    case none
}

private let DefaultBounceOffset = CGFloat(8)
private let DefaultFloatOffset = CGFloat(8)
private let DefaultPulseOffset = CGFloat(1.1)

open class PTTipsView: UIView {
    
    // MARK: - 公开属性 (Public Properties)
    
    /// 气泡显示的文本。可见后也能动态更新
    open var text: String? {
        didSet {
            accessibilityLabel = text
            setNeedsLayout()
        }
    }
    /// 文本字体
    open var font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    /// 文本颜色
    @objc open dynamic var textColor = UIColor.white
    /// 文本对齐方式
    @objc open dynamic var textAlignment = NSTextAlignment.center
    /// 气泡背景颜色。如果指定了 `bubbleLayerGenerator`，此属性将被忽略
    @objc open dynamic var bubbleColor = UIColor.red
    /// 用于生成气泡底层 CALayer 的闭包。如果为空，将使用 bubbleColor 纯色填充
    @objc open dynamic var bubbleLayerGenerator: ((_ path: UIBezierPath) -> CALayer?)?
    /// 边框颜色
    @objc open dynamic var borderColor = UIColor.clear
    /// 边框宽度
    @objc open dynamic var borderWidth = CGFloat(0.0)
    /// 圆角半径
    @objc open dynamic var cornerRadius = CGFloat(4.0)
    /// 是否为全圆角。如果为 true，圆角半径等于 `frame.height / 2`
    @objc open dynamic var isRounded = false
    
    // 阴影配置
    @objc open dynamic var shadowColor: UIColor = .clear
    @objc open dynamic var shadowOffset: CGSize = .zero
    @objc open dynamic var shadowRadius: Float = 0
    @objc open dynamic var shadowOpacity: Float = 0
    
    /// 气泡和目标视图之间的间距
    @objc open dynamic var offset = CGFloat(0.0)
    /// 内部文本的通用内边距
    @objc open dynamic var padding = CGFloat(6.0)
    /// 不同方向的具体内边距 (优先级高于 padding)
    @objc open dynamic var edgeInsets = UIEdgeInsets.zero
    /// 箭头的宽高
    @objc open dynamic var arrowSize = CGSize(width: 8, height: 8)
    /// 箭头顶点的圆角半径
    @objc open dynamic var arrowRadius = CGFloat(0.0)
    
    // 动画时间配置
    @objc open dynamic var animationIn: TimeInterval = 0.4
    @objc open dynamic var animationOut: TimeInterval = 0.2
    @objc open dynamic var delayIn: TimeInterval = 0
    @objc open dynamic var delayOut: TimeInterval = 0
    
    /// 入场动画类型
    open var entranceAnimation = PopTipEntranceAnimation.scale
    /// 退场动画类型
    open var exitAnimation = PopTipExitAnimation.scale
    /// 持续动作动画类型
    open var actionAnimation = PopTipActionAnimation.none
    
    // 动作动画时间配置
    @objc open dynamic var actionAnimationIn: TimeInterval = 1.2
    @objc open dynamic var actionAnimationOut: TimeInterval = 1.0
    @objc open dynamic var actionDelayIn: TimeInterval = 0
    @objc open dynamic var actionDelayOut: TimeInterval = 0
    
    /// 距离屏幕边缘的最短边距
    @objc open dynamic var edgeMargin = CGFloat(0.0)
    /// 气泡自身的偏移量（左右移动）
    @objc open dynamic var bubbleOffset = CGFloat(0.0)
    /// 箭头相对于气泡中心的偏移量
    @objc open dynamic var arrowOffset = CGFloat(0.0)
    
    // 背景遮罩配置
    /// 显示提示时，背景遮罩的颜色
    @objc open dynamic var maskColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
    /// 是否显示背景遮罩
    @objc open dynamic var shouldShowMask = false
    /// 是否对目标区域进行镂空显示
    @objc open dynamic var shouldCutoutMask = false
    /// 镂空区域的路径生成器 (默认在目标视图基础上向外扩展 8pt 并带圆角)
    @objc open dynamic var cutoutPathGenerator: (_ from: CGRect) -> UIBezierPath = { from in
        UIBezierPath(roundedRect: from.insetBy(dx: -8, dy: -8), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 8, height: 8))
    }
    
    /// 是否限制气泡不超出父视图边界
    @objc open dynamic var constrainInContainerView = true
    
    /// 气泡指向的目标区域 (CGRect)
    open var from = CGRect.zero {
        didSet { setup() }
    }
    
    /// 气泡是否可见（只读）
    open var isVisible: Bool { get { return self.superview != nil } }
    
    // 交互行为配置
    /// 点击气泡自身时是否使其消失
    @objc open dynamic var shouldDismissOnTap = true
    /// 点击气泡外部区域时是否使其消失
    @objc open dynamic var shouldDismissOnTapOutside = true
    /// 是否将目标区域(from)视作气泡的一部分 (影响点击事件回调)
    @objc open dynamic var shouldConsiderOriginatingFrameAsPopTip = false
    /// 是否将镂空区域的点击作为独立事件回调
    @objc open dynamic var shouldConsiderCutoutTapSeparately = false
    /// 滑动气泡外部时是否使其消失
    @objc open dynamic var shouldDismissOnSwipeOutside = false
    /// 显示后是否自动开始动作动画
    @objc open dynamic var startActionAnimationOnShow = true
    
    /// 外部滑动消失的手势方向，默认为向右
    open var swipeRemoveGestureDirection = UISwipeGestureRecognizer.Direction.right {
        didSet { swipeGestureRecognizer?.direction = swipeRemoveGestureDirection }
    }
    
    // MARK: - 回调闭包 (Handlers)
    
    open var tapHandler: ((PTTipsView) -> Void)?
    open var tapOutsideHandler: ((PTTipsView) -> Void)?
    open var tapCutoutHandler: ((PTTipsView) -> Void)?
    open var swipeOutsideHandler: ((PTTipsView) -> Void)?
    open var appearHandler: ((PTTipsView) -> Void)?
    open var dismissHandler: ((PTTipsView) -> Void)?
    
    open var entranceAnimationHandler: ((@escaping () -> Void) -> Void)?
    open var exitAnimationHandler: ((@escaping () -> Void) -> Void)?
    
    // MARK: - 私有 & 只读属性
    
    open private(set) var arrowPosition = CGPoint.zero
    open private(set) weak var containerView: UIView?
    open private(set) var direction = PopTipDirection.none
    open private(set) var isAnimating: Bool = false
    open private(set) var isPerformingExitAnimation: Bool = false
    open private(set) var backgroundMask: UIView?
    open private(set) var tapGestureRecognizer: UITapGestureRecognizer?
    open private(set) var tapToRemoveGestureRecognizer: UITapGestureRecognizer?
    
    fileprivate var attributedText: NSAttributedString?
    fileprivate var paragraphStyle = NSMutableParagraphStyle()
    fileprivate var swipeGestureRecognizer: UISwipeGestureRecognizer?
    fileprivate var dismissTimer: Timer?
    fileprivate var textBounds = CGRect.zero
    fileprivate var maxWidth = CGFloat(0)
    fileprivate var customView: UIView?
    fileprivate var hostingController: UIViewController?
    fileprivate var isApplicationInBackground: Bool?
    
    fileprivate var bubbleLayer: CALayer? {
        willSet { bubbleLayer?.removeFromSuperlayer() }
    }
    
    fileprivate var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private var shouldBounce = false

    // MARK: - 生命周期补充: 暗黑模式适配
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // 当系统主题颜色改变时，强制重绘以更新颜色
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setNeedsDisplay()
        }
    }

    // MARK: - 布局与计算 (Layout & Math)
    
    /// 设置垂直方向（上下）的位置
    internal func setupVertically() -> (CGRect, CGPoint) {
        guard let containerView = containerView else { return (CGRect.zero, CGPoint.zero) }

        var frame = CGRect.zero
        let offset = self.offset * (direction == .up ? -1 : 1)

        frame.size = CGSize(width: textBounds.width + padding * 2 + edgeInsets.horizontal, height: textBounds.height + padding * 2 + edgeInsets.vertical + arrowSize.height)
        var x = from.origin.x + from.width / 2 - frame.width / 2
        if x < 0 { x = edgeMargin }
        if constrainInContainerView && (x + frame.width > containerView.bounds.width) {
            x = containerView.bounds.width - frame.width - edgeMargin
        }

        if direction == .down {
            frame.origin = CGPoint(x: x, y: from.origin.y + from.height + offset)
        } else {
            frame.origin = CGPoint(x: x, y: from.origin.y - frame.height + offset)
        }

        // 优化点：修复箭头偏移为0时的 NaN 崩溃问题
        let arrowOffsetSign: CGFloat = arrowOffset < 0 ? -1 : 1
        let maxAllowedOffset = frame.size.width / 2 - cornerRadius * 2
        let constrainedArrowOffset = abs(arrowOffset) > (frame.size.width / 2) ? (arrowOffsetSign * maxAllowedOffset) : arrowOffset
        
        var arrowPosition = CGPoint(
          x: from.origin.x + from.width / 2 - frame.origin.x - constrainedArrowOffset,
          y: (direction == .up) ? frame.height : from.origin.y + from.height - frame.origin.y + offset
        )

        if bubbleOffset > 0 && arrowPosition.x < bubbleOffset {
            bubbleOffset = arrowPosition.x - arrowSize.width
        } else if bubbleOffset < 0 && frame.width < abs(bubbleOffset) {
            bubbleOffset = -(arrowPosition.x - arrowSize.width)
        } else if bubbleOffset < 0 && (frame.origin.x - arrowPosition.x) < abs(bubbleOffset) {
            bubbleOffset = -(arrowSize.width + edgeMargin)
        }

        if constrainInContainerView {
          let leftSpace = frame.origin.x - containerView.frame.origin.x
          let rightSpace = containerView.frame.width - leftSpace - frame.width

          if bubbleOffset < 0 && leftSpace < abs(bubbleOffset) {
              bubbleOffset = -leftSpace + edgeMargin
          } else if bubbleOffset > 0 && rightSpace < bubbleOffset {
              bubbleOffset = rightSpace - edgeMargin
          }
        }
        frame.origin.x += bubbleOffset
        frame.size = CGSize(width: frame.width + borderWidth * 2, height: frame.height + borderWidth * 2)

        if containerView.frame.width < frame.width, !constrainInContainerView {
            frame.origin.x = -frame.width / 2 + containerView.frame.width / 2
            arrowPosition.x += frame.width / 2 - containerView.frame.width / 2
        }

        return (frame, arrowPosition)
    }

    /// 设置水平方向（左右）的位置
    internal func setupHorizontally() -> (CGRect, CGPoint) {
        guard let containerView = containerView else { return (CGRect.zero, CGPoint.zero) }

        var frame = CGRect.zero
        let offset = self.offset * (direction == .left ? -1 : 1)
        frame.size = CGSize(width: textBounds.width + padding * 2 + edgeInsets.horizontal + arrowSize.height, height: textBounds.height + padding * 2 + edgeInsets.vertical)

        let x = direction == .left ? from.origin.x - frame.width + offset : from.origin.x + from.width + offset
        var y = from.origin.y + from.height / 2 - frame.height / 2

        if y < 0 { y = edgeMargin }
        
        if let containerScrollView = containerView as? UIScrollView {
            if y + frame.height > containerScrollView.contentSize.height {
                y = containerScrollView.contentSize.height - frame.height - edgeMargin
            }
        } else {
            if y + frame.height > containerView.bounds.height && constrainInContainerView {
                y = containerView.bounds.height - frame.height - edgeMargin
            }
        }
        frame.origin = CGPoint(x: x, y: y)

        // 优化点：修复箭头偏移为0时的 NaN 崩溃问题
        let arrowOffsetSign: CGFloat = arrowOffset < 0 ? -1 : 1
        let maxAllowedOffset = frame.size.height / 2  - cornerRadius * 2
        let constrainedArrowOffset = abs(arrowOffset) > (frame.size.height / 2) ? (arrowOffsetSign * maxAllowedOffset) : arrowOffset
        
        let arrowPosition = CGPoint(
          x: direction == .left ? from.origin.x - frame.origin.x + offset : from.origin.x + from.width - frame.origin.x + offset,
          y: from.origin.y + from.height / 2 - frame.origin.y - constrainedArrowOffset
        )

        if bubbleOffset > 0 && arrowPosition.y < bubbleOffset {
            bubbleOffset = arrowPosition.y - arrowSize.width
        } else if bubbleOffset < 0 && frame.height < abs(bubbleOffset) {
            bubbleOffset = -(arrowPosition.y - arrowSize.height)
        }

        if constrainInContainerView {
            let topSpace = frame.origin.y - containerView.frame.origin.y
            let bottomSpace = containerView.frame.height - topSpace - frame.height

            if bubbleOffset < 0 && topSpace < abs(bubbleOffset) {
                bubbleOffset = -topSpace + edgeMargin
            } else if bubbleOffset > 0 && bottomSpace < bubbleOffset {
                bubbleOffset = bottomSpace - edgeMargin
            }
        }

        frame.origin.y += bubbleOffset
        frame.size = CGSize(width: frame.width + borderWidth * 2, height: frame.height + borderWidth * 2)

        return (frame, arrowPosition)
    }

    internal func rectContained(rect: CGRect) -> CGRect {
        guard let containerView = containerView, constrainInContainerView else { return rect }
        var finalRect = rect
        if (rect.origin.x) < containerView.frame.origin.x { finalRect.origin.x = edgeMargin }
        if (rect.origin.y) < containerView.frame.origin.y { finalRect.origin.y = edgeMargin }
        if (rect.origin.x + rect.width) > (containerView.frame.origin.x + containerView.frame.width) {
            finalRect.origin.x = containerView.frame.origin.x + containerView.frame.width - rect.width - edgeMargin
        }
        if (rect.origin.y + rect.height) > (containerView.frame.origin.y + containerView.frame.height) {
            finalRect.origin.y = containerView.frame.origin.y + containerView.frame.height - rect.height - edgeMargin
        }
        return finalRect
    }

    fileprivate func textBounds(for text: String?, attributedText: NSAttributedString?, view: UIView?, with font: UIFont, padding: CGFloat, edges: UIEdgeInsets, in maxWidth: CGFloat) -> CGRect {
        var bounds = CGRect.zero
        if let text = text {
            bounds = NSString(string: text).boundingRect(with: CGSize(width: maxWidth, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        }
        if let attributedText = attributedText {
            bounds = attributedText.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.infinity), options: .usesLineFragmentOrigin, context: nil)
        }
        if let view = view {
            bounds = view.frame
        }
        bounds.origin = CGPoint(x: padding + edges.left, y: padding + edges.top)
        return bounds.integral
    }

    fileprivate func setup() {
        guard let containerView = containerView else { return }

        var rect = CGRect.zero
        backgroundColor = .clear

        if direction.isAuto {
            var spaces: [PopTipDirection: CGFloat] = [:]
            if direction == .autoHorizontal || direction == .auto {
                spaces[.left] = from.minX - containerView.frame.minX
                spaces[.right] = containerView.frame.maxX - from.maxX
            }
            if direction == .autoVertical || direction == .auto {
                spaces[.up] = from.minY - containerView.frame.minY
                spaces[.down] = containerView.frame.maxY - from.maxY
            }
            // 优化点：安全解包，防止无空间时崩溃，提供默认值 .up
            direction = spaces.sorted(by: { $0.1 > $1.1 }).first?.key ?? .up
        }

        if direction == .left {
            maxWidth = CGFloat.minimum(maxWidth, from.origin.x - padding * 2 - edgeInsets.horizontal - arrowSize.width)
        }
        if direction == .right {
            maxWidth = CGFloat.minimum(maxWidth, containerView.bounds.width - from.origin.x - from.width - padding * 2 - edgeInsets.horizontal - arrowSize.width)
        }

        textBounds = textBounds(for: text, attributedText: attributedText, view: customView, with: font, padding: padding, edges: edgeInsets, in: maxWidth)

        // 优化点：防御除以0，防止 anchor 计算导致界面异常
        switch direction {
        case .auto, .autoHorizontal, .autoVertical: break
        case .up:
            let dimensions = setupVertically()
            rect = dimensions.0
            arrowPosition = dimensions.1
            let anchorX = rect.size.width > 0 ? arrowPosition.x / rect.size.width : 0.5
            layer.anchorPoint = CGPoint(x: anchorX, y: 1)
            layer.position = CGPoint(x: layer.position.x + rect.width * anchorX, y: layer.position.y + rect.height / 2)
        case .down:
            let dimensions = setupVertically()
            rect = dimensions.0
            arrowPosition = dimensions.1
            let anchorX = rect.size.width > 0 ? arrowPosition.x / rect.size.width : 0.5
            textBounds.origin = CGPoint(x: textBounds.origin.x, y: textBounds.origin.y + arrowSize.height)
            layer.anchorPoint = CGPoint(x: anchorX, y: 0)
            layer.position = CGPoint(x: layer.position.x + rect.width * anchorX, y: layer.position.y - rect.height / 2)
        case .left:
            let dimensions = setupHorizontally()
            rect = dimensions.0
            arrowPosition = dimensions.1
            let anchorY = rect.height > 0 ? arrowPosition.y / rect.height : 0.5
            layer.anchorPoint = CGPoint(x: 1, y: anchorY)
            layer.position = CGPoint(x: layer.position.x - rect.width / 2, y: layer.position.y + rect.height * anchorY)
        case .right:
            let dimensions = setupHorizontally()
            rect = dimensions.0
            arrowPosition = dimensions.1
            textBounds.origin = CGPoint(x: textBounds.origin.x + arrowSize.height, y: textBounds.origin.y)
            let anchorY = rect.height > 0 ? arrowPosition.y / rect.height : 0.5
            layer.anchorPoint = CGPoint(x: 0, y: anchorY)
            layer.position = CGPoint(x: layer.position.x + rect.width / 2, y: layer.position.y + rect.height * anchorY)
        case .none:
            rect.size = CGSize(width: textBounds.width + padding * 2.0 + edgeInsets.horizontal + borderWidth * 2, height: textBounds.height + padding * 2.0 + edgeInsets.vertical + borderWidth * 2)
            rect.origin = CGPoint(x: from.midX - rect.size.width / 2, y: from.midY - rect.height / 2)
            rect = rectContained(rect: rect)
            arrowPosition = CGPoint.zero
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            layer.position = CGPoint(x: from.midX, y: from.midY)
        }

        label.frame = textBounds
        if label.superview == nil {
            addSubview(label)
        }

        frame = rect

        if let customView = customView {
            customView.frame = textBounds
        }

        if !shouldShowMask {
            backgroundMask?.removeFromSuperview()
        } else {
            if backgroundMask == nil {
                backgroundMask = UIView()
            }
            backgroundMask?.frame = containerView.bounds
        }

        setNeedsDisplay()

        if tapGestureRecognizer == nil {
            tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PTTipsView.handleTap(_:)))
            tapGestureRecognizer?.cancelsTouchesInView = false
            self.addGestureRecognizer(tapGestureRecognizer!)
        }
        if shouldDismissOnTapOutside && tapToRemoveGestureRecognizer == nil {
            tapToRemoveGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PTTipsView.handleTapOutside(_:)))
        }
        if shouldDismissOnSwipeOutside && swipeGestureRecognizer == nil {
            swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(PTTipsView.handleSwipeOutside(_:)))
            swipeGestureRecognizer?.direction = swipeRemoveGestureDirection
        }

        if isApplicationInBackground == nil {
            NotificationCenter.default.addObserver(self, selector: #selector(PTTipsView.handleApplicationActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(PTTipsView.handleApplicationResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        }
    }

    open override func draw(_ rect: CGRect) {
        if isRounded {
            let showHorizontally = direction == .left || direction == .right
            cornerRadius = (frame.size.height - (showHorizontally ? 0 : arrowSize.height)) / 2
        }

        let path = PTTipsView.pathWith(rect: rect, frame: frame, direction: direction, arrowSize: arrowSize, arrowPosition: arrowPosition, arrowRadius: arrowRadius, borderWidth: borderWidth, radius: cornerRadius)

        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = CGFloat(shadowRadius)
        layer.shadowOffset = shadowOffset
        layer.shadowColor = shadowColor.cgColor

        if let bubbleLayerGenerator = self.bubbleLayerGenerator, let bubbleLayer = bubbleLayerGenerator(path) {
            self.bubbleLayer = bubbleLayer
            layer.insertSublayer(bubbleLayer, at: 0)
        } else {
            bubbleLayer = nil
            bubbleColor.setFill()
            path.fill()
        }

        borderColor.setStroke()
        path.lineWidth = borderWidth
        path.stroke()

        paragraphStyle.alignment = textAlignment

        let titleAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor
        ]

        if let text = text {
            label.attributedText = NSAttributedString(string: text, attributes: titleAttributes)
        } else if let text = attributedText {
            label.attributedText = text
        } else {
            label.attributedText = nil
        }
    }

    // MARK: - 显示接口 (Show Methods)

    open func show(text: String, direction: PopTipDirection, maxWidth: CGFloat, in view: UIView, from frame: CGRect, duration: TimeInterval? = nil) {
        resetView()
        attributedText = nil
        self.text = text
        accessibilityLabel = text
        self.direction = direction
        containerView = view
        self.maxWidth = maxWidth
        customView?.removeFromSuperview()
        customView = nil
        label.isHidden = false
        self.from = frame
        show(duration: duration)
    }

    open func show(attributedText: NSAttributedString, direction: PopTipDirection, maxWidth: CGFloat, in view: UIView, from frame: CGRect, duration: TimeInterval? = nil) {
        resetView()
        text = nil
        self.attributedText = attributedText
        accessibilityLabel = attributedText.string
        self.direction = direction
        containerView = view
        self.maxWidth = maxWidth
        customView?.removeFromSuperview()
        customView = nil
        label.isHidden = false
        self.from = frame
        show(duration: duration)
    }

    open func show(customView: UIView, direction: PopTipDirection, in view: UIView, from frame: CGRect, duration: TimeInterval? = nil) {
        resetView()
        text = nil
        attributedText = nil
        self.direction = direction
        containerView = view
        maxWidth = customView.frame.size.width
        self.customView?.removeFromSuperview()
        self.customView = customView
        label.isHidden = true
        addSubview(customView)
        self.from = frame
        show(duration: duration)
    }

  #if !(os(iOS) && (arch(i386) || arch(arm)))
    open func show<V: View>(rootView: V, direction: PopTipDirection, in view: UIView, from frame: CGRect, parent: UIViewController, duration: TimeInterval? = nil) {
        resetView()
        text = nil
        attributedText = nil
        self.direction = direction
        containerView = view
        
        let controller = UIHostingController(rootView: rootView)
        controller.view.backgroundColor = .clear
        
        let maxContentWidth: CGFloat
        if let window = parent.view.window {
            maxContentWidth = window.bounds.width - (self.edgeMargin * 2) - self.edgeInsets.horizontal - (self.padding * 2)
        } else {
            maxContentWidth = .greatestFiniteMagnitude
        }
        let sizeThatFits = controller.view.sizeThatFits(CGSize(width: maxContentWidth, height: CGFloat.greatestFiniteMagnitude))
        controller.view.frame.size = CGSize(width: min(sizeThatFits.width, maxContentWidth), height: sizeThatFits.height)
        maxWidth = controller.view.frame.size.width
        
        self.customView?.removeFromSuperview()
        self.customView = controller.view
        parent.addChild(controller)
        addSubview(controller.view)
        controller.didMove(toParent: parent)
        controller.view.layoutIfNeeded()
        self.from = frame
        hostingController = controller

        show(duration: duration)
    }
  #endif

    open func update(text: String) {
        self.text = text
        updateBubble()
    }

    open func update(attributedText: NSAttributedString) {
        self.attributedText = attributedText
        updateBubble()
    }

    open func update(customView: UIView) {
        self.customView = customView
        updateBubble()
    }

    // MARK: - 隐藏与控制 (Hide & Actions)

    @objc open func hide(forced: Bool = false) {
        if !forced && isAnimating {
            return
        }

        resetView()
        isAnimating = true
        dismissTimer?.invalidate()
        dismissTimer = nil

        if let gestureRecognizer = tapToRemoveGestureRecognizer {
            containerView?.removeGestureRecognizer(gestureRecognizer)
        }
        if let gestureRecognizer = swipeGestureRecognizer {
            containerView?.removeGestureRecognizer(gestureRecognizer)
        }

        let completion = {
            self.hostingController?.willMove(toParent: nil)
            self.customView?.removeFromSuperview()
            self.hostingController?.removeFromParent()
            self.customView = nil
            self.dismissActionAnimation()
            self.bubbleLayer = nil
            self.backgroundMask?.removeFromSuperview()
            self.backgroundMask?.subviews.forEach { $0.removeFromSuperview() }
            self.removeFromSuperview()
            self.layer.removeAllAnimations()
            self.transform = .identity
            self.isAnimating = false
            self.isPerformingExitAnimation = false
            self.dismissHandler?(self)
        }

        if isApplicationInBackground ?? false {
            completion()
        } else {
            isPerformingExitAnimation = true
            performExitAnimation(completion: completion)
        }
    }

    open func startActionAnimation() {
        performActionAnimation()
    }

    open func stopActionAnimation(_ completion: (() -> Void)? = nil) {
        dismissActionAnimation(completion)
    }

    fileprivate func resetView() {
        CATransaction.begin()
        layer.removeAllAnimations()
        CATransaction.commit()
        transform = .identity
        shouldBounce = false
    }

    fileprivate func updateBubble() {
        stopActionAnimation {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.transitionCrossDissolve, .beginFromCurrentState], animations: {
                self.setup()
                let path = PTTipsView.pathWith(rect: self.frame, frame: self.frame, direction: self.direction, arrowSize: self.arrowSize, arrowPosition: self.arrowPosition, arrowRadius: self.arrowRadius, borderWidth: self.borderWidth, radius: self.cornerRadius)

                let shadowAnimation = CABasicAnimation(keyPath: "shadowPath")
                shadowAnimation.duration = 0.2
                shadowAnimation.toValue = path.cgPath
                shadowAnimation.isRemovedOnCompletion = true
                self.layer.add(shadowAnimation, forKey: "shadowAnimation")
            }) { (_) in
                self.startActionAnimation()
            }
        }
    }

    fileprivate func show(duration: TimeInterval? = nil) {
        isAnimating = true
        dismissTimer?.invalidate()

        setNeedsLayout()
        performEntranceAnimation {
            guard !self.isPerformingExitAnimation && self.isVisible else {
                return
            }
               
            self.customView?.layoutIfNeeded()

            if let tapRemoveGesture = self.tapToRemoveGestureRecognizer {
                self.containerView?.addGestureRecognizer(tapRemoveGesture)
            }
            if let swipeGesture = self.swipeGestureRecognizer {
                self.containerView?.addGestureRecognizer(swipeGesture)
            }

            self.appearHandler?(self)
            if self.startActionAnimationOnShow {
                self.performActionAnimation()
            }
            self.isAnimating = false
            
            // 优化点：使用 Block 方法防止因为 Target-Action 强引用导致 Timer 内存泄漏
            if let duration = duration {
                self.dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                    self?.hide()
                }
            }
        }
    }

    @objc fileprivate func handleTap(_ gesture: UITapGestureRecognizer) {
        if shouldDismissOnTap { hide() }
        tapHandler?(self)
    }

    @objc fileprivate func handleTapOutside(_ gesture: UITapGestureRecognizer) {
        if !isVisible { return }
        if shouldDismissOnTapOutside { hide() }

        let gestureLocationInContainer = gesture.location(in: containerView)
        if shouldConsiderOriginatingFrameAsPopTip && from.contains(gestureLocationInContainer) {
            tapHandler?(self)
        } else if shouldConsiderCutoutTapSeparately && shouldShowMask && shouldCutoutMask && cutoutPathGenerator(from).contains(gestureLocationInContainer) {
            tapCutoutHandler?(self)
        } else {
            tapOutsideHandler?(self)
        }
    }

    @objc fileprivate func handleSwipeOutside(_ gesture: UITapGestureRecognizer) {
        if shouldDismissOnSwipeOutside { hide() }
        swipeOutsideHandler?(self)
    }

    @objc fileprivate func handleApplicationActive() {
        isApplicationInBackground = false
    }

    @objc fileprivate func handleApplicationResignActive() {
        isApplicationInBackground = true
    }

    // MARK: - 内部动作动画
    
    fileprivate func performActionAnimation() {
        switch actionAnimation {
        case .bounce(let offset):
            shouldBounce = true
            bounceAnimation(offset: offset ?? DefaultBounceOffset)
        case .float(let offsetX, let offsetY):
            floatAnimation(offsetX: offsetX ?? DefaultFloatOffset, offsetY: offsetY ?? DefaultFloatOffset)
        case .pulse(let offset):
            pulseAnimation(offset: offset ?? DefaultPulseOffset)
        case .none:
            return
        }
    }

    fileprivate func dismissActionAnimation(_ completion: (() -> Void)? = nil) {
        shouldBounce = false
        UIView.animate(withDuration: actionAnimationOut / 2, delay: actionDelayOut, options: .beginFromCurrentState, animations: {
            self.transform = .identity
        }) { (_) in
            self.layer.removeAllAnimations()
            completion?()
        }
    }

    fileprivate func bounceAnimation(offset: CGFloat) {
        var offsetX = CGFloat(0)
        var offsetY = CGFloat(0)
        switch direction {
        case .auto, .autoHorizontal, .autoVertical: break
        case .up, .none: offsetY = -offset
        case .left: offsetX = -offset
        case .right: offsetX = offset
        case .down: offsetY = offset
        }

        UIView.animate(withDuration: actionAnimationIn / 10, delay: actionDelayIn, options: [.curveEaseIn, .allowUserInteraction, .beginFromCurrentState], animations: {
            self.transform = CGAffineTransform(translationX: offsetX, y: offsetY)
        }) { (completed) in
            if completed {
                UIView.animate(withDuration: self.actionAnimationIn - self.actionAnimationIn / 10, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                    self.transform = .identity
                }, completion: { (done) in
                    if self.shouldBounce && done {
                        self.bounceAnimation(offset: offset)
                    }
                })
            }
        }
    }

    fileprivate func floatAnimation(offsetX: CGFloat, offsetY: CGFloat) {
        var offsetX = offsetX
        var offsetY = offsetY
        switch direction {
        case .up, .none: offsetY = -offsetY
        case .left: offsetX = -offsetX
        default: break
        }

        UIView.animate(withDuration: actionAnimationIn / 2, delay: actionDelayIn, options: [.curveEaseInOut, .repeat, .autoreverse, .beginFromCurrentState, .allowUserInteraction], animations: {
            self.transform = CGAffineTransform(translationX: offsetX, y: offsetY)
        }, completion: nil)
    }

    fileprivate func pulseAnimation(offset: CGFloat) {
        UIView.animate(withDuration: actionAnimationIn / 2, delay: actionDelayIn, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState, .autoreverse, .repeat], animations: {
            self.transform = CGAffineTransform(scaleX: offset, y: offset)
        }, completion: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        dismissTimer?.invalidate()
    }
}

// MARK: - 贝塞尔曲线辅助方法 (Bezier Path Helpers)
public extension PTTipsView {
    class func pathWith(rect: CGRect, frame: CGRect, direction: PopTipDirection, arrowSize: CGSize, arrowPosition: CGPoint, arrowRadius: CGFloat, borderWidth: CGFloat = 0, radius: CGFloat = 0) -> UIBezierPath {
        var path = UIBezierPath()
        var baloonFrame = CGRect.zero
        
        switch direction {
        case .auto, .autoHorizontal, .autoVertical: break
        case .none:
            baloonFrame = CGRect(x: borderWidth, y: borderWidth, width: frame.width - borderWidth * 2, height: frame.height - borderWidth * 2)
            path = UIBezierPath(roundedRect: baloonFrame, cornerRadius: radius)
        case .down:
            baloonFrame = CGRect(x: 0, y: arrowSize.height, width: rect.width - borderWidth * 2, height: rect.height - arrowSize.height - borderWidth * 2)
            
            let arrowStartPoint = CGPoint(x: arrowPosition.x - arrowSize.width / 2, y: arrowPosition.y + arrowSize.height)
            let arrowEndPoint = CGPoint(x: arrowPosition.x + arrowSize.width / 2, y: arrowPosition.y + arrowSize.height)
            let arrowVertex = arrowPosition
            
            path.move(to: CGPoint(x: arrowStartPoint.x, y: arrowStartPoint.y))
            if let cornerPoint = self.roundCornerCircleCenter(start: arrowStartPoint, vertex: arrowVertex, end: arrowEndPoint, radius: arrowRadius) {
                path.addArc(withCenter: cornerPoint.center, radius: arrowRadius, startAngle: cornerPoint.startAngle, endAngle: cornerPoint.endAngle, clockwise: true)
            }
            path.addLine(to: CGPoint(x: arrowEndPoint.x, y: arrowEndPoint.y))
            path.addLine(to: CGPoint(x: baloonFrame.width - radius, y: baloonFrame.minY))
            path.addArc(withCenter: CGPoint(x: baloonFrame.width - radius, y: baloonFrame.minY + radius), radius:radius, startAngle: CGFloat.pi * 1.5, endAngle: 0, clockwise:true)
            path.addLine(to: CGPoint(x: baloonFrame.width, y: baloonFrame.maxY - radius - borderWidth))
            path.addArc(withCenter: CGPoint(x: baloonFrame.maxX - radius, y: baloonFrame.maxY - radius), radius:radius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
            path.addLine(to: CGPoint(x: baloonFrame.minX + radius + borderWidth, y: baloonFrame.maxY))
            path.addArc(withCenter: CGPoint(x: borderWidth + radius, y: baloonFrame.maxY - radius), radius:radius, startAngle: CGFloat.pi / 2, endAngle: CGFloat.pi, clockwise: true)
            path.addLine(to: CGPoint(x: borderWidth, y: baloonFrame.minY + radius + borderWidth))
            path.addArc(withCenter: CGPoint(x: borderWidth + radius, y: baloonFrame.minY + radius), radius:radius, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 1.5, clockwise: true)
            path.close()

        case .up:
            baloonFrame = CGRect(x: 0, y: 0, width: rect.size.width - borderWidth * 2, height: rect.size.height - arrowSize.height - borderWidth * 2)
            
            let arrowStartPoint = CGPoint(x: arrowPosition.x + arrowSize.width / 2, y: arrowPosition.y - arrowSize.height)
            let arrowEndPoint = CGPoint(x: arrowPosition.x - arrowSize.width / 2, y: arrowPosition.y - arrowSize.height)
            let arrowVertex = arrowPosition
            
            path.move(to: CGPoint(x: arrowStartPoint.x, y: arrowStartPoint.y))
            if let cornerPoint = self.roundCornerCircleCenter(start: arrowStartPoint, vertex: arrowVertex, end: arrowEndPoint, radius: arrowRadius) {
                path.addArc(withCenter: cornerPoint.center, radius: arrowRadius, startAngle: cornerPoint.startAngle, endAngle: cornerPoint.endAngle, clockwise: true)
            }
            path.addLine(to: CGPoint(x: arrowEndPoint.x, y: arrowEndPoint.y))
            path.addLine(to: CGPoint(x: baloonFrame.minX + radius + borderWidth, y: baloonFrame.maxY))
            path.addArc(withCenter: CGPoint(x: borderWidth + radius, y: baloonFrame.maxY - radius), radius:radius, startAngle: CGFloat.pi / 2, endAngle: CGFloat.pi, clockwise: true)
            path.addLine(to: CGPoint(x: borderWidth, y: baloonFrame.minY + radius + borderWidth))
            path.addArc(withCenter: CGPoint(x: baloonFrame.minX + radius + borderWidth, y: baloonFrame.minY + radius), radius:radius, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 1.5, clockwise: true)
            path.addLine(to: CGPoint(x: baloonFrame.width - radius, y: baloonFrame.minY))
            path.addArc(withCenter: CGPoint(x: baloonFrame.width - radius, y: baloonFrame.minY + radius), radius:radius, startAngle: CGFloat.pi * 1.5, endAngle: 0, clockwise:true)
            path.addLine(to: CGPoint(x: baloonFrame.width, y: baloonFrame.maxY - radius - borderWidth))
            path.addArc(withCenter: CGPoint(x: baloonFrame.maxX - radius, y: baloonFrame.maxY - radius), radius:radius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
            path.close()

        case .left:
            baloonFrame = CGRect(x: 0, y: 0, width: rect.size.width - arrowSize.height - borderWidth * 2, height: rect.size.height - borderWidth * 2)
            
            let arrowStartPoint = CGPoint(x: arrowPosition.x - arrowSize.height, y: arrowPosition.y - arrowSize.width / 2)
            let arrowEndPoint = CGPoint(x: arrowPosition.x - arrowSize.height, y: arrowPosition.y + arrowSize.width / 2)
            let arrowVertex = arrowPosition
            
            path.move(to: CGPoint(x: arrowStartPoint.x, y: arrowStartPoint.y))
            if let cornerPoint = self.roundCornerCircleCenter(start: arrowStartPoint, vertex: arrowVertex, end: arrowEndPoint, radius: arrowRadius) {
                path.addArc(withCenter: cornerPoint.center, radius: arrowRadius, startAngle: cornerPoint.startAngle, endAngle: cornerPoint.endAngle, clockwise: true)
            }
            path.addLine(to: CGPoint(x: arrowEndPoint.x, y: arrowEndPoint.y))
            path.addLine(to: CGPoint(x: baloonFrame.width, y: baloonFrame.maxY - radius - borderWidth))
            path.addArc(withCenter: CGPoint(x: baloonFrame.maxX - radius, y: baloonFrame.maxY - radius), radius:radius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
            path.addLine(to: CGPoint(x: baloonFrame.minX + radius + borderWidth, y: baloonFrame.maxY))
            path.addArc(withCenter: CGPoint(x: borderWidth + radius, y: baloonFrame.maxY - radius), radius:radius, startAngle: CGFloat.pi / 2, endAngle: CGFloat.pi, clockwise: true)
            path.addLine(to: CGPoint(x: borderWidth, y: baloonFrame.minY + radius + borderWidth))
            path.addArc(withCenter: CGPoint(x: borderWidth + radius, y: baloonFrame.minY + radius + borderWidth), radius:radius, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 1.5, clockwise: true)
            path.addLine(to: CGPoint(x: baloonFrame.width - radius, y: baloonFrame.minY + borderWidth))
            path.addArc(withCenter: CGPoint(x: baloonFrame.width - radius, y: baloonFrame.minY + radius + borderWidth), radius:radius, startAngle: CGFloat.pi * 1.5, endAngle: 0, clockwise:true)
            path.close()

        case .right:
            baloonFrame = CGRect(x: arrowSize.height, y: 0, width: rect.size.width - arrowSize.height - borderWidth * 2, height: rect.size.height - borderWidth * 2)
            
            let arrowStartPoint = CGPoint(x: arrowPosition.x + arrowSize.height, y: arrowPosition.y + arrowSize.width / 2)
            let arrowEndPoint = CGPoint(x: arrowPosition.x + arrowSize.height, y: arrowPosition.y - arrowSize.width / 2)
            let arrowVertex = arrowPosition
            
            path.move(to: CGPoint(x: arrowStartPoint.x, y: arrowStartPoint.y))
            if let cornerPoint = self.roundCornerCircleCenter(start: arrowStartPoint, vertex: arrowVertex, end: arrowEndPoint, radius: arrowRadius) {
                path.addArc(withCenter: cornerPoint.center, radius: arrowRadius, startAngle: cornerPoint.startAngle, endAngle: cornerPoint.endAngle, clockwise: true)
            }
            path.addLine(to: CGPoint(x: arrowEndPoint.x, y: arrowEndPoint.y))
            path.addLine(to: CGPoint(x: baloonFrame.minX, y: baloonFrame.minY + radius + borderWidth))
            path.addArc(withCenter: CGPoint(x: baloonFrame.minX + radius, y: baloonFrame.minY + radius + borderWidth), radius:radius, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 1.5, clockwise: true)
            path.addLine(to: CGPoint(x: baloonFrame.width - radius, y: baloonFrame.minY + borderWidth))
            path.addArc(withCenter: CGPoint(x: baloonFrame.maxX - radius, y: baloonFrame.minY + radius + borderWidth), radius:radius, startAngle: CGFloat.pi * 1.5, endAngle: 0, clockwise:true)
            path.addLine(to: CGPoint(x: baloonFrame.maxX, y: baloonFrame.maxY - radius))
            path.addArc(withCenter: CGPoint(x: baloonFrame.maxX - radius, y: baloonFrame.maxY - radius), radius:radius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
            path.addLine(to: CGPoint(x: baloonFrame.minX + radius, y: baloonFrame.maxY ))
            path.addArc(withCenter: CGPoint(x: baloonFrame.minX + radius, y: baloonFrame.maxY - radius), radius:radius, startAngle: CGFloat.pi / 2, endAngle: CGFloat.pi, clockwise: true)
            path.close()
          }
          
          return path
    }
    
    private class func roundCornerCircleCenter(start: CGPoint, vertex: CGPoint, end: CGPoint, radius: CGFloat) -> CornerPoint? {
        let firstLineAngle: CGFloat = atan2(vertex.y - start.y, vertex.x - start.x)
        let secondLineAngle: CGFloat = atan2(end.y - vertex.y, end.x - vertex.x)
        
        let firstLineOffset = CGVector(dx: -sin(firstLineAngle) * radius, dy: cos(firstLineAngle) * radius)
        let secondLineOffset = CGVector(dx: -sin(secondLineAngle) * radius, dy: cos(secondLineAngle) * radius)
        
        let x1 = start.x + firstLineOffset.dx
        let y1 = start.y + firstLineOffset.dy
        let x2 = vertex.x + firstLineOffset.dx
        let y2 = vertex.y + firstLineOffset.dy
        let x3 = vertex.x + secondLineOffset.dx
        let y3 = vertex.y + secondLineOffset.dy
        let x4 = end.x + secondLineOffset.dx
        let y4 = end.y + secondLineOffset.dy
        
        let divisor = ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))
        
        if divisor == 0 { return nil }
        
        let intersectionX = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / divisor
        let intersectionY = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / divisor
        
        return CornerPoint(center: CGPoint(x: intersectionX, y: intersectionY),
                           startAngle: firstLineAngle - CGFloat.pi / 2,
                           endAngle: secondLineAngle - CGFloat.pi / 2)
    }
}

// MARK: - 进出场动画执行模块
public extension PTTipsView {

    func performEntranceAnimation(completion: @escaping () -> Void) {
        switch entranceAnimation {
        case .scale:
            entranceScale(completion: completion)
        case .transition:
            entranceTransition(completion: completion)
        case .fadeIn:
            entranceFadeIn(completion: completion)
        case .custom:
            if shouldShowMask { addBackgroundMask(to: containerView) }
            containerView?.addSubview(self)
            entranceAnimationHandler?(completion)
        case .none:
            if shouldShowMask { addBackgroundMask(to: containerView) }
            containerView?.addSubview(self)
            completion()
        }
    }

    func performExitAnimation(completion: @escaping () -> Void) {
        switch exitAnimation {
        case .scale:
            exitScale(completion: completion)
        case .fadeOut:
            exitFadeOut(completion: completion)
        case .custom:
            exitAnimationHandler?(completion)
        case .none:
            completion()
        }
    }

    private func entranceTransition(completion: @escaping () -> Void) {
        transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        switch direction {
        case .up: transform = transform.translatedBy(x: 0, y: -from.origin.y)
        case .down, .none: transform = transform.translatedBy(x: 0, y: (containerView?.frame.height ?? 0) - from.origin.y)
        case .left: transform = transform.translatedBy(x: from.origin.x, y: 0)
        case .right: transform = transform.translatedBy(x: (containerView?.frame.width ?? 0) - from.origin.x, y: 0)
        case .auto, .autoHorizontal, .autoVertical: break
        }
        if shouldShowMask { addBackgroundMask(to: containerView) }
        containerView?.addSubview(self)

        UIView.animate(withDuration: animationIn, delay: delayIn, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.5, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.transform = .identity
            self.backgroundMask?.alpha = 1
        }) { (_) in
            completion()
        }
    }

    private func entranceScale(completion: @escaping () -> Void) {
        transform = CGAffineTransform(scaleX: 0, y: 0)
        if shouldShowMask { addBackgroundMask(to: containerView) }
        containerView?.addSubview(self)

        UIView.animate(withDuration: animationIn, delay: delayIn, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.5, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.transform = .identity
            self.backgroundMask?.alpha = 1
        }) { (_) in
            completion()
        }
    }

    private func entranceFadeIn(completion: @escaping () -> Void) {
        if shouldShowMask { addBackgroundMask(to: containerView) }
        containerView?.addSubview(self)

        alpha = 0
        UIView.animate(withDuration: animationIn, delay: delayIn, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.alpha = 1
            self.backgroundMask?.alpha = 1
        }) { (_) in
            completion()
        }
    }

    private func exitScale(completion: @escaping () -> Void) {
        transform = .identity

        UIView.animate(withDuration: animationOut, delay: delayOut, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
            self.backgroundMask?.alpha = 0
        }) { (_) in
            completion()
        }
    }

    private func exitFadeOut(completion: @escaping () -> Void) {
        alpha = 1

        UIView.animate(withDuration: animationOut, delay: delayOut, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.alpha = 0
            self.backgroundMask?.alpha = 0
        }) { (_) in
            completion()
        }
    }
      
    private func addBackgroundMask(to targetView: UIView?) {
        guard let backgroundMask = backgroundMask, let targetView = targetView else { return }
          
        targetView.addSubview(backgroundMask)

        guard shouldCutoutMask else {
            backgroundMask.backgroundColor = maskColor
            return
        }

        let cutoutView = UIView(frame: backgroundMask.bounds)
        let cutoutShapeMaskLayer = CAShapeLayer()
        let cutoutPath = cutoutPathGenerator(from)
        let path = UIBezierPath(rect: backgroundMask.bounds)

        path.append(cutoutPath)

        cutoutShapeMaskLayer.path = path.cgPath
        cutoutShapeMaskLayer.fillRule = .evenOdd

        cutoutView.layer.mask = cutoutShapeMaskLayer
        cutoutView.clipsToBounds = true
        cutoutView.backgroundColor = maskColor
        cutoutView.isUserInteractionEnabled = false

        backgroundMask.addSubview(cutoutView)
    }
}
