//
//  PTFilledPageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias FillPageControlBlock = (_ sender:PTFilledPageControl) -> Void

@objcMembers
open class PTFilledPageControl: UIControl { // 🚀 1. 升级为 UIControl
    
    // MARK: - PageControl
    open var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    
    open var progress: CGFloat = 0 {
        didSet {
            // 🚀 2. 健壮性提升：增加安全边界保护
            guard pageCount > 0 else { return }
            let safeProgress = max(0, min(progress, CGFloat(pageCount - 1)))
            updateActivePageIndicatorMasks(forProgress: safeProgress)
        }
    }
    
    open var currentPage: Int {
        Int(round(progress))
    }
    
    // MARK: - Appearance
    
    override open var tintColor: UIColor! {
        didSet {
            inactiveLayers.forEach { $0.backgroundColor = tintColor.cgColor }
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
            updateActivePageIndicatorMasks(forProgress: progress)
        }
    }
    
    open var indicatorRadius: CGFloat = 4 {
        didSet {
            layoutPageIndicators(inactiveLayers)
            updateActivePageIndicatorMasks(forProgress: progress)
        }
    }
    
    fileprivate var indicatorDiameter: CGFloat {
        indicatorRadius * 2
    }
    
    fileprivate var inactiveLayers = [CALayer]()
    
    // MARK: - Init
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    // 🚀 移除 fatalError，使其支持 Interface Builder 实例化
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        pageCount = 0
        progress = 0
        inactiveRingWidth = 1
        indicatorPadding = 8
        indicatorRadius = 4
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
            layer.backgroundColor = tintColor.cgColor
            self.layer.addSublayer(layer)
            return layer
        }
        
        layoutPageIndicators(inactiveLayers)
        updateActivePageIndicatorMasks(forProgress: progress)
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - Layout
    
    fileprivate func updateActivePageIndicatorMasks(forProgress currentProgress: CGFloat) {
        guard pageCount > 0 else { return }
        let safeProgress = max(0, min(currentProgress, CGFloat(pageCount - 1)))
        
        // mask rect w/ default stroke width
        let insetRect = CGRect(x: 0, y: 0, width: indicatorDiameter, height: indicatorDiameter).insetBy(dx: inactiveRingWidth, dy: inactiveRingWidth)
        let leftPageFloat = trunc(safeProgress)
        let leftPageInt = Int(safeProgress)
        
        // inset right moving page indicator
        let spaceToMove = insetRect.width / 2
        let percentPastLeftIndicator = safeProgress - leftPageFloat
        let additionalSpaceToInsetRight = spaceToMove * percentPastLeftIndicator
        let closestRightInsetRect = insetRect.insetBy(dx: additionalSpaceToInsetRight, dy: additionalSpaceToInsetRight)
        
        // inset left moving page indicator
        let additionalSpaceToInsetLeft = (1 - percentPastLeftIndicator) * spaceToMove
        let closestLeftInsetRect = insetRect.insetBy(dx: additionalSpaceToInsetLeft, dy: additionalSpaceToInsetLeft)
        
        // adjust masks
        for (idx, layer) in inactiveLayers.enumerated() {
            let maskLayer = CAShapeLayer()
            maskLayer.fillRule = .evenOdd
            
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
        let yCenter = max(0, (self.bounds.height - layerDiameter) / 2)
        
        // 🚀 1. 计算所有圆点加间距的总宽度
        let totalWidth = CGFloat(layers.count) * layerDiameter + CGFloat(max(0, layers.count - 1)) * indicatorPadding
        
        // 🚀 2. 计算水平居中的起始 X 坐标
        let startX = max(0, (self.bounds.width - totalWidth) / 2)
        
        // 🚀 3. 从 startX 开始布局
        var layerFrame = CGRect(x: startX, y: yCenter, width: layerDiameter, height: layerDiameter)
        
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
    
    // 🚀 在 layoutSubviews 中同步更新所有图层状态
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutPageIndicators(inactiveLayers)
        updateActivePageIndicatorMasks(forProgress: progress)
    }
    
    // MARK: - 🚀 新增功能：支持交互点击 (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let location = touch.location(in: self)
        let unitWidth = indicatorDiameter + indicatorPadding
        
        // 🚀 1. 同样计算出起始 X 坐标
        let totalWidth = CGFloat(pageCount) * indicatorDiameter + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        let startX = max(0, (bounds.width - totalWidth) / 2)
        
        // 🚀 2. 将点击的绝对坐标减去 startX，得到相对于点阵列的偏移量
        let relativeX = location.x - startX
        
        // 根据相对 X 坐标推算目标页码
        var targetPage = Int(round(relativeX / unitWidth))
        targetPage = max(0, min(targetPage, pageCount - 1)) // 安全边界
        
        if targetPage != currentPage {
            // 提供轻微震动反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            self.progress = CGFloat(targetPage)
            self.sendActions(for: .valueChanged)
        }
    }
}

public extension PTFilledPageControl {
    @objc func addPageControlAction(handler:@escaping FillPageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
