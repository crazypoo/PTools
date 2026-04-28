//
//  PTProgressHUD.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

/// 高性能且高度可定制的 Swift 版 ProgressHUD
public class PTProgressHUD: UIView {
    
    // MARK: - 枚举定义
    
    public enum Mode: Equatable {
        case indeterminate        /// 默认的菊花加载样式
        case determinateBar       /// 水平进度条 (之前的 PTProgressBar)
        case determinateRing      /// 环形进度条 (LoopDiagram)
        case determinatePie       /// 饼状图进度条 (PieDiagram)
        case text                 /// 纯文本样式
        case customView(UIView)   /// 自定义视图样式
    }
    
    public enum AnimationType {
        /// 纯透明度渐变
        case fade
        /// 从大变小+透明度
        case zoomIn
        /// 从小变大+透明度
        case zoomOut
    }
    
    // MARK: - 公开属性 (内容 & 进度)
    
    public var mode: Mode = .indeterminate {
        didSet { updateIndicators() }
    }
    
    public var title: String? {
        didSet { titleLabel.text = title; updateIndicators() }
    }
    
    public var details: String? {
        didSet { detailsLabel.text = details; updateIndicators() }
    }
    
    /// 是否在进度满 1.0 时自动隐藏，默认为 true
    public var autoHideWhenProgressCompletes: Bool = true

    /// 当前进度 (0.0 到 1.0)
    public var progress: Float = 0.0 {
        didSet {
            // 确保进度值在安全范围内
            let safeProgress = max(0, min(1, progress))
            
            if let progressBar = indicatorView as? PTProgressBar {
                progressBar.animationProgress(duration: 0.1, value: CGFloat(safeProgress))
            } else if let circularProgress = indicatorView as? PTCircularProgressView {
                circularProgress.progress = CGFloat(safeProgress)
            }
            
            // 2. 满进度自动隐藏逻辑
            if safeProgress >= 1.0 && autoHideWhenProgressCompletes {
                // 加一个 0.2 秒的延迟，让用户肉眼能看清进度条“跑满”的瞬间，体验更顺滑
                self.hide(animated: true, afterDelay: 0.2)
            }
        }
    }
    
    // MARK: - 公开属性 (时间 & 回调)
    
    /// 最小显示时间，防止 HUD 闪烁（单位：秒）
    public var minShowTime: TimeInterval = 0.0
    
    /// 宽限时间：若任务在宽限时间内完成，则不显示 HUD（单位：秒）
    public var graceTime: TimeInterval = 0.0
    
    /// HUD 隐藏后的回调闭包
    public var completionBlock: (() -> Void)?
    
    // MARK: - 公开属性 (布局位置)
    
    /// 内容距离底框边缘的间距，默认 20.0
    public var margin: CGFloat = 20.0 {
        didSet { updateLayout() }
    }
    
    /// 强制底框为正方形，默认 false
    public var isSquare: Bool = false {
        didSet { updateLayout() }
    }
    
    /// 中心点偏移量（x, y），默认在正中心
    public var offset: CGPoint = .zero {
        didSet { updateLayout() }
    }
    
    // MARK: - 公开属性 (外观定制)
    
    public var animationType: AnimationType = .fade
    
    public var cornerRadius: CGFloat = 10.0 {
        didSet { bezelView.layer.cornerRadius = cornerRadius }
    }
    
    public var titleColor: UIColor = .label {
        didSet { titleLabel.textColor = titleColor }
    }
    
    public var detailsColor: UIColor = .secondaryLabel {
        didSet { detailsLabel.textColor = detailsColor }
    }
    
    public var indicatorColor: UIColor = .white {
        didSet { updateIndicators() }
    }
    
    public var dimBackground: Bool = false {
        didSet {
            backgroundView.backgroundColor = dimBackground ? UIColor(white: 0.0, alpha: 0.4) : .clear
        }
    }
    
    public var titleFont: UIFont = .boldSystemFont(ofSize: 16) {
        didSet { titleLabel.font = titleFont }
    }
    
    public var detailsFont: UIFont = .systemFont(ofSize: 14) {
        didSet { detailsLabel.font = detailsFont }
    }
    
    /// 毛玻璃的样式，默认是适应深浅模式的 .systemThickMaterial
    public var blurEffectStyle: UIBlurEffect.Style = .systemThickMaterial {
        didSet {
            bezelView.effect = UIBlurEffect(style: blurEffectStyle)
        }
    }
    
