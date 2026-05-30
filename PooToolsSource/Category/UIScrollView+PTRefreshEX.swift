//
//  UIScrollView+PTRefreshEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import ObjectiveC
import SwifterSwift

public enum PTRefreshState: Sendable {
    case idle        // 普通状态
    case pulling     // 松开就可以进行刷新的状态
    case willRefresh    // 松开手，即将刷新的动画过渡状态 (新加入)
    case refreshing  // 正在刷新中的状态
    case noMoreData     // 没有更多数据 (新加入，主要用于 Footer/Trailer)
}

public struct PTRefreshTextConfig: Sendable {
    public var idleText: String
    public var pullingText: String
    public var refreshingText: String
    public var noMoreDataText: String
    public var font: UIFont
    public var textColor: UIColor
    public var dimension: CGFloat
    
    public var showLastTime: Bool
    public var timeFont: UIFont
    public var timeColor: UIColor
    
    public var automaticallyHidden: Bool
    
    /// 动画持续时间 (默认 0.3或0.4秒)
    public var animationDuration: TimeInterval
    /// 弹簧阻尼系数 (0.0 ~ 1.0)，越小越 Q 弹，1.0 为无弹簧效果的平滑移动
    public var springDamping: CGFloat
    
    public var isHapticFeedbackEnabled: Bool
    
    public var showText: Bool
}

@MainActor
public final class PTRefreshConfig {
    
    // 单例入口
    public static let shared = PTRefreshConfig()
    
    private init() {}
    
    // 顶部下拉刷新默认配置
    public var header = PTRefreshTextConfig(idleText: "下拉可以刷新",
                                            pullingText: "松开立即刷新",
                                            refreshingText: "正在刷新数据中...",
                                            noMoreDataText: "没有更多数据了",
                                            font: .systemFont(ofSize: 14),
                                            textColor: .gray,
                                            dimension: 54.0,
                                            showLastTime: true,
                                            timeFont: .systemFont(ofSize: 12),
                                            timeColor: .gray,
                                            automaticallyHidden: false,
                                            animationDuration: 0.4,
                                            springDamping: 0.7,
                                            isHapticFeedbackEnabled: true,
                                            showText:false
    )
    
    // 底部上拉加载默认配置 (默认关闭时间显示，如需可在此改为 true)
    public var footer = PTRefreshTextConfig(idleText: "上拉可以加载更多",
                                            pullingText: "松开立即加载更多",
                                            refreshingText: "正在加载更多数据...",
                                            noMoreDataText: "到底了，没有更多数据了",
                                            font: .systemFont(ofSize: 14),
                                            textColor: .gray,
                                            dimension: 54.0,
                                            showLastTime: false,
                                            timeFont: .systemFont(ofSize: 12),
                                            timeColor: .gray,
                                            automaticallyHidden: true,
                                            animationDuration: 0.3,
                                            springDamping: 1.0,
                                            isHapticFeedbackEnabled: false,
                                            showText:true
    )
    
    // 左/右侧加载通常因空间太小不显示时间，默认给 false
    public var leftHeader = PTRefreshTextConfig(idleText: "向右\n滑动",
                                                pullingText: "松开\n刷新",
                                                refreshingText: "刷新\n中...",
                                                noMoreDataText: "无\n数\n据",
                                                font: .systemFont(ofSize: 12),
                                                textColor: .gray,
                                                dimension: 60.0,
                                                showLastTime: false,
                                                timeFont: .systemFont(ofSize: 10),
                                                timeColor: .gray,
                                                automaticallyHidden: false,
                                                animationDuration: 0.3,
                                                springDamping: 1.0 ,
                                                isHapticFeedbackEnabled: false,
                                                showText:true
    )
    
    public var trailer = PTRefreshTextConfig(idleText: "滑动\n加载",
                                             pullingText: "松开\n加载",
                                             refreshingText: "加载\n中...",
                                             noMoreDataText: "到\n头\n了",
                                             font: .systemFont(ofSize: 12),
                                             textColor: .gray,
                                             dimension: 60.0,
                                             showLastTime: false,
                                             timeFont: .systemFont(ofSize: 10),
                                             timeColor: .gray,
                                             automaticallyHidden: false,
                                             animationDuration: 0.3,
                                             springDamping: 1.0,
                                             isHapticFeedbackEnabled: false,
                                             showText:true
    )
}

fileprivate struct AssociatedKeys {
    @MainActor static var headerKey: Void?
    @MainActor static var footerKey: Void?
    @MainActor static var trailerKey: Void?
    @MainActor static var leftHeaderKey: Void?
}

@MainActor
open class PTRefreshComponent: UIView {
    
    // MARK: - 基础属性
    public weak var scrollView: UIScrollView?
    private var offsetObservation: NSKeyValueObservation?
    private var sizeObservation: NSKeyValueObservation?
    
    private var insetObservation: NSKeyValueObservation?
    
    // 异步任务
    public let action: @MainActor () async -> Void
    public var currentTask: Task<Void, Never>?
    
    // UI 控件（改为 public 或 internal，方便子类布局）
    public let textLabel = UILabel()
    public let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - 新增的高级特性配置
    /// 触发刷新时的临界比例 (默认 1.0，即拉出 100% 尺寸时触发)
    public var triggerAutomaticallyRefreshPercent: CGFloat = 1.0
    
    /// 拖拽进度 (0.0 ~ 1.0+)，可以监听此属性来做动画
    public var pullingPercent: CGFloat = 0.0 {
        didSet {
            guard oldValue != pullingPercent else { return }
            pullingPercentDidChange(percent: pullingPercent)
            pullingPercentHandler?(pullingPercent)
        }
    }
    
    /// 进度回调闭包
    public var pullingPercentHandler: (@MainActor (CGFloat) -> Void)?
    
    public var stateChangedHandler: (@MainActor (PTRefreshState) -> Void)?
    
    /// 开发者局部自定义的尺寸 (优先级高于全局配置)
    public var customDimension: CGFloat?
    
