//
//  CGPoint+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(CoreGraphics)
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension CGPoint {
    var nsValue: NSValue {
        #if os(iOS)
        return NSValue(cgPoint: self)
        #else
        return NSValue(point: NSPointFromCGPoint(self))
        #endif
    }

    func distance(from point: CGPoint) -> CGFloat {
        CGPoint.distance(from: self, to: point)
    }
    
    static func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }
    
    static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        CGPoint(x: point.x * scalar, y: point.y * scalar)
    }

    static func *= (point: inout CGPoint, scalar: CGFloat) {
        point = point * scalar
    }

    static func * (scalar: CGFloat, point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * scalar, y: point.y * scalar)
    }
    
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        CGPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }

    /// 两个CGPoint之间的差
    /// - Parameters:
    ///   - lhs: 左边的点
    ///   - rhs: 右边的点
    /// - Returns: 结果
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        CGPoint(x: left.x - right.x, y: left.y - right.y)
    }

    static func -= (left: inout CGPoint, right: CGPoint) {
        left = left - right
    }

    /// 计算两个 CGPoint 的中点
    /// - Parameter point: 另外一个点
    /// - Returns: 中间点
    func midPoint(by point: CGPoint) -> CGPoint {
        return CGPoint(x: (self.x + point.x) / 2, y: (self.y + point.y) / 2)
    }
}
#endif
