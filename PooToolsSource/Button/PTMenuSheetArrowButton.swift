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
    private enum ArrowDirection {
        case up, down, left, right
    }
    
    // MARK: - Public properties
    
    public var animationDuration: TimeInterval = 0.2
    public var arrowInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) {
        didSet {
            needsPathRefresh = true
            setNeedsLayout()
        }
    }
    
    public var arrowWidth: CGFloat = 1 {
        didSet {
            let safeWidth = max(0, arrowWidth)
            topLineLayer.lineWidth = safeWidth
            bottomLineLayer.lineWidth = safeWidth
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
    private var currentDirection: ArrowDirection = .down
    private var needsPathRefresh = true
    private var lastLayoutBounds = CGRect.null
    
    // MARK: - Lifecycle

    public override init(frame: CGRect) {
        super.init(frame: frame)
        registerTraitChanges()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerTraitChanges()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        if needsPathRefresh || bounds != lastLayoutBounds || topLineLayer.path == nil || bottomLineLayer.path == nil {
            lastLayoutBounds = bounds
            updateArrow(direction: currentDirection, animated: false)
        }
    }

    // MARK: - Public API
    
    public func showUpArrow()       { updateArrow(direction: .up, animated: true) }
    public func showDownArrow()     { updateArrow(direction: .down, animated: true) }
    public func showLeftArrow()     { updateArrow(direction: .left, animated: true) }
    public func showRightArrow()    { updateArrow(direction: .right, animated: true) }
  
    // MARK: - Private helpers
    
    private func updateArrow(direction: ArrowDirection, animated: Bool) {
        currentDirection = direction
        let paths: ArrowPathPair
        switch direction {
        case .up: paths = upArrowPaths()
        case .down: paths = downArrowPaths()
        case .left: paths = leftArrowPaths()
        case .right: paths = rightArrowPaths()
        }

        let keyPath = "path"

        let canAnimate = animated &&
            topLineLayer.path != nil &&
            bottomLineLayer.path != nil &&
            animationDuration > 0 &&
            !UIAccessibility.isReduceMotionEnabled
        if canAnimate {
            topLineLayer.add(makeAnimation(keyPath: keyPath, fromValue: topLineLayer.path, toValue: paths.top), forKey: keyPath)
            bottomLineLayer.add(makeAnimation(keyPath: keyPath, fromValue: bottomLineLayer.path, toValue: paths.bottom), forKey: keyPath)
        } else {
            topLineLayer.removeAnimation(forKey: keyPath)
            bottomLineLayer.removeAnimation(forKey: keyPath)
        }
        
        topLineLayer.path = paths.top
        bottomLineLayer.path = paths.bottom
        needsPathRefresh = false
    }
    
    private func makeAnimation(keyPath: String, fromValue: Any?, toValue: Any?) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = max(0, animationDuration)
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

    private func registerTraitChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (button: PTMenuSheetArrowButton, _: UITraitCollection) in
            button.topLineLayer.strokeColor = button.arrowColor.cgColor
            button.bottomLineLayer.strokeColor = button.arrowColor.cgColor
        }
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
