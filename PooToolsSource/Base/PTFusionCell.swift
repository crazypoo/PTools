//
//  PTFusionCell.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public typealias PTCellSwitchBlock = (_ rowText:String,_ sender:UISwitch)->Void

fileprivate extension UIView
{
    /// 绘制简单横线
    func drawLine() -> UIView {
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor.init(hexString: "#E8E8E8")
        return lineView
    }
}

@objcMembers
public class PTFusionCellContent:UIView
{
    public static let ContentIconHeight:CGFloat = CGFloat.ScaleW(w: 64)
    public var switchValueChangeBLock:PTCellSwitchBlock?

    enum MNCellAccessoryView
    {
        case Switch
        case DisclosureIndicator
        case None
    }

    public var cellModel:PTFunctionCellModel?
    {
        didSet
        {
            var cellType:MNCellAccessoryView = .None
            if self.cellModel!.haveDisclosureIndicator && !self.cellModel!.haveSwitch
            {
                self.valueSwitch.isHidden = true
                self.accessV.isHidden = false
                self.accessV.image = UIImage.init(named: cellModel!.disclosureIndicatorImageName)
                self.accessV.snp.makeConstraints { make in
                    make.width.height.equalTo(14)
                    make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    make.centerY.equalToSuperview()
                }
                cellType = .DisclosureIndicator
            }
            else if !self.cellModel!.haveDisclosureIndicator && self.cellModel!.haveSwitch
            {
                self.accessV.isHidden = true
                self.valueSwitch.isHidden = false
                self.valueSwitch.onTintColor = self.cellModel!.switchTinColor
                self.valueSwitch.snp.makeConstraints { (make) in
                    make.width.equalTo(51)
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                }
                self.valueSwitch.addTarget(self, action: #selector(onSwitch(sender:)), for: .valueChanged)
                cellType = .Switch
            }
            else
            {
                self.accessV.isHidden = true
                self.valueSwitch.isHidden = true
                cellType = .None
            }
            
            if !self.cellModel!.imageName.stringIsEmpty() && !self.cellModel!.name.stringIsEmpty() && (self.cellModel!.content.stringIsEmpty() && self.cellModel!.contentAttr == nil) && !self.cellModel!.showContentIcon
            {
                if self.cellModel!.imageName.isURL()
                {
                    self.cellIcon.pt_SDWebImage(imageString: self.cellModel!.imageName)
                }
                else
                {
                    self.cellIcon.image = UIImage.init(named: self.cellModel!.imageName)
                }
                self.cellIcon.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                    make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                    make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                    make.width.equalTo(self.cellIcon.snp.height)
                }
                
                self.nameTitle.text = self.cellModel!.name
                self.nameTitle.textColor = self.cellModel!.nameColor
                self.nameTitle.font = self.cellModel!.cellFont
                self.nameTitle.snp.makeConstraints { make in
                    make.left.equalTo(self.cellIcon.snp.right).offset(self.cellModel!.leftSpace)
                    make.centerY.equalTo(self.cellIcon)
                    switch cellType {
                    case .Switch:
                        make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                    case .DisclosureIndicator:
                        make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                    case .None:
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    }
                }
                self.contentLabel.isHidden = true
                self.cellIcon.isHidden = false
                self.nameTitle.isHidden = false
                self.cellContentIcon.isHidden = true
            }
            else if !self.cellModel!.imageName.stringIsEmpty() && !self.cellModel!.name.stringIsEmpty() && (!self.cellModel!.content.stringIsEmpty() || self.cellModel!.contentAttr != nil) && !self.cellModel!.showContentIcon
            {
                if self.cellModel!.imageName.isURL()
                {
                    self.cellIcon.pt_SDWebImage(imageString: self.cellModel!.imageName)
                }
                else
                {
                    self.cellIcon.image = UIImage.init(named: self.cellModel!.imageName)
                }

                self.cellIcon.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                    make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                    make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                    make.width.equalTo(self.cellIcon.snp.height)
                }
                
                self.nameTitle.text = self.cellModel!.name
                self.nameTitle.textColor = self.cellModel!.nameColor
                self.nameTitle.snp.remakeConstraints { make in
                    make.left.equalTo(self.cellIcon.snp.right).offset(self.cellModel!.leftSpace)
                    make.centerY.equalTo(self.cellIcon)
                    make.width.equalTo(PTUtils.sizeFor(string: self.nameTitle.text!, font: self.nameTitle.font, height: 44, width: CGFloat(MAXFLOAT)).width + 10)
                }

                if self.cellModel!.contentAttr != nil
                {
                    self.contentLabel.attributedText = self.cellModel!.contentAttr
                }
                else
                {
                    self.contentLabel.text = self.cellModel!.content
                    self.contentLabel.textColor = self.cellModel!.contentTextColor
                }
                self.contentLabel.snp.remakeConstraints { make in
                    make.left.equalTo(self.nameTitle.snp.right).offset(5)
                    make.centerY.equalTo(self.cellIcon)
                    switch cellType {
                    case .Switch:
                        make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                    case .DisclosureIndicator:
                        make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                    case .None:
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    }
                }
                
                self.contentLabel.isHidden = false
                self.cellIcon.isHidden = false
                self.nameTitle.isHidden = false
                self.cellContentIcon.isHidden = true
            }
            else if self.cellModel!.imageName.stringIsEmpty() && !self.cellModel!.name.stringIsEmpty() && (!self.cellModel!.content.stringIsEmpty() || self.cellModel!.contentAttr != nil) && !self.cellModel!.showContentIcon
            {
                self.contentLabel.isHidden = false
                self.cellIcon.isHidden = true
                self.nameTitle.isHidden = false
                self.cellContentIcon.isHidden = true

                self.nameTitle.text = self.cellModel!.name
                self.nameTitle.textColor = self.cellModel!.nameColor
                self.nameTitle.font = self.cellModel!.cellFont
                self.nameTitle.snp.remakeConstraints { make in
                    make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                    make.top.bottom.equalToSuperview()
                    make.width.equalTo(PTUtils.sizeFor(string: self.nameTitle.text!, font: self.nameTitle.font, height: 44, width: CGFloat(MAXFLOAT)).width + 10)
                }

                if self.cellModel!.contentAttr != nil
                {
                    self.contentLabel.attributedText = self.cellModel!.contentAttr
                }
                else
                {
                    self.contentLabel.text = self.cellModel!.content
                    self.contentLabel.textColor = self.cellModel!.contentTextColor
                }
                self.contentLabel.snp.remakeConstraints { make in
                    make.left.equalTo(self.nameTitle.snp.right).offset(5)
                    make.top.bottom.equalToSuperview()
                    switch cellType {
                    case .Switch:
                        make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                    case .DisclosureIndicator:
                        make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                    case .None:
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    }
                }
            }
            else if self.cellModel!.imageName.stringIsEmpty() && !self.cellModel!.name.stringIsEmpty() && (self.cellModel!.content.stringIsEmpty() && self.cellModel!.contentAttr == nil) && !self.cellModel!.showContentIcon
            {
                self.contentLabel.isHidden = true
                self.cellIcon.isHidden = true
                self.nameTitle.isHidden = false
                self.cellContentIcon.isHidden = true

                self.nameTitle.text = self.cellModel!.name
                self.nameTitle.textColor = self.cellModel!.nameColor
                self.nameTitle.snp.remakeConstraints { make in
                    make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                    make.top.bottom.equalToSuperview()
                    switch cellType {
                    case .Switch:
                        make.right.lessThanOrEqualTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                    case .DisclosureIndicator:
                        make.right.lessThanOrEqualTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                    case .None:
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    }
                }
            }
            else if (self.cellModel!.content.stringIsEmpty() && self.cellModel!.contentAttr == nil) && self.cellModel!.showContentIcon
            {
                self.contentLabel.isHidden = true
                self.cellContentIcon.isHidden = false
                
                self.cellContentIcon.pt_SDWebImage(imageString: self.cellModel!.contentIcon)
                self.cellContentIcon.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview().inset(CGFloat.ScaleW(w: 5))
                    switch cellType {
                    case .Switch:
                        make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                    case .DisclosureIndicator:
                        make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                    case .None:
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    }
                    make.width.equalTo(self.cellContentIcon.snp.height)
                }
                self.cellContentIcon.viewCorner(radius: (PTFusionCellContent.ContentIconHeight - CGFloat.ScaleW(w: 5) * 2) / 2)
                
                if self.cellModel!.imageName.stringIsEmpty() && !self.cellModel!.name.stringIsEmpty()
                {
                    self.cellIcon.isHidden = true
                    self.nameTitle.isHidden = false
                    
                    self.nameTitle.text = self.cellModel!.name
                    self.nameTitle.textColor = self.cellModel!.nameColor
                    self.nameTitle.snp.remakeConstraints { make in
                        make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                        make.top.bottom.equalToSuperview()
                        make.right.equalTo(self.cellContentIcon.snp.left).offset(-self.cellModel!.rightSpace)
                    }
                }
                else if !self.cellModel!.imageName.stringIsEmpty() && self.cellModel!.name.stringIsEmpty()
                {
                    self.nameTitle.isHidden = true
                    self.cellIcon.isHidden = false
                    
                    if self.cellModel!.imageName.isURL()
                    {
                        self.cellIcon.pt_SDWebImage(imageString: self.cellModel!.imageName)
                    }
                    else
                    {
                        self.cellIcon.image = UIImage.init(named: self.cellModel!.imageName)
                    }

                    self.cellIcon.snp.makeConstraints { make in
                        make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                        make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                        make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                        make.width.equalTo(self.cellIcon.snp.height)
                    }
                }
                else if !self.cellModel!.imageName.stringIsEmpty() && !self.cellModel!.name.stringIsEmpty()
                {
                    self.nameTitle.isHidden = false
                    self.cellIcon.isHidden = false
                    
                    if self.cellModel!.imageName.isURL()
                    {
                        self.cellIcon.pt_SDWebImage(imageString: self.cellModel!.imageName)
                    }
                    else
                    {
                        self.cellIcon.image = UIImage.init(named: self.cellModel!.imageName)
                    }

                    self.cellIcon.snp.makeConstraints { make in
                        make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                        make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                        make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                        make.width.equalTo(self.cellIcon.snp.height)
                    }
                    
                    self.nameTitle.text = self.cellModel!.name
                    self.nameTitle.textColor = self.cellModel!.nameColor
                    self.nameTitle.snp.remakeConstraints { make in
                        make.left.equalTo(self.cellIcon.snp.right).offset(self.cellModel!.leftSpace)
                        make.centerY.equalTo(self.cellIcon)
                        make.right.equalTo(self.cellContentIcon.snp.left).offset(-self.cellModel!.rightSpace)
                    }
                }
            }
            
