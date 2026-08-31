//
//  PTActionLayoutButton.swift
//  YD1688
//
//  Created by 邓杰豪 on 12/29/24.
//  Copyright © 2024 YongDong. All rights reserved.
//

import UIKit
import AttributedString
import SnapKit

public class PTActionLayoutButton: UIControl {

    public var actionMargin:CGFloat = 10
    
    // English: Mark layout changes and refresh constraints only when a value actually changes.
    // Español: Marca los cambios de diseño y actualiza las restricciones solo cuando cambia un valor.
    // 中文：只有属性真正变化时才标记布局并刷新约束。
    public var layoutStyle: PTLayoutButtonStyle = .leftImageRightTitle {
        didSet { if oldValue != layoutStyle { setNeedsConstraintUpdate() } }
    }
        
    public var imageSize: CGSize = .zero {
        didSet { if oldValue != imageSize { setNeedsConstraintUpdate() } }
    }
    
    public var midSpacing: CGFloat = 0 {
        didSet { if oldValue != midSpacing { setNeedsConstraintUpdate() } }
    }
        
    public var labelLineSpace: CGFloat = 2 {
        didSet { if oldValue != labelLineSpace { setNeedsConstraintUpdate() } }
    }
    
    public var textAlignment: NSTextAlignment = .center {
        didSet { if oldValue != textAlignment { updateAppearance() } }
    }
    
    public var numbersOfLine: Int = 0 {
        didSet { if oldValue != numbersOfLine { updateAppearance() } }
    }
    
    public var textLineBreakMode: NSLineBreakMode = .byCharWrapping {
        didSet { if oldValue != textLineBreakMode { updateAppearance() } }
    }
    
    public var imageContentMode: UIView.ContentMode = .scaleAspectFit {
        didSet { if oldValue != imageContentMode { updateAppearance() } }
    }
        
    // English: Resolve overlapping control states with a stable priority.
    // Español: Resuelve estados superpuestos del control con una prioridad estable.
    // 中文：用稳定的优先级解析可能同时存在的控件状态。
    public override var state: UIControl.State {
        if !isEnabled {
            return .disabled
        } else if isHighlighted {
            return .highlighted
        } else if isSelected {
            return .selected
        } else {
            return .normal
        }
    }

    // English: Refresh the appearance only after a state transition.
    // Español: Actualiza la apariencia solo después de una transición de estado.
    // 中文：只在状态发生变化后刷新外观，避免不必要的重绘。
    public override var isEnabled: Bool {
        didSet { if oldValue != isEnabled { updateAppearance() } }
    }
    public override var isSelected: Bool {
        didSet { if oldValue != isSelected { updateAppearance() } }
    }
    public override var isHighlighted: Bool {
        didSet { if oldValue != isHighlighted { updateAppearance() } }
    }
        
