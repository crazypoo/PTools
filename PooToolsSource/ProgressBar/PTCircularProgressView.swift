//
//  PTCircularProgressView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

public enum PTCircularProgressStyle {
    case loop /// 环形线条
    case pie  /// 饼状图
}

/// 专为 PTProgressHUD 打造的环形/饼状进度视图
public class PTCircularProgressView: UIView {
    
    public var style: PTCircularProgressStyle = .loop
    
    /// 进度颜色，会跟随 HUD 的 indicatorColor
    public var progressColor: UIColor = .label {
        didSet { setNeedsDisplay() }
    }
    
    /// 进度值 (0.0 ~ 1.0)
    public var progress: CGFloat = 0 {
        didSet {
            let _ = max(0, min(1, progress))
            // 确保在主线程刷新 UI
            if Thread.isMainThread {
                self.setNeedsDisplay()
            } else {
                DispatchQueue.main.async { self.setNeedsDisplay() }
            }
        }
    }
    
    public init(style: PTCircularProgressStyle) {
        self.style = style
        super.init(frame: .zero)
        self.backgroundColor = .clear // 必须透明
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let xCenter = rect.size.width * 0.5
        let yCenter = rect.size.height * 0.5
        // 设置绘制颜色为传入的主题色
        progressColor.set()
        
        // 统一计算圆弧的起点 (12点钟方向)
        let startAngle: CGFloat = -.pi * 0.5
        let endAngle = startAngle + (progress * .pi * 2)
        
        let padding: CGFloat = 2.0 // 边缘留白
        
        switch style {
        case .pie:
            let radius = min(xCenter, yCenter) - padding
            let w = radius * 2
            let x = (rect.size.width - w) * 0.5
            let y = (rect.size.height - w) * 0.5
            
            // 1. 画外部空心圆圈 (边界)
            ctx.setLineWidth(2)
            ctx.addEllipse(in: CGRect(x: x, y: y, width: w, height: w))
            ctx.strokePath()
            
            // 2. 画内部进度扇形
            // 扇形半径稍微比外圈小一点，留出中间的缝隙
            let innerRadius = radius - 3
            ctx.move(to: CGPoint(x: xCenter, y: yCenter))
            ctx.addArc(center: CGPoint(x: xCenter, y: yCenter), radius: innerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            ctx.closePath()
            ctx.fillPath()
            
        case .loop:
            ctx.setLineWidth(4) // 环形的线条粗细
            ctx.setLineCap(.round)
            
            let radius = min(rect.size.width, rect.size.height) * 0.5 - padding - 2 // 减去线宽一半防止裁剪
            ctx.addArc(center: CGPoint(x: xCenter, y: yCenter), radius: radius, startAngle: startAngle, endAngle: max(endAngle, startAngle + 0.05), clockwise: false)
            ctx.strokePath()
        }
    }
}
