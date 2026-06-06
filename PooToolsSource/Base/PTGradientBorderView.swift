//
//  PTGradientBorderView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/7/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

open class PTGradientBorderView: UIView {
    
    // MARK: - 属性定义
    
    open var cornerRadius: CGFloat = 8 {
        didSet {
            updateGradientBorder()
        }
    }
    
    open var lineWidth: CGFloat = 5 {
        didSet {
            updateGradientBorder()
        }
    }
    
    open var gradientColors: [UIColor] = [UIColor.red, UIColor.blue] {
        didSet {
            updateGradientBorder()
        }
    }
    
    // 注意：假设 Imagegradien 是你在其他地方定义的枚举
    open var gradientDirection: Imagegradien = .LeftToRight {
        didSet {
            updateGradientBorder()
        }
    }
    
    // MARK: - 初始化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        updateGradientBorder()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        updateGradientBorder()
    }
    
    // MARK: - 核心方法
    
    /// 将所有的属性变化，直接桥接到 Extension 提供的方法中
    private func updateGradientBorder() {
        // 直接调用你写好的 superGradient 扩展方法
        // 因为这是一个“只有边框”的视图，所以 bgType 和 bgColors 传 nil
        self.superGradient(
            bgType: nil,
            bgColors: nil,
            borderType: gradientDirection,
            borderColors: gradientColors,
            borderWidth: lineWidth,
            radius: cornerRadius
        )
    }
}
