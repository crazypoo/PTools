//
//  PooSegmentView.swift
//  Diou
//
//  Created by jax on 2021/1/22.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import Kingfisher

@objc public enum PTSegmentSelectedType : Int {
    case UnderLine
    case Background
    case Dog
    case SubBackground
}

@objcMembers
public class PTSegmentConfig: NSObject {
    ///选中字体
    open var selectedFont:UIFont = .systemFont(ofSize: 16)
    ///未选中字体
    open var normalFont:UIFont = .boldSystemFont(ofSize: 14)
    ///显示类型
    open var showType:PTSegmentSelectedType = PTSegmentSelectedType(rawValue: 0)!
    ///选中颜色
    open var selectedColor:UIColor = .red
    ///普通颜色
    open var normalColor:UIColor = .black
    
    open var normalColor_BG:UIColor = .clear
    ///选中颜色(背景)
    open var selectedColor_BG:UIColor = .systemBlue
    ///底线height
    open var underHight:CGFloat = 3
    ///默认选中第X
    open var normalSelecdIndex:Int = 0
    ///子界面到他的父界面的左右距离总和
    open var subViewInContentSpace:CGFloat = 20
    ///设置底线角
    open var underlineRadius:Bool = true
    ///文字图片位置
    open var imagePosition:PTLayoutButtonStyle = PTLayoutButtonStyle(rawValue: 0)!
    ///文字图片间距
    open var imageTitleSpace:CGFloat = 5
    ///留给展示dog/或者underline的空间
    open var bottomSquare:CGFloat = 5
    ///是否左对齐
    open var leftEdges:Bool = false
    ///每个item的间隙
    open var itemSpace:CGFloat = 0
    ///初始x(左对齐生效)
    open var originalX:CGFloat = 0
}

@objcMembers
public class PTSegmentModel:NSObject {
    ///标题
    open var titles:String = ""
    ///图片
    open var imageURL:Any?
    ///图片
    open var imagePlaceHolder:String = ""
    ///选中图片
    open var selectedImageURL:Any?
    ///iCloud文件夹名称
    open var iCloudDocument:String = ""
}

@objc public enum PTSegmentButtonShowType:Int {
    case OnlyTitle
    case OnlyImage
    case TitleImage
}

@objcMembers
public class PTSegmentSubView:UIView {
    private var viewConfig = PTSegmentConfig()
            
    var buttonShowType:PTSegmentButtonShowType = .OnlyTitle
    
    lazy var imageBtn:PTLayoutButton = {
        let btn = PTLayoutButton()
        btn.normalTitleColor = self.viewConfig.normalColor
        btn.selectedTitleColor = self.viewConfig.selectedColor
        btn.midSpacing = self.viewConfig.imageTitleSpace
        btn.layoutStyle = self.viewConfig.imagePosition
        btn.selectedTitleFont = viewConfig.selectedFont
        btn.normalTitleFont = viewConfig.normalFont
        return btn
    }()
        
    lazy var underLine:UIButton = {
        let label = UIButton(type: .custom)
        
        label.setBackgroundImage(UIColor.clear.createImageWithColor(), for: .normal)
        label.setBackgroundImage(self.viewConfig.selectedColor_BG.createImageWithColor(), for: .selected)
        return label
    }()
    
