//
//  PTMentSheetArrowButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/31.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public class PTMenuSheetArrowButton: UIButton {
    
    private typealias ArrowPathPair = (top: CGPath, bottom: CGPath)
    
    // MARK: - Public properties
    
    public var animationDuration: TimeInterval = 0.2
    public var arrowInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    
    public var arrowWidth: CGFloat = 1 {
        didSet {
            topLineLayer.lineWidth = arrowWidth
            bottomLineLayer.lineWidth = arrowWidth
        }
    }
    
    public var arrowColor: UIColor = .black {
        didSet {
            topLineLayer.strokeColor = arrowColor.cgColor
            bottomLineLayer.strokeColor = arrowColor.cgColor
        }
    }
    
    public var isArrowsHidden = false  {
        didSet {
            topLineLayer.isHidden = isArrowsHidden
            bottomLineLayer.isHidden = isArrowsHidden
        }
    }
    
    // MARK: - Private properties
    
    private lazy var topLineLayer: CAShapeLayer = makeArrowLayer()
    private lazy var bottomLineLayer: CAShapeLayer = makeArrowLayer()
    
    // MARK: - Lifecycle
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        // 初次繪製箭頭方向（可改為你預設想要的方向）
        if topLineLayer.path == nil || bottomLineLayer.path == nil {
            showDownArrow()
        }
    }

    // MARK: - Public API
    
    public func showUpArrow()       { animateArrow(with: upArrowPaths()) }
    public func showDownArrow()     { animateArrow(with: downArrowPaths()) }
    public func showLeftArrow()     { animateArrow(with: leftArrowPaths()) }
    public func showRightArrow()    { animateArrow(with: rightArrowPaths()) }
  
    // MARK: - Private helpers
    
    private func animateArrow(with paths: ArrowPathPair) {
        let keyPath = "path"
        
        topLineLayer.add(makeAnimation(keyPath: keyPath, fromValue: topLineLayer.path, toValue: paths.top), forKey: keyPath)
        bottomLineLayer.add(makeAnimation(keyPath: keyPath, fromValue: bottomLineLayer.path, toValue: paths.bottom), forKey: keyPath)
        
        topLineLayer.path = paths.top
        bottomLineLayer.path = paths.bottom
    }
    
    private func makeAnimation(keyPath: String, fromValue: Any?, toValue: Any?) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = animationDuration
        animation.fromValue = fromValue
        animation.toValue = toValue
        return animation
    }
    
    private func makeArrowLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.strokeColor = arrowColor.cgColor
        layer.lineWidth = arrowWidth
        layer.lineJoin = .round
        layer.lineCap = .round
        self.layer.addSublayer(layer)
        return layer
    }
    
    // MARK: - Arrow path builders
    
    private func upArrowPaths() -> ArrowPathPair {
        let centerX = bounds.midX
        let centerY = bounds.midY
        let verticalInset = bounds.height / 3
        let horizontalInset = bounds.width / 2.5
        
        let point1 = CGPoint(x: centerX - horizontalInset + arrowInsets.left, y: centerY + verticalInset - arrowInsets.bottom)
        let point2 = CGPoint(x: centerX + horizontalInset - arrowInsets.right, y: centerY + verticalInset - arrowInsets.bottom)
        let midPoint = CGPoint(x: centerX, y: centerY - verticalInset + arrowInsets.top)
        
        return arrowPaths(firstPoint: point1, secondPoint: point2, centerPoint: midPoint)
    }
    
    private func downArrowPaths() -> ArrowPathPair {
        let centerX = bounds.midX
        let centerY = bounds.midY
        let verticalInset = bounds.height / 3
        let horizontalInset = bounds.width / 2.5
        
        let point1 = CGPoint(x: centerX - horizontalInset + arrowInsets.left, y: centerY - verticalInset + arrowInsets.top)
        let point2 = CGPoint(x: centerX + horizontalInset - arrowInsets.right, y: centerY - verticalInset + arrowInsets.top)
        let midPoint = CGPoint(x: centerX, y: centerY + verticalInset - arrowInsets.bottom)
        
        return arrowPaths(firstPoint: point1, secondPoint: point2, centerPoint: midPoint)
    }
    
    private func leftArrowPaths() -> ArrowPathPair {
        let centerX = bounds.midX
        let centerY = bounds.midY
        let verticalInset = bounds.height / 2.5
        let horizontalInset = bounds.width / 3
        
        let point1 = CGPoint(x: centerX + horizontalInset - arrowInsets.right, y: centerY - verticalInset + arrowInsets.top)
        let point2 = CGPoint(x: centerX + horizontalInset - arrowInsets.right, y: centerY + verticalInset - arrowInsets.bottom)
        let midPoint = CGPoint(x: centerX - horizontalInset + arrowInsets.left, y: centerY)
        
        return arrowPaths(firstPoint: point1, secondPoint: point2, centerPoint: midPoint)
    }
    
    private func rightArrowPaths() -> ArrowPathPair {
        let centerX = bounds.midX
        let centerY = bounds.midY
        let verticalInset = bounds.height / 2.5
        let horizontalInset = bounds.width / 3
        
        let point1 = CGPoint(x: centerX - horizontalInset + arrowInsets.left, y: centerY - verticalInset + arrowInsets.top)
        let point2 = CGPoint(x: centerX - horizontalInset + arrowInsets.left, y: centerY + verticalInset - arrowInsets.bottom)
        let midPoint = CGPoint(x: centerX + horizontalInset - arrowInsets.right, y: centerY)
        
        return arrowPaths(firstPoint: point1, secondPoint: point2, centerPoint: midPoint)
    }
    
    private func arrowPaths(firstPoint: CGPoint, secondPoint: CGPoint, centerPoint: CGPoint) -> ArrowPathPair {
        let gravityCenter = CGPoint(
            x: (firstPoint.x + secondPoint.x + centerPoint.x) / 3,
            y: (firstPoint.y + secondPoint.y + centerPoint.y) / 3
        )
        let offset = CGPoint(x: bounds.midX - gravityCenter.x, y: bounds.midY - gravityCenter.y)
        
        let topPath = buildLine(from: firstPoint, to: centerPoint, offset: offset)
        let bottomPath = buildLine(from: secondPoint, to: centerPoint, offset: offset)
        
        return (top: topPath, bottom: bottomPath)
    }
    
    private func buildLine(from start: CGPoint, to end: CGPoint, offset: CGPoint) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: start.x + offset.x, y: start.y + offset.y))
        path.addLine(to: CGPoint(x: end.x + offset.x, y: end.y + offset.y))
        return path
    }
}
