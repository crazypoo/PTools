//
//  PTListAnimationEnum.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public enum PTListAnimationDirection:Int,CaseIterable {
    case top
    case left
    case right
    case bottom
    
    var isVertical:Bool {
        switch self {
        case .top,.bottom:
            true
        default:
            false
        }
    }
    
    var sign:CGFloat {
        switch self {
        case .top,.left:
            -1
        default:
            1
        }
    }
    
    static func random() -> PTListAnimationDirection {
        allCases.randomElement()!
    }
}

public enum PTListAnimationType:PTListAnimationProtocols {
    
    case from(direcation:PTListAnimationDirection,offset:CGFloat)
    case vector(CGVector)
    case zoom(scale:CGFloat)
    case rotate(angle:CGFloat)
    case identity
    
    public var initialTransform: CGAffineTransform {
        switch self {
        case .from(let direcation, let offset):
            let sign = direcation.sign
            if direcation.isVertical {
                return CGAffineTransform(translationX: 0, y: offset * sign)
            }
            return CGAffineTransform(translationX: offset * sign, y: 0)
        case .vector(let cGVector):
            return CGAffineTransform(translationX: cGVector.dx, y: cGVector.dy)
        case .zoom(let scale):
            return CGAffineTransform(scaleX: scale, y: scale)
        case .rotate(let angle):
            return CGAffineTransform(rotationAngle: angle)
        case .identity:
            return .identity
        }
    }
    
    public static func random() -> PTListAnimationType {
        let index = Int.random(in: 0..<3 )
        if index == 1 {
            return PTListAnimationType.vector(CGVector(dx: .random(in: -10...10), dy: .random(in: -30...30)))
        } else if index == 2 {
            let scale = Double.random(in: 0...PTListAnimationConfig.maxZoomScale)
            return PTListAnimationType.zoom(scale: CGFloat(scale))
        }
        let angle = CGFloat.random(in: -PTListAnimationConfig.maxRotationAngle...PTListAnimationConfig.maxRotationAngle)
        return PTListAnimationType.rotate(angle: angle)
    }
}
