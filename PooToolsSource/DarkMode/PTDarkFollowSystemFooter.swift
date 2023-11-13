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
    
    static let footerHeight = UIView.sizeFor(string: "PT Theme system info".localized(), font: .appfont(size: 14), height: CGFloat(MAXFLOAT), width: CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2).height + 20
    
    lazy var descLabel:UILabel = {
        let view = UILabel()
        view.text = "PT Theme system info".localized()
        view.font = PTDarkSmartFooter.footerDescFont
        view.numberOfLines = 0
        view.textAlignment = .left
        view.textColor = .lightGray
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.descLabel)
        self.descLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10 + PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
