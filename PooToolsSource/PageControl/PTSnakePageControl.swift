//
//  PTSnakePageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias SnakePageControlBlock = (_ sender:PTSnakePageControl) -> Void

@objcMembers
open class PTSnakePageControl: UIControl { // 🚀 1. 升级为 UIControl
    
    // MARK: - PageControl
    
    open var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    
    open var progress: CGFloat = 0 {
        didSet {
            // 🚀 2. 增加边界保护，防止贪吃蛇动画在极值时拉伸错乱或崩溃
            guard pageCount > 0 else { return }
            let safeProgress = max(0, min(progress, CGFloat(pageCount - 1)))
            layoutActivePageIndicator(safeProgress)
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
            layoutActivePageIndicator(progress)
        }
    }
    
    open var indicatorRadius: CGFloat = 5 {
        didSet {
            layoutInactivePageIndicators(inactiveLayers)
            layoutActivePageIndicator(progress)
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
    
    // MARK: - Init
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        layer.addSublayer(activeLayer)
    }
    
    // MARK: - State Update
    
    fileprivate func updateNumberOfPages(_ count: Int) {
        guard count != inactiveLayers.count else { return }
        
        // 清理旧图层
        inactiveLayers.forEach { $0.removeFromSuperlayer() }
        inactiveLayers.removeAll()
        
        // 添加新图层
        inactiveLayers = (0..<count).map { _ in
            let layer = CALayer()
            layer.backgroundColor = inactiveTint.cgColor
            self.layer.addSublayer(layer)
            return layer
        }
        
        layoutInactivePageIndicators(inactiveLayers)
        
        // 确保活动图层始终在最顶层
        activeLayer.removeFromSuperlayer()
        layer.addSublayer(activeLayer)
        
        layoutActivePageIndicator(progress)
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - Layout
    
    fileprivate func layoutActivePageIndicator(_ safeProgress: CGFloat) {
        guard pageCount > 0 else { return }
        
        let denormalizedProgress = safeProgress * (indicatorDiameter + indicatorPadding)
        let distanceFromPage = abs(round(safeProgress) - safeProgress)
        
        // 核心贪吃蛇动画逻辑：计算拉伸的宽度
        let stretchWidth = indicatorDiameter + indicatorPadding * (distanceFromPage * 2)
        
        var newFrame = CGRect(x: 0, y: 0, width: stretchWidth, height: indicatorDiameter)
        
        // 调整拉伸时的原点（如果是向左拉伸或向右拉伸，视觉中心需要保持平衡）
        // 原有逻辑中的 denormalizedProgress 作为起点在大部分时候表现良好
        newFrame.origin.x = denormalizedProgress
        // 垂直居中对齐（如果你有改变 frame 高度的需求，这里更为安全）
        newFrame.origin.y = (self.bounds.height - indicatorDiameter) / 2
        
        activeLayer.cornerRadius = indicatorRadius
        activeLayer.frame = newFrame
    }
    
    fileprivate func layoutInactivePageIndicators(_ layers: [CALayer]) {
        let layerDiameter = indicatorRadius * 2
        // 垂直居中
        var layerFrame = CGRect(x: 0, y: (self.bounds.height - layerDiameter) / 2, width: layerDiameter, height: layerDiameter)
        
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
        CGSize(width: CGFloat(inactiveLayers.count) * indicatorDiameter + CGFloat(max(0, inactiveLayers.count - 1)) * indicatorPadding,
               height: indicatorDiameter)
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
        let unitWidth = indicatorDiameter + indicatorPadding
        
        // 计算点击区域对应的页码 (稍微增加了一点点击容错判定范围)
        var targetPage = Int(round(location.x / unitWidth))
        targetPage = max(0, min(targetPage, pageCount - 1)) // 安全限制
        
        if targetPage != currentPage {
            // 提供轻微震动反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 触发事件通知外部
            self.progress = CGFloat(targetPage)
            self.sendActions(for: .valueChanged)
        }
    }
}

public extension PTSnakePageControl {
    @objc func addSwitchAction(handler:@escaping SnakePageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
