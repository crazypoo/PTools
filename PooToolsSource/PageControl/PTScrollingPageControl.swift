//
//  PTScrollingPageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias ScrollingPageControlBlock = (_ sender: PTScrollingPageControl) -> Void

@objcMembers
open class PTScrollingPageControl: PTBasePageControl {
        
    // MARK: - Internal Visual State
    
    /// 外圈专用的颜色。如果不设置(nil)，则默认跟随 activeTint
    open var ringTint: UIColor? {
        didSet { updateAppearance() }
    }

    /// 内部用于驱动 UI 滚动的视觉进度
    private var visualProgress: CGFloat = 0 {
        didSet {
            layoutFor(visualProgress)
        }
    }
    
    // MARK: - 独有外观属性
    
    open var ringRadius: CGFloat = 10 {
        didSet {
            updateLayout()
            invalidateIntrinsicContentSize()
        }
    }
    
    fileprivate var ringDiameter: CGFloat { ringRadius * 2 }
    
    fileprivate var inactiveLayersContainer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    fileprivate var activeLayersContainer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    fileprivate lazy var ringLayer: CALayer = { [unowned self] in
        let layer = CALayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.borderWidth = 1
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    fileprivate lazy var inactiveLayerMask: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    fileprivate lazy var activeLayerMask: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    // MARK: - Animation Engine
    private var displayLink: CADisplayLink?
    private var startProgress: CGFloat = 0
    private var targetProgress: CGFloat = 0
    private var progressStartTime: CFTimeInterval = 0
    private let animDuration: CFTimeInterval = 0.35 // 滚动的耗时，可以微调
    private var isAnimating: Bool { return displayLink != nil }

    deinit {
        stopDisplayLink()
    }
    
    // MARK: - 重写基类模板方法
    
    override open func commonInit() {
        indicatorPadding = 10 // 重写基类默认 padding
        indicatorRadius = 5   // 重写基类默认 radius
        
        layer.addSublayer(inactiveLayersContainer)
        layer.addSublayer(activeLayersContainer)
        layer.addSublayer(ringLayer)
        inactiveLayersContainer.mask = inactiveLayerMask
        activeLayersContainer.mask = activeLayerMask
    }
    
    override open func updateAppearance() {
        ringLayer.borderColor = (ringTint ?? activeTint).cgColor
        activeLayersContainer.sublayers?.forEach { $0.backgroundColor = activeTint.cgColor }
        inactiveLayersContainer.sublayers?.forEach { $0.backgroundColor = inactiveTint.cgColor }
    }
    
    override open func updateNumberOfPages(_ count: Int) {
        guard count != inactiveLayersContainer.sublayers?.count else { return }
        
        inactiveLayersContainer.sublayers?.forEach { $0.removeFromSuperlayer() }
        activeLayersContainer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        var inactivePageIndicatorLayers = [CALayer]()
        var activePageIndicatorLayers = [CALayer]()
        
        for _ in 0..<count {
            let inactiveLayer = CALayer()
            inactiveLayer.backgroundColor = inactiveTint.cgColor
            inactiveLayersContainer.addSublayer(inactiveLayer)
            inactivePageIndicatorLayers.append(inactiveLayer)
            
            let activeLayer = CALayer()
            activeLayer.backgroundColor = activeTint.cgColor
            activeLayersContainer.addSublayer(activeLayer)
            activePageIndicatorLayers.append(activeLayer)
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
        if let layers = self.inactiveLayersContainer.sublayers {
            self.layoutPageIndicators(layers, container: self.inactiveLayersContainer)
        }
        if let layers = self.activeLayersContainer.sublayers {
            self.layoutPageIndicators(layers, container: self.activeLayersContainer)
        }
        
        self.inactiveLayerMask.frame = self.inactiveLayersContainer.bounds
        self.activeLayerMask.frame = self.activeLayersContainer.bounds
        
        self.centerRingLayer()
        self.layoutFor(visualProgress) // 刷新滚动位置
    }
    
    // MARK: - Layout (核心滚动逻辑)
    
    fileprivate func maskPath(_ size: CGSize, progress: CGFloat, inverted: Bool) -> CGPath {
        let offsetFromCenter = progress * (indicatorDiameter + indicatorPadding) - (ringRadius - indicatorRadius)
        let circleRect = CGRect(x: offsetFromCenter, y: 0, width: size.height, height: size.height)
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
        guard pageCount > 0 else { return }
        
        let offsetFromCenter = progress * (indicatorDiameter + indicatorPadding)
        
        // 动态计算传送带需要偏移的 X 距离
        let xOffset = bounds.size.width/2 - indicatorRadius - offsetFromCenter
        let yOffset = max(0, (bounds.size.height - ringDiameter) / 2)
        
        inactiveLayersContainer.frame.origin = CGPoint(x: xOffset, y: yOffset)
        activeLayersContainer.frame.origin = CGPoint(x: xOffset, y: yOffset)
        
        inactiveLayerMask.path = maskPath(inactiveLayerMask.bounds.size, progress: progress, inverted: true)
        activeLayerMask.path = maskPath(activeLayerMask.bounds.size, progress: progress, inverted: false)
    }
    
    fileprivate func centerRingLayer() {
        ringLayer.cornerRadius = ringRadius
        let frame = CGRect(x: (bounds.width - ringDiameter)/2,
                           y: (bounds.height - ringDiameter)/2,
                           width: ringDiameter,
                           height: ringDiameter)
        ringLayer.frame = frame
    }
    
    fileprivate func layoutPageIndicators(_ layers: [CALayer], container: CALayer) {
        var layerFrame = CGRect(x: 0, y: (ringDiameter - indicatorDiameter)/2, width: indicatorDiameter, height: indicatorDiameter)
        
        layers.forEach { layer in
            layer.cornerRadius = indicatorRadius
            layer.frame = layerFrame
            layerFrame.origin.x += indicatorDiameter + indicatorPadding
        }
        layerFrame.origin.x -= indicatorPadding
        
        container.bounds = CGRect(x: 0, y: 0, width: layerFrame.origin.x, height: ringDiameter)
    }
    
    override open var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        let pageCountWidth = pageCount + (pageCount - 1)
        return CGSize(width: CGFloat(pageCountWidth) * indicatorDiameter + CGFloat(pageCountWidth - 1) * indicatorPadding,
                      height: ringDiameter)
    }
    
    // MARK: - 🚀 Interaction (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let location = touch.location(in: self)
        // 针对带滚动的特殊组件，使用原生函数将触控坐标转换到滚动容器内部
        let pointInContainer = self.layer.convert(location, to: inactiveLayersContainer)
        
        let unitWidth = indicatorDiameter + indicatorPadding
        var targetPage = Int(round(pointInContainer.x / unitWidth))
        targetPage = max(0, min(targetPage, pageCount - 1))
        
        if targetPage != currentPage {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 🚀 触发！启用动画引擎平滑滚动到指定页
            setProgress(CGFloat(targetPage), animated: true)
            self.sendActions(for: .valueChanged)
        }
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
            self.progress = safeProgress // 对外暴露的值立刻到位
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
        
        // Ease-In-Out 缓动公式，让滚动的起步和刹车都十分平滑
        let easePercent = percent < 0.5 ? 2 * percent * percent : -1 + (4 - 2 * percent) * percent
        visualProgress = startProgress + (targetProgress - startProgress) * easePercent
    }
    
    private class DisplayLinkProxy {
        weak var target: PTScrollingPageControl?
        init(target: PTScrollingPageControl) { self.target = target }
        @objc func update() { target?.updateDisplayLink() }
    }
}

public extension PTScrollingPageControl {
    @objc func addPageControlAction(handler: @escaping ScrollingPageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
