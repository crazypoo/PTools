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
@MainActor
open class PTEmptyDataViewConfig: NSObject {
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

public enum PTUnavailableState: Sendable {
    case loading
    case empty
    case error
    case content
}

@MainActor
public struct PTUnavailableManager { // 👈 弃用单例，改用 Struct 静态方法
    // 使用 Tag 来标记视图，避免单例持有 View 导致内存泄漏和状态冲突
    private static let emptyViewTag = 99991
    private static let loadingViewTag = 99992
    private static let customerViewTag = 99993
    
    // MARK: - Public Methods

    /// 统一的 loading/empty/error/content 状态入口。
    public static func render(_ state: PTUnavailableState,
                              in view: UIView,
                              config: PTEmptyDataViewConfig? = nil,
                              action: (() -> Void)? = nil) {
        switch state {
        case .loading:
            showEmptyLoadingView(in: view)
        case .empty, .error:
            guard let config else {
                hideUnavailableView(in: view)
                return
            }
            showEmptyView(in: view, config: config, action: action)
        case .content:
            hideUnavailableView(in: view)
        }
    }
    
    /// 展示空数据视图
    public static func showEmptyView(in view: UIView, config: PTEmptyDataViewConfig, action: (() -> Void)? = nil) {
        let emptyConfig = createEmptyConfig(from: config, action: action)
        let unavailableView: UIContentUnavailableView
        if let existingView = view.viewWithTag(emptyViewTag) as? UIContentUnavailableView {
            unavailableView = existingView
            unavailableView.configuration = emptyConfig
        } else {
            hideUnavailableView(in: view)
            unavailableView = UIContentUnavailableView(configuration: emptyConfig)
            unavailableView.tag = emptyViewTag
            view.addSubview(unavailableView)
            unavailableView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        showCustomerView(in: unavailableView, config: config)
    }
    
    /// 展示加载中视图
    public static func showEmptyLoadingView(in view: UIView) {
        if view.viewWithTag(loadingViewTag) != nil { return }
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
            if subview.tag == emptyViewTag || subview.tag == loadingViewTag || subview.tag == customerViewTag {
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
        view.viewWithTag(customerViewTag)?.removeFromSuperview()
        guard let customerView = config.customerView else { return }
        customerView.tag = customerViewTag
        view.addSubview(customerView)
        customerView.snp.makeConstraints { make in
            // 👈 移除了 make.size.equalTo(customerView.size)，因为如果外界没给 size 会引起约束冲突
            // 通常自定义 view 自身应该撑起内容，或者由外界限制
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(config.verticalOffSet)
        }
    }
}
