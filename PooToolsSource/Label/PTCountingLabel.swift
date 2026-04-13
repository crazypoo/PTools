//
//  PTCountingLabel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/17.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation

public let kPTLabelCounterRate: CGFloat = 3
public typealias PTCountingLabelAttributedFormatBlock = (CGFloat) -> NSAttributedString
public typealias PTCountingLabelFormatBlock = (CGFloat) -> String

public enum PTCountingLabelType {
    case Inout
    case In
    case Out
    case Linear
    
    func lineUpdate(t: CGFloat) -> CGFloat {
        return t
    }
    
    func inUpdate(t: CGFloat) -> CGFloat {
        return CGFloat(powf(Float(t), Float(kPTLabelCounterRate)))
    }
    
    func inOutUpdate(t: CGFloat) -> CGFloat {
        var newT = t
        var sign = 1
        let r: Int = Int(kPTLabelCounterRate)
        if r % 2 == 0 {
            sign -= 1
        }
        newT *= 2
        if t < 1 {
            return CGFloat(0.5 * powf(Float(newT), Float(kPTLabelCounterRate)))
        } else {
            return CGFloat(sign) * CGFloat(0.5 * powf(Float(newT - 2), Float(kPTLabelCounterRate) + Float(sign * 2)))
        }
    }
}

// MARK: - 弱引用代理 (解决 CADisplayLink 内存泄漏)
/// 专门用于打破 CADisplayLink 循环引用的代理类
private class WeakDisplayLinkProxy {
    weak var target: AnyObject?
    let selector: Selector
    
    init(target: AnyObject, selector: Selector) {
        self.target = target
        self.selector = selector
    }
    
    @objc func step(displaylink: CADisplayLink) {
        _ = target?.perform(selector, with: displaylink)
    }
}

@objcMembers
public class PTCountingLabel: UILabel {

    open var countingType: PTCountingLabelType = .Linear
    open var attributedFormatBlock: PTCountingLabelAttributedFormatBlock?
    open var formatBlock: PTCountingLabelFormatBlock?
    open var showCompletionBlock: PTActionTask?
    
    open var format: String = "%f" {
        didSet {
            textValue(value: currentValue())
        }
    }
    
    /// 如果浮点数需要千分位分隔符,须使用@"###,##0.00"进行控制样式
    open var positiveFormat: String = "" {
        didSet {
            numberFormatter.positiveFormat = positiveFormat
        }
    }
    
    // MARK: - 懒加载复用 NumberFormatter 提升性能
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    private var progress: TimeInterval = 0
    private var totalTime: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var animationDuration: TimeInterval = 2
    private var destinationValue: CGFloat = 0
    private var startingValue: CGFloat = 0
    private var timer: CADisplayLink?
    private var easingRate: CGFloat = 3

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - 获取当前进度值
    public func currentValue() -> CGFloat {
        if progress >= totalTime {
            return destinationValue
        }
        
        let percent = progress / totalTime
        var updateVal: CGFloat = 0
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
    
    // MARK: - 触发动画方法
    public func countFrom(value: CGFloat, toValue: CGFloat) {
        self.countFrom(starValue: value, toValue: toValue, duration: animationDuration)
    }
    
    public func countFromCurrentValue(toValue: CGFloat) {
        self.countFrom(value: currentValue(), toValue: toValue)
    }
    
    public func countFormCurrentValue(toValue: CGFloat, duration: TimeInterval) {
        self.countFrom(starValue: currentValue(), toValue: toValue, duration: duration)
    }
    
    public func countFromZero(toValue: CGFloat) {
        self.countFrom(value: 0, toValue: toValue)
    }
    
    public func countFromZero(toValue: CGFloat, duration: TimeInterval) {
        self.countFrom(starValue: 0, toValue: toValue, duration: duration)
    }
    
    public func countFrom(starValue: CGFloat, toValue: CGFloat, duration: TimeInterval) {
        startingValue = starValue
        destinationValue = toValue
        
        timer?.invalidate()
        timer = nil
        
        if duration == 0 {
            textValue(value: toValue)
            runCompletionBlock()
            return // 注意：如果时间为0，直接返回，不再开启定时器
        }
        
        easingRate = 3
        progress = 0
        totalTime = duration
        lastUpdate = Date.timeIntervalSinceReferenceDate
        
        // 使用 WeakProxy 打破循环引用
        let proxy = WeakDisplayLinkProxy(target: self, selector: #selector(updateValue(timer:)))
        timer = CADisplayLink(target: proxy, selector: #selector(WeakDisplayLinkProxy.step(displaylink:)))
        
        if #available(iOS 10.0, *) {
            timer?.preferredFramesPerSecond = 60
        }
        timer?.add(to: RunLoop.main, forMode: .common) // 推荐使用 common 模式，避免滑动时动画停止
    }
    
    // MARK: - 定时器回调
    // 修复了参数类型错误，现为 CADisplayLink
    @objc private func updateValue(timer: CADisplayLink) {
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
    
    private func runCompletionBlock() {
        showCompletionBlock?()
    }
    
    // MARK: - 文本渲染 (性能优化核心)
    private func textValue(value: CGFloat) {
        if let attributedFormatBlock = attributedFormatBlock {
            attributedText = attributedFormatBlock(value)
        } else if let formatBlock = formatBlock {
            text = formatBlock(value)
        } else {
            // 优化：不再使用正则判断，简化逻辑；直接利用 NumberFormatter
            if !positiveFormat.isEmpty {
                // 直接转换，省去了转成String再转Double的损耗
                text = numberFormatter.string(from: NSNumber(value: Float(value)))
            } else {
                // 判断是否是需要转为整型显示
                if format.contains("%d") || format.contains("%i") {
                    text = String(format: format, Int(value))
                } else {
                    text = String(format: format, value)
                }
            }
        }
    }
    
    // MARK: - 清理资源
    deinit {
        timer?.invalidate()
        timer = nil
    }
}
