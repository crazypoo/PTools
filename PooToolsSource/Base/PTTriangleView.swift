//
//  PTTriangleView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/7/11.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

public enum PTTriangleDirection {
    case up, down, left, right
}

public class PTTriangleView: UIView {
    public var fillColor: UIColor = .systemBlue
    public var direction: PTTriangleDirection = .up

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let path = UIBezierPath()

        switch direction {
        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))         // 上顶点
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))      // 左下
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))      // 右下
        case .down:
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))         // 下顶点
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))      // 左上
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))      // 右上
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))         // 左顶点
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))      // 右上
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))      // 右下
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))         // 右顶点
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))      // 左上
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))      // 左下
        }

        path.close()

        context.addPath(path.cgPath)
        context.setFillColor(fillColor.cgColor)
        context.fillPath()
    }
}
