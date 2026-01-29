//
//  PTMediaBrowserNav.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

class PTMediaBrowserNav: UIView {
    
    lazy var closeButton:UIButton = {
        let view = UIButton(type: .custom)
        view.imageView?.contentMode = .scaleAspectFit
        if #available(iOS 26.0, *) {
            view.configuration = UIButton.Configuration.clearGlass()
        }
        return view
    }()
    
    lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        return view
    }()
    
    lazy var navBar:PTNavBar = {
        let view = PTNavBar()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 26.0, *) {
            backgroundColor = .clear
        } else {
            backgroundColor = MediaBrowserToolBarColor
        }

        addSubviews([navBar])
        navBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
        navBar.setLeftButtons([closeButton])
        navBar.titleView = titleLabel
        navBar.titleViewMode = .fill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
