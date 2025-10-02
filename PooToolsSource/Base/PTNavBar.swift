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

open class PTNavBar: UIView {
    
    fileprivate var titleViewMAxWidth:CGFloat = (CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2) {
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
    
    // 左侧按钮容器
    private let leftStack = UIStackView()
    // 右侧按钮容器
    private let rightStack = UIStackView()
    // 标题容器（保持居中）
    private let titleContainer = UIView()
    
    // MARK: - TitleView 布局模式
    public enum PTTitleViewMode {
        case auto              // 根据 intrinsicContentSize 自适应
        case fixed(CGFloat)    // 固定宽度
        case fill              // 撑满 titleContainer
    }

    public var titleViewMode: PTTitleViewMode = .fill {
        didSet {
            // 重新应用约束
            if let view = titleView {
                applyTitleViewConstraints(view)
            }
        }
    }

    // 对外暴露的 titleView
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
            }
        }
    }
    
    public init() {
        super.init(frame: .zero)
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
        // 配置左右按钮组
        [leftStack, rightStack].forEach {
            $0.axis = .horizontal
            $0.spacing = PTAppBaseConfig.share.navBarButtonSpacing
            $0.alignment = .center
            $0.distribution = .equalSpacing
        }
        
        addSubviews([leftStack,rightStack,titleContainer])
        
        // SnapKit 约束
        leftStack.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalToSuperview()
            make.height.equalTo(34)
            make.width.equalTo(0)
        }
        
        rightStack.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalToSuperview()
            make.height.equalTo(34)
            make.width.equalTo(0)
        }
        
        titleContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftStack.snp.right).offset(PTAppBaseConfig.share.navContainerSpacing)
            make.right.lessThanOrEqualTo(rightStack.snp.left).offset(-PTAppBaseConfig.share.navContainerSpacing)
            make.height.equalTo(34)
        }
    }
    
    // MARK: - 私有方法
    
    private func applyTitleViewConstraints(_ view: UIView) {
        view.snp.remakeConstraints { make in
            switch titleViewMode {
            case .auto:
                make.centerX.centerY.equalToSuperview()
                make.height.equalToSuperview()
                let targetWidth = max(view.intrinsicContentSize.width, view.bounds.width)
                make.width.equalTo(min(targetWidth, titleViewMAxWidth))
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
    
    /// 添加左侧按钮
    public func setLeftButtons(_ buttons: [UIView]) {
        leftStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons.forEach { value in
            leftStack.addArrangedSubview(value)
            if let switchV = value as? PTSwitch {
                switchV.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size)
                    make.centerY.equalToSuperview()
                }
            } else if let switchV = value as? UISwitch {
                switchV.snp.makeConstraints { make in
                    make.size.equalTo(CGSize.SwitchSize)
                    make.centerY.equalToSuperview()
                }
            }
        }
        let widthToTal:CGFloat = stackTotalWidth(leftStack)
        leftStack.snp.updateConstraints { make in
            make.width.equalTo(widthToTal)
        }
        calculateMaxWidth()
    }
    
    /// 添加右侧按钮
    public func setRightButtons(_ buttons: [UIView]) {
        rightStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons.forEach { value in
            rightStack.addArrangedSubview(value)
            if let switchV = value as? PTSwitch {
                switchV.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size)
                    make.centerY.equalToSuperview()
                }
            } else if let switchV = value as? UISwitch {
                switchV.snp.makeConstraints { make in
                    make.size.equalTo(CGSize.SwitchSize)
                    make.centerY.equalToSuperview()
                }
            }
        }
        let widthToTal:CGFloat = stackTotalWidth(rightStack)
        rightStack.snp.updateConstraints { make in
            make.width.equalTo(widthToTal)
        }
        calculateMaxWidth()
    }
    
    private func stackTotalWidth(_ stack: UIStackView) -> CGFloat {
        var total: CGFloat = 0
        stack.arrangedSubviews.forEach {
            if let switchV = $0 as? PTSwitch {
                total += switchV.bounds.width > 0 ? switchV.bounds.width : CGSize.SwitchSize.width
            } else if $0 is UISwitch {
                total += CGSize.SwitchSize.width
            } else {
                total += $0.bounds.width > 0 ? $0.bounds.width : 34
            }
        }
        return total + CGFloat(stack.arrangedSubviews.count - 1) * PTAppBaseConfig.share.navBarButtonSpacing
    }
    
    private func calculateMaxWidth() {
        let rightWidthToTal:CGFloat = stackTotalWidth(rightStack)
        let leftWidthToTal:CGFloat = stackTotalWidth(leftStack)
        if leftStack.arrangedSubviews.count == rightStack.arrangedSubviews.count {
            titleContainer.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.centerX.equalToSuperview()
                make.left.lessThanOrEqualTo(leftStack.snp.right).offset(PTAppBaseConfig.share.navContainerSpacing)
                make.right.lessThanOrEqualTo(rightStack.snp.left).offset(-PTAppBaseConfig.share.navContainerSpacing)
                make.height.equalTo(34)
            }
        } else {
            titleContainer.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(leftStack.snp.right).offset(PTAppBaseConfig.share.navContainerSpacing)
                make.right.equalTo(rightStack.snp.left).offset(-PTAppBaseConfig.share.navContainerSpacing)
                make.height.equalTo(34)
            }
        }

        let newWidth = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2 - PTAppBaseConfig.share.navContainerSpacing * 2 - leftWidthToTal - rightWidthToTal
        if newWidth != titleViewMAxWidth {
            titleViewMAxWidth = newWidth
            if let view = titleView {
                applyTitleViewConstraints(view)
            }
        }
    }
}
