//
//  PTFusionCell.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import AttributedString
import SwifterSwift

public typealias PTCellSwitchBlock = (_ rowText:String,_ sender:UIControl) -> Void
public typealias PTSectionMoreBlock = (_ rowText:String,_ sender:UIButton) -> Void

fileprivate extension UIView {
    /// 绘制简单横线
    func drawLine() -> UIView {
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor(hexString: "#E8E8E8")
        return lineView
    }
}

@objcMembers
public class PTFusionCellContent:UIView {
    public static let ContentIconHeight:CGFloat = CGFloat.ScaleW(w: 64)
    public var switchValueChangeBlock:PTCellSwitchBlock?

    enum PTFusionContentCellType {
        case Name
        case NameContent
        case Content
        case None
    }
    
    enum PTFusionCellImageType {
        case OnlyLeftImage
        case OnlyRightImage
        case BothImage(type:PTFusionContentCellType)
        case LeftImageContent(type:PTFusionContentCellType)
        case RightImageContent(type:PTFusionContentCellType)
        case None(type:PTFusionContentCellType)
    }
    
    enum PTFusionCellAccessoryView {
        case Switch(type:PTFusionCellImageType)
        case DisclosureIndicator(type:PTFusionCellImageType)
        case NoneAccessoryView(type:PTFusionCellImageType)
        case More(type:PTFusionCellImageType)
        case Error
    }
    
    public var cellModel:PTFusionCellModel? {
        didSet {
            if let model = cellModel {
                self.loadCellData(cellModel: model)
            } else {
                self.removeSubviews()
            }
        }
    }
    
    func loadCellData(cellModel:PTFusionCellModel) {
        switch cellModel.accessoryType {
        case .Switch:
            if let _ = self.accessV {
                self.accessV?.removeFromSuperview()
                self.accessV = nil
            }
            if let _ = self.sectionMore {
                self.sectionMore?.removeFromSuperview()
                self.sectionMore = nil
            }
            let switchHeight = cellModel.switchControlWidth * (31 / 51)
            let rightSpacing:CGFloat = cellModel.rightSpace
            
            if let valueSwitch = self.valueSwitch {
                switchDataSet(switchControl: valueSwitch)
                valueSwitch.snp.remakeConstraints { make in
                    if #available(iOS 26.0, *) {} else {
                        make.width.equalTo(cellModel.switchControlWidth)
                        make.height.equalTo(switchHeight)
                    }
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview().inset(rightSpacing)
                }
            } else {
                valueSwitch = setValueSwitch()
                switchDataSet(switchControl: valueSwitch!)
                if valueSwitch is PTSwitch {
                    (valueSwitch as! PTSwitch).valueChangeCallBack = { value in
                        self.switchValueChangeBlock?(cellModel.name,self.valueSwitch!)
                    }
                } else if valueSwitch is UISwitch {
                    (valueSwitch as! UISwitch).addSwitchAction { sender in
                        self.switchValueChangeBlock?(cellModel.name,sender)
                    }
                }
                addSubview(valueSwitch!)
                valueSwitch!.snp.makeConstraints { (make) in
                    if #available(iOS 26.0, *) {} else {
                        make.width.equalTo(cellModel.switchControlWidth)
                        make.height.equalTo(switchHeight)
                    }
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview().inset(rightSpacing)
                }
            }
        case .DisclosureIndicator:
            if let _ = self.valueSwitch {
                valueSwitch?.removeFromSuperview()
                valueSwitch = nil
            }
            if let _ = self.sectionMore {
                self.sectionMore?.removeFromSuperview()
                self.sectionMore = nil
            }
            
            if let access = self.accessV {
                access.loadImage(contentData: cellModel.disclosureIndicatorImage as Any,iCloudDocumentName: cellModel.iCloudDocument)
                access.snp.remakeConstraints { make in
                    make.size.equalTo(cellModel.moreDisclosureIndicatorSize)
                    make.right.equalToSuperview().inset(cellModel.rightSpace)
                    make.centerY.equalToSuperview()
                }
            } else {
                accessV = setAccessV()
                addSubview(accessV!)
                accessV!.snp.makeConstraints { make in
                    make.size.equalTo(cellModel.moreDisclosureIndicatorSize)
                    make.right.equalToSuperview().inset(cellModel.rightSpace)
                    make.centerY.equalToSuperview()
                }
                accessV!.loadImage(contentData: cellModel.disclosureIndicatorImage as Any,iCloudDocumentName: cellModel.iCloudDocument)
            }
        case .More:
            if let _ = self.accessV {
                self.accessV?.removeFromSuperview()
                self.accessV = nil
            }
            if let _ = self.valueSwitch {
                valueSwitch?.removeFromSuperview()
                valueSwitch = nil
            }
            
            if let _ = self.sectionMore {
            } else {
                sectionMore = setSectionMore()
                addSubview(sectionMore!)
            }
            
