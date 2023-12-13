//
//  UIBezierPath+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

public extension UIBezierPath {
    
    convenience init(from: CGPoint,
                     to otherPoint: CGPoint) {
        self.init()
        move(to: from)
        addLine(to: otherPoint)
    }
    
    convenience init(points: [CGPoint]) {
        self.init()
        if !points.isEmpty {
            move(to: points[0])
            for point in points[1...] {
                addLine(to: point)
            }
        }
    }
    
    @discardableResult
    func move(_ x: CGFloat, _ y: CGFloat) -> UIBezierPath{
        self.move(to: CGPoint(x: x, y: y))
        return self
    }
    
    @discardableResult
    func line(_ x: CGFloat, _ y: CGFloat) -> UIBezierPath {
        self.addLine(to: CGPoint(x: x, y: y))
        return self
    }
    
    @discardableResult
    func closed() -> UIBezierPath {
        self.close()
        return self
    }
    
    @discardableResult
    func strokeFill(_ color: UIColor, lineWidth: CGFloat = 1) -> UIBezierPath {
        color.set()
        self.lineWidth = lineWidth
        self.stroke()
        self.fill()
        return self
    }
    
    @discardableResult
    func stroke(_ color: UIColor, lineWidth: CGFloat = 1) -> UIBezierPath {
        color.set()
        self.lineWidth = lineWidth
        self.stroke()
        return self
    }
}
#endif
