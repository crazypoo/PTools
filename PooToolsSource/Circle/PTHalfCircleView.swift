//
//  PTHalfCircleView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@objc public enum LXHalfCircleViewType:Int,CaseIterable {
    case Left
    case Right
    case Up
    case Down
}

@objcMembers
public class PTHalfCircleView: UIView {
    public var circleType:LXHalfCircleViewType = .Right
    public var diameter:CGFloat = 19
    public var circleColor:UIColor = .systemRed
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
                
        // 定义半圆的矩形范围
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        
        // 开始一个新的绘制路径
        context.beginPath()
        
        // 根据方向确定起始和结束角度
        let startAngle: CGFloat
        let endAngle: CGFloat
        var centerX: CGFloat = rect.midX
        var centerY: CGFloat = rect.midY
        switch circleType {
        case .Right:
            startAngle = -CGFloat.pi / 2 // -90度
            endAngle = CGFloat.pi / 2    // 90度
        case .Left:
            startAngle = CGFloat.pi / 2   // 90度
            endAngle = -CGFloat.pi / 2   // -90度
        case .Up:
            startAngle = 0
            endAngle = CGFloat.pi
            centerX = rect.midX
            centerY = rect.maxY
        case .Down:
            startAngle = CGFloat.pi
            endAngle = 0
            centerX = rect.midX
            centerY = rect.minY
        }
        
        // 添加半圆的路径到当前的绘制路径中
        context.addArc(center: CGPoint(x: centerX, y: centerY),
                        radius: diameter / 2,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: true)
        
        // 将绘制路径闭合
        context.closePath()
        
        // 设置绘制样式
        context.setFillColor(circleColor.cgColor)
        
        // 填充路径
        context.fillPath()
    }
}
