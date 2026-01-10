//
//  BKCutsomButton.swift
//  xddmerchant
//
//  Created by innoo on 2019/8/15.
//  Copyright © 2019 kooun. All rights reserved.
//

import UIKit
import AttributedString
import Kingfisher

@objc public enum PTLayoutButtonStyle: Int {
    case leftImageRightTitle // 系统默认
    case leftTitleRightImage
    case upImageDownTitle
    case upTitleDownImage
    case title
    case image
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
    
    open var clearGlass:Bool = false {
        didSet {
            configuration = layoutConfig
        }
    }
    
    /// 布局方式
    open var layoutStyle: PTLayoutButtonStyle = .leftImageRightTitle {
        didSet {
            configuration = layoutConfig
        }
    }
    
    /// 图片和文字的间距，默认值5
    open var midSpacing: CGFloat = 5 {
        didSet {
            configuration = layoutConfig
        }
    }
    
    /// 指定图片size
    open var imageSize: CGSize = .zero {
        didSet {
            configuration = layoutConfig
        }
    }
    
    /// 按钮圆角风格
    open var cornerStyle: PTLayoutButtonConnerStyle = .none {
        didSet {
            configuration = layoutConfig
        }
    }
    
    /// 按钮Border粗度
    open var borderWidth: CGFloat = 0 {
        didSet {
            configuration = layoutConfig
        }
    }
    
    /// 文本对齐方向
    open var textAlignment: PTLayoutButtonTitleAlignmentStyle = .center {
        didSet {
            configuration = layoutConfig
        }
    }
    
    /// 按钮Border颜色
    open var borderColor: UIColor = .clear {
        didSet {
            configuration = layoutConfig
        }
    }
    
