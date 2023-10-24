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

let PageControlHeight:CGFloat = 20
let PageControlBottomSpace:CGFloat = 5

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

    lazy var labelScroller:UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.textColor = self.viewConfig.titleColor
        view.textAlignment = .left
        view.font = UIFont.init(name: self.viewConfig.viewerFont.familyName, size: self.viewConfig.viewerFont.pointSize * 0.8)
        view.numberOfLines = 0
        view.lineBreakMode = .byTruncatingTail
        view.textColor = self.viewConfig.titleColor
        return view
    }()
    
    fileprivate var viewConfig:PTViewerConfig!
    
    init(viewConfig:PTViewerConfig) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
        
        backgroundColor = UIColor.init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4)

        self.addSubviews([self.pageControlView,self.moreActionButton])
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
    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateBottomSize(models:PTViewerModel) {
        
        self.addSubviews([self.labelScroller])
        self.labelScroller.addSubview(self.titleLabel)

        self.titleLabel.text = models.imageInfo
        self.titleLabel.isHidden = models.imageInfo.stringIsEmpty()
        
        let bottonH:CGFloat = 44
        
        let labelContentWidth = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2
        
        switch viewConfig.actionType {
            case .Empty:
                let infoH = UIView.sizeFor(string: models.imageInfo, font: self.titleLabel.font, height: CGFloat(MAXFLOAT), width: labelContentWidth).height
            
                self.labelScroller.contentSize = CGSize.init(width: labelContentWidth, height: infoH)
//                self.bottomControl.snp.updateConstraints { make in
//                    if (bottonH * 2) > infoH && infoH > bottonH {
//                        make.height.equalTo(infoH + CGFloat.kTabbarSaveAreaHeight)
//                    }  else if infoH < bottonH {
//                        make.height.equalTo(bottonH + CGFloat.kTabbarSaveAreaHeight)
//                    } else if infoH > (bottonH * 2) {
//                        make.height.equalTo(bottonH * 2 + CGFloat.kTabbarSaveAreaHeight)
//                    }
//                }

                self.labelScroller.snp.makeConstraints { make in
                    make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                    make.top.equalToSuperview().inset(10)
                    make.bottom.equalTo(self.pageControlView.snp.top).offset(-5)
                }
                
                if (bottonH * 2) > infoH && infoH > bottonH {
                    self.labelScroller.isScrollEnabled = false
                } else if infoH < bottonH {
                    self.labelScroller.isScrollEnabled = false
                } else if infoH > (bottonH * 2) {
                    self.labelScroller.isScrollEnabled = true
                }
                
                self.titleLabel.snp.makeConstraints { make in
                    make.left.top.equalToSuperview()
                    make.width.equalTo(labelContentWidth)
                }
            
            self.moreActionButton.isHidden = true
            self.moreActionButton.isUserInteractionEnabled = false
        default:
            let labelW = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2 - 10 - 34
            
            let infoH = UIView.sizeFor(string: models.imageInfo, font: self.titleLabel.font,lineSpacing: 2, height: CGFloat(MAXFLOAT), width: labelW).height
            self.labelScroller.contentSize = CGSize.init(width: labelW, height: infoH)

//            self.bottomControl.snp.updateConstraints { make in
//                make.left.right.bottom.equalToSuperview()
//                if (bottonH * 2) > infoH && infoH > bottonH {
//                    make.height.equalTo(infoH + CGFloat.kTabbarSaveAreaHeight + PageControlHeight + PageControlBottomSpace)
//                } else if infoH < bottonH {
//                    make.height.equalTo(bottonH + CGFloat.kTabbarSaveAreaHeight + PageControlHeight + PageControlBottomSpace)
//                } else if infoH > (bottonH * 2) {
//                    make.height.equalTo(bottonH * 2 + CGFloat.kTabbarSaveAreaHeight + PageControlHeight + PageControlBottomSpace)
//                }
//            }
            
            self.labelScroller.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.right.equalTo(self.moreActionButton.snp.left).offset(-10)
                make.bottom.equalTo(self.pageControlView.snp.top).offset(-5)
                make.top.equalTo(self.moreActionButton)
            }
            
            if (bottonH * 2) > infoH && infoH > bottonH {
                self.labelScroller.isScrollEnabled = false
            } else if infoH < bottonH {
                self.labelScroller.isScrollEnabled = false
            } else if infoH > (bottonH * 2) {
                self.labelScroller.isScrollEnabled = true
            }

            self.titleLabel.snp.makeConstraints { make in
                make.width.equalTo(labelW)
                make.centerX.equalToSuperview()
                make.top.equalTo(0)
            }
        }
    }

}
