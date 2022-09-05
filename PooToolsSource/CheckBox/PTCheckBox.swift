//
//  PTCheckBox.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/2.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public typealias PTCheckboxValueChangedBlock = (_ isChecked:Bool)->Void

public enum PTCheckBoxStyle:Int
{
    /// ■
    case Square
    /// ●
    case Circle
    /// ╳
    case Cross
    /// ✓
    case Tick
}

public enum PTCheckBoxBorderStyle:Int
{
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
    public var isChecked:Bool = true
    {
        didSet{
            self.setNeedsDisplay()
        }
    }
    public var useHapticFeedback:Bool = true
    public lazy var uncheckedBorderColor:UIColor = self.tintColor
    public lazy var checkedBorderColor:UIColor = self.tintColor
    public lazy var checkmarkColor:UIColor = self.tintColor
    public lazy var feedbackGenerator:UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupDefults()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupDefults()
    }
    
    public override func draw(_ rect: CGRect) {
        self.drawBorder(shappe: self.borderStyle, frame: rect)
        if self.isChecked
        {
            self.drawCheckmark(style: self.checkmarkStyle, frame: rect)
        }
    }
    
    func drawBorder(shappe:PTCheckBoxBorderStyle,frame:CGRect)
    {
        switch shappe {
        case .Square:
            self.squareBorder(frame: frame)
        case .Circle:
            self.circleBorder(frame: frame)
        }
    }
    
    func setupDefults()
    {
        self.backgroundColor = UIColor.init(white: 1, alpha: 0)
        let tap = UITapGestureRecognizer.init { sender in
            self.isChecked = !self.isChecked
            if self.valueChanged != nil
            {
                self.valueChanged!(self.isChecked)
            }
            self.sendActions(for: .valueChanged)
            
            if self.useHapticFeedback
            {
                self.feedbackGenerator.impactOccurred()
                self.feedbackGenerator.prepare()
            }
        }
        self.addGestureRecognizer(tap)
        
        if self.useHapticFeedback
        {
            self.feedbackGenerator.prepare()
        }
    }
    
    func squareBorder(frame:CGRect)
    {
        let rectanglePath = UIBezierPath.init(rect: frame)
        if self.isChecked
        {
            self.checkedBorderColor.setStroke()
        }
        else
        {
            self.uncheckedBorderColor.setStroke()
        }
        
        rectanglePath.lineWidth = self.boxBorderWidth
        rectanglePath.stroke()
        self.checkboxBackgroundColor.setFill()
        rectanglePath.fill()
    }
    
    func circleBorder(frame:CGRect)
    {
        let adjustedRect = CGRect.init(x: self.boxBorderWidth / 2, y: self.boxBorderWidth / 2, width: self.bounds.size.width - self.boxBorderWidth, height: self.bounds.size.height - self.boxBorderWidth)
        let ovalPath = UIBezierPath.init(rect: adjustedRect)
        
        if self.isChecked
        {
            self.checkedBorderColor.setStroke()
        }
        else
        {
            self.uncheckedBorderColor.setStroke()
        }
        
        ovalPath.lineWidth = self.boxBorderWidth / 2
        ovalPath.stroke()
        self.checkboxBackgroundColor.setFill()
        ovalPath.fill()
    }
    
    func drawCheckmark(style:PTCheckBoxStyle,frame:CGRect)
    {
        let adjustRect = self.checkmarkRect(rect: frame)
        switch style {
        case .Square:
            self.squareCheckmark(rect: adjustRect)
        case .Circle:
            self.circleCheckmark(rect: adjustRect)
        case .Cross:
            self.crossCheckmark(rect: adjustRect)
        case .Tick:
            self.tickCheckmark(rect: adjustRect)
        }
    }
    
    func circleCheckmark(rect:CGRect)
    {
        let ovalPath = UIBezierPath.init(ovalIn: rect)
        self.checkmarkColor.setFill()
        ovalPath.fill()
    }
    
    func squareCheckmark(rect:CGRect)
    {
        let ovalPath = UIBezierPath.init(rect: rect)
        self.checkmarkColor.setFill()
        ovalPath.fill()
    }
    
    func crossCheckmark(rect:CGRect)
    {
        let bezier4Path = UIBezierPath()
        bezier4Path.move(to: CGPoint.init(x: rect.minX + 0.06250 * rect.size.width, y: rect.minY + 0.06250 * rect.size.height))
        bezier4Path.addLine(to: CGPoint.init(x: rect.minX + 0.93750 * rect.size.width, y: rect.minY + 0.93548 * rect.size.height))
        bezier4Path.move(to: CGPoint.init(x: rect.minX + 0.93750 * rect.size.width, y: rect.minY + 0.06452 * rect.size.height))
        bezier4Path.addLine(to: CGPoint.init(x: rect.minX + 0.06250 * rect.size.width, y: rect.minY + 0.93548 * rect.size.height))
        self.checkmarkColor.setStroke()
        bezier4Path.lineWidth = self.checkmarkSize * 2
        bezier4Path.stroke()
    }
    
    func tickCheckmark(rect:CGRect)
    {
        let bezier4Path = UIBezierPath()
        bezier4Path.move(to: CGPoint.init(x: rect.minX + 0.4688 * rect.size.width, y: rect.minY + 0.63548 * rect.size.height))
        bezier4Path.addLine(to: CGPoint.init(x: rect.minX + 0.34896 * rect.size.width, y: rect.minY + 0.95161 * rect.size.height))
        bezier4Path.addLine(to: CGPoint.init(x: rect.minX + 0.95312 * rect.size.width, y: rect.minY + 0.04839 * rect.size.height))
        self.checkmarkColor.setStroke()
        bezier4Path.lineWidth = self.checkmarkSize * 2
        bezier4Path.stroke()
    }
    
    func checkmarkRect(rect:CGRect)->CGRect
    {
        let width = rect.maxX * self.checkmarkSize
        let height = rect.maxY * self.checkmarkSize
        let adjustedRect = CGRect.init(x: (rect.maxX - width) / 2, y: (rect.maxY - height) / 2, width: width, height: height)
        return adjustedRect
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let relativeFrame = self.bounds
        let hitTestEdgeInsets = UIEdgeInsets.init(top: -self.increasedTouchRadius, left: -self.increasedTouchRadius, bottom: -self.increasedTouchRadius, right: -self.increasedTouchRadius)
        let hitFrame = relativeFrame.inset(by: hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}
