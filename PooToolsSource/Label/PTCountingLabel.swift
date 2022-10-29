//
//  PTCountingLabel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/17.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import SwifterSwift

public let kPTLabelCounterRate:CGFloat = 3
public typealias PTCountingLabelAttributedFormatBlock = (CGFloat) -> NSAttributedString
public typealias PTCountingLabelFormatBlock = (CGFloat) -> String
public typealias PTCountingLabelShowCompletionBlock = () -> Void

public enum PTCountingLabelType {
    case Inout
    case In
    case Out
    case Linear
    
    func lineUpdate(t:CGFloat)->CGFloat
    {
        return t
    }
    
    func inUpdate(t:CGFloat)->CGFloat
    {
        return CGFloat(powf(Float(t), Float(kPTLabelCounterRate)))
    }
    
    func inOutUpdate(t:CGFloat)->CGFloat
    {
        var newT = t
        var sign = 1
        let r:Int = Int(kPTLabelCounterRate)
        if r % 2 == 0
        {
            sign -= 1
        }
        newT *= 2
        if t < 1
        {
            return  CGFloat(0.5 * powf(Float(newT), Float(kPTLabelCounterRate)))
        }
        else
        {
            return  CGFloat(sign) * CGFloat(0.5 * powf(Float(newT - 2), Float(kPTLabelCounterRate) + Float(sign * 2)))
        }
    }
}

@objcMembers
public class PTCountingLabel: UILabel {

    public var countingType:PTCountingLabelType = .Linear
    public var attributedFormatBlock:PTCountingLabelAttributedFormatBlock?
    public var formatBlock:PTCountingLabelFormatBlock?
    public var showCompletionBlock:PTCountingLabelShowCompletionBlock?
    public var format:String = "%f"
    {
        didSet
        {
            self.textValue(value: self.currentValue())
        }
    }
    ///如果浮点数需要千分位分隔符,须使用@"###,##0.00"进行控制样式
    public var positiveFormat:String = ""
    var progress:TimeInterval = 0
    var totalTime:TimeInterval = 0
    var lastUpdate:TimeInterval = 0
    var animationDuration:TimeInterval = 2
    var destinationValue:CGFloat = 0
    var startingValue:CGFloat = 0
    public func currentValue()->CGFloat
    {
        if self.progress >= self.totalTime
        {
            return self.destinationValue
        }
        
        let percent = self.progress / self.totalTime
        var updateVal:CGFloat = 0
        switch self.countingType {
        case .Linear:
            updateVal = self.countingType.lineUpdate(t: percent)
        case .In:
            updateVal = self.countingType.inUpdate(t: percent)
        case .Inout:
            updateVal = self.countingType.inOutUpdate(t: percent)
        default:
            break
        }
        return self.startingValue + (updateVal * (self.destinationValue - self.startingValue))
    }
    var timer:CADisplayLink?
    var easingRate:CGFloat = 3

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func countFrom(value:CGFloat,toValue:CGFloat)
    {
        self.countFrom(starValue: value, toValue: toValue, duration: self.animationDuration)
    }
    
    public func countFromCurrentValue(toValue:CGFloat)
    {
        self.countFrom(value: self.currentValue(), toValue: toValue)
    }
    
    public func countFormCurrentValue(toValue:CGFloat,duration:TimeInterval)
    {
        self.countFrom(starValue: self.currentValue(), toValue: toValue,duration: duration)
    }
    
    public func countFromZero(toValue:CGFloat)
    {
        self.countFrom(value: 0, toValue: toValue)
    }
    
    public func countFromZero(toValue:CGFloat,duration:TimeInterval)
    {
        self.countFrom(starValue: 0, toValue: toValue, duration: duration)
    }
    
    public func countFrom(starValue:CGFloat,toValue:CGFloat,duration:TimeInterval)
    {
        self.startingValue = starValue
        self.destinationValue = toValue
        
        self.timer?.invalidate()
        self.timer = nil
        
        if duration == 0
        {
            self.textValue(value: toValue)
            self.runCompletionBlock()
        }
        
        self.easingRate = 3
        self.progress = 0
        self.totalTime = duration
        
        self.lastUpdate = Date.timeIntervalSinceReferenceDate
        
        self.timer = CADisplayLink(target: self, selector: #selector(self.updateValue(timer:)))
        self.timer?.preferredFramesPerSecond = 60
        self.timer?.add(to: RunLoop.main, forMode: .default)
        self.timer?.add(to: RunLoop.main, forMode: .tracking)
    }
    
    @objc func updateValue(timer:Timer)
    {
        let now = Date.timeIntervalSinceReferenceDate
        self.progress += (now - self.lastUpdate)
        self.lastUpdate = now
        
        if self.progress >= self.totalTime
        {
            self.timer?.invalidate()
            self.timer = nil
            self.progress = self.totalTime
        }
        
        self.textValue(value: self.currentValue())
        
        if self.progress == self.totalTime
        {
            self.runCompletionBlock()
        }
    }
    
    func runCompletionBlock()
    {
        if self.showCompletionBlock != nil
        {
            self.showCompletionBlock!()
            self.showCompletionBlock = nil
        }
    }
    
    func textValue(value:CGFloat)
    {
        if self.attributedFormatBlock != nil
        {
            self.attributedText = self.attributedFormatBlock!(value)
        }
        else if self.formatBlock != nil
        {
            self.text = self.formatBlock!(value)
        }
        else
        {
            if self.format.nsString.range(of: "%(.*)d",options: NSString.CompareOptions.regularExpression).location != NSNotFound || self.format.nsString.range(of: "%(.*)i").location != NSNotFound
            {
                self.text = String(format: self.format, value)
            }
            else
            {
                if self.positiveFormat.nsString.length > 0
                {
                    let str = String(format: self.format, value)
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.positiveFormat = self.positiveFormat
                    self.text = String(format: "%@", formatter.string(from: NSNumber(floatLiteral: str.double()!))!)
                }
                else
                {
                    self.text = String(format: self.format, value)
                }
            }
        }
    }
}
