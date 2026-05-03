//
//  PTPillPageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias PillPageControlBlock = (_ sender:PTPillPageControl) -> Void

@objcMembers
open class PTPillPageControl: UIControl { // 🚀 1. 升级为 UIControl
    
    // MARK: - PageControl
    
    open var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    
    open var progress: CGFloat = 0 {
        didSet {
            // 🚀 2. 增加边界保护
            guard pageCount > 0 else { return }
            let safeProgress = max(0, min(progress, CGFloat(pageCount - 1)))
            layoutActivePageIndicator(safeProgress)
        }
    }
    
    open var currentPage: Int {
        Int(round(progress))
    }
    
    // MARK: - Appearance
    
    open var pillSize: CGSize = CGSize(width: 20, height: 2.5) {
        didSet {
            // 尺寸变化时重新布局
            activeLayer.frame.size = pillSize
            activeLayer.cornerRadius = pillSize.height / 2
            layoutInactivePageIndicators(inactiveLayers)
            layoutActivePageIndicator(progress)
            invalidateIntrinsicContentSize()
        }
    }
    
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
    
    open var indicatorPadding: CGFloat = 7 {
        didSet {
            layoutInactivePageIndicators(inactiveLayers)
            layoutActivePageIndicator(progress)
            invalidateIntrinsicContentSize()
        }
    }
    
    fileprivate var inactiveLayers = [CALayer]()
    
    fileprivate lazy var activeLayer: CALayer = { [unowned self] in
        let layer = CALayer()
        // y 坐标将在 layout 阶段动态计算以保持垂直居中
        layer.frame = CGRect(origin: CGPoint.zero, size: pillSize)
        layer.backgroundColor = activeTint.cgColor
        layer.cornerRadius = pillSize.height / 2
        layer.actions = [
            "bounds": NSNull(),
            "frame": NSNull(),
            "position": NSNull()]
        return layer
    }()
    
    // MARK: - Init
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        pageCount = 0
        progress = 0
        indicatorPadding = 7
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pageCount = 0
        progress = 0
        indicatorPadding = 7
    }
    
    // MARK: - State Update
    
    fileprivate func updateNumberOfPages(_ count: Int) {
        guard count != inactiveLayers.count else { return }
        
        // reset current layout
        inactiveLayers.forEach { $0.removeFromSuperlayer() }
        inactiveLayers.removeAll()
        
        // add layers for new page count
        inactiveLayers = (0..<count).map { _ in
            let layer = CALayer()
            layer.backgroundColor = inactiveTint.cgColor
            self.layer.addSublayer(layer)
            return layer
        }
        
        layoutInactivePageIndicators(inactiveLayers)
        
        // ensure active page indicator is on top
        activeLayer.removeFromSuperlayer()
        layer.addSublayer(activeLayer)
        
        layoutActivePageIndicator(progress)
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - Layout
    
    fileprivate func layoutActivePageIndicator(_ safeProgress: CGFloat) {
        guard pageCount > 0 else { return }
        let denormalizedProgress = safeProgress * (pillSize.width + indicatorPadding)
        
        // 🚀 3. 垂直居中优化
        let yCenter = (self.bounds.height - pillSize.height) / 2
        activeLayer.frame = CGRect(x: denormalizedProgress, y: yCenter, width: pillSize.width, height: pillSize.height)
    }
    
    fileprivate func layoutInactivePageIndicators(_ layers: [CALayer]) {
        // 🚀 3. 垂直居中优化
        let yCenter = (self.bounds.height - pillSize.height) / 2
        var layerFrame = CGRect(x: 0, y: yCenter, width: pillSize.width, height: pillSize.height)
        
        layers.forEach { layer in
            layer.cornerRadius = pillSize.height / 2
            layer.frame = layerFrame
            layerFrame.origin.x += layerFrame.width + indicatorPadding
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: CGFloat(inactiveLayers.count) * pillSize.width + CGFloat(max(0, inactiveLayers.count - 1)) * indicatorPadding,
               height: pillSize.height)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        // 确保父视图尺寸改变时，图层能够重新计算 Y 轴居中
        layoutInactivePageIndicators(inactiveLayers)
        layoutActivePageIndicator(progress)
    }
    
    // MARK: - 🚀 新增功能：支持交互点击 (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let location = touch.location(in: self)
        let unitWidth = pillSize.width + indicatorPadding
        
        // 根据点击的 X 坐标推算目标页码
        var targetPage = Int(round(location.x / unitWidth))
        targetPage = max(0, min(targetPage, pageCount - 1))
        
        if targetPage != currentPage {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            self.progress = CGFloat(targetPage)
            self.sendActions(for: .valueChanged)
        }
    }
}

public extension PTPillPageControl {
    @objc func addSwitchAction(handler:@escaping PillPageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
