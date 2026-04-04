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
public typealias PTSectionMoreBlock = (_ rowText:String,_ sender:PTActionLayoutButton) -> Void

fileprivate extension UIView {
    /// 绘制简单横线
    func drawLine() -> UIView {
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor(hexString: "#E8E8E8")
        return lineView
    }
}

public struct PTFusionLayoutConfig {
    let showLeftIcon: Bool
    let showRightIcon: Bool
    let showTitle: Bool
    let showContent: Bool
    let accessory: PTFusionShowAccessoryType
}

public final class PTFusionContentView: UIView {
    
    public var switchValueChangeBlock:PTCellSwitchBlock?

    // MARK: - View Pool（一次创建）
    
    private let leftIcon = UIImageView()
    private let rightIcon = UIImageView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    public lazy var switchView = UIControl()
    public let moreButton = PTActionLayoutButton()
    private let disclosure = UIImageView()
    
    private let leftSpacingView = UIView()
    private let rightSpacingView = UIView()

    public lazy var topLineView: UIView = {
        let view = drawLine()
        view.isHidden = true
        return view
    }()
    public lazy var bottomLineView: UIView = {
        let view = drawLine()
        view.isHidden = true
        return view
    }()
    
    public lazy var topImaginaryLineView: PTImaginaryLineView = {
        let view = PTImaginaryLineView()
        view.isHidden = true
        return view
    }()
    public lazy var bottomImaginaryLineView: PTImaginaryLineView = {
        let view = PTImaginaryLineView()
        view.isHidden = true
        return view
    }()

    // MARK: - Constraints（缓存）
    
    private var rightAnchorConstraint: Constraint?
        
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

private extension PTFusionContentView {
    
    func cellSwitchSet(_ cellModel:PTFusionCellModel,switchType:PTFusionShowAccessoryType.SwitchType) -> UIControl {
        switch switchType {
        case .Framework:
            let view = PTSwitch()
            view.onTintColor = cellModel.switchOnTinColor
            view.thumbColor = cellModel.switchThumbTintColor
            view.switchTintColor = cellModel.switchTintColor
            view.backgroundColor = cellModel.switchBackgroundColor
            return view
        case .System:
            if #available(iOS 26.0, *) {
                let view = UISwitch()
                view.onTintColor = cellModel.switchOnTinColor
                view.thumbTintColor = cellModel.switchThumbTintColor
                view.tintColor = cellModel.switchTintColor
                view.backgroundColor = cellModel.switchBackgroundColor
                return view
            } else {
                let view = PTSwitch()
                view.onTintColor = cellModel.switchOnTinColor
                view.thumbColor = cellModel.switchThumbTintColor
                view.switchTintColor = cellModel.switchTintColor
                view.backgroundColor = cellModel.switchBackgroundColor
                return view
            }
        }
    }
    
    func setupUI() {
        
        addSubviews([leftSpacingView, rightSpacingView, topLineView, bottomLineView,topImaginaryLineView, bottomImaginaryLineView, leftIcon, rightIcon, titleLabel, contentLabel, switchView, moreButton, disclosure])
        
        titleLabel.numberOfLines = 0
        contentLabel.numberOfLines = 0
        
        leftSpacingView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
        
        rightSpacingView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
        
        topLineView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().inset(0)
            make.right.equalToSuperview().inset(0)
            make.height.equalTo(0)
        }
        
        bottomLineView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(0)
            make.right.equalToSuperview().inset(0)
            make.height.equalTo(0)
        }
        
        topImaginaryLineView.snp.makeConstraints { make in
            make.edges.equalTo(self.topLineView)
        }
        
        bottomImaginaryLineView.snp.makeConstraints { make in
            make.edges.equalTo(self.bottomLineView)
        }
        // 左图
        leftIcon.snp.makeConstraints {
            $0.left.equalToSuperview().inset(0)
            $0.top.equalToSuperview().inset(0)
            $0.bottom.equalToSuperview().inset(0)
            $0.width.equalTo(leftIcon.snp.height)
        }
        
        // 右图
        rightIcon.snp.makeConstraints {
            rightAnchorConstraint = $0.right.equalToSuperview().offset(-16).constraint
            $0.top.equalToSuperview().inset(0)
            $0.bottom.equalToSuperview().inset(0)
            $0.width.equalTo(rightIcon.snp.height)
        }
        
        // title
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(leftIcon.snp.right).offset(12)
            $0.centerY.equalToSuperview()
        }
        
        // content
        contentLabel.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.right).offset(8)
            $0.top.bottom.equalToSuperview()
            $0.right.lessThanOrEqualTo(rightIcon.snp.left).offset(-8)
        }
        
        // switch
        switchView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(16)
            $0.size.equalTo(CGSize.SwitchSize)
        }
        
        // more
        moreButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
        }
        
        // disclosure
        disclosure.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
            $0.size.equalTo(16)
        }
    }
}

