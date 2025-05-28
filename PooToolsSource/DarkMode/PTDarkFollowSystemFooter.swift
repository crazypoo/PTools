//
//  PTDarkFollowSystemFooter.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 20/3/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import UIKit
import SnapKit

class PTDarkFollowSystemFooter: PTBaseCollectionReusableView {
    static let ID = "PTDarkFollowSystemFooter"
    
    static let footerHeight = UIView.sizeFor(string: PTDarkModeOption.footerDesc, font: PTDarkSmartFooter.footerDescFont, height: CGFloat(MAXFLOAT), width: CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2).height + 20
    
    lazy var descLabel:UILabel = {
        let view = UILabel()
        view.text = PTDarkModeOption.footerDesc
        view.font = PTDarkSmartFooter.footerDescFont
        view.numberOfLines = 0
        view.textAlignment = .left
        view.textColor = .lightGray
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10 + PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
