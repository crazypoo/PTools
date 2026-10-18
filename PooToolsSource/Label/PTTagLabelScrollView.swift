//
//  PTTagLabelScrollView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/8/19.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

public class PTTagLabelScrollView: UIScrollView {

    private let stackView = UIStackView()
    private var font: UIFont
    private var spacing: CGFloat
    private var textColor: UIColor
    private var borderColor: UIColor
    private var itemPadding: UIEdgeInsets
    private var cornerRadius: CGFloat
    private var borderLineHeight: CGFloat

    public init(spacing: CGFloat = 6,
                font: UIFont = .systemFont(ofSize: 14),
                textColor: UIColor = .black,
                cornerRadius: CGFloat = 2,
                borderColor: UIColor = .black,
                borderLineHeight: CGFloat = 1,
                itemPadding: UIEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)) {
        self.font = font
        self.spacing = spacing
        self.textColor = textColor
        self.borderColor = borderColor
        self.itemPadding = itemPadding
        self.cornerRadius = cornerRadius
        self.borderLineHeight = borderLineHeight
        super.init(frame: .zero)
        
        setupStackView()
    }
    
    public required init?(coder: NSCoder) {
        self.font = .systemFont(ofSize: 14)
        self.spacing = 6
        self.textColor = .black
        self.borderColor = .black
        self.itemPadding = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        self.cornerRadius = 2
        self.borderLineHeight = 1
        super.init(coder: coder)
        
        setupStackView()
    }
    
    private func setupStackView() {
        stackView.axis = .horizontal
        stackView.spacing = spacing
        stackView.alignment = .center
        // 使用 .fill 替代 .fillProportionally，对于依赖 intrinsicContentSize 的 Label 更可靠
        stackView.distribution = .fill
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            // 现代 UIScrollView 布局：明确区分内容区域（content）与视口区域（frame）
            make.edges.equalTo(self.contentLayoutGuide)
            make.height.equalTo(self.frameLayoutGuide) // 锁定高度，允许内部宽度自由撑开
        }
        
        showsHorizontalScrollIndicator = false
    }
    
    /// 设置标签（已加入性能优化：视图复用机制）
    public func setTags(_ tags: [String]) {
        let currentLabels = stackView.arrangedSubviews.compactMap { $0 as? PTPaddingLabel }
        
        // 1. 遍历最新数据，复用旧 Label 或创建新 Label
        for (index, text) in tags.enumerated() {
            let label: PTPaddingLabel
            
            if index < currentLabels.count {
                // 【复用逻辑】如果已有 Label，直接拿来用，并确保它是显示状态
                label = currentLabels[index]
                label.isHidden = false
            } else {
                // 【创建逻辑】如果 Label 不够了，再创建新的
                label = PTPaddingLabel(padding: itemPadding)
                label.font = font
                label.textColor = textColor
                label.backgroundColor = .clear
                label.layer.masksToBounds = true
                
                // 🌟 修复延迟 Bug：直接使用 layer 属性，立刻生效，不需要异步等待
                label.layer.cornerRadius = cornerRadius
                label.layer.borderWidth = borderLineHeight
                label.layer.borderColor = borderColor.cgColor
                
                stackView.addArrangedSubview(label)
                
                // 删除了内部冗余的 snp.makeConstraints，避免与 StackView 机制冲突
            }
            
            // 更新文本
            label.text = text
        }
        
        // 2. 隐藏多余的 Label（不执行 removeFromSuperview，以便下次继续复用）
        if tags.count < currentLabels.count {
            for i in tags.count..<currentLabels.count {
                currentLabels[i].isHidden = true
            }
        }
    }
    
    /// 清空所有标签
    public func clearTags() {
        // 通常配合复用机制，只需隐藏即可。
        // 如果你的目的是彻底释放内存，保留原有 removeFromSuperview 也可以。
        stackView.arrangedSubviews.forEach { $0.isHidden = true }
    }
}

/// 一个带内边距的 UILabel，保持不变（你的实现很棒）
public class PTPaddingLabel: UILabel {
    private var padding: UIEdgeInsets
    
    public init(padding: UIEdgeInsets) {
        self.padding = padding
        super.init(frame: .zero)
    }
    
    public required init?(coder: NSCoder) {
        self.padding = .zero
        super.init(coder: coder)
    }
    
    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    public override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }
}
