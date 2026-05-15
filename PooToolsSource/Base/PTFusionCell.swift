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

// ✅ Swift 6 优化：显式标记 @MainActor 确保 UI 回调在主线程安全执行
public typealias PTCellSwitchBlock = @MainActor (_ rowText: String, _ sender: UIControl) -> Void
public typealias PTSectionMoreBlock = @MainActor (_ rowText: String, _ sender: PTActionLayoutButton) -> Void

fileprivate extension UIView {
    /// 绘制简单横线
    func drawLine() -> UIView {
        let lineView = UIView()
        lineView.backgroundColor = UIColor(hexString: "#E8E8E8")
        return lineView
    }
}

public final class PTFusionContentView: UIView {
    
    public var switchValueChangeBlock: PTCellSwitchBlock?

    // MARK: - View Pool（一次创建）
    private var cellModel = PTFusionCellModel()
    private var currentLayoutState: PTFusionLayoutConfig?
    private let leftIcon = UIImageView()
    private let rightIcon = UIImageView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    
    // ✅ Swift 6 优化：添加 [weak self] 彻底修复强引用循环（内存泄漏）
    private lazy var systemSwitch: UISwitch = {
        let view = UISwitch()
        view.addSwitchAction { [weak self] sender in
            guard let self else { return }
            self.switchValueChangeBlock?(self.cellModel.name, sender)
        }
        return view
    }()
    
    // ✅ Swift 6 优化：添加 [weak self] 修复强引用循环
    private lazy var customSwitch: PTSwitch = {
        let view = PTSwitch()
        view.valueChangeCallBack = { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.switchValueChangeBlock?(self.cellModel.name, self.customSwitch)
            }
        }
        return view
    }()
    
    public var activeSwitch: UIControl? {
        if !systemSwitch.isHidden { return systemSwitch }
        if !customSwitch.isHidden { return customSwitch }
        return nil
    }
    
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
    // ✅ Swift 6 优化：将隐式解包(!)改为可选型(?)，使用更加安全
    private var rightAnchorConstraint: Constraint?
    private var titleLeftToIcon: Constraint?
    private var titleLeftToSpacing: Constraint?

    private var moreWidthConstraint: Constraint?
    private var moreTopConstraint: Constraint?
    private var moreBottomConstraint: Constraint?
    private var moreRightConstraint: Constraint?
    
    private var contentRightConstraint: Constraint?
    
    private var leftSpacingWidthConstraint: Constraint?
    private var rightSpacingWidthConstraint: Constraint?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Setup
private extension PTFusionContentView {
        
    func setupUI() {
        addSubviews([
            leftSpacingView, rightSpacingView, topLineView, bottomLineView,
            topImaginaryLineView, bottomImaginaryLineView, leftIcon, rightIcon,
            titleLabel, contentLabel, systemSwitch, customSwitch, moreButton, disclosure
        ])
        
        titleLabel.numberOfLines = 0
        contentLabel.numberOfLines = 0
        
        leftSpacingView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            leftSpacingWidthConstraint = make.width.equalTo(0).constraint
        }
        
        rightSpacingView.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            rightSpacingWidthConstraint = make.width.equalTo(0).constraint
        }
        
        topLineView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        
        bottomLineView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        
        topImaginaryLineView.snp.makeConstraints { make in
            make.edges.equalTo(self.topLineView)
        }
        
        bottomImaginaryLineView.snp.makeConstraints { make in
            make.edges.equalTo(self.bottomLineView)
        }
        
        leftIcon.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(leftIcon.snp.height)
        }
        
        rightIcon.snp.makeConstraints { make in
            rightAnchorConstraint = make.right.equalToSuperview().offset(-16).constraint
            make.top.bottom.equalToSuperview()
            make.width.equalTo(rightIcon.snp.height)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            titleLeftToIcon = make.left.equalTo(leftIcon.snp.right).offset(12).constraint
            titleLeftToSpacing = make.left.equalTo(leftSpacingView.snp.right).constraint
        }
        titleLeftToSpacing?.deactivate()
        titleLeftToIcon?.activate()

        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualTo(rightIcon.snp.left).offset(-8)
        }
        
        systemSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
        
        customSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.size.equalTo(CGSize.SwitchSize)
        }
        
        moreButton.snp.makeConstraints { make in
            moreRightConstraint = make.right.equalToSuperview().inset(16).constraint
            moreTopConstraint = make.top.equalToSuperview().constraint
            moreBottomConstraint = make.bottom.equalToSuperview().constraint
            moreWidthConstraint = make.width.equalTo(0).constraint
        }
        
        disclosure.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.size.equalTo(16)
        }
    }
}

