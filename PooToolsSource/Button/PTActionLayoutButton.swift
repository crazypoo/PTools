//
//  PTActionLayoutButton.swift
//  YD1688
//
//  Created by 邓杰豪 on 12/29/24.
//  Copyright © 2024 YongDong. All rights reserved.
//

import UIKit

public class PTActionLayoutButton: UIControl {

    public var layoutStyle:PTLayoutButtonStyle = .leftImageRightTitle {
        didSet {
            updateAppearance()
        }
    }
        
    public var imageSize:CGSize = .zero {
        didSet {
            updateAppearance()
        }
    }
    
    public var midSpacing:CGFloat = 0 {
        didSet {
            updateAppearance()
        }
    }
        
    public var labelLineSpace:NSNumber = 2 {
        didSet {
            updateAppearance()
        }
    }
    
    public var textAlignment:NSTextAlignment = .center {
        didSet {
            updateAppearance()
        }
    }
    
    public var numbersOfLine:Int = 0 {
        didSet {
            updateAppearance()
        }
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

    // 设置可用状态
    public override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }

    // 设置选中状态
    public override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    // 设置高亮状态
    public override var isHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    fileprivate lazy var imageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        let tap = UITapGestureRecognizer { sender in
            self.addTarget(self, action: #selector(self.actionTouched(sender:)), for: .touchUpInside)
        }
        view.addGestureRecognizer(tap)
        return view
    }()
    
    fileprivate lazy var titleLabel:UILabel = {
        let view = UILabel()
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews([imageView,titleLabel])
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if currentImage != nil && !currentString.stringIsEmpty() {
            switch layoutStyle {
            case .leftImageRightTitle:
                let maxWidth = frame.width - imageSize.width - midSpacing
                var titleWidth = titleLabel.sizeFor(lineSpacing: labelLineSpace,height: frame.height).width + 5
                if titleWidth > maxWidth {
                    titleWidth = maxWidth
                }
                let labelX = (frame.width - titleWidth) / 2 + imageSize.width / 2 + midSpacing
                titleLabel.snp.makeConstraints { make in
                    make.width.equalTo(titleWidth)
                    make.top.bottom.equalToSuperview()
                    make.left.equalToSuperview().inset(labelX)
                }
                
                imageView.snp.makeConstraints { make in
                    make.right.equalTo(self.titleLabel.snp.left).offset(-midSpacing)
                    make.size.equalTo(self.imageSize)
                    make.centerY.equalToSuperview()
                }
            case .leftTitleRightImage:
                let maxWidth = frame.width - imageSize.width - midSpacing
                var titleWidth = titleLabel.sizeFor(lineSpacing: labelLineSpace,height: frame.height).width + 5
                if titleWidth > maxWidth {
                    titleWidth = maxWidth
                }
                let labelX = (frame.width - (imageSize.width + midSpacing + titleWidth)) / 2
                titleLabel.snp.makeConstraints { make in
                    make.width.equalTo(titleWidth)
                    make.top.bottom.equalToSuperview()
                    make.left.equalToSuperview().inset(labelX)
                }
                imageView.snp.makeConstraints { make in
                    make.left.equalTo(self.titleLabel.snp.right).offset(midSpacing)
                    make.size.equalTo(self.imageSize)
                    make.centerY.equalToSuperview()
                }
            case .upImageDownTitle:
                let maxHeight = frame.height - imageSize.height - midSpacing
                var titleHeight = titleLabel.sizeFor(lineSpacing: labelLineSpace,width: frame.width).height + 5
                if titleHeight > maxHeight {
                    titleHeight = maxHeight
                }
                let labelY = (frame.height - titleHeight) / 2 + imageSize.height / 2 + midSpacing

                titleLabel.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalToSuperview().inset(labelY)
                    make.height.equalTo(titleHeight)
                }
                
                imageView.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.size.equalTo(self.imageSize)
                    make.bottom.equalTo(self.titleLabel.snp.top).offset(-self.midSpacing)
                }
            case .upTitleDownImage:
                let maxHeight = frame.height - imageSize.height - midSpacing
                var titleHeight = titleLabel.sizeFor(lineSpacing: labelLineSpace,width: frame.width).height + 5
                if titleHeight > maxHeight {
                    titleHeight = maxHeight
                }
                let labelY = (frame.height - (imageSize.height + midSpacing + titleHeight)) / 2

                titleLabel.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalToSuperview().inset(labelY)
                    make.height.equalTo(titleHeight)
                }
                
