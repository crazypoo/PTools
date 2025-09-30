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
    // 左侧按钮容器
    private let leftStack = UIStackView()
    // 右侧按钮容器
    private let rightStack = UIStackView()
    // 标题容器（保持居中）
    private let titleContainer = UIView()
    
    // 对外暴露的 titleView
    public var titleView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let newView = titleView {
                titleContainer.addSubview(newView)
                newView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
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
        }
        
        rightStack.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalToSuperview()
            make.height.equalTo(34)
        }
        
        titleContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftStack.snp.right).offset(PTAppBaseConfig.share.navContainerSpacing)
            make.right.lessThanOrEqualTo(rightStack.snp.left).offset(-PTAppBaseConfig.share.navContainerSpacing)
            make.height.equalTo(34)
        }
    }
    
    // MARK: - Public API
    
    /// 添加左侧按钮
    public func setLeftButtons(_ buttons: [UIView]) {
        leftStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons.forEach { leftStack.addArrangedSubview($0) }
    }
    
    /// 添加右侧按钮
    public func setRightButtons(_ buttons: [UIView]) {
        rightStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons.forEach { rightStack.addArrangedSubview($0) }
    }
}
