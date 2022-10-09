//
//  PooSegmentView.swift
//  Diou
//
//  Created by jax on 2021/1/22.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SnapKit
import YYCategories
import SwifterSwift

@objc public enum PooSegmentSelectedType : Int {
    case UnderLine
    case Background
    case Dog
}

@objcMembers
public class PooSegmentConfig: NSObject {
    ///选中字体
    public var selectedFont:UIFont = .systemFont(ofSize: 16)
    ///未选中字体
    public var normalFont:UIFont = .boldSystemFont(ofSize: 14)
    ///显示类型
    public var showType:PooSegmentSelectedType = PooSegmentSelectedType(rawValue: 0)!
    ///选中颜色
    public var selectedColor:UIColor = .red
    ///普通颜色
    public var normalColor:UIColor = .black
    ///选中颜色(背景)
    public var selectedColor_BG:UIColor = .red
    ///底线height
    public var underHight:CGFloat = 3
    ///默认选中第X
    public var normalSelecdIndex:Int = 0
    ///子界面到他的父界面的左右距离总和
    public var subViewInContentSpace:CGFloat = 20
    ///设置底线角
    public var underlineRadius:Bool = true
    ///文字图片位置
    public var imagePosition:BKLayoutButtonStyle = BKLayoutButtonStyle(rawValue: 0)!
    ///文字图片间距
    public var imageTitleSpace:CGFloat = 5
    ///留给展示dog/或者underline的空间
    public var bottomSquare:CGFloat = 5
}

@objcMembers
public class PooSegmentModel:NSObject
{
    ///标题
    public var titles:String = ""
    ///图片
    public var imageURL:String = ""
    ///图片
    public var imagePlaceHolder:String = ""
    ///选中图片
    public var selectedImageURL:String = ""
}

public enum ButtonShowType:Int {
    case OnlyTitle
    case OnlyImage
    case TitleImage
}

@objcMembers
public class PooSegmentSubView:UIView
{
    private var viewConfig = PooSegmentConfig()

//    private let lineSqare:CGFloat = 5
    
    public var buttonShowType:ButtonShowType = .OnlyTitle

    lazy var imageBtn:BKLayoutButton = {
        let btn = BKLayoutButton()
        btn.setTitleColor(self.viewConfig.normalColor, for: .normal)
        btn.setTitleColor(self.viewConfig.selectedColor, for: .selected)
        btn.setMidSpacing(self.viewConfig.imageTitleSpace)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.layoutStyle = self.viewConfig.imagePosition
        btn.setImageSize(CGSize(width: 30, height: 30))
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
        
        label.setBackgroundImage(UIColor.clear.createImageWithColor(), for: .normal)
        label.setBackgroundImage(self.viewConfig.selectedColor_BG.createImageWithColor(), for: .selected)
        return label
    }()

