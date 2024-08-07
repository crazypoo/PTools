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
    public var verticalOffSet:CGFloat = 0
    public var customerView:UIView? = nil
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
        if let _ = emptyViewConfig.customerView {
        } else {
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
        }
        var configBackground = UIBackgroundConfiguration.clear()
        configBackground.backgroundColor = emptyViewConfig.backgroundColor
        emptyConfig.background = configBackground

        unavailableView = UIContentUnavailableView(configuration: emptyConfig)
        showIn.addSubview(unavailableView!)
        unavailableView!.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if let emptyViews = emptyViewConfig.customerView {
            unavailableView?.addSubview(emptyViews)
            emptyViews.snp.makeConstraints { make in
                make.size.equalTo(emptyViews.size)
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(emptyViewConfig.verticalOffSet)
            }
        }
    }
    
    public func showEmptyLoadingView(showIn:UIView) {
        PTGCDManager.gcdMain {
            self.unavailableView?.removeFromSuperview()
            self.unavailableView = nil
            
            if self.unavailableLoadingView == nil {
                let loadingConfig = UIContentUnavailableConfiguration.loading()
                self.unavailableLoadingView = UIContentUnavailableView(configuration: loadingConfig)
                showIn.addSubview(self.unavailableLoadingView!)
                self.unavailableLoadingView!.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
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