    fileprivate lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    fileprivate lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.isUserInteractionEnabled = true
        view.clipsToBounds = true
        return view
    }()
    
    // 🚀 Bug修复：使用单一的手势实例，避免状态切换时无限增加手势对象
    private lazy var labelTapGesture: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap))
        return tap
    }()
    
    // English: Cache the last layout size to avoid rebuilding identical constraints.
    // Español: Guarda el último tamaño para evitar reconstruir restricciones idénticas.
    // 中文：缓存上一次布局尺寸，避免重复创建相同约束。
    private var lastLayoutSize: CGSize = .zero
    private var needsConstraintUpdate: Bool = true
    private var renderedImageToken: String?
    private var isImageLoading = false
    
    public override var intrinsicContentSize: CGSize {
        let titleSize = getKitTitleSize(lineSpacing: labelLineSpace)
        
        switch layoutStyle {
        case .image:
            // 单图模式下，固有尺寸就是图片尺寸
            return imageSize
        case .title:
            return titleSize
        case .leftImageRightTitle, .leftTitleRightImage:
            let width = imageSize.width + midSpacing + titleSize.width
            let height = max(imageSize.height, titleSize.height)
            return CGSize(width: width, height: height)
        case .upImageDownTitle, .upTitleDownImage:
            let width = max(imageSize.width, titleSize.width)
            let height = imageSize.height + midSpacing + titleSize.height
            return CGSize(width: width, height: height)
        default:
            return super.intrinsicContentSize
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        addSubviews([imageView, titleLabel])
        isAccessibilityElement = true
        accessibilityTraits = .button
        updateAppearance()
    }
    
    private func setNeedsConstraintUpdate() {
        needsConstraintUpdate = true
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        updateAppearance()
    }
    
    // English: Rebuild SnapKit constraints only when the bounds or layout values change.
    // Español: Reconstruye las restricciones de SnapKit solo cuando cambian los límites o el diseño.
    // 中文：仅在尺寸或布局属性变化时重建 SnapKit 约束。
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // English: Avoid repeated constraint work during ordinary layout passes.
        // Español: Evita recalcular restricciones durante los ciclos de diseño normales.
        // 中文：避免普通布局周期中重复计算约束。
        if bounds.size != lastLayoutSize || needsConstraintUpdate {
            lastLayoutSize = bounds.size
            needsConstraintUpdate = false
            updateLayoutConstraints()
        }
    }
    
    // English: Keep the layout calculation in one place so every state uses the same rules.
    // Español: Mantén el cálculo del diseño en un solo lugar para que todos los estados usen las mismas reglas.
    // 中文：将布局计算集中到一个入口，保证所有状态使用相同规则。
    private func updateLayoutConstraints() {
        let safeImageSize = CGSize(width: max(0, imageSize.width), height: max(0, imageSize.height))
        let safeSpacing = max(0, midSpacing)
        let availableWidth = max(0, bounds.width)
        let availableHeight = max(0, bounds.height)

        switch layoutStyle {
        case .leftImageRightTitle:
            imageView.isHidden = false
            titleLabel.isHidden = false

            let maxWidth = max(0, availableWidth - safeImageSize.width - safeSpacing)
            let measuredTitleWidth = max(0, getKitTitleSize(lineSpacing: labelLineSpace, height: availableHeight).width + 5)
            let titleWidth = min(measuredTitleWidth, maxWidth)
            let labelX = max(0, (availableWidth - (safeImageSize.width + safeSpacing + titleWidth)) / 2)
            
            imageView.snp.remakeConstraints { make in
                make.left.equalToSuperview().inset(labelX)
                make.size.equalTo(safeImageSize)
                make.centerY.equalToSuperview()
            }
            titleLabel.snp.remakeConstraints { make in
                make.width.equalTo(titleWidth)
                make.top.bottom.equalToSuperview()
                make.left.equalTo(self.imageView.snp.right).offset(safeSpacing)
            }
            
        case .leftTitleRightImage:
            imageView.isHidden = false
            titleLabel.isHidden = false

            let maxWidth = max(0, availableWidth - safeImageSize.width - safeSpacing)
            let measuredTitleWidth = max(0, getKitTitleSize(lineSpacing: labelLineSpace, height: availableHeight).width + 5)
            let titleWidth = min(measuredTitleWidth, maxWidth)
            let labelX = max(0, (availableWidth - (safeImageSize.width + safeSpacing + titleWidth)) / 2)
            
            titleLabel.snp.remakeConstraints { make in
                make.width.equalTo(titleWidth)
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview().inset(labelX)
            }
            imageView.snp.remakeConstraints { make in
                make.left.equalTo(self.titleLabel.snp.right).offset(safeSpacing)
                make.size.equalTo(safeImageSize)
                make.centerY.equalToSuperview()
            }
            
        case .upImageDownTitle:
            imageView.isHidden = false
            titleLabel.isHidden = false

            let maxHeight = max(0, availableHeight - safeImageSize.height - safeSpacing)
            let measuredTitleHeight = max(0, getKitTitleSize(lineSpacing: labelLineSpace, width: availableWidth).height + 5)
            let titleHeight = min(measuredTitleHeight, maxHeight)
            let labelY = max(0, (availableHeight - (titleHeight + safeImageSize.height + safeSpacing)) / 2)
            imageView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.size.equalTo(safeImageSize)
                make.top.equalToSuperview().inset(labelY)
            }

            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.imageView.snp.bottom).offset(safeSpacing)
                make.height.equalTo(titleHeight)
            }
            
        case .upTitleDownImage:
            imageView.isHidden = false
            titleLabel.isHidden = false
            
            let maxHeight = max(0, availableHeight - safeImageSize.height - safeSpacing)
            let measuredTitleHeight = max(0, getKitTitleSize(lineSpacing: labelLineSpace, width: availableWidth).height + 5)
            let titleHeight = min(measuredTitleHeight, maxHeight)
            let labelY = max(0, (availableHeight - (titleHeight + safeImageSize.height + safeSpacing)) / 2)

            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().inset(labelY)
                make.height.equalTo(titleHeight)
            }
            
            imageView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.size.equalTo(safeImageSize)
                make.top.equalTo(self.titleLabel.snp.bottom).offset(safeSpacing)
            }
            
        case .title:
            titleLabel.isHidden = false
            imageView.isHidden = true
            
            titleLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview() // 简写
            }
            
        case .image:
            titleLabel.isHidden = true
            imageView.isHidden = false

            imageView.snp.remakeConstraints { make in
                make.centerX.centerY.equalToSuperview()
                make.size.equalTo(safeImageSize)
                make.edges.equalToSuperview().priority(.high)
            }
            
        default:
            imageView.isHidden = true
            titleLabel.isHidden = true
        }
    }
    
    fileprivate var normalString = ""
    fileprivate var highlightedString = ""
    fileprivate var disabledString = ""
    fileprivate var selectedString = ""
    public var currentString = ""
    
    fileprivate var normalImage: Any?
    fileprivate var highlightedImage: Any?
    fileprivate var disabledImage: Any?
    fileprivate var selectedImage: Any?
    public var currentImage: Any? = nil

    fileprivate var normalTitleColor: UIColor = .black
    fileprivate var highlightedTitleColor: UIColor = .black
    fileprivate var disabledTitleColor: UIColor = .black
    fileprivate var selectedTitleColor: UIColor = .black
    public var currentTitleColor: UIColor = .black

    fileprivate var normalFont: UIFont = .systemFont(ofSize: 14) // 假设你内部的 .appfont
    fileprivate var highlightedFont: UIFont?
    fileprivate var disabledFont: UIFont?
    fileprivate var selectedFont: UIFont?
    public var currentFont: UIFont = .systemFont(ofSize: 14)
    
    fileprivate var normalBGColor: UIColor = .clear
    fileprivate var highlightedBGColor: UIColor = .clear
    fileprivate var disabledBGColor: UIColor = .clear
    fileprivate var selectedBGColor: UIColor = .clear
    public var currentBGColor: UIColor = .clear

    fileprivate var normalAtt: ASAttributedString?
    fileprivate var highlightedAtt: ASAttributedString?
    fileprivate var disabledAtt: ASAttributedString?
    fileprivate var selectedAtt: ASAttributedString?
    public var currentAtt: ASAttributedString? = nil

    public var progressLayerRadius: CGFloat = 0
    public var progressLayerTopLeft: CGFloat = 0
    public var progressLayerTopRight: CGFloat = 0
    public var progressLayerBottomLeft: CGFloat = 0
    public var progressLayerBottomRight: CGFloat = 0
    public var progressLayerCorner: UIRectCorner = .allCorners
    public var progressLayerCapsule: Bool = false
    public var progressLayerBorderWidth: CGFloat = PTAppBaseConfig.share.loadImageProgressBorderWidth
    public var progressLayerBorderColor: UIColor = PTAppBaseConfig.share.loadImageProgressBorderColor
    public var progressLayerShowValueLabel: Bool = PTAppBaseConfig.share.loadImageShowValueLabel
    public var progressLayerValueLabelFont: UIFont = PTAppBaseConfig.share.loadImageShowValueFont
    public var progressLayerValueLabelColor: UIColor = PTAppBaseConfig.share.loadImageShowValueColor
    public var progressLayerUniCount: Int = PTAppBaseConfig.share.loadImageShowValueUniCount
    
    // English: Render the complete appearance for the current control state.
    // Español: Renderiza la apariencia completa del estado actual del control.
    // 中文：根据当前控件状态完整渲染外观。
    private func updateAppearance() {
        let currentState: UIControl.State
        if state.contains(.disabled) {
            currentState = .disabled
        } else if state.contains(.highlighted) {
            currentState = .highlighted
        } else if state.contains(.selected) {
            currentState = .selected
        } else {
            currentState = .normal
        }

        switch currentState {
        case .normal:
            currentString = normalString
            currentImage = normalImage
            currentTitleColor = normalTitleColor
            currentFont = normalFont
            currentBGColor = normalBGColor
            currentAtt = normalAtt
        case .highlighted:
            currentString = highlightedString.isEmpty ? normalString : highlightedString
            currentImage = highlightedImage ?? normalImage
            currentTitleColor = highlightedTitleColor
            currentFont = highlightedFont ?? normalFont
            currentBGColor = highlightedBGColor
            currentAtt = highlightedAtt
        case .disabled:
            currentString = disabledString.isEmpty ? normalString : disabledString
            currentImage = disabledImage ?? normalImage
            currentTitleColor = disabledTitleColor
            currentFont = disabledFont ?? normalFont
            currentBGColor = disabledBGColor
            currentAtt = disabledAtt
        case .selected:
            currentString = selectedString.isEmpty ? normalString : selectedString
            currentImage = selectedImage ?? normalImage
            currentTitleColor = selectedTitleColor
            currentFont = selectedFont ?? normalFont
            currentBGColor = selectedBGColor
            currentAtt = selectedAtt
        default:
            currentString = normalString
            currentImage = normalImage
            currentTitleColor = normalTitleColor
            currentFont = normalFont
            currentBGColor = normalBGColor
            currentAtt = normalAtt
        }
        
        titleLabel.numberOfLines = numbersOfLine
        
        if let att = currentAtt {
            titleLabel.attributed.text = att
            
            // English: Keep one fallback gesture and do not add duplicates on every refresh.
            // Español: Conserva un solo gesto de respaldo y no añadas duplicados en cada actualización.
            // 中文：只保留一个兜底手势，避免每次刷新重复添加。
            if !att.value.containsAction() {
                if !(titleLabel.gestureRecognizers?.contains(labelTapGesture) ?? false) {
                    titleLabel.addGestureRecognizer(labelTapGesture)
                }
            } else {
                titleLabel.removeGestureRecognizer(labelTapGesture)
            }
        } else {
            // English: Remove the fallback gesture when the attributed text owns the action.
            // Español: Elimina el gesto de respaldo cuando el texto atribuido contiene la acción.
            // 中文：富文本自身包含动作时移除兜底手势。
            titleLabel.removeGestureRecognizer(labelTapGesture)
            
            // English: Capture the control weakly because the attributed text is retained by the label.
            // Español: Captura el control débilmente porque la etiqueta conserva el texto atribuido.
            // 中文：富文本会被标签持有，因此闭包弱引用控件以避免循环引用。
            let nameAtt: ASAttributedString = """
                        \(wrap: .embedding("""
                        \(self.currentString,.foreground(self.currentTitleColor),.font(self.currentFont),.paragraph(.alignment(self.textAlignment),.lineSpacing(self.labelLineSpace),.lineBreakMode(self.textLineBreakMode)))
                        """),.action { [weak self] in
                            guard let self = self else { return }
                            self.sendActions(for: .touchUpInside)
                        })
                        """
            self.titleLabel.attributed.text = nameAtt
        }
        
        backgroundColor = currentBGColor
        imageView.contentMode = self.imageContentMode
        
        let imageToken = imageSourceToken(currentImage)
        if renderedImageToken != imageToken {
            renderedImageToken = imageToken
            imageView.cancelImageLoad()
            imageView.image = nil
            isImageLoading = false
        }

        if let currentImage, !isImageLoading {
            isImageLoading = true
            imageView.loadImage(contentData: currentImage,
                                radius: self.progressLayerRadius,
                                topLeft: self.progressLayerTopLeft,
                                topRight: self.progressLayerTopRight,
                                bottomLeft: self.progressLayerBottomLeft,
                                bottomRight: self.progressLayerBottomRight,
                                corner: self.progressLayerCorner,
                                capsule: self.progressLayerCapsule,
                                borderWidth: self.progressLayerBorderWidth,
                                borderColor: self.progressLayerBorderColor,
                                showValueLabel: self.progressLayerShowValueLabel,
                                valueLabelFont: self.progressLayerValueLabelFont,
                                valueLabelColor: self.progressLayerValueLabelColor,
                                uniCount: self.progressLayerUniCount,
                                loadFinish: { [weak self] _ in
                guard let self, self.renderedImageToken == imageToken else { return }
                self.isImageLoading = false
            })
        } else if currentImage == nil {
            isImageLoading = false
        }
        
        accessibilityLabel = currentString
        accessibilityValue = currentState == .disabled ? "Disabled" : nil
        setNeedsLayout()
    }

    private func imageSourceToken(_ source: Any?) -> String {
        guard let source else { return "none" }
        if let image = source as? UIImage {
            return "image:\(ObjectIdentifier(image)):\(image.size.width)x\(image.size.height)"
        }
        if let url = source as? URL {
            return "url:\(url.absoluteString)"
        }
        if let string = source as? String {
            return "string:\(string)"
        }
        if let data = source as? Data {
            return "data:\(data.count):\(data.hashValue)"
        }
        return String(reflecting: source)
    }
    
    @objc private func handleLabelTap() {
        self.sendActions(for: .touchUpInside)
    }
    
    public func getKitTitleSize(lineSpacing:CGFloat = 2.5,
                                height:CGFloat = CGFloat.greatestFiniteMagnitude,
                                width:CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
        if let att = currentAtt {
            return att.value.sizeOfAttributedString()
        } else {
            return UIView.sizeFor(string: currentString, font: currentFont,lineSpacing: lineSpacing,height: height,width: width)
        }
    }
    
    public func getKitCurrentDimension(lineSpacing:CGFloat = 2.5,
                                       height:CGFloat = CGFloat.greatestFiniteMagnitude,
                                       width:CGFloat = CGFloat.greatestFiniteMagnitude) -> CGFloat {
        var total:CGFloat = 0
        switch layoutStyle {
        case .leftImageRightTitle,.leftTitleRightImage:
            total = self.getKitTitleSize(lineSpacing: lineSpacing,height: height,width: width).width + 5 + imageSize.width + midSpacing
        default:
            total = self.getKitTitleSize(lineSpacing: lineSpacing,height: height,width: width).height + 5 + imageSize.height + midSpacing
        }
        return total
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let margin: CGFloat = actionMargin
        // 以自身 bounds 为基础的可点击区域
        var largerBounds = bounds.insetBy(dx: -margin, dy: -margin)
        
        // 🚀 Bug修复（核心）：主动将子视图的 Frame 纳入可点击范围！
        // 如果 Button 自身没有被撑开 (bounds = 0)，但图片显示出来了，只要点击在图片上就能响应。
        if !imageView.isHidden {
            let imageBounds = imageView.frame.insetBy(dx: -margin, dy: -margin)
            largerBounds = largerBounds.union(imageBounds)
        }
        
        if !titleLabel.isHidden {
            let titleBounds = titleLabel.frame.insetBy(dx: -margin, dy: -margin)
            largerBounds = largerBounds.union(titleBounds)
        }
        
        return largerBounds.contains(point)
    }
}