// MARK: - Data & Layout Configuration
extension PTFusionContentView {
    
    public func configure(model: PTFusionCellModel) {
        cellModel = model
        let newState = model.layoutState
        
        // 只有结构变化才更新 layout
        if currentLayoutState != newState {
            applyLayout(cellModel: model)
            currentLayoutState = newState
        }

        applySwitch(model)
        applyData(model)
    }
        
    private func applyLayout(cellModel: PTFusionCellModel) {
        leftIcon.isHidden = !cellModel.layoutState.showLeftIcon
        rightIcon.isHidden = !cellModel.layoutState.showRightIcon
        titleLabel.isHidden = !cellModel.layoutState.showTitle
        contentLabel.isHidden = !cellModel.layoutState.showContent
        
        if case let .Switch(value) = cellModel.accessoryType,
           case .Framework = value {
            customSwitch.snp.updateConstraints { make in
                make.right.equalToSuperview().inset(cellModel.rightSpace)
                make.size.equalTo(CGSize(width: cellModel.switchControlWidth, height: CGSize.SwitchSize.height))
            }
        }
        
        switch cellModel.layoutState.accessory {
        case .Switch:
            disclosure.isHidden = true
            moreButton.isHidden = true
        case .DisclosureIndicator:
            disclosure.isHidden = false
            moreButton.isHidden = true
        case .More:
            disclosure.isHidden = true
            moreButton.isHidden = false
        case .NoneAccessoryView:
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
        
        // ✅ Swift 6：安全调用可选型约束更新
        moreRightConstraint?.update(inset: cellModel.rightSpace)
        moreTopConstraint?.update(inset: cellModel.imageTopOffset)
        moreBottomConstraint?.update(inset: cellModel.imageBottomOffset)
        moreWidthConstraint?.update(offset: cellModel.cachedMoreWidth)
        
        disclosure.snp.updateConstraints { make in
            make.right.equalToSuperview().inset(cellModel.rightSpace)
            make.size.equalTo(cellModel.moreDisclosureIndicatorSize)
        }

        let targetView: UIView = {
            switch cellModel.layoutState.accessory {
            case .Switch(let value):
                switch value {
                case .Framework: return customSwitch
                case .System: return systemSwitch
                }
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
        
        leftSpacingWidthConstraint?.update(offset: cellModel.leftSpace)
        rightSpacingWidthConstraint?.update(offset: cellModel.rightSpace)
        
        if cellModel.layoutState.showLeftIcon {
            titleLeftToSpacing?.deactivate()
            titleLeftToIcon?.activate()
            titleLeftToIcon?.update(offset: cellModel.contentLeftSpace)
        } else {
            titleLeftToIcon?.deactivate()
            titleLeftToSpacing?.activate()
        }
        
        rightIcon.snp.remakeConstraints { make in
            make.right.equalTo(targetView.snp.left).offset(-cellModel.contentRightSpace)
            make.top.equalToSuperview().inset(cellModel.imageTopOffset)
            make.bottom.equalToSuperview().inset(cellModel.imageBottomOffset)
            make.width.equalTo(rightIcon.snp.height)
        }
                 
        var rightTargetSpacing: CGFloat = 0
        if cellModel.layoutState.showRightIcon {
            rightTargetSpacing = cellModel.contentToRightImageSpacing
        } else {
            switch cellModel.layoutState.accessory {
            case .NoneAccessoryView:
                rightTargetSpacing = 0
            default:
                rightTargetSpacing = cellModel.contentRightSpace
            }
        }
        
        let contentRightTarget: UIView = {
            if cellModel.layoutState.showRightIcon {
                return rightIcon
            } else {
                switch cellModel.layoutState.accessory {
                case .Switch(let value):
                    switch value {
                    case .Framework: return customSwitch
                    case .System: return systemSwitch
                    }
                case .DisclosureIndicator: return disclosure
                case .More: return moreButton
                case .NoneAccessoryView: return rightSpacingView
                }
            }
        }()
        
        contentLabel.snp.remakeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(contentRightTarget.snp.left).offset(-rightTargetSpacing)
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
        titleLabel.attributed.text = model.cachedTitleAttr
        contentLabel.numberOfLines = model.contentNumberOfLines
        contentLabel.attributed.text = model.cachedContentAttr
        
        leftIcon.contentMode = .scaleAspectFit
        leftIcon.loadImage(contentData: model.leftImage as Any, iCloudDocumentName: model.iCloudDocument)
        
        rightIcon.contentMode = .scaleAspectFit
        rightIcon.loadImage(contentData: model.contentIcon as Any, iCloudDocumentName: model.iCloudDocument)
        
        disclosure.contentMode = .scaleAspectFit
        disclosure.loadImage(contentData: model.disclosureIndicatorImage as Any, iCloudDocumentName: model.iCloudDocument)
    }
    
    private func applySwitch(_ model: PTFusionCellModel) {
        systemSwitch.isHidden = true
        customSwitch.isHidden = true
        
        guard case let .Switch(type) = model.accessoryType else { return }
                 
        switch type {
        case .System:
            systemSwitch.onTintColor = model.switchOnTinColor
            systemSwitch.thumbTintColor = model.switchThumbTintColor
            systemSwitch.tintColor = model.switchTintColor
            systemSwitch.backgroundColor = model.switchBackgroundColor
            systemSwitch.isHidden = false
        case .Framework:
            customSwitch.onTintColor = model.switchOnTinColor
            customSwitch.thumbColor = model.switchThumbTintColor
            customSwitch.switchTintColor = model.switchTintColor
            customSwitch.backgroundColor = model.switchBackgroundColor
            customSwitch.isHidden = false
        }
    }
}

// ✅ Swift 6 优化：显式添加 @MainActor 保证遵循该协议的类型在并发下对齐 Actor 隔离
@MainActor
protocol PTFusionCellProtocol: AnyObject {
    var switchValueChangeBlock: PTCellSwitchBlock? { get set }
    var moreActionBlock: PTSectionMoreBlock? { get set }
    var cellModel: PTFusionCellModel? { get set }
    var switchValue: Bool? { get set }
    
    var dataContent: PTFusionContentView { get }
    
    func setupFusionUI(in view: UIView)
}

extension PTFusionCellProtocol {

    func setupFusionUI(in view: UIView) {
        view.addSubview(dataContent)
        dataContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bindEvents()
    }
    
    private func bindEvents() {
        dataContent.switchValueChangeBlock = { [weak self] name, sender in
            self?.switchValueChangeBlock?(name, sender)
        }
        
        dataContent.moreButton.addActionHandlers { [weak self] sender in
            guard let self, let model = self.cellModel else { return }
            self.moreActionBlock?(model.name, sender)
        }
    }
    
    func updateSwitch(_ value: Bool?) {
        guard let value else { return }
        
        switch dataContent.activeSwitch {
        case let v as PTSwitch:
            v.isOn = value
        case let v as UISwitch:
            v.isOn = value
        default:
            break
        }
    }
    
    func updateModel(_ model: PTFusionCellModel?) {
        guard let model else { return }
        dataContent.configure(model: model)
    }
}

@objcMembers
open class PTFusionCell: PTBaseNormalCell, PTFusionCellProtocol {
    public static let ID = "PTFusionCell"
        
    public var switchValueChangeBlock: PTCellSwitchBlock?
    public var moreActionBlock: PTSectionMoreBlock?
    
    open var switchValue: Bool? {
        didSet { updateSwitch(switchValue) }
    }

    open var cellModel: PTFusionCellModel? {
        didSet { updateModel(cellModel) }
    }
        
    public lazy var dataContent: PTFusionContentView = PTFusionContentView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupFusionUI(in: contentView)
    }
    
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objcMembers
open class PTFusionSwipeCell: PTBaseSwipeCell, PTFusionCellProtocol {
    public static let ID = "PTFusionSwipeCell"
    
    public var switchValueChangeBlock: PTCellSwitchBlock?
    public var moreActionBlock: PTSectionMoreBlock?
    
    open var switchValue: Bool? {
        didSet { updateSwitch(switchValue) }
    }

    open var cellModel: PTFusionCellModel? {
        didSet { updateModel(cellModel) }
    }
        
    public lazy var dataContent: PTFusionContentView = PTFusionContentView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupFusionUI(in: contentView)
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension UICollectionViewCell {
    func cellContentViewCorners(radius: CGFloat = 0, borderWidth: CGFloat = 0, borderColor: UIColor = .clear, capsule: Bool = false) {
        self.contentView.viewCornerRectCorner(radius: radius, borderWidth: borderWidth, borderColor: borderColor, corner: .allCorners, capsule: capsule)
    }
    
    func cellContentViewCornerRectCorners(cornerRadii: CGFloat = 5, borderWidth: CGFloat = 0, borderColor: UIColor = .clear, corner: UIRectCorner = .allCorners, capsule: Bool = false) {
        self.contentView.viewCornerRectCorner(radius: cornerRadii, borderWidth: borderWidth, borderColor: borderColor, corner: corner, capsule: capsule)
    }
}