    // MARK: - 局部配置缓存
    // 存储开发者为该实例单独设置的属性
    public var customStateTitles: [PTRefreshState: String] = [:]
    public var customFont: UIFont?
    public var customTextColor: UIColor?
    
    // 外部塞入的完全自定义视图
    public var customView: UIView?

    // 状态机
    public var state: PTRefreshState = .idle {
        didSet {
            guard oldValue != state else { return }
            if state == .pulling && isHapticEnabled {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
            stateDidChanged(from: oldValue, to: state)
            stateChangedHandler?(state)
        }
    }
    // MARK: - 新增：时间标签与持久化属性
    public let timeLabel = UILabel()
    
    /// 用于在 UserDefaults 中存取时间的唯一 Key
    public var lastTimeKey: String? {
        didSet { updateTimeLabel() }
    }
    
    // 局部 UI 缓存 (新增时间相关)
    public var customShowLastTime: Bool?
    public var customTimeFont: UIFont?
    public var customTimeColor: UIColor?

    public var customAutomaticallyHidden: Bool?
    
    // MARK: - 局部动画与阻尼缓存
    public var customAnimationDuration: TimeInterval?
    public var customSpringDamping: CGFloat?
        
    public var customHapticFeedback: Bool?
    
    public var customShowText: Bool?
    
    // MARK: - 初始化
    public init(action: @escaping @MainActor () async -> Void) {
        self.action = action
        super.init(frame: .zero)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 链式调用配置接口
    /// 单独设置某个状态下的文字
    @discardableResult
    public func setTitle(_ title: String, for state: PTRefreshState) -> Self {
        customStateTitles[state] = title
        // 如果刚好是当前状态，立即刷新 UI
        if self.state == state {
            stateDidChanged(from: state, to: state)
        }
        return self
    }
    
    /// 单独设置文本颜色
    @discardableResult
    public func setTextColor(_ color: UIColor) -> Self {
        self.customTextColor = color
        self.textLabel.textColor = color
        return self
    }
    
    /// 单独设置文本字体
    @discardableResult
    public func setFont(_ font: UIFont) -> Self {
        self.customFont = font
        self.textLabel.font = font
        return self
    }
    
    /// 设置局部高度/宽度
    @discardableResult
    public func setDimension(_ dimension: CGFloat) -> Self {
        self.customDimension = dimension; return self
    }
    
    /// 监听拖拽进度回调 (用于自定义动画)
    @discardableResult
    public func onPullingPercentChanged(_ handler: @escaping @MainActor (CGFloat) -> Void) -> Self {
        self.pullingPercentHandler = handler; return self
    }
            
    /// 配置是否显示最后更新时间
    @discardableResult
    public func setShowLastTime(_ show: Bool) -> Self {
        self.customShowLastTime = show
        self.setNeedsLayout()
        return self
    }
    
    /// 单独设置时间文本颜色
    @discardableResult
    public func setTimeColor(_ color: UIColor) -> Self {
        self.customTimeColor = color
        self.timeLabel.textColor = color
        return self
    }
    
    /// 单独设置时间文本字体
    @discardableResult
    public func setTimeFont(_ font: UIFont) -> Self {
        self.customTimeFont = font
        self.timeLabel.font = font
        return self
    }
    
    /// 设置记录时间的唯一标识
    @discardableResult
    public func setLastTimeKey(_ key: String) -> Self {
        self.lastTimeKey = key
        return self
    }

    @discardableResult
    public func setAutomaticallyHidden(_ hidden: Bool) -> Self {
        self.customAutomaticallyHidden = hidden
        // 主动触发一次隐藏状态检查 (需要子类重写 checkAutomaticallyHidden 来实现)
        self.checkAutomaticallyHidden()
        return self
    }
    
    open func checkAutomaticallyHidden() {}
    
    /// 塞入完全自定义的 View (原生文本和菊花会被隐藏)
    @discardableResult
    public func setCustomView(_ view: UIView) -> Self {
        self.customView?.removeFromSuperview()
        self.customView = view
        self.addSubview(view)
        
        // 隐藏原生的所有控件
        self.textLabel.isHidden = true
        self.timeLabel.isHidden = true
        self.activityIndicator.isHidden = true
        
        self.setNeedsLayout()
        return self
    }

    /// 单独设置该组件的回弹弹簧阻尼 (0.0 ~ 1.0)
    @discardableResult
    public func setSpringDamping(_ damping: CGFloat) -> Self {
        self.customSpringDamping = damping
        return self
    }
    
    /// 单独设置该组件的状态切换动画时长
    @discardableResult
    public func setAnimationDuration(_ duration: TimeInterval) -> Self {
        self.customAnimationDuration = duration
        return self
    }
    
    /// 监听状态变化 (配合 customView 使用最佳)
    @discardableResult
    public func onStateChanged(_ handler: @escaping @MainActor (PTRefreshState) -> Void) -> Self {
        self.stateChangedHandler = handler
        return self
    }

    @discardableResult
    public func setHapticFeedback(_ enabled: Bool) -> Self {
        self.customHapticFeedback = enabled
        return self
    }
    
    @discardableResult
    public func setShowText(_ show: Bool) -> Self {
        self.customShowText = show
        self.setNeedsLayout()
        return self
    }

    /// 供子类重写的属性：当前是否开启震动
    open var isHapticEnabled: Bool {
        return customHapticFeedback ?? false
    }

    public var ignoredContentInsetTop: CGFloat = 0.0
    public var ignoredContentInsetBottom: CGFloat = 0.0
    public var ignoredContentInsetLeft: CGFloat = 0.0
    public var ignoredContentInsetRight: CGFloat = 0.0
    
    @discardableResult
    public func setIgnoredContentInsetTop(_ inset: CGFloat) -> Self {
        self.ignoredContentInsetTop = inset
        return self
    }
    
    @discardableResult
    public func setIgnoredContentInsetBottom(_ inset: CGFloat) -> Self {
        self.ignoredContentInsetBottom = inset
        return self
    }
    
    @discardableResult
    public func setIgnoredContentInsetLeft(_ inset: CGFloat) -> Self {
        self.ignoredContentInsetLeft = inset
        return self
    }
    
    @discardableResult
    public func setIgnoredContentInsetRight(_ inset: CGFloat) -> Self {
        self.ignoredContentInsetRight = inset
        return self
    }

    /// 工具方法：给子类调用的获取最终文案的方法 (局部覆盖 > 全局)
    public func resolvedTitle(for state: PTRefreshState, globalConfig: PTRefreshTextConfig) -> String {
        if let customTitle = customStateTitles[state] {
            return customTitle
        }
        switch state {
        case .idle: return globalConfig.idleText
        case .pulling: return globalConfig.pullingText
        case .willRefresh: return globalConfig.pullingText // 过渡时使用 pulling 的文字
        case .refreshing: return globalConfig.refreshingText
        case .noMoreData: return globalConfig.noMoreDataText
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        // 新增：如果外部塞入了 customView，默认让它铺满整个刷新区域
        if let customView = customView {
            customView.frame = self.bounds
        }
    }

    // MARK: - 公共方法 (供子类重写或调用)
    open func setupUI() {
        textLabel.textAlignment = .center
        timeLabel.textAlignment = .center
        activityIndicator.hidesWhenStopped = true
        addSubviews([textLabel,timeLabel,activityIndicator])
        state = .idle
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        offsetObservation?.invalidate()
        sizeObservation?.invalidate()
        insetObservation?.invalidate() // 🌟 销毁旧监听
        guard let scrollView = newSuperview as? UIScrollView else { return }
        self.scrollView = scrollView
        
        // 统一注册 KVO
        sizeObservation = scrollView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
            PTGCDManager.shared.runOnMain { [weak self] in
                self?.scrollViewContentSizeDidChange()
            }
        }
        
        offsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
            PTGCDManager.shared.runOnMain {  [weak self] in
                self?.scrollViewContentOffsetDidChange()
            }
        }
        
        insetObservation = scrollView.observe(\.contentInset, options: [.new]) { [weak self] _, _ in
            PTGCDManager.shared.runOnMain {  [weak self] in
                self?.scrollViewContentInsetDidChange()
            }
        }
    }
    
    // MARK: - 子类重写入口点
    open func scrollViewContentSizeDidChange() {}
    open func scrollViewContentOffsetDidChange() {}
    open func scrollViewContentInsetDidChange() {}
    open func stateDidChanged(from oldState: PTRefreshState, to newState: PTRefreshState) {}
    
    open func pullingPercentDidChange(percent: CGFloat) {}
    
    // 默认的手势松开逻辑：如果是 pulling 状态，就触发刷新
    open func scrollViewPanStateDidChange() {
        if state == .pulling {
            state = .willRefresh
        }
    }
    
    // MARK: - 行为控制
    public func beginRefreshing() {
        guard state == .idle || state == .pulling else { return }
        state = .willRefresh
    }
    
    public func endRefreshing() {
        guard state == .refreshing else { return }
        state = .idle
        saveCurrentTime()
    }
    
    // 新增：没有更多数据
    public func endRefreshingWithNoMoreData() {
        state = .noMoreData
        saveCurrentTime() // 无更多数据时，也可以视作一次数据更新完毕
    }
    
    // 新增：重置数据状态
    public func resetNoMoreData() {
        state = .idle
    }
    
    public func executeAction() {
        currentTask?.cancel()
        currentTask = Task { @MainActor in
            await self.action()
        }
    }
    
    private func saveCurrentTime() {
        guard let key = lastTimeKey else { return }
        UserDefaults.standard.set(Date(), forKey: key)
        updateTimeLabel()
    }
    
    /// 更新时间文本的具体逻辑
    public func updateTimeLabel() {
        guard let key = lastTimeKey else {
            timeLabel.text = "最后更新：无记录"
            return
        }
        
        if let lastDate = UserDefaults.standard.object(forKey: key) as? Date {
            // 简单的格式化，如果你需要 "今天/昨天" 逻辑，可在此处扩展 DateFormatter
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString = formatter.string(from: lastDate)
            timeLabel.text = "最后更新：\(dateString)"
        } else {
            timeLabel.text = "最后更新：无记录"
        }
    }
}

@MainActor
open class PTRefreshHeader: PTRefreshComponent {
    
