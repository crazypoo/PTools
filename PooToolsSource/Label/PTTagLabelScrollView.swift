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
    private var textColor:UIColor
    private var borderColor:UIColor
    private var itemPadding: UIEdgeInsets
    private var cornerRadius:CGFloat
    private var borderLineHeight:CGFloat


    public init(spacing: CGFloat = 6,
                font: UIFont = .systemFont(ofSize: 14),
                textColor:DynamicColor = .black,
                cornerRadius:CGFloat = 2,
                borderColor:DynamicColor = .black,
                borderLineHeight:CGFloat = 1,
                itemPadding:UIEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)) {
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
        stackView.distribution = .fillProportionally
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        showsHorizontalScrollIndicator = false
    }
    
    /// 设置标签（传空数组也会清空）
    public func setTags(_ tags: [String]) {
        clearTags()
        for text in tags {
            let label = PTPaddingLabel(padding: itemPadding)
            label.text = text
            label.font = font
            label.textColor = textColor
            label.backgroundColor = .clear
            label.layer.masksToBounds = true
            stackView.addArrangedSubview(label)
            label.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(4)
            }
        }
        
        PTGCDManager.gcdAfter(time: 0.1) {
            self.stackView.arrangedSubviews.forEach { value in
                value.viewCorner(radius: self.cornerRadius,borderWidth: self.borderLineHeight,borderColor: self.borderColor)
            }
        }
    }
    
    /// 清空标签
    public func clearTags() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}

/// 一个带内边距的 UILabel，方便加 padding
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
