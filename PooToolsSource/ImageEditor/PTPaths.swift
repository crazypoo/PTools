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
        
        path = UIBezierPath()
        path.lineWidth = pathWidth / ratio
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: CGPoint(x: startPoint.x / ratio, y: startPoint.y / ratio))
        
        points.append(startPoint)
        self.ratio = ratio
        index = Self.pathIndex
        Self.pathIndex += 1
        
        super.init()
    }
    
    func addLine(to point: CGPoint) {
        points.append(point)
        
        func divRatio(_ point: CGPoint) -> CGPoint {
            return CGPoint(x: point.x / ratio, y: point.y / ratio)
        }
        
        guard points.count >= 4 else {
            path.addLine(to: divRatio(point))
            return
        }
        
        path.removeAllPoints()
        
        path.move(to: divRatio(points[0]))
        path.addLine(to: divRatio(points[1]))
        
        let granularity = 4
        for i in 3..<points.count {
            let p0 = points[i - 3]
            let p1 = points[i - 2]
            let p2 = points[i - 1]
            let p3 = points[i]
            
            for i in 1..<granularity {
                let t = CGFloat(i) * (1 / CGFloat(granularity))
                let tt = t * t
                let ttt = tt * t

                var point = CGPoint.zero
                point.x = 0.5 * (
                    2 * p1.x + (p2.x - p0.x) * t +
                    (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * tt +
                    (3 * p1.x - p0.x - 3 * p2.x + p3.x) * ttt
                )
                point.y = 0.5 * (
                    2 * p1.y + (p2.y - p0.y) * t +
                    (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * tt +
                    (3 * p1.y - p0.y - 3 * p2.y + p3.y) * ttt
                )
                path.addLine(to: divRatio(point))
            }
            
            path.addLine(to: divRatio(p2))
        }
        
        path.addLine(to: divRatio(points[points.count - 1]))
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

// MARK: 马赛克path
public class PTMosaicPath: NSObject {
    let path: UIBezierPath
    
    let ratio: CGFloat
    
    let startPoint: CGPoint
    
    var linePoints: [CGPoint] = []
    
    public init(pathWidth: CGFloat, ratio: CGFloat, startPoint: CGPoint) {
        path = UIBezierPath()
        path.lineWidth = pathWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: startPoint)
        
        self.ratio = ratio
        self.startPoint = CGPoint(x: startPoint.x / ratio, y: startPoint.y / ratio)
        
        super.init()
    }
    
    func addLine(to point: CGPoint) {
        path.addLine(to: point)
        linePoints.append(CGPoint(x: point.x / ratio, y: point.y / ratio))
    }
}