public extension PTActionLayoutButton {
    
    func setBackgroundColor(_ color:UIColor,state:UIControl.State) {
        switch state {
        case .normal:
            normalBGColor = color
        case .highlighted:
            highlightedBGColor = color
        case .disabled:
            disabledBGColor = color
        case .selected:
            selectedBGColor = color
        default:
            break
        }
        updateAppearance()
    }
    
    func setTitleColor(_ titleColor:UIColor,state:UIControl.State) {
        switch state {
        case .normal:
            normalTitleColor = titleColor
        case .highlighted:
            highlightedTitleColor = titleColor
        case .disabled:
            disabledTitleColor = titleColor
        case .selected:
            selectedTitleColor = titleColor
        default:
            break
        }
        updateAppearance()
    }
    
    func setTitle(_ title:String,state:UIControl.State) {
        switch state {
        case .normal:
            normalString = title
        case .highlighted:
            highlightedString = title
        case .disabled:
            disabledString = title
        case .selected:
            selectedString = title
        default:
            break
        }
        updateAppearance()
    }
    
    func setTitleFont(_ font:UIFont,state:UIControl.State) {
        switch state {
        case .normal:
            normalFont = font
        case .highlighted:
            highlightedFont = font
        case .disabled:
            disabledFont = font
        case .selected:
            selectedFont = font
        default:
            break
        }
        updateAppearance()
    }

