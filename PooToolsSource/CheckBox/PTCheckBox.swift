//
//  PTCheckBox.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/2.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public typealias PTCheckboxValueChangedBlock = (_ isChecked:Bool)->Void

public enum PTCheckBoxStyle:Int {
    /// ■
    case Square
    /// ●
    case Circle
    /// ╳
    case Cross
    /// ✓
    case Tick
}

public enum PTCheckBoxBorderStyle:Int {
    /// ▢
    case Square
    /// ◯
    case Circle
}

@objcMembers
public class PTCheckBox: UIControl {
    
    public var valueChanged:PTCheckboxValueChangedBlock?
    
    public var checkmarkStyle:PTCheckBoxStyle = .Square
    public var borderStyle:PTCheckBoxBorderStyle = .Square
    public var boxBorderWidth:CGFloat = 2
    public var checkmarkSize:CGFloat = 0.5
    public var checkboxBackgroundColor:UIColor = .clear
    public var increasedTouchRadius:CGFloat = 5
    public var isChecked:Bool = true {
        didSet{
            self.setNeedsDisplay()
        }
    }
    public var useHapticFeedback:Bool = true
    public lazy var uncheckedBorderColor:UIColor = tintColor
    public lazy var checkedBorderColor:UIColor = tintColor
    public lazy var checkmarkColor:UIColor = tintColor
    public lazy var feedbackGenerator:UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefults()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDefults()
    }
    
    public override func draw(_ rect: CGRect) {
        drawBorder(shappe: borderStyle, frame: rect)
        if isChecked {
            drawCheckmark(style: checkmarkStyle, frame: rect)
        }
    }
    
    func drawBorder(shappe:PTCheckBoxBorderStyle,frame:CGRect) {
        switch shappe {
        case .Square:
            squareBorder(frame: frame)
        case .Circle:
            circleBorder(frame: frame)
        }
    }
    
    func setupDefults() {
        backgroundColor = UIColor.init(white: 1, alpha: 0)
        
        let tap = UITapGestureRecognizer { sender in
            self.isChecked = !self.isChecked
            if self.valueChanged != nil {
                self.valueChanged!(self.isChecked)
            }
            self.sendActions(for: .valueChanged)
            
            if self.useHapticFeedback {
                self.feedbackGenerator.impactOccurred()
                self.feedbackGenerator.prepare()
            }
        }
        addGestureRecognizer(tap)
        
        if useHapticFeedback {
            feedbackGenerator.prepare()
        }
    }
    
    func squareBorder(frame:CGRect) {
        let rectanglePath = UIBezierPath.init(rect: frame)
        if isChecked {
            checkedBorderColor.setStroke()
        } else {
            uncheckedBorderColor.setStroke()
        }
        
        rectanglePath.lineWidth = boxBorderWidth
        rectanglePath.stroke()
        checkboxBackgroundColor.setFill()
        rectanglePath.fill()
    }
    
    func circleBorder(frame:CGRect) {
        let adjustedRect = CGRect.init(x: boxBorderWidth / 2, y: boxBorderWidth / 2, width: bounds.size.width - boxBorderWidth, height: bounds.size.height - boxBorderWidth)
        let ovalPath = UIBezierPath.init(rect: adjustedRect)
        
        if isChecked {
            checkedBorderColor.setStroke()
        } else {
            uncheckedBorderColor.setStroke()
        }
        
        ovalPath.lineWidth = boxBorderWidth / 2
        ovalPath.stroke()
        checkboxBackgroundColor.setFill()
        ovalPath.fill()
    }
    
    func drawCheckmark(style:PTCheckBoxStyle,frame:CGRect) {
        let adjustRect = checkmarkRect(rect: frame)
        switch style {
        case .Square:
            squareCheckmark(rect: adjustRect)
        case .Circle:
            circleCheckmark(rect: adjustRect)
        case .Cross:
            crossCheckmark(rect: adjustRect)
        case .Tick:
            tickCheckmark(rect: adjustRect)
        }
    }
    
    func circleCheckmark(rect:CGRect) {
        let ovalPath = UIBezierPath.init(ovalIn: rect)
        checkmarkColor.setFill()
        ovalPath.fill()
    }
    
    func squareCheckmark(rect:CGRect) {
        let ovalPath = UIBezierPath.init(rect: rect)
        checkmarkColor.setFill()
        ovalPath.fill()
    }
    
    func crossCheckmark(rect:CGRect) {
        let bezier4Path = UIBezierPath()
        bezier4Path.move(to: CGPoint.init(x: rect.minX + 0.06250 * rect.size.width, y: rect.minY + 0.06250 * rect.size.height))
        bezier4Path.addLine(to: CGPoint.init(x: rect.minX + 0.93750 * rect.size.width, y: rect.minY + 0.93548 * rect.size.height))
        bezier4Path.move(to: CGPoint.init(x: rect.minX + 0.93750 * rect.size.width, y: rect.minY + 0.06452 * rect.size.height))
        bezier4Path.addLine(to: CGPoint.init(x: rect.minX + 0.06250 * rect.size.width, y: rect.minY + 0.93548 * rect.size.height))
        checkmarkColor.setStroke()
        bezier4Path.lineWidth = checkmarkSize * 2
        bezier4Path.stroke()
    }
    
    func tickCheckmark(rect:CGRect) {
        let bezier4Path = UIBezierPath()
        bezier4Path.move(to: CGPoint.init(x: rect.minX + 0.4688 * rect.size.width, y: rect.minY + 0.63548 * rect.size.height))
        bezier4Path.addLine(to: CGPoint.init(x: rect.minX + 0.34896 * rect.size.width, y: rect.minY + 0.95161 * rect.size.height))
        bezier4Path.addLine(to: CGPoint.init(x: rect.minX + 0.95312 * rect.size.width, y: rect.minY + 0.04839 * rect.size.height))
        checkmarkColor.setStroke()
        bezier4Path.lineWidth = checkmarkSize * 2
        bezier4Path.stroke()
    }
    
    func checkmarkRect(rect:CGRect)->CGRect {
        let width = rect.maxX * checkmarkSize
        let height = rect.maxY * checkmarkSize
        let adjustedRect = CGRect.init(x: (rect.maxX - width) / 2, y: (rect.maxY - height) / 2, width: width, height: height)
        return adjustedRect
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let relativeFrame = bounds
        let hitTestEdgeInsets = UIEdgeInsets.init(top: -increasedTouchRadius, left: -increasedTouchRadius, bottom: -increasedTouchRadius, right: -increasedTouchRadius)
        let hitFrame = relativeFrame.inset(by: hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}
