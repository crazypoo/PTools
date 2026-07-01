//
//  PTFlexibleSteppedProgressBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/7/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

// MARK: - CATextLayer 扩展
extension CATextLayer {
    /// 根据字体和内容自动调整图层大小
    func sizeWidthToFit() {
        let preferredSize = self.preferredFrameSize()
                
        self.bounds = CGRect(x: 0,
                             y: 0,
                             width: ceil(preferredSize.width),
                             height: ceil(preferredSize.height))
    }
}

// MARK: - CGPoint 扩展
extension CGPoint {
    /// 计算两点之间的距离
    func barDistance(to point: CGPoint) -> CGFloat {
        // 使用 hypot 是计算距离更现代、且有效防止溢出的数学方法
        return hypot(self.x - point.x, self.y - point.y)
    }    
}

public enum PTFlexibleSteppedProgressBarTextLocation: Int {
    case top
    case bottom
    case center
}

@MainActor
public protocol PTFlexibleSteppedProgressBarDelegate: AnyObject {
    func progressBar(_ progressBar: PTFlexibleSteppedProgressBar, willSelectItemAtIndex index: Int)
    func progressBar(_ progressBar: PTFlexibleSteppedProgressBar, didSelectItemAtIndex index: Int)
    func progressBar(_ progressBar: PTFlexibleSteppedProgressBar, canSelectItemAtIndex index: Int) -> Bool
    func progressBar(_ progressBar: PTFlexibleSteppedProgressBar, textAtIndex index: Int, position: PTFlexibleSteppedProgressBarTextLocation) -> String
}

// 通过扩展提供默认实现
public extension PTFlexibleSteppedProgressBarDelegate {
    func progressBar(_ progressBar: PTFlexibleSteppedProgressBar, willSelectItemAtIndex index: Int) {}
    func progressBar(_ progressBar: PTFlexibleSteppedProgressBar, didSelectItemAtIndex index: Int) {}
    func progressBar(_ progressBar: PTFlexibleSteppedProgressBar, canSelectItemAtIndex index: Int) -> Bool { return true }
    func progressBar(_ progressBar: PTFlexibleSteppedProgressBar, textAtIndex index: Int, position: PTFlexibleSteppedProgressBarTextLocation) -> String { return "\(index)" }
}

@MainActor
@IBDesignable open class PTFlexibleSteppedProgressBar: UIView {
    
