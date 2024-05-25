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
    public var mainTitleAtt:ASAttributedString?
    public var secondaryEmptyAtt:ASAttributedString?
    public var buttonTitle:String = ""
    public var buttonFont:UIFont = .appfont(size: 18)
    public var buttonTextColor:UIColor = .systemBlue
    public var image:UIImage? = UIImage(.exclamationmark.triangle)
    public var backgroundColor:UIColor = .clear
    public var imageToTextPadding:CGFloat = 10
    public var textToSecondaryTextPadding:CGFloat = 5
    public var buttonToSecondaryButtonPadding:CGFloat = 15
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
    
    var emptyConfig:UIContentUnavailableConfiguration!
    
    var unavailableView:UIContentUnavailableView?
    
    var unavailableLoadingView:UIContentUnavailableView?
    
    public func showEmptyView(showIn:UIView) {
        emptyConfig = UIContentUnavailableConfiguration.empty()
        emptyConfig.imageToTextPadding = emptyViewConfig.imageToTextPadding
        emptyConfig.textToButtonPadding = emptyViewConfig.textToSecondaryTextPadding
        emptyConfig.buttonToSecondaryButtonPadding = emptyViewConfig.buttonToSecondaryButtonPadding
        if emptyViewConfig.mainTitleAtt != nil {
            emptyConfig.attributedText = emptyViewConfig.mainTitleAtt!.value
        }
        
        if emptyViewConfig.secondaryEmptyAtt != nil {
            emptyConfig.secondaryAttributedText = emptyViewConfig.secondaryEmptyAtt!.value
        }
        
        if emptyViewConfig.image != nil {
            emptyConfig.image = emptyViewConfig.image!
        }
        if !emptyViewConfig.buttonTitle.stringIsEmpty() {
            emptyConfig.button = self.emptyButtonConfig
        }
        emptyConfig.buttonProperties.primaryAction = UIAction { sender in
            if self.emptyTap != nil {
                self.emptyTap!()
            }
        }
        var configBackground = UIBackgroundConfiguration.clear()
        configBackground.backgroundColor = emptyViewConfig.backgroundColor
        emptyConfig.background = configBackground

        unavailableView = UIContentUnavailableView(configuration: emptyConfig)
        unavailableView?.frame = showIn.frame
        showIn.addSubview(unavailableView!)
    }
    
    public func showEmptyLoadingView(showIn:UIView) {
        PTGCDManager.gcdMain {
            self.unavailableView?.removeFromSuperview()
            self.unavailableView = nil
            
            if self.unavailableLoadingView == nil {
                let loadingConfig = UIContentUnavailableConfiguration.loading()
                self.unavailableLoadingView = UIContentUnavailableView(configuration: loadingConfig)
                self.unavailableLoadingView?.frame = showIn.frame
                showIn.addSubview(self.unavailableLoadingView!)
            }
        }
    }
    
    public func hideUnavailableView(showIn:UIView,task:PTActionTask?) {
        if unavailableView != nil {
            unavailableView!.removeFromSuperview()
            unavailableView = nil
        }
        
        if self.unavailableLoadingView != nil {
            self.unavailableLoadingView!.removeFromSuperview()
            self.unavailableLoadingView = nil
        }
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
