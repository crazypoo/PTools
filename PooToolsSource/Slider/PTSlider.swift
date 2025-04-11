//
//  PTSlider.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/2.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

let thumbBoundY: CGFloat = 20
let thumbBoundX: CGFloat = 10

public enum PTSliderTitleShowType: Int {
    case top
    case bottom
}

@objcMembers
public class PTSlider: UISlider {
    
    // MARK: - Configurable Properties
    
    public var showTitle: Bool = false {
        didSet { updateSliderValueLabelVisibility() }
    }
    
    public var showRawValue: Bool = false {
        didSet { updateSliderValueLabel() }
    }
    
    public var titleStyle: PTSliderTitleShowType = .top {
        didSet { updateSliderValueLabelPosition() }
    }
    
    public var titleColor: UIColor = .systemBlue {
        didSet { sliderValueLabel.textColor = titleColor }
    }
    
    public var titleFont: UIFont = .systemFont(ofSize: 14) {
        didSet { sliderValueLabel.font = titleFont }
    }
    
    public var titleValueUnit: String = "" {
        didSet { updateSliderValueLabel() }
    }
    
    // MARK: - Private
    
    private var lastThumbBounds: CGRect = .zero
    private var hasAddedLabel: Bool = false
    
    private lazy var sliderValueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = self.titleFont
        label.textColor = self.titleColor
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
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if showTitle && !hasAddedLabel {
            addSliderValueLabel()
        }
        updateSliderValueLabelPosition()
        updateSliderValueLabel()
    }
    
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }
    
    // MARK: - Thumb Rect Override
    
    public override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var extendedRect = rect
        extendedRect.origin.x -= 10
        extendedRect.size.width += 20
        let result = super.thumbRect(forBounds: bounds, trackRect: extendedRect, value: value)
        lastThumbBounds = result
        return result
    }
    
    // MARK: - Touch Handling
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        
        if bounds.contains(point) {
            return result
        }

        let thumbFrame = lastThumbBounds.insetBy(dx: -thumbBoundX, dy: -thumbBoundY)
        if thumbFrame.contains(point) {
            // 拖拽模擬
            let relativeValue = max(0, min(1, (point.x - bounds.origin.x) / bounds.width))
            setValue(Float(relativeValue) * (maximumValue - minimumValue) + minimumValue, animated: true)
            return result
        }

        return result
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let baseResult = super.point(inside: point, with: event)
        if baseResult { return true }
        
        let thumbFrame = lastThumbBounds.insetBy(dx: -thumbBoundX, dy: -thumbBoundY)
        return thumbFrame.contains(point)
    }
    
    // MARK: - Label Handling
    
    private func addSliderValueLabel() {
        guard frame.height >= 31 + titleFont.pointSize + 5 else {
            sliderValueLabel.removeFromSuperview()
            hasAddedLabel = false
            return
        }
        
        addSubview(sliderValueLabel)
        hasAddedLabel = true
        
        sliderValueLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            switch titleStyle {
            case .top:
                make.bottom.equalTo(self.snp.centerY).offset(-15.5)
            case .bottom:
                make.top.equalTo(self.snp.centerY).offset(15.5)
            }
        }
    }
    
    private func updateSliderValueLabel() {
        guard showTitle else { return }
        
        if showRawValue {
            sliderValueLabel.text = String(format: "%.0f%@", value, titleValueUnit)
        } else {
            sliderValueLabel.text = String(format: "%.0f%%", value / maximumValue * 100)
        }
    }
    
    private func updateSliderValueLabelPosition() {
        guard hasAddedLabel else { return }
        
        sliderValueLabel.snp.updateConstraints { make in
            switch titleStyle {
            case .top:
                make.bottom.equalTo(self.snp.centerY).offset(-15.5)
            case .bottom:
                make.top.equalTo(self.snp.centerY).offset(15.5)
            }
        }
    }
    
    private func updateSliderValueLabelVisibility() {
        if showTitle {
            if !hasAddedLabel {
                setNeedsLayout()
            }
        } else {
            sliderValueLabel.removeFromSuperview()
            hasAddedLabel = false
        }
    }
    
    // MARK: - Actions
    
    @objc private func sliderValueChanged() {
        updateSliderValueLabel()
    }
}
