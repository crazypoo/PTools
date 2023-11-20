//
//  BKCutsomButton.swift
//  xddmerchant
//
//  Created by innoo on 2019/8/15.
//  Copyright © 2019 kooun. All rights reserved.
//

import AttributedString
import UIKit

@objc public enum PTLayoutButtonStyle: Int {
    case leftImageRightTitle // 系统默认
    case leftTitleRightImage
    case upImageDownTitle
    case upTitleDownImage
}

@objc public enum PTLayoutButtonConnerStyle: Int {
    case none
    case fixed
    case dynamic
    case small
    case medium
    case large
    case capsule
}

@objc public enum PTLayoutButtonSizeStyle: Int {
    case none
    case mini
    case small
    case mediun
    case large
}

@objc public enum PTLayoutButtonTitleAlignmentStyle: Int {
    case automatic
    case leading
    case center
    case trailing
}

// MARK: - 上图下文 上文下图 左图右文(系统默认) 右图左文
/// 重写layoutSubviews的方式实现布局，忽略imageEdgeInsets、titleEdgeInsets和contentEdgeInsets
@objcMembers
public class PTLayoutButton: UIButton {
    /// 布局方式
    public var layoutStyle: PTLayoutButtonStyle! = .leftImageRightTitle {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setNeedsLayout()
            }
        }
    }
    /// 图片和文字的间距，默认值5
    public var midSpacing: CGFloat = 5 {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setNeedsLayout()
            }
        }
    }
    /// 指定图片size
    public var imageSize: CGSize = .zero {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setNeedsLayout()
            }
        }
    }
    /// 按钮圆角风格
    public var cornerStyle: PTLayoutButtonConnerStyle = .none {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            }
        }
    }
    /// 按钮Border粗度
    public var borderWidth: CGFloat = 0 {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                viewCorner(radius: cornerRadius, borderWidth: borderWidth, borderColor: borderColor)
            }
        }
    }
    /// 文本对齐方向
    public var textAlignment: PTLayoutButtonTitleAlignmentStyle = .center {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            }
        }
    }
    /// 按钮Border颜色
    public var borderColor: UIColor = .clear {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                viewCorner(radius: cornerRadius, borderWidth: borderWidth, borderColor: borderColor)
            }
        }
    }
    /// 按钮圆角大小
    public var cornerRadius: CGFloat = 0 {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                viewCorner(radius: cornerRadius, borderWidth: borderWidth, borderColor: borderColor)
            }
        }
    }
    public var configBackgroundColor: UIColor = .clear {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                backgroundColor = configBackgroundColor
            }
        }
    }
    public var configBackgroundSelectedColor: UIColor = .clear {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                backgroundColor = configBackgroundSelectedColor
            }
        }
    }
    public var configBackgroundHightlightColor: UIColor = .clear {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                backgroundColor = configBackgroundHightlightColor
            }
        }
    }
    public var buttonSizeStyle: PTLayoutButtonSizeStyle = .none {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            }
        }
    }
    public var titlePadding: CGFloat = 0 {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setNeedsLayout()
            }
        }
    }
    public var showHightlightActivity: Bool = false {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            }
        }
    }
    public var activityColor: UIColor = .systemPurple {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            }
        }
    }
    public var loadingCanTap: Bool = false {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            }
        }
    }

    public var normalImage: UIImage? = nil {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setImage(normalImage, for: .normal)
            }
        }
    }
    public var selectedImage: UIImage? = nil {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setImage(selectedImage, for: .selected)
            }
        }
    }
    public var hightlightImage: UIImage? = nil {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setImage(hightlightImage, for: .highlighted)
            }
        }
    }
    public var disabledImage: UIImage? = nil {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setImage(disabledImage, for: .disabled)
            }
        }
    }

    public var normalTitle: String = "" {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setTitle(normalTitle, for: .normal)
            }
        }
    }
    public var selectedTitle: String {
        get {
            normalTitle
        } set {
            if self.selectedTitle != newValue {
                self.selectedTitle = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setTitle(selectedTitle, for: .selected)
                }
            }
        }
    }
    public var hightlightTitle: String {
        get {
            normalTitle
        } set {
            if self.hightlightTitle != newValue {
                self.hightlightTitle = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setTitle(hightlightTitle, for: .highlighted)
                }
            }
        }
    }
    public var disabledTitle: String {
        get {
            normalTitle
        } set {
            if self.disabledTitle != newValue {
                self.disabledTitle = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setTitle(disabledTitle, for: .disabled)
                }
            }
        }
    }

    public var normalTitleColor: UIColor = .black {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setTitleColor(normalTitleColor, for: .normal)
            }
        }
    }
    public var selectedTitleColor: UIColor = .black {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setTitleColor(selectedTitleColor, for: .disabled)
            }
        }
    }
    public var hightlightTitleColor: UIColor = .black {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setTitleColor(hightlightTitleColor, for: .disabled)
            }
        }
    }
    public var disabledTitleColor: UIColor = .lightGray {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setTitleColor(disabledTitleColor, for: .disabled)
            }
        }
    }

    public var normalTitleFont: UIFont = .appfont(size: 14) {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                titleLabel?.font = normalTitleFont
                setNeedsLayout()
            }
        }
    }
    public var selectedTitleFont: UIFont = .appfont(size: 14) {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                titleLabel?.font = selectedTitleFont
                setNeedsLayout()
            }
        }
    }
    public var hightlightTitleFont: UIFont = .appfont(size: 14) {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                if isHighlighted {
                    titleLabel?.font = hightlightTitleFont
                } else {
                    titleLabel?.font = normalTitleFont
                }
                setNeedsLayout()
            }
        }
    }
    public var disabledTitleFont: UIFont = .appfont(size: 14) {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                if isEnabled {
                    titleLabel?.font = normalTitleFont
                } else {
                    titleLabel?.font = disabledTitleFont
                }
                setNeedsLayout()
            }
        }
    }

    public var normalSubTitle: String? = "" {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setAttValue(title: normalTitle, titleFont: normalTitleFont, titleColor: normalTitleColor, subTitle: normalSubTitle ?? "", subTitleFont: normalSubTitleFont, subTitleColor: normalSubTitleColor, state: .normal)
            }
        }
    }
    public var selectedSubTitle: String {
        get {
            normalSubTitle!
        } set {
            if self.selectedSubTitle != newValue {
                self.selectedSubTitle = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setAttValue(title: selectedTitle, titleFont: selectedTitleFont, titleColor: selectedTitleColor, subTitle: selectedSubTitle, subTitleFont: selectedSubTitleFont, subTitleColor: selectedSubTitleColor, state: .selected)
                }
            }
        }
    }
    public var hightlightSubTitle: String {
        get {
            normalSubTitle!
        } set {
            if self.hightlightSubTitle != newValue {
                self.hightlightSubTitle = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setAttValue(title: hightlightTitle, titleFont: hightlightTitleFont, titleColor: hightlightTitleColor, subTitle: hightlightSubTitle, subTitleFont: hightlightSubTitleFont, subTitleColor: hightlightSubTitleColor, state: .highlighted)
                }
            }
        }
    }
    public var disabledSubTitle: String {
        get {
            normalSubTitle!
        } set {
            if self.disabledSubTitle != newValue {
                self.disabledSubTitle = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setAttValue(title: disabledTitle, titleFont: disabledTitleFont, titleColor: disabledTitleColor, subTitle: disabledSubTitle, subTitleFont: disabledSubTitleFont, subTitleColor: disabledSubTitleColor, state: .disabled)
                }
            }
        }
    }

    public var normalSubTitleColor: UIColor = .black {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setAttValue(title: normalTitle, titleFont: normalTitleFont, titleColor: normalTitleColor, subTitle: normalSubTitle ?? "", subTitleFont: normalSubTitleFont, subTitleColor: normalSubTitleColor, state: .normal)
            }
        }
    }
    public var selectedSubTitleColor: UIColor {
        get {
            normalSubTitleColor
        } set {
            if self.selectedSubTitleColor != newValue {
                self.selectedSubTitleColor = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setAttValue(title: selectedTitle, titleFont: selectedTitleFont, titleColor: selectedTitleColor, subTitle: selectedSubTitle, subTitleFont: selectedSubTitleFont, subTitleColor: selectedSubTitleColor, state: .selected)
                }
            }
        }
    }
    public var hightlightSubTitleColor: UIColor {
        get {
            normalSubTitleColor
        } set {
            if self.hightlightSubTitleColor != newValue {
                self.hightlightSubTitleColor = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setAttValue(title: hightlightTitle, titleFont: hightlightTitleFont, titleColor: hightlightTitleColor, subTitle: hightlightSubTitle, subTitleFont: hightlightSubTitleFont, subTitleColor: hightlightSubTitleColor, state: .highlighted)
                }
            }
        }
    }
    public var disabledSubTitleColor: UIColor = .lightGray {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setAttValue(title: disabledTitle, titleFont: disabledTitleFont, titleColor: disabledTitleColor, subTitle: disabledSubTitle, subTitleFont: disabledSubTitleFont, subTitleColor: disabledSubTitleColor, state: .disabled)
            }
        }
    }

    public var normalSubTitleFont: UIFont = .appfont(size: 12) {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            } else {
                setAttValue(title: normalTitle, titleFont: normalTitleFont, titleColor: normalTitleColor, subTitle: normalSubTitle ?? "", subTitleFont: normalSubTitleFont, subTitleColor: normalSubTitleColor, state: .normal)
            }
        }
    }
    public var selectedSubTitleFont: UIFont {
        get {
            normalSubTitleFont
        } set {
            if self.selectedSubTitleFont != newValue {
                self.selectedSubTitleFont = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setAttValue(title: selectedTitle, titleFont: selectedTitleFont, titleColor: selectedTitleColor, subTitle: selectedSubTitle, subTitleFont: selectedSubTitleFont, subTitleColor: selectedSubTitleColor, state: .selected)
                }
            }
        }
    }
    public var hightlightSubTitleFont: UIFont {
        get {
            normalSubTitleFont
        } set {
            if self.hightlightSubTitleFont != newValue {
                self.hightlightSubTitleFont = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setAttValue(title: disabledTitle, titleFont: disabledTitleFont, titleColor: disabledTitleColor, subTitle: disabledSubTitle, subTitleFont: disabledSubTitleFont, subTitleColor: disabledSubTitleColor, state: .disabled)
                }
            }
        }
    }
    public var disabledSubTitleFont: UIFont {
        get {
            normalSubTitleFont
        } set {
            if self.disabledSubTitleFont != newValue {
                self.disabledSubTitleFont = newValue
                if #available(iOS 15.0, *) {
                    configuration = layoutConfig
                } else {
                    setAttValue(title: disabledTitle, titleFont: disabledTitleFont, titleColor: disabledTitleColor, subTitle: disabledSubTitle, subTitleFont: disabledSubTitleFont, subTitleColor: disabledSubTitleColor, state: .disabled)
                }
            }
        }
    }

    public var contentEdges: NSDirectionalEdgeInsets = .zero {
        didSet {
            if #available(iOS 15.0, *) {
                configuration = layoutConfig
            }
        }
    }

    private var isButtonLoading: Bool = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 15.0, *) {
            self.configuration = layoutConfig
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if #unavailable(iOS 15.0) {
            switchLayoutStyle()
        }
    }

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

        var leftOrighialX: CGFloat = 0
        var rightOrighialX: CGFloat = 0
        switch contentHorizontalAlignment {
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

    override public func setImage(_ image: UIImage?, for state: UIControl.State) {
        super.setImage(image, for: state)
        setNeedsLayout()
    }

    override public func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        setNeedsLayout()
    }

    @available(iOS 15.0,*)
    private var layoutConfig: UIButton.Configuration {
        var btnconfig:UIButton.Configuration
        if configBackgroundSelectedColor != .clear || configBackgroundColor != .clear || configBackgroundHightlightColor != .clear {
            btnconfig = UIButton.Configuration.filled()
        } else {
            btnconfig = UIButton.Configuration.plain()
        }
        switch cornerStyle {
        case .none:
            break
        case .fixed:
            btnconfig.cornerStyle = .fixed
        case .dynamic:
            btnconfig.cornerStyle = .dynamic
        case .small:
            btnconfig.cornerStyle = .dynamic
        case .medium:
            btnconfig.cornerStyle = .medium
        case .large:
            btnconfig.cornerStyle = .large
        case .capsule:
            btnconfig.cornerStyle = .capsule
        }
        btnconfig.background.strokeWidth = borderWidth
        btnconfig.background.strokeColor = borderColor
        btnconfig.background.cornerRadius = cornerRadius

        switch buttonSizeStyle {
        case .none:
            break
        case .mini:
            btnconfig.buttonSize = .mini
        case .small:
            btnconfig.buttonSize = .small
        case .mediun:
            btnconfig.buttonSize = .medium
        case .large:
            btnconfig.buttonSize = .large
        }
        switch layoutStyle {
        case .leftImageRightTitle:
            btnconfig.imagePlacement = .leading
        case .leftTitleRightImage:
            btnconfig.imagePlacement = .trailing
        case .upImageDownTitle:
            btnconfig.imagePlacement = .top
        case .upTitleDownImage:
            btnconfig.imagePlacement = .bottom
        default:
            break
        }
        btnconfig.imagePadding = midSpacing
        btnconfig.titlePadding = titlePadding
        btnconfig.contentInsets = contentEdges
        switch textAlignment {
        case .automatic:
            btnconfig.titleAlignment = .automatic
        case .leading:
            btnconfig.titleAlignment = .leading
        case .center:
            btnconfig.titleAlignment = .center
        case .trailing:
            btnconfig.titleAlignment = .trailing
        }
        configurationUpdateHandler = { sender in
            switch sender.state {
            case .normal:
                btnconfig.showsActivityIndicator = self.isButtonLoading
                if !self.normalTitle.stringIsEmpty() {
                    btnconfig.attributedTitle = AttributedString(self.normalTitle)
                    btnconfig.titleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.normalTitleFont).foregroundColor(self.normalTitleColor))
                    }
                }

                if !(self.normalSubTitle ?? "").stringIsEmpty() {
                    btnconfig.attributedSubtitle = AttributedString(self.normalSubTitle!)
                    btnconfig.subtitleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.normalSubTitleFont).foregroundColor(self.normalSubTitleColor))
                    }
                }

                if self.isButtonLoading {
                    btnconfig.activityIndicatorColorTransformer = .init { _ in
                        self.activityColor
                    }
                } else {
                    if self.imageSize != .zero && self.normalImage != nil {
                        btnconfig.image = self.normalImage!.transformImage(size: self.imageSize)
                    }
                }
                btnconfig.baseBackgroundColor = self.configBackgroundColor
                sender.configuration = btnconfig
            case .highlighted:
                btnconfig.showsActivityIndicator = self.showHightlightActivity

                if !self.hightlightTitle.stringIsEmpty() {
                    btnconfig.attributedTitle = AttributedString(self.hightlightTitle)
                    btnconfig.titleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.hightlightTitleFont).foregroundColor(self.hightlightTitleColor))
                    }
                }

                if !self.hightlightSubTitle.stringIsEmpty() {
                    btnconfig.attributedSubtitle = AttributedString(self.hightlightSubTitle)
                    btnconfig.subtitleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.hightlightSubTitleFont).foregroundColor(self.hightlightSubTitleColor))
                    }
                }

                if !self.showHightlightActivity {
                    if self.imageSize != .zero && self.hightlightImage != nil {
                        btnconfig.image = self.hightlightImage!.transformImage(size: self.imageSize)
                    }
                }

                btnconfig.activityIndicatorColorTransformer = .init { _ in
                    self.activityColor
                }
                btnconfig.baseBackgroundColor = self.configBackgroundHightlightColor
                sender.configuration = btnconfig
            case .selected:
                btnconfig.showsActivityIndicator = false

                if !self.selectedTitle.stringIsEmpty() {
                    btnconfig.attributedTitle = AttributedString(self.selectedTitle)
                    btnconfig.titleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.selectedTitleFont).foregroundColor(self.selectedTitleColor))
                    }
                }

                if !self.selectedSubTitle.stringIsEmpty() {
                    btnconfig.attributedSubtitle = AttributedString(self.selectedSubTitle)
                    btnconfig.subtitleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.selectedSubTitleFont).foregroundColor(self.selectedSubTitleColor))
                    }
                }

                if self.imageSize != .zero && self.selectedImage != nil {
                    btnconfig.image = self.selectedImage!.transformImage(size: self.imageSize)
                }
                btnconfig.baseBackgroundColor = self.configBackgroundSelectedColor
                sender.configuration = btnconfig
            case .disabled:
                btnconfig.showsActivityIndicator = false
                if !self.disabledTitle.stringIsEmpty() {
                    btnconfig.attributedTitle = AttributedString(self.disabledTitle)
                    btnconfig.titleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.disabledTitleFont).foregroundColor(self.disabledTitleColor))
                    }
                }

                if !self.disabledSubTitle.stringIsEmpty() {
                    btnconfig.attributedSubtitle = AttributedString(self.disabledSubTitle)
                    btnconfig.subtitleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.disabledTitleFont).foregroundColor(self.disabledSubTitleColor))
                    }
                }

                if self.imageSize != .zero && self.disabledImage != nil {
                    btnconfig.image = self.disabledImage!.transformImage(size: self.imageSize)
                }

                sender.configuration = btnconfig

            default:
                break
            }
        }
        return btnconfig
    }

    @available(iOS 15, *)
    public func isLoading(value: Bool? = false) {
        isButtonLoading = value!
        configuration = layoutConfig
        if value! {
            isUserInteractionEnabled = loadingCanTap
        } else {
            isUserInteractionEnabled = true
        }
    }

    private func setAttValue(title: String,
                             titleFont: UIFont,
                             titleColor: UIColor,
                             subTitle: String,
                             subTitleFont: UIFont,
                             subTitleColor: UIColor,
                             state: UIControl.State)
    {
        if title.stringIsEmpty() {
            titleLabel?.font = subTitleFont
            setTitle(subTitle, for: state)
            setTitleColor(subTitleColor, for: state)
        } else {
            var textAlignment: NSTextAlignment = .center
            switch self.textAlignment {
            case .automatic:
                textAlignment = .natural
            case .leading:
                textAlignment = .left
            case .center:
                textAlignment = .center
            case .trailing:
                textAlignment = .right
            }

            let att: ASAttributedString = """
            \(wrap: .embedding("""
            \(title, .foreground(titleColor), .font(titleFont), .paragraph(.alignment(textAlignment)))\("\n ", .foreground(.clear), .font(.appfont(size: titlePadding)), .paragraph(.alignment(textAlignment)))\("\n\(subTitle)", .foreground(subTitleColor), .font(subTitleFont), .paragraph(.alignment(textAlignment)))
            """))
            """
            setAttributedTitle(att.value, for: state)
        }
    }
}