    /// 按钮圆角大小
    open var cornerRadius: CGFloat = 0 {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var configBackgroundColor: UIColor = .clear {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var configBackgroundSelectedColor: UIColor = .clear {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var configBackgroundHightlightColor: UIColor = .clear {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var configBackgroundDisableColor: UIColor = .clear {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var buttonSizeStyle: PTLayoutButtonSizeStyle = .none {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var titlePadding: CGFloat = 0 {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var showHightlightActivity: Bool = false {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var activityColor: UIColor = .systemPurple {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var loadingCanTap: Bool = false {
        didSet {
            configuration = layoutConfig
        }
    }

    open var normalImage: UIImage? = nil {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var selectedImage: UIImage? = nil {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var hightlightImage: UIImage? = nil {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var disabledImage: UIImage? = nil {
        didSet {
            configuration = layoutConfig
        }
    }

    open var normalTitle: String = "" {
        didSet {
            selectedTitle = normalTitle
            configuration = layoutConfig
        }
    }
    
    open var selectedTitle: String! {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var hightlightTitle: String {
        get {
            normalTitle
        } set {
            if hightlightTitle != newValue {
                self.hightlightTitle = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var disabledTitle: String {
        get {
            normalTitle
        } set {
            if disabledTitle != newValue {
                self.disabledTitle = newValue
                configuration = layoutConfig
            }
        }
    }

    open var normalTitleColor: UIColor = .black {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var selectedTitleColor: UIColor = .black {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var hightlightTitleColor: UIColor = .black {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var disabledTitleColor: UIColor = .lightGray {
        didSet {
            configuration = layoutConfig
        }
    }

    open var normalTitleFont: UIFont = .appfont(size: 14) {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var selectedTitleFont: UIFont = .appfont(size: 14) {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var hightlightTitleFont: UIFont = .appfont(size: 14) {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var disabledTitleFont: UIFont = .appfont(size: 14) {
        didSet {
            configuration = layoutConfig
        }
    }

    open var normalSubTitle: String? = "" {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var selectedSubTitle: String {
        get {
            normalSubTitle ?? ""
        } set {
            if selectedSubTitle != newValue {
                self.selectedSubTitle = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var hightlightSubTitle: String {
        get {
            normalSubTitle ?? ""
        } set {
            if hightlightSubTitle != newValue {
                self.hightlightSubTitle = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var disabledSubTitle: String {
        get {
            normalSubTitle ?? ""
        } set {
            if disabledSubTitle != newValue {
                self.disabledSubTitle = newValue
                configuration = layoutConfig
            }
        }
    }

    open var normalSubTitleColor: UIColor = .black {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var selectedSubTitleColor: UIColor {
        get {
            normalSubTitleColor
        } set {
            if selectedSubTitleColor != newValue {
                self.selectedSubTitleColor = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var hightlightSubTitleColor: UIColor {
        get {
            normalSubTitleColor
        } set {
            if hightlightSubTitleColor != newValue {
                self.hightlightSubTitleColor = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var disabledSubTitleColor: UIColor = .lightGray {
        didSet {
            configuration = layoutConfig
        }
    }

    open var normalSubTitleFont: UIFont = .appfont(size: 12) {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var selectedSubTitleFont: UIFont {
        get {
            normalSubTitleFont
        } set {
            if selectedSubTitleFont != newValue {
                self.selectedSubTitleFont = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var hightlightSubTitleFont: UIFont {
        get {
            normalSubTitleFont
        } set {
            if hightlightSubTitleFont != newValue {
                self.hightlightSubTitleFont = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var disabledSubTitleFont: UIFont {
        get {
            normalSubTitleFont
        } set {
            if disabledSubTitleFont != newValue {
                self.disabledSubTitleFont = newValue
                configuration = layoutConfig
            }
        }
    }

    open var contentEdges: NSDirectionalEdgeInsets = .zero {
        didSet {
            configuration = layoutConfig
        }
    }

    private var isButtonLoading: Bool = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configuration = layoutConfig
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

        let totalWidth: CGFloat = (leftViewFrame.width > 0 ? leftViewFrame.width : 0) + midSpacing + (rightViewFrame.width > 0 ? rightViewFrame.width : 0)

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
        if clearGlass {
            if #available(iOS 26.0, *) {
                btnconfig = UIButton.Configuration.clearGlass()
            } else {
                if configBackgroundSelectedColor != .clear || configBackgroundColor != .clear || configBackgroundHightlightColor != .clear {
                    btnconfig = UIButton.Configuration.filled()
                } else {
                    btnconfig = UIButton.Configuration.plain()
                }
            }
        } else {
            if configBackgroundSelectedColor != .clear || configBackgroundColor != .clear || configBackgroundHightlightColor != .clear {
                btnconfig = UIButton.Configuration.filled()
            } else {
                btnconfig = UIButton.Configuration.plain()
            }
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
                btnconfig.baseBackgroundColor = self.configBackgroundDisableColor
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
                             state: UIControl.State) {
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

extension PTLayoutButton {
    func layoutLoadImage(contentData:Any,
                         iCloudDocumentName:String = "",
                         borderWidth:CGFloat = 1.5,
                         borderColor:UIColor = UIColor.purple,
                         showValueLabel:Bool = false,
                         valueLabelFont:UIFont = .appfont(size: 16,bold: true),
                         valueLabelColor:UIColor = .white,
                         uniCount:Int = 0,
                         emptyImage:UIImage = PTAppBaseConfig.share.defaultEmptyImage,
                         controlState:UIControl.State = .normal) {
        if let image = contentData as? UIImage {
            switch controlState {
            case .normal:
                normalImage = image
            case .selected:
                selectedImage = image
            case .highlighted:
                hightlightImage = image
            case .disabled:
                disabledImage = image
            default:
                break
            }
        } else if let dataUrlString = contentData as? String {
            Task {
                let result = await PTLoadImageFunction.handleStringContent(dataUrlString, iCloudDocumentName) { receivedSize, totalSize in
                    PTGCDManager.gcdMain {
                        self.layerProgress(value: CGFloat((receivedSize / totalSize)),borderWidth: borderWidth,borderColor: borderColor,showValueLabel: showValueLabel,valueLabelFont:valueLabelFont,valueLabelColor:valueLabelColor,uniCount:uniCount)
                    }
                }
                if let image = result.firstImage {
                    switch controlState {
                    case .normal:
                        normalImage = image
                    case .selected:
                        selectedImage = image
                    case .highlighted:
                        hightlightImage = image
                    case .disabled:
                        disabledImage = image
                    default:
                        break
                    }
                }
            }
        } else if let contentDatas = contentData as? Data {
            let dataImage = UIImage(data: contentDatas)
            switch controlState {
            case .normal:
                normalImage = dataImage
            case .selected:
                selectedImage = dataImage
            case .highlighted:
                hightlightImage = dataImage
            case .disabled:
                disabledImage = dataImage
            default:
                break
            }
        } else {
            switch controlState {
            case .normal:
                normalImage = emptyImage
            case .selected:
                selectedImage = emptyImage
            case .highlighted:
                hightlightImage = emptyImage
            case .disabled:
                disabledImage = emptyImage
            default:
                break
            }
        }
    }
    
    func getButtonTitleSize(type:UIControl.State,
                            lineSpacing:CGFloat = 2.5,
                            height:CGFloat = CGFloat.greatestFiniteMagnitude,
                            width:CGFloat = CGFloat.greatestFiniteMagnitude) ->CGSize {
        var sizeString = ""
        var buttonFont:UIFont = .appfont(size: 10)
        switch type {
        case .normal:
            sizeString = (self.normalTitle.count > (self.normalSubTitle ?? "").count ? self.normalTitle : self.normalSubTitle)!
            buttonFont = (self.normalTitle.count > (self.normalSubTitle ?? "").count ? self.normalTitleFont : self.normalSubTitleFont)
        case .selected:
            sizeString = (self.selectedTitle.count > (self.selectedSubTitle).count ? self.selectedTitle : self.selectedSubTitle)!
            buttonFont = (self.selectedTitle.count > self.selectedSubTitle.count ? self.selectedTitleFont : self.selectedSubTitleFont)
        default:
            sizeString = self.normalTitle
            buttonFont = self.normalTitleFont
        }
        return UIView.sizeFor(string: sizeString, font: buttonFont,lineSpacing: lineSpacing,height: height, width: width)
    }
}
