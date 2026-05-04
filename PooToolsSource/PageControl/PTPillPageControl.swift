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
open class PTPillPageControl: UIControl {
    
    // MARK: - PageControl
    
    open var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    
    open var progress: CGFloat = 0 {
        didSet {
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
        
        inactiveLayers.forEach { $0.removeFromSuperlayer() }
        inactiveLayers.removeAll()
        
        inactiveLayers = (0..<count).map { _ in
            let layer = CALayer()
            layer.backgroundColor = inactiveTint.cgColor
            self.layer.addSublayer(layer)
            return layer
        }
        
        layoutInactivePageIndicators(inactiveLayers)
        
        activeLayer.removeFromSuperlayer()
        layer.addSublayer(activeLayer)
        
        layoutActivePageIndicator(progress)
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - Layout
    
    fileprivate func layoutActivePageIndicator(_ safeProgress: CGFloat) {
        guard pageCount > 0 else { return }
        
        // 🚀 1. 计算总宽度与起始居中点 startX
        let totalWidth = CGFloat(pageCount) * pillSize.width + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        let startX = max(0, (self.bounds.width - totalWidth) / 2)
        
        let denormalizedProgress = safeProgress * (pillSize.width + indicatorPadding)
        let yCenter = (self.bounds.height - pillSize.height) / 2
        
        // 🚀 2. 活跃图层(胶囊)的 X 坐标也要加上 startX
        activeLayer.frame = CGRect(x: startX + denormalizedProgress, y: yCenter, width: pillSize.width, height: pillSize.height)
    }
    
    fileprivate func layoutInactivePageIndicators(_ layers: [CALayer]) {
        let yCenter = (self.bounds.height - pillSize.height) / 2
        
        // 🚀 1. 计算总宽度与起始居中点 startX
        let totalWidth = CGFloat(layers.count) * pillSize.width + CGFloat(max(0, layers.count - 1)) * indicatorPadding
        let startX = max(0, (self.bounds.width - totalWidth) / 2)
        
        // 🚀 2. 从 startX 开始排布背景胶囊
        var layerFrame = CGRect(x: startX, y: yCenter, width: pillSize.width, height: pillSize.height)
        
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
        layoutInactivePageIndicators(inactiveLayers)
        layoutActivePageIndicator(progress)
    }
    
    // MARK: - 🚀 新增功能：支持交互点击 (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let location = touch.location(in: self)
        let unitWidth = pillSize.width + indicatorPadding
        
        // 🚀 1. 计算点击偏移量 startX
        let totalWidth = CGFloat(pageCount) * pillSize.width + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        let startX = max(0, (bounds.width - totalWidth) / 2)
        
        // 🚀 2. 去除左侧空白区域的干扰，获取真实的点击相对 X 坐标
        let relativeX = location.x - startX
        
        var targetPage = Int(round(relativeX / unitWidth))
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
    @objc func addPageControlAction(handler:@escaping PillPageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