    fileprivate init(config:PTSegmentConfig,
                subViewModels:PTSegmentModel,
                contentW:CGFloat,
                showType:PTSegmentButtonShowType) {
        viewConfig = config
        buttonShowType = showType
        super.init(frame: .zero)
        
        switch showType {
        case .OnlyTitle:
            imageBtn.normalTitle = subViewModels.titles
            imageBtn.midSpacing = 0
            imageBtn.imageSize = .zero
            imageBtn.layoutStyle = .leftImageRightTitle
        case .OnlyImage:
            imageBtn.midSpacing = 0
            imageBtn.layoutStyle = .leftImageRightTitle
            let placeHolderImage = subViewModels.imagePlaceHolder.stringIsEmpty() ? UIColor.randomColor.createImageWithColor() : UIImage(named: subViewModels.imagePlaceHolder)
            
            setBtnImage(subViewModels: subViewModels, placeHolderImage: placeHolderImage!)
        case .TitleImage:
            //MARK:两个都有
            let placeHolderImage = subViewModels.imagePlaceHolder.stringIsEmpty() ? UIColor.randomColor.createImageWithColor() : UIImage(named: subViewModels.imagePlaceHolder)
            imageBtn.normalTitle = subViewModels.titles
            setBtnImage(subViewModels: subViewModels, placeHolderImage: placeHolderImage!)
        }
        
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
            case .Background,.SubBackground:
                make.left.right.equalToSuperview()
                make.bottom.top.equalToSuperview().inset(self.viewConfig.bottomSquare)
            default:break
            }
        }

        switch config.showType {
        case .UnderLine:
            addSubview(underLine)
            underLine.snp.makeConstraints { (make) in
                switch showType {
                case .TitleImage:
                    make.left.right.equalTo(self.imageBtn)
                default:
                    make.left.right.equalTo(self.imageBtn)
                }
                var lineHight: CGFloat
                if self.viewConfig.underHight >= self.viewConfig.bottomSquare {
                    lineHight = self.viewConfig.bottomSquare
                    make.height.equalTo(self.viewConfig.bottomSquare)
                } else {
                    lineHight = self.viewConfig.underHight
                    make.height.equalTo(self.viewConfig.underHight)
                }
                make.bottom.equalToSuperview().inset((self.viewConfig.bottomSquare-lineHight)/2)
                if self.viewConfig.underlineRadius {
                    underLine.viewCorner(radius: lineHight/2)
                }
            }
        case .Dog:
            addSubview(underLine)
            underLine.snp.makeConstraints { (make) in
                let lineHight: CGFloat
                if self.viewConfig.underHight >= self.viewConfig.bottomSquare {
                    lineHight = self.viewConfig.bottomSquare
                    make.width.height.equalTo(self.viewConfig.bottomSquare)
                } else {
                    lineHight = self.viewConfig.underHight
                    make.width.height.equalTo(self.viewConfig.underHight)
                }
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset((self.viewConfig.bottomSquare-lineHight)/2)
                underLine.viewCorner(radius: lineHight/2)
            }
            
        case .Background:
            break
        case .SubBackground:
            imageBtn.configBackgroundColor = viewConfig.normalColor_BG
            imageBtn.configBackgroundSelectedColor = viewConfig.selectedColor_BG
        default:break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setBtnImage(subViewModels:PTSegmentModel,placeHolderImage:UIImage) {
        imageBtn.layoutLoadImage(contentData: subViewModels.imageURL as Any,iCloudDocumentName: subViewModels.iCloudDocument,emptyImage: placeHolderImage)
        
        imageBtn.layoutLoadImage(contentData: subViewModels.selectedImageURL as Any,iCloudDocumentName: subViewModels.iCloudDocument,emptyImage: placeHolderImage,controlState: .selected)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        switch buttonShowType {
        case .OnlyImage,.TitleImage:
            imageBtn.imageSize = CGSize(width: frame.size.height - 5, height: frame.size.height - 5)
        default:
            imageBtn.imageSize = .zero
        }
    }
}

@objcMembers
public class PTSegmentView: UIView {
        
    ///数据
    open var viewDatas = [PTSegmentModel]()
    
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
    
    ///选中某个index
    open var selectedIndex:Int? {
        didSet {
            setSelectItem(indexs: selectedIndex!)
        }
    }
    
    public var segTapBlock:((_ currentIndex:Int)->Void)?
    
    private var viewConfig = PTSegmentConfig()
    private var subViewArr = [UIView]()

