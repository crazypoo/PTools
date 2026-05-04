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
open class PTSnakePageControl: UIControl {
    
    // MARK: - PageControl
    
    open var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    
    /// 暴露给外部的真实进度数据
    open var progress: CGFloat = 0 {
        didSet {
            guard pageCount > 0 else { return }
            let safeProgress = max(0, min(progress, CGFloat(pageCount - 1)))
            
            if isAnimating {
                // 如果外部(如ScrollView)传进来的进度与我们内部目标的进度不一致，
                // 说明外部接管了动画控制权，我们立刻停止内部定时器
                if safeProgress != targetProgress {
                    stopDisplayLink()
                    visualProgress = safeProgress
                }
            } else {
                visualProgress = safeProgress
            }
        }
    }
    
    open var currentPage: Int {
        Int(round(progress))
    }
    
    // MARK: - Internal Visual State
    
    /// 内部用于驱动 UI 绘制的视觉进度
    private var visualProgress: CGFloat = 0 {
        didSet {
            layoutActivePageIndicator(visualProgress)
        }
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
            layoutActivePageIndicator(visualProgress)
        }
    }
    
    open var indicatorRadius: CGFloat = 5 {
        didSet {
            layoutInactivePageIndicators(inactiveLayers)
            layoutActivePageIndicator(visualProgress)
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
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    // MARK: - Animation Engine
    private var displayLink: CADisplayLink?
    private var startProgress: CGFloat = 0
    private var targetProgress: CGFloat = 0
    private var progressStartTime: CFTimeInterval = 0
    private let animDuration: CFTimeInterval = 0.3
    private var isAnimating: Bool { return displayLink != nil }

    // MARK: - Init & Deinit
    
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
    
    deinit {
        stopDisplayLink()
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
        
        layoutActivePageIndicator(visualProgress)
        invalidateIntrinsicContentSize()
    }
    
    // MARK: - Layout
    
    fileprivate func layoutActivePageIndicator(_ safeProgress: CGFloat) {
        guard pageCount > 0 else { return }
        
        let totalWidth = CGFloat(pageCount) * indicatorDiameter + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        let startX = max(0, (self.bounds.width - totalWidth) / 2)
        
        let denormalizedProgress = safeProgress * (indicatorDiameter + indicatorPadding)
        let distanceFromPage = abs(round(safeProgress) - safeProgress)
        
        let stretchWidth = indicatorDiameter + indicatorPadding * (distanceFromPage * 2)
        
        var newFrame = CGRect(x: 0, y: 0, width: stretchWidth, height: indicatorDiameter)
        newFrame.origin.x = startX + denormalizedProgress
        newFrame.origin.y = (self.bounds.height - indicatorDiameter) / 2
        
        activeLayer.cornerRadius = indicatorRadius
        activeLayer.frame = newFrame
    }
    
    fileprivate func layoutInactivePageIndicators(_ layers: [CALayer]) {
        let layerDiameter = indicatorRadius * 2
        let yCenter = (self.bounds.height - layerDiameter) / 2
        
        let totalWidth = CGFloat(layers.count) * layerDiameter + CGFloat(max(0, layers.count - 1)) * indicatorPadding
        let startX = max(0, (self.bounds.width - totalWidth) / 2)
        
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutInactivePageIndicators(inactiveLayers)
        layoutActivePageIndicator(visualProgress)
    }
    
    // MARK: - Interaction (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let location = touch.location(in: self)
        let unitWidth = indicatorDiameter + indicatorPadding
        
        let totalWidth = CGFloat(pageCount) * indicatorDiameter + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        let startX = max(0, (bounds.width - totalWidth) / 2)
        let relativeX = location.x - startX
        
        var targetPage = Int(round(relativeX / unitWidth))
        targetPage = max(0, min(targetPage, pageCount - 1))
        
        if targetPage != currentPage {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 触发事件通知外部：数据瞬间更新，触发外部回调
            setProgress(CGFloat(targetPage), animated: true)
            self.sendActions(for: .valueChanged)
        }
    }
    
    // MARK: - Animation Engine Methods
    
    public func setProgress(_ newProgress: CGFloat, animated: Bool) {
        guard pageCount > 0 else { return }
        let safeProgress = max(0, min(newProgress, CGFloat(pageCount - 1)))
        
        if animated {
            startProgress = self.visualProgress
            targetProgress = safeProgress
            progressStartTime = CACurrentMediaTime()
            
            startDisplayLink()
            
            // 🚀 数据与视觉分离：立刻修改公共数据，使得外部回调获取的数据100%正确
            self.progress = safeProgress
        } else {
            stopDisplayLink()
            self.progress = safeProgress
        }
    }
    
    private func startDisplayLink() {
        stopDisplayLink()
        // 🚀 使用 Proxy 打破循环引用，防止内存泄漏
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
        
        let easePercent = percent < 0.5 ? 2 * percent * percent : -1 + (4 - 2 * percent) * percent
        // 🚀 修改的只是视觉属性，不会乱触发外部事件
        visualProgress = startProgress + (targetProgress - startProgress) * easePercent
    }
    
    // 🚀 防止内存泄漏的弱引用代理类
    private class DisplayLinkProxy {
        weak var target: PTSnakePageControl?
        init(target: PTSnakePageControl) {
            self.target = target
        }
        @objc func update() {
            target?.updateDisplayLink()
        }
    }
}

public extension PTSnakePageControl {
    @objc func addPageControlAction(handler: @escaping SnakePageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
