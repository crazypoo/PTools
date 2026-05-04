//
//  PTPillPageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias PillPageControlBlock = (_ sender: PTPillPageControl) -> Void

@objcMembers
open class PTPillPageControl: PTBasePageControl {
    
    // MARK: - Internal Visual State
    
    /// 内部用于驱动 UI 绘制的视觉进度
    private var visualProgress: CGFloat = 0 {
        didSet {
            layoutActivePageIndicator(visualProgress)
        }
    }
    
    // MARK: - Appearance
    
    open var pillSize: CGSize = CGSize(width: 20, height: 2.5) {
        didSet {
            activeLayer.frame.size = pillSize
            activeLayer.cornerRadius = pillSize.height / 2
            updateLayout()
            invalidateIntrinsicContentSize()
        }
    }
    
    fileprivate var inactiveLayers = [CALayer]()
    
    fileprivate lazy var activeLayer: CALayer = { [unowned self] in
        let layer = CALayer()
        layer.frame = CGRect(origin: CGPoint.zero, size: pillSize)
        layer.backgroundColor = activeTint.cgColor
        layer.cornerRadius = pillSize.height / 2
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    // MARK: - Animation Engine
    private var displayLink: CADisplayLink?
    private var startProgress: CGFloat = 0
    private var targetProgress: CGFloat = 0
    private var progressStartTime: CFTimeInterval = 0
    private let animDuration: CFTimeInterval = 0.3 // 平滑滑动的时间
    private var isAnimating: Bool { return displayLink != nil }
    
    // MARK: - Deinit
    
    deinit {
        stopDisplayLink()
    }
    
    // MARK: - 重写基类模板方法
    
    override open func commonInit() {
        indicatorPadding = 7 // 重写基类默认的 8，使用胶囊控件特有的 7
    }
    
    override open func updateAppearance() {
        // 响应基类的颜色变化
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
        
        activeLayer.removeFromSuperlayer()
        layer.addSublayer(activeLayer)
        
        updateLayout()
        invalidateIntrinsicContentSize()
    }
    
    override open func updateProgress(_ safeProgress: CGFloat) {
        // 🚀 数据与视觉分离：外部介入打断时停止内部定时器
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
        layoutInactivePageIndicators(inactiveLayers)
        layoutActivePageIndicator(visualProgress) // 🚀 使用视觉进度渲染
    }
    
    // MARK: - 内部布局私有方法
    
    fileprivate func layoutActivePageIndicator(_ safeProgress: CGFloat) {
        guard pageCount > 0 else { return }
        
        let totalWidth = CGFloat(pageCount) * pillSize.width + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        
        let startX = getStartX(totalWidth: totalWidth)
        let yCenter = getYCenter(itemHeight: pillSize.height)
        
        let denormalizedProgress = safeProgress * (pillSize.width + indicatorPadding)
        
        activeLayer.frame = CGRect(x: startX + denormalizedProgress, y: yCenter, width: pillSize.width, height: pillSize.height)
    }
    
    fileprivate func layoutInactivePageIndicators(_ layers: [CALayer]) {
        let totalWidth = CGFloat(layers.count) * pillSize.width + CGFloat(max(0, layers.count - 1)) * indicatorPadding
        
        let startX = getStartX(totalWidth: totalWidth)
        let yCenter = getYCenter(itemHeight: pillSize.height)
        
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
    
    // MARK: - 🚀 交互点击 (Tap to Page)
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let totalWidth = CGFloat(pageCount) * pillSize.width + CGFloat(max(0, pageCount - 1)) * indicatorPadding
        let unitWidth = pillSize.width + indicatorPadding
        
        let targetPage = getTargetPage(for: touch.location(in: self), totalWidth: totalWidth, unitWidth: unitWidth)
        
        if targetPage != currentPage {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 🚀 触发！启用动画引擎平滑滑到指定页
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
            
            // 对外数据瞬间到位，保证外部回调获取正确的值
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
        
        // 缓动函数 (Ease-In-Out)
        let easePercent = percent < 0.5 ? 2 * percent * percent : -1 + (4 - 2 * percent) * percent
        // 驱动视觉进度，产生平滑移动
        visualProgress = startProgress + (targetProgress - startProgress) * easePercent
    }
    
    private class DisplayLinkProxy {
        weak var target: PTPillPageControl?
        init(target: PTPillPageControl) {
            self.target = target
        }
        @objc func update() {
            target?.updateDisplayLink()
        }
    }
}

public extension PTPillPageControl {
    @objc func addPageControlAction(handler: @escaping PillPageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
