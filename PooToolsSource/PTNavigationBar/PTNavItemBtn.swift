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
            self.superview?.setValue(1, forKey: "shouldRefLayout")
            self.noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn的固定高度，若设置，则ZXNavDefalutItemSize无效，若要恢复初始值，可设置为-1
    public var jx_fixHeight:CGFloat = -1 {
        didSet {
            self.superview?.setValue(1, forKey: "shouldRefLayout")
            self.noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn距离左边元素的固定距离，若要恢复初始值，可设置为-1
    public var jx_fixMarginLeft:CGFloat = -1 {
        didSet {
            self.superview?.setValue(1, forKey: "shouldRefLayout")
            self.noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn距离右边元素的固定距离，若要恢复初始值，可设置为-1
    public var jx_fixMarginRight:CGFloat = -1 {
        didSet {
            self.superview?.setValue(1, forKey: "shouldRefLayout")
            self.noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn image的固定大小，若要恢复初始值，可设置为CGSizeZero
    public var jx_fixImageSize:CGSize = .zero {
        didSet {
            self.superview?.setValue(1, forKey: "shouldRefLayout")
            self.jx_layoutImageAndTitle()
            self.noticeUpdateFrame()
        }
    }
    ///禁止自动调整按钮图片和文字的布局，若要使contentEdgeInsets、titleEdgeInsets、imageEdgeInsets等，则需要将此属性设置为NO
    public var jx_disableAutoLayoutImageAndTitle:Bool = false {
        didSet {
            self.jx_layoutImageAndTitle()
            self.noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn文字自动计算宽度后的附加宽度
    public var jx_textAttachWidth:CGFloat = 0 {
        didSet {
            self.superview?.setValue(1, forKey: "shouldRefLayout")
            self.jx_layoutImageAndTitle()
            self.noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn文字的附加高度
    public var jx_textAttachHeight:CGFloat = 0 {
        didSet {
            self.superview?.setValue(1, forKey: "shouldRefLayout")
            self.jx_layoutImageAndTitle()
            self.noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn内部图片x轴的偏移量，负数代表左移，无title且设置了jx_fixImageSize后生效，仅改变内容imageView的位移，不会改变原始NavItemBtn的frame
    public var jx_imageOffsetX:CGFloat = 0 {
        didSet {
            self.jx_layoutImageAndTitle()
        }
    }
    ///设置NavItemBtn的tintColor仅用于UIControlStateNormal状态(请在jx_imageColor和jx_tintColor之前设置)，默认为NO
    public var jx_useTintColorOnlyInStateNormal:UIColor? = nil
    ///设置NavItemBtn的自定义view
    public var jx_customView:UIView? {
        get {
            return nil
        } set {
            if self.jx_customView != nil {
                if self.subviews.contains(where: {$0 == self.jx_customView!}) {
                    self.jx_customView?.removeFromSuperview()
                }
                self.jx_customView = nil
                self.noticeUpdateFrame()
            }
            
            self.addSubview(newValue!)
            if newValue?.frame == .zero {
                let customViewWidth = self.jx_fixWidth < 0 ? PTNavDefalutItemSize : self.jx_fixWidth
                let customViewHeight = self.jx_fixHeight < 0 ? PTNavDefalutItemSize : self.jx_fixWidth
                newValue?.frame = CGRect(x: 0, y: 0, width: customViewWidth, height: customViewHeight)
            }
            
            self.jx_fixWidth = newValue!.frame.size.width + newValue!.frame.origin.x * 2
            self.jx_fixHeight = newValue!.frame.size.height + newValue!.frame.origin.y * 2
            
            self.setImage(nil, for: .normal)
            self.setTitle("", for: .normal)
            setAttributedTitle(nil, for: .normal)
        }
    }
    ///设置NavItemBtn的tintColor
    public var jx_tintColor:UIColor? = nil {
        didSet {
            self.tintColor = self.jx_tintColor
            self.restImage()
            self.resetTitle()
        }
    }
    ///设置NavItemBtn的image颜色
    public var jx_imageColor:UIColor? = nil {
        didSet {
            self.tintColor = self.jx_imageColor
            self.restImage()
        }
    }
    ///设置NavItemBtn的image颜色
    public var jx_fontSize:CGFloat? = 0 {
        didSet {
            self.titleLabel?.font = .appfont(size: self.jx_fontSize!)
            self.superview?.setValue(1, forKey: "shouldRefLayout")
            self.jx_layoutImageAndTitle()
            self.noticeUpdateFrame()
        }
    }
    ///设置NavItemBtn的cornerRadius为高度的一半(圆形圆角)
    public var jx_setCornerRadiusRounded:Bool? = false {
        didSet {
            self.noticeUpdateFrame()
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.jx_layoutImageAndTitle()
    }
    
    open override func setTitle(_ title: String?, for state: UIControl.State) {
        if self.jx_customView != nil && !(title ?? "").stringIsEmpty() {
            return
        }
        super.setTitle(title, for: state)
        if self.jx_tintColor != nil {
            self.setTitleColor(self.jx_tintColor!, for: state)
        }
        self.jx_layoutImageAndTitle()
        self.noticeUpdateFrame()
    }
    
    open override func setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State) {
        if self.jx_customView != nil && !(title?.string ?? "").stringIsEmpty() {
            return
        }
        super.setAttributedTitle(title, for: state)
        self.jx_layoutImageAndTitle()
        self.noticeUpdateFrame()
    }
    
    open override func setImage(_ image: UIImage?, for state: UIControl.State) {
        if self.jx_customView != nil && image != nil {
            return
        }
        
        var newImage = image ?? UIImage()
        if self.jx_tintColor != nil {
            newImage = newImage.withRenderingMode(.alwaysTemplate)
        } else {
            newImage = newImage.withRenderingMode(.alwaysOriginal)
        }
        self.imageView?.image = newImage
        self.jx_layoutImageAndTitle()
        self.noticeUpdateFrame()
    }
    
    open override var isSelected: Bool {
        didSet {
            self.jx_layoutImageAndTitle()
            self.noticeUpdateFrame()
        }
    }
    
    open override var isHighlighted: Bool {
        didSet {
            self.jx_layoutImageAndTitle()
            self.noticeUpdateFrame()
        }
    }
    
    open override var isEnabled: Bool {
        didSet {
            self.jx_layoutImageAndTitle()
            self.noticeUpdateFrame()
        }
    }
    
    public func jx_updateLayput() {
        self.jx_layoutImageAndTitle()
        self.noticeUpdateFrame()
    }
    
    private func resetTitle() {
        let isStateFocused = self.state == .focused
        if self.jx_useTintColorOnlyInStateNormal != nil || isStateFocused {
            self.setTitle(self.title(for: .normal), for: .normal)
        } else {
            self.setTitle(self.currentTitle, for: self.state)
        }
    }
    
    private func restImage() {
        let isStateFocused = self.state == .focused
        if self.jx_useTintColorOnlyInStateNormal != nil || isStateFocused {
            self.setImage(self.image(for: .normal), for: .normal)
        } else {
            self.setImage(self.currentImage, for: self.state)
        }
    }
    
    public func jx_layoutImageAndTitle() {
        if self.jx_disableAutoLayoutImageAndTitle {
            return
        }
        
        var btnW:CGFloat = 0
        if self.currentAttributedTitle != nil {
            btnW = UIView.sizeFor(string: self.currentAttributedTitle!.string, font: self.titleLabel?.font ?? .systemFont(ofSize: 14), height: 34, width: CGFloat(MAXFLOAT)).width + 5
        } else {
            if !(self.currentTitle ?? "").stringIsEmpty() {
                btnW = UIView.sizeFor(string: self.currentTitle!, font: self.titleLabel?.font ?? .systemFont(ofSize: 14), height: 34, width: CGFloat(MAXFLOAT)).width + 5
            }
        }
        
        btnW += self.jx_textAttachWidth
        if self.imageView?.image != nil {
            var useFixImageSize = false
            var imageWidth = self.frame.size.height
            var imageHeight = self.frame.size.height
            if self.jx_fixImageSize != .zero {
                imageWidth = self.jx_fixImageSize.width
                imageHeight = self.jx_fixImageSize.height
                useFixImageSize = true
            }
            
            var imageViewX:CGFloat = 0
            if !((self.currentTitle ?? "").stringIsEmpty() || (self.currentAttributedTitle?.string ?? "").stringIsEmpty()) && useFixImageSize {
                imageViewX = (self.frame.size.width - imageWidth) / 2 + self.jx_imageOffsetX
            }
            
            self.imageView?.frame = CGRect(x: imageViewX, y: (self.frame.size.height - imageHeight) / 2, width: imageWidth, height: imageHeight)
            self.titleLabel?.frame = CGRect(x: self.imageView!.frame.maxX, y: 0, width: btnW, height: self.frame.size.height)
        } else {
            self.imageView?.frame = .zero
            self.titleLabel?.frame = CGRect(x: 0, y: 0, width: btnW, height: self.frame.size.height)
        }
    }
    
    private func noticeUpdateFrame() {
        if self.jx_barItemFrameUpdateBlock != nil {
            self.jx_barItemFrameUpdateBlock!(self)
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if self.jx_touchesBeganBlock != nil {
            self.jx_touchesBeganBlock!()
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if self.jx_touchesEndBlock != nil {
            self.jx_touchesEndBlock!()
        }
    }
}
