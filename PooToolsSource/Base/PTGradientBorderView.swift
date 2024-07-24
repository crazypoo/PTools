//
//  PTGradientBorderView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/7/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

open class PTGradientBorderView: UIView {
    
    // 属性定义
    open var cornerRadius: CGFloat = 8 {
        didSet {
            setup()
        }
    }
    
    open var lineWidth: CGFloat = 5 {
        didSet {
            setup()
        }
    }
    
    open var gradientColors: [UIColor] = [UIColor.red, UIColor.blue] {
        didSet {
            setup()
        }
    }
    
    open var gradientDirection: Imagegradien = .LeftToRight {
        didSet {
            setup()
        }
    }
        
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // 设置视图的圆角
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true

        // 创建一个CAShapeLayer来绘制圆角矩形路径
        let shapeLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius)
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        
        // 创建一个渐变图层
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = gradientColors.map { $0.cgColor }
        
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
        
        // 创建一个用渐变图层填充的图层蒙版
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.clear.cgColor
        maskLayer.strokeColor = UIColor.black.cgColor
        maskLayer.lineWidth = shapeLayer.lineWidth
        gradientLayer.mask = maskLayer
        
        // 清除现有图层，添加新的图层
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.layer.addSublayer(gradientLayer)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        // 更新路径和渐变图层框架，以确保在视图大小变化时正确显示
        setup()
    }
}