    public override var isHapticEnabled: Bool {
        return customHapticFeedback ?? PTRefreshConfig.shared.header.isHapticFeedbackEnabled
    }
    
    private var originalContentInsetTop: CGFloat = 0
    private var componentHeight: CGFloat { customDimension ?? PTRefreshConfig.shared.header.dimension }
    
    public override func setupUI() {
        super.setupUI()
        self.autoresizingMask = .flexibleWidth
        
        textLabel.font = self.customFont ?? PTRefreshConfig.shared.header.font
        textLabel.textColor = self.customTextColor ?? PTRefreshConfig.shared.header.textColor
        timeLabel.font = self.customTimeFont ?? PTRefreshConfig.shared.header.timeFont
        timeLabel.textColor = self.customTimeColor ?? PTRefreshConfig.shared.header.timeColor
        
        // 🌟 覆盖基类行为：让菊花不自动隐藏，而是通过 Alpha 渐变控制
        activityIndicator.hidesWhenStopped = false
        activityIndicator.alpha = 0.0
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let showText = customShowText ?? PTRefreshConfig.shared.header.showText
        let showTime = customShowLastTime ?? PTRefreshConfig.shared.header.showLastTime
        
        // 文本显示控制
        textLabel.isHidden = !showText
        timeLabel.isHidden = (!showText || !showTime) // 如果主文案都不显示，时间也强制隐藏
        
        if showText {
            // 文字模式排版
            if showTime {
                let halfHeight = bounds.height / 2.0
                textLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: halfHeight)
                timeLabel.frame = CGRect(x: 0, y: halfHeight, width: bounds.width, height: halfHeight)
            } else {
                textLabel.frame = bounds
            }
            activityIndicator.center = CGPoint(x: bounds.midX - 50, y: bounds.midY)
            activityIndicator.alpha = 1.0 // 文字模式下，直接显示
            activityIndicator.transform = .identity
            activityIndicator.hidesWhenStopped = true // 回归原始 MJ 行为
        } else {
            // 🌟 极简原生模式排版：菊花独占中心
            activityIndicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
            activityIndicator.hidesWhenStopped = false // 依靠 pullingPercent 处理渐变
        }
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let scrollView = self.scrollView else { return }
        
