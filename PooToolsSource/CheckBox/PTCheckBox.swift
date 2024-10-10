//
//  PTCheckBox.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/2.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public typealias PTCheckboxValueChangedBlock = (_ isChecked: Bool) -> Void

public enum PTCheckBoxStyle: Int {
    /// ■
    case Square
    /// ●
    case Circle
    /// ╳
    case Cross
    /// ✓
    case Tick
}

public enum PTCheckBoxBorderStyle: Int {
    /// ▢
    case Square
    /// ◯
    case Circle
}

@objcMembers
public class PTCheckBox: UIControl {
    ///回调
    open var valueChanged: PTCheckboxValueChangedBlock?
    ///外风格
    open var checkmarkStyle: PTCheckBoxStyle = .Square
    ///内风格
    open var borderStyle: PTCheckBoxBorderStyle = .Square
    ///外部线宽度
    open var boxBorderWidth: CGFloat = 2
    ///内部占比/线宽度
    open var checkmarkSize: CGFloat = 0.5
    ///底部颜色
    open var checkboxBackgroundColor: UIColor = .clear
    ///触摸范围
    open var increasedTouchRadius: CGFloat = 5
    ///是否已经点击
    open var isChecked: Bool = true {
        didSet {
            self.updateUI()
        }
    }
    ///点击震动
    open var useHapticFeedback: Bool = true
    ///边框未选颜色
    open lazy var uncheckedBorderColor: UIColor = tintColor
    ///边框选颜色
    open lazy var checkedBorderColor: UIColor = tintColor
    ///内部颜色
    open lazy var checkmarkColor: UIColor = tintColor
    
    fileprivate lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        if self.useHapticFeedback {
            generator.prepare()
        }
        return generator
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaults()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDefaults()
    }

    private func setupDefaults() {
        backgroundColor = .clear
        accessibilityValue = isChecked ? "Checked" : "Unchecked"
        
        let tap = UITapGestureRecognizer { _ in
            self.isChecked.toggle()
            self.valueChanged?(self.isChecked)
            self.sendActions(for: .valueChanged)
            
            if self.useHapticFeedback {
                self.feedbackGenerator.impactOccurred()
                self.feedbackGenerator.prepare()
            }
        }
        addGestureRecognizer(tap)
    }

    private func updateUI() {
        setNeedsDisplay()
        accessibilityValue = isChecked ? "Checked" : "Unchecked"
    }

    public override func draw(_ rect: CGRect) {
        drawBorder(shape: borderStyle, frame: rect)
        if isChecked {
            drawCheckmark(style: checkmarkStyle, frame: rect)
        }
    }
    
    private func drawBorder(shape: PTCheckBoxBorderStyle, frame: CGRect) {
        switch shape {
        case .Square:
            squareBorder(frame: frame)
        case .Circle:
            circleBorder(frame: frame)
        }
    }
    
    private func squareBorder(frame: CGRect) {
        let rectanglePath = UIBezierPath(rect: frame)
        let borderColor = isChecked ? checkedBorderColor : uncheckedBorderColor
        borderColor.setStroke()
        rectanglePath.lineWidth = boxBorderWidth
        rectanglePath.stroke()
        checkboxBackgroundColor.setFill()
        rectanglePath.fill()
    }

    private func circleBorder(frame: CGRect) {
        let adjustedRect = frame.insetBy(dx: boxBorderWidth / 2, dy: boxBorderWidth / 2)
        let ovalPath = UIBezierPath(ovalIn: adjustedRect)
        let borderColor = isChecked ? checkedBorderColor : uncheckedBorderColor
        borderColor.setStroke()
        ovalPath.lineWidth = boxBorderWidth / 2
        ovalPath.stroke()
        checkboxBackgroundColor.setFill()
        ovalPath.fill()
    }
    
    private func drawCheckmark(style: PTCheckBoxStyle, frame: CGRect) {
        let adjustedRect = checkmarkRect(rect: frame)
        switch style {
        case .Square:
            squareCheckmark(rect: adjustedRect)
        case .Circle:
            circleCheckmark(rect: adjustedRect)
        case .Cross:
            crossCheckmark(rect: adjustedRect)
        case .Tick:
            tickCheckmark(rect: adjustedRect)
        }
    }
    
    private func squareCheckmark(rect: CGRect) {
        let path = UIBezierPath(rect: rect)
        checkmarkColor.setFill()
        path.fill()
    }
    
    private func circleCheckmark(rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        checkmarkColor.setFill()
        path.fill()
    }
    
    private func crossCheckmark(rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        checkmarkColor.setStroke()
        path.lineWidth = checkmarkSize * 2
        path.stroke()
    }

    private func tickCheckmark(rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + 0.3 * rect.size.width, y: rect.minY + 0.5 * rect.size.height))
        path.addLine(to: CGPoint(x: rect.minX + 0.5 * rect.size.width, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        checkmarkColor.setStroke()
        path.lineWidth = checkmarkSize * 2
        path.stroke()
    }

    private func checkmarkRect(rect: CGRect) -> CGRect {
        let width = rect.width * checkmarkSize
        let height = rect.height * checkmarkSize
        return CGRect(x: (rect.width - width) / 2, y: (rect.height - height) / 2, width: width, height: height)
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let hitTestInsets = UIEdgeInsets(top: -increasedTouchRadius, left: -increasedTouchRadius, bottom: -increasedTouchRadius, right: -increasedTouchRadius)
        let hitFrame = bounds.inset(by: hitTestInsets)
        return hitFrame.contains(point)
    }
}
