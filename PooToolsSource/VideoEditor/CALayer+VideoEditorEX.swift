//
//  CALayer+VideoEditorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

extension CALayer {
    func resizeAndMove(frame: CGRect,
                       duration: TimeInterval = 0.3) {
        let positionAnimation = CABasicAnimation(keyPath: "position")
        positionAnimation.fromValue = value(forKey: "position")
        positionAnimation.toValue = NSValue(cgPoint: CGPoint(x: frame.minX, y: frame.minY))

        let oldBounds = bounds
        var newBounds = oldBounds
        newBounds.size = frame.size

        let boundsAnimation = CABasicAnimation(keyPath: "bounds")
        boundsAnimation.fromValue = NSValue(cgRect: oldBounds)
        boundsAnimation.toValue = NSValue(cgRect: newBounds)

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [positionAnimation, boundsAnimation]
        groupAnimation.fillMode = .forwards
        groupAnimation.duration = duration
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.frame = frame
        add(groupAnimation, forKey: "frame")
    }
    
    func roundCorners(_ radius: CGFloat, _ corners: UIRectCorner) {
        let path = UIBezierPath(roundedRect: bounds,byRoundingCorners: corners,cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.mask = mask
    }
}