                imageView.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.size.equalTo(self.imageSize)
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(self.midSpacing)
                }
            default:
                break
            }
            
        } else if currentImage == nil && !currentString.stringIsEmpty() {
            titleLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else if currentImage != nil && currentString.stringIsEmpty() {
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    fileprivate var normalString = ""
    fileprivate var highlightedString = ""
    fileprivate var disabledString = ""
    fileprivate var selectedString = ""
    public var currentString = ""
    
    fileprivate var normalImage:Any?
    fileprivate var highlightedImage:Any?
    fileprivate var disabledImage:Any?
    fileprivate var selectedImage:Any?
    public var currentImage:Any? = nil

    fileprivate var normalTitleColor:UIColor = .black
    fileprivate var highlightedTitleColor:UIColor = .black
    fileprivate var disabledTitleColor:UIColor = .black
    fileprivate var selectedTitleColor:UIColor = .black
    public var currentTitleColor:UIColor = .black

    fileprivate var normalFont:UIFont = .appfont(size: 14)
    fileprivate var highlightedFont:UIFont?
    fileprivate var disabledFont:UIFont?
    fileprivate var selectedFont:UIFont?
    public var currentFont:UIFont = .appfont(size: 14)
    
    // 更新状态时的外观
    private func updateAppearance() {
        switch state {
        case .normal:
            currentString = normalString
            currentImage = normalImage ?? currentImage
            currentTitleColor = normalTitleColor
            currentFont = normalFont
        case .highlighted:
            currentString = highlightedString.stringIsEmpty() ? normalString : highlightedString
            currentImage = highlightedImage ?? normalImage
            currentTitleColor = highlightedTitleColor
            currentFont = highlightedFont ?? normalFont
        case .disabled:
            currentString = disabledString.stringIsEmpty() ? normalString : disabledString
            currentImage = disabledImage ?? normalImage
            currentTitleColor = disabledTitleColor
            currentFont = disabledFont ?? normalFont
        case .selected:
            currentString = selectedString.stringIsEmpty() ? normalString : selectedString
            currentImage = selectedImage ?? normalImage
            currentTitleColor = selectedTitleColor
            currentFont = selectedFont ?? normalFont
        default:
            break
        }
        titleLabel.textColor = currentTitleColor
        titleLabel.numberOfLines = numbersOfLine
        titleLabel.textAlignment = textAlignment
        titleLabel.font = currentFont
        titleLabel.text = currentString
        if let currentImage = currentImage {
            imageView.loadImage(contentData: currentImage)
        }
        setNeedsLayout()
    }
    
    public func getKitTitleSize(lineSpacing:NSNumber? = nil,
                            height:CGFloat = CGFloat.greatestFiniteMagnitude,
                            width:CGFloat = CGFloat.greatestFiniteMagnitude) ->CGSize {
        return UIView.sizeFor(string: currentString, font: currentFont,lineSpacing: lineSpacing,height: height,width: width)
    }
    
    public func getKitCurrentDimension(lineSpacing:NSNumber? = nil,
                            height:CGFloat = CGFloat.greatestFiniteMagnitude,
                            width:CGFloat = CGFloat.greatestFiniteMagnitude) ->CGFloat {
        var total:CGFloat = 0
        switch layoutStyle {
        case .leftImageRightTitle,.leftTitleRightImage:
            total = self.getKitTitleSize(lineSpacing: lineSpacing,height: height,width: width).width + 5 + imageSize.width + midSpacing
        default:
            total = self.getKitTitleSize(lineSpacing: lineSpacing,height: height,width: width).height + 5 + imageSize.height + midSpacing
        }
        return total
    }
}

public extension PTActionLayoutButton {
    
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

    func setImage(_ image:Any!,state:UIControl.State) {
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
}

public typealias LayoutTouchedBlock = (_ sender:PTActionLayoutButton) -> Void

public extension PTActionLayoutButton {
    private struct AssociatedKeys {
        static var UIButtonBlockKey = 998
    }
    
    @objc func addActionHandlers(handler:@escaping LayoutTouchedBlock) {
        objc_setAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        addTarget(self, action: #selector(actionTouched(sender:)), for: .touchUpInside)
    }
    
    @objc func actionTouched(sender:PTActionLayoutButton) {
        let block:LayoutTouchedBlock = objc_getAssociatedObject(self, &AssociatedKeys.UIButtonBlockKey) as! LayoutTouchedBlock
        block(sender)
    }
    
    @objc func removeTargerAndAction() {
        removeTarget(nil, action: nil, for: .allEvents)
    }
}
