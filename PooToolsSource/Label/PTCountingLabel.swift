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
    
    func lineUpdate(t:CGFloat)->CGFloat {
        t
    }
    
    func inUpdate(t:CGFloat)->CGFloat {
        CGFloat(powf(Float(t), Float(kPTLabelCounterRate)))
    }
    
    func inOutUpdate(t:CGFloat)->CGFloat {
        var newT = t
        var sign = 1
        let r:Int = Int(kPTLabelCounterRate)
        if r % 2 == 0 {
            sign -= 1
        }
        newT *= 2
        if t < 1 {
            return  CGFloat(0.5 * powf(Float(newT), Float(kPTLabelCounterRate)))
        } else {
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
    public var format:String = "%f" {
        didSet {
            textValue(value: currentValue())
        }
    }
    
    //MARK: 如果浮点数需要千分位分隔符,须使用@"###,##0.00"进行控制样式
    ///如果浮点数需要千分位分隔符,须使用@"###,##0.00"进行控制样式
    public var positiveFormat:String = ""
    var progress:TimeInterval = 0
    var totalTime:TimeInterval = 0
    var lastUpdate:TimeInterval = 0
    var animationDuration:TimeInterval = 2
    var destinationValue:CGFloat = 0
    var startingValue:CGFloat = 0
    public func currentValue()->CGFloat {
        if progress >= totalTime {
            return destinationValue
        }
        
        let percent = progress / totalTime
        var updateVal:CGFloat = 0
        switch countingType {
        case .Linear:
            updateVal = countingType.lineUpdate(t: percent)
        case .In:
            updateVal = countingType.inUpdate(t: percent)
        case .Inout:
            updateVal = countingType.inOutUpdate(t: percent)
        default:
            break
        }
        return startingValue + (updateVal * (destinationValue - startingValue))
    }
    var timer:CADisplayLink?
    var easingRate:CGFloat = 3

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func countFrom(value:CGFloat,toValue:CGFloat) {
        self.countFrom(starValue: value, toValue: toValue, duration: animationDuration)
    }
    
    public func countFromCurrentValue(toValue:CGFloat) {
        self.countFrom(value: currentValue(), toValue: toValue)
    }
    
    public func countFormCurrentValue(toValue:CGFloat,duration:TimeInterval) {
        self.countFrom(starValue: currentValue(), toValue: toValue,duration: duration)
    }
    
    public func countFromZero(toValue:CGFloat) {
        self.countFrom(value: 0, toValue: toValue)
    }
    
    public func countFromZero(toValue:CGFloat,duration:TimeInterval) {
        self.countFrom(starValue: 0, toValue: toValue, duration: duration)
    }
    
    public func countFrom(starValue:CGFloat,toValue:CGFloat,duration:TimeInterval) {
        startingValue = starValue
        destinationValue = toValue
        
        timer?.invalidate()
        timer = nil
        
        if duration == 0 {
            textValue(value: toValue)
            runCompletionBlock()
        }
        
        easingRate = 3
        progress = 0
        totalTime = duration
        
        lastUpdate = Date.timeIntervalSinceReferenceDate
        
        timer = CADisplayLink(target: self, selector: #selector(updateValue(timer:)))
        timer?.preferredFramesPerSecond = 60
        timer?.add(to: RunLoop.main, forMode: .default)
        timer?.add(to: RunLoop.main, forMode: .tracking)
    }
    
    func updateValue(timer:Timer) {
        let now = Date.timeIntervalSinceReferenceDate
        progress += (now - lastUpdate)
        lastUpdate = now
        
        if progress >= totalTime {
            self.timer?.invalidate()
            self.timer = nil
            progress = totalTime
        }
        
        textValue(value: currentValue())
        
        if progress == totalTime {
            runCompletionBlock()
        }
    }
    
    func runCompletionBlock() {
        if showCompletionBlock != nil {
            showCompletionBlock!()
            showCompletionBlock = nil
        }
    }
    
    func textValue(value:CGFloat) {
        if attributedFormatBlock != nil {
            attributedText = attributedFormatBlock!(value)
        } else if formatBlock != nil {
            text = formatBlock!(value)
        } else {
            if format.nsString.range(of: "%(.*)d",options: NSString.CompareOptions.regularExpression).location != NSNotFound || format.nsString.range(of: "%(.*)i").location != NSNotFound {
                text = String(format: format, value)
            } else {
                if positiveFormat.nsString.length > 0 {
                    let str = String(format: format, value)
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.positiveFormat = positiveFormat
                    text = String(format: "%@", formatter.string(from: NSNumber(floatLiteral: str.double() ?? 0))!)
                } else {
                    text = String(format: format, value)
                }
            }
        }
    }
}
