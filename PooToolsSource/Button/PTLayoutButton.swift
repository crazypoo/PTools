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

    private var highlightTitleStorage: String?
    private var disabledTitleStorage: String?
    private var selectedSubTitleStorage: String?
    private var highlightSubTitleStorage: String?
    private var disabledSubTitleStorage: String?
    private var selectedSubTitleColorStorage: UIColor?
    private var highlightSubTitleColorStorage: UIColor?
    private var selectedSubTitleFontStorage: UIFont?
    private var highlightSubTitleFontStorage: UIFont?
    private var disabledSubTitleFontStorage: UIFont?
    
    open var selectedTitle: String! {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var hightlightTitle: String {
        get {
            highlightTitleStorage ?? normalTitle
        } set {
            if highlightTitleStorage != newValue {
                highlightTitleStorage = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var disabledTitle: String {
        get {
            disabledTitleStorage ?? normalTitle
        } set {
            if disabledTitleStorage != newValue {
                disabledTitleStorage = newValue
                configuration = layoutConfig
            }
        }
    }

    open var normalTitleColor: UIColor = .label {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var selectedTitleColor: UIColor = .label {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var hightlightTitleColor: UIColor = .label {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var disabledTitleColor: UIColor = .secondaryLabel {
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
            selectedSubTitleStorage ?? normalSubTitle ?? ""
        } set {
            if selectedSubTitleStorage != newValue {
                selectedSubTitleStorage = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var hightlightSubTitle: String {
        get {
            highlightSubTitleStorage ?? normalSubTitle ?? ""
        } set {
            if highlightSubTitleStorage != newValue {
                highlightSubTitleStorage = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var disabledSubTitle: String {
        get {
            disabledSubTitleStorage ?? normalSubTitle ?? ""
        } set {
            if disabledSubTitleStorage != newValue {
                disabledSubTitleStorage = newValue
                configuration = layoutConfig
            }
        }
    }

    open var normalSubTitleColor: UIColor = .secondaryLabel {
        didSet {
            configuration = layoutConfig
        }
    }
    
    open var selectedSubTitleColor: UIColor {
        get {
            selectedSubTitleColorStorage ?? normalSubTitleColor
        } set {
            if selectedSubTitleColorStorage != newValue {
                selectedSubTitleColorStorage = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var hightlightSubTitleColor: UIColor {
        get {
            highlightSubTitleColorStorage ?? normalSubTitleColor
        } set {
            if highlightSubTitleColorStorage != newValue {
                highlightSubTitleColorStorage = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var disabledSubTitleColor: UIColor = .tertiaryLabel {
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
            selectedSubTitleFontStorage ?? normalSubTitleFont
        } set {
            if selectedSubTitleFontStorage != newValue {
                selectedSubTitleFontStorage = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var hightlightSubTitleFont: UIFont {
        get {
            highlightSubTitleFontStorage ?? normalSubTitleFont
        } set {
            if highlightSubTitleFontStorage != newValue {
                highlightSubTitleFontStorage = newValue
                configuration = layoutConfig
            }
        }
    }
    
    open var disabledSubTitleFont: UIFont {
        get {
            disabledSubTitleFontStorage ?? normalSubTitleFont
        } set {
            if disabledSubTitleFontStorage != newValue {
                disabledSubTitleFontStorage = newValue
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
    private var imageLoadTask: Task<Void, Never>?
    private var imageLoadGeneration = 0

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

    deinit {
        imageLoadTask?.cancel()
    }

    fileprivate func switchLayoutStyle() {
        if CGSize.zero.equalTo(imageSize) {
            imageView?.sizeToFit()
        } else if let imageView {
            imageView.frame = CGRect(x: imageView.x, y: imageView.y, width: imageSize.width, height: imageSize.height)
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
            let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
            leftOrighialX = isRightToLeft ? frame.width - totalWidth : 0
            rightOrighialX = leftViewFrame.maxX + midSpacing
        case .trailing:
            let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
            leftOrighialX = isRightToLeft ? 0 : frame.width - totalWidth
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
        let baseConfig = btnconfig
        configurationUpdateHandler = { [weak self] sender in
            guard let self else { return }
            // English: Reset the state-specific values before applying the current state.
            // Español: Restablece los valores específicos del estado antes de aplicar el estado actual.
            // 中文：应用当前状态前先重置状态专属值，避免上一个状态残留。
            btnconfig = baseConfig
            let currentState: UIControl.State
            if sender.state.contains(.disabled) {
                currentState = .disabled
            } else if sender.state.contains(.highlighted) {
                currentState = .highlighted
            } else if sender.state.contains(.selected) {
                currentState = .selected
            } else {
                currentState = .normal
            }

            switch currentState {
            case .normal:
                btnconfig.showsActivityIndicator = self.isButtonLoading
                if !self.normalTitle.stringIsEmpty() {
                    btnconfig.attributedTitle = AttributedString(self.normalTitle)
                    btnconfig.titleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.normalTitleFont).foregroundColor(self.normalTitleColor))
                    }
                }

                if !(self.normalSubTitle ?? "").stringIsEmpty() {
                    btnconfig.attributedSubtitle = AttributedString(self.normalSubTitle ?? "")
                    btnconfig.subtitleTextAttributesTransformer = .init { container in
                        container.merging(AttributeContainer.font(self.normalSubTitleFont).foregroundColor(self.normalSubTitleColor))
                    }
                }

                if self.isButtonLoading {
                    btnconfig.activityIndicatorColorTransformer = .init { _ in
                        self.activityColor
                    }
                } else {
                    if self.imageSize != .zero, let image = self.normalImage {
                        btnconfig.image = image.transformImage(size: self.imageSize)
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
                    if self.imageSize != .zero, let image = self.hightlightImage ?? self.normalImage {
                        btnconfig.image = image.transformImage(size: self.imageSize)
                    }
                }

                btnconfig.activityIndicatorColorTransformer = .init { _ in
                    self.activityColor
                }
                btnconfig.baseBackgroundColor = self.configBackgroundHightlightColor
                sender.configuration = btnconfig
            case .selected:
                btnconfig.showsActivityIndicator = false

                if let title = self.selectedTitle, !title.stringIsEmpty() {
                    btnconfig.attributedTitle = AttributedString(title)
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

                if self.imageSize != .zero, let image = self.selectedImage ?? self.normalImage {
                    btnconfig.image = image.transformImage(size: self.imageSize)
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
                        container.merging(AttributeContainer.font(self.disabledSubTitleFont).foregroundColor(self.disabledSubTitleColor))
                    }
                }

                if self.imageSize != .zero, let image = self.disabledImage ?? self.normalImage {
                    btnconfig.image = image.transformImage(size: self.imageSize)
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
        let loading = value ?? false
        isButtonLoading = loading
        configuration = layoutConfig
        // English: Expose loading state without changing the caller's enabled/tap contract.
        // Español: Expón el estado de carga sin cambiar el contrato de interacción del llamador.
        // 中文：只暴露加载状态，不改变调用方原有的可用性和点击约定。
        accessibilityValue = loading ? "Loading" : nil
        if loading {
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
    @MainActor
    func layoutLoadImage(contentData:Any,
                         iCloudDocumentName:String = "",
                         borderWidth:CGFloat? = nil,
                         borderColor:UIColor? = nil,
                         showValueLabel:Bool? = nil,
                         valueLabelFont:UIFont? = nil,
                         valueLabelColor:UIColor? = nil,
                         uniCount:Int? = nil,
                         emptyImage:UIImage? = nil,
                         controlState:UIControl.State = .normal) {
        imageLoadGeneration &+= 1
        let generation = imageLoadGeneration
        imageLoadTask?.cancel()

        // English: Keep image loading tied to the button and ignore results from an older request.
        // Español: Vincula la carga de imágenes al botón e ignora los resultados de solicitudes anteriores.
        // 中文：让图片加载绑定到按钮，并忽略旧请求返回的结果。
        imageLoadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let borderW = borderWidth ?? PTAppBaseConfig.share.loadImageProgressBorderWidth
            let borderC = borderColor ?? PTAppBaseConfig.share.loadImageProgressBorderColor
            let showValueL = showValueLabel ?? PTAppBaseConfig.share.loadImageShowValueLabel
            let valueLabelF = valueLabelFont ?? PTAppBaseConfig.share.loadImageShowValueFont
            let valueLabelC = valueLabelColor ?? PTAppBaseConfig.share.loadImageShowValueColor
            let uniC = uniCount ?? PTAppBaseConfig.share.loadImageShowValueUniCount
            let placeholder = emptyImage ?? PTAppBaseConfig.share.defaultEmptyImage

            let result = await PTLoadImageFunction.loadImage(contentData: contentData,iCloudDocumentName: iCloudDocumentName) { receivedSize, totalSize in
                guard generation == self.imageLoadGeneration else { return }
                let progress = totalSize > 0
                    ? min(max(CGFloat(receivedSize) / CGFloat(totalSize), 0), 1)
                    : 0
                self.layerProgress(value: progress,borderWidth: borderW,borderColor: borderC,showValueLabel: showValueL,valueLabelFont:valueLabelF,valueLabelColor:valueLabelC,uniCount:uniC)
            }
            guard !Task.isCancelled, generation == self.imageLoadGeneration else { return }
            if let findImage = result.firstImage {
                switch controlState {
                case .normal:
                    normalImage = findImage
                case .selected:
                    selectedImage = findImage
                case .highlighted:
                    hightlightImage = findImage
                case .disabled:
                    disabledImage = findImage
                default:
                    break
                }
            } else {
                switch controlState {
                case .normal:
                    normalImage = placeholder
                case .selected:
                    selectedImage = placeholder
                case .highlighted:
                    hightlightImage = placeholder
                case .disabled:
                    disabledImage = placeholder
                default:
                    break
                }
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
            let subtitle = self.normalSubTitle ?? ""
            sizeString = self.normalTitle.count > subtitle.count ? self.normalTitle : subtitle
            buttonFont = (self.normalTitle.count > (self.normalSubTitle ?? "").count ? self.normalTitleFont : self.normalSubTitleFont)
        case .selected:
            let title = self.selectedTitle ?? self.normalTitle
            sizeString = title.count > self.selectedSubTitle.count ? title : self.selectedSubTitle
            buttonFont = (title.count > self.selectedSubTitle.count ? self.selectedTitleFont : self.selectedSubTitleFont)
        default:
            sizeString = self.normalTitle
            buttonFont = self.normalTitleFont
        }
        return UIView.sizeFor(string: sizeString, font: buttonFont,lineSpacing: lineSpacing,height: height, width: width)
    }
}
