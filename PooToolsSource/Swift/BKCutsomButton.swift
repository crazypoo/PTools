//
//  BKCutsomButton.swift
//  xddmerchant
//
//  Created by innoo on 2019/8/15.
//  Copyright © 2019 kooun. All rights reserved.
//

import UIKit

//MARK: 左文右图（间隔5，Label的文字居左。）
public class BKRightImageButton: UIButton {

    private let space: CGFloat = 5.0
    private var margin: CGFloat = 5.0
    
    public init(frame: CGRect = .zero,
         margin: CGFloat = 5) {
        self.margin = margin
        super.init(frame: frame)
        titleLabel?.lineBreakMode = .byTruncatingTail
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var titleRect = super.titleRect(forContentRect: contentRect)
        let imgRect = super.imageRect(forContentRect: contentRect)
        titleRect.size.width = contentRect.size.width - (space + 2*margin + imgRect.size.width)
        return CGRect(origin: CGPoint(x: margin, y: titleRect.origin.y), size: titleRect.size)
    }
    
    public override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imgRect = super.imageRect(forContentRect: contentRect)
        let imgX = contentRect.size.width - imgRect.size.width - margin
        return CGRect(origin: CGPoint(x: imgX, y: imgRect.origin.y), size: imgRect.size)
    }
    
}

//MARK: 上图下文（间隔7，文字和图片水平垂直都居中）
public class BKTopImageButton: UIButton {
    
    private let space: CGFloat = 7.0
    
    public override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleRect = super.titleRect(forContentRect: contentRect)
        let imgRect = super.imageRect(forContentRect: contentRect)
        let titleX = (contentRect.size.width - titleRect.size.width) / 2.0
        let customContentHeight = imgRect.size.height + space + titleRect.size.height
        let imgY = (contentRect.size.height - customContentHeight) / 2.0
        let titleY = imgY + imgRect.size.height + space
        return CGRect(origin: CGPoint(x: titleX, y: titleY), size: titleRect.size)
    }
     
    public override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleRect = super.titleRect(forContentRect: contentRect)
        let imgRect = super.imageRect(forContentRect: contentRect)
        let imgX = (contentRect.size.width - imgRect.size.width) / 2.0
        let customContentHeight = imgRect.size.height + space + titleRect.size.height
        let imgY = (contentRect.size.height - customContentHeight) / 2.0
        return CGRect(origin: CGPoint(x: imgX, y: imgY), size: imgRect.size)
    }
    
}

@objc public enum BKLayoutButtonStyle : Int {
    case leftImageRightTitle // 系统默认
    case leftTitleRightImage
    case upImageDownTitle
    case upTitleDownImage
}

// MARK: - 上图下文 上文下图 左图右文(系统默认) 右图左文
/// 重写layoutSubviews的方式实现布局，忽略imageEdgeInsets、titleEdgeInsets和contentEdgeInsets
public class BKLayoutButton: UIButton {
    /// 布局方式
    public var layoutStyle: BKLayoutButtonStyle!
    /// 图片和文字的间距，默认值5
    private var midSpacing: CGFloat = 0.5
    /// 指定图片size
    private var imageSize :CGSize = .zero
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()

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

        leftViewFrame.origin.x = (frame.width - totalWidth) / 2.0
        leftViewFrame.origin.y = (frame.height - leftViewFrame.height) / 2.0
        leftView?.frame = leftViewFrame

        rightViewFrame.origin.x = leftViewFrame.maxX + midSpacing
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

    public func setMidSpacing(_ midSpacing: CGFloat) {
        self.midSpacing = midSpacing
        setNeedsLayout()
    }
    
    public func setImageSize(_ imageSize: CGSize) {
        self.imageSize = imageSize
        setNeedsLayout()
    }
    
}
