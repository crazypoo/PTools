//
//  PTFrostedGlassView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/22/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import CoreImage

public class PTFrostedGlassView: UIView {
    
    // 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // 配置视图，添加模糊和渐变层
    private func setupView() {
        // 1. 添加模糊效果层
        addBlurEffect()

        // 2. 添加渐变效果层
        addGradientLayer()

        // 3. 设置背景颜色为半透明
        self.backgroundColor = .white.withAlphaComponent(0.01)
    }
    
    // 添加模糊效果
    private func addBlurEffect() {
        // 使用 UIBlurEffect 来创建模糊效果
        let blurEffect = UIBlurEffect(style: .regular)  // 你可以根据需求选择不同的样式 .extraLight, .dark 等
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        // 设置模糊视图的大小与主视图相同
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]  // 支持自适应
        
        // 添加到主视图上
        self.addSubview(blurEffectView)
    }
    
    // 添加渐变效果层，模拟玻璃质感
    private func addGradientLayer() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [
            UIColor(white: 1.0, alpha: 0.15).cgColor,  // 渐变的起始颜色
            UIColor(white: 1, alpha: 0).cgColor   // 渐变的结束颜色
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)  // 渐变起始点
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)    // 渐变结束点
        gradientLayer.locations = [0, 1]                    // 渐变分布
        
        // 使用图层的方式添加渐变
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
}
