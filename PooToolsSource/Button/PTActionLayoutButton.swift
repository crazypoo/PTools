//
//  PTActionLayoutButton.swift
//  YD1688
//
//  Created by 邓杰豪 on 12/29/24.
//  Copyright © 2024 YongDong. All rights reserved.
//

import UIKit
import PooTools

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
    
    public var midSpace:CGFloat = 0 {
        didSet {
            updateAppearance()
        }
    }
    
    public var labelFont:UIFont = .appfont(size: 14) {
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
                let maxWidth = frame.width - imageSize.width - midSpace
                var titleWidth = titleLabel.sizeFor(lineSpacing: labelLineSpace,height: frame.height).width + 5
                if titleWidth > maxWidth {
                    titleWidth = maxWidth
                }
                let labelX = (frame.width - titleWidth) / 2 + imageSize.width / 2 + midSpace
                titleLabel.snp.makeConstraints { make in
                    make.width.equalTo(titleWidth)
                    make.top.bottom.equalToSuperview()
                    make.left.equalToSuperview().inset(labelX)
                }
                
                imageView.snp.makeConstraints { make in
                    make.right.equalTo(self.titleLabel.snp.left).offset(-midSpace)
                    make.size.equalTo(self.imageSize)
                    make.centerY.equalToSuperview()
                }
            case .leftTitleRightImage:
                let maxWidth = frame.width - imageSize.width - midSpace
                var titleWidth = titleLabel.sizeFor(lineSpacing: labelLineSpace,height: frame.height).width + 5
                if titleWidth > maxWidth {
                    titleWidth = maxWidth
                }
                let labelX = (frame.width - (imageSize.width + midSpace + titleWidth)) / 2
                titleLabel.snp.makeConstraints { make in
                    make.width.equalTo(titleWidth)
                    make.top.bottom.equalToSuperview()
                    make.left.equalToSuperview().inset(labelX)
                }
                imageView.snp.makeConstraints { make in
                    make.left.equalTo(self.titleLabel.snp.right).offset(midSpace)
                    make.size.equalTo(self.imageSize)
                    make.centerY.equalToSuperview()
                }
            case .upImageDownTitle:
                let maxHeight = frame.height - imageSize.height - midSpace
                var titleHeight = titleLabel.sizeFor(lineSpacing: labelLineSpace,width: frame.width).height + 5
                if titleHeight > maxHeight {
                    titleHeight = maxHeight
                }
                let labelY = (frame.height - titleHeight) / 2 + imageSize.height / 2 + midSpace

                titleLabel.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalToSuperview().inset(labelY)
                    make.height.equalTo(titleHeight)
                }
                
                imageView.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.size.equalTo(self.imageSize)
                    make.bottom.equalTo(self.titleLabel.snp.top).offset(-self.midSpace)
                }
            case .upTitleDownImage:
                let maxHeight = frame.height - imageSize.height - midSpace
                var titleHeight = titleLabel.sizeFor(lineSpacing: labelLineSpace,width: frame.width).height + 5
                if titleHeight > maxHeight {
                    titleHeight = maxHeight
                }
                let labelY = (frame.height - (imageSize.height + midSpace + titleHeight)) / 2

                titleLabel.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalToSuperview().inset(labelY)
                    make.height.equalTo(titleHeight)
                }
                
                imageView.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.size.equalTo(self.imageSize)
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(self.midSpace)
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
    fileprivate var currentString = ""
    
    fileprivate var normalImage:UIImage?
    fileprivate var highlightedImage:UIImage?
    fileprivate var disabledImage:UIImage?
    fileprivate var selectedImage:UIImage?
    fileprivate var currentImage:UIImage? = nil

    fileprivate var normalTitleColor:UIColor = .black
    fileprivate var highlightedTitleColor:UIColor = .black
    fileprivate var disabledTitleColor:UIColor = .black
    fileprivate var selectedTitleColor:UIColor = .black
    fileprivate var currentTitleColor:UIColor = .black

    // 更新状态时的外观
    private func updateAppearance() {
        switch state {
        case .normal:
            currentString = normalString
            currentImage = normalImage ?? currentImage
            currentTitleColor = normalTitleColor
        case .highlighted:
            currentString = highlightedString.stringIsEmpty() ? normalString : highlightedString
            currentImage = highlightedImage ?? normalImage
            currentTitleColor = highlightedTitleColor
        case .disabled:
            currentString = disabledString.stringIsEmpty() ? normalString : disabledString
            currentImage = disabledImage ?? normalImage
            currentTitleColor = disabledTitleColor
        case .selected:
            currentString = selectedString.stringIsEmpty() ? normalString : selectedString
            currentImage = selectedImage ?? normalImage
            currentTitleColor = selectedTitleColor
        default:
            break
        }
        titleLabel.textColor = currentTitleColor
        titleLabel.numberOfLines = numbersOfLine
        titleLabel.textAlignment = textAlignment
        titleLabel.font = labelFont
        titleLabel.text = currentString
        imageView.image = currentImage
        setNeedsLayout()
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
    
    func setImage(_ image:UIImage!,state:UIControl.State) {
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
