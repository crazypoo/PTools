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
            // 只需要标记需要重新布局，系统会在下一次绘制周期自动调用 layoutSubviews
            setNeedsLayout()
        }
    }
    
    open var lineWidth: CGFloat = 5 {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var gradientColors: [UIColor] = [UIColor.red, UIColor.blue] {
        didSet {
            // 颜色变化不影响布局，直接更新现有 Layer 的属性，性能极高
            updateGradientColors()
        }
    }
    
    // 注意：假设 Imagegradien 是你在其他地方定义的枚举
    open var gradientDirection: Imagegradien = .LeftToRight {
        didSet {
            updateGradientDirection()
        }
    }
    
    // MARK: - 图层重用 (提升性能的核心)
    // 只创建一次 Layer，后续只更新它们的属性，避免重复初始化
    private let gradientLayer = CAGradientLayer()
    private let borderMaskLayer = CAShapeLayer()
    
    // MARK: - 初始化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }
    
    // MARK: - 核心方法
    
    private func initialSetup() {
        // 配置蒙版层 (Mask Layer)
        borderMaskLayer.fillColor = UIColor.clear.cgColor
        borderMaskLayer.strokeColor = UIColor.black.cgColor // 颜色不重要，Mask 只看透明度
        
        // 配置渐变层并设置蒙版
        gradientLayer.mask = borderMaskLayer
        
        // 将渐变层添加到视图最底层，确保不会遮挡你未来可能添加的子视图
        self.layer.insertSublayer(gradientLayer, at: 0)
        
        // 初始化颜色和方向
        updateGradientColors()
        updateGradientDirection()
    }
    
    private func updateGradientColors() {
        gradientLayer.colors = gradientColors.map { $0.cgColor }
    }
    
    private func updateGradientDirection() {
        switch gradientDirection {
        case .LeftToRight:
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        case .TopToBottom:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        case .BottomToTop:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        case .RightToLeft:
            gradientLayer.startPoint = CGPoint(x: 1, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 0, y: 0.5)
        }
    }
    
    // 系统在视图 Frame 改变时会自动调用此方法
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // 设置自身的圆角属性
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
        
        // 关键修复：计算向内缩进的路径，防止一半的边框被 masksToBounds 裁剪
        let inset = lineWidth / 2.0
        let pathRect = self.bounds.insetBy(dx: inset, dy: inset)
        
        // 调整圆角大小以适应缩进后的路径，防止负数产生异常
        let adjustedCornerRadius = max(cornerRadius - inset, 0)
        
        // 更新路径
        let path = UIBezierPath(roundedRect: pathRect, cornerRadius: adjustedCornerRadius)
        borderMaskLayer.path = path.cgPath
        borderMaskLayer.lineWidth = lineWidth
        
        // 更新渐变层大小
        gradientLayer.frame = self.bounds
    }
}