        self.originalContentInsetTop = scrollView.contentInset.top
        self.frame = CGRect(x: 0, y: -(componentHeight + ignoredContentInsetTop), width: scrollView.bounds.width, height: componentHeight)
        updateTimeLabel()
    }
    
    public override func scrollViewContentInsetDidChange() {
        guard let scrollView = scrollView else { return }
        // 🌟 核心：只有在空闲状态下，才认为是业务方手动修改了 inset，我们将其作为新的还原点
        if state == .idle {
            self.originalContentInsetTop = scrollView.contentInset.top
        }
    }

    public override func scrollViewContentOffsetDidChange() {
        guard let scrollView = scrollView else { return }
        if state == .refreshing || state == .willRefresh { return }
        
        let offsetY = scrollView.contentOffset.y
        let happenOffsetY = -originalContentInsetTop + ignoredContentInsetTop
        if offsetY >= happenOffsetY {
            self.pullingPercent = 0.0
            return
        }
        self.pullingPercent = (happenOffsetY - offsetY) / componentHeight
        let pullingOffsetY = happenOffsetY - (componentHeight * triggerAutomaticallyRefreshPercent)
        
        if scrollView.isDragging {
            if state == .idle && offsetY < pullingOffsetY {
                state = .pulling
            } else if state == .pulling && offsetY >= pullingOffsetY {
                state = .idle
            }
        } else {
            // 🌟 终极修复：手指松开了！此时如果正好是 pulling 状态，瞬间锁定并触发刷新！
            if state == .pulling {
                self.beginRefreshing()
            }
        }
    }

    // MARK: - 🌟 新增：下拉时的菊花浮现与缩放动画
    public override func pullingPercentDidChange(percent: CGFloat) {
        super.pullingPercentDidChange(percent: percent)
        
        let showText = customShowText ?? PTRefreshConfig.shared.header.showText
        if !showText && state != .refreshing {
            // 在极简模式下，菊花随着手指下拉慢慢浮现、放大
            activityIndicator.alpha = percent
            let scale = max(0.5, min(1.0, percent)) // 从 0.5 放大到 1.0
            activityIndicator.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
    public override func stateDidChanged(from oldState: PTRefreshState, to newState: PTRefreshState) {
        guard let scrollView = scrollView else { return }
        
        textLabel.text = resolvedTitle(for: newState, globalConfig: PTRefreshConfig.shared.header)
        
        let duration = customAnimationDuration ?? PTRefreshConfig.shared.header.animationDuration
        let damping = customSpringDamping ?? PTRefreshConfig.shared.header.springDamping
        let showText = customShowText ?? PTRefreshConfig.shared.header.showText
        
        switch newState {
        case .idle, .noMoreData:
            activityIndicator.stopAnimating()
            if oldState == .refreshing || oldState == .willRefresh {
                UIView.animate(
                    withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut]
                ) {
                    scrollView.contentInset.top = self.originalContentInsetTop
                    // 如果是极简模式，缩回时菊花淡出
                    if !showText { self.activityIndicator.alpha = 0.0 }
                }
            }
            
        case .pulling:
            break
        case .willRefresh:
            UIView.animate(
                withDuration: duration - 0.1, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 1.0, options: [.allowUserInteraction, .curveEaseInOut]
            ) {
                let top = self.originalContentInsetTop + self.componentHeight
                scrollView.contentInset.top = top
                scrollView.contentOffset.y = -top
            } completion: { _ in
                self.state = .refreshing
            }
            
        case .refreshing:
            if !showText {
                activityIndicator.alpha = 1.0
                activityIndicator.transform = .identity
            }
            activityIndicator.startAnimating()
            self.executeAction()
        }
    }
}

@MainActor
public final class PTRefreshFooter: PTRefreshComponent {
    
    public override var isHapticEnabled: Bool {
        return customHapticFeedback ?? PTRefreshConfig.shared.footer.isHapticFeedbackEnabled
    }

    private var originalContentInsetBottom: CGFloat = 0
    private var componentHeight: CGFloat { customDimension ?? PTRefreshConfig.shared.footer.dimension }
    
    public override func setupUI() {
        super.setupUI()
        self.autoresizingMask = .flexibleWidth
        
        // 1. 初始化时应用字体和颜色 (局部优先 -> 全局配置中心后补)
        textLabel.font = self.customFont ?? PTRefreshConfig.shared.footer.font
        textLabel.textColor = self.customTextColor ?? PTRefreshConfig.shared.footer.textColor
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = bounds
        activityIndicator.center = CGPoint(x: bounds.midX - 50, y: bounds.midY)
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let scrollView = self.scrollView else { return }
        self.originalContentInsetBottom = scrollView.contentInset.bottom
        checkAutomaticallyHidden()
    }
    
    // MARK: - 动态检测隐藏逻辑
    public override func checkAutomaticallyHidden() {
        guard let scrollView = scrollView else { return }
        
        // 获取最终的配置：优先读取局部 custom 属性，再读全局 shared 配置
        let autoHidden = customAutomaticallyHidden ?? PTRefreshConfig.shared.footer.automaticallyHidden
        
        if autoHidden {
            // 核心判断公式：内容高度 == 0，或者 内容高度不足以撑开当前 ScrollView 的可视高度
            let isShorterThanScreen = scrollView.contentSize.height <= scrollView.bounds.height
            self.isHidden = isShorterThanScreen
        } else {
            // 如果开发者明确关闭了自动隐藏，就永远显示
            self.isHidden = false
        }
    }
    
