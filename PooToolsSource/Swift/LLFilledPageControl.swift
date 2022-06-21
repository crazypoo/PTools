//
//  LLFilledPageControl.swift
//  LL 使用备注
//  https://github.com/popwarsweet/PageControls
//
//  Created by Kyle Zaragoza on 8/6/16.
//  Copyright © 2016 Kyle Zaragoza. All rights reserved.
//

import UIKit

open class LLFilledPageControl: UIView {
    
    // MARK: - PageControl
    
    
    open var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    open var progress: CGFloat = 0 {
        didSet {
            updateActivePageIndicatorMasks(forProgress: progress)
        }
    }
    open var currentPage: Int {
        return Int(round(progress))
    }
    
    
    // MARK: - Appearance
    
    override open var tintColor: UIColor! {
        didSet {
            inactiveLayers.forEach() { $0.backgroundColor = tintColor.cgColor }
        }
    }
    open var inactiveRingWidth: CGFloat = 1 {
        didSet {
            updateActivePageIndicatorMasks(forProgress: progress)
        }
    }
    open var indicatorPadding: CGFloat = 8 {
        didSet {
            layoutPageIndicators(inactiveLayers)
        }
    }
    open var indicatorRadius: CGFloat = 4 {
        didSet {
            layoutPageIndicators(inactiveLayers)
        }
    }
    
    fileprivate var indicatorDiameter: CGFloat {
        return indicatorRadius * 2
    }
    
    fileprivate var inactiveLayers = [CALayer]()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        pageCount = 0
        progress = 0
        inactiveRingWidth = 1
        indicatorPadding = 8
        indicatorRadius = 4
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - State Update
    
    fileprivate func updateNumberOfPages(_ count: Int) {
        // no need to update
        guard count != inactiveLayers.count else { return }
        // reset current layout
        inactiveLayers.forEach() { $0.removeFromSuperlayer() }
        inactiveLayers = [CALayer]()
        // add layers for new page count
        inactiveLayers = stride(from: 0, to:count, by:1).map() { _ in
            let layer = CALayer()
            layer.backgroundColor = self.tintColor.cgColor
            self.layer.addSublayer(layer)
            return layer
        }
        layoutPageIndicators(inactiveLayers)
        updateActivePageIndicatorMasks(forProgress: progress)
        self.invalidateIntrinsicContentSize()
    }
    
    
    // MARK: - Layout
    
    fileprivate func updateActivePageIndicatorMasks(forProgress progress: CGFloat) {
        // ignore if progress is outside of page indicators' bounds
        guard progress >= 0 && progress <= CGFloat(pageCount - 1) else { return }

        // mask rect w/ default stroke width
        let insetRect = CGRect(x: 0, y: 0, width: indicatorDiameter, height: indicatorDiameter).insetBy(dx: inactiveRingWidth, dy: inactiveRingWidth)
        let leftPageFloat = trunc(progress)
        let leftPageInt = Int(progress)
        
        // inset right moving page indicator
        let spaceToMove = insetRect.width / 2
        let percentPastLeftIndicator = progress - leftPageFloat
        let additionalSpaceToInsetRight = spaceToMove * percentPastLeftIndicator
        let closestRightInsetRect = insetRect.insetBy(dx: additionalSpaceToInsetRight, dy: additionalSpaceToInsetRight)
        
        // inset left moving page indicator
        let additionalSpaceToInsetLeft = (1 - percentPastLeftIndicator) * spaceToMove
        let closestLeftInsetRect = insetRect.insetBy(dx: additionalSpaceToInsetLeft, dy: additionalSpaceToInsetLeft)
        
        // adjust masks
        for (idx, layer) in inactiveLayers.enumerated() {
            let maskLayer = CAShapeLayer()
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
            
            let boundsPath = UIBezierPath(rect: layer.bounds)
            let circlePath: UIBezierPath
            if leftPageInt == idx {
                circlePath = UIBezierPath(ovalIn: closestLeftInsetRect)
            } else if leftPageInt + 1 == idx {
                circlePath = UIBezierPath(ovalIn: closestRightInsetRect)
            } else {
                circlePath = UIBezierPath(ovalIn: insetRect)
            }
            boundsPath.append(circlePath)
            maskLayer.path = boundsPath.cgPath
            layer.mask = maskLayer
        }
    }
    
    fileprivate func layoutPageIndicators(_ layers: [CALayer]) {
        let layerDiameter = indicatorRadius * 2
        var layerFrame = CGRect(x: 0, y: 0, width: layerDiameter, height: layerDiameter)
        layers.forEach() { layer in
            layer.cornerRadius = self.indicatorRadius
            layer.frame = layerFrame
            layerFrame.origin.x += layerDiameter + indicatorPadding
        }
        // 布局
        let oldFrame = self.frame
        let width = CGFloat(inactiveLayers.count) * layerDiameter + CGFloat(inactiveLayers.count - 1) * indicatorPadding
        self.frame = CGRect.init(x: UIScreen.main.bounds.width / 2 - width / 2, y: oldFrame.origin.y, width: width, height: oldFrame.size.height)
    }
    
    override open var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        let layerDiameter = indicatorRadius * 2
        return CGSize(width: CGFloat(inactiveLayers.count) * layerDiameter + CGFloat(inactiveLayers.count - 1) * indicatorPadding,
                      height: layerDiameter)
    }
}