    func setImage(_ image:Any?,state:UIControl.State) {
        switch state {
        case .normal:
            normalImage = image
        case .highlighted:
            highlightedImage = image
        case .disabled:
            disabledImage = image
        case .selected:
            selectedImage = image
        default:
            break
        }
        updateAppearance()
    }
    
    func setAtt(_ att:ASAttributedString?,state:UIControl.State) {
        switch state {
        case .normal:
            normalAtt = att
        case .highlighted:
            highlightedAtt = att
        case .disabled:
            disabledAtt = att
        case .selected:
            selectedAtt = att
        default:
            break
        }
        updateAppearance()
    }
}

extension NSAttributedString {
    func containsAction() -> Bool {
        var hasAction = false
        self.enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { attrs, _, stop in
            if attrs.keys.contains(where: { key in
                // 檢查任一 key 表示為 action attribute
                String(describing: key).contains("action")
            }) {
                hasAction = true
                stop.pointee = true
            }
        }
        return hasAction
    }
}

public typealias PTControlTouchedBlock = (_ sender:PTActionLayoutButton) -> Void

public extension PTActionLayoutButton {
    
    @objc func addActionHandlers(handler:@escaping PTControlTouchedBlock) {
        self.addActionHandler(for: .touchUpInside) { [weak self] (sender:PTActionLayoutButton) in
            handler(sender)
            self?.updateAppearance()
        }
    }

    @objc func removeTargetAndAction() {
        removeTarget(nil, action: nil, for: .allEvents)
    }

    @available(*, deprecated, renamed: "removeTargetAndAction")
    @objc func removeTargerAndAction() {
        removeTargetAndAction()
    }
}