    lazy var scrolView : UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.isPagingEnabled = false
        return view
    }()
    
    ///初始化
    public init(config:PTSegmentConfig? = PTSegmentConfig()) {
        super.init(frame: .zero)
        viewConfig = config!
    }
    
    ///刷新items
    public func reloadViewData(block:((_ index:Int)->Void)?) {
        subViewArr.forEach { (value) in
            let subV = value as! PTSegmentSubView
            subV.removeFromSuperview()
        }
        subViewArr.removeAll()
        scrolView.removeSubviews()
        setUI(datas: viewDatas)
        block?(selectedIndex ?? 0)
    }
    
    private func getContentWidth(datas:[PTSegmentModel],
                                 enumeratedHandle: (PTSegmentModel, Int, CGFloat, CGFloat, PTSegmentButtonShowType)->Void) {
        var scrolContentW:CGFloat = 0
        if datas.count > 0 {
            datas.enumerated().forEach { (index,value) in
                var subContentW:CGFloat = 0
                var subShowType:PTSegmentButtonShowType!
                getCurrentSubWidthAndType(value: value) { currentWidth, showType in
                    subShowType = showType
                    subContentW = currentWidth
                }

                if viewConfig.leftEdges {
                    if index == 0 {
                        scrolContentW = viewConfig.originalX
                    }
                }

                enumeratedHandle(value,index,subContentW,scrolContentW,subShowType)
                var space:CGFloat = 0
                if index != (datas.count - 1) {
                    space = viewConfig.itemSpace
                }

                scrolContentW += (subContentW + space)
            }
        }
    }
    
    func getTotalW(datas:[PTSegmentModel],completeHandle: (CGFloat, Bool)->Void) {
        var scrolContentW:CGFloat = 0
        var isExceed:Bool = false
        if datas.count > 0 {
            datas.enumerated().forEach { (index,value) in
                getCurrentSubWidthAndType(value: value) { currentWidth, showType in
                    scrolContentW += currentWidth
                }
                
                if index == (datas.count - 1) {
                    if scrolContentW > frame.size.width {
                        isExceed = true
                    }
                    
                    if viewConfig.itemSpace > 0 {
                        scrolContentW = scrolContentW + CGFloat(datas.count - 1) * viewConfig.itemSpace
                    }

                    
                    if viewConfig.leftEdges {
                        scrolContentW += viewConfig.originalX
                    }
                    completeHandle(scrolContentW,isExceed)
                }
            }
        } else {
            completeHandle(0,false)
        }
    }
    
    func getCurrentSubWidthAndType(value:PTSegmentModel,handle: (CGFloat, PTSegmentButtonShowType)->Void) {
        var subShowType:PTSegmentButtonShowType!
        let normalW = UIView.sizeFor(string: value.titles, font: viewConfig.normalFont, height: frame.size.height).width
        let selectedW = UIView.sizeFor(string: value.titles, font: viewConfig.selectedFont, height: frame.size.height).width
        
        var subContentW:CGFloat = 0
        if selectedW >= normalW {
            subContentW = selectedW + viewConfig.subViewInContentSpace + 10
        } else {
            subContentW = normalW + viewConfig.subViewInContentSpace + 10
        }
        
        if NSObject.checkObject(value.imageURL as? NSObject) && !value.titles.stringIsEmpty() && NSObject.checkObject(value.selectedImageURL as? NSObject) {
            subShowType = .OnlyTitle
            subContentW = subContentW + 10
        } else if !NSObject.checkObject(value.imageURL as? NSObject) && value.titles.stringIsEmpty() && !NSObject.checkObject(value.selectedImageURL as? NSObject) {
            subShowType = .OnlyImage
            subContentW = frame.height - 5 + viewConfig.subViewInContentSpace + 10
        } else if !NSObject.checkObject(value.imageURL as? NSObject) && !value.titles.stringIsEmpty() && !NSObject.checkObject(value.selectedImageURL as? NSObject) {
            subShowType = .TitleImage
            switch viewConfig.imagePosition {
            case .leftImageRightTitle,.leftTitleRightImage:
                subContentW = subContentW + viewConfig.imageTitleSpace + (frame.height-5) + 10
            default:
                subContentW = subContentW + 10
            }
        } else {
            subShowType = .OnlyTitle
            subContentW = subContentW + 10
        }
        handle(subContentW,subShowType)
    }
    
    private func setUI(datas:[PTSegmentModel]) {
        PTGCDManager.gcdAfter(time: 0.1) {
            
            self.getTotalW(datas: datas) { totalWidth, isExceed in
                self.getContentWidth(datas: datas) { currentModel, index,subContentW,x,showType in
                    var newX = x
                    
                    if !self.viewConfig.leftEdges {
                        if !isExceed {
                            newX += (self.frame.size.width - totalWidth) / 2
                        }
                    }
                                        
                    let subView = PTSegmentSubView(config: self.viewConfig,subViewModels: currentModel,contentW: (subContentW-self.viewConfig.subViewInContentSpace),showType: showType)
                    subView.tag = index
                    subView.frame = CGRect.init(x: newX, y: 0, width: subContentW, height: self.frame.size.height)
                    
                    switch showType {
                    case .TitleImage:
                        subView.imageBtn.tag = index
                        subView.imageBtn.addActionHandlers { (sender) in
                            self.setSelectItem(indexs: sender.tag)
                            self.segTapBlock?(sender.tag)
                        }
                    default:
                        subView.imageBtn.tag = index
                        subView.imageBtn.addActionHandlers { (sender) in
                            self.setSelectItem(indexs: sender.tag)
                            self.segTapBlock?(sender.tag)
                        }
                    }
                    self.scrolView.addSubview(subView)
                    self.subViewArr.append(subView)
                }
                
                self.addSubview(self.scrolView)
                self.scrolView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                self.scrolView.contentSize = CGSize.init(width: totalWidth, height: self.frame.size.height)
                self.selectedIndex = self.viewConfig.normalSelecdIndex
                
                self.scrolView.isScrollEnabled = isExceed
            }
            self.layoutSubviews()
        }
    }
    
    ///选择某个item
    public func setSelectItem(indexs:Int) {
        if indexs <= (subViewArr.count - 1) {
            let subV = subViewArr[indexs] as! PTSegmentSubView
            
            switch indexs {
            case 0:
                scrolView.pt.scrolToLeftAnimation(animation: true)
            default:
                scrolView.scrollRectToVisible(CGRect.init(x: (subV.frame.origin.x) + (subV.frame.size.width) / 2, y: 0, width: (subV.frame.size.width), height: frame.size.height), animated: true)
            }
            
            subViewArr.enumerated().forEach { (index,value) in
                let viewInArr = value as! PTSegmentSubView
                if index != indexs {
                    switch viewConfig.showType {
                    case .UnderLine,.Dog,.SubBackground:
                        viewInArr.underLine.isSelected = false
                    case .Background:
                        viewInArr.backgroundColor = viewConfig.normalColor_BG
                    default:break
                    }
                    viewInArr.imageBtn.isSelected = false
                } else {
                    switch viewConfig.showType {
                    case .UnderLine,.Dog,.SubBackground:
                        viewInArr.underLine.isSelected = true
                    case .Background:
                        viewInArr.backgroundColor = viewConfig.selectedColor_BG
                    default:break
                    }
                    viewInArr.imageBtn.isSelected = true
                }
            }
        }
    }
    
    ///设置某个Badge
    public func setSegBadge(indexView:Int,
                            badgePosition:PooSegmentBadgePosition? = .TopRight,
                            badgeBGColor:UIColor? = UIColor.red,
                            badgeShowType:PTBadgeStyle? = .RedDot,
                            badgeAnimation:PTBadgeAnimType? = .Breathe,
                            badgeValue:Int? = 1) {
        PTGCDManager.gcdAfter(time: 0.1) {
            self.subViewArr.enumerated().forEach { (index,value) in
                if index == indexView {
                    let subViews = (value as! PTSegmentSubView)
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
                    subViews.badgeBgColor = badgeBGColor!
                    subViews.showBadge(style: badgeShowType!, value: badgeValue!, aniType: badgeAnimation!)
                }
            }
        }
    }
    
    ///移除某个Badge
    public func removeBadgeAtIndex(indexView:Int) {
        subViewArr.enumerated().forEach { (index,value) in
            if index == indexView {
                let subViews = (value as! PTSegmentSubView)
                subViews.clearBadge()
            }
        }
    }
    
    ///移除全部Badge
    public func removeAllBadge() {
        subViewArr.enumerated().forEach { (index,value) in
            let subViews = (value as! PTSegmentSubView)
            subViews.clearBadge()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
