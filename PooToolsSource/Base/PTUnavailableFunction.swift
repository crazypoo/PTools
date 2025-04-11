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
open class PTEmptyDataViewConfig : NSObject {
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
@objcMembers
public class PTUnavailableFunction: NSObject {
    public static let shared = PTUnavailableFunction()
    open var emptyViewConfig: PTEmptyDataViewConfig = PTEmptyDataViewConfig() {
        didSet {
            emptyConfig = createEmptyConfig()
        }
    }
    open var emptyTap: PTActionTask?

    private func makeEmptyButtonConfig() -> UIButton.Configuration {
        var plainConfig = UIButton.Configuration.plain()
        plainConfig.title = emptyViewConfig.buttonTitle
        plainConfig.titleTextAttributesTransformer = .init { container in
            container.merging(
                AttributeContainer.font(self.emptyViewConfig.buttonFont)
                    .foregroundColor(self.emptyViewConfig.buttonTextColor)
            )
        }
        return plainConfig
    }
    
    private lazy var emptyConfig: UIContentUnavailableConfiguration = createEmptyConfig()
    var unavailableView: UIContentUnavailableView?
    var unavailableLoadingView: UIContentUnavailableView?

    public func showEmptyView(showIn view: UIView) {
        
        unavailableView = UIContentUnavailableView(configuration: emptyConfig)
        view.addSubview(unavailableView!)
        unavailableView?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        showCustomerView(in: unavailableView!)
    }
    
    private func showCustomerView(in view: UIView) {
        guard let customerView = emptyViewConfig.customerView else { return }
        view.addSubview(customerView)
        customerView.snp.makeConstraints { make in
            make.size.equalTo(customerView.size)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(emptyViewConfig.verticalOffSet)
        }
    }

    public func showEmptyLoadingView(showIn view: UIView) {
        PTGCDManager.gcdMain {
            self.removeUnavailableViews()
            
            if self.unavailableLoadingView == nil {
                let loadingConfig = UIContentUnavailableConfiguration.loading()
                self.unavailableLoadingView = UIContentUnavailableView(configuration: loadingConfig)
                view.addSubview(self.unavailableLoadingView!)
                self.unavailableLoadingView?.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
    }

    public func hideUnavailableView(showIn view: UIView, task: PTActionTask?) {
        removeUnavailableViews()
        task?()
    }

    public func showEmptyView(viewController: PTBaseViewController) {
        viewController.contentUnavailableConfiguration = emptyConfig
    }

    public func showEmptyLoadingView(viewController: PTBaseViewController) {
        let loadingConfig = UIContentUnavailableConfiguration.loading()
        viewController.contentUnavailableConfiguration = loadingConfig
    }

    public func hideUnavailableView(viewController: PTBaseViewController, task: PTActionTask?) {
        viewController.contentUnavailableConfiguration = nil
        task?()
    }

    // MARK: - Helper Methods
    
    private func createEmptyConfig() -> UIContentUnavailableConfiguration {
        var config = UIContentUnavailableConfiguration.empty()

        if let mainTitle = emptyViewConfig.mainTitleAtt {
            config.attributedText = mainTitle.value
        }
        if let secondaryText = emptyViewConfig.secondaryEmptyAtt {
            config.secondaryAttributedText = secondaryText.value
        }
        config.image = emptyViewConfig.image
        config.imageToTextPadding = emptyViewConfig.imageToTextPadding
        config.textToButtonPadding = emptyViewConfig.textToSecondaryTextPadding
        config.buttonToSecondaryButtonPadding = emptyViewConfig.buttonToSecondaryButtonPadding
        
        if !emptyViewConfig.buttonTitle.isEmpty {
            config.button = makeEmptyButtonConfig()
            config.buttonProperties.primaryAction = UIAction { [weak self] _ in
                Task { @MainActor in
                    self?.emptyTap?()
                }
            }
        }
        
        var backgroundConfig = UIBackgroundConfiguration.clear()
        backgroundConfig.backgroundColor = emptyViewConfig.backgroundColor
        config.background = backgroundConfig
        
        return config
    }

    private func removeUnavailableViews() {
        unavailableView?.removeFromSuperview()
        unavailableView = nil
        unavailableLoadingView?.removeFromSuperview()
        unavailableLoadingView = nil
    }
}