    public override func scrollViewContentInsetDidChange() {
        guard let scrollView = scrollView else { return }
        if state == .idle {
            self.originalContentInsetBottom = scrollView.contentInset.bottom
        }
    }

    public override func scrollViewContentSizeDidChange() {
        guard let scrollView = scrollView else { return }
        let footerY = scrollView.contentSize.height
        self.frame = CGRect(x: 0, y: footerY, width: scrollView.bounds.width, height: componentHeight)
        checkAutomaticallyHidden()
    }
    
    public override func scrollViewContentOffsetDidChange() {
        guard let scrollView = scrollView else { return }
        if self.isHidden { return }
        if state == .noMoreData || state == .refreshing || state == .willRefresh { return }
        guard scrollView.contentSize.height > scrollView.bounds.height else { return }
        
        let offsetY = scrollView.contentOffset.y
        let judgeOffsetY = scrollView.contentSize.height - scrollView.bounds.height + originalContentInsetBottom - ignoredContentInsetBottom
        if offsetY <= judgeOffsetY {
            self.pullingPercent = 0.0
            return
        }
        self.pullingPercent = (offsetY - judgeOffsetY) / componentHeight
        let pullingOffsetY = judgeOffsetY + (componentHeight * triggerAutomaticallyRefreshPercent)
        
        if scrollView.isDragging {
            if state == .idle && offsetY > pullingOffsetY {
                state = .pulling
            } else if state == .pulling && offsetY <= pullingOffsetY {
                state = .idle
            }
        } else {
            // 🌟 终极修复：手指松开了！
            if state == .pulling {
                self.beginRefreshing()
            }
        }
    }

    public override func stateDidChanged(from oldState: PTRefreshState, to newState: PTRefreshState) {
        guard let scrollView = scrollView else { return }
        textLabel.text = resolvedTitle(for: newState, globalConfig: PTRefreshConfig.shared.footer)
        
        // 获取动画阻尼配置
        let duration = customAnimationDuration ?? PTRefreshConfig.shared.footer.animationDuration
        let damping = customSpringDamping ?? PTRefreshConfig.shared.footer.springDamping
        
        switch newState {
        case .idle:
            activityIndicator.stopAnimating()
            if oldState == .refreshing || oldState == .willRefresh {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut]) {
                    scrollView.contentInset.bottom = self.originalContentInsetBottom
                }
            }
        case .pulling:
            break
            
        case .willRefresh:
            UIView.animate(withDuration: duration - 0.1, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 1.0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                scrollView.contentInset.bottom = self.originalContentInsetBottom + self.componentHeight
            }) { _ in
                self.state = .refreshing
            }
            
        case .refreshing:
            activityIndicator.startAnimating()
            self.executeAction()
            
        case .noMoreData:
            activityIndicator.stopAnimating()
            if oldState == .refreshing || oldState == .willRefresh {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut]) {
                    scrollView.contentInset.bottom = self.originalContentInsetBottom
                }
            }
        }
    }
}

@MainActor
public final class PTRefreshTrailer: PTRefreshComponent {
    
    public override var isHapticEnabled: Bool {
        return customHapticFeedback ?? PTRefreshConfig.shared.trailer.isHapticFeedbackEnabled
    }

    private var originalContentInsetRight: CGFloat = 0
    // 获取当前最终使用的宽度尺寸
    private var componentWidth: CGFloat { customDimension ?? PTRefreshConfig.shared.trailer.dimension }
    
    public override func setupUI() {
        super.setupUI()
        self.autoresizingMask = [.flexibleHeight]
        textLabel.numberOfLines = 0
        
        // 标题配置
        textLabel.font = self.customFont ?? PTRefreshConfig.shared.trailer.font
        textLabel.textColor = self.customTextColor ?? PTRefreshConfig.shared.trailer.textColor
        
        // 时间配置
        timeLabel.numberOfLines = 0 // 支持竖排
        timeLabel.font = self.customTimeFont ?? PTRefreshConfig.shared.trailer.timeFont
        timeLabel.textColor = self.customTimeColor ?? PTRefreshConfig.shared.trailer.timeColor
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let showTime = customShowLastTime ?? PTRefreshConfig.shared.trailer.showLastTime
        timeLabel.isHidden = !showTime
        
        if showTime {
            // 横向排版：如果强制开启时间显示，可以上下平分
            let halfHeight = bounds.height / 2.0
            activityIndicator.center = CGPoint(x: bounds.midX, y: halfHeight - 30)
            textLabel.frame = CGRect(x: 0, y: halfHeight - 15, width: bounds.width, height: halfHeight)
            timeLabel.frame = CGRect(x: 0, y: halfHeight, width: bounds.width, height: halfHeight)
        } else {
            let centerY = bounds.midY
            let centerX = bounds.midX
            activityIndicator.center = CGPoint(x: centerX, y: centerY - 20)
            textLabel.frame = CGRect(x: 0, y: centerY, width: bounds.width, height: 40)
        }
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let scrollView = self.scrollView else { return }
        self.originalContentInsetRight = scrollView.contentInset.right
        
        updateTimeLabel()
        // 挂载时，检查一次是否需要隐藏
        checkAutomaticallyHidden()
    }
    
    // MARK: - 动态检测隐藏逻辑 (宽度判定)
    public override func checkAutomaticallyHidden() {
        guard let scrollView = scrollView else { return }
        
        let autoHidden = customAutomaticallyHidden ?? PTRefreshConfig.shared.trailer.automaticallyHidden
        
        if autoHidden {
            // 核心判断公式：内容宽度 <= 容器视口宽度
            let isShorterThanScreen = scrollView.contentSize.width <= scrollView.bounds.width
            self.isHidden = isShorterThanScreen
        } else {
            self.isHidden = false
        }
    }
    
