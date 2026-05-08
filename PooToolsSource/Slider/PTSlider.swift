//
//  PTSlider.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/2.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

public enum PTSliderTitlePosition: Int {
    case top
    case bottom
}

@objcMembers
public class PTSlider: UISlider {
    
    // MARK: - Configurable Properties
    
    /// 标题显示位置
    public var titleStyle: PTSliderTitlePosition = .top {
        didSet { updateLabelConstraints() }
    }
    
    /// 是否让标题跟随滑块 (Thumb) 移动
    public var isLabelFloatingWithThumb: Bool = true {
        didSet { setNeedsLayout() }
    }
    
    /// 步进值，如果大于 0，滑块会按此值吸附 (例如：5)
    public var step: Float = 0
    
    /// 是否开启触觉震动反馈
    public var enableHapticFeedback: Bool = true
    
    public var titleColor: UIColor = .systemBlue {
        didSet { sliderValueLabel.textColor = titleColor }
    }
    
    public var titleFont: UIFont = .systemFont(ofSize: 14) {
        didSet { sliderValueLabel.font = titleFont }
    }
    
    /// 高级自定义：完全控制文本的显示格式
    public var valueFormatter: ((Float) -> String)? {
        didSet { updateSliderValueLabel() }
    }
    
    // 旧有属性，保留以兼容你之前的逻辑，但在内部交由 formatter 处理更好
    public var showTitle: Bool = false {
        didSet { sliderValueLabel.isHidden = !showTitle }
    }
    public var showRawValue: Bool = false {
        didSet { updateSliderValueLabel() }
    }
    public var titleValueUnit: String = "" {
        didSet { updateSliderValueLabel() }
    }
    
    // MARK: - Private
    
    private let thumbBoundY: CGFloat = 20
    private let thumbBoundX: CGFloat = 10
    private var lastThumbBounds: CGRect = .zero
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    private var lastSteppedValue: Float?
    
    private lazy var sliderValueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = self.titleFont
        label.textColor = self.titleColor
        label.isHidden = !self.showTitle
        return label
    }()
    
    // MARK: - Initializers
    
    public init(showTitle: Bool = false, showRawValue: Bool = false) {
        self.showTitle = showTitle
        self.showRawValue = showRawValue
        super.init(frame: .zero)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        isContinuous = true
        
        addSubview(sliderValueLabel)
        updateLabelConstraints()
        feedbackGenerator.prepare()
    }
    
    // MARK: - Layout & Thumb
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateSliderValueLabel()
        
        // 动态更新 Floating Label 的 X 坐标
        if isLabelFloatingWithThumb, !lastThumbBounds.isEmpty {
            sliderValueLabel.snp.updateConstraints { make in
                // lastThumbBounds.midX 是相对于整个 slider width 的中心偏移
                make.centerX.equalTo(self.snp.leading).offset(lastThumbBounds.midX)
            }
        }
    }
    
    public override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        // 扩展物理轨道的范围，让两端可以完全滑到底
        var extendedRect = rect
        extendedRect.origin.x -= 10
        extendedRect.size.width += 20
        let result = super.thumbRect(forBounds: bounds, trackRect: extendedRect, value: value)
        lastThumbBounds = result
        return result
    }
    
    // MARK: - Hit Test (扩大点击热区)
    
    // 删除了你原来的 hitTest 覆写，因为这是不良实践。
    // 只保留 point(inside:) 就可以完美实现热区放大，且不破坏系统的 Tracking 事件传递
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let defaultResult = super.point(inside: point, with: event)
        if defaultResult { return true }
        
        // 只有滑块周围的区域扩大了热区，避免污染其他 UI 的点击
        let thumbFrame = lastThumbBounds.insetBy(dx: -thumbBoundX, dy: -thumbBoundY)
        return thumbFrame.contains(point)
    }
    
    // MARK: - Label Handling
    
    private func updateLabelConstraints() {
        sliderValueLabel.snp.remakeConstraints { make in
            // 如果不悬浮跟随，默认居中
            if !isLabelFloatingWithThumb {
                make.centerX.equalToSuperview()
            } else {
                make.centerX.equalTo(self.snp.leading).offset(bounds.midX) // 临时占位，layoutSubviews 中会修正
            }
            
            // 使用 remakeConstraints 安全切换上下方
            switch titleStyle {
            case .top:
                make.bottom.equalTo(self.snp.centerY).offset(-15)
            case .bottom:
                make.top.equalTo(self.snp.centerY).offset(15)
            }
        }
    }
    
    private func updateSliderValueLabel() {
        guard showTitle else { return }
        
        if let formatter = valueFormatter {
            sliderValueLabel.text = formatter(value)
        } else {
            // 兼容原来的逻辑
            if showRawValue {
                sliderValueLabel.text = String(format: "%.0f%@", value, titleValueUnit)
            } else {
                sliderValueLabel.text = String(format: "%.0f%%", value / maximumValue * 100)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func sliderValueChanged() {
        // 1. 处理 Step (步进)
        if step > 0 {
            let roundedValue = round(value / step) * step
            setValue(roundedValue, animated: false)
        }
        
        // 2. 触发震动反馈
        if enableHapticFeedback {
            if value == minimumValue || value == maximumValue {
                feedbackGenerator.selectionChanged()
            } else if step > 0 && value != lastSteppedValue {
                feedbackGenerator.selectionChanged()
                lastSteppedValue = value
            }
        }
        
        // 3. 更新 UI
        updateSliderValueLabel()
        
        // 如果 Label 需要跟随 Thumb 悬浮，触发重绘以计算新的偏移量
        if isLabelFloatingWithThumb {
            setNeedsLayout()
        }
    }
}
