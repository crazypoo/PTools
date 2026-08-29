//
//  PTSwitch.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/18.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

open class PTSwitch: UIControl {
    public var valueChangeCallBack:PTBoolTask?
    private var thumbColorStorage: Any?
    
    public var isOn = false {
        didSet {
            updateSwitchState(animated: animation)
        }
    }
    
    public var switchTintColor:UIColor = .systemGray4 {
        didSet {
            updateSwitchAppearance()
        }
    }

    public var onTintColor:UIColor = .systemGreen {
        didSet {
            updateSwitchAppearance()
        }
    }
    
    public var thumbColor:Any {
        get {
            return thumbColorStorage ?? UIColor.white
        }
        set {
            thumbColorStorage = newValue
            switchThumbView.loadImage(contentData: newValue)
        }
    }
    
    private let switchBackgroundView = UIView()
    private lazy var switchThumbView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    private var animation:Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // 设置背景视图
        switchBackgroundView.backgroundColor = switchTintColor
        addSubview(switchBackgroundView)

        // 设置滑块视图
        switchThumbView.backgroundColor = .white
        addSubview(switchThumbView)

        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSwitch))
        addGestureRecognizer(tapGesture)
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        updateAccessibilityValue()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        // 设置背景视图的布局
        switchBackgroundView.frame = bounds
        switchBackgroundView.layer.cornerRadius = max(0, bounds.height) / 2

        // 设置滑块视图的布局
        switchThumbView.frame = thumbFrame()
        switchThumbView.layer.cornerRadius = switchThumbView.bounds.height / 2
    }

    @objc private func toggleSwitch() {
        guard isEnabled else { return }
        animation = true
        isOn.toggle()
        sendActions(for: .valueChanged)
        valueChangeCallBack?(isOn)
    }

    private func updateSwitchState(animated: Bool) {
        let targetFrame = thumbFrame()
        let update = { [weak self] in
            guard let self else { return }
            self.updateSwitchAppearance()
            self.switchThumbView.frame = targetFrame
            self.switchThumbView.layer.cornerRadius = targetFrame.height / 2
        }
        switchThumbView.layer.removeAllAnimations()
        let shouldAnimate = animated && !UIAccessibility.isReduceMotionEnabled && window != nil
        if shouldAnimate {
            UIView.animate(withDuration: 0.3, animations: update)
        } else {
            UIView.performWithoutAnimation(update)
        }
        updateAccessibilityValue()
    }

    // English: Keep the thumb inside the control even when Auto Layout briefly reports a tiny or zero-sized bound.
    // Español: Mantén el pulgar dentro del control aunque Auto Layout informe temporalmente un tamaño mínimo o cero.
    // 中文：即使 Auto Layout 暂时产生极小或零尺寸，也要保证滑块不越出控件边界。
    private func thumbFrame() -> CGRect {
        let width = max(0, bounds.width)
        let height = max(0, bounds.height)
        let diameter = min(max(0, height - 4), max(0, width - 4))
        let inset = min(2, max(0, (width - diameter) / 2))
        let x = isOn ? width - inset - diameter : inset
        let y = max(0, (height - diameter) / 2)
        return CGRect(x: bounds.minX + x,
                      y: bounds.minY + y,
                      width: diameter,
                      height: diameter)
    }

    private func updateSwitchAppearance() {
        switchBackgroundView.backgroundColor = isOn ? onTintColor : switchTintColor
    }

    // English: Keep VoiceOver state synchronized with the visual switch state.
    // Español: Mantén el estado de VoiceOver sincronizado con el estado visual del interruptor.
    // 中文：让 VoiceOver 状态与开关的视觉状态保持同步。
    private func updateAccessibilityValue() {
        accessibilityTraits = isOn ? [.button, .selected] : [.button]
        accessibilityValue = isOn ? "On" : "Off"
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            switchThumbView.layer.removeAllAnimations()
        }
    }

    public func setOn(_ on: Bool, animated: Bool) {
        animation = animated
        isOn = on
    }
}
