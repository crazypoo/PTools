//
//  CGRect+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(CoreGraphics)
import CoreGraphics
import UIKit

public extension CGRect {
    
    var center: CGPoint {
        .init(x: midX, y: midY)
    }
    
    mutating func setMaxX(_ value: CGFloat) {
        origin.x = value - width
    }
    
    mutating func setMaxY(_ value: CGFloat) {
        origin.y = value - height
    }
    
    mutating func setWidth(_ width: CGFloat) {
        if width == self.width { return }
        self = CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }
    
    mutating func setHeight(_ height: CGFloat) {
        if height == self.height { return }
        self = CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }
    
    // MARK: - Init
    
    init(center: CGPoint, size: CGSize) {
        let origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
        self.init(origin: origin, size: size)
    }
    
    init(x: CGFloat, maxY: CGFloat, width: CGFloat, height: CGFloat) {
        self.init(x: x, y: .zero, width: width, height: height)
        setMaxY(maxY)
    }
    
    init(maxX: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.init(x: .zero, y: y, width: width, height: height)
        setMaxX(maxX)
    }
    
    init(maxX: CGFloat, maxY: CGFloat, width: CGFloat, height: CGFloat) {
        self.init(x: .zero, y: .zero, width: width, height: height)
        setMaxX(maxX)
        setMaxY(maxY)
    }
    
    init(x: CGFloat, y: CGFloat, side: CGFloat) {
        self.init(x: x, y: y, width: side, height: side)
    }
    
    init(side: CGFloat) {
        self.init(x: .zero, y: .zero, width: side, height: side)
    }
}

extension CGRect: PTNumberValueAdapterable {
    public typealias PTNumberValueAdapterType = CGRect
    public var adapter: CGRect {
        /// 不参与屏幕rect
        if self == UIScreen.main.bounds {
            return self
        }

        let scale = adapterScale()
        let x = origin.x * scale
        let y = origin.y * scale
        let width = size.width * scale
        let height = size.height * scale
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
#endif
