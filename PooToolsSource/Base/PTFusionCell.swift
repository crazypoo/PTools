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

public typealias PTCellSwitchBlock = (_ rowText:String,_ sender:UISwitch)->Void

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
    public var switchValueChangeBLock:PTCellSwitchBlock?
    
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
        case Error
    }
    
    public var cellModel:PTFusionCellModel? {
        didSet {
            var cellType:PTFusionCellAccessoryView = .NoneAccessoryView(type: .None(type: .None))
            switch cellModel!.accessoryType {
            case .Switch:
                accessV.removeFromSuperview()
                valueSwitch.onTintColor = cellModel!.switchTinColor
                addSubview(valueSwitch)
                valueSwitch.snp.makeConstraints { (make) in
                    make.width.equalTo(51)
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                }
                valueSwitch.addSwitchAction { sender in
                    if self.switchValueChangeBLock != nil {
                        self.switchValueChangeBLock!(self.nameTitle.text!,sender)
                    }
                }
            case .DisclosureIndicator:
                valueSwitch.removeFromSuperview()
                
                if !NSObject.checkObject(cellModel!.disclosureIndicatorImage as? NSObject) {
                    if cellModel!.disclosureIndicatorImage is String {
                        let link = cellModel!.disclosureIndicatorImage as! String
                        if FileManager.pt.judgeFileOrFolderExists(filePath: link) {
                            accessV.image = UIImage(contentsOfFile: link)
                        } else {
                            if link.isURL() {
                                accessV.pt_SDWebImage(imageString: link)
                            } else if link.isSingleEmoji {
                                accessV.image = link.emojiToImage()
                            } else {
                                accessV.image = UIImage(named: link)
                            }
                        }
                    } else if cellModel!.disclosureIndicatorImage is UIImage {
                        accessV.image = (cellModel!.disclosureIndicatorImage as! UIImage)
                    } else if cellModel!.disclosureIndicatorImage is Data {
                        accessV.image = UIImage(data: (cellModel!.disclosureIndicatorImage as! Data))
                    }
                } else {
                    accessV.image = UIColor.random.createImageWithColor()
                }
                
                addSubview(accessV)
                accessV.snp.makeConstraints { make in
                    make.width.height.equalTo(14)
                    make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    make.centerY.equalToSuperview()
                }
            case .NoneAccessoryView:
                accessV.removeFromSuperview()
                valueSwitch.removeFromSuperview()
            }
            
            cellType = accessoryViewType(type: cellModel!.accessoryType)
            
            switch cellType {
            case .Switch(type: .OnlyLeftImage),
                    .Switch(type: .BothImage),
                    .Switch(type: .LeftImageContent),
                    .DisclosureIndicator(type: .OnlyLeftImage),
                    .DisclosureIndicator(type: .BothImage),
                    .DisclosureIndicator(type: .LeftImageContent),
                    .NoneAccessoryView(type: .OnlyLeftImage),
                    .NoneAccessoryView(type: .BothImage),
                    .NoneAccessoryView(type: .LeftImageContent):
                addSubview(cellIcon)
                cellIcon.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                    make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                    make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                    make.width.equalTo(self.cellIcon.snp.height)
                }
                
                if cellModel!.leftImage is String {
                    let link = cellModel!.leftImage as! String
                    if FileManager.pt.judgeFileOrFolderExists(filePath: link) {
                        cellIcon.image = UIImage(contentsOfFile: link)
                    } else {
                        if link.isURL() {
                            cellIcon.pt_SDWebImage(imageString: link)
                        } else if link.isSingleEmoji {
                            cellIcon.image = link.emojiToImage()
                        } else {
                            cellIcon.image = UIImage(named: link)
                        }
                    }
                } else if cellModel!.leftImage is UIImage {
                    cellIcon.image = (cellModel!.leftImage as! UIImage)
                } else if cellModel!.leftImage is Data {
                    cellIcon.image = UIImage(data: (cellModel!.leftImage as! Data))
                }
                
            default:
                cellIcon.removeFromSuperview()
            }
            
            switch cellType {
            case .Switch(type: .OnlyRightImage),
                    .Switch(type: .BothImage),
                    .Switch(type: .RightImageContent),
                    .DisclosureIndicator(type: .OnlyRightImage),
                    .DisclosureIndicator(type: .BothImage),
                    .DisclosureIndicator(type: .RightImageContent),
                    .NoneAccessoryView(type: .OnlyRightImage),
                    .NoneAccessoryView(type: .BothImage),
                    .NoneAccessoryView(type: .RightImageContent):
                
                if cellModel!.contentIcon is String {
                    let link = cellModel!.contentIcon as! String
                    if FileManager.pt.judgeFileOrFolderExists(filePath: link) {
                        cellContentIcon.image = UIImage(contentsOfFile: link)
                    } else {
                        if link.isURL() {
                            cellIcon.pt_SDWebImage(imageString: link)
                        } else if link.isSingleEmoji {
                            cellIcon.image = link.emojiToImage()
                        } else {
                            cellIcon.image = UIImage(named: link)
                        }
                    }
                } else if cellModel!.contentIcon is UIImage {
                    cellContentIcon.image = (cellModel!.contentIcon as! UIImage)
                } else if cellModel!.contentIcon is Data {
                    cellContentIcon.image = UIImage(data: (cellModel!.contentIcon as! Data))
                }
                
                addSubview(cellContentIcon)
                cellContentIcon.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                    make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                    switch cellType {
                    case .Switch(type: .OnlyRightImage),
                            .Switch(type: .BothImage),
                            .Switch(type: .RightImageContent):
                        make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                    case .DisclosureIndicator(type: .OnlyRightImage),
                            .DisclosureIndicator(type: .BothImage),
                            .DisclosureIndicator(type: .RightImageContent):
                        make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                    case .NoneAccessoryView(type: .OnlyRightImage),
                            .NoneAccessoryView(type: .BothImage),
                            .NoneAccessoryView(type: .RightImageContent):
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    default:
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    }
                    make.width.equalTo(self.cellContentIcon.snp.height)
                }
                
            default:
                cellContentIcon.removeFromSuperview()
            }
            
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
                    .NoneAccessoryView(type: .BothImage(type: .NameContent)):
                
                if  cellModel!.nameAttr != nil {
                    nameTitle.attributed.text = cellModel!.nameAttr
                } else {
                    var atts:ASAttributedString = ASAttributedString(string: "")
                    if !cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() {
                        let nameAtts:ASAttributedString =  ASAttributedString("\(cellModel!.name)",.paragraph(.alignment(.left)),.font(cellModel!.cellFont),.foreground(cellModel!.nameColor))
                        atts = nameAtts
                    } else if cellModel!.name.stringIsEmpty() && !cellModel!.desc.stringIsEmpty() {
                        let descAtts:ASAttributedString =  ASAttributedString("\(cellModel!.desc)",.paragraph(.alignment(.left)),.font(cellModel!.cellDescFont),.foreground(cellModel!.descColor))
                        atts = descAtts
                    } else if !cellModel!.name.stringIsEmpty() && !cellModel!.desc.stringIsEmpty() {
                        let nameAtts:ASAttributedString =  ASAttributedString("\(cellModel!.name)",.paragraph(.alignment(.left)),.font(cellModel!.cellFont),.foreground(cellModel!.nameColor))
                        let descAtts:ASAttributedString =  ASAttributedString("\n\(cellModel!.desc)",.paragraph(.alignment(.left)),.font(cellModel!.cellDescFont),.foreground(cellModel!.descColor))
                        atts = nameAtts + descAtts
                    }
                    nameTitle.attributed.text = atts
                }
                
                addSubview(nameTitle)
                nameTitle.snp.makeConstraints { make in
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
                            .NoneAccessoryView(type: .RightImageContent(type: .NameContent)):
                        make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                        make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                        make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
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
                            .NoneAccessoryView(type: .BothImage(type: .NameContent)):
                        make.left.equalTo(self.cellIcon.snp.right).offset(self.cellModel!.leftSpace)
                        make.top.bottom.equalTo(self.cellIcon)
                    default:break
                    }
                    
                    switch cellType {
                    case .Switch(type: .BothImage(type: .Name)),
                            .DisclosureIndicator(type: .BothImage(type: .Name)),
                            .NoneAccessoryView(type: .BothImage(type: .Name)):
                        make.right.equalTo(self.cellContentIcon.snp.left).offset(-self.cellModel!.rightSpace)
                    case .Switch(type: .None(type: .Name)):
                        make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                    case .DisclosureIndicator(type: .None(type: .Name)):
                        make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                    case .Switch(type: .BothImage(type: .NameContent)),
                            .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                            .Switch(type: .None(type: .Content)),
                            .DisclosureIndicator(type: .None(type: .Content)):
                        make.right.equalTo(self.snp.centerX)
                    default:
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    }
                }
            default:
                nameTitle.removeFromSuperview()
            }
            
            switch cellType {
            case .Switch(type: .BothImage(type: .NameContent)),
                    .Switch(type: .BothImage(type: .Content)),
                    .Switch(type: .LeftImageContent(type: .NameContent)),
                    .Switch(type: .LeftImageContent(type: .Content)),
                    .Switch(type: .None(type: .Content)),
                    .Switch(type: .None(type: .NameContent)),
                    .Switch(type: .RightImageContent(type: .NameContent)),
                    .Switch(type: .RightImageContent(type: .Content)),
                    .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                    .DisclosureIndicator(type: .BothImage(type: .Content)),
                    .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                    .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                    .DisclosureIndicator(type: .None(type: .Content)),
                    .DisclosureIndicator(type: .None(type: .NameContent)),
                    .DisclosureIndicator(type: .RightImageContent(type: .Content)),
                    .DisclosureIndicator(type: .RightImageContent(type: .NameContent)),
                    .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                    .NoneAccessoryView(type: .BothImage(type: .Content)),
                    .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                    .NoneAccessoryView(type: .LeftImageContent(type: .Content)),
                    .NoneAccessoryView(type: .RightImageContent(type: .Content)),
                    .NoneAccessoryView(type: .RightImageContent(type: .NameContent)),
                    .NoneAccessoryView(type: .None(type: .Content)),
                    .NoneAccessoryView(type: .None(type: .NameContent)):
                if cellModel!.contentAttr != nil && cellModel!.content.stringIsEmpty() {
                    contentLabel.attributed.text = cellModel!.contentAttr
                } else if cellModel!.contentAttr == nil && !cellModel!.content.stringIsEmpty() {
                    let contentAtts:ASAttributedString =  ASAttributedString("\(cellModel!.content)",.paragraph(.alignment(.right)),.font(cellModel!.contentFont),.foreground(cellModel!.contentTextColor))
                    contentLabel.attributed.text = contentAtts
                }
                addSubview(contentLabel)
                contentLabel.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    
                    switch cellType {
                    case .Switch(type: .None(type: .Content)),
                            .DisclosureIndicator(type: .None(type: .Content)):
                        make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                    case .Switch(type: .LeftImageContent(type: .Content)),
                            .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                            .Switch(type: .BothImage(type: .Content)),
                            .DisclosureIndicator(type: .BothImage(type: .Content)):
                        make.left.equalTo(self.cellIcon.snp.right).offset(self.cellModel!.leftSpace)
                    default:
                        make.left.equalTo(self.snp.centerX).offset(10)
                    }
                    
                    switch cellType {
                    case .Switch(type: .None(type: .Content)),
                            .Switch(type: .LeftImageContent(type: .Content)),
                            .Switch(type: .LeftImageContent(type: .NameContent)),
                            .Switch(type: .None(type: .NameContent)):
                        make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                    case .DisclosureIndicator(type: .None(type: .Content)),
                            .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                            .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                            .DisclosureIndicator(type: .None(type: .NameContent)):
                        make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                    case .NoneAccessoryView(type: .BothImage(type: .Content)),
                            .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                            .NoneAccessoryView(type: .LeftImageContent(type: .Content)),
                            .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                            .NoneAccessoryView(type: .None(type: .Content)),
                            .NoneAccessoryView(type: .None(type: .NameContent)),
                            .NoneAccessoryView(type: .RightImageContent(type: .Content)),
                            .NoneAccessoryView(type: .RightImageContent(type: .NameContent)):
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    default:
                        make.right.equalTo(self.cellContentIcon.snp.left).offset(-self.cellModel!.rightSpace)
                    }
                }
            default:
                contentLabel.removeFromSuperview()
            }
            
            lineView.isHidden = !cellModel!.haveLine
            topLineView.isHidden = !cellModel!.haveTopLine
            
            addSubviews([lineView, topLineView])
            lineView.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                make.bottom.equalToSuperview()
                make.height.equalTo(1)
                switch cellType {
                case .Switch(type: .BothImage(type: .Name)),
                        .Switch(type: .BothImage(type: .NameContent)),
                        .Switch(type: .None(type: .Name)),
                        .Switch(type: .None(type: .NameContent)),
                        .Switch(type: .LeftImageContent(type: .Name)),
                        .Switch(type: .LeftImageContent(type: .NameContent)),
                        .Switch(type: .RightImageContent(type: .Name)),
                        .Switch(type: .RightImageContent(type: .NameContent)),
                        .DisclosureIndicator(type: .BothImage(type: .Name)),
                        .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                        .DisclosureIndicator(type: .None(type: .Name)),
                        .DisclosureIndicator(type: .None(type: .NameContent)),
                        .DisclosureIndicator(type: .LeftImageContent(type: .Name)),
                        .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                        .DisclosureIndicator(type: .RightImageContent(type: .Name)),
                        .DisclosureIndicator(type: .RightImageContent(type: .NameContent)),
                        .NoneAccessoryView(type: .BothImage(type: .Name)),
                        .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                        .NoneAccessoryView(type: .LeftImageContent(type: .Name)),
                        .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                        .NoneAccessoryView(type: .None(type: .Name)),
                        .NoneAccessoryView(type: .None(type: .NameContent)),
                        .NoneAccessoryView(type: .RightImageContent(type: .Name)),
                        .NoneAccessoryView(type: .RightImageContent(type: .NameContent)):
                    make.left.equalTo(self.nameTitle)
                case .Switch(type: .OnlyLeftImage),.DisclosureIndicator(type: .OnlyLeftImage):
                    make.left.equalTo(self.cellIcon.snp.right).offset(self.cellModel!.leftSpace)
                default:
                    make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                }
            }
            
            topLineView.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                make.top.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalTo(self.lineView)
            }
            
            if cellModel!.conrner != [] {
                PTGCDManager.gcdMain {
                    self.viewCornerRectCorner(cornerRadii: self.cellModel!.cellCorner, corner: self.cellModel!.conrner)
                }
            } else {
                PTGCDManager.gcdMain {
                    self.viewCornerRectCorner(cornerRadii: 0, corner: [.allCorners])
                }
            }
        }
    }
    
    fileprivate lazy var nameTitle:UILabel = {
        let view = UILabel()
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
        view.numberOfLines = 0
        return view
    }()
    
    fileprivate lazy var cellIcon:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    public lazy var topLineView = drawLine()
    public lazy var lineView = drawLine()
    
    fileprivate lazy var cellContentIcon:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func accessoryViewType(type:PTFusionShowAccessoryType) -> PTFusionCellAccessoryView {
        var cellType:PTFusionCellAccessoryView
        if (!NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
            (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
            (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
            NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .LeftImageContent(type: .Name))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .LeftImageContent(type: .Name))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .LeftImageContent(type: .Name))
            }
        } else if (!NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                   NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .LeftImageContent(type: .NameContent))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .LeftImageContent(type: .NameContent))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .LeftImageContent(type: .NameContent))
            }
        } else if (!NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                   !NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .BothImage(type: .Name))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .BothImage(type: .Name))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .BothImage(type: .Name))
            }
        } else if !NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                    !NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .BothImage(type: .Content))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .BothImage(type: .Content))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .BothImage(type: .Content))
            }
        } else if (!NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                   !NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .BothImage(type: .NameContent))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .BothImage(type: .NameContent))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .BothImage(type: .NameContent))
            }
        } else if !NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                    NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .LeftImageContent(type: .Content))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .LeftImageContent(type: .Content))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .LeftImageContent(type: .Content))
            }
        } else if !NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                    NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .OnlyLeftImage)
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .OnlyLeftImage)
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .OnlyLeftImage)
            }
        } else if NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                    !NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .OnlyRightImage)
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .OnlyRightImage)
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .OnlyRightImage)
            }
        } else if (NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                   !NSObject.checkObject(cellModel!.contentIcon as? NSObject)){
            switch type {
            case .Switch:
                cellType = .Switch(type: .RightImageContent(type: .Name))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .RightImageContent(type: .Name))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .RightImageContent(type: .Name))
            }
        } else if (NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                   !NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .RightImageContent(type: .NameContent))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .RightImageContent(type: .NameContent))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .RightImageContent(type: .NameContent))
            }
        } else if NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                    !NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .RightImageContent(type: .Content))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .RightImageContent(type: .Content))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .RightImageContent(type: .Content))
            }
        } else if (NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                   NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .None(type: .NameContent))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .None(type: .NameContent))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .None(type: .NameContent))
            }
        } else if !NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                    !NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .BothImage(type: .None))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .BothImage(type: .None))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .BothImage(type: .None))
            }
        } else if (NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                   NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .None(type: .Name))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .None(type: .Name))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .None(type: .Name))
            }
        } else if NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                    NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                cellType = .Switch(type: .None(type: .Content))
            case .DisclosureIndicator:
                cellType = .DisclosureIndicator(type: .None(type: .Content))
            case .NoneAccessoryView:
                cellType = .NoneAccessoryView(type: .None(type: .Content))
            }
        } else {
            cellType = .Error
        }
        return cellType
    }
}

@objcMembers
open class PTFusionCell: PTBaseNormalCell {
    public static let ID = "PTFusionCell"
    
    open var switchValueChangeBLock:PTCellSwitchBlock?
    
    open var cellModel:PTFusionCellModel? {
        didSet {
            contentView.addSubview(dataContent)
            dataContent.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            PTGCDManager.gcdAfter(time: 0.1) {
                self.dataContent.cellModel = self.cellModel
            }
        }
    }
    
    open lazy var dataContent:PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.switchValueChangeBLock = self.switchValueChangeBLock
        return view
    }()
    
    override init(frame:CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if POOTOOLS_SWIPECELL
@objcMembers
open class PTFusionSwipeCell: PTBaseSwipeCell {
    public static let ID = "PTFusionSwipeCell"
    
    open var switchValueChangeBLock:PTCellSwitchBlock?
    
    open var cellModel:PTFusionCellModel? {
        didSet {
            self.contentView.addSubview(self.dataContent)
            self.dataContent.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            PTGCDManager.gcdAfter(time: 0.1) {
                self.dataContent.cellModel = self.cellModel
            }
        }
    }
    
    open lazy var dataContent:PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.switchValueChangeBLock = self.switchValueChangeBLock
        return view
    }()
    
    override init(frame:CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
