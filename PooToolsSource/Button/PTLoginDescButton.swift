//
//  PTLoginDescButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/12/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

open class PTLoginDescConfig:PTBaseModel {
    open var textColor:DynamicColor = DynamicColor(hexString: "7f7f7f") ?? .clear
    open var textFont:UIFont = .appfont(size: 12)
    open var leftDesc:String = "A"
    open var rightDesc:String = "B"
    open var lineWidth:CGFloat = 1
    open var lineTopNBottomSpace:CGFloat = 2
    open var itemSpace:CGFloat = 8
}

public enum PTLoginDescButtonType {
    case Left
    case Right
}

open class PTLoginDescButton: UIView {
    
    public var descHandler:((PTLoginDescButtonType)->Void)?
    
    private lazy var leftDesc:UIButton = {
        let view = baseButton()
        view.setTitle(viewConfig.leftDesc, for: .normal)
        view.addActionHandlers { sender in
            self.descHandler?(.Left)
        }
        return view
    }()
    
    private lazy var rightDesc:UIButton = {
        let view = baseButton()
        view.setTitle(viewConfig.rightDesc, for: .normal)
        view.addActionHandlers { sender in
            self.descHandler?(.Right)
        }
        return view
    }()
    
    private lazy var verLine:UIView = {
        let view = UIView()
        view.backgroundColor = viewConfig.textColor
        return view
    }()
    
    private lazy var stackView:UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .fill
        view.spacing = viewConfig.itemSpace
        return view
    }()
    
    fileprivate var viewConfig:PTLoginDescConfig!
    
    public init(config:PTLoginDescConfig = PTLoginDescConfig()) {
        viewConfig = config
        super.init(frame: .zero)
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
       
        stackView.addArrangedSubviews([leftDesc,verLine,rightDesc])
        verLine.snp.makeConstraints { make in
            make.width.equalTo(self.viewConfig.lineWidth)
            make.top.bottom.equalToSuperview().inset(self.viewConfig.lineTopNBottomSpace)
       }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func baseButton() -> UIButton {
        let view = UIButton(type: .custom)
        view.titleLabel?.font = viewConfig.textFont
        view.setTitleColor(viewConfig.textColor, for: .normal)
        return view
    }
}