            var moreWith:CGFloat = 0
            let moreStringWidth = UIView.sizeFor(string: cellModel.moreString, font: cellModel.moreFont, height: height - (cellModel.imageTopOffset + cellModel.imageBottomOffset)).width
            if let moreDis = cellModel.moreDisclosureIndicator,!cellModel.moreDisclosureIndicator.isNullOrEmpty() && !cellModel.moreString.stringIsEmpty() {
                //两个都有
                Task {
                    let result = await PTLoadImageFunction.loadImage(contentData: moreDis,iCloudDocumentName: cellModel.iCloudDocument)
                    self.sectionMore!.normalTitleFont = cellModel.moreFont
                    self.sectionMore!.normalTitle = cellModel.moreString
                    self.sectionMore!.normalTitleColor = cellModel.moreColor
                    self.sectionMore!.midSpacing = cellModel.moreDisclosureIndicatorSpace
                    self.sectionMore!.imageSize = cellModel.moreDisclosureIndicatorSize
                    self.sectionMore!.layoutStyle = cellModel.moreLayoutStyle
                    if (result.allImages?.count ?? 0) > 1 {
                        self.sectionMore!.normalImage = UIImage.animatedImage(with: result.allImages!, duration: result.loadTime)
                    } else if (result.allImages?.count ?? 0) == 1 {
                        self.sectionMore!.normalImage = result.firstImage
                    }
                    
                    switch cellModel.moreLayoutStyle {
                    case .leftImageRightTitle,.leftTitleRightImage:
                        moreWith = cellModel.moreDisclosureIndicatorSize.width + cellModel.moreDisclosureIndicatorSpace + moreStringWidth + 5
                    case .upImageDownTitle,.upTitleDownImage:
                        if moreStringWidth > cellModel.moreDisclosureIndicatorSize.width {
                            moreWith = moreStringWidth + 5
                        } else {
                            moreWith = cellModel.moreDisclosureIndicatorSize.width + 5
                        }
                    case .title:
                        moreWith = moreStringWidth + 5
                    case .image:
                        moreWith = cellModel.moreDisclosureIndicatorSize.width + 5
                    }
                    self.sectionMore!.snp.makeConstraints { make in
                        make.top.equalToSuperview().inset(cellModel.imageTopOffset)
                        make.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
                        make.right.equalToSuperview().inset(cellModel.rightSpace)
                        make.centerY.equalToSuperview()
                        make.width.equalTo(moreWith)
                    }
                }
            } else if cellModel.moreDisclosureIndicator.isNullOrEmpty() && !cellModel.moreString.stringIsEmpty() {
                //没图片
                sectionMore!.normalTitleFont = cellModel.moreFont
                sectionMore!.normalTitle = cellModel.moreString
                sectionMore!.normalTitleColor = cellModel.moreColor
                sectionMore!.midSpacing = 0
                sectionMore!.imageSize = .zero
                sectionMore!.layoutStyle = cellModel.moreLayoutStyle
                moreWith = moreStringWidth + 5
                sectionMore!.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(cellModel.imageTopOffset)
                    make.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
                    make.right.equalToSuperview().inset(cellModel.rightSpace)
                    make.centerY.equalToSuperview()
                    make.width.equalTo(moreWith)
                }
            } else if let moreDis = cellModel.moreDisclosureIndicator,!cellModel.moreDisclosureIndicator.isNullOrEmpty(), cellModel.moreString.stringIsEmpty() {
                //没字
                Task {
                    let result = await PTLoadImageFunction.loadImage(contentData: moreDis,iCloudDocumentName: cellModel.iCloudDocument)
                    self.sectionMore!.midSpacing = 0
                    self.sectionMore!.imageSize = cellModel.moreDisclosureIndicatorSize
                    self.sectionMore!.layoutStyle = cellModel.moreLayoutStyle
                    if (result.allImages?.count ?? 0) > 1 {
                        self.sectionMore!.normalImage = UIImage.animatedImage(with: result.allImages!, duration: result.loadTime)
                    } else if (result.allImages?.count ?? 0) == 1 {
                        self.sectionMore!.normalImage = result.firstImage
                    }
                    moreWith = cellModel.moreDisclosureIndicatorSize.width + 5
                    self.sectionMore!.snp.makeConstraints { make in
                        make.top.equalToSuperview().inset(cellModel.imageTopOffset)
                        make.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
                        make.right.equalToSuperview().inset(cellModel.rightSpace)
                        make.centerY.equalToSuperview()
                        make.width.equalTo(moreWith)
                    }
                }
            }

        case .NoneAccessoryView:
            if let _ = self.accessV {
                self.accessV?.removeFromSuperview()
                self.accessV = nil
            }
            if let _ = self.valueSwitch {
                valueSwitch?.removeFromSuperview()
                valueSwitch = nil
            }
            if let _ = self.sectionMore {
                self.sectionMore?.removeFromSuperview()
                self.sectionMore = nil
            }
        }
        
        accessoryViewType(type: cellModel.accessoryType) { cellType in
            PTGCDManager.gcdAfter(time: 0.1) {
                self.setLeftIconView(cellType: cellType,cellModel:cellModel)
                self.setRightIconView(cellType: cellType,cellModel:cellModel)
                self.setTitleLabel(cellType: cellType,cellModel:cellModel)
                self.setRightContent(cellType: cellType,cellModel:cellModel)
                self.setLine(cellType: cellType,cellModel:cellModel)
                
                PTGCDManager.gcdMain {
                    if cellModel.conrner != [] {
                        self.viewCornerRectCorner(cornerRadii: cellModel.cellCorner, corner: cellModel.conrner)
                    } else {
                        self.viewCornerRectCorner(cornerRadii: 0, corner: [.allCorners])
                    }
                }
            }
        }
    }
    
    fileprivate var nameTitle: UILabel?
    fileprivate func setNameTitle() -> UILabel {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }
    
    fileprivate var accessV: UIImageView?
    fileprivate func setAccessV() -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }
    
    public var valueSwitch: UIControl?
    fileprivate func setValueSwitch() -> UIControl {
        if #available(iOS 26.0, *) {
            let switchV = UISwitch()
            return switchV
        } else {
            let switchV = PTSwitch()
            return switchV
        }
    }
    
    fileprivate func switchDataSet(switchControl:UIControl) {
        if let currentCellModel = cellModel {
            if let ptSwitch = switchControl as? PTSwitch {
                ptSwitch.onTintColor = currentCellModel.switchOnTinColor
                ptSwitch.thumbColor = currentCellModel.switchThumbTintColor
                ptSwitch.switchTintColor = currentCellModel.switchTintColor
                ptSwitch.backgroundColor = currentCellModel.switchBackgroundColor
            } else if let iOSSwitch = switchControl as? UISwitch {
                iOSSwitch.onTintColor = currentCellModel.switchOnTinColor
                iOSSwitch.thumbTintColor = currentCellModel.switchThumbTintColor
                iOSSwitch.tintColor = currentCellModel.switchTintColor
                iOSSwitch.backgroundColor = currentCellModel.switchBackgroundColor
            }
        }
    }
    
    var contentLabel: UILabel?
    fileprivate func setContentLabel() -> UILabel {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }
    
    var cellIcon: UIImageView?
    fileprivate func setCellIcon() -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }
    
    public var sectionMore:PTLayoutButton?
    fileprivate func setSectionMore() -> PTLayoutButton {
        let view = PTLayoutButton()
        view.isUserInteractionEnabled = true
        return view
    }
    
    fileprivate var contentButtonLabel: PTLayoutButton?
    fileprivate func setContentButtonLabel() -> PTLayoutButton {
        let view = PTLayoutButton()
        view.titleLabel?.numberOfLines = 0
        view.layoutStyle = .leftImageRightTitle
        view.isUserInteractionEnabled = false
        return view
    }
        
    public lazy var topLineView: UIView = {
        let view = drawLine()
        view.backgroundColor = self.cellModel!.topLineColor
        return view
    }()
    public lazy var lineView: UIView = {
        let view = drawLine()
        view.backgroundColor = self.cellModel!.bottomLineColor
        return view
    }()
    
    public lazy var topImaginaryLineView: PTImaginaryLineView = {
        let view = PTImaginaryLineView()
        view.lineColor = self.cellModel!.topLineColor
        return view
    }()
    public lazy var imaginaryLineView: PTImaginaryLineView = {
        let view = PTImaginaryLineView()
        view.lineColor = self.cellModel!.bottomLineColor
        return view
    }()
    
    fileprivate var cellContentIcon: UIImageView?
    fileprivate func setCellContentIcon() -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func accessoryViewType(type: PTFusionShowAccessoryType, finish: (PTFusionCellAccessoryView) -> Void) {
        let hasLeftImage = cellModel?.leftImage != nil
        let hasContentIcon = cellModel?.contentIcon != nil
        let hasNameOrDescOrAttr = !(cellModel?.name.stringIsEmpty() ?? true) || !(cellModel?.desc.stringIsEmpty() ?? true) || cellModel?.nameAttr != nil
        let hasContentOrAttr = !(cellModel?.content.stringIsEmpty() ?? true) || cellModel?.contentAttr != nil

        let viewType: PTFusionCellImageType

        switch (hasLeftImage, hasNameOrDescOrAttr, hasContentOrAttr, hasContentIcon) {
        case (true, true, false, false):
            viewType = .LeftImageContent(type: .Name)
        case (true, true, true, false):
            viewType = .LeftImageContent(type: .NameContent)
        case (true, true, false, true):
            viewType = .BothImage(type: .Name)
        case (true, false, true, true):
            viewType = .BothImage(type: .Content)
        case (true, true, true, true):
            viewType = .BothImage(type: .NameContent)
        case (true, false, true, false):
            viewType = .LeftImageContent(type: .Content)
        case (true, false, false, false):
            viewType = .OnlyLeftImage
        case (false, false, false, true):
            viewType = .OnlyRightImage
        case (false, true, false, true):
            viewType = .RightImageContent(type: .Name)
        case (false, true, true, true):
            viewType = .RightImageContent(type: .NameContent)
        case (false, false, true, true):
            viewType = .RightImageContent(type: .Content)
        case (false, true, true, false):
            viewType = .None(type: .NameContent)
        case (true, false, false, true):
            viewType = .BothImage(type: .None)
        case (false, true, false, false):
            viewType = .None(type: .Name)
        case (false, false, true, false):
            viewType = .None(type: .Content)
        default:
            finish(.Error)
            return
        }

        let accessoryView: PTFusionCellAccessoryView

        switch type {
        case .Switch:
            accessoryView = .Switch(type: viewType)
        case .DisclosureIndicator:
            accessoryView = .DisclosureIndicator(type: viewType)
        case .NoneAccessoryView:
            accessoryView = .NoneAccessoryView(type: viewType)
        case .More:
            accessoryView = .More(type: viewType)
        }

        finish(accessoryView)
    }
    
    //MARK: 设置左图标
    func setLeftIconView(cellType: PTFusionCellAccessoryView,cellModel:PTFusionCellModel) {
        let isLeftIconNeeded: Bool

        switch cellType {
        case .Switch(let type), .DisclosureIndicator(let type), .NoneAccessoryView(let type), .More(let type):
            switch type {
            case .OnlyLeftImage, .BothImage, .LeftImageContent:
                isLeftIconNeeded = true
            default:
                isLeftIconNeeded = false
            }
        default:
            isLeftIconNeeded = false
        }

        if isLeftIconNeeded {
            if let icon = cellIcon {
                icon.snp.remakeConstraints { make in
                    make.top.equalToSuperview().inset(cellModel.imageTopOffset)
                    make.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
                    make.left.equalToSuperview().inset(cellModel.leftSpace)
                    make.width.equalTo(icon.snp.height)
                }
            } else {
                cellIcon = setCellIcon()
                addSubview(cellIcon!)
                cellIcon!.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(cellModel.imageTopOffset)
                    make.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
                    make.left.equalToSuperview().inset(cellModel.leftSpace)
                    make.width.equalTo(cellIcon!.snp.height)
                }
            }

            if cellModel.iconRound {
                PTGCDManager.gcdMain {
                    self.cellIcon!.viewCorner(radius: (self.frame.size.height - cellModel.imageTopOffset - cellModel.imageBottomOffset) / 2)
                }
            }
            cellIcon!.loadImage(contentData: cellModel.leftImage as Any, iCloudDocumentName: cellModel.iCloudDocument)
        } else {
            if let _ = cellIcon {
                cellIcon?.removeFromSuperview()
                cellIcon = nil
            }
        }
    }
    
    //MARK: 设置右图标
    func setRightIconView(cellType: PTFusionCellAccessoryView,cellModel:PTFusionCellModel) {
        let shouldShowIcon: Bool
        let rightConstraintView: UIView?

        switch cellType {
        case .Switch(type: .OnlyRightImage),
             .Switch(type: .BothImage),
             .Switch(type: .RightImageContent):
            shouldShowIcon = true
            rightConstraintView = valueSwitch
            
        case .DisclosureIndicator(type: .OnlyRightImage),
             .DisclosureIndicator(type: .BothImage),
             .DisclosureIndicator(type: .RightImageContent):
            shouldShowIcon = true
            rightConstraintView = accessV

        case .NoneAccessoryView(type: .OnlyRightImage),
             .NoneAccessoryView(type: .BothImage),
             .NoneAccessoryView(type: .RightImageContent):
            shouldShowIcon = true
            rightConstraintView = nil
            
        case .More(type: .OnlyRightImage),
             .More(type: .BothImage),
             .More(type: .RightImageContent):
            shouldShowIcon = true
            rightConstraintView = sectionMore
            
        default:
            shouldShowIcon = false
            rightConstraintView = nil
        }

        if shouldShowIcon {
            if let cellContentIcon = self.cellContentIcon {
                cellContentIcon.snp.remakeConstraints { make in
                    make.top.equalToSuperview().inset(cellModel.imageTopOffset)
                    make.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
                    if let rightView = rightConstraintView {
                        make.right.equalTo(rightView.snp.left).offset(-cellModel.contentRightSpace)
                    } else {
                        make.right.equalToSuperview().inset(cellModel.rightSpace)
                    }
                    make.width.equalTo(cellContentIcon.snp.height)
                }
            } else {
                cellContentIcon = setCellContentIcon()
                addSubview(cellContentIcon!)
                cellContentIcon!.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(cellModel.imageTopOffset)
                    make.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
                    if let rightView = rightConstraintView {
                        make.right.equalTo(rightView.snp.left).offset(-cellModel.contentRightSpace)
                    } else {
                        make.right.equalToSuperview().inset(cellModel.rightSpace)
                    }
                    make.width.equalTo(self.cellContentIcon!.snp.height)
                }

            }
            cellContentIcon!.loadImage(contentData: cellModel.contentIcon as Any, iCloudDocumentName: cellModel.iCloudDocument)
        } else {
            if let _ = cellContentIcon {
                cellContentIcon?.removeFromSuperview()
                cellContentIcon = nil
            }
        }
    }
    
    //MARK: 设置主文本
    func setTitleLabel(cellType:PTFusionCellAccessoryView,cellModel:PTFusionCellModel) {
        switch cellType {
        case .Switch(type: .LeftImageContent(type: .Name)),
                .Switch(type: .LeftImageContent(type: .NameContent)),
                .Switch(type: .BothImage(type: .Name)),
                .Switch(type: .BothImage(type: .NameContent)),
                .Switch(type: .None(type: .Name)),
                .Switch(type: .None(type: .NameContent)),
                .Switch(type: .RightImageContent(type: .Name)),
                .Switch(type: .RightImageContent(type: .NameContent)),
                .DisclosureIndicator(type: .LeftImageContent(type: .Name)),
                .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                .DisclosureIndicator(type: .BothImage(type: .Name)),
                .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                .DisclosureIndicator(type: .None(type: .Name)),
                .DisclosureIndicator(type: .None(type: .NameContent)),
                .DisclosureIndicator(type: .RightImageContent(type: .Name)),
                .DisclosureIndicator(type: .RightImageContent(type: .NameContent)),
                .NoneAccessoryView(type: .RightImageContent(type: .Name)),
                .NoneAccessoryView(type: .RightImageContent(type: .NameContent)),
                .NoneAccessoryView(type: .None(type: .Name)),
                .NoneAccessoryView(type: .None(type: .NameContent)),
                .NoneAccessoryView(type: .LeftImageContent(type: .Name)),
                .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                .NoneAccessoryView(type: .BothImage(type: .Name)),
                .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                .More(type: .RightImageContent(type: .Name)),
                .More(type: .RightImageContent(type: .NameContent)),
                .More(type: .None(type: .Name)),
                .More(type: .None(type: .NameContent)),
                .More(type: .LeftImageContent(type: .Name)),
                .More(type: .LeftImageContent(type: .NameContent)),
                .More(type: .BothImage(type: .Name)),
                .More(type: .BothImage(type: .NameContent)):
            
            var atts:ASAttributedString = ASAttributedString(string: "")
            if let cellAtt = cellModel.nameAttr {
                atts = cellAtt
            } else {
                if !cellModel.name.stringIsEmpty() && cellModel.desc.stringIsEmpty() {
                    let nameAtts:ASAttributedString =  ASAttributedString("\(cellModel.name)",.paragraph(.alignment(.left),.lineSpacing(cellModel.labelLineSpace)),.font(cellModel.cellFont),.foreground(cellModel.nameColor))
                    atts = nameAtts
                } else if cellModel.name.stringIsEmpty() && !cellModel.desc.stringIsEmpty() {
                    let descAtts:ASAttributedString =  ASAttributedString("\(cellModel.desc)",.paragraph(.alignment(.left),.lineSpacing(cellModel.labelLineSpace)),.font(cellModel.cellDescFont),.foreground(cellModel.descColor))
                    atts = descAtts
                } else if !cellModel.name.stringIsEmpty() && !cellModel.desc.stringIsEmpty() {
                    let nameAtts:ASAttributedString =  ASAttributedString("\(cellModel.name)",.paragraph(.alignment(.left),.lineSpacing(cellModel.labelLineSpace)),.font(cellModel.cellFont),.foreground(cellModel.nameColor))
                    let descAtts:ASAttributedString =  ASAttributedString("\n\(cellModel.desc)",.paragraph(.alignment(.left),.lineSpacing(cellModel.labelLineSpace)),.font(cellModel.cellDescFont),.foreground(cellModel.descColor))
                    atts = nameAtts + descAtts
                }
            }
            if let nameT = nameTitle {
                nameT.attributed.text = atts
                self.nameTitle!.snp.remakeConstraints { make in
                    make.top.bottom.lessThanOrEqualToSuperview().inset(5)
                    make.centerY.equalToSuperview()
                    switch cellType {
                    case .Switch(type: .None(type: .Name)),
                            .Switch(type: .None(type: .NameContent)),
                            .Switch(type: .RightImageContent(type: .NameContent)),
                            .Switch(type: .RightImageContent(type: .Name)),
                            .DisclosureIndicator(type: .None(type: .Name)),
                            .DisclosureIndicator(type: .None(type: .NameContent)),
                            .DisclosureIndicator(type: .RightImageContent(type: .Name)),
                            .DisclosureIndicator(type: .RightImageContent(type: .NameContent)),
                            .NoneAccessoryView(type: .None(type: .Name)),
                            .NoneAccessoryView(type: .None(type: .NameContent)),
                            .NoneAccessoryView(type: .RightImageContent(type: .Name)),
                            .NoneAccessoryView(type: .RightImageContent(type: .NameContent)),
                            .More(type: .None(type: .Name)),
                            .More(type: .None(type: .NameContent)),
                            .More(type: .RightImageContent(type: .Name)),
                            .More(type: .RightImageContent(type: .NameContent)):
                        make.left.equalToSuperview().inset(cellModel.leftSpace)
                    case .Switch(type: .LeftImageContent(type: .Name)),
                            .Switch(type: .LeftImageContent(type: .NameContent)),
                            .Switch(type: .BothImage(type: .Name)),
                            .Switch(type: .BothImage(type: .NameContent)),
                            .DisclosureIndicator(type: .LeftImageContent(type: .Name)),
                            .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                            .DisclosureIndicator(type: .BothImage(type: .Name)),
                            .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                            .NoneAccessoryView(type: .LeftImageContent(type: .Name)),
                            .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                            .NoneAccessoryView(type: .BothImage(type: .Name)),
                            .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                            .More(type: .LeftImageContent(type: .Name)),
                            .More(type: .LeftImageContent(type: .NameContent)),
                            .More(type: .BothImage(type: .Name)),
                            .More(type: .BothImage(type: .NameContent)):
                        make.left.equalTo(self.cellIcon!.snp.right).offset(cellModel.contentLeftSpace)
                    default:
                        make.left.equalToSuperview().inset(cellModel.leftSpace + cellModel.contentLeftSpace + (self.frame.size.height - (cellModel.imageTopOffset + cellModel.imageBottomOffset)))
                    }
                    
                    switch cellType {
                    case .Switch(type: .BothImage(type: .Name)),
                            .DisclosureIndicator(type: .BothImage(type: .Name)),
                            .NoneAccessoryView(type: .BothImage(type: .Name)),
                            .More(type: .BothImage(type: .Name)):
                        make.right.equalTo(self.cellContentIcon!.snp.left).offset(-cellModel.contentRightSpace)
                    case .Switch(type: .None(type: .Name)):
                        make.right.equalTo(self.valueSwitch!.snp.left).offset(-cellModel.contentRightSpace)
                    case .DisclosureIndicator(type: .None(type: .Name)):
                        make.right.equalToSuperview().inset(cellModel.contentRightSpace)
                    case .More(type: .None(type: .Name)):
                        make.right.equalTo(self.sectionMore!.snp.left).offset(-cellModel.contentRightSpace)
                    case .Switch(type: .BothImage(type: .NameContent)),
                            .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                            .More(type: .BothImage(type: .NameContent)),
                            .Switch(type: .None(type: .Content)),
                            .DisclosureIndicator(type: .None(type: .Content)),
                            .More(type: .None(type: .Content)):
                        var titleWidth = UIView.sizeFor(string: atts.value.string, font: .appfont(size: atts.value.largestFontSize()),height: self.height).width + 5
                        let maxWidth = (self.width - 10  - cellModel.leftSpace - cellModel.contentLeftSpace - cellModel.contentRightSpace - cellModel.rightSpace) / 2
                        if titleWidth > maxWidth {
                            titleWidth = maxWidth
                        } else if titleWidth < 1 {
                            titleWidth = maxWidth
                        }
                        make.width.equalTo(titleWidth)
                    case .Switch(type: .LeftImageContent(type: .Name)):
                        make.right.equalTo(self.valueSwitch!.snp.left).offset(-cellModel.contentRightSpace)
                    case .DisclosureIndicator(type: .None(type: .NameContent)),
                            .NoneAccessoryView(type: .None(type: .NameContent)),
                            .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)):
                        var titleWidth = UIView.sizeFor(string: atts.value.string, font: .appfont(size: atts.value.largestFontSize()),height: self.height).width + 5
                        let maxWidth = (self.width - 10  - cellModel.leftSpace - cellModel.contentLeftSpace - cellModel.contentRightSpace - cellModel.rightSpace) / 2
                        if titleWidth > maxWidth {
                            titleWidth = maxWidth
                        } else if titleWidth < 1 {
                            titleWidth = maxWidth
                        }
                        make.width.equalTo(titleWidth)
                    default:
                        make.right.equalToSuperview().inset(cellModel.rightSpace)
                    }
                }
            } else {
                nameTitle = setNameTitle()
                nameTitle!.attributed.text = atts
                addSubview(nameTitle!)
                self.nameTitle!.snp.makeConstraints { make in
                    make.top.bottom.lessThanOrEqualToSuperview().inset(5)
                    make.centerY.equalToSuperview()
                    switch cellType {
                    case .Switch(type: .None(type: .Name)),
                            .Switch(type: .None(type: .NameContent)),
                            .Switch(type: .RightImageContent(type: .NameContent)),
                            .Switch(type: .RightImageContent(type: .Name)),
                            .DisclosureIndicator(type: .None(type: .Name)),
                            .DisclosureIndicator(type: .None(type: .NameContent)),
                            .DisclosureIndicator(type: .RightImageContent(type: .Name)),
                            .DisclosureIndicator(type: .RightImageContent(type: .NameContent)),
                            .NoneAccessoryView(type: .None(type: .Name)),
                            .NoneAccessoryView(type: .None(type: .NameContent)),
                            .NoneAccessoryView(type: .RightImageContent(type: .Name)),
                            .NoneAccessoryView(type: .RightImageContent(type: .NameContent)),
                            .More(type: .None(type: .Name)),
                            .More(type: .None(type: .NameContent)),
                            .More(type: .RightImageContent(type: .Name)),
                            .More(type: .RightImageContent(type: .NameContent)):
                        make.left.equalToSuperview().inset(cellModel.leftSpace)
                    case .Switch(type: .LeftImageContent(type: .Name)),
                            .Switch(type: .LeftImageContent(type: .NameContent)),
                            .Switch(type: .BothImage(type: .Name)),
                            .Switch(type: .BothImage(type: .NameContent)),
                            .DisclosureIndicator(type: .LeftImageContent(type: .Name)),
                            .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                            .DisclosureIndicator(type: .BothImage(type: .Name)),
                            .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                            .NoneAccessoryView(type: .LeftImageContent(type: .Name)),
                            .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                            .NoneAccessoryView(type: .BothImage(type: .Name)),
                            .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                            .More(type: .LeftImageContent(type: .Name)),
                            .More(type: .LeftImageContent(type: .NameContent)),
                            .More(type: .BothImage(type: .Name)),
                            .More(type: .BothImage(type: .NameContent)):
                        make.left.equalTo(self.cellIcon!.snp.right).offset(cellModel.contentLeftSpace)
                    default:
                        make.left.equalToSuperview().inset(cellModel.leftSpace + cellModel.contentLeftSpace + (self.frame.size.height - (cellModel.imageTopOffset + cellModel.imageBottomOffset)))
                    }
                    
                    switch cellType {
                    case .Switch(type: .BothImage(type: .Name)),
                            .DisclosureIndicator(type: .BothImage(type: .Name)),
                            .NoneAccessoryView(type: .BothImage(type: .Name)),
                            .More(type: .BothImage(type: .Name)):
                        make.right.equalTo(self.cellContentIcon!.snp.left).offset(-cellModel.contentRightSpace)
                    case .Switch(type: .None(type: .Name)):
                        make.right.equalTo(self.valueSwitch!.snp.left).offset(-cellModel.contentRightSpace)
                    case .DisclosureIndicator(type: .None(type: .Name)):
                        make.right.equalToSuperview().inset(cellModel.contentRightSpace)
                    case .More(type: .None(type: .Name)):
                        make.right.equalTo(self.sectionMore!.snp.left).offset(-cellModel.contentRightSpace)
                    case .Switch(type: .BothImage(type: .NameContent)),
                            .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                            .More(type: .BothImage(type: .NameContent)),
                            .Switch(type: .None(type: .Content)),
                            .DisclosureIndicator(type: .None(type: .Content)),
                            .More(type: .None(type: .Content)):
                        var titleWidth = UIView.sizeFor(string: atts.value.string, font: .appfont(size: atts.value.largestFontSize()),height: self.height).width + 5
                        let maxWidth = (self.width - 10  - cellModel.leftSpace - cellModel.contentLeftSpace - cellModel.contentRightSpace - cellModel.rightSpace) / 2
                        if titleWidth > maxWidth {
                            titleWidth = maxWidth
                        } else if titleWidth < 1 {
                            titleWidth = maxWidth
                        }
                        make.width.equalTo(titleWidth)
                    case .Switch(type: .LeftImageContent(type: .Name)):
                        make.right.equalTo(self.valueSwitch!.snp.left).offset(-cellModel.contentRightSpace)
                    case .DisclosureIndicator(type: .None(type: .NameContent)),
                            .NoneAccessoryView(type: .None(type: .NameContent)),
                            .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)):
                        var titleWidth = UIView.sizeFor(string: atts.value.string, font: .appfont(size: atts.value.largestFontSize()),height: self.height).width + 5
                        let maxWidth = (self.width - 10  - cellModel.leftSpace - self.cellModel!.contentLeftSpace - cellModel.contentRightSpace - cellModel.rightSpace) / 2
                        if titleWidth > maxWidth {
                            titleWidth = maxWidth
                        } else if titleWidth < 1 {
                            titleWidth = maxWidth
                        }
                        make.width.equalTo(titleWidth)
                    default:
                        make.right.equalToSuperview().inset(cellModel.rightSpace)
                    }
                }
            }
        default:
            if let _ = nameTitle {
                nameTitle?.removeFromSuperview()
                nameTitle = nil
            }
        }
    }
    
    //MARK: 设置右文本
    func setRightContent(cellType:PTFusionCellAccessoryView,cellModel:PTFusionCellModel) {
        switch cellType {
        case .Switch(let type),.DisclosureIndicator(let type),.NoneAccessoryView(let type),.More(let type):
            switch type {
            case .BothImage(let subType),.LeftImageContent(let subType),.RightImageContent(let subType),.None(let subType):
                switch subType {
                case .NameContent,.Content:
                
                    if let contentL = contentLabel {
                        contentL.snp.remakeConstraints { make in
                            make.top.bottom.equalToSuperview()
                                                
                            switch cellType {
                            case .Switch(type: .None(type: .Content)),
                                    .DisclosureIndicator(type: .None(type: .Content)),
                                    .More(type: .None(type: .Content)):
                                make.left.equalToSuperview().inset(cellModel.leftSpace)
                            case .Switch(type: .LeftImageContent(type: .Content)),
                                    .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                                    .More(type: .LeftImageContent(type: .Content)),
                                    .Switch(type: .BothImage(type: .Content)),
                                    .DisclosureIndicator(type: .BothImage(type: .Content)),
                                    .More(type: .BothImage(type: .Content)):
                                make.left.equalTo(self.cellIcon!.snp.right).offset(cellModel.contentLeftSpace)
                            case .NoneAccessoryView(type: .None(type: .Content)):
                                make.left.equalToSuperview().inset(cellModel.contentLeftSpace)
                            default:
                                make.left.equalTo(self.nameTitle!.snp.right).offset(10)
                            }
                            
                            switch cellType {
                            case .Switch(type: .None(type: .Content)),
                                    .Switch(type: .LeftImageContent(type: .Content)),
                                    .Switch(type: .LeftImageContent(type: .NameContent)),
                                    .Switch(type: .None(type: .NameContent)):
                                make.right.equalTo(self.valueSwitch!.snp.left).offset(-cellModel.contentRightSpace)
                            case .DisclosureIndicator(type: .None(type: .Content)),
                                    .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                                    .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                                    .DisclosureIndicator(type: .None(type: .NameContent)):
                                make.right.equalTo(self.accessV!.snp.left).offset(-self.cellModel!.contentRightSpace)
                            case .More(type: .None(type: .Content)),
                                    .More(type: .LeftImageContent(type: .Content)),
                                    .More(type: .LeftImageContent(type: .NameContent)),
                                    .More(type: .None(type: .NameContent)):
                                make.right.equalTo(self.sectionMore!.snp.left).offset(-cellModel.contentRightSpace)
                            case .NoneAccessoryView(type: .BothImage(type: .Content)),
                                    .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                                    .NoneAccessoryView(type: .LeftImageContent(type: .Content)),
                                    .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                                    .NoneAccessoryView(type: .None(type: .Content)),
                                    .NoneAccessoryView(type: .None(type: .NameContent)),
                                    .NoneAccessoryView(type: .RightImageContent(type: .Content)),
                                    .NoneAccessoryView(type: .RightImageContent(type: .NameContent)):
                                make.right.equalToSuperview().inset(cellModel.contentRightSpace)
                            default:
                                make.right.equalTo(self.cellContentIcon!.snp.left).offset(-cellModel.contentRightSpace)
                            }
                        }

                    } else {
                        contentLabel = setContentLabel()
                        addSubview(contentLabel!)
                        contentLabel!.snp.makeConstraints { make in
                            make.top.bottom.equalToSuperview()
                                                
                            switch cellType {
                            case .Switch(type: .None(type: .Content)),
                                    .DisclosureIndicator(type: .None(type: .Content)),
                                    .More(type: .None(type: .Content)):
                                make.left.equalToSuperview().inset(cellModel.leftSpace)
                            case .Switch(type: .LeftImageContent(type: .Content)),
                                    .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                                    .More(type: .LeftImageContent(type: .Content)),
                                    .Switch(type: .BothImage(type: .Content)),
                                    .DisclosureIndicator(type: .BothImage(type: .Content)),
                                    .More(type: .BothImage(type: .Content)):
                                make.left.equalTo(self.cellIcon!.snp.right).offset(cellModel.contentLeftSpace)
                            case .NoneAccessoryView(type: .None(type: .Content)):
                                make.left.equalToSuperview().inset(cellModel.contentLeftSpace)
                            default:
                                make.left.equalTo(self.nameTitle!.snp.right).offset(10)
                            }
                            
                            switch cellType {
                            case .Switch(type: .None(type: .Content)),
                                    .Switch(type: .LeftImageContent(type: .Content)),
                                    .Switch(type: .LeftImageContent(type: .NameContent)),
                                    .Switch(type: .None(type: .NameContent)):
                                make.right.equalTo(self.valueSwitch!.snp.left).offset(-cellModel.contentRightSpace)
                            case .DisclosureIndicator(type: .None(type: .Content)),
                                    .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                                    .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                                    .DisclosureIndicator(type: .None(type: .NameContent)):
                                make.right.equalTo(self.accessV!.snp.left).offset(-cellModel.contentRightSpace)
                            case .More(type: .None(type: .Content)),
                                    .More(type: .LeftImageContent(type: .Content)),
                                    .More(type: .LeftImageContent(type: .NameContent)),
                                    .More(type: .None(type: .NameContent)):
                                make.right.equalTo(self.sectionMore!.snp.left).offset(-cellModel.contentRightSpace)
                            case .NoneAccessoryView(type: .BothImage(type: .Content)),
                                    .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                                    .NoneAccessoryView(type: .LeftImageContent(type: .Content)),
                                    .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                                    .NoneAccessoryView(type: .None(type: .Content)),
                                    .NoneAccessoryView(type: .None(type: .NameContent)),
                                    .NoneAccessoryView(type: .RightImageContent(type: .Content)),
                                    .NoneAccessoryView(type: .RightImageContent(type: .NameContent)):
                                make.right.equalToSuperview().inset(cellModel.contentRightSpace)
                            default:
                                make.right.equalTo(self.cellContentIcon!.snp.left).offset(-cellModel.contentRightSpace)
                            }
                        }
                    }
                    
                    if cellModel.contentAttr != nil && cellModel.content.stringIsEmpty() {
                        contentLabel!.attributed.text = cellModel.contentAttr
                    } else if cellModel.contentAttr == nil && !cellModel.content.stringIsEmpty() {
                        contentLabel?.numberOfLines = cellModel.contentNumberOfLines
                        let contentAtts:ASAttributedString =  ASAttributedString("\(cellModel.content)",.paragraph(.alignment(.right),.lineSpacing(cellModel.labelLineSpace),.lineBreakMode(cellModel.contentLineBreakMode)),.font(cellModel.contentFont),.foreground(cellModel.contentTextColor))
                        contentLabel!.attributed.text = contentAtts
                    }
                default:
                    if let _ = contentLabel {
                        contentLabel?.removeFromSuperview()
                        contentLabel = nil
                    }
                }
            default:
                if let _ = contentLabel {
                    contentLabel?.removeFromSuperview()
                    contentLabel = nil
                }
            }
        case .Error:
            if let _ = contentLabel {
                contentLabel?.removeFromSuperview()
                contentLabel = nil
            }
        }
    }
    
    //MARK: 设置上下线
    func setLine(cellType:PTFusionCellAccessoryView,cellModel:PTFusionCellModel) {
        switch cellModel.haveLine {
        case .Normal:
            lineView.isHidden = false
            imaginaryLineView.isHidden = true
        case .Imaginary:
            lineView.isHidden = true
            imaginaryLineView.isHidden = false
        case .NO:
            lineView.isHidden = true
            imaginaryLineView.isHidden = true
        default:
            lineView.isHidden = true
            imaginaryLineView.isHidden = true
        }
        
        switch cellModel.haveTopLine {
        case .Normal:
            topLineView.isHidden = false
            topImaginaryLineView.isHidden = true
        case .Imaginary:
            topLineView.isHidden = true
            topImaginaryLineView.isHidden = false
        case .NO:
            topLineView.isHidden = true
            topImaginaryLineView.isHidden = true
        default:
            topLineView.isHidden = true
            topImaginaryLineView.isHidden = true
        }
        
        addSubviews([lineView, topLineView,imaginaryLineView,topImaginaryLineView])
        lineView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(cellModel.rightSpace)
            make.bottom.equalToSuperview()
            make.height.equalTo(cellModel.bottomLineHeight)
            
            switch cellType {
            case .Switch(let type),.DisclosureIndicator(let type),.NoneAccessoryView(let type),.More(let type):
                switch type {
                case .BothImage(let subType),.LeftImageContent(let subType),.RightImageContent(let subType),.None(let subType):
                    switch subType {
                    case .Name,.NameContent:
                        make.left.equalTo(self.nameTitle!)
                    default:
                        make.left.equalToSuperview().inset(cellModel.leftSpace)
                    }
                case .OnlyLeftImage:
                    make.left.equalTo(self.cellIcon!.snp.right).offset(cellModel.contentLeftSpace)
                default:
                    make.left.equalToSuperview().inset(cellModel.leftSpace)
                }
            case .Error:
                break
            }
        }
        
        imaginaryLineView.snp.makeConstraints { make in
            make.edges.equalTo(self.lineView)
        }
        
        topLineView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(cellModel.rightSpace)
            make.top.equalToSuperview()
            make.height.equalTo(cellModel.topLineHeight)
            make.left.equalTo(self.lineView)
        }
        
        topImaginaryLineView.snp.makeConstraints { make in
            make.edges.equalTo(self.topLineView)
        }
    }
}

