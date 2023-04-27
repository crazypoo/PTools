//
//  PTNavigationBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 27/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import AttributedString

open class PTNavigationBar: UIView {
    
    private var shouldRefLayou:Bool = false
    private var shouldRelayoutSubviews:Bool = false
    
    /// 是否开启系统导航栏与自定义导航栏平滑过渡(务必仅当存在系统导航栏与自定义导航栏过渡时启用，非必要请勿启用，否则可能造成自定义导航栏跳动，若当前控制器显示了系统导航栏，请于当前控制器pop的上一个控制器中使用self.zx_navEnableSmoothFromSystemNavBar = YES)
    public var jx_navEnableSmoothFromSystemNavBar:Bool = false
    
    /// 导航栏背景色Components
    public var jx_backgroundColorComponents:[CGFloat] = []
    
    open override var backgroundColor: UIColor? {
        didSet {
            if self.jx_navEnableSmoothFromSystemNavBar {
                AppWindows?.backgroundColor = self.backgroundColor
            }
            
            var components:[CGFloat] = [0,0,0]
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            var resultingPixel:[Int] = [0,0,0,0]
            let bitmap:CGContext = CGContext(data: &resultingPixel , width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            bitmap.setFillColor(self.backgroundColor?.cgColor ?? UIColor.clear.cgColor)
            bitmap.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            for i in 0...components.count {
                components[i] = CGFloat(resultingPixel[i] / 255)
            }
            self.jx_backgroundColorComponents = components
        }
    }
    
    /// 导航栏背景渐变的CAGradientLayer
    public var jx_gradientLayer:CAGradientLayer? {
        get {
            return nil
        } set {
            self.jx_gradientLayer?.removeFromSuperlayer()
            
            PTGCDManager.gcdAfter(time: 0.1) {
                if newValue != nil {
                    self.layer.insertSublayer(newValue!, at: 0)
                }
            }
        }
    }
    /// 自定义的导航栏View，是ZXNavigationBar的SubView
    public var jx_customNavBar:UIView?
    /// 自定义的titleView，是TitleView的SubView
    public var jx_customTitleView:UIView?
    
    /// 设置左右Button的大小(宽高相等)
    public var jx_itemSize:CGFloat = PTNavDefalutItemSize {
        didSet {
            self.shouldRefLayou = true
            self.relayoutSubviews()
            PTGCDManager.gcdAfter(time: 0.1) {
                self.reloadInputViews()
            }
        }
    }
    /// 设置Item之间的间距
    public var jx_itemMargin:CGFloat = PTNavDefalutItemMargin {
        didSet {
            self.shouldRefLayou = true
            self.relayoutSubviews()
        }
    }
    ///分割线的高度，默认为1
    public var jx_lineViewHeight:CGFloat = 0.5 {
        didSet {
            self.shouldRefLayou = true
            self.relayoutSubviews()
        }
    }

    /// 导航栏背景ImageView
    public var jx_backImage:UIImage? {
        didSet {
            self.jx_backImageView.image = self.jx_backImage
        }
    }


    /// 导航栏背景ImageView
    public lazy var jx_backImageView:PTNavBackImageView = {
        let view = PTNavBackImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    /// 最左侧Button
    public lazy var jx_leftBtn:PTNavItemBtn = {
        let view = PTNavItemBtn()
        view.titleLabel?.font = .appfont(size: PTNavDefalutItemFontSize)
        view.titleLabel?.textAlignment = .center
        view.setTitleColor(PTNavDefalutItemTextColor, for: .normal)
        view.titleLabel?.adjustsFontSizeToFitWidth = true
        view.jx_barItemFrameUpdateBlock = { sender in
            self.shouldRefLayou = true
            self.relayoutSubviews()
        }
        return view
    }()
    
    /// 最右侧Button
    public lazy var jx_rightBtn:PTNavItemBtn = {
        let view = PTNavItemBtn()
        view.titleLabel?.font = .appfont(size: PTNavDefalutItemFontSize)
        view.titleLabel?.textAlignment = .center
        view.setTitleColor(PTNavDefalutItemTextColor, for: .normal)
        view.titleLabel?.adjustsFontSizeToFitWidth = true
        view.jx_barItemFrameUpdateBlock = { sender in
            self.shouldRefLayou = true
            self.relayoutSubviews()
        }
        return view
    }()

    /// 左侧第二个Button
    public lazy var jx_subLeftBtn:PTNavItemBtn = {
        let view = PTNavItemBtn()
        view.titleLabel?.font = .appfont(size: PTNavDefalutItemFontSize)
        view.titleLabel?.textAlignment = .center
        view.setTitleColor(PTNavDefalutItemTextColor, for: .normal)
        view.titleLabel?.adjustsFontSizeToFitWidth = true
        view.jx_barItemFrameUpdateBlock = { sender in
            self.shouldRefLayou = true
            self.relayoutSubviews()
        }
        return view
    }()
    
    ///  右侧第二个Button
    public lazy var jx_subRightBtn:PTNavItemBtn = {
        let view = PTNavItemBtn()
        view.titleLabel?.font = .appfont(size: PTNavDefalutItemFontSize)
        view.titleLabel?.textAlignment = .center
        view.setTitleColor(PTNavDefalutItemTextColor, for: .normal)
        view.titleLabel?.adjustsFontSizeToFitWidth = true
        view.jx_barItemFrameUpdateBlock = { sender in
            self.shouldRefLayou = true
            self.relayoutSubviews()
        }
        return view
    }()
    
    /// titleLabel，显示在正中间的标题Label
    public lazy var jx_titleLabel:PTNavTitleLabel = {
        let view = PTNavTitleLabel()
        view.textAlignment = .center
        view.font = .appfont(size: PTNavDefalutTitleSize)
        view.numberOfLines = 0
        view.textColor = PTNavDefalutTitleColor
        return view
    }()
    
    /// 分割线
    public lazy var jx_lineView:UIView = {
        let view = UIView()
        view.backgroundColor = PTNavDefalutLineColor
        return view
    }()
    
    ///  titleView，显示在正中间的标题View
    public lazy var jx_titleView:PTNavTitleView = {
        let view = PTNavTitleView()
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initNavBar()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if !self.shouldRelayoutSubviews {
            PTGCDManager.gcdAfter(time: 0.1) {
                self.shouldRelayoutSubviews = true
                self.shouldRefLayou = true
                self.relayoutSubviews()
            }
        } else {
            self.relayoutSubviews()
        }
    }
    
    private func initNavBar() {
        self.backgroundColor = PTNavDefalutBackColor
        self.addSubviews([self.jx_backImageView,self.jx_leftBtn,self.jx_rightBtn,self.jx_subRightBtn,self.jx_subLeftBtn,self.jx_titleLabel,self.jx_titleView,self.jx_lineView])
    }
    
    private func relayoutSubviews() {
        if !self.shouldRelayoutSubviews {
            if self.jx_leftBtn.frame == .zero {
                self.jx_leftBtn.pt.jx_width = self.getInitItemBtnWidth(barItemBtn: self.jx_leftBtn)
                self.jx_leftBtn.pt.jx_height = self.getInitItemBtnHeight(barItemBtn: self.jx_leftBtn)
            }
            
            if self.jx_rightBtn.frame == .zero {
                self.jx_rightBtn.pt.jx_width = self.getInitItemBtnWidth(barItemBtn: self.jx_rightBtn)
                self.jx_rightBtn.pt.jx_height = self.getInitItemBtnHeight(barItemBtn: self.jx_rightBtn)
            }
            return
        }
        
        let centerOffet = CGFloat.statusBarHeight()
        var leftBtnSize:CGSize = .zero
        let leftBtnFinalHeight = self.getItemBtnHeight(barItemBtn: self.jx_leftBtn)
        let leftBtnFinalwidth = self.getItemBtnWidth(barItemBtn: self.jx_leftBtn)
        if self.jx_leftBtn.currentImage != nil || !(self.jx_leftBtn.currentTitle ?? "").stringIsEmpty() || !(self.jx_leftBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() || self.jx_leftBtn.jx_customView != nil {
            leftBtnSize = CGSize(width: leftBtnFinalwidth, height: leftBtnFinalHeight)
        }
        var leftBtnLeftMargin = self.jx_itemMargin
        if self.jx_leftBtn.jx_fixMarginLeft >= 0 {
            leftBtnLeftMargin = self.jx_leftBtn.jx_fixMarginLeft
        }
        self.jx_leftBtn.frame = CGRect(x: leftBtnLeftMargin + PTHorizontaledSafeArea, y: (self.pt.jx_height - leftBtnFinalHeight + centerOffet) / 2, width: leftBtnSize.width, height: leftBtnSize.height)
        self.handleItemBtnFrame(barItemBtn: self.jx_leftBtn)
        
        var rightBtnSize:CGSize = .zero
        let rightBtnFinalHeight = self.getItemBtnHeight(barItemBtn: self.jx_rightBtn)
        let rightBtnFinalwidth = self.getItemBtnWidth(barItemBtn: self.jx_rightBtn)
        if self.jx_rightBtn.currentImage != nil || !(self.jx_rightBtn.currentTitle ?? "").stringIsEmpty() || !(self.jx_rightBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() || self.jx_rightBtn.jx_customView != nil {
            rightBtnSize = CGSize(width: rightBtnFinalwidth, height: rightBtnFinalHeight)
        }
        var rightBtnRightMargin = self.jx_itemMargin
        if self.jx_rightBtn.jx_fixMarginRight >= 0 {
            rightBtnRightMargin = self.jx_rightBtn.jx_fixMarginRight
        }
        self.jx_rightBtn.frame = CGRect(x: self.pt.jx_width - rightBtnRightMargin - rightBtnSize.width - PTHorizontaledSafeArea, y: (self.pt.jx_height - rightBtnFinalHeight + centerOffet) / 2, width: rightBtnSize.width, height: rightBtnSize.height)
        self.handleItemBtnFrame(barItemBtn: self.jx_rightBtn)

        let subRightBtnFinalHeight = self.getItemBtnHeight(barItemBtn: self.jx_subRightBtn)
        let subRightBtnFinalWidth = self.getItemBtnWidth(barItemBtn: self.jx_subRightBtn)
        var subRightBtnRightMargin = self.jx_itemMargin
        if self.jx_rightBtn.jx_fixMarginLeft >= 0 {
            subRightBtnRightMargin = self.jx_rightBtn.jx_fixMarginLeft
        }

        if self.jx_subRightBtn.jx_fixMarginRight >= 0 {
            subRightBtnRightMargin = self.jx_rightBtn.jx_fixMarginRight
        }
        let subRightBtnRightFinalMargin = self.jx_rightBtn.pt.jx_width > 0 ? subRightBtnRightMargin : 0
        if self.jx_subRightBtn.currentImage != nil || !(self.jx_subRightBtn.currentTitle ?? "").stringIsEmpty() || !(self.jx_subRightBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() || self.jx_subRightBtn.jx_customView != nil {
            self.jx_subRightBtn.frame = CGRect(x: CGRectGetMinX(self.jx_rightBtn.frame) - subRightBtnRightFinalMargin, y: self.jx_rightBtn.pt.jx_y, width: 0, height: 0)
        } else {
            self.jx_subRightBtn.frame = CGRect(x: CGRectGetMinX(self.jx_rightBtn.frame) - subRightBtnRightFinalMargin - subRightBtnFinalWidth, y: (self.pt.jx_height - subRightBtnFinalHeight + centerOffet) / 2, width: subRightBtnFinalWidth, height: subRightBtnFinalHeight)
        }
        self.handleItemBtnFrame(barItemBtn: self.jx_subRightBtn)
        
        let subleftBtnFinalHeight = self.getItemBtnHeight(barItemBtn: self.jx_subLeftBtn)
        let subleftBtnFinalWidth = self.getItemBtnWidth(barItemBtn: self.jx_subLeftBtn)
        var subLeftBtnLeftMargin = self.jx_itemMargin
        if self.jx_leftBtn.jx_fixMarginRight >= 0 {
            subLeftBtnLeftMargin = self.jx_leftBtn.jx_fixMarginRight
        }

        if self.jx_subLeftBtn.jx_fixMarginLeft >= 0 {
            subLeftBtnLeftMargin = self.jx_rightBtn.jx_fixMarginLeft
        }
        let subLeftBtnLeftFinalMargin = self.jx_leftBtn.pt.jx_width > 0 ? subLeftBtnLeftMargin : 0
        if self.jx_subLeftBtn.currentImage != nil || !(self.jx_subLeftBtn.currentTitle ?? "").stringIsEmpty() || !(self.jx_subLeftBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() || self.jx_subLeftBtn.jx_customView != nil {
            self.jx_subLeftBtn.frame = CGRect(x: CGRectGetMinX(self.jx_leftBtn.frame) - subLeftBtnLeftFinalMargin, y: self.jx_leftBtn.pt.jx_y, width: 0, height: 0)
        } else {
            self.jx_subLeftBtn.frame = CGRect(x: CGRectGetMinX(self.jx_leftBtn.frame) + subLeftBtnLeftFinalMargin, y: (self.pt.jx_height - subleftBtnFinalHeight + centerOffet) / 2, width: subleftBtnFinalWidth, height: subleftBtnFinalHeight)
        }
        self.handleItemBtnFrame(barItemBtn: self.jx_subLeftBtn)

        var leftBtnFakeWidth = CGRectGetMaxX(self.jx_subLeftBtn.frame)
        var titleLabelLeftMargin = self.jx_itemMargin
        if self.jx_subLeftBtn.jx_fixMarginRight >= 0 {
            titleLabelLeftMargin = self.jx_subLeftBtn.jx_fixMarginRight
        }
        
        var titleLabelRightMargin = self.jx_itemMargin
        if self.jx_subRightBtn.jx_fixMarginLeft >= 0 {
            titleLabelRightMargin = self.jx_subRightBtn.jx_fixMarginLeft
        }
        if self.jx_subLeftBtn.pt.jx_width > 0 {
            leftBtnFakeWidth += titleLabelLeftMargin
        }
        
        var rightBtnFakeWidth = self.pt.jx_width - self.jx_subRightBtn.pt.jx_x
        if self.jx_subRightBtn.pt.jx_width > 0 {
            rightBtnFakeWidth += titleLabelRightMargin
        }

        let maxItemWidth = max(leftBtnFakeWidth, rightBtnFakeWidth)
        self.jx_titleLabel.frame = CGRect(x: maxItemWidth, y: centerOffet, width: self.pt.jx_width - maxItemWidth * 2, height: self.pt.jx_height - centerOffet)
        self.jx_titleView.frame = self.jx_titleLabel.frame
        self.jx_lineView.frame = CGRect(x: 0, y: self.pt.jx_height - self.jx_lineViewHeight, width: self.pt.jx_width, height: self.jx_lineViewHeight)
        self.jx_backImageView.frame = self.frame
        self.shouldRefLayou = false
        
        if self.jx_gradientLayer != nil {
            self.jx_gradientLayer?.frame = self.bounds
        }
        
        if self.jx_customNavBar != nil {
            self.jx_customNavBar?.frame = self.bounds
        }

        if self.jx_customTitleView != nil {
            self.jx_customTitleView?.frame = self.bounds
        }

    }
    
    //MARK: 获取ItemBtn初始高度
    private func getInitItemBtnHeight(barItemBtn:PTNavItemBtn) -> CGFloat {
        if barItemBtn.jx_fixHeight >= 0 {
            return barItemBtn.jx_fixHeight
        }
        return self.jx_itemSize
    }
    
    //MARK: 获取ItemBtn的初始宽度
    private func getInitItemBtnWidth(barItemBtn:PTNavItemBtn) -> CGFloat {
        if barItemBtn.jx_fixHeight >= 0 {
            return barItemBtn.jx_fixWidth
        }
        return self.jx_itemSize
    }

    //MARK: 获取ItemBtn最终高度
    private func getItemBtnHeight(barItemBtn:PTNavItemBtn) -> CGFloat {
        if barItemBtn.jx_fixHeight >= 0 {
            return barItemBtn.jx_fixWidth
        }
        
        if !(barItemBtn.currentTitle ?? "").stringIsEmpty() || !(barItemBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() {
            return self.jx_itemSize + barItemBtn.jx_textAttachHeight
        }
        return self.jx_itemSize
    }

    //MARK: 获取ItemBtn的最终宽度
    private func getItemBtnWidth(barItemBtn:PTNavItemBtn) -> CGFloat {
        if barItemBtn.jx_fixWidth >= 0 {
            return barItemBtn.jx_fixWidth
        }
        
        if !(barItemBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() {
            var btnW:CGFloat = UIView.sizeFor(string: barItemBtn.currentAttributedTitle!.string, font: barItemBtn.titleLabel?.font ?? .systemFont(ofSize: 14), height: 34, width: CGFloat(MAXFLOAT)).width
            if barItemBtn.imageView?.image != nil {
                btnW += barItemBtn.imageView!.pt.jx_width
            }
            btnW += barItemBtn.jx_textAttachWidth + 5
            return btnW
        } else if !(barItemBtn.currentTitle ?? "").stringIsEmpty() {
            var btnW:CGFloat = UIView.sizeFor(string: barItemBtn.currentTitle!, font: barItemBtn.titleLabel?.font ?? .systemFont(ofSize: 14), height: 34, width: CGFloat(MAXFLOAT)).width
            if barItemBtn.imageView?.image != nil {
                btnW += barItemBtn.imageView!.pt.jx_width
            }
            btnW += barItemBtn.jx_textAttachWidth + 5
            return btnW
        }
        return self.jx_itemSize
    }
    
    //MARK: 拦截处理ItemBtn的frame
    private func handleItemBtnFrame(barItemBtn:PTNavItemBtn) {
        if barItemBtn.jx_handleFrameBlock != nil {
            barItemBtn.jx_handleFrameBlock!(barItemBtn.frame)
            barItemBtn.frame = barItemBtn.frame
        }
        
        if let frameUpdateBlock = barItemBtn.value(forKey: "zx_frameUpdateBlock") as? ((CGRect) -> Void) {
                frameUpdateBlock(barItemBtn.frame)
        }
        if barItemBtn.jx_setCornerRadiusRounded! {
            barItemBtn.clipsToBounds = true
            barItemBtn.layer.cornerRadius = barItemBtn.frame.size.height / 2
        } else if barItemBtn.layer.cornerRadius == barItemBtn.frame.size.height / 2 {
            barItemBtn.layer.cornerRadius = 0
        }
    }
    
    //MARK: 刷新导航栏titleView布局
    private func refNavBar() {
        self.jx_titleLabel.pt.jx_width = CGRectGetMinX(self.jx_rightBtn.frame) - self.jx_itemMargin * 3 - self.jx_itemSize
        self.jx_titleView.pt.jx_width = self.jx_titleLabel.pt.jx_width
    }
    
    public func setMultiTitle(title:String,subTitle:String) {
        self.setMultiTitle(title: title, subTitle: subTitle, subTitleFont: .appfont(size: PTNavDefalutSubTitleSize), subTitleTextColor: self.jx_titleLabel.textColor)
    }
    
    public func setMultiTitle(title:String,subTitle:String,subTitleFont:UIFont,subTitleTextColor:UIColor) {
        let att:ASAttributedString = """
        \(wrap:.embedding("""
        \("\(title)")
        \("\(subTitle)",.font(subTitleFont),.foreground(subTitleTextColor))
        """),.paragraph(.alignment(.center)))
        """
        self.jx_titleLabel.attributed.text = att
    }
}
