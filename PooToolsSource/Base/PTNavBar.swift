//
//  PTNavBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/9/30.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

@MainActor
open class PTNavBar: PTNavigationBarContainer {
    
    // ✅ 标记是否为普通的 View（不接管系统状态栏）
    public var isFakeNav: Bool = false {
        didSet {
            // 模式改变时，必须立刻重置外层容器的约束！
            updateTopBarContainerConstraints()
            
            // 触发内部按钮的重新布局
            if !leftContainer.arrangedSubviews.isEmpty {
                setLeftButtons(leftContainer.arrangedSubviews)
            }
            if !rightContainer.arrangedSubviews.isEmpty {
                setRightButtons(rightContainer.arrangedSubviews)
            }
        }
    }
    
    fileprivate var titleViewMAxWidth: CGFloat = (CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2) {
        didSet {
            switch titleViewMode {
            case .auto:
                if let view = titleView {
                    let targetWidth = max(view.intrinsicContentSize.width, view.bounds.width)
                    view.snp.remakeConstraints { make in
                        make.centerX.centerY.equalToSuperview()
                        make.height.equalToSuperview()
                        make.width.equalTo(min(targetWidth, titleViewMAxWidth))
                    }
                }
            case .fixed(let width):
                if let view = titleView {
                    view.snp.remakeConstraints { make in
                        make.center.equalToSuperview()
                        make.width.equalTo(min(width, titleViewMAxWidth))
                        make.height.equalToSuperview()
                    }
                }
            default:
                break
            }
        }
    }
    
    public enum PTTitleViewMode: Sendable {
        case auto
        case fixed(CGFloat)
        case fill
    }

    public var titleViewMode: PTTitleViewMode = .fill {
        didSet {
            if let view = titleView { applyTitleViewConstraints(view) }
        }
    }

    public var titleView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let newView = titleView {
                if let labelTitle = newView as? UILabel {
                    labelTitle.setContentHuggingPriority(.required, for: .horizontal)
                    labelTitle.setContentCompressionResistancePriority(.required, for: .horizontal)
                }
                titleContainer.addSubview(newView)
                applyTitleViewConstraints(newView)
                titleContainer.isHidden = false
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        calculateMaxWidth()
    }
    