            self.lineView.isHidden = !self.cellModel!.haveLine
            self.nameTitle.font = self.cellModel!.cellFont

            if self.cellModel!.conrner != []
            {
                PTUtils.gcdMain {
                    self.viewCornerRectCorner(cornerRadii: self.cellModel!.cellCorner, corner: self.cellModel!.conrner)
                }
            }
            else
            {
                PTUtils.gcdMain {
                    self.viewCornerRectCorner(cornerRadii: 0, corner: [.allCorners])
                }
            }
        }
    }
        
    fileprivate lazy var nameTitle:UILabel = {
        let view = UILabel()
        view.textAlignment = .left
        view.numberOfLines = 0
        return view
    }()
        
    lazy var accessV:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    public lazy var valueSwitch : UISwitch = {
        let switchV = UISwitch.init()
        return switchV
    }()
    
    fileprivate lazy var contentLabel : UILabel = {
        let view = UILabel()
        view.textAlignment = .right
        view.font = .appfont(size: 16)
        return view
    }()
    
    fileprivate lazy var cellIcon:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    public lazy var topLineView = self.drawLine()
    public lazy var lineView = self.drawLine()
    
    fileprivate lazy var cellContentIcon:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.isHidden = true
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.topLineView.isHidden = true
        self.lineView.isHidden = true
        self.accessV.isHidden = true
        self.nameTitle.isHidden = true
        self.valueSwitch.isHidden = true
        self.contentLabel.isHidden = true
        self.cellIcon.isHidden = true
        self.cellContentIcon.isHidden = true
        self.addSubviews([self.lineView,self.accessV,self.nameTitle,self.valueSwitch,self.contentLabel,self.cellContentIcon,self.cellIcon,self.topLineView])

        self.lineView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(self.cellModel?.rightSpace ?? 10)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.left.equalTo(self.nameTitle)
        }
        
        self.topLineView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(self.cellModel?.rightSpace ?? 10)
            make.top.equalToSuperview()
            make.height.equalTo(1)
            make.left.equalTo(self.nameTitle)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onSwitch(sender:UISwitch)
    {
        if switchValueChangeBLock != nil
        {
            switchValueChangeBLock!(self.nameTitle.text!,sender)
        }
    }
}

@objcMembers
open class PTFusionCell: PTBaseNormalCell {
    public static let ID = "PTFusionCell"
                
    open var switchValueChangeBLock:PTCellSwitchBlock?

    open var cellModel:PTFunctionCellModel?
    {
        didSet
        {
            self.dataContent.cellModel = self.cellModel
        }
    }
        
    open lazy var dataContent:PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.switchValueChangeBLock = self.switchValueChangeBLock
        return view
    }()
    
    override init(frame:CGRect)
    {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.dataContent)
        self.dataContent.snp.makeConstraints { make in
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
                
    open var switchValueChangeBLock:PTCellSwitchBlock?

    open var cellModel:PTFunctionCellModel?
    {
        didSet
        {
            self.dataContent.cellModel = self.cellModel
        }
    }
        
    open lazy var dataContent:PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.switchValueChangeBLock = self.switchValueChangeBLock
        return view
    }()
    
    override init(frame:CGRect)
    {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.dataContent)
        self.dataContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

