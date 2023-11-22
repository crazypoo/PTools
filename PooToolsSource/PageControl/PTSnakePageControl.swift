//
//  PTSnakePageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
open class PTSnakePageControl: UIView {
    
    // MARK: - PageControl
    open var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    open var progress: CGFloat = 0 {
        didSet {
            layoutActivePageIndicator(progress)
        }
    }
    open var currentPage: Int {
        Int(round(progress))
    }
    
    // MARK: - Appearance
    
    open var activeTint: UIColor = UIColor.white {
        didSet {
            activeLayer.backgroundColor = activeTint.cgColor
        }
    }
    open var inactiveTint: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet {
            inactiveLayers.forEach { $0.backgroundColor = inactiveTint.cgColor }
        }
    }
    open var indicatorPadding: CGFloat = 10 {
        didSet {
            layoutInactivePageIndicators(inactiveLayers)
        }
    }
    open var indicatorRadius: CGFloat = 5 {
        didSet {
            layoutInactivePageIndicators(inactiveLayers)
        }
    }
    
    fileprivate var indicatorDiameter: CGFloat {
        indicatorRadius * 2
    }
    fileprivate var inactiveLayers = [CALayer]()
    fileprivate lazy var activeLayer: CALayer = { [unowned self] in
        let layer = CALayer()
        layer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: indicatorDiameter, height: indicatorDiameter))
        layer.backgroundColor = activeTint.cgColor
        layer.cornerRadius = indicatorRadius
        layer.actions = [
            "bounds": NSNull(),
            "frame": NSNull(),
            "position": NSNull()]
        return layer
        }()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        pageCount = 0
        progress = 0
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
        inactiveLayers.forEach { $0.removeFromSuperlayer() }
        inactiveLayers = [CALayer]()
        // add layers for new page count
        inactiveLayers = stride(from: 0, to:count, by:1).map { _ in
            let layer = CALayer()
            layer.backgroundColor = inactiveTint.cgColor
            self.layer.addSublayer(layer)
            return layer
        }
        layoutInactivePageIndicators(inactiveLayers)
        // ensure active page indicator is on top
        layer.addSublayer(activeLayer)
        layoutActivePageIndicator(progress)
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - Layout
    
    fileprivate func layoutActivePageIndicator(_ progress: CGFloat) {
        // ignore if progress is outside of page indicators' bounds
        guard progress >= 0 && progress <= CGFloat(pageCount - 1) else { return }
        let denormalizedProgress = progress * (indicatorDiameter + indicatorPadding)
        let distanceFromPage = abs(round(progress) - progress)
        let width = indicatorDiameter + indicatorPadding * (distanceFromPage * 2)
        var newFrame = CGRect(x: 0, y: activeLayer.frame.origin.y, width: width, height: indicatorDiameter)
        newFrame.origin.x = denormalizedProgress
        activeLayer.cornerRadius = indicatorRadius
        activeLayer.frame = newFrame
    }
    
    fileprivate func layoutInactivePageIndicators(_ layers: [CALayer]) {
        let layerDiameter = indicatorRadius * 2
        var layerFrame = CGRect(x: 0, y: 0, width: layerDiameter, height: layerDiameter)
        layers.forEach { layer in
            layer.cornerRadius = indicatorRadius
            layer.frame = layerFrame
            layerFrame.origin.x += layerDiameter + indicatorPadding
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: CGFloat(inactiveLayers.count) * indicatorDiameter + CGFloat(inactiveLayers.count - 1) * indicatorPadding, height: indicatorDiameter)
    }
}
