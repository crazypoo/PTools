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
    
    // 🚀 性能优化：当布局属性发生改变时，标记需要重新更新约束并触发重新布局
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
    
    // 重写 `state` 属性
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

    // 🚀 性能优化：只有状态真正改变时，才去刷新外观，避免不必要的重绘
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
    
    // 🚀 性能优化：记录上一次布局的大小和是否需要更新约束的标志
    private var lastLayoutSize: CGSize = .zero
    private var needsConstraintUpdate: Bool = true
    
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
        addSubviews([imageView, titleLabel])
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setNeedsConstraintUpdate() {
        needsConstraintUpdate = true
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        updateAppearance()
    }
    
    // 🚀 性能优化：拦截 layoutSubviews，避免高频触发 SnapKit 重建约束
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // 只有当尺寸真的改变了，或者主动标记了属性改变时，才重新计算约束
        if bounds.size != lastLayoutSize || needsConstraintUpdate {
            lastLayoutSize = bounds.size
            needsConstraintUpdate = false
            updateLayoutConstraints()
        }
    }
    
    // 将原本在 layoutSubviews 里的 SnapKit 逻辑抽离出来
    private func updateLayoutConstraints() {
        switch layoutStyle {
        case .leftImageRightTitle:
            imageView.isHidden = false
            titleLabel.isHidden = false

            let currentImageSize: CGFloat = imageSize.width
            let maxWidth = frame.width - currentImageSize - midSpacing
            var titleWidth = getKitTitleSize(lineSpacing: labelLineSpace, height: frame.height).width + 5
            if titleWidth > maxWidth {
                titleWidth = maxWidth
            }
            let labelX = (frame.width - (currentImageSize + midSpacing + titleWidth)) / 2
            
            imageView.snp.remakeConstraints { make in
                make.left.equalToSuperview().inset(labelX)
                make.size.equalTo(self.imageSize)
                make.centerY.equalToSuperview()
            }
            titleLabel.snp.remakeConstraints { make in
                make.width.equalTo(titleWidth)
                make.top.bottom.equalToSuperview()
                make.left.equalTo(self.imageView.snp.right).offset(midSpacing)
            }
            
        case .leftTitleRightImage:
            imageView.isHidden = false
            titleLabel.isHidden = false

            let currentImageSize: CGFloat = imageSize.width
            let maxWidth = frame.width - currentImageSize - midSpacing
            var titleWidth = getKitTitleSize(lineSpacing: labelLineSpace, height: frame.height).width + 5
            if titleWidth > maxWidth {
                titleWidth = maxWidth
            }
            let labelX = (frame.width - (currentImageSize + midSpacing + titleWidth)) / 2
            
            titleLabel.snp.remakeConstraints { make in
                make.width.equalTo(titleWidth)
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview().inset(labelX)
            }
            imageView.snp.remakeConstraints { make in
                make.left.equalTo(self.titleLabel.snp.right).offset(midSpacing)
                make.size.equalTo(self.imageSize)
                make.centerY.equalToSuperview()
            }
            
        case .upImageDownTitle:
            imageView.isHidden = false
            titleLabel.isHidden = false

            let maxHeight = frame.height - imageSize.height - midSpacing
            let titleHeight = getKitTitleSize(lineSpacing: labelLineSpace, width: frame.width).height + 5
            
            var offSet: CGFloat = 0
            if titleHeight < maxHeight {
                offSet = maxHeight - titleHeight
                if offSet < 0 { offSet = 0 }
            }
            
            let labelY = (frame.height - (titleHeight + imageSize.height + midSpacing)) / 2
            imageView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.size.equalTo(self.imageSize)
                make.top.equalToSuperview().inset(labelY)
            }

            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.imageView.snp.bottom).offset(midSpacing)
                make.height.equalTo(maxHeight - offSet)
            }
            
        case .upTitleDownImage:
            imageView.isHidden = false
            titleLabel.isHidden = false
            
            let maxHeight = frame.height - imageSize.height - midSpacing
            var titleHeight = getKitTitleSize(lineSpacing: labelLineSpace, width: frame.width).height + 5
            if titleHeight > maxHeight {
                titleHeight = maxHeight
            }
            
            let labelY = (frame.height - (titleHeight + imageSize.height + midSpacing)) / 2

            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().inset(labelY)
                make.height.equalTo(titleHeight)
            }
            
            imageView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.size.equalTo(self.imageSize)
                make.top.equalTo(self.titleLabel.snp.bottom).offset(self.midSpacing)
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
                make.size.equalTo(self.imageSize)
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

    // 更新状态时的外观
    private func updateAppearance() {
        switch state {
        case .normal:
            currentString = normalString
            currentImage = normalImage ?? currentImage
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
            break
        }
        
        titleLabel.numberOfLines = numbersOfLine
        
        if let att = currentAtt {
            titleLabel.attributed.text = att
            
            // 🚀 Bug修复：优雅地管理手势，而不是每次刷新都添加新的
            if !att.value.containsAction() {
                if !(titleLabel.gestureRecognizers?.contains(labelTapGesture) ?? false) {
                    titleLabel.addGestureRecognizer(labelTapGesture)
                }
            } else {
                titleLabel.removeGestureRecognizer(labelTapGesture)
            }
        } else {
            // 清理可能存在的手势
            titleLabel.removeGestureRecognizer(labelTapGesture)
            
            // 🚀 内存泄漏修复：在 block 中使用 [weak self] 防止循环引用
            let nameAtt: ASAttributedString = """
                        \(wrap: .embedding("""
                        \(self.currentString,.foreground(self.currentTitleColor),.font(self.currentFont),.paragraph(.alignment(self.textAlignment),.lineSpacing(self.labelLineSpace),.lineBreakMode(self.textLineBreakMode)))
                        """),.action { [weak self] in
                            guard let self = self else { return }
                            if let block: PTControlTouchedBlock = objc_getAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey) as? PTControlTouchedBlock {
                                block(self)
                            }
                            PTGCDManager.gcdAfter(time: 0.1) { [weak self] in
                                self?.updateAppearance()
                            }
                        })
                        """
            self.titleLabel.attributed.text = nameAtt
        }
        
        backgroundColor = currentBGColor
        imageView.contentMode = self.imageContentMode
        
        if let currentImage = currentImage {
            imageView.loadImage(contentData: currentImage) // 你的自定义方法
        } else {
            imageView.image = nil
        }
        
        setNeedsDisplay() // 使用 setNeedsDisplay 而不是 setNeedsLayout，除非约束确实需要变
    }
    
    @objc private func handleLabelTap() {
        if let block: PTControlTouchedBlock = objc_getAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey) as? PTControlTouchedBlock {
            block(self)
        }
        PTGCDManager.gcdAfter(time: 0.1) { [weak self] in
            self?.updateAppearance()
        }
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
    private struct AssociatedKeys {
        // 🚀 规范修复：使用 UInt8 静态变量作为 AssociatedObject 的 Key 更加安全和标准
        static var UIButtonBlockKey: UInt8 = 0
    }
    
    @objc func addActionHandlers(handler:@escaping PTControlTouchedBlock) {
        objc_setAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        addTarget(self, action: #selector(actionTouched(sender:)), for: .touchUpInside)
    }
    
    @objc func actionTouched(sender:PTActionLayoutButton) {
        if let block = objc_getAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey) as? PTControlTouchedBlock {
            block(sender)
        }
        // 🚀 优化体验：对齐 `handleLabelTap` 的逻辑，点击后也触发 0.1s 的延时刷新
        PTGCDManager.gcdAfter(time: 0.1) { [weak self] in
            self?.updateAppearance()
        }
    }
    
    @objc func removeTargerAndAction() {
        removeTarget(nil, action: nil, for: .allEvents)
    }
}
