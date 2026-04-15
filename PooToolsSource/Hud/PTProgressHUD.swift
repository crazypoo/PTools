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
    
    public enum Mode {
        /// 默认的菊花加载样式
        case indeterminate
        /// 纯文本样式
        case text
        /// 自定义视图样式
        case customView(UIView)
    }
    
    // MARK: - 公开属性 (内容)
    
    /// HUD 的显示模式，默认是 indeterminate
    public var mode: Mode = .indeterminate {
        didSet { updateIndicators() }
    }
    
    /// 标题文字
    public var title: String? {
        didSet { titleLabel.text = title; updateIndicators() }
    }
    
    /// 详情文字
    public var details: String? {
        didSet { detailsLabel.text = details; updateIndicators() }
    }
    
    /// 最小显示时间，防止 HUD 闪烁（单位：秒）
    public var minShowTime: TimeInterval = 0.0
    
    // MARK: - 公开属性 (外观定制)
    
    /// 毛玻璃底框的圆角大小，默认是 10.0
    public var cornerRadius: CGFloat = 10.0 {
        didSet { bezelView.layer.cornerRadius = cornerRadius }
    }
    
    /// 标题文字颜色，默认是 .label (自适应黑白)
    public var titleColor: UIColor = .label {
        didSet { titleLabel.textColor = titleColor }
    }
    
    /// 详情文字颜色，默认是 .secondaryLabel
    public var detailsColor: UIColor = .secondaryLabel {
        didSet { detailsLabel.textColor = detailsColor }
    }
    
    /// 菊花指示器的颜色，默认是 .label
    public var indicatorColor: UIColor = .label {
        didSet { updateIndicators() }
    }
    
    /// HUD 周围屏幕的背景遮罩颜色
    public var dimBackground: Bool = false {
        didSet {
            backgroundView.backgroundColor = dimBackground ? UIColor(white: 0.0, alpha: 0.4) : .clear
        }
    }
    
    /// 标题文字字体，默认是 .boldSystemFont(ofSize: 16)
    public var titleFont: UIFont = .boldSystemFont(ofSize: 16) {
        didSet { titleLabel.font = titleFont }
    }
    
    /// 详情文字字体，默认是 .systemFont(ofSize: 14) 
    public var detailsFont: UIFont = .systemFont(ofSize: 14) {
        didSet { detailsLabel.textColor = detailsColor }
    }
    
    // MARK: - 私有 UI 组件
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear // 默认透明，可通过 dimBackground 变暗
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    private let bezelView: UIVisualEffectView = {
        // 使用系统材质毛玻璃效果
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
    private var showStarted: Date?
    
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
        
        backgroundView.frame = self.bounds
        addSubview(backgroundView)
        addSubview(bezelView)
        bezelView.contentView.addSubview(stackView)
        
        let margin: CGFloat = 20.0
        NSLayoutConstraint.activate([
            bezelView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            bezelView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            bezelView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            bezelView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.8),
            
            stackView.topAnchor.constraint(equalTo: bezelView.contentView.topAnchor, constant: margin),
            stackView.bottomAnchor.constraint(equalTo: bezelView.contentView.bottomAnchor, constant: -margin),
            stackView.leadingAnchor.constraint(equalTo: bezelView.contentView.leadingAnchor, constant: margin),
            stackView.trailingAnchor.constraint(equalTo: bezelView.contentView.trailingAnchor, constant: -margin)
        ])
        
        updateIndicators()
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
            spinner.color = indicatorColor // 应用自定义指示器颜色
            spinner.startAnimating()
            indicatorView = spinner
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
    
    // MARK: - 显示/隐藏逻辑
    
    public func show(animated: Bool) {
        showStarted = Date()
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut]) {
                self.alpha = 1.0
            }
        } else {
            self.alpha = 1.0
        }
    }
    
    public func hide(animated: Bool) {
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
            }) { _ in
                self.removeFromSuperview()
            }
        } else {
            self.alpha = 0.0
            self.removeFromSuperview()
        }
    }
}
