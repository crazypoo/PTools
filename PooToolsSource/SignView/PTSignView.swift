//
//  PTSignView.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/5.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString

public typealias SignImageBlock = (_ signImage:UIImage?) -> Void
public typealias SignImageDismissBlock = () -> Void

@objcMembers
public class PTSignView: UIView {
    
    var viewConfig:PTSignatureConfig!
    
    public var doneBlock:SignImageBlock?
    public var dismissBlock:SignImageDismissBlock?

    lazy var devMaskView:UIView = {
        let view = UIView()
        view.backgroundColor = .DevMaskColor
        let tap = UITapGestureRecognizer.init { sender in
            self.viewDismiss()
        }
        view.addGestureRecognizer(tap)
        return view
    }()
    
    lazy var viewNavView:UIView = {
        let view = UIView()
        view.backgroundColor = self.viewConfig.navBarColor
        return view
    }()
    
    lazy var saveBtn:UIButton = {
        let view = UIButton(type: .custom)
        view.titleLabel?.font = self.viewConfig.saveFont
        view.setTitleColor(self.viewConfig.saveTextColor, for: .normal)
        view.setTitle(self.viewConfig.saveName, for: .normal)
        view.addActionHandlers { sender in
            self.signView.saveSign()
            if self.doneBlock != nil {
                self.doneBlock!(self.signView.SignatureImg)
            }
            self.viewDismiss()
        }
        return view
    }()
    
    lazy var clearBtn:UIButton = {
        let view = UIButton(type: .custom)
        view.titleLabel?.font = self.viewConfig.clearFont
        view.setTitleColor(self.viewConfig.clearTextColor, for: .normal)
        view.setTitle(self.viewConfig.clearName, for: .normal)
        view.addActionHandlers { sender in
            self.signView.clearSign()
        }
        return view
    }()

    lazy var infoLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        var totalAtts:ASAttributedString = ASAttributedString("")
        if !self.viewConfig.infoTitle.stringIsEmpty() && self.viewConfig.infoDesc.stringIsEmpty() {
            let textAtt:ASAttributedString = ASAttributedString("\(self.viewConfig.infoTitle)",.paragraph(.alignment(.center)),.font(self.viewConfig.signNavTitleFont),.foreground(self.viewConfig.signNavTitleColor))
            totalAtts = textAtt
        } else if self.viewConfig.infoTitle.stringIsEmpty() && !self.viewConfig.infoDesc.stringIsEmpty() {
            let descAtt:ASAttributedString = ASAttributedString("\(self.viewConfig.infoDesc)",.paragraph(.alignment(.center)),.font(self.viewConfig.signNavDescFont),.foreground(self.viewConfig.signNavDescColor))
            totalAtts = descAtt
        } else if !self.viewConfig.infoTitle.stringIsEmpty() && !self.viewConfig.infoDesc.stringIsEmpty() {
            let textAtt:ASAttributedString = ASAttributedString("\(self.viewConfig.infoTitle)",.paragraph(.alignment(.center)),.font(self.viewConfig.signNavTitleFont),.foreground(self.viewConfig.signNavTitleColor))
            let descAtt:ASAttributedString = ASAttributedString("\n\(self.viewConfig.infoDesc)",.paragraph(.alignment(.center)),.font(self.viewConfig.signNavDescFont),.foreground(self.viewConfig.signNavDescColor))
            totalAtts = textAtt + descAtt
        }
        view.attributed.text = totalAtts

        return view
    }()
    
    lazy var signView:PTEasySignatureView = {
        let view = PTEasySignatureView(viewConfig: self.viewConfig)
        view.showMessage = self.viewConfig.waterMarkMessage
        view.onSignatureWriteAction = { wirtting in
            self.infoLabel.isHidden = !wirtting
        }
        return view
    }()

    public init(viewConfig:PTSignatureConfig) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
        
        self.addSubviews([self.devMaskView,self.viewNavView,self.signView])
        self.devMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.viewNavView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(240)
        }
        
        self.viewNavView.addSubviews([self.saveBtn,self.clearBtn,self.infoLabel])
        self.saveBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        
        self.clearBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.centerY.equalTo(self.saveBtn)
        }
        self.infoLabel.snp.makeConstraints { make in
            make.left.equalTo(self.clearBtn.snp.right).offset(10)
            make.right.equalTo(self.saveBtn.snp.left).offset(-10)
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        self.infoLabel.isHidden = true
        
        self.signView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.viewNavView.snp.bottom)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func showView() {
        AppWindows!.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    public func viewDismiss() {
        self.removeFromSuperview()
        if self.dismissBlock != nil {
            self.dismissBlock!()
        }
    }
}
