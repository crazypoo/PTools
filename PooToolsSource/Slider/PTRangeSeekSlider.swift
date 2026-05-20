//
//  PTRangeSeekSlider.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/5/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import CoreGraphics

// MARK: - Taptic Engine Wrapper
/// 封装设备的触觉反馈引擎 (Haptic Feedback)
/// Swift 6 要求与 UI 和硬件反馈交互的类标注 @MainActor
@MainActor
open class TapticEngine {

    public static let impact: Impact = Impact()
    public static let selection: Selection = Selection()
    public static let notification: Notification = Notification()

    /// 包装 `UIImpactFeedbackGenerator` (物理碰撞感)
    @MainActor
    open class Impact {
        public enum ImpactStyle {
            case light, medium, heavy, soft, rigid
            
            var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
                switch self {
                case .light: return .light
                case .medium: return .medium
                case .heavy: return .heavy
                case .soft: return .soft
                case .rigid: return .rigid
                }
            }
        }

        private var style: ImpactStyle = .light
        private var generator: UIImpactFeedbackGenerator? = UIImpactFeedbackGenerator(style: .light)

        private func updateGeneratorIfNeeded(_ style: ImpactStyle) {
            guard self.style != style else { return }
            generator = UIImpactFeedbackGenerator(style: style.feedbackStyle)
            generator?.prepare()
            self.style = style
        }

        public func feedback(_ style: ImpactStyle) {
            updateGeneratorIfNeeded(style)
            generator?.impactOccurred()
            generator?.prepare()
        }

        public func prepare(_ style: ImpactStyle) {
            updateGeneratorIfNeeded(style)
            generator?.prepare()
        }
    }

    /// 包装 `UISelectionFeedbackGenerator` (选择切换感)
    @MainActor
    open class Selection {
        private var generator: UISelectionFeedbackGenerator? = {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            return generator
        }()

        public func feedback() {
            generator?.selectionChanged()
            generator?.prepare()
        }

        public func prepare() {
            generator?.prepare()
        }
    }

    /// 包装 `UINotificationFeedbackGenerator` (成功、警告、错误提示)
    @MainActor
    open class Notification {
        public enum NotificationType {
            case success, warning, error
            
            var feedbackType: UINotificationFeedbackGenerator.FeedbackType {
                switch self {
                case .success: return .success
                case .warning: return .warning
                case .error: return .error
                }
            }
        }

        private var generator: UINotificationFeedbackGenerator? = {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            return generator
        }()

        public func feedback(_ type: NotificationType) {
            generator?.notificationOccurred(type.feedbackType)
            generator?.prepare()
        }

        public func prepare() {
            generator?.prepare()
        }
    }
}

// MARK: - Range Slider Delegate

/// 滑块回调代理
/// 修复：将 `class` 替换为 `AnyObject`，适配 Swift 6 规范
@MainActor
public protocol PTRangeSeekSliderDelegate: AnyObject {
    func rangeSeekSlider(_ slider: PTRangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat)
    func didStartTouches(in slider: PTRangeSeekSlider)
    func didEndTouches(in slider: PTRangeSeekSlider)
    func rangeSeekSlider(_ slider: PTRangeSeekSlider, stringForMinValue minValue: CGFloat) -> String?
    
    // 修复：补全了原来遗漏的参数名 maxValue
    func rangeSeekSlider(_ slider: PTRangeSeekSlider, stringForMaxValue maxValue: CGFloat) -> String?
}

// 提供默认实现，使得协议方法成为可选(Optional)
public extension PTRangeSeekSliderDelegate {
    func rangeSeekSlider(_ slider: PTRangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat) {}
    func didStartTouches(in slider: PTRangeSeekSlider) {}
    func didEndTouches(in slider: PTRangeSeekSlider) {}
    func rangeSeekSlider(_ slider: PTRangeSeekSlider, stringForMinValue minValue: CGFloat) -> String? { return nil }
    func rangeSeekSlider(_ slider: PTRangeSeekSlider, stringForMaxValue maxValue: CGFloat) -> String? { return nil }
}

// MARK: - Main Slider Class

