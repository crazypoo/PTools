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
    
    lazy var pageControlView:UIView = UIView()
    
    lazy var moreActionButton:ConsoleMenuButton = {
        let view = ConsoleMenuButton()
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.isUserInteractionEnabled = true
        view.numberOfLines = 0
        return view
    }()
    
    var viewConfig:PTMediaBrowserConfig? {
        didSet {
            if let viewConfig = viewConfig {
                switch viewConfig.pageControlOption {
                case .system:
                    let view = UIPageControl()
                    view.pageIndicatorTintColor = .lightGray
                    view.currentPageIndicatorTintColor = .white
                    pageControlView = view
                case .fill:
                    let view = PTFilledPageControl()
                    view.tintColor = .lightGray
                    view.indicatorPadding = 8
                    view.indicatorRadius = 4
                    pageControlView = view
                case .pill:
                    let view = PTPillPageControl()
                    view.indicatorPadding = 8
                    view.activeTint = .lightGray
                    view.inactiveTint = .white
                    pageControlView = view
                case .snake:
                    let view = PTSnakePageControl()
                    view.activeTint = .lightGray
                    view.indicatorPadding = 8
                    view.indicatorRadius = 4
                    view.inactiveTint = .white
                    pageControlView = view
                case .image:
                    let view = PTImagePageControl()
                    pageControlView = view
                case .scrolling:
                    let view = PTScrollingPageControl()
                    view.activeTint = .lightGray
                    view.inactiveTint = .white
                    pageControlView = view
                }

                addSubviews([pageControlView, moreActionButton, titleLabel])
                pageControlView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                    make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + PageControlBottomSpace)
                    make.height.equalTo(PageControlHeight)
                }
                
                moreActionButton.snp.makeConstraints { make in
                    make.width.height.equalTo(34)
                    make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                    make.top.equalToSuperview().inset(10)
                }

                switch viewConfig.actionType {
                case .Empty:
                    moreActionButton.isHidden = true
                    titleLabel.snp.remakeConstraints { make in
                        make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                        make.bottom.equalTo(self.pageControlView.snp.top).offset(5)
                        make.top.equalTo(self.moreActionButton)
                    }
                default:
                    moreActionButton.isHidden = false
                    titleLabel.snp.remakeConstraints { make in
                        make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                        make.bottom.equalTo(self.pageControlView.snp.top).offset(5)
                        make.top.equalTo(self.moreActionButton)
                        make.right.equalTo(self.moreActionButton.snp.left).offset(-10)
                    }
                }
            }
        }
    }
    
    override init(frame:CGRect) {
        super.init(frame: .zero)
        
        backgroundColor = MediaBrowserToolBarColor
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLabelAtt(att:ASAttributedString) {
        titleLabel.attributed.text = att
    }
}
