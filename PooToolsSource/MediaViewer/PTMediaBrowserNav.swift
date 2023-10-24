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
        return view
    }()
    
    lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = MediaBrowserToolBarColor

        self.addSubviews([self.closeButton,self.titleLabel])
        self.closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(34)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.bottom.equalToSuperview().inset(5)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.bottom.equalTo(self.closeButton)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