    public override func scrollViewContentInsetDidChange() {
        guard let scrollView = scrollView else { return }
        if state == .idle {
            self.originalContentInsetRight = scrollView.contentInset.right
        }
    }

    public override func scrollViewContentSizeDidChange() {
        guard let scrollView = scrollView else { return }
        let trailerX = scrollView.contentSize.width
        self.frame = CGRect(x: trailerX, y: 0, width: componentWidth, height: scrollView.bounds.height)
        
        // 内容尺寸一变，立刻重新判断是否需要隐藏
        checkAutomaticallyHidden()
    }
    
    public override func scrollViewContentOffsetDidChange() {
        guard let scrollView = scrollView else { return }
        if self.isHidden { return }
        if state == .noMoreData || state == .refreshing || state == .willRefresh { return }
        guard scrollView.contentSize.width > scrollView.bounds.width else { return }
        
        let offsetX = scrollView.contentOffset.x
        let judgeOffsetX = scrollView.contentSize.width - scrollView.bounds.width + originalContentInsetRight - ignoredContentInsetRight
        if offsetX <= judgeOffsetX {
            self.pullingPercent = 0.0
            return
        }
        self.pullingPercent = (offsetX - judgeOffsetX) / componentWidth
        let pullingOffsetX = judgeOffsetX + (componentWidth * triggerAutomaticallyRefreshPercent)
        
        if scrollView.isDragging {
            if state == .idle && offsetX > pullingOffsetX {
                state = .pulling
            } else if state == .pulling && offsetX <= pullingOffsetX {
                state = .idle
            }
        } else {
            // 🌟 终极修复：手指松开了！
            if state == .pulling {
                self.beginRefreshing()
            }
        }
    }

    public override func stateDidChanged(from oldState: PTRefreshState, to newState: PTRefreshState) {
        guard let scrollView = scrollView else { return }
        textLabel.text = resolvedTitle(for: newState, globalConfig: PTRefreshConfig.shared.trailer)
        
        // 获取动画阻尼配置
        let duration = customAnimationDuration ?? PTRefreshConfig.shared.trailer.animationDuration
        let damping = customSpringDamping ?? PTRefreshConfig.shared.trailer.springDamping
        
        switch newState {
        case .idle:
            activityIndicator.stopAnimating()
            if oldState == .refreshing || oldState == .willRefresh {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut]) {
                    scrollView.contentInset.right = self.originalContentInsetRight
                }
            }
            
        case .pulling:
            break
            
        case .willRefresh:
            UIView.animate(withDuration: duration - 0.1, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 1.0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                scrollView.contentInset.right = self.originalContentInsetRight + self.componentWidth
            }) { _ in
                self.state = .refreshing
            }
            
        case .refreshing:
            activityIndicator.startAnimating()
            self.executeAction()
            
        case .noMoreData:
            activityIndicator.stopAnimating()
            if oldState == .refreshing || oldState == .willRefresh {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut]) {
                    scrollView.contentInset.right = self.originalContentInsetRight
                }
            }
        }
    }
}

@MainActor
public final class PTRefreshLeftHeader: PTRefreshComponent {
    
    public override var isHapticEnabled: Bool {
        return customHapticFeedback ?? PTRefreshConfig.shared.leftHeader.isHapticFeedbackEnabled
    }

    private var originalContentInsetLeft: CGFloat = 0
    // 获取当前最终使用的宽度尺寸
    private var componentWidth: CGFloat { customDimension ?? PTRefreshConfig.shared.leftHeader.dimension }
    
    public override func setupUI() {
        super.setupUI()
        self.autoresizingMask = [.flexibleHeight]
        textLabel.numberOfLines = 0 // 支持竖排显示
        textLabel.font = self.customFont ?? PTRefreshConfig.shared.leftHeader.font
        textLabel.textColor = self.customTextColor ?? PTRefreshConfig.shared.leftHeader.textColor
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let centerY = bounds.midY
        let centerX = bounds.midX
        activityIndicator.center = CGPoint(x: centerX, y: centerY - 20)
        textLabel.frame = CGRect(x: 0, y: centerY, width: bounds.width, height: 40)
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let scrollView = self.scrollView else { return }
        
        self.originalContentInsetLeft = scrollView.contentInset.left
        self.frame = CGRect(
                    x: -(componentWidth + ignoredContentInsetLeft),
                    y: 0,
                    width: componentWidth,
                    height: scrollView.bounds.height
                )
    }
    
    public override func scrollViewContentInsetDidChange() {
        guard let scrollView = scrollView else { return }
        if state == .idle {
            self.originalContentInsetLeft = scrollView.contentInset.left
        }
    }

    public override func scrollViewContentOffsetDidChange() {
        guard let scrollView = scrollView else { return }
        if state == .refreshing || state == .willRefresh { return }
        
        let offsetX = scrollView.contentOffset.x
        let happenOffsetX = -originalContentInsetLeft + ignoredContentInsetLeft
        if offsetX >= happenOffsetX {
            self.pullingPercent = 0.0
            return
        }
        self.pullingPercent = (happenOffsetX - offsetX) / componentWidth
        let pullingOffsetX = happenOffsetX - (componentWidth * triggerAutomaticallyRefreshPercent)
        
        if scrollView.isDragging {
            if state == .idle && offsetX < pullingOffsetX {
                state = .pulling
            } else if state == .pulling && offsetX >= pullingOffsetX {
                state = .idle
            }
        } else {
            // 🌟 终极修复：手指松开了！
            if state == .pulling {
                self.beginRefreshing()
            }
        }
    }

    public override func stateDidChanged(from oldState: PTRefreshState, to newState: PTRefreshState) {
        guard let scrollView = scrollView else { return }
        textLabel.text = resolvedTitle(for: newState, globalConfig: PTRefreshConfig.shared.leftHeader)
        
        // 获取动画阻尼配置
        let duration = customAnimationDuration ?? PTRefreshConfig.shared.leftHeader.animationDuration
        let damping = customSpringDamping ?? PTRefreshConfig.shared.leftHeader.springDamping
        
        switch newState {
        case .idle, .noMoreData:
            activityIndicator.stopAnimating()
            if oldState == .refreshing || oldState == .willRefresh {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut]) {
                    scrollView.contentInset.left = self.originalContentInsetLeft
                }
            }
            
