//
//  PTCycleLoadingView.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/2.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTCycleLoadingView: UIView {

    // MARK: - 公开属性
    open var lineWidth: CGFloat = 1 {
        didSet {
            shapeLayer.lineWidth = lineWidth
        }
    }
    
    open var lineColor: UIColor = .lightGray {
        didSet {
            shapeLayer.strokeColor = lineColor.cgColor
        }
    }
    
    // 改为只读的外部访问，防止外部错误修改状态
    open private(set) var isAnimation: Bool = false
    
    // MARK: - 私有属性
    // 使用 CAShapeLayer 替代 draw(_:)，利用 GPU 硬件加速提升性能
    private lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineCap = .round // 圆角端点，让加载动画看起来更平滑
        return layer
    }()
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = lineColor.cgColor
        // 将 shapeLayer 添加到视图的 layer 中
        layer.addSublayer(shapeLayer)
    }
    
    // 当视图大小改变时，更新 layer 的框架和路径
    public override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        updatePath()
    }
    
    // 生成完整的圆弧路径
    private func updatePath() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.width / 2 - lineWidth
        let startAngle = angle(float: 120)
        let endAngle = startAngle + angle(float: 330) // 画一段 330 度的弧
        
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        shapeLayer.path = path.cgPath
    }
    
    // MARK: - 动画控制
    public func startAnimation() {
        guard !isAnimation else { return }
        isAnimation = true
        
        self.alpha = 1
        shapeLayer.removeAllAnimations()
        layer.removeAllAnimations()
        
        // 1. 路径绘制动画 (替代原来的 Timer 逻辑)
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 1
        strokeAnimation.duration = 0.6 // 动画时长，可根据需要调整
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shapeLayer.add(strokeAnimation, forKey: "strokeEndAnimation")
        
        // 2. 旋转动画 (保持原来的效果)
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = CGFloat.pi * 2
        rotateAnimation.duration = 1
        rotateAnimation.repeatCount = .infinity // 无限循环
        layer.add(rotateAnimation, forKey: "rotationAnimation")
    }
    
    public func stopAnimation(handle: PTActionTask? = nil) {
        guard isAnimation else {
            handle?()
            return
        }
        isAnimation = false
        
        // 渐隐视图后移除所有动画
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.shapeLayer.removeAllAnimations()
            self.layer.removeAllAnimations()
            self.alpha = 1 // 恢复透明度供下次使用
            handle?()
        }
    }
    
    // MARK: - 辅助方法
    private func angle(float: CGFloat) -> CGFloat {
        return .pi * 2 / 360 * float
    }
}
