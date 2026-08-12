//
//  PTBaseButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/9/23.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

open class PTBaseButton: UIButton {
    
    // MARK: - 私有 UI 组件
    // 懒加载传统的菊花指示器，仅在未使用 Configuration 时作为兜底方案介入
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.isUserInteractionEnabled = false
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.expandClickEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        if #available(iOS 26.0, *) {
            if PTAppBaseConfig.share.navBarButton26Mode {
                configuration = UIButton.Configuration.clearGlass()
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 🚀 状态控制 API
        
    /// 开始等待动画
    /// - Parameter indicatorColor: 菊花的颜色（仅在非 Configuration 模式下生效）
    public func startLoading(indicatorColor: UIColor = .white) {
        // 阻断交互，防止重复点击触发多次网络请求
        self.isUserInteractionEnabled = false
        
        // 现代方案：如果检测到按钮正在使用 iOS 15+ 的 Configuration
        if var currentConfig = self.configuration {
            currentConfig.showsActivityIndicator = true
            self.configuration = currentConfig
            return
        }
        
        // 传统方案：手动居中注入菊花指示器
        if activityIndicator.superview == nil {
            addSubview(activityIndicator)
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
        }
        
        activityIndicator.color = indicatorColor
        activityIndicator.startAnimating()
        
        // 柔和地隐藏原有内容，避免与菊花重叠重影
        UIView.animate(withDuration: 0.2) {
            self.titleLabel?.alpha = 0
            self.imageView?.alpha = 0
        }
    }
    
    /// 停止等待动画，恢复常态
    public func stopLoading() {
        // 恢复交互
        self.isUserInteractionEnabled = true
        
        // 现代方案：关闭原生指示器
        if var currentConfig = self.configuration {
            currentConfig.showsActivityIndicator = false
            self.configuration = currentConfig
            return
        }
        
        // 3. 传统方案：停止动画并恢复原有文字和图片的透明度
        activityIndicator.stopAnimating()
        
        UIView.animate(withDuration: 0.2) {
            self.titleLabel?.alpha = 1
            self.imageView?.alpha = 1
        }
    }
}
