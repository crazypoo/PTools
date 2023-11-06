//
//  BKCutsomButton.swift
//  xddmerchant
//
//  Created by innoo on 2019/8/15.
//  Copyright © 2019 kooun. All rights reserved.
//

import UIKit

@objc public enum PTLayoutButtonStyle : Int {
    case leftImageRightTitle // 系统默认
    case leftTitleRightImage
    case upImageDownTitle
    case upTitleDownImage
}

//@objc public enum PTLayoutButtonConnerStyle : Int {
//    case none
//    case fixed
//    case dynamic
//    case small
//    case medium
//    case large
//    case capsule
//}
//
//@objc public enum PTLayoutButtonSizeStyle : Int {
//    case none
//    case mini
//    case small
//    case mediun
//    case large
//}
//
//public class PTLayoutButtonConfig:PTBaseModel {
//    /// 布局方式
//    public var layoutStyle: PTLayoutButtonStyle! = .leftImageRightTitle
//    /// 图片和文字的间距，默认值5
//    public var midSpacing: CGFloat = 5
//    /// 指定图片size
//    public var imageSize :CGSize = .zero
//    /// 按钮圆角风格
//    public var cornerStyle: PTLayoutButtonConnerStyle = .none
//    /// 按钮Border粗度
//    public var borderWidth:CGFloat = 0
//    /// 按钮Border颜色
//    public var borderColor:UIColor = .clear
//    /// 按钮圆角大小
//    public var cornerRadius:CGFloat = 0
//    public var backgroundColor:UIColor = .clear
//    public var buttonSizeStyle:PTLayoutButtonSizeStyle = .none
//    public var titlePadding:CGFloat = 0
//    public var showHightlightActivity:Bool = false
//    public var activityColor:UIColor = .systemPurple
//    
//    public var normalImage:UIImage?
//    public var selectedImage:UIImage?
//    public var hightlightImage:UIImage?
//    public var disabledImage:UIImage?
//    
//    public var normalTitle:String = ""
//    public var selectedTitle:String {
//        get {
//            self.normalTitle
//        } set {
//            newValue
//        }
//    }
//    public var hightlightTitle:String {
//        get {
//            self.normalTitle
//        } set {
//            if self.hightlightTitle != newValue {
//                self.hightlightTitle = newValue
//            }
//        }
//    }
//    public var disabledTitle:String {
//        get {
//            self.normalTitle
//        } set {
//            if self.disabledTitle != newValue {
//                self.disabledTitle = newValue
//            }
//        }
//    }
//    public var normalTitleColor:UIColor = .black
//    public var selectedTitleColor:UIColor = .green
//    public var hightlightTitleColor:UIColor = .systemBlue
//    public var disabledTitleColor:UIColor = .lightGray
//    public var normalTitleFont:UIFont = .appfont(size: 14)
//    public var selectedTitleFont:UIFont = .appfont(size: 14)
//    public var hightlightTitleFont:UIFont = .appfont(size: 14)
//    public var disabledTitleFont:UIFont = .appfont(size: 14)
//    
//    public var normalSubTitle:String? = ""
//    public var selectedSubTitle:String {
//        get {
//            self.normalSubTitle!
//        } set {
//            if self.selectedSubTitle != newValue {
//                self.selectedSubTitle = newValue
//            }
//        }
//    }
//    public var hightlightSubTitle:String {
//        get {
//            self.normalSubTitle!
//        } set {
//            if self.hightlightSubTitle != newValue {
//                self.hightlightSubTitle = newValue
//            }
//        }
//    }
//    public var disabledSubTitle:String {
//        get {
//            self.normalSubTitle!
//        } set {
//            if self.disabledSubTitle != newValue {
//                self.disabledSubTitle = newValue
//            }
//        }
//    }
//    public var normalSubTitleColor:UIColor = .black
//    public var selectedSubTitleColor:UIColor = .green
//    public var hightlightSubTitleColor:UIColor = .systemBlue
//    public var disabledSubTitleColor:UIColor = .lightGray
//    public var normalSubTitleFont:UIFont = .appfont(size: 12)
//    public var selectedSubTitleFont:UIFont = .appfont(size: 12)
//    public var hightlightSubTitleFont:UIFont = .appfont(size: 12)
//    public var disabledSubTitleFont:UIFont = .appfont(size: 12)
//}