    private func setupUI() {
        [leftContainer, rightContainer].forEach {
            $0.spacing = PTAppBaseConfig.share.navBarButtonSpacing
        }
        
        // 初始化外层
        updateTopBarContainerConstraints()
        
        // 初始化内层
        updateContainerConstraints(leftContainer, isLeft: true)
        updateContainerConstraints(rightContainer, isLeft: false)
        
        titleContainer.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftContainer.snp.right).offset(PTAppBaseConfig.share.navContainerSpacing)
            make.right.lessThanOrEqualTo(rightContainer.snp.left).offset(-PTAppBaseConfig.share.navContainerSpacing)
            make.height.equalTo(34)
        }
    }
    
    // 🔥 核心逻辑 1：接管并重构父类 topBarContainer 的约束
    private func updateTopBarContainerConstraints() {
        // topBarContainer 是父类 PTNavigationBarContainer 里的属性
        topBarContainer.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            
            if isFakeNav {
                // 如果是假导航栏，完全贴紧边界，不需要 statusBar 偏移
                make.top.equalToSuperview()
                make.height.equalToSuperview() // 或者 equalTo(CGFloat.kNavBarHeight)
            } else {
                // 父类原始逻辑：需要扣减 statusBar 的偏移量
                var offsetHeight: CGFloat = 0
                if let findCurrent = PTUtils.getCurrentVC(), let sheet = findCurrent.sheetViewController {
                    let offset = sheet.options.useFullScreenMode ? CGFloat.statusBarHeight() * 2 : sheet.options.pullBarHeight
                    make.top.equalToSuperview().offset(-offset)
                    offsetHeight = offset
                } else {
                    make.top.equalToSuperview()
                    offsetHeight = CGFloat.statusBarHeight()
                }
                make.height.equalTo(offsetHeight + CGFloat.kNavBarHeight)
            }
        }
    }

    // 🔥 核心逻辑 2：调整内部按钮组相对于 topBarContainer 的 Y 轴布局
    private func updateContainerConstraints(_ container: UIStackView, isLeft: Bool) {
        let widthTotal = stackTotalWidth(container)
        
        container.snp.remakeConstraints { make in
            if isLeft {
                make.left.equalToSuperview().offset(PTAppBaseConfig.share.defaultViewSpace)
            } else {
                make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            }
            
            if isFakeNav {
                // FakeNav 模式：绝对居中
                make.centerY.equalToSuperview()
                make.height.equalTo(34)
            } else {
                // 父类系统接管模式：扣去 statusBar 高度往下顶
                let offsetHeight = (PTUtils.getCurrentVC()?.sheetViewController != nil) ? CGFloat.statusBarHeight() : 0
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + offsetHeight)
                make.bottom.equalToSuperview()
            }
            
            make.width.equalTo(widthTotal)
        }
    }

    private func applyTitleViewConstraints(_ view: UIView) {
        view.snp.remakeConstraints { make in
            switch titleViewMode {
            case .auto:
                let targetWidth = max(view.intrinsicContentSize.width, view.bounds.width)
                let width = min(targetWidth, titleViewMAxWidth)
                make.centerX.centerY.equalToSuperview()
                make.height.equalToSuperview()
                make.width.equalTo(width)
            case .fixed(let width):
                make.center.equalToSuperview()
                make.width.equalTo(min(width, titleViewMAxWidth))
                make.height.equalToSuperview()
            case .fill:
                make.edges.equalToSuperview()
            }
        }
        calculateMaxWidth()
    }

    // MARK: - Public API
    
    public func setLeftButtons(_ buttons: [UIView]) {
        leftContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if !buttons.isEmpty {
            leftContainer.isHidden = false
        }
        buttons.forEach { value in
            leftContainer.addArrangedSubview(value)
            if let switchV = value as? UISwitch {
                switchV.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size.width > 0 ? value.bounds.size : CGSize(width: 51, height: 31))
                    make.centerY.equalToSuperview()
                }
            } else {
                value.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size)
                    make.centerY.equalToSuperview()
                }
            }
        }
        self.leftContainerWidth = stackTotalWidth(leftContainer)
        updateContainerConstraints(leftContainer, isLeft: true)
        calculateMaxWidth()
    }
    
    public func setRightButtons(_ buttons: [UIView]) {
        rightContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if !buttons.isEmpty {
            rightContainer.isHidden = false
        }
        buttons.forEach { value in
            rightContainer.addArrangedSubview(value)
            if let switchV = value as? UISwitch {
                switchV.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size.width > 0 ? value.bounds.size : CGSize(width: 51, height: 31))
                    make.centerY.equalToSuperview()
                }
            } else {
                value.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size)
                    make.centerY.equalToSuperview()
                }
            }
        }
        self.rightContainerWidth = stackTotalWidth(rightContainer)
        updateContainerConstraints(rightContainer, isLeft: false)
        calculateMaxWidth()
    }
    
    private func stackTotalWidth(_ stack: UIStackView) -> CGFloat {
        var total: CGFloat = 0
        stack.arrangedSubviews.forEach {
            if $0 is UISwitch {
                total += $0.bounds.width > 0 ? $0.bounds.width : 51
            } else {
                total += $0.bounds.width > 0 ? $0.bounds.width : 34
            }
        }
        return total + CGFloat(max(0, stack.arrangedSubviews.count - 1)) * PTAppBaseConfig.share.navBarButtonSpacing
    }
    
    private func calculateMaxWidth() {
        let rightWidthTotal: CGFloat = stackTotalWidth(rightContainer)
        let leftWidthTotal: CGFloat = stackTotalWidth(leftContainer)
        
        titleContainer.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftContainer.snp.right).offset(PTAppBaseConfig.share.navContainerSpacing)
            make.right.lessThanOrEqualTo(rightContainer.snp.left).offset(-PTAppBaseConfig.share.navContainerSpacing)
            make.height.equalTo(34)
        }

        let newWidth = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2 - PTAppBaseConfig.share.navContainerSpacing * 2 - leftWidthTotal - rightWidthTotal
        if newWidth != titleViewMAxWidth {
            titleViewMAxWidth = newWidth
            if let view = titleView {
                applyTitleViewConstraints(view)
            }
        }
    }
}
