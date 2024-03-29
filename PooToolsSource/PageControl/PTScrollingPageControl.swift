//
//  PTScrollingPageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTScrollingPageControl: UIView {
    // MARK: - PageControl
    
    open var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    open var progress: CGFloat = 0 {
        didSet {
            layoutFor(progress)
        }
    }
    open var currentPage: Int {
        Int(round(progress))
    }
    
    // MARK: - Appearance
    
    open var activeTint: UIColor = UIColor.white {
        didSet {
            ringLayer.borderColor = activeTint.cgColor
            activeLayersContainer.sublayers?.forEach { $0.backgroundColor = activeTint.cgColor }
        }
    }
    open var inactiveTint: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet {
            inactiveLayersContainer.sublayers?.forEach { $0.backgroundColor = inactiveTint.cgColor }
        }
    }
    open var indicatorPadding: CGFloat = 10 {
        didSet {
            if let sublayers = inactiveLayersContainer.sublayers {
                layoutPageIndicators(sublayers, container: inactiveLayersContainer)
            }
            if let sublayers = activeLayersContainer.sublayers {
                layoutPageIndicators(sublayers, container: activeLayersContainer)
            }
        }
    }
    open var ringRadius: CGFloat = 10 {
        didSet {
            // resize view to fit ring
            sizeToFit()
            // adjust size
            ringLayer.cornerRadius = ringRadius
            ringLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: ringDiameter, height: ringDiameter))
            // layout
            center(ringLayer)
        }
    }
    open var indicatorRadius: CGFloat = 5 {
        didSet {
            if let sublayers = inactiveLayersContainer.sublayers {
                layoutPageIndicators(sublayers, container: inactiveLayersContainer)
            }
            if let sublayers = activeLayersContainer.sublayers {
                layoutPageIndicators(sublayers, container: activeLayersContainer)
            }
        }
    }
    
    fileprivate var indicatorDiameter: CGFloat {
        indicatorRadius * 2
    }
    fileprivate var ringDiameter: CGFloat {
        ringRadius * 2
    }
    fileprivate var inactiveLayersContainer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.actions = [
            "bounds": NSNull(),
            "frame": NSNull(),
            "position": NSNull()]
        return layer
    }()
    fileprivate var activeLayersContainer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.actions = [
            "bounds": NSNull(),
            "frame": NSNull(),
            "position": NSNull()]
        return layer
    }()
    fileprivate lazy var ringLayer: CALayer = { [unowned self] in
        let layer = CALayer()
        layer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: ringDiameter, height: ringDiameter))
        layer.backgroundColor = UIColor.clear.cgColor
        layer.cornerRadius = ringRadius
        layer.borderColor = activeTint.cgColor
        layer.borderWidth = 1
        layer.actions = [
            "bounds": NSNull(),
            "frame": NSNull(),
            "position": NSNull()]
        return layer
    }()
    fileprivate lazy var inactiveLayerMask: CAShapeLayer = { [unowned self] in
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        layer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: ringDiameter, height: ringDiameter))
        layer.actions = [
            "bounds": NSNull(),
            "frame": NSNull(),
            "position": NSNull()]
        return layer
    }()
    fileprivate lazy var activeLayerMask: CAShapeLayer = { [unowned self] in
        let layer = CAShapeLayer()
        layer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: ringDiameter, height: ringDiameter))
        layer.actions = [
            "bounds": NSNull(),
            "frame": NSNull(),
            "position": NSNull()]
        return layer
    }()
    
    // MARK: - Init
    
    fileprivate func addRequiredLayers() {
        layer.addSublayer(inactiveLayersContainer)
        layer.addSublayer(activeLayersContainer)
        layer.addSublayer(ringLayer)
        inactiveLayersContainer.mask = inactiveLayerMask
        activeLayersContainer.mask = activeLayerMask
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addRequiredLayers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addRequiredLayers()
    }
    
    // MARK: - State Update
    
    fileprivate func updateNumberOfPages(_ count: Int) {
        // no need to update
        guard count != inactiveLayersContainer.sublayers?.count else { return }
        // reset current layout
        inactiveLayersContainer.sublayers?.forEach { $0.removeFromSuperlayer() }
        activeLayersContainer.sublayers?.forEach { $0.removeFromSuperlayer() }
        // add layers for new page count
        var inactivePageIndicatorLayers = [CALayer]()
        var activePageIndicatorLayers = [CALayer]()
        for _ in 0..<count {
            // add inactve layers
            let inactiveLayer = pageIndicatorLayer(inactiveTint.cgColor)
            inactiveLayersContainer.addSublayer(inactiveLayer)
            inactivePageIndicatorLayers.append(inactiveLayer)
            // add actve layers
            let activeLayer = pageIndicatorLayer(activeTint.cgColor)
            activeLayersContainer.addSublayer(activeLayer)
            activePageIndicatorLayers.append(activeLayer)
        }
        layoutPageIndicators(inactivePageIndicatorLayers, container: inactiveLayersContainer)
        layoutPageIndicators(activePageIndicatorLayers, container: activeLayersContainer)
        center(ringLayer)
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func pageIndicatorLayer(_ color: CGColor) -> CALayer {
        let layer = CALayer()
        layer.backgroundColor = color
        return layer
    }
    
    // MARK: - Layout
    
    fileprivate func maskPath(_ size: CGSize, progress: CGFloat, inverted: Bool) -> CGPath {
        let offsetFromCenter = progress * (indicatorDiameter + indicatorPadding) - (ringRadius - indicatorRadius)
        let circleRect = CGRect( x: offsetFromCenter, y: 0, width: size.height, height: size.height)
        let circlePath = UIBezierPath(roundedRect: circleRect, cornerRadius: size.height/2)
        if inverted {
            let path = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: size))
            path.append(circlePath)
            return path.cgPath
        } else {
            return circlePath.cgPath
        }
    }
    
    fileprivate func layoutFor(_ progress: CGFloat) {
        // ignore if progress is outside of page indicators' bounds
        guard progress >= 0 && progress <= CGFloat(pageCount - 1) else { return }
        let offsetFromCenter = progress * (indicatorDiameter + indicatorPadding)
        let containerOffset = bounds.size.width/2 - indicatorRadius - offsetFromCenter
        inactiveLayersContainer.frame.origin.x = containerOffset
        activeLayersContainer.frame.origin.x = containerOffset
        inactiveLayerMask.path = maskPath(inactiveLayerMask.bounds.size, progress: progress, inverted: true)
        activeLayerMask.path = maskPath(activeLayerMask.bounds.size, progress: progress, inverted: false)
    }
    
    fileprivate func center(_ layer: CALayer) {
        let frame = CGRect( x: (bounds.width - layer.bounds.width)/2, y: (bounds.height - layer.bounds.height)/2, width: layer.bounds.width, height: layer.bounds.width)
        layer.frame = frame
    }
    
    fileprivate func layoutPageIndicators(_ layers: [CALayer], container: CALayer) {
        let layerDiameter = indicatorRadius * 2
        var layerFrame = CGRect( x: 0, y: (ringDiameter - indicatorDiameter)/2, width: layerDiameter, height: layerDiameter)
        layers.forEach { layer in
            layer.cornerRadius = indicatorRadius
            layer.frame = layerFrame
            layerFrame.origin.x += layerDiameter + indicatorPadding
        }
        layerFrame.origin.x -= indicatorPadding
        container.frame = CGRect(x: 0, y: 0, width: layerFrame.origin.x, height: ringLayer.bounds.height)
    }
    
    override open var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        let pageCountWidth = pageCount + (pageCount - 1)
        return CGSize(width: CGFloat(pageCountWidth) * indicatorDiameter + CGFloat(pageCountWidth - 1) * indicatorPadding,
                      height: ringDiameter)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        // layout containers
        PTGCDManager.gcdAfter(time: 0.1) {
            self.inactiveLayersContainer.frame = self.bounds
            self.inactiveLayerMask.frame = self.bounds
            self.activeLayersContainer.frame = self.bounds
            self.activeLayerMask.frame = self.bounds
            // layout indicators
            if let layers = self.inactiveLayersContainer.sublayers {
                self.layoutPageIndicators(layers, container: self.inactiveLayersContainer)
            }
            if let layers = self.activeLayersContainer.sublayers {
                self.layoutPageIndicators(layers, container: self.activeLayersContainer)
            }
            // update ring
            self.center(self.ringLayer)
            self.layoutFor(self.progress)
        }
    }
}
