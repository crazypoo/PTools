//
//  PooSegmentView.swift
//  Diou
//
//  Created by jax on 2021/1/22.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import PooTools.Utils
import PooTools.NSString_Regulars
import PooTools.UIButton_ImageTitleSpacing
import WZLBadge.UIView_WZLBadge

enum PooSegmentSelectedType {
    case UnderLine
    case Background
    case Dog
}

class PooSegmentConfig: NSObject {
    ///选中字体
    var selectedFont:UIFont? = .systemFont(ofSize: 16)
    ///未选中字体
    var normalFont:UIFont? = .boldSystemFont(ofSize: 14)
    ///显示类型
    var showType:PooSegmentSelectedType? = .UnderLine
    ///选中颜色
    var selectedColor:UIColor? = UIColor.red
    ///普通颜色
    var normalColor:UIColor? = UIColor.black
    ///选中颜色(背景)
    var selectedColor_BG:UIColor? = UIColor.red
    ///底线height
    var underHight:CGFloat? = 3
    ///默认选中第X
    var normalSelecdIndex:Int? = 0
    ///子界面到他的父界面的左右距离总和
    var subViewInContentSpace:CGFloat? = 20.0
    ///设置底线角
    var underlineRadius:Bool? = true
    ///文字图片位置
    var imagePosition:BKLayoutButtonStyle? = .leftImageRightTitle
    ///文字图片间距
    var imageTitleSpace:CGFloat? = 5.0
    ///留给展示dog/或者underline的空间
    var bottomSquare:CGFloat? = 5.0
}

class PooSegmentModel:NSObject
{
    ///标题
    var titles:String?
    ///图片
    var imageURL:String?
    ///选中图片
    var selectedImageURL:String?
}

class PooSegmentSubView:UIView
{
    private var viewConfig = PooSegmentConfig()

//    private let lineSqare:CGFloat = 5
    
    enum ButtonShowType {
        case OnlyTitle
        case OnlyImage
        case TitleImage
    }
    
    var buttonShowType:ButtonShowType? = .OnlyTitle

    lazy var imageBtn:BKLayoutButton = {
        let btn = BKLayoutButton()
        btn.setTitleColor(self.viewConfig.normalColor, for: .normal)
        btn.setTitleColor(self.viewConfig.selectedColor, for: .selected)
        btn.setMidSpacing(self.viewConfig.imageTitleSpace!)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.layoutStyle = self.viewConfig.imagePosition
        return btn
    }()
    
    lazy var label:UIButton = {
        let label = UIButton(type: .custom)
        label.titleLabel!.textAlignment = .center
        label.setTitleColor(self.viewConfig.normalColor, for: .normal)
        label.setTitleColor(self.viewConfig.selectedColor, for: .selected)
        return label
    }()
    
    lazy var underLine:UIButton = {
        let label = UIButton(type: .custom)
        label.setBackgroundImage(Utils.createImage(with: UIColor.clear), for: .normal)
        label.setBackgroundImage(Utils.createImage(with: self.viewConfig.selectedColor_BG!), for: .selected)
        return label
    }()

