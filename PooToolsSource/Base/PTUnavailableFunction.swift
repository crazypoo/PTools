//
//  PTUnavailableFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AttributedString
import SafeSFSymbols
import SnapKit

@objcMembers
// 👈 加上 @unchecked Sendable 保证在并发环境传递配置时消除编译器警告
open class PTEmptyDataViewConfig: NSObject, @unchecked Sendable {
    public var mainTitleAtt: ASAttributedString?
    public var secondaryEmptyAtt: ASAttributedString?
    public var buttonTitle: String = ""
    public var buttonFont: UIFont = .appfont(size: 18)
    public var buttonTextColor: UIColor = .systemBlue
    public var image: UIImage? = UIImage(.exclamationmark.triangle)
    public var backgroundColor: UIColor = .clear
    public var imageToTextPadding: CGFloat = 10
    public var textToSecondaryTextPadding: CGFloat = 5
    public var buttonToSecondaryButtonPadding: CGFloat = 15
    public var verticalOffSet: CGFloat = 0
    public var customerView: UIView? = nil
}

@MainActor
@available(iOS 17.0 , *)
public struct PTUnavailableManager { // 👈 弃用单例，改用 Struct 静态方法
    // 使用 Tag 来标记视图，避免单例持有 View 导致内存泄漏和状态冲突
    private static let emptyViewTag = 99991
    private static let loadingViewTag = 99992
    
    // MARK: - Public Methods
    
    /// 展示空数据视图
    public static func showEmptyView(in view: UIView, config: PTEmptyDataViewConfig, action: (() -> Void)? = nil) {
        hideUnavailableView(in: view) // 确保先移除旧的
        
        let emptyConfig = createEmptyConfig(from: config, action: action)
        let unavailableView = UIContentUnavailableView(configuration: emptyConfig)
        unavailableView.tag = emptyViewTag
        
        view.addSubview(unavailableView)
        unavailableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        showCustomerView(in: unavailableView, config: config)
    }
    
    /// 展示加载中视图
    public static func showEmptyLoadingView(in view: UIView) {
        // 已经标记了 @MainActor，直接执行 UI 操作，删除了冗余的 GCD 调度
        hideUnavailableView(in: view)
        
        let loadingConfig = UIContentUnavailableConfiguration.loading()
        let unavailableLoadingView = UIContentUnavailableView(configuration: loadingConfig)
        unavailableLoadingView.tag = loadingViewTag
        
        view.addSubview(unavailableLoadingView)
        unavailableLoadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    /// 隐藏所有状态视图
    public static func hideUnavailableView(in view: UIView, task: (() -> Void)? = nil) {
        view.subviews.forEach { subview in
            if subview.tag == emptyViewTag || subview.tag == loadingViewTag {
                subview.removeFromSuperview()
            }
        }
        task?()
    }
    
    // MARK: - ViewController 支持
    
    public static func showEmptyView(viewController: UIViewController, config: PTEmptyDataViewConfig, action: (() -> Void)? = nil) {
        viewController.contentUnavailableConfiguration = createEmptyConfig(from: config, action: action)
    }
    
    public static func showEmptyLoadingView(viewController: UIViewController) {
        viewController.contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
    }
    
    public static func hideUnavailableView(viewController: UIViewController, task: (() -> Void)? = nil) {
        viewController.contentUnavailableConfiguration = nil
        task?()
    }
    
    // MARK: - Helper Methods
    
    private static func createEmptyConfig(from configModel: PTEmptyDataViewConfig, action: (() -> Void)?) -> UIContentUnavailableConfiguration {
        var config = UIContentUnavailableConfiguration.empty()
        
        if let mainTitle = configModel.mainTitleAtt {
            config.attributedText = mainTitle.value
        }
        if let secondaryText = configModel.secondaryEmptyAtt {
            config.secondaryAttributedText = secondaryText.value
        }
        config.image = configModel.image
        config.imageToTextPadding = configModel.imageToTextPadding
        config.textToButtonPadding = configModel.textToSecondaryTextPadding
        config.buttonToSecondaryButtonPadding = configModel.buttonToSecondaryButtonPadding
        
        if !configModel.buttonTitle.isEmpty {
            config.button = makeEmptyButtonConfig(from: configModel)
            // 👈 直接在这里注入外部传进来的闭包，切断对全局属性的依赖
            config.buttonProperties.primaryAction = UIAction { _ in
                action?()
            }
        }
        
        var backgroundConfig = UIBackgroundConfiguration.clear()
        backgroundConfig.backgroundColor = configModel.backgroundColor
        config.background = backgroundConfig
        
        return config
    }
    
    private static func makeEmptyButtonConfig(from configModel: PTEmptyDataViewConfig) -> UIButton.Configuration {
        var plainConfig = UIButton.Configuration.plain()
        plainConfig.title = configModel.buttonTitle
        plainConfig.titleTextAttributesTransformer = .init { container in
            container.merging(
                AttributeContainer.font(configModel.buttonFont)
                    .foregroundColor(configModel.buttonTextColor)
            )
        }
        return plainConfig
    }
    
    private static func showCustomerView(in view: UIView, config: PTEmptyDataViewConfig) {
        guard let customerView = config.customerView else { return }
        view.addSubview(customerView)
        customerView.snp.makeConstraints { make in
            // 👈 移除了 make.size.equalTo(customerView.size)，因为如果外界没给 size 会引起约束冲突
            // 通常自定义 view 自身应该撑起内容，或者由外界限制
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(config.verticalOffSet)
        }
    }
}
