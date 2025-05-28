//
//  PTDarkSmartFooter.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 20/3/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols

public class PTDarkSmartFooter: PTBaseCollectionReusableView {
    static let ID = "PTDarkSmartFooter"
    
    public static let footerDescFont:UIFont = .appfont(size: 14)
    public static let imageSize:CGSize = CGSizeMake(14, 14)
    public static let imageContentSpace:CGFloat = 5
    public static let imageContentFont:UIFont = .appfont(size: 16)

    static let footerTotalHeight = 10 + UIView.sizeFor(string: PTDarkModeOption.themeSmartInfo, font: PTDarkSmartFooter.footerDescFont, height: CGFloat(MAXFLOAT), width: CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2).height + 10 + 44 * 2
    
    lazy var footerContent:UIView = {
        let view = UIView()
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        return view
    }()
    
    lazy var descLabel:UILabel = {
        let view = UILabel()
        view.text = PTDarkModeOption.themeSmartInfo
        view.font = PTDarkSmartFooter.footerDescFont
        view.numberOfLines = 0
        view.textAlignment = .left
        view.textColor = PTAppBaseConfig.share.viewDefaultTextColor
        return view
    }()
    
    lazy var themeName:UILabel = {
        let view = UILabel()
        view.text = PTDarkModeOption.themeSubNightTitle
        view.font = PTDarkModeOption.themeSubFont
        view.textAlignment = .left
        view.textColor = PTAppBaseConfig.share.viewDefaultTextColor
        return view
    }()
    
    lazy var themeNight:UILabel = {
        let view = UILabel()
        view.text = PTDarkModeOption.blackThemeString
        view.font = PTDarkModeOption.themeSubDescFont
        view.textAlignment = .left
        view.textColor = PTAppBaseConfig.share.viewDefaultTextColor
        return view
    }()

    lazy var themeTime:UILabel = {
        let view = UILabel()
        view.text = PTDarkModeOption.themeSubTimeTitle
        view.font = PTDarkModeOption.themeSubFont
        view.textAlignment = .left
        view.textColor = PTAppBaseConfig.share.viewDefaultTextColor
        return view
    }()
    
    lazy var themeTimeButton:PTLayoutButton = {
        let view = PTLayoutButton()
        view.layoutStyle = .leftTitleRightImage
        view.midSpacing = PTDarkSmartFooter.imageContentSpace
        view.setTitle(PTDarkModeOption.smartPeelingTimeIntervalValue, for: .normal)
        view.imageSize = PTDarkSmartFooter.imageSize
        view.normalImage = PTDarkModeOption.themeSubTimeArrow
        view.normalTitleFont = PTDarkSmartFooter.imageContentFont
        view.normalTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(footerContent)
        footerContent.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview()
        }
        
        footerContent.addSubviews([descLabel, themeName, themeNight, themeTime, themeTimeButton])
        descLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(10)
        }
        
        themeName.snp.makeConstraints { make in
            make.left.equalTo(self.descLabel)
            make.top.equalTo(self.descLabel.snp.bottom).offset(10)
            make.height.equalTo(44)
        }
        themeNight.snp.makeConstraints { make in
            make.right.equalTo(self.descLabel)
            make.top.bottom.equalTo(self.themeName)
        }
        themeTime.snp.makeConstraints { make in
            make.top.equalTo(self.themeName.snp.bottom)
            make.left.equalTo(self.descLabel)
            make.height.equalTo(self.themeName)
        }
        themeTimeButton.snp.makeConstraints { make in
            make.right.equalTo(self.descLabel)
            make.centerY.equalTo(self.themeTime)
            make.width.equalTo(PTDarkSmartFooter.imageSize.width + PTDarkSmartFooter.imageContentSpace + UIView.sizeFor(string: PTDarkModeOption.smartPeelingTimeIntervalValue, font: PTDarkSmartFooter.imageContentFont,height: 44).width + 5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