    // MARK: - Public properties
    open override var intrinsicContentSize: CGSize {
        // 如果半径未设定，给一个默认的预估值 15
        let currentMaxRadius = max(_radius > 0 ? _radius : 15.0, _progressRadius > 0 ? _progressRadius : 15.0)
        
        // 预估文本的高度
        let textHeight = max(stepTextFont.lineHeight, centerLayerTextFont.lineHeight)
        
        // 计算所需总高度: 上下文本高度 + 上下文本间距 + 圆圈直径
        let requiredHeight = (textHeight + textDistance) * 2 + (currentMaxRadius * 2)
        
        // 宽度填 UIView.noIntrinsicMetric 代表宽度由外部 SnapKit 决定 (比如左右贴边)
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(requiredHeight))
    }
    
    @IBInspectable open var numberOfPoints: Int = 3 { didSet { setNeedsLayout() } }
    
    open var currentIndex: Int = 0 {
        willSet {
            delegate?.progressBar(self, willSelectItemAtIndex: newValue)
        }
        didSet {
            setNeedsLayout()
        }
    }
    
    open var completedTillIndex: Int = -1 { didSet { setNeedsLayout() } }
    
    open var currentSelectedCenterColor: UIColor = .black
    open var currentSelectedTextColor: UIColor = .orange
    open var viewBackgroundColor: UIColor = .white
    open var selectedOuterCircleStrokeColor: UIColor = .orange
    open var lastStateOuterCircleStrokeColor: UIColor = .orange
    open var lastStateCenterColor: UIColor = .lightGray
    open var centerLayerTextColor: UIColor = .black
    open var centerLayerDarkBackgroundTextColor: UIColor = .white
    
    open var useLastState: Bool = false {
        didSet {
            if useLastState {
                layer.addSublayer(clearLastStateLayer)
                layer.addSublayer(lastStateLayer)
                layer.addSublayer(lastStateCenterLayer)
            }
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var lineHeight: CGFloat = 0.0 { didSet { setNeedsLayout() } }
    open var selectedOuterCircleLineWidth: CGFloat = 3.0 { didSet { setNeedsLayout() } }
    open var lastStateOuterCircleLineWidth: CGFloat = 5.0 { didSet { setNeedsLayout() } }
    open var textDistance: CGFloat = 20.0 {
        didSet {
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
    
    private var _lineHeight: CGFloat {
        return (lineHeight == 0.0 || lineHeight > bounds.height) ? bounds.height * 0.4 : lineHeight
    }
    
    @IBInspectable open var radius: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
    private var _radius: CGFloat {
        return (radius == 0.0 || radius > bounds.height / 2.0) ? bounds.height / 2.0 : radius
    }
    
    @IBInspectable open var progressRadius: CGFloat = 0.0 {
        didSet {
            maskLayer.cornerRadius = progressRadius
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
    private var _progressRadius: CGFloat {
        return (progressRadius == 0.0 || progressRadius > bounds.height / 2.0) ? bounds.height / 2.0 : progressRadius
    }
    
    @IBInspectable open var progressLineHeight: CGFloat = 0.0 { didSet { setNeedsLayout() } }
    private var _progressLineHeight: CGFloat {
        return (progressLineHeight == 0.0 || progressLineHeight > _lineHeight) ? _lineHeight : progressLineHeight
    }
    
    @IBInspectable open var stepAnimationDuration: CFTimeInterval = 0.4
    @IBInspectable open var displayStepText: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var stepTextFont: UIFont = UIFont(name: "HelveticaNeue-Medium", size: 14.0) ?? .systemFont(ofSize: 14.0) {
        didSet {
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
    open var stepTextColor: UIColor = .black {
        didSet {
            setNeedsLayout()
        }
    }
    open var centerLayerTextFont: UIFont = .boldSystemFont(ofSize: 15) {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var backgroundShapeColor: UIColor = UIColor(red: 238.0/255.0, green: 238.0/255.0, blue: 238.0/255.0, alpha: 0.8) {
        didSet {
            setNeedsLayout()
        }
    }
    @IBInspectable open var selectedBackgoundColor: UIColor = UIColor(red: 251.0/255.0, green: 167.0/255.0, blue: 51.0/255.0, alpha: 1.0) {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var isRTL: Bool = false {
        didSet {
            transform = isRTL ? CGAffineTransform(scaleX: -1, y: 1) : .identity
            setNeedsLayout()
        }
    }
    
    public weak var delegate: PTFlexibleSteppedProgressBarDelegate? {
        didSet {
            setNeedsLayout()
        }
    }
    
    // MARK: - Private properties
    
    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let selectionLayer = CAShapeLayer()
    private let clearSelectionLayer = CAShapeLayer()
    private let clearLastStateLayer = CAShapeLayer()
    private let lastStateLayer = CAShapeLayer()
    private let lastStateCenterLayer = CAShapeLayer()
    private let selectionCenterLayer = CAShapeLayer()
    private let roadToSelectionLayer = CAShapeLayer()
    private let clearCentersLayer = CAShapeLayer()
    private let maskLayer = CAShapeLayer()
    
    private var centerPoints = [CGPoint]()
    private var textLayers = [Int: CATextLayer]()
    private var topTextLayers = [Int: CATextLayer]()
    private var bottomTextLayers = [Int: CATextLayer]()
    
    private var previousIndex: Int = 0
    private var animationRendering = false
    
    // MARK: - Life cycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(gestureAction(_:)))
        let swipeGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(gestureAction(_:)))
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(swipeGestureRecognizer)
        
        // 按照 Z 轴顺序添加图层
        layer.addSublayer(clearCentersLayer)
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
        layer.addSublayer(clearSelectionLayer)
        layer.addSublayer(selectionCenterLayer)
        layer.addSublayer(selectionLayer)
        layer.addSublayer(roadToSelectionLayer)
        
        progressLayer.mask = maskLayer
    }
    
    // 将原有的 draw(_:) 逻辑转移至 layoutSubviews()
    open override func layoutSubviews() {
        super.layoutSubviews()
        updatePathsAndUI()
    }
    
    private func updatePathsAndUI() {
        // 1. 拦截 SnapKit 初始化的零尺寸状态
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // 🐛 核心修复 1：打破死循环！只在值真正不同时才赋值，防止触发无限 setNeedsLayout
        if !useLastState && completedTillIndex != currentIndex {
            completedTillIndex = currentIndex
        }
        
        centerPoints.removeAll()
        let largerRadius = max(_radius, _progressRadius)
        
        let divisor = max(CGFloat(numberOfPoints - 1), 1.0)
        let distanceBetweenCircles = (bounds.width - (CGFloat(numberOfPoints) * 2 * largerRadius)) / divisor
        
        var xCursor: CGFloat = largerRadius
        for _ in 0..<numberOfPoints {
            centerPoints.append(CGPoint(x: xCursor, y: bounds.height / 2))
            xCursor += 2 * largerRadius + distanceBetweenCircles
        }
        
        // 🐛 核心修复 2：防止越界崩溃 (如果外部给的 currentIndex 超出了设定的总节点数)
        guard centerPoints.count > 0 else { return }
        let safeCurrentIndex = max(0, min(currentIndex, centerPoints.count - 1))
        
        let largerLineWidth = max(selectedOuterCircleLineWidth, lastStateOuterCircleLineWidth)
        
        if !animationRendering {
            clearCentersLayer.path = shapePath(centerPoints, aRadius: largerRadius + largerLineWidth, aLineHeight: _lineHeight).cgPath
            clearCentersLayer.fillColor = viewBackgroundColor.cgColor
            
            backgroundLayer.path = shapePath(centerPoints, aRadius: _radius, aLineHeight: _lineHeight).cgPath
            backgroundLayer.fillColor = backgroundShapeColor.cgColor
            
            progressLayer.path = shapePath(centerPoints, aRadius: _progressRadius, aLineHeight: _progressLineHeight).cgPath
            progressLayer.fillColor = selectedBackgoundColor.cgColor
            
            let clearSelectedRadius = max(_progressRadius, _progressRadius + selectedOuterCircleLineWidth)
            // 使用 safeCurrentIndex 替代 currentIndex
            clearSelectionLayer.path = shapePathForSelected(centerPoints[safeCurrentIndex], aRadius: clearSelectedRadius).cgPath
            clearSelectionLayer.fillColor = viewBackgroundColor.cgColor
            
            selectionLayer.path = shapePathForSelected(centerPoints[safeCurrentIndex], aRadius: _radius).cgPath
            selectionLayer.fillColor = currentSelectedCenterColor.cgColor
            
            if !useLastState {
                selectionCenterLayer.path = shapePathForSelectedPathCenter(centerPoints[safeCurrentIndex], aRadius: _progressRadius).cgPath
                selectionCenterLayer.strokeColor = selectedOuterCircleStrokeColor.cgColor
                selectionCenterLayer.fillColor = UIColor.clear.cgColor
                selectionCenterLayer.lineWidth = selectedOuterCircleLineWidth
                selectionCenterLayer.strokeEnd = 1.0
            } else {
                selectionCenterLayer.path = shapePathForSelectedPathCenter(centerPoints[safeCurrentIndex], aRadius: _progressRadius + selectedOuterCircleLineWidth).cgPath
                selectionCenterLayer.strokeColor = selectedOuterCircleStrokeColor.cgColor
                selectionCenterLayer.fillColor = UIColor.clear.cgColor
                selectionCenterLayer.lineWidth = selectedOuterCircleLineWidth
                
                if completedTillIndex >= 0 {
                    let safeCompletedIndex = max(0, min(completedTillIndex, centerPoints.count - 1))
                    lastStateLayer.path = shapePathForLastState(centerPoints[safeCompletedIndex]).cgPath
                    lastStateLayer.strokeColor = lastStateOuterCircleStrokeColor.cgColor
                    lastStateLayer.fillColor = viewBackgroundColor.cgColor
                    lastStateLayer.lineWidth = lastStateOuterCircleLineWidth
                    
                    lastStateCenterLayer.path = shapePathForSelected(centerPoints[safeCompletedIndex], aRadius: _radius).cgPath
                    lastStateCenterLayer.fillColor = lastStateCenterColor.cgColor
                }
                
                if safeCurrentIndex > 0 {
                    let lastPoint = centerPoints[safeCurrentIndex - 1]
                    let centerCurrent = centerPoints[safeCurrentIndex]
                    let xCursor = centerCurrent.x - progressRadius - _radius
                    let routeToSelectedPath = UIBezierPath()
                    
                    routeToSelectedPath.move(to: CGPoint(x: lastPoint.x + progressRadius + selectedOuterCircleLineWidth, y: lastPoint.y))
                    routeToSelectedPath.addLine(to: CGPoint(x: xCursor, y: centerCurrent.y))
                    roadToSelectionLayer.path = routeToSelectedPath.cgPath
                    roadToSelectionLayer.strokeColor = selectedBackgoundColor.cgColor
                    roadToSelectionLayer.lineWidth = progressLineHeight
                }
            }
        }
        
        renderTopTextIndexes()
        renderBottomTextIndexes()
        renderTextIndexes()
        
        let validCompletedIndex = max(0, min(completedTillIndex, centerPoints.count - 1))
        let progressCenterPoints = Array(centerPoints[0...validCompletedIndex])
        
        if let currentProgressCenterPoint = progressCenterPoints.last {
            let targetMaskPath = maskPath(currentProgressCenterPoint)
            
            CATransaction.begin()
            let progressAnimation = CABasicAnimation(keyPath: "path")
            progressAnimation.duration = stepAnimationDuration * CFTimeInterval(abs(completedTillIndex - previousIndex))
            progressAnimation.toValue = targetMaskPath.cgPath
            progressAnimation.isRemovedOnCompletion = false
            progressAnimation.fillMode = .forwards
            progressAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else { return }
                self.maskLayer.path = targetMaskPath.cgPath
                if self.animationRendering {
                    self.delegate?.progressBar(self, didSelectItemAtIndex: self.currentIndex)
                    self.animationRendering = false
                }
            }
            
            maskLayer.add(progressAnimation, forKey: "progressAnimation")
            CATransaction.commit()
        }
        previousIndex = currentIndex
    }

    // MARK: - Text Rendering Helpers
    
    private func renderTextIndexes() {
        for i in 0..<numberOfPoints {
            let centerPoint = centerPoints[i]
            let textLayer = fetchTextLayer(for: i, dictionary: &textLayers)
            
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.font = centerLayerTextFont
            textLayer.fontSize = centerLayerTextFont.pointSize
            
            textLayer.foregroundColor = (i == currentIndex || i == completedTillIndex) ? centerLayerDarkBackgroundTextColor.cgColor : centerLayerTextColor.cgColor
            
            textLayer.string = delegate?.progressBar(self, textAtIndex: i, position: .center) ?? "\(i)"
            textLayer.sizeWidthToFit()
            
            textLayer.frame = CGRect(x: centerPoint.x - textLayer.bounds.width / 2,
                                     y: centerPoint.y - textLayer.bounds.height / 2,
                                     width: textLayer.bounds.width,
                                     height: textLayer.bounds.height)
            
            if isRTL { textLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1)) }
        }
    }
    
    private func renderTopTextIndexes() {
        for i in 0..<numberOfPoints {
            let centerPoint = centerPoints[i]
            let textLayer = fetchTextLayer(for: i, dictionary: &topTextLayers)
            
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.font = stepTextFont
            textLayer.fontSize = stepTextFont.pointSize
            
            textLayer.foregroundColor = (i == currentIndex) ? currentSelectedTextColor.cgColor : stepTextColor.cgColor
            textLayer.string = delegate?.progressBar(self, textAtIndex: i, position: .top) ?? "\(i)"
            textLayer.sizeWidthToFit()
            
            textLayer.frame = CGRect(x: centerPoint.x - textLayer.bounds.width / 2,
                                     y: centerPoint.y - textLayer.bounds.height / 2 - _progressRadius - textDistance,
                                     width: textLayer.bounds.width,
                                     height: textLayer.bounds.height)
            
            if isRTL { textLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1)) }
        }
    }
    
    private func renderBottomTextIndexes() {
        for i in 0..<numberOfPoints {
            let centerPoint = centerPoints[i]
            let textLayer = fetchTextLayer(for: i, dictionary: &bottomTextLayers)
            
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.font = stepTextFont
            textLayer.fontSize = stepTextFont.pointSize
            
            textLayer.foregroundColor = (i == currentIndex) ? currentSelectedTextColor.cgColor : stepTextColor.cgColor
            textLayer.string = delegate?.progressBar(self, textAtIndex: i, position: .bottom) ?? "\(i)"
            textLayer.sizeWidthToFit()
            
            textLayer.frame = CGRect(x: centerPoint.x - textLayer.bounds.width / 2,
                                     y: centerPoint.y - textLayer.bounds.height / 2 + _progressRadius + textDistance,
                                     width: textLayer.bounds.width,
                                     height: textLayer.bounds.height)
            
            if isRTL { textLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1)) }
        }
    }
    
    // 合并创建 Layer 的重复逻辑
    private func fetchTextLayer(for index: Int, dictionary: inout [Int: CATextLayer]) -> CATextLayer {
        if let existingLayer = dictionary[index] {
            return existingLayer
        }
        let newLayer = CATextLayer()
        dictionary[index] = newLayer
        layer.addSublayer(newLayer)
        return newLayer
    }
    
    // MARK: - Path Drawing Helpers
    
    private func shapePath(_ centerPoints: [CGPoint], aRadius: CGFloat, aLineHeight: CGFloat) -> UIBezierPath {
        
        let nbPoint = centerPoints.count
        guard nbPoint > 0, aRadius > 0 else { return UIBezierPath() }

        let path = UIBezierPath()
        var distanceBetweenCircles: CGFloat = 0
        
        if nbPoint > 1 {
            distanceBetweenCircles = centerPoints[1].x - centerPoints[0].x - 2 * aRadius
        }
        
        let angle = aLineHeight / 2.0 / aRadius
        var xCursor: CGFloat = 0
        
        for i in 0..<(2 * nbPoint) {
            let index = i >= nbPoint ? (nbPoint - 1) - (i - nbPoint) : i
            let centerPoint = centerPoints[index]
            
            let startAngle: CGFloat
            let endAngle: CGFloat
            
            if i == 0 {
                xCursor = centerPoint.x
                startAngle = .pi
                endAngle = -angle
            } else if i < nbPoint - 1 {
                startAngle = .pi + angle
                endAngle = -angle
            } else if i == (nbPoint - 1) {
                startAngle = .pi + angle
                endAngle = 0
            } else if i == nbPoint {
                startAngle = 0
                endAngle = .pi - angle
            } else if i < (2 * nbPoint - 1) {
                startAngle = angle
                endAngle = .pi - angle
            } else {
                startAngle = angle
                endAngle = .pi
            }
            
            path.addArc(withCenter: centerPoint, radius: aRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            if i < nbPoint - 1 {
                xCursor += aRadius + distanceBetweenCircles
                path.addLine(to: CGPoint(x: xCursor, y: centerPoint.y - aLineHeight / 2.0))
                xCursor += aRadius
            } else if i < (2 * nbPoint - 1) && i >= nbPoint {
                xCursor -= aRadius + distanceBetweenCircles
                path.addLine(to: CGPoint(x: xCursor, y: centerPoint.y + aLineHeight / 2.0))
                xCursor -= aRadius
            }
        }
        return path
    }
    
    private func shapePathForSelected(_ centerPoint: CGPoint, aRadius: CGFloat) -> UIBezierPath {
        return UIBezierPath(roundedRect: CGRect(x: centerPoint.x - aRadius, y: centerPoint.y - aRadius, width: 2.0 * aRadius, height: 2.0 * aRadius), cornerRadius: aRadius)
    }
    
    private func shapePathForLastState(_ center: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.addArc(withCenter: center, radius: _progressRadius + lastStateOuterCircleLineWidth, startAngle: 0, endAngle: 4 * .pi, clockwise: true)
        return path
    }
    
    private func shapePathForSelectedPathCenter(_ centerPoint: CGPoint, aRadius: CGFloat) -> UIBezierPath {
        return UIBezierPath(roundedRect: CGRect(x: centerPoint.x - aRadius, y: centerPoint.y - aRadius, width: 2.0 * aRadius, height: 2.0 * aRadius), cornerRadius: aRadius)
    }
    
    private func maskPath(_ currentProgressCenterPoint: CGPoint) -> UIBezierPath {
        guard _progressRadius > 0 else { return UIBezierPath() }
        let angle = _progressLineHeight / 2.0 / _progressRadius
        let xOffset = cos(angle) * _progressRadius
        let maskPath = UIBezierPath()
        
        maskPath.move(to: .zero)
        maskPath.addLine(to: CGPoint(x: currentProgressCenterPoint.x + xOffset, y: 0.0))
        maskPath.addLine(to: CGPoint(x: currentProgressCenterPoint.x + xOffset, y: currentProgressCenterPoint.y - _progressLineHeight))
        maskPath.addArc(withCenter: currentProgressCenterPoint, radius: _progressRadius, startAngle: -angle, endAngle: angle, clockwise: true)
        maskPath.addLine(to: CGPoint(x: currentProgressCenterPoint.x + xOffset, y: bounds.height))
        maskPath.addLine(to: CGPoint(x: 0.0, y: bounds.height))
        maskPath.close()
        
        return maskPath
    }
    
    // MARK: - Interactions
    
    @objc private func gestureAction(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .changed {
            let touchPoint = gestureRecognizer.location(in: self)
            var smallestDistance = CGFloat.infinity
            var selectedIndex = 0
            
            for (index, point) in centerPoints.enumerated() {
                // 使用我们更新后的拓展方法
                let distance = touchPoint.barDistance(to: point)
                if distance < smallestDistance {
                    smallestDistance = distance
                    selectedIndex = index
                }
            }
            
            if currentIndex != selectedIndex {
                let canSelect = delegate?.progressBar(self, canSelectItemAtIndex: selectedIndex) ?? true
                if canSelect {
                    if selectedIndex > completedTillIndex {
                        completedTillIndex = selectedIndex
                    }
                    currentIndex = selectedIndex
                    animationRendering = true
                }
            }
        }
    }
}