extension PTFusionContentView {
    
    public func configure(model: PTFusionCellModel) {
        
        let config = makeLayoutConfig(model)
        
        applyLayout(config,cellModel: model)
        applyData(model)
    }
    
    private func makeLayoutConfig(_ model: PTFusionCellModel) -> PTFusionLayoutConfig {
        
        return PTFusionLayoutConfig(
            showLeftIcon: model.leftImage != nil,
            showRightIcon: model.contentIcon != nil,
            showTitle: !model.name.isEmpty || model.nameAttr != nil,
            showContent: !model.content.isEmpty || model.contentAttr != nil,
            accessory: {
                switch model.accessoryType {
                case .Switch: return model.accessoryType
                case .DisclosureIndicator: return .DisclosureIndicator
                case .More: return .More
                default: return .NoneAccessoryView
                }
            }()
        )
    }
    
    private func applyLayout(_ config: PTFusionLayoutConfig,cellModel:PTFusionCellModel) {
        
        // 显示控制（不再 remove）
        leftIcon.isHidden = !config.showLeftIcon
        rightIcon.isHidden = !config.showRightIcon
        titleLabel.isHidden = !config.showTitle
        contentLabel.isHidden = !config.showContent
        switchView.removeFromSuperview()
        var cellType = PTFusionShowAccessoryType.SwitchType.System
        switch cellModel.accessoryType {
        case .Switch(let value):
            cellType = value
        default:
            cellType = .System
        }
        switchView = cellSwitchSet(cellModel, switchType: cellType)
        addSubview(switchView)
        switchView.snp.makeConstraints {
            $0.right.equalToSuperview().inset(cellModel.rightSpace)
            $0.centerY.equalToSuperview()
            switch cellType {
            case .Framework:
                $0.size.equalTo(CGSize(width: cellModel.switchControlWidth, height: CGSize.SwitchSize.height))
            case .System:
                $0.size.equalTo(CGSize.SwitchSize)
            }
        }

        switch config.accessory {
        case .Switch:
            switchView.isHidden = false
            disclosure.isHidden = true
            moreButton.isHidden = true
        case .DisclosureIndicator:
            switchView.isHidden = true
            disclosure.isHidden = false
            moreButton.isHidden = true
        case .More:
            switchView.isHidden = true
            disclosure.isHidden = true
            moreButton.isHidden = false
        case .NoneAccessoryView:
            switchView.isHidden = true
            disclosure.isHidden = true
            moreButton.isHidden = true
        }
                
        moreButton.layoutStyle = cellModel.moreLayoutStyle
        moreButton.midSpacing = cellModel.moreDisclosureIndicatorSpace
        moreButton.imageSize = cellModel.moreDisclosureIndicatorSize
        moreButton.setTitleFont(cellModel.moreFont, state: .normal)
        moreButton.setTitleColor(cellModel.moreColor, state: .normal)
        moreButton.setTitle(cellModel.moreString, state: .normal)
        moreButton.setImage(cellModel.moreDisclosureIndicator, state: .normal)
        
        layoutSubviews()
        var moreWith:CGFloat = 0
        switch cellModel.moreLayoutStyle {
        case .leftImageRightTitle,.leftTitleRightImage:
            moreWith = moreButton.getKitCurrentDimension()
        case .upImageDownTitle,.upTitleDownImage:
            let moreStringWidth = UIView.sizeFor(string: cellModel.moreString, font: cellModel.moreFont, height: height - (cellModel.imageTopOffset + cellModel.imageBottomOffset)).width
            if moreStringWidth > cellModel.moreDisclosureIndicatorSize.width {
                moreWith = moreStringWidth + 5
            } else {
                moreWith = cellModel.moreDisclosureIndicatorSize.width + 5
            }
        case .title:
            let moreStringWidth = UIView.sizeFor(string: cellModel.moreString, font: cellModel.moreFont, height: height - (cellModel.imageTopOffset + cellModel.imageBottomOffset)).width
            moreWith = moreStringWidth + 5
        case .image:
            moreWith = cellModel.moreDisclosureIndicatorSize.width + 5
        }
        moreButton.snp.remakeConstraints {
            $0.right.equalToSuperview().inset(cellModel.rightSpace)
            $0.top.equalToSuperview().inset(cellModel.imageTopOffset)
            $0.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
            $0.width.equalTo(moreWith)
        }
                
        disclosure.snp.updateConstraints {
            $0.right.equalToSuperview().inset(cellModel.rightSpace)
        }

        disclosure.snp.updateConstraints {
            $0.right.equalToSuperview().inset(cellModel.rightSpace)
        }

        // 动态右边约束目标
        let targetView: UIView = {
            switch config.accessory {
            case .Switch: return switchView
            case .DisclosureIndicator: return disclosure
            case .More: return moreButton
            case .NoneAccessoryView: return rightSpacingView
            }
        }()
        
        leftIcon.snp.updateConstraints { make in
            make.left.equalToSuperview().inset(cellModel.leftSpace)
            make.top.equalToSuperview().inset(cellModel.imageTopOffset)
            make.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
        }
        
        leftSpacingView.snp.updateConstraints { make in
            make.width.equalTo(cellModel.leftSpace)
        }
        
        rightSpacingView.snp.updateConstraints { make in
            make.width.equalTo(cellModel.rightSpace)
        }

        let leftTargetView: UIView = {
            if config.showLeftIcon {
                return leftIcon
            } else {
                return leftSpacingView
            }
        }()
        
        let leftTargetSpacing:CGFloat = config.showLeftIcon ? cellModel.contentLeftSpace : 0
        
        titleLabel.snp.remakeConstraints {
            $0.left.equalTo(leftTargetView.snp.right).offset(leftTargetSpacing)
            $0.top.bottom.equalToSuperview()
        }

        rightIcon.snp.remakeConstraints { // 这里只允许一个 remake（固定结构）
            $0.right.equalTo(targetView.snp.left).offset(-cellModel.contentRightSpace)
            $0.top.equalToSuperview().inset(cellModel.imageTopOffset)
            $0.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
            $0.width.equalTo(rightIcon.snp.height)
        }
        
        disclosure.snp.updateConstraints {
            $0.size.equalTo(cellModel.moreDisclosureIndicatorSize)
        }
        
        var rightTargetSpacing:CGFloat = 0
        if config.showRightIcon {
            rightTargetSpacing = cellModel.contentToRightImageSpacing
        } else {
            switch config.accessory {
            case .NoneAccessoryView:
                rightTargetSpacing = 0
            default:
                rightTargetSpacing = cellModel.contentRightSpace
            }
        }
        
        let contentRightTarget: UIView = {
            if config.showRightIcon {
                return rightIcon
            } else {
                switch config.accessory {
                case .Switch: return switchView
                case .DisclosureIndicator: return disclosure
                case .More: return moreButton
                case .NoneAccessoryView: return rightSpacingView
                }
            }
        }()
        
        contentLabel.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.right).offset(8)
            $0.top.bottom.equalToSuperview()
            $0.right.lessThanOrEqualTo(contentRightTarget.snp.left).offset(-rightTargetSpacing)
        }
        
        switch cellModel.haveLine {
        case .NO:
            bottomLineView.isHidden = true
            bottomImaginaryLineView.isHidden = true
        case .Normal:
            bottomLineView.isHidden = false
            bottomImaginaryLineView.isHidden = true
        case .Imaginary:
            bottomLineView.isHidden = true
            bottomImaginaryLineView.isHidden = false
        }
        
        switch cellModel.haveTopLine {
        case .NO:
            topLineView.isHidden = true
            topImaginaryLineView.isHidden = true
        case .Normal:
            topLineView.isHidden = false
            topImaginaryLineView.isHidden = true
        case .Imaginary:
            topLineView.isHidden = true
            topImaginaryLineView.isHidden = false
        }
        topLineView.backgroundColor = cellModel.topLineColor
        topLineView.snp.updateConstraints { make in
            make.height.equalTo(cellModel.topLineHeight)
            make.left.equalToSuperview().inset(cellModel.leftSpace)
            make.right.equalToSuperview().inset(cellModel.rightSpace)
        }
        topImaginaryLineView.lineColor = cellModel.topLineColor
        
        bottomLineView.backgroundColor = cellModel.bottomLineColor
        bottomLineView.snp.updateConstraints { make in
            make.height.equalTo(cellModel.bottomLineHeight)
            make.left.equalToSuperview().inset(cellModel.leftSpace)
            make.right.equalToSuperview().inset(cellModel.rightSpace)
        }
        bottomImaginaryLineView.lineColor = cellModel.bottomLineColor
    }
    
    private func applyData(_ model: PTFusionCellModel) {
        
        titleLabel.attributed.text = titleLabelAtt(model)
        
        contentLabel.numberOfLines = model.contentNumberOfLines
        contentLabel.attributed.text = contentLabelAtt(model)
        
        leftIcon.loadImage(contentData: model.leftImage as Any,iCloudDocumentName: model.iCloudDocument)
        rightIcon.loadImage(contentData: model.contentIcon as Any,iCloudDocumentName: model.iCloudDocument)
        disclosure.loadImage(contentData: model.disclosureIndicatorImage as Any,iCloudDocumentName: model.iCloudDocument)
    }
    
    private func titleLabelAtt(_ model: PTFusionCellModel) -> ASAttributedString {
        if let findModel = model.nameAttr {
            return findModel
        } else {
            if !model.name.stringIsEmpty() && !model.desc.stringIsEmpty() {
                let att:ASAttributedString = """
                            \(wrap: .embedding("""
                            \(model.name,.font(model.cellFont),.foreground(model.nameColor))
                            \(model.desc,.font(model.cellDescFont),.foreground(model.descColor))
                            """),.paragraph(.alignment(.left),.lineSpacing(model.labelLineSpace)))
                            """
                return att
            } else if !model.name.stringIsEmpty() && model.desc.stringIsEmpty() {
                let att:ASAttributedString = """
                            \(wrap: .embedding("""
                            \(model.name,.font(model.cellFont),.foreground(model.nameColor))
                            """),.paragraph(.alignment(.left),.lineSpacing(model.labelLineSpace)))
                            """
                return att
            } else if model.name.stringIsEmpty() && !model.desc.stringIsEmpty() {
                let att:ASAttributedString = """
                            \(wrap: .embedding("""
                            \(model.desc,.font(model.cellDescFont),.foreground(model.descColor))
                            """),.paragraph(.alignment(.left),.lineSpacing(model.labelLineSpace)))
                            """
                return att
            } else {
                let att:ASAttributedString = """
                            \(wrap: .embedding("""
                            """),.paragraph(.alignment(.left),.lineSpacing(model.labelLineSpace)))
                            """
                return att
            }
        }
    }
    
    private func contentLabelAtt(_ model: PTFusionCellModel) -> ASAttributedString {
        if let findModel = model.contentAttr {
            return findModel
        } else {
            if !model.content.stringIsEmpty() {
                let contentAtts:ASAttributedString =  ASAttributedString("\(model.content)",.paragraph(.alignment(.right),.lineSpacing(model.labelLineSpace),.lineBreakMode(model.contentLineBreakMode)),.font(model.contentFont),.foreground(model.contentTextColor))
                return contentAtts
            } else {
                let att:ASAttributedString = """
                            \(wrap: .embedding("""
                            """),.paragraph(.alignment(.left),.lineSpacing(model.labelLineSpace)))
                            """
                return att
            }
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
            if let findValue = switchValue {
                switch dataContent.switchView {
                case let valueView as PTSwitch:
                    valueView.isOn = findValue
                case let valueView as UISwitch:
                    valueView.isOn = findValue
                default:break
                }
            }
        }
    }

    open var cellModel: PTFusionCellModel? {
        didSet {
            if let cellModel = cellModel {
                dataContent.configure(model: cellModel)
            }
        }
    }
        
    fileprivate lazy var dataContent: PTFusionContentView = {
        let view = PTFusionContentView()
        view.switchValueChangeBlock = { name,view in
            self.switchValueChangeBlock?(name,view)
        }
        view.moreButton.addActionHandlers { sender in
            if let findCellModel = self.cellModel {
                self.moreActionBlock?(findCellModel.name,sender)
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
            if let findValue = switchValue {
                switch dataContent.switchView {
                case let valueView as PTSwitch:
                    valueView.isOn = findValue
                case let valueView as UISwitch:
                    valueView.isOn = findValue
                default:break
                }
            }
        }
    }

    open var cellModel: PTFusionCellModel? {
        didSet {
            if let cellModel = cellModel {
                dataContent.configure(model: cellModel)
            }
        }
    }
    
    fileprivate lazy var dataContent: PTFusionContentView = {
        let view = PTFusionContentView()
        view.switchValueChangeBlock = { name,view in
            self.switchValueChangeBlock?(name,view)
        }
        view.moreButton.addActionHandlers { sender in
            if let findCellModel = self.cellModel {
                self.moreActionBlock?(findCellModel.name,sender)
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