    public init(config:PooSegmentConfig,subViewModels:PooSegmentModel,contentW:CGFloat) {
        viewConfig = config
        super.init(frame: .zero)

        if subViewModels.imageURL.stringIsEmpty() && !subViewModels.titles.stringIsEmpty() && subViewModels.selectedImageURL.stringIsEmpty()
        {
            buttonShowType = .OnlyTitle
            label.titleLabel?.font = config.normalFont
            label.setTitle(subViewModels.titles, for: .normal)
        }
        else if !subViewModels.imageURL.stringIsEmpty() && subViewModels.titles.stringIsEmpty() && !subViewModels.selectedImageURL.stringIsEmpty()
        {
            //MARK:图片地址判断
            buttonShowType = .OnlyImage
            label.contentMode = .scaleAspectFit
            
            let placeHolderImage = subViewModels.imagePlaceHolder.stringIsEmpty() ? UIColor.randomColor.createImageWithColor() : UIImage(named: subViewModels.imagePlaceHolder)

            if subViewModels.imageURL.isValidUrl
            {
                
                label.sd_setImage(with:  URL.init(string: subViewModels.imageURL), for: .normal, placeholderImage: placeHolderImage, options: PTUtils.gobalWebImageLoadOption(), context: nil)
            }
            else
            {
                label.setImage(UIImage.init(named: subViewModels.imageURL), for: .normal)
            }

            if subViewModels.selectedImageURL.isValidUrl
            {
                label.sd_setImage(with:  URL.init(string: subViewModels.selectedImageURL), for: .selected, placeholderImage: placeHolderImage, options: PTUtils.gobalWebImageLoadOption(), context: nil)
            }
            else
            {
                label.setImage(UIImage.init(named: subViewModels.selectedImageURL), for: .selected)
            }
        }
        else if !subViewModels.imageURL.stringIsEmpty() && !subViewModels.titles.stringIsEmpty() && !subViewModels.selectedImageURL.stringIsEmpty()
        {
            let placeHolderImage = subViewModels.imagePlaceHolder.stringIsEmpty() ? UIColor.randomColor.createImageWithColor() : UIImage(named: subViewModels.imagePlaceHolder)
            //MARK:两个都有
            buttonShowType = .TitleImage
            imageBtn.contentMode = .scaleAspectFit
            imageBtn.titleLabel?.font = config.normalFont
            imageBtn.setTitle(subViewModels.titles, for: .normal)
            if subViewModels.imageURL.isURL()
            {
                imageBtn.sd_setImage(with:  URL.init(string: subViewModels.imageURL), for: .normal, placeholderImage: placeHolderImage, options: PTUtils.gobalWebImageLoadOption(), context: nil)
            }
            else
            {
                imageBtn.setImage(UIImage.init(named: subViewModels.imageURL), for: .normal)
            }

            if subViewModels.selectedImageURL.isURL()
            {
                imageBtn.sd_setImage(with:  URL.init(string: subViewModels.selectedImageURL), for: .selected, placeholderImage: placeHolderImage, options: PTUtils.gobalWebImageLoadOption(), context: nil)
            }
            else
            {
                imageBtn.setImage(UIImage.init(named: subViewModels.selectedImageURL), for: .selected)
            }
        }
        
        switch buttonShowType {
        case .TitleImage:
            addSubview(imageBtn)
            imageBtn.snp.makeConstraints { (make) in
                switch config.showType {
                case .UnderLine:
                    make.width.equalTo(contentW as ConstraintRelatableTarget)
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.viewConfig.bottomSquare)
                    make.top.equalToSuperview()
                case .Dog:
                    make.width.equalTo(contentW as ConstraintRelatableTarget)
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.viewConfig.bottomSquare)
                    make.top.equalToSuperview()
                case .Background:
                    make.left.right.equalToSuperview().inset(10)
                    make.bottom.top.equalToSuperview().inset(self.viewConfig.bottomSquare)
                default:break
                }
            }
        default:
            addSubview(label)
            label.snp.makeConstraints { (make) in
                switch config.showType {
                case .UnderLine:
                    make.width.equalTo(contentW as ConstraintRelatableTarget)
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.viewConfig.bottomSquare)
                    make.top.equalToSuperview()
                case .Dog:
                    make.width.equalTo(contentW as ConstraintRelatableTarget)
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.viewConfig.bottomSquare)
                    make.top.equalToSuperview()
                case .Background:
                    make.left.right.equalToSuperview().inset(10)
                    make.bottom.top.equalToSuperview().inset(self.viewConfig.bottomSquare)
                default:break
                }
            }
        }
        
        switch config.showType {
        case .UnderLine:
            addSubview(underLine)
            underLine.snp.makeConstraints { (make) in
                switch self.buttonShowType {
                case .TitleImage:
                    make.left.right.equalTo(self.imageBtn)
                default:
                    make.left.right.equalTo(self.label)
                }
                let lineHight:CGFloat?
                if self.viewConfig.underHight >= self.viewConfig.bottomSquare
                {
                    lineHight = self.viewConfig.bottomSquare
                    make.height.equalTo(self.viewConfig.bottomSquare)
                }
                else
                {
                    lineHight = self.viewConfig.underHight
                    make.height.equalTo(self.viewConfig.underHight)
                }
                make.bottom.equalToSuperview().inset((self.viewConfig.bottomSquare-lineHight!)/2)
                if self.viewConfig.underlineRadius
                {
                    underLine.viewCorner(radius: lineHight!/2)
                }
            }
        case .Dog:
            addSubview(underLine)
            underLine.snp.makeConstraints { (make) in
                let lineHight:CGFloat?
                if self.viewConfig.underHight >= self.viewConfig.bottomSquare
                {
                    lineHight = self.viewConfig.bottomSquare
                    make.width.height.equalTo(self.viewConfig.bottomSquare)
                }
                else
                {
                    lineHight = self.viewConfig.underHight
                    make.width.height.equalTo(self.viewConfig.underHight)
                }
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset((self.viewConfig.bottomSquare-lineHight!)/2)
                underLine.viewCorner(radius: lineHight!/2)
            }

        case .Background:
            switch buttonShowType {
            case .TitleImage:
                imageBtn.setBackgroundImage(UIColor.clear.createImageWithColor(), for: .normal)
                imageBtn.setBackgroundImage(viewConfig.selectedColor_BG.createImageWithColor(), for: .selected)
            default:
                label.setBackgroundImage(UIColor.clear.createImageWithColor(), for: .normal)
                label.setBackgroundImage(viewConfig.selectedColor_BG.createImageWithColor(), for: .selected)
            }
        default:break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objcMembers
public class PooSegmentView: UIView {
    
    private var viewConfig = PooSegmentConfig()
    private var subViewArr = [UIView]()
    
    public var viewDatas = [PooSegmentModel]()

    public enum PooSegmentBadgePosition {
        case TopLeft
        case TopMiddle
        case TopRight
        case MiddleLeft
        case MiddleRigh
        case BottomLeft
        case BottomMiddle
        case BottomRight
    }
    
    public var selectedIndex:Int?
    {
        didSet
        {
            setSelectItem(indexs: selectedIndex!)
        }
    }

    public var segTapBlock:((_ currentIndex:Int)->Void)?

    lazy var scrolView : UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.isPagingEnabled = false
        return view
    }()
        
    public init(config:PooSegmentConfig? = PooSegmentConfig()) {
        super.init(frame: .zero)
        viewConfig = config!
    }
    
    public func reloadViewData(block:((_ index:Int)->Void)?)
    {
        subViewArr.forEach { (value) in
            let subV = value as! PooSegmentSubView
            subV.removeFromSuperview()
        }
        subViewArr.removeAll()
        scrolView.removeAllSubviews()
        setUI(datas: viewDatas)
        if block != nil
        {
            block!(selectedIndex ?? 0)
        }
    }
    
    private func setUI(datas:[PooSegmentModel])
    {
        PTUtils.gcdAfter(time: 0.1) {
            var scrolContentW:CGFloat = 0
            if datas.count > 0
            {
                datas.enumerated().forEach { (index,value) in                    
                    let normalW = PTUtils.sizeFor(string: value.titles, font: self.viewConfig.normalFont, height: self.frame.size.height, width:  CGFloat(MAXFLOAT)).width
                    let selectedW = PTUtils.sizeFor(string: value.titles, font: self.viewConfig.selectedFont, height: self.frame.size.height, width:  CGFloat(MAXFLOAT)).width
                    var subContentW:CGFloat?
                    if selectedW >= normalW
                    {
                        subContentW = selectedW + self.viewConfig.subViewInContentSpace + 10
                    }
                    else
                    {
                        subContentW = normalW + self.viewConfig.subViewInContentSpace + 10
                    }
                    
                    if value.imageURL.stringIsEmpty() && !value.titles.stringIsEmpty() && value.selectedImageURL.stringIsEmpty()
                    {
                        
                    }
                    else if !value.imageURL.stringIsEmpty() && value.titles.stringIsEmpty() && !value.selectedImageURL.stringIsEmpty()
                    {
                        subContentW = self.frame.height - 5 + self.viewConfig.subViewInContentSpace
                    }
                    else if !value.imageURL.stringIsEmpty() && !value.titles.stringIsEmpty() && !value.selectedImageURL.stringIsEmpty()
                    {
                        switch self.viewConfig.imagePosition {
                        case .leftImageRightTitle:
                            subContentW = subContentW! + self.viewConfig.imageTitleSpace + (self.frame.height-5)
                        case .leftTitleRightImage:
                            subContentW = subContentW! + self.viewConfig.imageTitleSpace + (self.frame.height-5)
                        default:break
                        }
                    }

                    let subView = PooSegmentSubView(config: self.viewConfig,subViewModels: value,contentW: (subContentW!-self.viewConfig.subViewInContentSpace))
                    
                    var subShowType:ButtonShowType!
                    if value.titles.stringIsEmpty() && !value.selectedImageURL.stringIsEmpty() && !value.imageURL.stringIsEmpty()
                    {
                        subShowType = .OnlyImage
                    }
                    else if !value.titles.stringIsEmpty() && value.selectedImageURL.stringIsEmpty() && value.imageURL.stringIsEmpty()
                    {
                        subShowType = .OnlyTitle
                    }
                    else if !value.titles.stringIsEmpty() && !value.selectedImageURL.stringIsEmpty() && !value.imageURL.stringIsEmpty()
                    {
                        subShowType = .TitleImage
                    }
                    else
                    {
                        subShowType = .OnlyTitle
                    }
                    subView.buttonShowType = subShowType
                    subView.tag = index
                    subView.frame = CGRect.init(x: scrolContentW, y: 0, width: subContentW!, height: self.frame.size.height)
                    scrolContentW += subContentW!
                    
                    switch subView.buttonShowType {
                    case .TitleImage:
                        subView.imageBtn.tag = index
                        subView.imageBtn.addActionHandlers { (sender) in
                            self.setSelectItem(indexs: sender.tag)
                            if self.segTapBlock != nil
                            {
                                self.segTapBlock!(sender.tag)
                            }
                        }
                    default:
                        subView.label.tag = index
                        subView.label.addActionHandlers { (sender) in
                            self.setSelectItem(indexs: sender.tag)
                            if self.segTapBlock != nil
                            {
                                self.segTapBlock!(sender.tag)
                            }
                        }
                    }
                    self.scrolView.addSubview(subView)
                    self.subViewArr.append(subView)
                }
                
                self.addSubview(self.scrolView)
                self.scrolView.snp.makeConstraints { (make) in
                    if scrolContentW >= kSCREEN_WIDTH
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
                
                if scrolContentW >= kSCREEN_WIDTH
                {
                    self.scrolView.isScrollEnabled = true
                }
                else
                {
                    self.scrolView.isScrollEnabled = false
                }
            }
            self.layoutSubviews()
        }
    }
    
    public func setSelectItem(indexs:Int)
    {
        if indexs <= (subViewArr.count - 1)
        {
            let subV = subViewArr[indexs] as! PooSegmentSubView

            switch indexs {
            case 0:
                scrolView.scrollToLeft()
            default:
                scrolView.scrollRectToVisible(CGRect.init(x: (subV.frame.origin.x) + (subV.frame.size.width) / 2, y: 0, width: (subV.frame.size.width), height: frame.size.height), animated: true)
            }

            subViewArr.enumerated().forEach { (index,value) in
                let viewInArr = value as! PooSegmentSubView
                if index != indexs
                {
                    switch viewConfig.showType {
                    case .UnderLine:
                        viewInArr.underLine.isSelected = false
                    case .Dog:
                        viewInArr.underLine.isSelected = false
                    default:break
                    }
                    viewInArr.label.isSelected = false
                    switch viewInArr.buttonShowType {
                    case .TitleImage:
                        viewInArr.imageBtn.titleLabel?.font = viewConfig.normalFont
                    default:
                        viewInArr.label.titleLabel?.font = viewConfig.normalFont
                    }
                }
                else
                {
                    switch viewConfig.showType {
                    case .UnderLine:
                        viewInArr.underLine.isSelected = true
                    case .Dog:
                        viewInArr.underLine.isSelected = true
                    default:break
                    }
                    switch viewInArr.buttonShowType {
                    case .TitleImage:
                        viewInArr.imageBtn.titleLabel?.font = viewConfig.selectedFont
                    default:
                        viewInArr.label.titleLabel?.font = viewConfig.selectedFont
                    }
                }
            }
        }
    }
    
    public func setSegBadge(indexView:Int,badgePosition:PooSegmentBadgePosition? = .TopRight,badgeBGColor:UIColor? = UIColor.red,badgeShowType:WBadgeStyle? = .redDot,badgeAnimation:WBadgeAnimType? = .breathe,badgeValue:Int? = 1)
    {
        PTUtils.gcdAfter(time: 0.1) {
            self.subViewArr.enumerated().forEach { (index,value) in
                if index == indexView
                {
                    let subViews = (value as! PooSegmentSubView)
                    var badgePoint = CGPoint.init(x: 0, y: 0)
                    switch badgePosition {
                    case .TopLeft:
                        badgePoint = CGPoint(x: -subViews.pt.jx_width+5, y: 5)
                    case .TopMiddle:
                        badgePoint = CGPoint(x: -(subViews.pt.jx_width/2), y: 5)
                    case .TopRight:
                        badgePoint = CGPoint(x: 0, y: 5)
                    case .MiddleLeft:
                        badgePoint = CGPoint(x: -subViews.pt.jx_width+5, y: subViews.pt.jx_height/2)
                    case .MiddleRigh:
                        badgePoint = CGPoint(x: -5, y: subViews.pt.jx_height/2)
                    case .BottomLeft:
                        badgePoint = CGPoint(x: -subViews.pt.jx_width+5, y: subViews.pt.jx_height-5)
                    case .BottomMiddle:
                        badgePoint = CGPoint(x: -(subViews.pt.jx_width/2), y: subViews.pt.jx_height-5)
                    case .BottomRight:
                        badgePoint = CGPoint(x: -5, y: subViews.pt.jx_height-5)
                    default:break
                    }
                    subViews.badgeCenterOffset = badgePoint
                    subViews.badgeBgColor = badgeBGColor
                    subViews.showBadge(with: badgeShowType!, value: badgeValue!, animationType: badgeAnimation!)
                }
            }
        }
    }
    
    public func removeBadgeAtIndex(indexView:Int)
    {
        subViewArr.enumerated().forEach { (index,value) in
            if index == indexView
            {
                let subViews = (value as! PooSegmentSubView)
                subViews.clearBadge()
            }
        }
    }
    
    public func removeAllBadge()
    {
        subViewArr.enumerated().forEach { (index,value) in
            let subViews = (value as! PooSegmentSubView)
            subViews.clearBadge()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