// MARK: - 上图下文 上文下图 左图右文(系统默认) 右图左文
/// 重写layoutSubviews的方式实现布局，忽略imageEdgeInsets、titleEdgeInsets和contentEdgeInsets
@objcMembers
public class PTLayoutButton: UIButton {
//    public var buttonLayoutConfig:PTLayoutButtonConfig = PTLayoutButtonConfig()
    /// 布局方式
    public var layoutStyle: PTLayoutButtonStyle! = .leftImageRightTitle
    /// 图片和文字的间距，默认值5
    public var midSpacing: CGFloat = 5 {
        didSet {
            setNeedsLayout()
        }
    }
    /// 指定图片size
    public var imageSize :CGSize = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()

        switchLayoutStyle()
    }
    
//    @available(iOS 15.0 ,*)
//    public func newLayoutStyle() {
//        var btnconfig = UIButton.Configuration.filled()
//        switch self.buttonLayoutConfig.cornerStyle {
//        case .none:
//            break
//        case .fixed:
//            btnconfig.cornerStyle = .fixed
//        case .dynamic:
//            btnconfig.cornerStyle = .dynamic
//        case .small:
//            btnconfig.cornerStyle = .dynamic
//        case .medium:
//            btnconfig.cornerStyle = .medium
//        case .large:
//            btnconfig.cornerStyle = .large
//        case .capsule:
//            btnconfig.cornerStyle = .capsule
//        }
//        btnconfig.background.strokeWidth = self.buttonLayoutConfig.borderWidth
//        btnconfig.background.strokeColor = self.buttonLayoutConfig.borderColor
//        btnconfig.background.cornerRadius = self.buttonLayoutConfig.cornerRadius
//        btnconfig.baseBackgroundColor = self.buttonLayoutConfig.backgroundColor
//        switch self.buttonLayoutConfig.buttonSizeStyle {
//        case .none:
//            break
//        case .mini:
//            btnconfig.buttonSize = .mini
//        case .small:
//            btnconfig.buttonSize = .small
//        case .mediun:
//            btnconfig.buttonSize = .medium
//        case .large:
//            btnconfig.buttonSize = .large
//        }
//        switch self.buttonLayoutConfig.layoutStyle {
//        case .leftImageRightTitle:
//            btnconfig.imagePlacement = .leading
//        case .leftTitleRightImage:
//            btnconfig.imagePlacement = .trailing
//        case .upImageDownTitle:
//            btnconfig.imagePlacement = .top
//        case .upTitleDownImage:
//            btnconfig.imagePlacement = .bottom
//        default:
//            break
//        }
//        btnconfig.imagePadding = self.buttonLayoutConfig.midSpacing
//        btnconfig.titlePadding = self.buttonLayoutConfig.titlePadding
//                                
//        configurationUpdateHandler = { sender in
//            switch sender.state {
//            case .normal:
//                btnconfig.showsActivityIndicator = false
//                if !self.buttonLayoutConfig.normalTitle.stringIsEmpty() {
//                    btnconfig.attributedTitle = AttributedString(self.buttonLayoutConfig.normalTitle)
//                    btnconfig.titleTextAttributesTransformer = .init({ container in
//                        container.merging(AttributeContainer.font(self.buttonLayoutConfig.normalTitleFont).foregroundColor(self.buttonLayoutConfig.normalTitleColor))
//                    })
//                }
//                
//                if !(self.buttonLayoutConfig.normalSubTitle ?? "").stringIsEmpty() {
//                    btnconfig.attributedSubtitle = AttributedString(self.buttonLayoutConfig.normalSubTitle!)
//                    btnconfig.subtitleTextAttributesTransformer = .init({ container in
//                        container.merging(AttributeContainer.font(self.buttonLayoutConfig.normalSubTitleFont).foregroundColor(self.buttonLayoutConfig.normalSubTitleColor))
//                    })
//                }
//                
//                btnconfig.image = self.buttonLayoutConfig.normalImage
//                sender.configuration = btnconfig
//            case .highlighted:
//                btnconfig.showsActivityIndicator = self.buttonLayoutConfig.showHightlightActivity
//                
//                if !self.buttonLayoutConfig.hightlightTitle.stringIsEmpty() {
//                    btnconfig.attributedTitle = AttributedString(self.buttonLayoutConfig.hightlightTitle)
//                    btnconfig.titleTextAttributesTransformer = .init({ container in
//                        container.merging(AttributeContainer.font(self.buttonLayoutConfig.hightlightTitleFont).foregroundColor(self.buttonLayoutConfig.hightlightTitleColor))
//                    })
//                }
//
//                if !self.buttonLayoutConfig.hightlightSubTitle.stringIsEmpty() {
//                    btnconfig.attributedSubtitle = AttributedString(self.buttonLayoutConfig.hightlightSubTitle)
//                    btnconfig.subtitleTextAttributesTransformer = .init({ container in
//                        container.merging(AttributeContainer.font(self.buttonLayoutConfig.hightlightSubTitleFont).foregroundColor(self.buttonLayoutConfig.hightlightSubTitleColor))
//                    })
//                }
//
//                if !self.buttonLayoutConfig.showHightlightActivity {
//                    btnconfig.image = self.buttonLayoutConfig.hightlightImage
//                }
//
//                btnconfig.activityIndicatorColorTransformer = .init({ color in
//                    return self.buttonLayoutConfig.activityColor
//                })
//
//                sender.configuration = btnconfig
//            case .selected:
//                btnconfig.showsActivityIndicator = false
//                
//                if !self.buttonLayoutConfig.selectedTitle.stringIsEmpty() {
//                    btnconfig.attributedTitle = AttributedString(self.buttonLayoutConfig.selectedTitle)
//                    btnconfig.titleTextAttributesTransformer = .init({ container in
//                        container.merging(AttributeContainer.font(self.buttonLayoutConfig.selectedTitleFont).foregroundColor(self.buttonLayoutConfig.selectedTitleColor))
//                    })
//                }
//
//                if !self.buttonLayoutConfig.selectedSubTitle.stringIsEmpty() {
//                    btnconfig.attributedSubtitle = AttributedString(self.buttonLayoutConfig.selectedSubTitle)
//                    btnconfig.subtitleTextAttributesTransformer = .init({ container in
//                        container.merging(AttributeContainer.font(self.buttonLayoutConfig.selectedSubTitleFont).foregroundColor(self.buttonLayoutConfig.selectedSubTitleColor))
//                    })
//                }
//
//                btnconfig.image = self.buttonLayoutConfig.selectedImage
//
//                sender.configuration = btnconfig
//            case .disabled:
//                btnconfig.showsActivityIndicator = false
//                if !self.buttonLayoutConfig.disabledTitle.stringIsEmpty() {
//                    btnconfig.attributedTitle = AttributedString(self.buttonLayoutConfig.disabledTitle)
//                    btnconfig.titleTextAttributesTransformer = .init({ container in
//                        container.merging(AttributeContainer.font(self.buttonLayoutConfig.disabledTitleFont).foregroundColor(self.buttonLayoutConfig.disabledTitleColor))
//                    })
//                }
//
//                if !self.buttonLayoutConfig.disabledSubTitle.stringIsEmpty() {
//                    btnconfig.attributedSubtitle = AttributedString(self.buttonLayoutConfig.disabledSubTitle)
//                    btnconfig.subtitleTextAttributesTransformer = .init({ container in
//                        container.merging(AttributeContainer.font(self.buttonLayoutConfig.disabledTitleFont).foregroundColor(self.buttonLayoutConfig.disabledSubTitleColor))
//                    })
//                }
//
//                btnconfig.image = self.buttonLayoutConfig.disabledImage
//
//                sender.configuration = btnconfig
//
//            default:
//                break
//            }
//        }
//    }
//    
    fileprivate func switchLayoutStyle() {
        if CGSize.zero.equalTo(imageSize) {
            imageView?.sizeToFit()
        } else {
            imageView?.frame = CGRect(x: imageView!.x, y: imageView!.y, width: imageSize.width, height: imageSize.height)
        }
        titleLabel?.sizeToFit()

        switch layoutStyle {
        case .leftImageRightTitle:
            layoutHorizontal(withLeftView: imageView, rightView: titleLabel)
        case .leftTitleRightImage:
            layoutHorizontal(withLeftView: titleLabel, rightView: imageView)
        case .upImageDownTitle:
            layoutVertical(withUp: imageView, downView: titleLabel)
        case .upTitleDownImage:
            layoutVertical(withUp: titleLabel, downView: imageView)
        default:
            break
        }
    }

    public func layoutHorizontal(withLeftView leftView: UIView?, rightView: UIView?) {
        
        guard var leftViewFrame = leftView?.frame,
            var rightViewFrame = rightView?.frame else { return }
        
        let totalWidth: CGFloat = leftViewFrame.width + midSpacing + rightViewFrame.width

        var leftOrighialX:CGFloat = 0
        var rightOrighialX:CGFloat = 0
        switch self.contentHorizontalAlignment {
        case .center:
            leftOrighialX = (frame.width - totalWidth) / 2.0
            rightOrighialX = leftViewFrame.maxX + midSpacing
        case .left:
            leftOrighialX = 0
            rightOrighialX = leftViewFrame.maxX + midSpacing
        case .right:
            leftOrighialX = frame.width - rightViewFrame.width - midSpacing - leftViewFrame.width
            rightOrighialX = frame.width - rightViewFrame.width
        case .fill:
            leftOrighialX = (frame.width - totalWidth) / 2.0
            rightOrighialX = leftViewFrame.maxX + midSpacing
        case .leading:
            leftOrighialX = (frame.width - totalWidth) / 2.0
            rightOrighialX = leftViewFrame.maxX + midSpacing
        case .trailing:
            leftOrighialX = (frame.width - totalWidth) / 2.0
            rightOrighialX = leftViewFrame.maxX + midSpacing
        default:
            leftOrighialX = (frame.width - totalWidth) / 2.0
            rightOrighialX = leftViewFrame.maxX + midSpacing
        }
        
        leftViewFrame.origin.x = leftOrighialX
        leftViewFrame.origin.y = (frame.height - leftViewFrame.height) / 2.0
        leftView?.frame = leftViewFrame

        rightViewFrame.origin.x = rightOrighialX
        rightViewFrame.origin.y = (frame.height - rightViewFrame.height) / 2.0
        rightView?.frame = rightViewFrame
    }
    
    public func layoutVertical(withUp upView: UIView?, downView: UIView?) {
        
        guard var upViewFrame = upView?.frame,
            var downViewFrame = downView?.frame else { return }

        let totalHeight: CGFloat = upViewFrame.height + midSpacing + downViewFrame.height

        upViewFrame.origin.y = (frame.height - totalHeight) / 2.0
        upViewFrame.origin.x = (frame.width - upViewFrame.width) / 2.0
        upView?.frame = upViewFrame

        downViewFrame.origin.y = upViewFrame.maxY + midSpacing
        downViewFrame.origin.x = (frame.width - downViewFrame.width) / 2.0
        downView?.frame = downViewFrame
    }

    public override func setImage(_ image: UIImage?, for state: UIControl.State) {
        super.setImage(image, for: state)
        setNeedsLayout()
    }

    public override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        setNeedsLayout()
    }
}