        case .pulling:
            break
            
        case .willRefresh:
            UIView.animate(withDuration: duration - 0.1, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 1.0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                let left = self.originalContentInsetLeft + self.componentWidth
                scrollView.contentInset.left = left
                scrollView.contentOffset.x = -left
            }) { _ in
                self.state = .refreshing
            }
            
        case .refreshing:
            activityIndicator.startAnimating()
            self.executeAction()
        }
    }
}

public extension PTPOP where Base: UIScrollView {
    @MainActor
    var header: PTRefreshHeader? {
        get {
            objc_getAssociatedObject(base, &AssociatedKeys.headerKey) as? PTRefreshHeader
        }
        set {
            if let oldHeader = header {
                oldHeader.removeFromSuperview()
            }
            if let newHeader = newValue {
                base.insertSubview(newHeader, at: 0)
            }
            objc_setAssociatedObject(base, &AssociatedKeys.headerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @MainActor
    var footer: PTRefreshFooter? {
        get {
            objc_getAssociatedObject(base, &AssociatedKeys.footerKey) as? PTRefreshFooter
        }
        set {
            if let oldFooter = footer {
                oldFooter.removeFromSuperview()
            }
            if let newFooter = newValue {
                base.insertSubview(newFooter, at: 0)
            }
            objc_setAssociatedObject(base, &AssociatedKeys.footerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @MainActor
    var trailer: PTRefreshTrailer? {
        get {
            objc_getAssociatedObject(base, &AssociatedKeys.trailerKey) as? PTRefreshTrailer
        }
        set {
            if let oldTrailer = trailer {
                oldTrailer.removeFromSuperview()
            }
            if let newTrailer = newValue {
                base.insertSubview(newTrailer, at: 0)
            }
            objc_setAssociatedObject(base, &AssociatedKeys.trailerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @MainActor
    var leftHeader: PTRefreshLeftHeader? {
        get {
            objc_getAssociatedObject(base, &AssociatedKeys.leftHeaderKey) as? PTRefreshLeftHeader
        }
        set {
            if let oldHeader = leftHeader {
                oldHeader.removeFromSuperview()
            }
            if let newHeader = newValue {
                base.insertSubview(newHeader, at: 0)
            }
            objc_setAssociatedObject(base, &AssociatedKeys.leftHeaderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @MainActor
    var autoFooter: PTRefreshAutoFooter? {
        get {
            objc_getAssociatedObject(base, &AssociatedKeys.footerKey) as? PTRefreshAutoFooter // 共用 footerKey，保证同一时间只有一个底部加载器
        }
        set {
            if let oldFooter = footer { oldFooter.removeFromSuperview() }
            if let oldAutoFooter = autoFooter { oldAutoFooter.removeFromSuperview() }
            
            if let newFooter = newValue {
                base.insertSubview(newFooter, at: 0)
            }
            objc_setAssociatedObject(base, &AssociatedKeys.footerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

@MainActor
public final class PTRefreshGifHeader: PTRefreshHeader {
    
    // MARK: - 动图控件
    public let gifView = UIImageView()
    
    // 保存不同状态下的序列帧图片
    private var stateImages: [PTRefreshState: [UIImage]] = [:]
    // 保存不同状态下的动画持续时间
    private var stateDurations: [PTRefreshState: TimeInterval] = [:]
    
    // MARK: - 初始化设置
    public override func setupUI() {
        super.setupUI()
        
        // 隐藏原生的菊花图，换上我们要的动图视图
        activityIndicator.isHidden = true
        addSubview(gifView)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // 排版逻辑：如果你想保留文字，gifView 就放在菊花原来的位置；如果文字全隐藏了，gifView 就居中
//        let _ = customShowLastTime ?? PTRefreshConfig.shared.header.showLastTime
        let hasText = !textLabel.isHidden
        
        if hasText {
            // 文字存在时，动图放在左边 (替代原来的 activityIndicator 位置)
            let gifWidth: CGFloat = 40.0
            let gifHeight: CGFloat = 40.0
            gifView.frame = CGRect(
                x: bounds.midX - 75 - gifWidth/2,
                y: bounds.midY - gifHeight/2,
                width: gifWidth,
                height: gifHeight
            )
        } else {
            // 文字都隐藏了，动图铺满居中
            gifView.frame = bounds
            gifView.contentMode = .center
        }
    }
    
    // MARK: - 配置动图接口
    
    /// 设置对应状态的动图数组
    @discardableResult
    public func setImages(_ images: [UIImage], duration: TimeInterval? = nil, for state: PTRefreshState) -> Self {
        stateImages[state] = images
        if let duration = duration {
            stateDurations[state] = duration
        } else {
            // 默认每帧 0.1 秒
            stateDurations[state] = TimeInterval(images.count) * 0.1
        }
        
        // 如果当前正好是这个状态，立刻更新图片
        if self.state == state, let firstImage = images.first {
            gifView.image = firstImage
        }
        return self
    }
    
    // MARK: - 核心动画控制逻辑
    
    public override func stateDidChanged(from oldState: PTRefreshState, to newState: PTRefreshState) {
        super.stateDidChanged(from: oldState, to: newState)
        
        // 先停止之前的动画
        gifView.stopAnimating()
        
        switch newState {
        case .idle, .pulling:
            // 闲置和下拉状态：显示第一张静态图，或者让 pullingPercentDidChange 去处理逐帧播放
            if let images = stateImages[newState], let firstImage = images.first {
                gifView.image = firstImage
            }
        case .refreshing, .willRefresh:
            // 开始刷新：提取 refreshing 数组，开始播放
            if let images = stateImages[.refreshing] ?? stateImages[.idle], !images.isEmpty {
                gifView.animationImages = images
                gifView.animationDuration = stateDurations[.refreshing] ?? (TimeInterval(images.count) * 0.1)
                gifView.startAnimating()
            }
        case .noMoreData:
            break
        }
    }
    
    public override func pullingPercentDidChange(percent: CGFloat) {
        super.pullingPercentDidChange(percent: percent)
        
        // 如果正在刷新，不干预动画
        guard state == .idle || state == .pulling else { return }
        // 获取下拉时的图片组
        guard let images = stateImages[.pulling] ?? stateImages[.idle], !images.isEmpty else { return }
        
        // 核心：将拉动的百分比映射到图片数组的索引上！
        var index = Int(percent * CGFloat(images.count))
        if index >= images.count { index = images.count - 1 }
        if index < 0 { index = 0 }
        
        gifView.stopAnimating()
        gifView.image = images[index]
    }
}

@MainActor
public final class PTRefreshAutoFooter: PTRefreshComponent {
    
    public override var isHapticEnabled: Bool {
        return customHapticFeedback ?? PTRefreshConfig.shared.footer.isHapticFeedbackEnabled
    }
    
    private var originalContentInsetBottom: CGFloat = 0
    private var componentHeight: CGFloat { customDimension ?? PTRefreshConfig.shared.footer.dimension }
    
    public override func setupUI() {
        super.setupUI()
        self.autoresizingMask = .flexibleWidth
        textLabel.font = self.customFont ?? PTRefreshConfig.shared.footer.font
        textLabel.textColor = self.customTextColor ?? PTRefreshConfig.shared.footer.textColor
        
        // 自动加载时，默认文案可以稍作调整，使其更顺滑
        self.customStateTitles[.idle] = "正在准备加载..."
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = bounds
        activityIndicator.center = CGPoint(x: bounds.midX - 50, y: bounds.midY)
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let scrollView = self.scrollView else { return }
        self.originalContentInsetBottom = scrollView.contentInset.bottom
        checkAutomaticallyHidden()
    }
    
    public override func checkAutomaticallyHidden() {
        guard let scrollView = scrollView else { return }
        let autoHidden = customAutomaticallyHidden ?? PTRefreshConfig.shared.footer.automaticallyHidden
        if autoHidden {
            self.isHidden = scrollView.contentSize.height <= scrollView.bounds.height
        } else {
            self.isHidden = false
        }
    }
    
    public override func scrollViewContentInsetDidChange() {
        guard let scrollView = scrollView else { return }
        if state == .idle {
            self.originalContentInsetBottom = scrollView.contentInset.bottom
        }
    }
    
    public override func scrollViewContentSizeDidChange() {
        guard let scrollView = scrollView else { return }
        let footerY = scrollView.contentSize.height
        self.frame = CGRect(x: 0, y: footerY, width: scrollView.bounds.width, height: componentHeight)
        checkAutomaticallyHidden()
    }
    
    // MARK: - 核心：无缝自动加载判定
    public override func scrollViewContentOffsetDidChange() {
        guard let scrollView = scrollView else { return }
        
        if self.isHidden { return }
        if state == .noMoreData || state == .refreshing || state == .willRefresh { return }
        guard scrollView.contentSize.height > scrollView.bounds.height else { return }
        
        let offsetY = scrollView.contentOffset.y
        // 判断刚好滑到底部的临界值
        let judgeOffsetY = scrollView.contentSize.height - scrollView.bounds.height + originalContentInsetBottom - ignoredContentInsetBottom
        
        // 当向上滑动的距离超过了临界值，无需松手，直接触发刷新！
        if offsetY >= judgeOffsetY {
            self.beginRefreshing()
        }
    }
    
    public override func stateDidChanged(from oldState: PTRefreshState, to newState: PTRefreshState) {
        guard let scrollView = scrollView else { return }
        textLabel.text = resolvedTitle(for: newState, globalConfig: PTRefreshConfig.shared.footer)
        
        let duration = customAnimationDuration ?? PTRefreshConfig.shared.footer.animationDuration
        let damping = customSpringDamping ?? PTRefreshConfig.shared.footer.springDamping
        
        switch newState {
        case .idle:
            activityIndicator.stopAnimating()
            if oldState == .refreshing || oldState == .willRefresh {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut]) {
                    scrollView.contentInset.bottom = self.originalContentInsetBottom
                }
            }
            
        case .pulling:
            break
            
        case .willRefresh:
            // 🌟 修复关键：无缝加载不需要松手过渡等待，直接进入正在刷新状态！
            self.state = .refreshing
            
        case .refreshing:
            // 自动加载时，固定底部留白并启动请求
            activityIndicator.startAnimating()
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 1.0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                scrollView.contentInset.bottom = self.originalContentInsetBottom + self.componentHeight
            }) { _ in
                // 确保动画定型后再执行回调
                self.executeAction()
            }
            
        case .noMoreData:
            activityIndicator.stopAnimating()
            if oldState == .refreshing || oldState == .willRefresh {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut]) {
                    scrollView.contentInset.bottom = self.originalContentInsetBottom
                }
            }
        }
    }
}

public extension UIScrollView {
    
    //MARK: 自动判断上拉或下拉结束正在刷新状态
    ///自动判断上拉或下拉结束正在刷新状态
   @objc func pt_endMJRefresh() {
        
       if let header = self.pt.header {
           if header.state == .refreshing {
               header.endRefreshing()
           }
       }
       
       if let footer = self.pt.footer {
           if footer.state == .refreshing {
               footer.endRefreshing()
           }
       }
       
       if let trailer = self.pt.trailer {
           if trailer.state == .refreshing {
               trailer.endRefreshing()
           }
       }
       
       if let leftHeader = self.pt.leftHeader {
           if leftHeader.state == .refreshing {
               leftHeader.endRefreshing()
           }
       }
       
       if let autoFooter = self.pt.autoFooter {
           if autoFooter.state == .refreshing {
               autoFooter.endRefreshing()
           }
       }
    }
}