    /// 毛玻璃底框的背景颜色 (染色效果)。
    /// 💡 提示：如果想要保留毛玻璃的模糊效果，建议传入带有透明度的颜色。
    /// 例如：UIColor(white: 0.1, alpha: 0.8) 或 UIColor.black.withAlphaComponent(0.7)
    public var bezelColor: UIColor? {
        didSet {
            // 在 UIVisualEffectView 上设置带有透明度的背景色，可以完美实现染色且不丢失毛玻璃质感
            bezelView.backgroundColor = bezelColor
        }
    }

    // MARK: - 私有 UI 组件与约束状态
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    private let bezelView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemThickMaterial)
        let view = UIVisualEffectView(effect: effect)
        view.layer.cornerRadius = 10.0
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private var indicatorView: UIView?
    
    // 状态记录
    private var showStarted: Date?
    private var graceTimer: Timer?
    private var isFinished: Bool = false
    private var hideTimer: Timer? // 👈 新增：用于处理延迟隐藏的定时器
    
    // 动态约束引用
    private var bezelCenterXConstraint: NSLayoutConstraint!
    private var bezelCenterYConstraint: NSLayoutConstraint!
    private var stackPaddingConstraints: [NSLayoutConstraint] = []
    private var squareConstraint: NSLayoutConstraint?
    
    
    /// 安全获取当前的 Key Window (兼容 iOS 13+ SceneDelegate 机制)
    private static var currentKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive } // 筛选当前处于活跃状态的场景
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    // MARK: - 初始化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - UI 布局设置
    
    private func setupViews() {
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.alpha = 0.0
        self.isHidden = true // 初始隐藏，等待 graceTime 处理
        
        backgroundView.frame = self.bounds
        addSubview(backgroundView)
        addSubview(bezelView)
        bezelView.contentView.addSubview(stackView)
        
        // 核心约束
        bezelCenterXConstraint = bezelView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        bezelCenterYConstraint = bezelView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        
        stackPaddingConstraints = [
            stackView.topAnchor.constraint(equalTo: bezelView.contentView.topAnchor, constant: margin),
            stackView.bottomAnchor.constraint(equalTo: bezelView.contentView.bottomAnchor, constant: -margin),
            stackView.leadingAnchor.constraint(equalTo: bezelView.contentView.leadingAnchor, constant: margin),
            stackView.trailingAnchor.constraint(equalTo: bezelView.contentView.trailingAnchor, constant: -margin)
        ]
        
        NSLayoutConstraint.activate([
            bezelCenterXConstraint,
            bezelCenterYConstraint,
            bezelView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            bezelView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.8)
        ] + stackPaddingConstraints)
        
        updateIndicators()
    }
    
    /// 动态更新布局 (偏移量、内边距、正方形)
    private func updateLayout() {
        bezelCenterXConstraint.constant = offset.x
        bezelCenterYConstraint.constant = offset.y
        
        stackPaddingConstraints[0].constant = margin
        stackPaddingConstraints[1].constant = -margin
        stackPaddingConstraints[2].constant = margin
        stackPaddingConstraints[3].constant = -margin
        
        if isSquare {
            if squareConstraint == nil {
                squareConstraint = bezelView.heightAnchor.constraint(equalTo: bezelView.widthAnchor)
                squareConstraint?.isActive = true
            }
        } else {
            squareConstraint?.isActive = false
            squareConstraint = nil
        }
        
        self.layoutIfNeeded()
    }
    
    // MARK: - 状态更新
    
    private func updateIndicators() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.updateIndicators() }
            return
        }
        
        indicatorView?.removeFromSuperview()
        indicatorView = nil
        
        switch mode {
        case .indeterminate:
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.color = indicatorColor
            spinner.startAnimating()
            indicatorView = spinner
            
        case .determinateBar:
            let progressBar = PTProgressBar(showType: .Horizontal)
                        
            // 2. 颜色配置：与 HUD 的主题色保持一致
            progressBar.barColor = indicatorColor
            // 轨道颜色可以设置为主题色的透明版，视觉上更和谐
            progressBar.trackColor = indicatorColor.withAlphaComponent(0.2)
            
            // 3. 圆角与约束设置
            progressBar.layer.cornerRadius = 3.0 // 添加一点圆角更精致
            progressBar.clipsToBounds = true
            progressBar.translatesAutoresizingMaskIntoConstraints = false
            
            // 4. 设定尺寸：你的进度条需要明确的宽和高
            NSLayoutConstraint.activate([
                progressBar.widthAnchor.constraint(equalToConstant: 120),
                progressBar.heightAnchor.constraint(equalToConstant: 6) // 设置进度条的粗细
            ])
            
            indicatorView = progressBar
        case .determinateRing, .determinatePie: // 新增的环形和饼状图
            let style: PTCircularProgressStyle = (mode == .determinateRing) ? .loop : .pie
            let circularView = PTCircularProgressView(style: style)
            circularView.progressColor = indicatorColor
            circularView.translatesAutoresizingMaskIntoConstraints = false
            // 圆形进度条通常需要一个正方形的固定大小
            NSLayoutConstraint.activate([
                circularView.widthAnchor.constraint(equalToConstant: 45),
                circularView.heightAnchor.constraint(equalToConstant: 45)
            ])
            indicatorView = circularView
        case .customView(let view):
            indicatorView = view
            
        case .text:
            break
        }
        
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let indicator = indicatorView { stackView.addArrangedSubview(indicator) }
        if title?.isEmpty == false { stackView.addArrangedSubview(titleLabel) }
        if details?.isEmpty == false { stackView.addArrangedSubview(detailsLabel) }
    }
    
    // MARK: - 静态快捷方法
    
    /// 将 HUD 显示在当前的主 Window 上 (全局遮挡)
    @discardableResult
    public static func showOnWindow(animated: Bool = true) -> PTProgressHUD? {
        guard let window = currentKeyWindow else {
            PTNSLogConsole("PTProgressHUD Error: 无法获取当前的 Key Window")
            return nil
        }
        // 复用之前的 show 方法
        return show(addedTo: window, animated: animated)
    }

    @discardableResult
    public static func show(addedTo view: UIView, animated: Bool = true) -> PTProgressHUD {
        let hud = PTProgressHUD(frame: view.bounds)
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud
    }
    
    @discardableResult
    public static func hide(for view: UIView, animated: Bool = true) -> Bool {
        guard let hud = view.subviews.compactMap({ $0 as? PTProgressHUD }).last else { return false }
        hud.hide(animated: animated)
        return true
    }
    
    /// 延迟指定时间后自动隐藏 HUD
    /// - Parameters:
    ///   - animated: 是否使用过渡动画
    ///   - delay: 延迟的时间（单位：秒）
    public func hide(animated: Bool, afterDelay delay: TimeInterval) {
        // 每次调用前先清理旧的定时器（防止多次调用导致时间错乱）
        hideTimer?.invalidate()
        
        // 创建新的定时器
        hideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.hide(animated: animated)
        }
    }

    // MARK: - 显示/隐藏逻辑
    
    public func show(animated: Bool) {
        isFinished = false
        
        // 宽限时间逻辑
        if graceTime > 0.0 {
            graceTimer = Timer.scheduledTimer(timeInterval: graceTime, target: self, selector: #selector(handleGraceTimer), userInfo: nil, repeats: false)
        } else {
            animateIn(animated: animated)
        }
    }
    
    @objc private func handleGraceTimer() {
        // 如果在宽限期内已经被标记结束，则不展示
        if isFinished { return }
        animateIn(animated: true)
    }
    
    private func animateIn(animated: Bool) {
        self.isHidden = false
        showStarted = Date()
        
        if animated {
            setupAnimationInStart()
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
                self.alpha = 1.0
                self.bezelView.transform = .identity
            })
        } else {
            self.alpha = 1.0
        }
    }
    
    private func setupAnimationInStart() {
        self.alpha = 0.0
        switch animationType {
        case .fade:
            bezelView.transform = .identity
        case .zoomIn:
            bezelView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        case .zoomOut:
            bezelView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }
    }
    
    public func hide(animated: Bool) {
        isFinished = true
        graceTimer?.invalidate()
        graceTimer = nil
        
        hideTimer?.invalidate()
        hideTimer = nil

        guard !self.isHidden else {
            // 说明在 graceTime 期间就被 hide 了，从未显示过
            self.done()
            return
        }
        
        let timeInterval = Date().timeIntervalSince(showStarted ?? Date())
        let delay = max(0, minShowTime - timeInterval)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.performHide(animated: animated)
        }
    }
    
    private func performHide(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
                self.alpha = 0.0
                switch self.animationType {
                case .fade: break
                case .zoomIn: self.bezelView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                case .zoomOut: self.bezelView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                }
            }) { _ in
                self.done()
            }
        } else {
            self.done()
        }
    }
    
    private func done() {
        self.alpha = 0.0
        self.isHidden = true
        self.removeFromSuperview()
        self.completionBlock?()
    }
}
