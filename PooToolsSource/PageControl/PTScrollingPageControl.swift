//
//  PTScrollingPageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias ScrollingPageControlBlock = (_ sender:PTScrollingPageControl) -> Void

@objcMembers
open class PTScrollingPageControl: UIControl {
    
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
            layoutFor(safeProgress)
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
            updateLayoutsForAppearanceChange()
        }
    }
    
    open var ringRadius: CGFloat = 10 {
        didSet {
            sizeToFit()
            ringLayer.cornerRadius = ringRadius
            ringLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: ringDiameter, height: ringDiameter))
            center(ringLayer)
        }
    }
    
    open var indicatorRadius: CGFloat = 5 {
        didSet {
            updateLayoutsForAppearanceChange()
        }
    }
    
    fileprivate var indicatorDiameter: CGFloat { indicatorRadius * 2 }
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
        layer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: ringDiameter, height: ringDiameter))
        layer.backgroundColor = UIColor.clear.cgColor
        layer.cornerRadius = ringRadius
        layer.borderColor = activeTint.cgColor
        layer.borderWidth = 1
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    fileprivate lazy var inactiveLayerMask: CAShapeLayer = { [unowned self] in
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        return layer
    }()
    
    fileprivate lazy var activeLayerMask: CAShapeLayer = { [unowned self] in
        let layer = CAShapeLayer()
        layer.actions = ["bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
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
        guard count != inactiveLayersContainer.sublayers?.count else { return }
        
        inactiveLayersContainer.sublayers?.forEach { $0.removeFromSuperlayer() }
        activeLayersContainer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        var inactivePageIndicatorLayers = [CALayer]()
        var activePageIndicatorLayers = [CALayer]()
        
        for _ in 0..<count {
            let inactiveLayer = pageIndicatorLayer(inactiveTint.cgColor)
            inactiveLayersContainer.addSublayer(inactiveLayer)
            inactivePageIndicatorLayers.append(inactiveLayer)
            
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
    
    fileprivate func updateLayoutsForAppearanceChange() {
        if let sublayers = inactiveLayersContainer.sublayers {
            layoutPageIndicators(sublayers, container: inactiveLayersContainer)
        }
        if let sublayers = activeLayersContainer.sublayers {
            layoutPageIndicators(sublayers, container: activeLayersContainer)
        }
    }
    
    // MARK: - Layout
    fileprivate func maskPath(_ size: CGSize, progress: CGFloat, inverted: Bool) -> CGPath {
        // 这里的 size 永远保证是紧紧贴合 ringDiameter 的，防止遮罩变形
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
        let safeProgress = max(0, min(progress, CGFloat(pageCount - 1)))
        
        let offsetFromCenter = safeProgress * (indicatorDiameter + indicatorPadding)
        
        // 🚀 1. 计算出让当前活跃圆点绝对水平居中的 X 坐标
        let xOffset = bounds.size.width/2 - indicatorRadius - offsetFromCenter
        
        // 🚀 2. 计算出垂直居中的 Y 坐标
        let yOffset = max(0, (bounds.size.height - ringDiameter) / 2)
        
        // 将传送带容器完美定位在中间
        inactiveLayersContainer.frame.origin = CGPoint(x: xOffset, y: yOffset)
        activeLayersContainer.frame.origin = CGPoint(x: xOffset, y: yOffset)
        
        inactiveLayerMask.path = maskPath(inactiveLayerMask.bounds.size, progress: safeProgress, inverted: true)
        activeLayerMask.path = maskPath(activeLayerMask.bounds.size, progress: safeProgress, inverted: false)
    }
    
    fileprivate func center(_ layer: CALayer) {
        // 固定中间圆环的位置，绝对居中
        let frame = CGRect(x: (bounds.width - layer.bounds.width)/2,
                           y: (bounds.height - layer.bounds.height)/2,
                           width: layer.bounds.width,
                           height: layer.bounds.width)
        layer.frame = frame
    }
    
    fileprivate func layoutPageIndicators(_ layers: [CALayer], container: CALayer) {
        let layerDiameter = indicatorRadius * 2
        var layerFrame = CGRect(x: 0, y: (ringDiameter - indicatorDiameter)/2, width: layerDiameter, height: layerDiameter)
        
        layers.forEach { layer in
            layer.cornerRadius = indicatorRadius
            layer.frame = layerFrame
            layerFrame.origin.x += layerDiameter + indicatorPadding
        }
        layerFrame.origin.x -= indicatorPadding // 计算传送带实际需要的总宽度
        
        // 🚀 修正容器大小，其高度必须等于 ringDiameter 才能保证遮罩形状正确
        container.bounds = CGRect(x: 0, y: 0, width: layerFrame.origin.x, height: ringLayer.bounds.height)
    }
    
    override open var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize.zero)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        let pageCountWidth = pageCount + (pageCount - 1)
        return CGSize(width: CGFloat(pageCountWidth) * indicatorDiameter + CGFloat(pageCountWidth - 1) * indicatorPadding,
                      height: ringDiameter)
    }
    
    // 🚀 在 layoutSubviews 中同步且精准地更新各层尺寸与位置
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        // 1. 刷新所有容器内部小圆点布局，容器大小会自动更新
        if let layers = self.inactiveLayersContainer.sublayers {
            self.layoutPageIndicators(layers, container: self.inactiveLayersContainer)
        }
        if let layers = self.activeLayersContainer.sublayers {
            self.layoutPageIndicators(layers, container: self.activeLayersContainer)
        }
        
        // 2. 限制遮罩（Mask）的尺寸与容器一样大，防止被 SnapKit 约束错误拉长
        self.inactiveLayerMask.frame = self.inactiveLayersContainer.bounds
        self.activeLayerMask.frame = self.activeLayersContainer.bounds
        
        // 3. 将中间静态圆环和底下滚动的圆点对齐到视图中间
        self.center(self.ringLayer)
        self.layoutFor(self.progress)
    }
    
    // MARK: - 🚀 交互点击 (Tap to Page)
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, pageCount > 1 else { return }
        
        let location = touch.location(in: self)
        
        // 因为传送带左右滚动了，所以通过原生的 convert 函数，把外部视图点击坐标转换为传送带内部相对坐标
        let pointInContainer = self.layer.convert(location, to: inactiveLayersContainer)
        
        let unitWidth = indicatorDiameter + indicatorPadding
        var targetPage = Int(round(pointInContainer.x / unitWidth))
        
        targetPage = max(0, min(targetPage, pageCount - 1))
        
        if targetPage != currentPage {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            self.progress = CGFloat(targetPage)
            self.sendActions(for: .valueChanged)
        }
    }
}

public extension PTScrollingPageControl {
    @objc func addPageControlAction(handler:@escaping ScrollingPageControlBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