@objcMembers
open class PTFusionCell: PTBaseNormalCell {
    public static let ID = "PTFusionCell"
    
    public var switchValueChangeBlock: PTCellSwitchBlock?
    public var moreActionBlock: PTSectionMoreBlock?
    open var switchValue: Bool? {
        didSet {
            if let valueSwitch = dataContent.valueSwitch {
                if let ptSwitch = valueSwitch as? PTSwitch {
                    ptSwitch.isOn = switchValue!
                } else if let iosSwitch = valueSwitch as? UISwitch {
                    iosSwitch.isOn = switchValue!
                }
            }
        }
    }

    open var cellModel: PTFusionCellModel? {
        didSet {
            dataContent.cellModel = cellModel
        }
    }
    
    //MARK: 需要在cellModel配置了之後設置
    open var hideTopLine: Bool! = true {
        didSet {
            if cellModel == nil {
                dataContent.topLineView.isHidden = true
                dataContent.topImaginaryLineView.isHidden = true
            } else {
                switch cellModel!.haveTopLine {
                case .Normal:
                    dataContent.topLineView.isHidden = hideTopLine
                    dataContent.topImaginaryLineView.isHidden = true
                case .Imaginary:
                    dataContent.topLineView.isHidden = true
                    dataContent.topImaginaryLineView.isHidden = hideTopLine
                case .NO:
                    dataContent.topLineView.isHidden = true
                    dataContent.topImaginaryLineView.isHidden = true
                default:
                    dataContent.topLineView.isHidden = true
                    dataContent.topImaginaryLineView.isHidden = true
                }
            }
        }
    }
    