    init(config:PooSegmentConfig,subViewModels:PooSegmentModel,contentW:CGFloat) {
        self.viewConfig = config
        super.init(frame: .zero)

        if DOFGobalTools.kStringIsEmpty(subViewModels.imageURL ?? "") && !DOFGobalTools.kStringIsEmpty(subViewModels.titles ?? "") && DOFGobalTools.kStringIsEmpty(subViewModels.selectedImageURL ?? "")
        {
            self.buttonShowType = .OnlyTitle
            self.label.titleLabel?.font = config.normalFont
            self.label.setTitle(subViewModels.titles, for: .normal)
        }
        else if !DOFGobalTools.kStringIsEmpty(subViewModels.imageURL ?? "") && DOFGobalTools.kStringIsEmpty(subViewModels.titles ?? "") && !DOFGobalTools.kStringIsEmpty(subViewModels.selectedImageURL ?? "")
        {
            //TODO:图片地址判断
            self.buttonShowType = .OnlyImage
            self.label.contentMode = .scaleAspectFit
            if (subViewModels.imageURL as! NSString).isUrlString()
            {
                self.label.sd_setImage(with:  URL.init(string: subViewModels.imageURL), for: .normal, placeholderImage: defaultsPlaceHolderImage, options: DOGobalFunction.gobalWebImageLoadOption(), context: nil)
            }
            else
            {
                self.label.setImage(UIImage.init(named: subViewModels.imageURL!), for: .normal)
            }

            if (subViewModels.selectedImageURL as! NSString).isUrlString()
            {
                self.label.sd_setImage(with:  URL.init(string: subViewModels.selectedImageURL), for: .selected, placeholderImage: defaultsPlaceHolderImage, options: DOGobalFunction.gobalWebImageLoadOption(), context: nil)
            }
            else
            {
                self.label.setImage(UIImage.init(named: subViewModels.selectedImageURL!), for: .selected)
            }
        }
        else if !DOFGobalTools.kStringIsEmpty(subViewModels.imageURL ?? "") && !DOFGobalTools.kStringIsEmpty(subViewModels.titles ?? "") && !DOFGobalTools.kStringIsEmpty(subViewModels.selectedImageURL ?? "")
        {
            //TODO:两个都有
            self.buttonShowType = .TitleImage
            self.imageBtn.contentMode = .scaleAspectFit
            self.imageBtn.titleLabel?.font = config.normalFont
            self.imageBtn.setTitle(subViewModels.titles, for: .normal)
            if (subViewModels.imageURL as! NSString).isUrlString()
            {
                self.imageBtn.sd_setImage(with:  URL.init(string: subViewModels.imageURL), for: .normal, placeholderImage: defaultsPlaceHolderImage, options: DOGobalFunction.gobalWebImageLoadOption(), context: nil)
            }
            else
            {
                self.imageBtn.setImage(UIImage.init(named: subViewModels.imageURL!), for: .normal)
            }

            if (subViewModels.selectedImageURL as! NSString).isUrlString()
            {
                self.imageBtn.sd_setImage(with:  URL.init(string: subViewModels.selectedImageURL), for: .selected, placeholderImage: defaultsPlaceHolderImage, options: DOGobalFunction.gobalWebImageLoadOption(), context: nil)
            }
            else
            {
                self.imageBtn.setImage(UIImage.init(named: subViewModels.selectedImageURL!), for: .selected)
            }
        }
        
        switch self.buttonShowType {
        case .TitleImage:
            self.addSubview(self.imageBtn)
            self.imageBtn.snp.makeConstraints { (make) in
                switch config.showType {
                case .UnderLine:
                    make.width.equalTo(contentW as! ConstraintRelatableTarget)
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.viewConfig.bottomSquare!)
                    make.top.equalToSuperview()
                case .Dog:
                    make.width.equalTo(contentW as! ConstraintRelatableTarget)
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.viewConfig.bottomSquare!)
                    make.top.equalToSuperview()
                case .Background:
                    make.left.right.equalToSuperview().inset(10)
                    make.bottom.top.equalToSuperview().inset(self.viewConfig.bottomSquare!)
                default:break
                }
            }
        default:
            self.addSubview(self.label)
            self.label.snp.makeConstraints { (make) in
                switch config.showType {
                case .UnderLine:
                    make.width.equalTo(contentW as! ConstraintRelatableTarget)
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.viewConfig.bottomSquare!)
                    make.top.equalToSuperview()
                case .Dog:
                    make.width.equalTo(contentW as! ConstraintRelatableTarget)
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.viewConfig.bottomSquare!)
                    make.top.equalToSuperview()
                case .Background:
                    make.left.right.equalToSuperview().inset(10)
                    make.bottom.top.equalToSuperview().inset(self.viewConfig.bottomSquare!)
                default:break
                }
            }
        }
        
        switch config.showType {
        case .UnderLine:
            self.addSubview(underLine)
            underLine.snp.makeConstraints { (make) in
                switch self.buttonShowType {
                case .TitleImage:
                    make.left.right.equalTo(self.imageBtn)
                default:
                    make.left.right.equalTo(self.label)
                }
                let lineHight:CGFloat?
                if self.viewConfig.underHight! >= self.viewConfig.bottomSquare!
                {
                    lineHight = self.viewConfig.bottomSquare
                    make.height.equalTo(self.viewConfig.bottomSquare as! ConstraintRelatableTarget)
                }
                else
                {
                    lineHight = self.viewConfig.underHight!
                    make.height.equalTo(self.viewConfig.underHight!)
                }
                make.bottom.equalToSuperview().inset((self.viewConfig.bottomSquare!-lineHight!)/2)
                if self.viewConfig.underlineRadius!
                {
                    DOFGobalTools.viewBorderRadius(underLine, withRadius: lineHight!/2, withWidth: 0, with: .clear)
                }
            }
        case .Dog:
            self.addSubview(underLine)
            underLine.snp.makeConstraints { (make) in
                let lineHight:CGFloat?
                if self.viewConfig.underHight! >= self.viewConfig.bottomSquare!
                {
                    lineHight = self.viewConfig.bottomSquare
                    make.width.height.equalTo(self.viewConfig.bottomSquare as! ConstraintRelatableTarget)
                }
                else
                {
                    lineHight = self.viewConfig.underHight!
                    make.width.height.equalTo(self.viewConfig.underHight!)
                }
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset((self.viewConfig.bottomSquare!-lineHight!)/2)
                DOFGobalTools.viewBorderRadius(underLine, withRadius: lineHight!/2, withWidth: 0, with: .clear)
            }

        case .Background:
            switch self.buttonShowType {
            case .TitleImage:
                imageBtn.setBackgroundImage(Utils.createImage(with: UIColor.clear), for: .normal)
                imageBtn.setBackgroundImage(Utils.createImage(with: self.viewConfig.selectedColor_BG!), for: .selected)
            default:
                label.setBackgroundImage(Utils.createImage(with: UIColor.clear), for: .normal)
                label.setBackgroundImage(Utils.createImage(with: self.viewConfig.selectedColor_BG!), for: .selected)
            }
        default:break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PooSegmentView: UIView {
    
    private var viewConfig = PooSegmentConfig()
    private var subViewArr = [UIView]()
    
    var viewDatas = [PooSegmentModel]()

    enum PooSegmentBadgePosition {
        case TopLeft
        case TopMiddle
        case TopRight
        case MiddleLeft
        case MiddleRigh
        case BottomLeft
        case BottomMiddle
        case BottomRight
    }
    
    var selectedIndex:Int?
    {
        didSet
        {
            self.setSelectItem(indexs: selectedIndex!)
        }
    }

    var segTapBlock:((_ currentIndex:Int)->Void)?

    lazy var scrolView : UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.isPagingEnabled = false
        return view
    }()
        
    init(config:PooSegmentConfig? = PooSegmentConfig()) {
        super.init(frame: .zero)
        self.viewConfig = config!
    }
    
    func reloadViewData(block:((_ index:Int)->Void)?)
    {
        self.subViewArr.forEach { (value) in
            let subV = value as! PooSegmentSubView
            subV.removeFromSuperview()
        }
        self.subViewArr.removeAll()
        self.scrolView.removeAllSubviews()
        self.setUI(datas: self.viewDatas)
        if block != nil
        {
            block!(self.selectedIndex ?? 0)
        }
    }
    
    private func setUI(datas:[PooSegmentModel])
    {
        DOFGobalTools.gcd(after: 0.1) {
            var scrolContentW:CGFloat = 0
            if datas.count > 0
            {
                datas.enumerated().forEach { (index,value) in
                    
                    let normalW = Utils.size(for: value.titles!, font: self.viewConfig.normalFont!, andHeigh:  self.frame.size.height, andWidth: CGFloat(MAXFLOAT)).width
                    let selectedW = Utils.size(for: value.titles!, font: self.viewConfig.selectedFont!, andHeigh:  self.frame.size.height, andWidth: CGFloat(MAXFLOAT)).width
                    var subContentW:CGFloat?
                    if selectedW >= normalW
                    {
                        subContentW = selectedW + self.viewConfig.subViewInContentSpace! + 10
                    }
                    else
                    {
                        subContentW = normalW + self.viewConfig.subViewInContentSpace! + 10
                    }
                    
                    if DOFGobalTools.kStringIsEmpty(value.imageURL ?? "") && !DOFGobalTools.kStringIsEmpty(value.titles ?? "") && DOFGobalTools.kStringIsEmpty(value.selectedImageURL ?? "")
                    {
                        
                    }
                    else if !DOFGobalTools.kStringIsEmpty(value.imageURL ?? "") && DOFGobalTools.kStringIsEmpty(value.titles ?? "") && !DOFGobalTools.kStringIsEmpty(value.selectedImageURL ?? "")
                    {
                        //TODO:图片地址判断
                        subContentW = self.frame.height - 5 + self.viewConfig.subViewInContentSpace!
                    }
                    else if !DOFGobalTools.kStringIsEmpty(value.imageURL ?? "") && !DOFGobalTools.kStringIsEmpty(value.titles ?? "") && !DOFGobalTools.kStringIsEmpty(value.selectedImageURL ?? "")
                    {
                        //TODO:两个都有
                        switch self.viewConfig.imagePosition {
                        case .leftImageRightTitle:
                            subContentW = subContentW! + self.viewConfig.imageTitleSpace! + (self.frame.height-5)
                        case .leftTitleRightImage:
                            subContentW = subContentW! + self.viewConfig.imageTitleSpace! + (self.frame.height-5)
                        default:break
                        }
                    }

                    let subView = PooSegmentSubView(config: self.viewConfig,subViewModels: value,contentW: (subContentW!-self.viewConfig.subViewInContentSpace!))
                    subView.tag = index
                    subView.frame = CGRect.init(x: scrolContentW, y: 0, width: subContentW!, height: self.frame.size.height)
                    scrolContentW += subContentW!
                    
                    switch subView.buttonShowType {
                    case .TitleImage:
                        subView.imageBtn.tag = index
                        subView.imageBtn.addActionHandler { (sender) in
                            self.setSelectItem(indexs: sender!.tag)
                            if self.segTapBlock != nil
                            {
                                self.segTapBlock!(sender!.tag)
                            }
                        }
                    default:
                        subView.label.tag = index
                        subView.label.addActionHandler { (sender) in
                            self.setSelectItem(indexs: sender!.tag)
                            if self.segTapBlock != nil
                            {
                                self.segTapBlock!(sender!.tag)
                            }
                        }
                    }
                    self.scrolView.addSubview(subView)
                    self.subViewArr.append(subView)
                }
                
                self.addSubview(self.scrolView)
                self.scrolView.snp.makeConstraints { (make) in
                    if scrolContentW >= kScreenWidth
                    {
                        make.edges.equalToSuperview()
                    }
                    else
                    {
                        make.width.equalTo(scrolContentW)
                        make.height.equalToSuperview()
                        make.centerX.equalToSuperview()
                    }
                }
                self.scrolView.contentSize = CGSize.init(width: scrolContentW, height: self.frame.size.height)
                self.selectedIndex = self.viewConfig.normalSelecdIndex
                
                if scrolContentW >= kScreenWidth
                {
                    self.scrolView.isScrollEnabled = true
                }
                else
                {
                    self.scrolView.isScrollEnabled = false
                }
            }
        }
    }
    
    func setSelectItem(indexs:Int)
    {
        if indexs <= (self.subViewArr.count - 1)
        {
            let subV = self.subViewArr[indexs] as! PooSegmentSubView

            switch indexs {
            case 0:
                self.scrolView.scrollToLeft()
            default:
                self.scrolView.scrollRectToVisible(CGRect.init(x: (subV.frame.origin.x) + (subV.frame.size.width) / 2, y: 0, width: (subV.frame.size.width), height: self.frame.size.height), animated: true)
            }

            self.subViewArr.enumerated().forEach { (index,value) in
                let viewInArr = value as! PooSegmentSubView
                if index != indexs
                {
                    switch self.viewConfig.showType {
                    case .UnderLine:
                        viewInArr.underLine.isSelected = false
                    case .Dog:
                        viewInArr.underLine.isSelected = false
                    default:break
                    }
                    viewInArr.label.isSelected = false
                    switch viewInArr.buttonShowType {
                    case .TitleImage:
                        viewInArr.imageBtn.titleLabel?.font = self.viewConfig.normalFont
                    default:
                        viewInArr.label.titleLabel?.font = self.viewConfig.normalFont
                    }
                }
                else
                {
                    switch self.viewConfig.showType {
                    case .UnderLine:
                        viewInArr.underLine.isSelected = true
                    case .Dog:
                        viewInArr.underLine.isSelected = true
                    default:break
                    }
                    switch viewInArr.buttonShowType {
                    case .TitleImage:
                        viewInArr.imageBtn.titleLabel?.font = self.viewConfig.selectedFont
                    default:
                        viewInArr.label.titleLabel?.font = self.viewConfig.selectedFont
                    }
                }
            }
        }
    }
    
    func setSegBadge(indexView:Int,badgePosition:PooSegmentBadgePosition? = .TopRight,badgeBGColor:UIColor? = UIColor.red,badgeShowType:WBadgeStyle? = .redDot,badgeAnimation:WBadgeAnimType? = .breathe,badgeValue:Int? = 1)
    {
        DOFGobalTools.gcd(after: 0.1) {
            self.subViewArr.enumerated().forEach { (index,value) in
                if index == indexView
                {
                    let subViews = (value as! PooSegmentSubView)
                    var badgePoint = CGPoint.init(x: 0, y: 0)
                    switch badgePosition {
                    case .TopLeft:
                        badgePoint = CGPoint(x: -subViews.width+5, y: 5)
                    case .TopMiddle:
                        badgePoint = CGPoint(x: -(subViews.width/2), y: 5)
                    case .TopRight:
                        badgePoint = CGPoint(x: 0, y: 5)
                    case .MiddleLeft:
                        badgePoint = CGPoint(x: -subViews.width+5, y: subViews.height/2)
                    case .MiddleRigh:
                        badgePoint = CGPoint(x: -5, y: subViews.height/2)
                    case .BottomLeft:
                        badgePoint = CGPoint(x: -subViews.width+5, y: subViews.height-5)
                    case .BottomMiddle:
                        badgePoint = CGPoint(x: -(subViews.width/2), y: subViews.height-5)
                    case .BottomRight:
                        badgePoint = CGPoint(x: -5, y: subViews.height-5)
                    default:break
                    }
                    subViews.badgeCenterOffset = badgePoint
                    subViews.badgeBgColor = badgeBGColor
                    subViews.showBadge(with: badgeShowType!, value: badgeValue!, animationType: badgeAnimation!)
                }
            }
        }
    }
    
    func removeBadgeAtIndex(indexView:Int)
    {
        self.subViewArr.enumerated().forEach { (index,value) in
            if index == indexView
            {
                let subViews = (value as! PooSegmentSubView)
                subViews.clearBadge()
            }
        }
    }
    
    func removeAllBadge()
    {
        self.subViewArr.enumerated().forEach { (index,value) in
            let subViews = (value as! PooSegmentSubView)
            subViews.clearBadge()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
