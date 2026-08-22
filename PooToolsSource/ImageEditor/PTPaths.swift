//
//  PTPaths.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

// MARK: 涂鸦path
public class PTDrawPath: NSObject {
    @MainActor private static var pathIndex = 0
    
    private let pathColor: UIColor
    private let ratio: CGFloat
    private var points: [CGPoint] = []
    
    let index: Int
    var path: UIBezierPath

    var hasMovement: Bool { points.count > 1 }
    
    // 🌟 1. 新增：标记这条路径是不是橡皮擦
    public var isEraser = false
        
    public override var hash: Int {
        return index.hashValue
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PTDrawPath else { return false }
        return self.index == other.index
    }

    // 初始化方法中去掉了 defaultLinePath 参数，因为用不到 bgPath 了
    @MainActor init(pathColor: UIColor, pathWidth: CGFloat, ratio: CGFloat, startPoint: CGPoint) {
        self.pathColor = pathColor
        self.ratio = max(abs(ratio), CGFloat.ulpOfOne)
        
        path = UIBezierPath()
        path.lineWidth = pathWidth / self.ratio
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: CGPoint(x: startPoint.x / self.ratio, y: startPoint.y / self.ratio))
        
        points.append(startPoint)
        index = Self.pathIndex
        Self.pathIndex += 1
        
        super.init()
    }
    
    func addLine(to point: CGPoint) {
        func divRatio(_ point: CGPoint) -> CGPoint {
            return CGPoint(x: point.x / ratio, y: point.y / ratio)
        }

        guard let previousPoint = points.last else {
            points.append(point)
            path.move(to: divRatio(point))
            return
        }

        points.append(point)
        if points.count == 2 {
            path.addLine(to: divRatio(point))
            return
        }

        let midpoint = CGPoint(x: (previousPoint.x + point.x) * 0.5,
                               y: (previousPoint.y + point.y) * 0.5)
        path.addQuadCurve(to: divRatio(midpoint), controlPoint: divRatio(previousPoint))
    }

    func finish() {
        guard let lastPoint = points.last else { return }
        path.addLine(to: CGPoint(x: lastPoint.x / ratio, y: lastPoint.y / ratio))
    }
    
    // 🌟 2. 核心渲染魔法
    func drawPath() {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if isEraser {
            // 如果是橡皮擦，设置混合模式为透明抠除
            context.setBlendMode(.clear)
            UIColor.clear.set()
        } else {
            // 如果是正常画笔，使用正常混合模式
            context.setBlendMode(.normal)
            pathColor.set()
        }
        
        path.stroke()
        
        // 🌟 3. 必须恢复模式，否则后面的普通画笔也会变成橡皮擦！
        context.setBlendMode(.normal)
    }
}

public extension PTDrawPath {
    static func ==(lhs: PTDrawPath, rhs: PTDrawPath) -> Bool {
        return lhs.index == rhs.index
    }
}
