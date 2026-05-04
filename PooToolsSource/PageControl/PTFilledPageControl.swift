//
//  PTFilledPageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias FillPageControlBlock = (_ sender: PTFilledPageControl) -> Void

@objcMembers
open class PTFilledPageControl: PTBasePageControl {
    
    // MARK: - Internal Visual State
    
    /// 内部用于驱动 UI 遮罩形变的视觉进度
    private var visualProgress: CGFloat = 0 {
        didSet {
            updateActivePageIndicatorMasks(forProgress: visualProgress)
        }
    }
    
    // MARK: - 独有外观属性
    
    override open var tintColor: UIColor! {
        didSet {
            inactiveLayers.forEach { $0.backgroundColor = tintColor.cgColor }
        }
    }
    
    open var inactiveRingWidth: CGFloat = 1 {
        didSet {
            updateProgress(progress)
        }
    }
    
    fileprivate var inactiveLayers = [CALayer]()
    
    // MARK: - Animation Engine
    private var displayLink: CADisplayLink?
    private var startProgress: CGFloat = 0
    private var targetProgress: CGFloat = 0
    private var progressStartTime: CFTimeInterval = 0
    private let animDuration: CFTimeInterval = 0.3 // 填充与镂空的过渡时间
    private var isAnimating: Bool { return displayLink != nil }
    
    // MARK: - Deinit
    
    deinit {
        stopDisplayLink()
    }
    
    // MARK: - 重写基类的模板方法
    
    override open func commonInit() {
        inactiveRingWidth = 1
        indicatorPadding = 8
        indicatorRadius = 4
    }
    
    override open func updateNumberOfPages(_ count: Int) {
        guard count != inactiveLayers.count else { return }
        
        inactiveLayers.forEach { $0.removeFromSuperlayer() }
        inactiveLayers.removeAll()
        
        inactiveLayers = (0..<count).map { _ in
            let layer = CALayer()
            layer.backgroundColor = tintColor?.cgColor ?? UIColor.white.cgColor
            self.layer.addSublayer(layer)
            return layer
        }
        
        updateLayout()
        invalidateIntrinsicContentSize()
    }
    
    override open func updateProgress(_ safeProgress: CGFloat) {
        // 🚀 数据与视觉分离，防止外部强行打断动画时发生冲突
        if isAnimating {
            if safeProgress != targetProgress {
                stopDisplayLink()
                visualProgress = safeProgress
            }
        } else {
            visualProgress = safeProgress
        }
    }
    
    override open func updateLayout() {
        layoutPageIndicators(inactiveLayers)
        updateActivePageIndicatorMasks(forProgress: visualProgress) // 🚀 使用视觉进度刷新
    }
    
    // MARK: - 独有核心逻辑 (遮罩 Mask)
    
    fileprivate func updateActivePageIndicatorMasks(forProgress currentProgress: CGFloat) {
        guard pageCount > 0 else { return }
        let safeProgress = max(0, min(currentProgress, CGFloat(pageCount - 1)))
        
        let insetRect = CGRect(x: 0, y: 0, width: indicatorDiameter, height: indicatorDiameter).insetBy(dx: inactiveRingWidth, dy: inactiveRingWidth)
        let leftPageFloat = trunc(safeProgress)
        let leftPageInt = Int(safeProgress)
        
        let spaceToMove = insetRect.width / 2
        let percentPastLeftIndicator = safeProgress - leftPageFloat
        let additionalSpaceToInsetRight = spaceToMove * percentPastLeftIndicator
        let closestRightInsetRect = insetRect.insetBy(dx: additionalSpaceToInsetRight, dy: additionalSpaceToInsetRight)
        
        let additionalSpaceToInsetLeft = (1 - percentPastLeftIndicator) * spaceToMove
        let closestLeftInsetRect = insetRect.insetBy(dx: additionalSpaceToInsetLeft, dy: additionalSpaceToInsetLeft)
        
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
    
    // MARK: - 🚀 交互 (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let totalWidth = CGFloat(pageCount) * indicatorDiameter + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        let unitWidth = indicatorDiameter + indicatorPadding
        
        let targetPage = getTargetPage(for: touch.location(in: self), totalWidth: totalWidth, unitWidth: unitWidth)
        
        if targetPage != currentPage {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 🚀 触发！启用动画引擎平滑过渡遮罩
            setProgress(CGFloat(targetPage), animated: true)
            self.sendActions(for: .valueChanged)
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: CGFloat(inactiveLayers.count) * indicatorDiameter + CGFloat(max(0, inactiveLayers.count - 1)) * indicatorPadding,
               height: indicatorDiameter)
    }
    
    // MARK: - 🚀 Animation Engine Methods
    
    public func setProgress(_ newProgress: CGFloat, animated: Bool) {
        guard pageCount > 0 else { return }
        let safeProgress = max(0, min(newProgress, CGFloat(pageCount - 1)))
        
        if animated {
            startProgress = self.visualProgress
            targetProgress = safeProgress
            progressStartTime = CACurrentMediaTime()
            
            startDisplayLink()
            
            // 数据层瞬间更新，确保外部回调拿到的值完全正确
            self.progress = safeProgress
        } else {
            stopDisplayLink()
            self.progress = safeProgress
        }
    }
    
    private func startDisplayLink() {
        stopDisplayLink()
        let proxy = DisplayLinkProxy(target: self)
        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc fileprivate func updateDisplayLink() {
        let elapsed = CACurrentMediaTime() - progressStartTime
        var percent = CGFloat(elapsed / animDuration)
        
        if percent >= 1.0 {
            percent = 1.0
            stopDisplayLink()
        }
        
        // Ease-In-Out 缓动算法，使呼吸感更加平滑自然
        let easePercent = percent < 0.5 ? 2 * percent * percent : -1 + (4 - 2 * percent) * percent
        visualProgress = startProgress + (targetProgress - startProgress) * easePercent
    }
    
    private class DisplayLinkProxy {
        weak var target: PTFilledPageControl?
        init(target: PTFilledPageControl) { self.target = target }
        @objc func update() { target?.updateDisplayLink() }
    }
}

public extension PTFilledPageControl {
    @objc func addPageControlAction(handler: @escaping FillPageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
