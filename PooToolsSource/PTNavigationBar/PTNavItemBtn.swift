//
//  PTNavItemBtn.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 27/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

open class PTNavItemBtn: UIButton {
    ///NavItemBtn frame发生改变时的回调，可在这个block中return修改后的frame
    public var jx_handleFrameBlock:((_ oldFrame:CGRect)->Void)?
    ///NavItemBtn的frame更新回调
    public var jx_barItemFrameUpdateBlock:((_ barItemBtn:PTNavItemBtn)->Void)?
    ///开始点击的回调
    public var jx_touchesBeganBlock:(()->Void)?
    ///结束点击的回调
    public var jx_touchesEndBlock:(()->Void)?

    ///设置NavItemBtn的固定宽度，若设置，则自动计算宽度无效，若要恢复初始值，可设置为-1
    public var jx_fixWidth:CGFloat = -1 {
        didSet {
            superview?.setValue(1, forKey: "shouldRefLayout")
            noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn的固定高度，若设置，则ZXNavDefalutItemSize无效，若要恢复初始值，可设置为-1
    public var jx_fixHeight:CGFloat = -1 {
        didSet {
            superview?.setValue(1, forKey: "shouldRefLayout")
            noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn距离左边元素的固定距离，若要恢复初始值，可设置为-1
    public var jx_fixMarginLeft:CGFloat = -1 {
        didSet {
            superview?.setValue(1, forKey: "shouldRefLayout")
            noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn距离右边元素的固定距离，若要恢复初始值，可设置为-1
    public var jx_fixMarginRight:CGFloat = -1 {
        didSet {
            superview?.setValue(1, forKey: "shouldRefLayout")
            noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn image的固定大小，若要恢复初始值，可设置为CGSizeZero
    public var jx_fixImageSize:CGSize = .zero {
        didSet {
            superview?.setValue(1, forKey: "shouldRefLayout")
            jx_layoutImageAndTitle()
            noticeUpdateFrame()
        }
    }
    ///禁止自动调整按钮图片和文字的布局，若要使contentEdgeInsets、titleEdgeInsets、imageEdgeInsets等，则需要将此属性设置为NO
    public var jx_disableAutoLayoutImageAndTitle:Bool = false {
        didSet {
            jx_layoutImageAndTitle()
            noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn文字自动计算宽度后的附加宽度
    public var jx_textAttachWidth:CGFloat = 0 {
        didSet {
            superview?.setValue(1, forKey: "shouldRefLayout")
            jx_layoutImageAndTitle()
            noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn文字的附加高度
    public var jx_textAttachHeight:CGFloat = 0 {
        didSet {
            superview?.setValue(1, forKey: "shouldRefLayout")
            jx_layoutImageAndTitle()
            noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn内部图片x轴的偏移量，负数代表左移，无title且设置了jx_fixImageSize后生效，仅改变内容imageView的位移，不会改变原始NavItemBtn的frame
    public var jx_imageOffsetX:CGFloat = 0 {
        didSet {
            jx_layoutImageAndTitle()
        }
    }
    ///设置NavItemBtn的tintColor仅用于UIControlStateNormal状态(请在jx_imageColor和jx_tintColor之前设置)，默认为NO
    public var jx_useTintColorOnlyInStateNormal:UIColor? = nil
    ///设置NavItemBtn的自定义view
    public var jx_customView:UIView? {
        get {
            nil
        } set {
            if jx_customView != nil {
                if subviews.contains(where: {$0 == jx_customView!}) {
                    jx_customView?.removeFromSuperview()
                }
                self.jx_customView = nil
                noticeUpdateFrame()
            }
            
            addSubview(newValue!)
            if newValue?.frame == .zero {
                let customViewWidth = jx_fixWidth < 0 ? PTNavDefalutItemSize : jx_fixWidth
                let customViewHeight = jx_fixHeight < 0 ? PTNavDefalutItemSize : jx_fixWidth
                newValue?.frame = CGRect(x: 0, y: 0, width: customViewWidth, height: customViewHeight)
            }
            
            jx_fixWidth = newValue!.frame.size.width + newValue!.frame.origin.x * 2
            jx_fixHeight = newValue!.frame.size.height + newValue!.frame.origin.y * 2
            
            setImage(nil, for: .normal)
            setTitle("", for: .normal)
            setAttributedTitle(nil, for: .normal)
        }
    }
    ///设置NavItemBtn的tintColor
    public var jx_tintColor:UIColor? = nil {
        didSet {
            tintColor = jx_tintColor
            restImage()
            resetTitle()
        }
    }
    ///设置NavItemBtn的image颜色
    public var jx_imageColor:UIColor? = nil {
        didSet {
            tintColor = jx_imageColor
            restImage()
        }
    }
    ///设置NavItemBtn的image颜色
    public var jx_fontSize:CGFloat? = 0 {
        didSet {
            titleLabel?.font = .appfont(size: jx_fontSize!)
            superview?.setValue(1, forKey: "shouldRefLayout")
            jx_layoutImageAndTitle()
            noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn的cornerRadius为高度的一半(圆形圆角)
    public var jx_setCornerRadiusRounded:Bool? = false {
        didSet {
            noticeUpdateFrame()
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        jx_layoutImageAndTitle()
    }
    
    open override func setTitle(_ title: String?, for state: UIControl.State) {
        if jx_customView != nil && !(title ?? "").stringIsEmpty() {
            return
        }
        super.setTitle(title, for: state)
        if jx_tintColor != nil {
            setTitleColor(jx_tintColor!, for: state)
        }
        jx_layoutImageAndTitle()
        noticeUpdateFrame()
    }
    
    open override func setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State) {
        if jx_customView != nil && !(title?.string ?? "").stringIsEmpty() {
            return
        }
        super.setAttributedTitle(title, for: state)
        jx_layoutImageAndTitle()
        noticeUpdateFrame()
    }
    
    open override func setImage(_ image: UIImage?, for state: UIControl.State) {
        if jx_customView != nil && image != nil {
            return
        }
        
        var newImage = image ?? UIImage()
        if jx_tintColor != nil {
            newImage = newImage.withRenderingMode(.alwaysTemplate)
        } else {
            newImage = newImage.withRenderingMode(.alwaysOriginal)
        }
        imageView?.image = newImage
        jx_layoutImageAndTitle()
        noticeUpdateFrame()
    }
    
    open override var isSelected: Bool {
        didSet {
            jx_layoutImageAndTitle()
            noticeUpdateFrame()
        }
    }
    
    open override var isHighlighted: Bool {
        didSet {
            jx_layoutImageAndTitle()
            noticeUpdateFrame()
        }
    }
    
    open override var isEnabled: Bool {
        didSet {
            jx_layoutImageAndTitle()
            noticeUpdateFrame()
        }
    }
    
    public func jx_updateLayput() {
        jx_layoutImageAndTitle()
        noticeUpdateFrame()
    }
    
    private func resetTitle() {
        let isStateFocused = state == .focused
        if jx_useTintColorOnlyInStateNormal != nil || isStateFocused {
            setTitle(self.title(for: .normal), for: .normal)
        } else {
            setTitle(currentTitle, for: state)
        }
    }
    
    private func restImage() {
        let isStateFocused = state == .focused
        if jx_useTintColorOnlyInStateNormal != nil || isStateFocused {
            setImage(self.image(for: .normal), for: .normal)
        } else {
            setImage(currentImage, for: state)
        }
    }
    
    public func jx_layoutImageAndTitle() {
        if jx_disableAutoLayoutImageAndTitle {
            return
        }
        
        var btnW:CGFloat = 0
        if currentAttributedTitle != nil {
            btnW = UIView.sizeFor(string: currentAttributedTitle!.string, font: titleLabel?.font ?? .systemFont(ofSize: 14), height: 34, width: CGFloat(MAXFLOAT)).width + 5
        } else {
            if !(currentTitle ?? "").stringIsEmpty() {
                btnW = UIView.sizeFor(string: currentTitle!, font: titleLabel?.font ?? .systemFont(ofSize: 14), height: 34, width: CGFloat(MAXFLOAT)).width + 5
            }
        }
        
        btnW += jx_textAttachWidth
        if imageView?.image != nil {
            var useFixImageSize = false
            var imageWidth = frame.size.height
            var imageHeight = frame.size.height
            if jx_fixImageSize != .zero {
                imageWidth = jx_fixImageSize.width
                imageHeight = jx_fixImageSize.height
                useFixImageSize = true
            }
            
            var imageViewX:CGFloat = 0
            if !((currentTitle ?? "").stringIsEmpty() || (currentAttributedTitle?.string ?? "").stringIsEmpty()) && useFixImageSize {
                imageViewX = (frame.size.width - imageWidth) / 2 + jx_imageOffsetX
            }
            
            self.imageView?.frame = CGRect(x: imageViewX, y: (frame.size.height - imageHeight) / 2, width: imageWidth, height: imageHeight)
            titleLabel?.frame = CGRect(x: imageView!.frame.maxX, y: 0, width: btnW, height: frame.size.height)
        } else {
            imageView?.frame = .zero
            titleLabel?.frame = CGRect(x: 0, y: 0, width: btnW, height: frame.size.height)
        }
    }
    
    private func noticeUpdateFrame() {
        if jx_barItemFrameUpdateBlock != nil {
            jx_barItemFrameUpdateBlock!(self)
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if jx_touchesBeganBlock != nil {
            jx_touchesBeganBlock!()
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if jx_touchesEndBlock != nil {
            jx_touchesEndBlock!()
        }
    }
}
