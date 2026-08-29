//
//  PTSnakePageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias SnakePageControlBlock = (_ sender: PTSnakePageControl) -> Void

@objcMembers
@MainActor
open class PTSnakePageControl: PTBasePageControl {
    
    // MARK: - Internal Visual State
    
    /// 内部用于驱动 UI 绘制的视觉进度
    private var visualProgress: CGFloat = 0 {
        didSet {
            layoutActivePageIndicator(visualProgress)
        }
    }
    
    fileprivate var inactiveLayers = [CALayer]()
    
    fileprivate lazy var activeLayer: CALayer = { [unowned self] in
        let layer = CALayer()
        layer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: indicatorDiameter, height: indicatorDiameter))
        layer.backgroundColor = activeTint.cgColor
        layer.cornerRadius = indicatorRadius
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    override open var progressAnimationDuration: CFTimeInterval { 0.3 }
    
    // MARK: - 重写基类模板方法
    
    override open func commonInit() {
        layer.addSublayer(activeLayer)
    }
    
    override open func updateAppearance() {
        activeLayer.backgroundColor = activeTint.cgColor
        inactiveLayers.forEach { $0.backgroundColor = inactiveTint.cgColor }
    }
    
    override open func updateNumberOfPages(_ count: Int) {
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
        
        layoutActivePageIndicator(visualProgress)
        invalidateIntrinsicContentSize()
    }
    
    override open func updateProgress(_ safeProgress: CGFloat) {
        visualProgress = safeProgress
    }
    
    override open func updateLayout() {
        layoutInactivePageIndicators(inactiveLayers)
        layoutActivePageIndicator(visualProgress)
    }
    
    // MARK: - Layout (核心绘制逻辑)
    
    fileprivate func layoutActivePageIndicator(_ safeProgress: CGFloat) {
        guard pageCount > 0 else { return }
        
        let totalWidth = CGFloat(pageCount) * indicatorDiameter + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        
        // 🚀 3. 爽点：直接复用基类的居中算法
        let startX = getStartX(totalWidth: totalWidth)
        let yCenter = getYCenter(itemHeight: indicatorDiameter)
        
        let denormalizedProgress = safeProgress * (indicatorDiameter + indicatorPadding)
        let distanceFromPage = abs(round(safeProgress) - safeProgress)
        
        let stretchWidth = indicatorDiameter + indicatorPadding * (distanceFromPage * 2)
        
        var newFrame = CGRect(x: 0, y: 0, width: stretchWidth, height: indicatorDiameter)
        newFrame.origin.x = startX + denormalizedProgress
        newFrame.origin.y = yCenter
        
        activeLayer.cornerRadius = indicatorRadius
        activeLayer.frame = newFrame
    }
    
    fileprivate func layoutInactivePageIndicators(_ layers: [CALayer]) {
        let totalWidth = CGFloat(layers.count) * indicatorDiameter + CGFloat(max(0, layers.count - 1)) * indicatorPadding
        
        let startX = getStartX(totalWidth: totalWidth)
        let yCenter = getYCenter(itemHeight: indicatorDiameter)
        
        var layerFrame = CGRect(x: startX, y: yCenter, width: indicatorDiameter, height: indicatorDiameter)
        
        layers.forEach { layer in
            layer.cornerRadius = indicatorRadius
            layer.frame = layerFrame
            layerFrame.origin.x += indicatorDiameter + indicatorPadding
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: CGFloat(inactiveLayers.count) * indicatorDiameter + CGFloat(max(0, inactiveLayers.count - 1)) * indicatorPadding,
               height: indicatorDiameter)
    }
    
    // MARK: - 🚀 Interaction (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let totalWidth = CGFloat(pageCount) * indicatorDiameter + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        let unitWidth = indicatorDiameter + indicatorPadding
        
        // 🚀 4. 爽点：不需要再写繁杂的相对坐标推算了，直接获取安全目标页！
        let targetPage = getTargetPage(for: touch.location(in: self), totalWidth: totalWidth, unitWidth: unitWidth)
        
        if targetPage != currentPage {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            setProgress(CGFloat(targetPage), animated: true)
            self.sendActions(for: .valueChanged)
        }
    }
    
}

public extension PTSnakePageControl {
    @objc func addPageControlAction(handler: @escaping SnakePageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
