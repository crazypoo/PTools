//
//  PTDarkModeHeader.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 20/3/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import UIKit
import SnapKit

extension UIImage {
    /// 选中
    private(set) static var tradeValidperiodSelected = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_cycle_selected@3x")
    /// 没有选中
    private(set) static var tradeValidperiod = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_cycle_unselected@3x")
}

/// 暗黑模式
enum DarkMode {
    case light
    case dark
}

class PTDarkModeHeader: PTBaseCollectionReusableView {
    static let ID = "PTDarkModeHeader"
    
    static let contentHeight:CGFloat = 256
    
    var selectModeBlock:((DarkMode)->Void)?
    
    var currentMode:DarkMode? {
        didSet {
            switch self.currentMode {
            case .light:
                self.whiteButton.isSelected = true
                self.blackButton.isSelected = false
            default:
                self.whiteButton.isSelected = false
                self.blackButton.isSelected = true
            }
        }
    }
    
    lazy var contentView:UIView = {
        let view = UIView()
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        return view
    }()
    
    lazy var titlaLabel:UILabel = {
        let view = UILabel()
        view.text = "PT Theme mt".localized()
        view.textAlignment = .left
        view.font = .appfont(size: 16)
        view.textColor = .black
        return view
    }()
    
    lazy var whiteImageView:UIImageView = {
        let view = UIImageView()
        view.image = UIColor.white.createImageWithColor()
        view.viewCorner(radius: 0,borderWidth: 1,borderColor: .lightGray)
        return view
    }()
    
    lazy var blackImageView:UIImageView = {
        let view = UIImageView()
        view.image = UIColor.black.createImageWithColor()
        view.viewCorner(radius: 0,borderWidth: 1,borderColor: .lightGray)
        return view
    }()
    
    lazy var whiteButton:PTLayoutButton = {
        let view = PTLayoutButton()
        view.imageSize = CGSizeMake(14, 14)
        view.layoutStyle = .leftImageRightTitle
        view.midSpacing = 7.5
        view.normalImage = .tradeValidperiod
        view.selectedImage = .tradeValidperiodSelected
        view.normalTitleFont = .appfont(size: 13)
        view.normalTitle = "PT Theme white".localized()
        view.normalTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        view.selectedTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        view.isSelected = false
        view.addActionHandlers { sender in
            if !sender.isSelected {
                sender.isSelected = !sender.isSelected
                if sender.isSelected {
                    self.blackButton.isSelected = false
                }
                if self.selectModeBlock != nil {
                    self.selectModeBlock!(.light)
                }
            }
        }
        return view
    }()
    
    lazy var blackButton:PTLayoutButton = {
        let view = PTLayoutButton()
        view.imageSize = CGSizeMake(14, 14)
        view.layoutStyle = .leftImageRightTitle
        view.midSpacing = 7.5
        view.normalImage = .tradeValidperiod
        view.selectedImage = .tradeValidperiodSelected
        view.normalTitleFont = .appfont(size: 13)
        view.normalTitle = "PT Theme black".localized()
        view.normalTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        view.selectedTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        view.isSelected = false
        view.addActionHandlers { sender in
            if !sender.isSelected {
                sender.isSelected = !sender.isSelected
                if sender.isSelected {
                    self.whiteButton.isSelected = false
                }
                if self.selectModeBlock != nil {
                    self.selectModeBlock!(.dark)
                }
            }
        }
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        let screenW:CGFloat = CGFloat.kSCREEN_WIDTH

        self.addSubviews([self.contentView])
        self.contentView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalTo(screenW - PTAppBaseConfig.share.defaultViewSpace * 2)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(10)
        }
        PTGCDManager.gcdMain {
            self.contentView.viewCornerRectCorner(cornerRadii: 5, corner: [.topLeft,.topRight])
        }
        
        self.contentView.addSubviews([self.titlaLabel,self.whiteImageView,self.blackImageView,self.whiteButton,self.blackButton])
        self.titlaLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(10)
        }
        self.whiteImageView.snp.makeConstraints { make in
            make.width.equalTo(80)
            make.height.equalTo(150)
            make.top.equalTo(self.titlaLabel.snp.bottom).offset(10)
            make.right.equalTo(self.contentView.snp.centerX).offset(-20)
        }
        self.blackImageView.snp.makeConstraints { make in
            make.top.width.height.equalTo(self.whiteImageView)
            make.left.equalTo(self.contentView.snp.centerX).offset(20)
        }
        
        self.whiteButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.whiteImageView)
            make.top.equalTo(self.whiteImageView.snp.bottom).offset(10)
        }
        
        self.blackButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.blackImageView)
            make.top.equalTo(self.whiteImageView.snp.bottom).offset(10)
        }
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                if PTDarkModeOption.isFollowSystem {
                    if previousTraitCollection.userInterfaceStyle == .light {
                        self.whiteButton.isSelected = true
                        self.blackButton.isSelected = false
                    } else {
                        self.whiteButton.isSelected = false
                        self.blackButton.isSelected = true
                    }
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @available(iOS, introduced: 8.0, deprecated: 17.0,message: "17後不再支持了")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if PTDarkModeOption.isFollowSystem {
            if UITraitCollection.current.userInterfaceStyle == .light {
                self.whiteButton.isSelected = true
                self.blackButton.isSelected = false
            } else {
                self.whiteButton.isSelected = false
                self.blackButton.isSelected = true
            }
        }
    }
}
