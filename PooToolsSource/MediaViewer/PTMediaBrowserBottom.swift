//
//  PTMediaBrowserBottom.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString

let PageControlHeight:CGFloat = 20
let PageControlBottomSpace:CGFloat = 5
let MediaBrowserToolBarColor = UIColor.init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4)

class PTMediaBrowserBottom: UIView {
    
    lazy var pageControlView:UIPageControl = {
        let view = UIPageControl()
        view.backgroundColor = .clear
        view.pageIndicatorTintColor = .lightGray
        view.currentPageIndicatorTintColor = .white
        return view
    }()
    
    lazy var moreActionButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.isUserInteractionEnabled = true
        view.numberOfLines = 0
        return view
    }()
    
    fileprivate var viewConfig:PTMediaBrowserConfig!
    
    init(viewConfig:PTMediaBrowserConfig) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
        
        backgroundColor = MediaBrowserToolBarColor

        self.addSubviews([self.pageControlView,self.moreActionButton,self.titleLabel])
        self.pageControlView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + PageControlBottomSpace)
            make.height.equalTo(PageControlHeight)
        }
        
        self.moreActionButton.snp.makeConstraints { make in
            make.width.height.equalTo(34)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(10)
        }
        switch viewConfig.actionType {
        case .Empty:
            self.moreActionButton.isHidden = true
            self.titleLabel.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.bottom.equalTo(self.pageControlView.snp.top).offset(5)
                make.top.equalTo(self.moreActionButton)
            }
        default:
            self.moreActionButton.isHidden = false
            self.titleLabel.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.bottom.equalTo(self.pageControlView.snp.top).offset(5)
                make.top.equalTo(self.moreActionButton)
                make.right.equalTo(self.moreActionButton.snp.left).offset(-10)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLabelAtt(att:ASAttributedString) {
        self.titleLabel.attributed.text = att
    }
}
