//
//  BKCutsomButton.swift
//  xddmerchant
//
//  Created by innoo on 2019/8/15.
//  Copyright © 2019 kooun. All rights reserved.
//

import UIKit

@objc public enum BKLayoutButtonStyle : Int {
    case leftImageRightTitle // 系统默认
    case leftTitleRightImage
    case upImageDownTitle
    case upTitleDownImage
}

// MARK: - 上图下文 上文下图 左图右文(系统默认) 右图左文
/// 重写layoutSubviews的方式实现布局，忽略imageEdgeInsets、titleEdgeInsets和contentEdgeInsets
@objcMembers
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
