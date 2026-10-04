//
//  PTSignView.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/5.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif

public typealias SignImageBlock = (_ signImage:UIImage?) -> Void

@objcMembers
public class PTSignView: UIView {
    
    var viewConfig:PTSignatureConfig!
    
    open var doneBlock:SignImageBlock?
    open var dismissBlock:PTActionTask?

    lazy var devMaskView:UIView = {
        let view = UIView()
        view.backgroundColor = .DevMaskColor
        let tap = UITapGestureRecognizer.init { sender in
            self.viewDismiss()
        }
        view.addGestureRecognizer(tap)
        return view
    }()
    
    lazy var viewNavView:PTNavBar = {
        let view = PTNavBar()
        view.isFakeNav = true
        if #available(iOS 26.0, *) {
            view.backgroundColor = .clear
        } else {
            view.backgroundColor = self.viewConfig.navBarColor
        }
        return view
    }()
    
    lazy var saveBtn:UIButton = {
        let view = UIButton(type: .custom)
        view.titleLabel?.font = self.viewConfig.saveFont
        view.setTitleColor(self.viewConfig.saveTextColor, for: .normal)
        view.setTitle(self.viewConfig.saveName, for: .normal)
        view.addActionHandlers { sender in
            self.signView.saveSign()
            self.doneBlock?(self.signView.SignatureImg)
            self.viewDismiss()
        }
        if #available(iOS 26.0, *) {
            view.configuration = UIButton.Configuration.clearGlass()
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
        if #available(iOS 26.0, *) {
            view.configuration = UIButton.Configuration.clearGlass()
        }
        return view
    }()

    lazy var infoLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        var totalAtts:PTRichText = PTRichText("")
        if !self.viewConfig.infoTitle.stringIsEmpty() && self.viewConfig.infoDesc.stringIsEmpty() {
            let textAtt:PTRichText = PTRichText("\(self.viewConfig.infoTitle)",.paragraph(.alignment(.center)),.font(self.viewConfig.signNavTitleFont),.foreground(self.viewConfig.signNavTitleColor))
            totalAtts = textAtt
        } else if self.viewConfig.infoTitle.stringIsEmpty() && !self.viewConfig.infoDesc.stringIsEmpty() {
            let descAtt:PTRichText = PTRichText("\(self.viewConfig.infoDesc)",.paragraph(.alignment(.center)),.font(self.viewConfig.signNavDescFont),.foreground(self.viewConfig.signNavDescColor))
            totalAtts = descAtt
        } else if !self.viewConfig.infoTitle.stringIsEmpty() && !self.viewConfig.infoDesc.stringIsEmpty() {
            let textAtt:PTRichText = PTRichText("\(self.viewConfig.infoTitle)",.paragraph(.alignment(.center)),.font(self.viewConfig.signNavTitleFont),.foreground(self.viewConfig.signNavTitleColor))
            let descAtt:PTRichText = PTRichText("\n\(self.viewConfig.infoDesc)",.paragraph(.alignment(.center)),.font(self.viewConfig.signNavDescFont),.foreground(self.viewConfig.signNavDescColor))
            totalAtts = textAtt + descAtt
        }
        view.attributedText = totalAtts.value

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
        
        addSubviews([devMaskView, viewNavView, signView])
        devMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        viewNavView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(240)
        }
        
        viewNavView.addSubviews([saveBtn, clearBtn, infoLabel])
        saveBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        
        clearBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.centerY.equalTo(self.saveBtn)
        }
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(self.clearBtn.snp.right).offset(10)
            make.right.equalTo(self.saveBtn.snp.left).offset(-10)
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        infoLabel.isHidden = true
        
        signView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.viewNavView.snp.bottom)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func showView(in hostView: UIView?) {
        // English: Prefer an explicit host and fall back to the active scene without force unwrapping.
        // Español: Prefiere un host explícito y usa la escena activa como respaldo sin desempaquetado forzado.
        // 中文：优先使用明确的承载视图，兜底到当前场景，并移除强制解包。
        guard let container = hostView ?? PTSceneContext.activeWindow() else { return }
        container.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // English: Preserve the historical no-argument entry point for 5.x callers.
    // Español: Conserva la entrada histórica sin argumentos para los clientes de 5.x.
    // 中文：保留 5.x 调用方使用的无参数历史入口。
    @available(*, deprecated, message: "Use showView(in:) to provide an explicit host view when possible.")
    public func showView() {
        showView(in: nil)
    }
    
    public func viewDismiss() {
        removeFromSuperview()
        dismissBlock?()
    }
}