    open var hideBottomLine: Bool! = true {
        didSet {
            if cellModel == nil {
                dataContent.lineView.isHidden = true
                dataContent.imaginaryLineView.isHidden = true
            } else {
                switch cellModel!.haveLine {
                case .Normal:
                    dataContent.lineView.isHidden = hideBottomLine
                    dataContent.imaginaryLineView.isHidden = true
                case .Imaginary:
                    dataContent.lineView.isHidden = true
                    dataContent.imaginaryLineView.isHidden = hideBottomLine
                case .NO:
                    dataContent.lineView.isHidden = true
                    dataContent.imaginaryLineView.isHidden = true
                default:
                    dataContent.lineView.isHidden = true
                    dataContent.imaginaryLineView.isHidden = true
                }
            }
        }
    }
    
    fileprivate lazy var dataContent: PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.switchValueChangeBlock = { name,view in
            self.switchValueChangeBlock?(name,view)
        }
        if let sectionModel = view.sectionMore {
            sectionModel.addActionHandlers { sender in
                self.moreActionBlock?(self.cellModel!.name,sender)
            }
        }
        return view
    }()
    
    public override init(frame:CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(dataContent)
        dataContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
        
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objcMembers
open class PTFusionSwipeCell: PTBaseSwipeCell {
    public static let ID = "PTFusionSwipeCell"
    
    public var switchValueChangeBlock: PTCellSwitchBlock?
    public var moreActionBlock: PTSectionMoreBlock?
    open var switchValue: Bool? {
        didSet {
            if let valueSwitch = dataContent.valueSwitch {
                if let ptSwitch = valueSwitch as? PTSwitch {
                    ptSwitch.isOn = switchValue!
                } else if let iosSwitch = valueSwitch as? UISwitch {
                    iosSwitch.isOn = switchValue!
                }
            }
        }
    }

    open var cellModel: PTFusionCellModel? {
        didSet {
            self.dataContent.cellModel = self.cellModel
        }
    }
    
    open var hideTopLine: Bool! {
        didSet {
            if cellModel == nil {
                dataContent.topLineView.isHidden = true
                dataContent.topImaginaryLineView.isHidden = true
            } else {
                switch cellModel!.haveLine {
                case .Normal:
                    dataContent.topLineView.isHidden = hideTopLine
                    dataContent.topImaginaryLineView.isHidden = true
                case .Imaginary:
                    dataContent.topLineView.isHidden = true
                    dataContent.topImaginaryLineView.isHidden = hideTopLine
                case .NO:
                    dataContent.topLineView.isHidden = true
                    dataContent.topImaginaryLineView.isHidden = true
                default:
                    dataContent.topLineView.isHidden = true
                    dataContent.topImaginaryLineView.isHidden = true
                }
            }
        }
    }
    
    open var hideBottomLine: Bool! {
        didSet {
            if cellModel == nil {
                dataContent.lineView.isHidden = true
                dataContent.imaginaryLineView.isHidden = true
            } else {
                switch cellModel!.haveLine {
                case .Normal:
                    dataContent.lineView.isHidden = hideBottomLine
                    dataContent.imaginaryLineView.isHidden = true
                case .Imaginary:
                    dataContent.lineView.isHidden = true
                    dataContent.imaginaryLineView.isHidden = hideBottomLine
                case .NO:
                    dataContent.lineView.isHidden = true
                    dataContent.imaginaryLineView.isHidden = true
                default:
                    dataContent.lineView.isHidden = true
                    dataContent.imaginaryLineView.isHidden = true
                }
            }
        }
    }

    fileprivate lazy var dataContent: PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.switchValueChangeBlock = { name,view in
            self.switchValueChangeBlock?(name,view)
        }
        if let sectionModel = view.sectionMore {
            sectionModel.addActionHandlers { sender in
                self.moreActionBlock?(self.cellModel!.name,sender)
            }
        }
        return view
    }()
    
    public override init(frame:CGRect) {
        super.init(frame: frame)
        
        contentContainer.addSubview(dataContent)
        dataContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
        
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension UICollectionViewCell {
    func cellContentViewCorners(radius:CGFloat = 0,
                                borderWidth:CGFloat = 0,
                                borderColor:UIColor = UIColor.clear,
                                capsule:Bool = false) {
        PTGCDManager.gcdMain {
            if #available(iOS 26.0, *) {
                let topLeft:UICornerRadius = UICornerRadius(floatLiteral: radius)
                let topRight:UICornerRadius = UICornerRadius(floatLiteral: radius)
                let bottomLeft:UICornerRadius = UICornerRadius(floatLiteral: radius)
                let bottomRight:UICornerRadius = UICornerRadius(floatLiteral: radius)
                self.contentView.corner26(tL: topLeft, tR: topRight, bL: bottomLeft, bR: bottomRight, capsule: capsule)
                self.corner26(tL: topLeft, tR: topRight, bL: bottomLeft, bR: bottomRight, capsule: capsule)
            } else {
                self.contentView.layer.cornerRadius = radius
                self.layer.cornerRadius = radius
            }
            self.contentView.layer.masksToBounds = true
            self.contentView.layer.borderWidth = borderWidth
            self.contentView.layer.borderColor = borderColor.cgColor
            
            self.layer.masksToBounds = true
            self.layer.borderWidth = borderWidth
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    func cellContentViewCornerRectCorners(cornerRadii:CGFloat = 5,
                                          borderWidth:CGFloat = 0,
                                          borderColor:UIColor = UIColor.clear,
                                          corner:UIRectCorner = .allCorners,
                                          capsule:Bool = false) {
        PTGCDManager.gcdMain {
            if #available(iOS 26.0, *) {
                var topLeft:UICornerRadius?
                var topRight:UICornerRadius?
                var bottomLeft:UICornerRadius?
                var bottomRight:UICornerRadius?
                if corner.contains(.topLeft) {
                    topLeft = UICornerRadius(floatLiteral: cornerRadii)
                }
                if corner.contains(.topRight) {
                    topRight = UICornerRadius(floatLiteral: cornerRadii)
                }
                if corner.contains(.bottomLeft) {
                    bottomLeft = UICornerRadius(floatLiteral: cornerRadii)
                }
                if corner.contains(.bottomRight) {
                    bottomRight = UICornerRadius(floatLiteral: cornerRadii)
                }
                if corner == .allCorners {
                    topLeft = UICornerRadius(floatLiteral: cornerRadii)
                    topRight = UICornerRadius(floatLiteral: cornerRadii)
                    bottomLeft = UICornerRadius(floatLiteral: cornerRadii)
                    bottomRight = UICornerRadius(floatLiteral: cornerRadii)
                }
                self.contentView.corner26(tL: topLeft, tR: topRight, bL: bottomLeft, bR: bottomRight, capsule: capsule)
            } else {
                let maskPath = UIBezierPath(roundedRect: self.contentView.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: cornerRadii, height: cornerRadii))
                let maskLayer = CAShapeLayer()
                maskLayer.frame = self.contentView.bounds
                maskLayer.path = maskPath.cgPath
                self.contentView.layer.mask = maskLayer
            }
            self.contentView.layer.masksToBounds = true
            self.contentView.layer.borderWidth = borderWidth
            self.contentView.layer.borderColor = borderColor.cgColor
        }
    }
}