@IBDesignable
@MainActor
open class PTRangeSeekSlider: UIControl {

    // MARK: - Initializers

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public required override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    // 修复：闭包参数类型从 RangeSeekSlider 修改为 PTRangeSeekSlider
    public convenience init(frame: CGRect = .zero, completion: ((PTRangeSeekSlider) -> Void)? = nil) {
        self.init(frame: frame)
        completion?(self)
    }

    // MARK: - Open Properties

    // 修复：类型更正为 PTRangeSeekSliderDelegate
    open weak var delegate: PTRangeSeekSliderDelegate?

    @IBInspectable open var minValue: CGFloat = 0.0 { didSet { refresh() } }
    @IBInspectable open var maxValue: CGFloat = 100.0 { didSet { refresh() } }

    @IBInspectable open var selectedMinValue: CGFloat = 0.0 {
        didSet { if selectedMinValue < minValue { selectedMinValue = minValue } }
    }

    @IBInspectable open var selectedMaxValue: CGFloat = 100.0 {
        didSet { if selectedMaxValue > maxValue { selectedMaxValue = maxValue } }
    }

    open var minLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0) {
        didSet {
            minLabel.font = minLabelFont as CFTypeRef
            minLabel.fontSize = minLabelFont.pointSize
        }
    }

    open var maxLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0) {
        didSet {
            maxLabel.font = maxLabelFont as CFTypeRef
            maxLabel.fontSize = maxLabelFont.pointSize
        }
    }

    open var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    @IBInspectable open var hideLabels: Bool = false {
        didSet {
            minLabel.isHidden = hideLabels
            maxLabel.isHidden = hideLabels
        }
    }

    @IBInspectable open var labelsFixed: Bool = false
    @IBInspectable open var minDistance: CGFloat = 0.0 { didSet { if minDistance < 0.0 { minDistance = 0.0 } } }
    @IBInspectable open var maxDistance: CGFloat = .greatestFiniteMagnitude { didSet { if maxDistance < 0.0 { maxDistance = .greatestFiniteMagnitude } } }

    @IBInspectable open var minLabelColor: UIColor?
    @IBInspectable open var maxLabelColor: UIColor?
    @IBInspectable open var handleColor: UIColor?
    @IBInspectable open var handleBorderColor: UIColor?
    @IBInspectable open var colorBetweenHandles: UIColor?
    @IBInspectable open var initialColor: UIColor?

    @IBInspectable open var disableRange: Bool = false {
        didSet {
            leftHandle.isHidden = disableRange
            minLabel.isHidden = disableRange
        }
    }

    @IBInspectable open var enableStep: Bool = false
    @IBInspectable open var step: CGFloat = 0.0

    @IBInspectable open var handleImage: UIImage? {
        didSet {
            guard let image = handleImage else { return }
            let handleFrame = CGRect(origin: .zero, size: image.size)
            leftHandle.frame = handleFrame
            leftHandle.contents = image.cgImage
            rightHandle.frame = handleFrame
            rightHandle.contents = image.cgImage
        }
    }

    @IBInspectable open var handleDiameter: CGFloat = 16.0 {
        didSet {
            leftHandle.cornerRadius = handleDiameter / 2.0
            rightHandle.cornerRadius = handleDiameter / 2.0
            leftHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
            rightHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
        }
    }

    @IBInspectable open var selectedHandleDiameterMultiplier: CGFloat = 1.7

    @IBInspectable open var lineHeight: CGFloat = 1.0 { didSet { updateLineHeight() } }
    @IBInspectable open var handleBorderWidth: CGFloat = 0.0 {
        didSet {
            leftHandle.borderWidth = handleBorderWidth
            rightHandle.borderWidth = handleBorderWidth
        }
    }
    @IBInspectable open var labelPadding: CGFloat = 8.0 { didSet { updateLabelPositions() } }

    @IBInspectable open var minLabelAccessibilityLabel: String?
    @IBInspectable open var maxLabelAccessibilityLabel: String?
    @IBInspectable open var minLabelAccessibilityHint: String?
    @IBInspectable open var maxLabelAccessibilityHint: String?

    // MARK: - Private Properties

    private enum HandleTracking { case none, left, right }
    private var handleTracking: HandleTracking = .none

    private let sliderLine: CALayer = CALayer()
    private let sliderLineBetweenHandles: CALayer = CALayer()
    private let leftHandle: CALayer = CALayer()
    private let rightHandle: CALayer = CALayer()

    fileprivate let minLabel: CATextLayer = CATextLayer()
    fileprivate let maxLabel: CATextLayer = CATextLayer()

    private var minLabelTextSize: CGSize = .zero
    private var maxLabelTextSize: CGSize = .zero

    private var previousStepMinValue: CGFloat?
    private var previousStepMaxValue: CGFloat?

    private var accessibleElements: [UIAccessibilityElement] = []

    // MARK: - Computed Properties

    private var leftHandleAccessibilityElement: UIAccessibilityElement {
        let element = RangeSeekSliderLeftElement(accessibilityContainer: self)
        element.isAccessibilityElement = true
        element.accessibilityLabel = minLabelAccessibilityLabel
        element.accessibilityHint = minLabelAccessibilityHint
        element.accessibilityValue = minLabel.string as? String
        element.accessibilityFrame = convert(leftHandle.frame, to: nil)
        element.accessibilityTraits = .adjustable
        return element
    }

    private var rightHandleAccessibilityElement: UIAccessibilityElement {
        let element = RangeSeekSliderRightElement(accessibilityContainer: self)
        element.isAccessibilityElement = true
        element.accessibilityLabel = maxLabelAccessibilityLabel
        element.accessibilityHint = maxLabelAccessibilityHint
        element.accessibilityValue = maxLabel.string as? String
        element.accessibilityFrame = convert(rightHandle.frame, to: nil)
        element.accessibilityTraits = .adjustable
        return element
    }

    // MARK: - UIView Lifecycle

    open override func layoutSubviews() {
        super.layoutSubviews()
        if handleTracking == .none {
            updateLineHeight()
            updateLabelValues()
            updateColors()
            updateHandlePositions()
            updateLabelPositions()
        }
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 65.0)
    }

    // MARK: - UIControl Touch Tracking

    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchLocation = touch.location(in: self)
        let insetExpansion: CGFloat = -30.0
        
        let isTouchingLeftHandle = leftHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)
        let isTouchingRightHandle = rightHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)

        guard isTouchingLeftHandle || isTouchingRightHandle else { return false }

        let distanceFromLeftHandle = touchLocation.distance(to: leftHandle.frame.center)
        let distanceFromRightHandle = touchLocation.distance(to: rightHandle.frame.center)

        if distanceFromLeftHandle < distanceFromRightHandle && !disableRange {
            handleTracking = .left
        } else if selectedMaxValue == maxValue && leftHandle.frame.midX == rightHandle.frame.midX {
            handleTracking = .left
        } else {
            handleTracking = .right
        }
        
        let handle = (handleTracking == .left) ? leftHandle : rightHandle
        animate(handle: handle, selected: true)
        delegate?.didStartTouches(in: self)

        return true
    }

    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard handleTracking != .none else { return false }

        let location = touch.location(in: self)
        let percentage = (location.x - sliderLine.frame.minX - handleDiameter / 2.0) / (sliderLine.frame.maxX - sliderLine.frame.minX)
        let selectedValue = percentage * (maxValue - minValue) + minValue

        switch handleTracking {
        case .left:
            selectedMinValue = min(selectedValue, selectedMaxValue)
        case .right:
            if disableRange && selectedValue >= minValue {
                selectedMaxValue = selectedValue
            } else {
                selectedMaxValue = max(selectedValue, selectedMinValue)
            }
        case .none:
            break
        }

        refresh()
        return true
    }

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        let handle = (handleTracking == .left) ? leftHandle : rightHandle
        animate(handle: handle, selected: false)
        handleTracking = .none
        delegate?.didEndTouches(in: self)
    }

    // MARK: - UIAccessibility

    open override func accessibilityElementCount() -> Int { return accessibleElements.count }
    open override func accessibilityElement(at index: Int) -> Any? { return accessibleElements[index] }
    open override func index(ofAccessibilityElement element: Any) -> Int {
        guard let element = element as? UIAccessibilityElement else { return 0 }
        return accessibleElements.firstIndex(of: element) ?? 0
    }

    // MARK: - Open Methods

    open func setupStyle() {}

    // MARK: - Private Methods

    private func setup() {
        isAccessibilityElement = false
        accessibleElements = [leftHandleAccessibilityElement, rightHandleAccessibilityElement]

        layer.addSublayer(sliderLine)
        layer.addSublayer(sliderLineBetweenHandles)

        leftHandle.cornerRadius = handleDiameter / 2.0
        leftHandle.borderWidth = handleBorderWidth
        layer.addSublayer(leftHandle)

        rightHandle.cornerRadius = handleDiameter / 2.0
        rightHandle.borderWidth = handleBorderWidth
        layer.addSublayer(rightHandle)

        let handleFrame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
        leftHandle.frame = handleFrame
        rightHandle.frame = handleFrame

        let labelFontSize: CGFloat = 12.0
        let labelFrame = CGRect(x: 0.0, y: 50.0, width: 75.0, height: 14.0)

        minLabelFont = UIFont.systemFont(ofSize: labelFontSize)
        minLabel.alignmentMode = .center
        minLabel.frame = labelFrame
        minLabel.contentsScale = UIScreen.main.scale
        layer.addSublayer(minLabel)

        maxLabelFont = UIFont.systemFont(ofSize: labelFontSize)
        maxLabel.alignmentMode = .center
        maxLabel.frame = labelFrame
        maxLabel.contentsScale = UIScreen.main.scale
        layer.addSublayer(maxLabel)

        setupStyle()
        refresh()
    }

    private func percentageAlongLine(for value: CGFloat) -> CGFloat {
        guard minValue < maxValue else { return 0.0 }
        let maxMinDif = maxValue - minValue
        let valueSubtracted = value - minValue
        return valueSubtracted / maxMinDif
    }

    private func xPositionAlongLine(for value: CGFloat) -> CGFloat {
        let percentage = percentageAlongLine(for: value)
        let maxMinDif = sliderLine.frame.maxX - sliderLine.frame.minX
        let offset = percentage * maxMinDif
        return sliderLine.frame.minX + offset
    }

    private func updateLineHeight() {
        let barSidePadding: CGFloat = 16.0
        let yMiddle = frame.height / 2.0
        let lineLeftSide = CGPoint(x: barSidePadding, y: yMiddle)
        let lineRightSide = CGPoint(x: frame.width - barSidePadding, y: yMiddle)
        
        sliderLine.frame = CGRect(x: lineLeftSide.x, y: lineLeftSide.y, width: lineRightSide.x - lineLeftSide.x, height: lineHeight)
        sliderLine.cornerRadius = lineHeight / 2.0
        sliderLineBetweenHandles.cornerRadius = sliderLine.cornerRadius
    }

    private func updateLabelValues() {
        minLabel.isHidden = hideLabels || disableRange
        maxLabel.isHidden = hideLabels

        if let replacedString = delegate?.rangeSeekSlider(self, stringForMinValue: selectedMinValue) {
            minLabel.string = replacedString
        } else {
            minLabel.string = numberFormatter.string(from: selectedMinValue as NSNumber)
        }

        if let replacedString = delegate?.rangeSeekSlider(self, stringForMaxValue: selectedMaxValue) {
            maxLabel.string = replacedString
        } else {
            maxLabel.string = numberFormatter.string(from: selectedMaxValue as NSNumber)
        }

        if let nsstring = minLabel.string as? NSString {
            minLabelTextSize = nsstring.size(withAttributes: [.font: minLabelFont])
        }

        if let nsstring = maxLabel.string as? NSString {
            maxLabelTextSize = nsstring.size(withAttributes: [.font: maxLabelFont])
        }
    }

    private func updateColors() {
        let isInitial = selectedMinValue == minValue && selectedMaxValue == maxValue
        if let initialColor = initialColor?.cgColor, isInitial {
            minLabel.foregroundColor = initialColor
            maxLabel.foregroundColor = initialColor
            sliderLineBetweenHandles.backgroundColor = initialColor
            sliderLine.backgroundColor = initialColor

            let color = (handleImage == nil) ? initialColor : UIColor.clear.cgColor
            leftHandle.backgroundColor = color
            leftHandle.borderColor = color
            rightHandle.backgroundColor = color
            rightHandle.borderColor = color
        } else {
            let tintCGColor = tintColor.cgColor
            minLabel.foregroundColor = minLabelColor?.cgColor ?? tintCGColor
            maxLabel.foregroundColor = maxLabelColor?.cgColor ?? tintCGColor
            sliderLineBetweenHandles.backgroundColor = colorBetweenHandles?.cgColor ?? tintCGColor
            sliderLine.backgroundColor = tintCGColor

            let color = handleImage != nil ? UIColor.clear.cgColor : (handleColor?.cgColor ?? tintCGColor)
            leftHandle.backgroundColor = color
            leftHandle.borderColor = handleBorderColor?.cgColor
            rightHandle.backgroundColor = color
            rightHandle.borderColor = handleBorderColor?.cgColor
        }
    }

    private func updateAccessibilityElements() {
        accessibleElements = [leftHandleAccessibilityElement, rightHandleAccessibilityElement]
    }

    private func updateHandlePositions() {
        leftHandle.position = CGPoint(x: xPositionAlongLine(for: selectedMinValue), y: sliderLine.frame.midY)
        rightHandle.position = CGPoint(x: xPositionAlongLine(for: selectedMaxValue), y: sliderLine.frame.midY)

        sliderLineBetweenHandles.frame = CGRect(
            x: leftHandle.position.x,
            y: sliderLine.frame.minY,
            width: rightHandle.position.x - leftHandle.position.x,
            height: lineHeight
        )
    }
    
    private func updateLabelPositions() {
        minLabel.frame.size = minLabelTextSize
        maxLabel.frame.size = maxLabelTextSize

        if labelsFixed {
            updateFixedLabelPositions()
            return
        }

        let minSpacingBetweenLabels: CGFloat = 8.0
        let newMinLabelCenter = CGPoint(x: leftHandle.frame.midX, y: leftHandle.frame.maxY + (minLabelTextSize.height/2) + labelPadding)
        let newMaxLabelCenter = CGPoint(x: rightHandle.frame.midX, y: rightHandle.frame.maxY + (maxLabelTextSize.height/2) + labelPadding)
        
        let newLeftMostXInMaxLabel = newMaxLabelCenter.x - maxLabelTextSize.width / 2.0
        let newRightMostXInMinLabel = newMinLabelCenter.x + minLabelTextSize.width / 2.0
        let newSpacingBetweenTextLabels = newLeftMostXInMaxLabel - newRightMostXInMinLabel

        if disableRange || newSpacingBetweenTextLabels > minSpacingBetweenLabels {
            minLabel.position = newMinLabelCenter
            maxLabel.position = newMaxLabelCenter

            if minLabel.frame.minX < 0.0 { minLabel.frame.origin.x = 0.0 }
            if maxLabel.frame.maxX > frame.width { maxLabel.frame.origin.x = frame.width - maxLabel.frame.width }
        } else {
            let increaseAmount = minSpacingBetweenLabels - newSpacingBetweenTextLabels
            minLabel.position = CGPoint(x: newMinLabelCenter.x - increaseAmount / 2.0, y: newMinLabelCenter.y)
            maxLabel.position = CGPoint(x: newMaxLabelCenter.x + increaseAmount / 2.0, y: newMaxLabelCenter.y)

            if minLabel.position.x == maxLabel.position.x {
                minLabel.position.x = leftHandle.frame.midX
                maxLabel.position.x = leftHandle.frame.midX + minLabel.frame.width / 2.0 + minSpacingBetweenLabels + maxLabel.frame.width / 2.0
            }

            if minLabel.frame.minX < 0.0 {
                minLabel.frame.origin.x = 0.0
                maxLabel.frame.origin.x = minSpacingBetweenLabels + minLabel.frame.width
            }

            if maxLabel.frame.maxX > frame.width {
                maxLabel.frame.origin.x = frame.width - maxLabel.frame.width
                minLabel.frame.origin.x = maxLabel.frame.origin.x - minSpacingBetweenLabels - minLabel.frame.width
            }
        }
    }

    private func updateFixedLabelPositions() {
        minLabel.position = CGPoint(
            x: xPositionAlongLine(for: minValue),
            y: sliderLine.frame.minY - (minLabelTextSize.height / 2.0) - (handleDiameter / 2.0) - labelPadding
        )
        maxLabel.position = CGPoint(
            x: xPositionAlongLine(for: maxValue),
            y: sliderLine.frame.minY - (maxLabelTextSize.height / 2.0) - (handleDiameter / 2.0) - labelPadding
        )
        
        if minLabel.frame.minX < 0.0 { minLabel.frame.origin.x = 0.0 }
        if maxLabel.frame.maxX > frame.width { maxLabel.frame.origin.x = frame.width - maxLabel.frame.width }
    }

    fileprivate func refresh() {
        if enableStep && step > 0.0 {
            // 性能优化：直接使用原生的 CGFloat .rounded() 替代 roundf(Float(...)) 转换
            selectedMinValue = (selectedMinValue / step).rounded() * step
            if let previousStepMinValue = previousStepMinValue, previousStepMinValue != selectedMinValue {
                TapticEngine.selection.feedback()
            }
            previousStepMinValue = selectedMinValue

            selectedMaxValue = (selectedMaxValue / step).rounded() * step
            if let previousStepMaxValue = previousStepMaxValue, previousStepMaxValue != selectedMaxValue {
                TapticEngine.selection.feedback()
            }
            previousStepMaxValue = selectedMaxValue
        }

        let diff = selectedMaxValue - selectedMinValue

        if diff < minDistance {
            switch handleTracking {
            case .left: selectedMinValue = selectedMaxValue - minDistance
            case .right: selectedMaxValue = selectedMinValue + minDistance
            case .none: break
            }
        } else if diff > maxDistance {
            switch handleTracking {
            case .left: selectedMinValue = selectedMaxValue - maxDistance
            case .right: selectedMaxValue = selectedMinValue + maxDistance
            case .none: break
            }
        }

        if selectedMinValue < minValue { selectedMinValue = minValue }
        if selectedMaxValue > maxValue { selectedMaxValue = maxValue }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateHandlePositions()
        updateLabelPositions()
        CATransaction.commit()

        updateLabelValues()
        updateColors()
        updateAccessibilityElements()

        if let delegate = delegate, handleTracking != .none {
            delegate.rangeSeekSlider(self, didChange: selectedMinValue, maxValue: selectedMaxValue)
        }
    }

    private func animate(handle: CALayer, selected: Bool) {
        let transform = selected ? CATransform3DMakeScale(selectedHandleDiameterMultiplier, selectedHandleDiameterMultiplier, 1.0) : CATransform3DIdentity

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        handle.transform = transform
        updateLabelPositions()
        CATransaction.commit()
    }
}

// MARK: - Accessibility Elements

private final class RangeSeekSliderLeftElement: UIAccessibilityElement {
    override func accessibilityIncrement() {
        guard let slider = accessibilityContainer as? PTRangeSeekSlider else { return }
        slider.selectedMinValue += slider.step
        accessibilityValue = slider.minLabel.string as? String
    }

    override func accessibilityDecrement() {
        guard let slider = accessibilityContainer as? PTRangeSeekSlider else { return }
        slider.selectedMinValue -= slider.step
        accessibilityValue = slider.minLabel.string as? String
    }
}

private final class RangeSeekSliderRightElement: UIAccessibilityElement {
    override func accessibilityIncrement() {
        guard let slider = accessibilityContainer as? PTRangeSeekSlider else { return }
        slider.selectedMaxValue += slider.step
        slider.refresh()
        accessibilityValue = slider.maxLabel.string as? String
    }

    override func accessibilityDecrement() {
        guard let slider = accessibilityContainer as? PTRangeSeekSlider else { return }
        slider.selectedMaxValue -= slider.step
        slider.refresh()
        accessibilityValue = slider.maxLabel.string as? String
    }
}
