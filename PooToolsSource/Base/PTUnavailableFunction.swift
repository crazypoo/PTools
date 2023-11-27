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

@objcMembers
open class PTEmptyDataViewConfig : NSObject {
    open var mainTitleAtt:ASAttributedString? = """
            \(wrap: .embedding("""
            \("主标题",.foreground(.random),.font(.appfont(size: 20)),.paragraph(.alignment(.center)))
            """))
            """
    open var secondaryEmptyAtt:ASAttributedString? = """
            \(wrap: .embedding("""
            \("副标题",.foreground(.random),.font(.appfont(size: 18)),.paragraph(.alignment(.center)))
            """))
            """
    open var buttonTitle:String = "点我刷新"
    open var buttonFont:UIFont = .appfont(size: 18)
    open var buttonTextColor:UIColor = .systemBlue
    open var image:UIImage? = UIImage(.exclamationmark.triangle)
    open var backgroundColor:UIColor = .clear
    open var imageToTextPadding:CGFloat = 10
    open var textToSecondaryTextPadding:CGFloat = 5
    open var buttonToSecondaryButtonPadding:CGFloat = 15
}

@available(iOS 17.0 , *)
@objcMembers
public class PTUnavailableFunction: NSObject {
    public static let share = PTUnavailableFunction()
    open var emptyViewConfig:PTEmptyDataViewConfig = PTEmptyDataViewConfig()
    open var emptyTap:PTActionTask?
        
    lazy var emptyButtonConfig:UIButton.Configuration = {
        var plainConfig = UIButton.Configuration.plain()
        plainConfig.title = emptyViewConfig.buttonTitle
        plainConfig.titleTextAttributesTransformer = .init({ container in
            container.merging(AttributeContainer.font(self.emptyViewConfig.buttonFont).foregroundColor(self.emptyViewConfig.buttonTextColor))
        })
        return plainConfig
    }()
    
    lazy var emptyConfig:UIContentUnavailableConfiguration = {
        var configs = UIContentUnavailableConfiguration.empty()
        configs.imageToTextPadding = emptyViewConfig.imageToTextPadding
        configs.textToButtonPadding = emptyViewConfig.textToSecondaryTextPadding
        configs.buttonToSecondaryButtonPadding = emptyViewConfig.buttonToSecondaryButtonPadding
        if emptyViewConfig.mainTitleAtt != nil {
            configs.attributedText = emptyViewConfig.mainTitleAtt!.value
        }
        
        if emptyViewConfig.secondaryEmptyAtt != nil {
            configs.secondaryAttributedText = emptyViewConfig.secondaryEmptyAtt!.value
        }
        
        if emptyViewConfig.image != nil {
            configs.image = emptyViewConfig.image!
        }
        if !emptyViewConfig.buttonTitle.stringIsEmpty() {
            configs.button = self.emptyButtonConfig
        }
        configs.buttonProperties.primaryAction = UIAction { sender in
            if self.emptyTap != nil {
                self.emptyTap!()
            }
        }
        var configBackground = UIBackgroundConfiguration.clear()
        configBackground.backgroundColor = emptyViewConfig.backgroundColor
        
        configs.background = configBackground

        return configs
    }()
    
    lazy var unavailableView:UIContentUnavailableView = {
        let view = UIContentUnavailableView(configuration: self.emptyConfig)
        return view
    }()
    
    lazy var unavailableLoadingView:UIContentUnavailableView = {
        let loadingConfig = UIContentUnavailableConfiguration.loading()
        let view = UIContentUnavailableView(configuration: loadingConfig)
        return view
    }()
    
    public func showEmptyView(showIn:UIView) {
        unavailableView.frame = showIn.bounds
        showIn.addSubview(unavailableView)
    }
    
    public func showEmptyLoadingView(showIn:UIView) {
        PTGCDManager.gcdMain {
            self.unavailableView.removeFromSuperview()
            self.unavailableLoadingView.frame = showIn.bounds
            showIn.addSubview(self.unavailableLoadingView)
        }
    }
    
    public func hideUnavailableView(task:PTActionTask?,showIn:UIView) {
        unavailableView.removeFromSuperview()
        unavailableLoadingView.removeFromSuperview()
        if task != nil {
            task!()
        }
    }
    
    public func showEmptyView(viewController:PTBaseViewController) {
        viewController.contentUnavailableConfiguration = emptyConfig
    }
    
    public func showEmptyLoadingView(viewController:PTBaseViewController) {
        let loadingConfig = UIContentUnavailableConfiguration.loading()
        viewController.contentUnavailableConfiguration = loadingConfig
    }
    
    public func hideUnavailableView(viewController:PTBaseViewController,task:PTActionTask?) {
        viewController.contentUnavailableConfiguration = nil

        if task != nil {
            task!()
        }
    }
}
