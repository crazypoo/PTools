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
            if jx_navEnableSmoothFromSystemNavBar {
                AppWindows?.backgroundColor = backgroundColor
            }
            
            var components:[CGFloat] = [0,0,0]
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            var resultingPixel:[Int] = [0,0,0,0]
            let bitmap:CGContext = CGContext(data: &resultingPixel , width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            bitmap.setFillColor(backgroundColor?.cgColor ?? UIColor.clear.cgColor)
            bitmap.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            for i in 0...components.count {
                components[i] = CGFloat(resultingPixel[i] / 255)
            }
            jx_backgroundColorComponents = components
        }
    }
    
    /// 导航栏背景渐变的CAGradientLayer
    public var jx_gradientLayer:CAGradientLayer? {
        get {
            nil
        } set {
            jx_gradientLayer?.removeFromSuperlayer()
            
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
            shouldRefLayou = true
            relayoutSubviews()
            PTGCDManager.gcdAfter(time: 0.1) {
                self.reloadInputViews()
            }
        }
    }
    /// 设置Item之间的间距
    public var jx_itemMargin:CGFloat = PTNavDefalutItemMargin {
        didSet {
            shouldRefLayou = true
            relayoutSubviews()
        }
    }
    ///分割线的高度，默认为1
    public var jx_lineViewHeight:CGFloat = 0.5 {
        didSet {
            shouldRefLayou = true
            relayoutSubviews()
        }
    }

    /// 导航栏背景ImageView
    public var jx_backImage:UIImage? {
        didSet {
            jx_backImageView.image = jx_backImage
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
        initNavBar()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if !shouldRelayoutSubviews {
            PTGCDManager.gcdAfter(time: 0.1) {
                self.shouldRelayoutSubviews = true
                self.shouldRefLayou = true
                self.relayoutSubviews()
            }
        } else {
            relayoutSubviews()
        }
    }
    
    private func initNavBar() {
        backgroundColor = PTNavDefalutBackColor
        addSubviews([jx_backImageView, jx_leftBtn, jx_rightBtn, jx_subRightBtn, jx_subLeftBtn, jx_titleLabel, jx_titleView, jx_lineView])
    }
    
    private func relayoutSubviews() {
        if !shouldRelayoutSubviews {
            if jx_leftBtn.frame == .zero {
                jx_leftBtn.pt.jx_width = getInitItemBtnWidth(barItemBtn: jx_leftBtn)
                jx_leftBtn.pt.jx_height = getInitItemBtnHeight(barItemBtn: jx_leftBtn)
            }
            
            if jx_rightBtn.frame == .zero {
                jx_rightBtn.pt.jx_width = getInitItemBtnWidth(barItemBtn: jx_rightBtn)
                jx_rightBtn.pt.jx_height = getInitItemBtnHeight(barItemBtn: jx_rightBtn)
            }
            return
        }
        
        let centerOffet = CGFloat.statusBarHeight()
        var leftBtnSize:CGSize = .zero
        let leftBtnFinalHeight = getItemBtnHeight(barItemBtn: jx_leftBtn)
        let leftBtnFinalwidth = getItemBtnWidth(barItemBtn: jx_leftBtn)
        if jx_leftBtn.currentImage != nil || !(jx_leftBtn.currentTitle ?? "").stringIsEmpty() || !(jx_leftBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() || jx_leftBtn.jx_customView != nil {
            leftBtnSize = CGSize(width: leftBtnFinalwidth, height: leftBtnFinalHeight)
        }
        var leftBtnLeftMargin = jx_itemMargin
        if jx_leftBtn.jx_fixMarginLeft >= 0 {
            leftBtnLeftMargin = jx_leftBtn.jx_fixMarginLeft
        }
        jx_leftBtn.frame = CGRect(x: leftBtnLeftMargin + PTHorizontaledSafeArea, y: (pt.jx_height - leftBtnFinalHeight + centerOffet) / 2, width: leftBtnSize.width, height: leftBtnSize.height)
        handleItemBtnFrame(barItemBtn: jx_leftBtn)
        
        var rightBtnSize:CGSize = .zero
        let rightBtnFinalHeight = getItemBtnHeight(barItemBtn: jx_rightBtn)
        let rightBtnFinalwidth = getItemBtnWidth(barItemBtn: jx_rightBtn)
        if jx_rightBtn.currentImage != nil || !(jx_rightBtn.currentTitle ?? "").stringIsEmpty() || !(jx_rightBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() || jx_rightBtn.jx_customView != nil {
            rightBtnSize = CGSize(width: rightBtnFinalwidth, height: rightBtnFinalHeight)
        }
        var rightBtnRightMargin = jx_itemMargin
        if jx_rightBtn.jx_fixMarginRight >= 0 {
            rightBtnRightMargin = jx_rightBtn.jx_fixMarginRight
        }
        jx_rightBtn.frame = CGRect(x: pt.jx_width - rightBtnRightMargin - rightBtnSize.width - PTHorizontaledSafeArea, y: (pt.jx_height - rightBtnFinalHeight + centerOffet) / 2, width: rightBtnSize.width, height: rightBtnSize.height)
        handleItemBtnFrame(barItemBtn: jx_rightBtn)

        let subRightBtnFinalHeight = getItemBtnHeight(barItemBtn: jx_subRightBtn)
        let subRightBtnFinalWidth = getItemBtnWidth(barItemBtn: jx_subRightBtn)
        var subRightBtnRightMargin = jx_itemMargin
        if jx_rightBtn.jx_fixMarginLeft >= 0 {
            subRightBtnRightMargin = jx_rightBtn.jx_fixMarginLeft
        }

        if jx_subRightBtn.jx_fixMarginRight >= 0 {
            subRightBtnRightMargin = jx_rightBtn.jx_fixMarginRight
        }
        let subRightBtnRightFinalMargin = jx_rightBtn.pt.jx_width > 0 ? subRightBtnRightMargin : 0
        if jx_subRightBtn.currentImage != nil || !(jx_subRightBtn.currentTitle ?? "").stringIsEmpty() || !(jx_subRightBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() || jx_subRightBtn.jx_customView != nil {
            jx_subRightBtn.frame = CGRect(x: CGRectGetMinX(jx_rightBtn.frame) - subRightBtnRightFinalMargin, y: jx_rightBtn.pt.jx_y, width: 0, height: 0)
        } else {
            jx_subRightBtn.frame = CGRect(x: CGRectGetMinX(jx_rightBtn.frame) - subRightBtnRightFinalMargin - subRightBtnFinalWidth, y: (pt.jx_height - subRightBtnFinalHeight + centerOffet) / 2, width: subRightBtnFinalWidth, height: subRightBtnFinalHeight)
        }
        handleItemBtnFrame(barItemBtn: jx_subRightBtn)
        
        let subleftBtnFinalHeight = getItemBtnHeight(barItemBtn: jx_subLeftBtn)
        let subleftBtnFinalWidth = getItemBtnWidth(barItemBtn: jx_subLeftBtn)
        var subLeftBtnLeftMargin = jx_itemMargin
        if jx_leftBtn.jx_fixMarginRight >= 0 {
            subLeftBtnLeftMargin = jx_leftBtn.jx_fixMarginRight
        }

        if jx_subLeftBtn.jx_fixMarginLeft >= 0 {
            subLeftBtnLeftMargin = jx_rightBtn.jx_fixMarginLeft
        }
        let subLeftBtnLeftFinalMargin = jx_leftBtn.pt.jx_width > 0 ? subLeftBtnLeftMargin : 0
        if jx_subLeftBtn.currentImage != nil || !(jx_subLeftBtn.currentTitle ?? "").stringIsEmpty() || !(jx_subLeftBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() || jx_subLeftBtn.jx_customView != nil {
            jx_subLeftBtn.frame = CGRect(x: CGRectGetMinX(jx_leftBtn.frame) - subLeftBtnLeftFinalMargin, y: jx_leftBtn.pt.jx_y, width: 0, height: 0)
        } else {
            jx_subLeftBtn.frame = CGRect(x: CGRectGetMinX(jx_leftBtn.frame) + subLeftBtnLeftFinalMargin, y: (pt.jx_height - subleftBtnFinalHeight + centerOffet) / 2, width: subleftBtnFinalWidth, height: subleftBtnFinalHeight)
        }
        handleItemBtnFrame(barItemBtn: jx_subLeftBtn)

        var leftBtnFakeWidth = CGRectGetMaxX(jx_subLeftBtn.frame)
        var titleLabelLeftMargin = jx_itemMargin
        if jx_subLeftBtn.jx_fixMarginRight >= 0 {
            titleLabelLeftMargin = jx_subLeftBtn.jx_fixMarginRight
        }
        
        var titleLabelRightMargin = jx_itemMargin
        if jx_subRightBtn.jx_fixMarginLeft >= 0 {
            titleLabelRightMargin = jx_subRightBtn.jx_fixMarginLeft
        }
        if jx_subLeftBtn.pt.jx_width > 0 {
            leftBtnFakeWidth += titleLabelLeftMargin
        }
        
        var rightBtnFakeWidth = pt.jx_width - jx_subRightBtn.pt.jx_x
        if jx_subRightBtn.pt.jx_width > 0 {
            rightBtnFakeWidth += titleLabelRightMargin
        }

        let maxItemWidth = max(leftBtnFakeWidth, rightBtnFakeWidth)
        self.jx_titleLabel.frame = CGRect(x: maxItemWidth, y: centerOffet, width: pt.jx_width - maxItemWidth * 2, height: pt.jx_height - centerOffet)
        jx_titleView.frame = jx_titleLabel.frame
        jx_lineView.frame = CGRect(x: 0, y: pt.jx_height - jx_lineViewHeight, width: pt.jx_width, height: jx_lineViewHeight)
        jx_backImageView.frame = frame
        shouldRefLayou = false
        
        if jx_gradientLayer != nil {
            jx_gradientLayer?.frame = bounds
        }
        
        if jx_customNavBar != nil {
            jx_customNavBar?.frame = bounds
        }

        if jx_customTitleView != nil {
            jx_customTitleView?.frame = bounds
        }

    }
    
    //MARK: 获取ItemBtn初始高度
    private func getInitItemBtnHeight(barItemBtn:PTNavItemBtn) -> CGFloat {
        if barItemBtn.jx_fixHeight >= 0 {
            return barItemBtn.jx_fixHeight
        }
        return jx_itemSize
    }
    
    //MARK: 获取ItemBtn的初始宽度
    private func getInitItemBtnWidth(barItemBtn:PTNavItemBtn) -> CGFloat {
        if barItemBtn.jx_fixHeight >= 0 {
            return barItemBtn.jx_fixWidth
        }
        return jx_itemSize
    }

    //MARK: 获取ItemBtn最终高度
    private func getItemBtnHeight(barItemBtn:PTNavItemBtn) -> CGFloat {
        if barItemBtn.jx_fixHeight >= 0 {
            return barItemBtn.jx_fixWidth
        }
        
        if !(barItemBtn.currentTitle ?? "").stringIsEmpty() || !(barItemBtn.currentAttributedTitle?.string ?? "").stringIsEmpty() {
            return jx_itemSize + barItemBtn.jx_textAttachHeight
        }
        return jx_itemSize
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
        return jx_itemSize
    }
    
    //MARK: 拦截处理ItemBtn的frame
    private func handleItemBtnFrame(barItemBtn:PTNavItemBtn) {
        if barItemBtn.jx_handleFrameBlock != nil {
            barItemBtn.jx_handleFrameBlock!(barItemBtn.frame)
            barItemBtn.frame = barItemBtn.frame
        }
        
        if let frameUpdateBlock = barItemBtn.value(forKey: "zx_frameUpdateBlock") as? (CGRect) -> Void {
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
        jx_titleLabel.pt.jx_width = CGRectGetMinX(jx_rightBtn.frame) - jx_itemMargin * 3 - jx_itemSize
        jx_titleView.pt.jx_width = jx_titleLabel.pt.jx_width
    }
    
    public func setMultiTitle(title:String,subTitle:String) {
        self.setMultiTitle(title: title, subTitle: subTitle, subTitleFont: .appfont(size: PTNavDefalutSubTitleSize), subTitleTextColor: jx_titleLabel.textColor)
    }
    
    public func setMultiTitle(title:String,subTitle:String,subTitleFont:UIFont,subTitleTextColor:UIColor) {
        let att:ASAttributedString = """
        \(wrap:.embedding("""
        \("\(title)")
        \("\(subTitle)",.font(subTitleFont),.foreground(subTitleTextColor))
        """),.paragraph(.alignment(.center)))
        """
        jx_titleLabel.attributed.text = att
    }
}
