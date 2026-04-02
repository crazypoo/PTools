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
let MediaBrowserToolBarColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4)
let BottomTopSpacing:CGFloat = 10
let BottomMoreHeight:CGFloat = 34
let BottomItemSpacing:CGFloat = 5
let ContentMoreSpacing:CGFloat = 10

class PTMediaBrowserBottom: UIView {
    
    lazy var pageControlView:UIView = {
        switch viewConfig.pageControlOption {
        case .system:
            let view = UIPageControl()
            view.pageIndicatorTintColor = .lightGray
            view.currentPageIndicatorTintColor = .white
            return view
        case .fill:
            let view = PTFilledPageControl()
            view.tintColor = .lightGray
            view.indicatorPadding = 8
            view.indicatorRadius = 4
            return view
        case .pill:
            let view = PTPillPageControl()
            view.indicatorPadding = 8
            view.activeTint = .lightGray
            view.inactiveTint = .white
            return view
        case .snake:
            let view = PTSnakePageControl()
            view.activeTint = .lightGray
            view.indicatorPadding = 8
            view.indicatorRadius = 4
            view.inactiveTint = .white
            return view
        case .image:
            let view = PTImagePageControl()
            return view
        case .scrolling:
            let view = PTScrollingPageControl()
            view.activeTint = .lightGray
            view.inactiveTint = .white
            return view
        }
    }()
    
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
    
    fileprivate var viewConfig = PTMediaBrowserConfig.share
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 26.0, *) {
            backgroundColor = .clear
        } else {
            backgroundColor = MediaBrowserToolBarColor
        }

        var subs = [UIView]()
        if viewConfig.pageControlShow {
            subs = [pageControlView, moreActionButton, titleLabel]
        } else {
            subs = [moreActionButton, titleLabel]
        }
        addSubviews(subs)
        if viewConfig.pageControlShow {
            pageControlView.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + PageControlBottomSpace)
                make.height.equalTo(PageControlHeight)
            }
        }
        
        moreActionButton.snp.makeConstraints { make in
            make.width.height.equalTo(BottomMoreHeight)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(BottomTopSpacing)
        }
        switch viewConfig.actionType {
        case .Empty:
            moreActionButton.isHidden = true
            titleLabel.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                if self.viewConfig.pageControlShow{
                    make.bottom.equalTo(self.pageControlView.snp.top).offset(-BottomItemSpacing)
                } else {
                    make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
                }
                make.top.equalTo(self.moreActionButton)
            }
        default:
            moreActionButton.isHidden = false
            titleLabel.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                if self.viewConfig.pageControlShow{
                    make.bottom.equalTo(self.pageControlView.snp.top).offset(-BottomItemSpacing)
                } else {
                    make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
                }
                make.top.equalTo(self.moreActionButton)
                make.right.equalTo(self.moreActionButton.snp.left).offset(-ContentMoreSpacing)
            }
        }
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLabelAtt(att:ASAttributedString) {
        titleLabel.attributed.text = att
    }
}
