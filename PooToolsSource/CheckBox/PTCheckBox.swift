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
    /// ■ (正方形)
    case Square
    /// ● (圆形)
    case Circle
    /// ╳ (叉号)
    case Cross
    /// ✓ (对号)
    case Tick
}

public enum PTCheckBoxBorderStyle: Int {
    /// ▢ (正方形边框)
    case Square
    /// ◯ (圆形边框)
    case Circle
}

@objcMembers
public class PTCheckBox: UIControl {
    /// 状态切换回调
    open var valueChanged: PTCheckboxValueChangedBlock?
    /// 内部选中标记风格
    open var checkmarkStyle: PTCheckBoxStyle = .Square
    /// 外部边框风格
    open var borderStyle: PTCheckBoxBorderStyle = .Square
    /// 外部边框线宽度
    open var boxBorderWidth: CGFloat = 2 { didSet { setNeedsDisplay() } }
    /// 内部标记尺寸占比 (0.0 ~ 1.0)
    open var checkmarkSize: CGFloat = 0.5 { didSet { setNeedsDisplay() } }
    /// 底部背景颜色
    open var checkboxBackgroundColor: UIColor = .clear { didSet { setNeedsDisplay() } }
    /// 触摸范围扩大值 (向外扩展)
    open var increasedTouchRadius: CGFloat = 5
    /// 是否开启缩放动画 (新功能)
    open var isAnimated: Bool = true
    
    /// 是否已经选中
    open var isChecked: Bool = true {
        didSet {
            updateUI(animated: isAnimated)
        }
    }
    
    /// 是否启用点击震动
    open var useHapticFeedback: Bool = true
    
    /// 边框未选中时的颜色
    open lazy var uncheckedBorderColor: UIColor = tintColor
    /// 边框选中时的颜色
    open lazy var checkedBorderColor: UIColor = tintColor
    /// 内部标记颜色
    open lazy var checkmarkColor: UIColor = tintColor
    
    /// 修复：使用 Selection 震动反馈更适合 Checkbox 切换
    fileprivate lazy var feedbackGenerator: UISelectionFeedbackGenerator = {
        let generator = UISelectionFeedbackGenerator()
        if self.useHapticFeedback {
            generator.prepare()
        }
        return generator
    }()

    // MARK: - 生命周期
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaults()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDefaults()
    }
    
    // 新功能：让 AutoLayout 知道控件的默认大小
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 30, height: 30)
    }
    
    // 新功能：处理禁用状态的视觉变化
    public override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.5
            isUserInteractionEnabled = isEnabled
        }
    }

    // MARK: - 初始化设置
    private func setupDefaults() {
        backgroundColor = .clear
        // 修复：添加 Accessibility trait，让旁白知道这是一个按钮
        accessibilityTraits = .button
        updateAccessibility()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        self.isChecked.toggle()
        self.valueChanged?(self.isChecked)
        self.sendActions(for: .valueChanged)
        
        if self.useHapticFeedback {
            self.feedbackGenerator.selectionChanged()
            self.feedbackGenerator.prepare()
        }
    }

    // MARK: - UI 更新与动画
    private func updateUI(animated: Bool) {
        updateAccessibility()
        
        if animated {
            // 新功能：添加点击时的弹簧动画效果
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            }) { _ in
                self.setNeedsDisplay() // 在缩小状态下重绘内容
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
                    self.transform = .identity
                }, completion: nil)
            }
        } else {
            setNeedsDisplay()
        }
    }
    
    private func updateAccessibility() {
        accessibilityValue = isChecked ? "已选中" : "未选中"
    }

    // MARK: - 绘制核心逻辑 (修复了边框裁剪 Bug)
    public override func draw(_ rect: CGRect) {
        drawBorder(shape: borderStyle, frame: rect)
        if isChecked {
            drawCheckmark(style: checkmarkStyle, frame: rect)
        }
    }
    
    private func drawBorder(shape: PTCheckBoxBorderStyle, frame: CGRect) {
        // 修复：必须减去线宽的一半，防止 Stroke 被 View 边界裁剪掉
        let adjustedRect = frame.insetBy(dx: boxBorderWidth / 2, dy: boxBorderWidth / 2)
        
        let path: UIBezierPath
        switch shape {
        case .Square:
            path = UIBezierPath(rect: adjustedRect)
        case .Circle:
            path = UIBezierPath(ovalIn: adjustedRect)
        }
        
        let borderColor = isChecked ? checkedBorderColor : uncheckedBorderColor
        borderColor.setStroke()
        path.lineWidth = boxBorderWidth
        path.stroke()
        
        checkboxBackgroundColor.setFill()
        path.fill()
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
        
        setupStrokeStyle(for: path)
    }

    private func tickCheckmark(rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + 0.2 * rect.size.width, y: rect.minY + 0.6 * rect.size.height))
        path.addLine(to: CGPoint(x: rect.minX + 0.45 * rect.size.width, y: rect.maxY - 0.1 * rect.size.height))
        path.addLine(to: CGPoint(x: rect.maxX - 0.1 * rect.size.width, y: rect.minY + 0.2 * rect.size.height))
        
        setupStrokeStyle(for: path)
    }
    
    // 提取公共的线条样式设置，增加圆润效果
    private func setupStrokeStyle(for path: UIBezierPath) {
        checkmarkColor.setStroke()
        path.lineWidth = boxBorderWidth * 1.5 // 线条略宽于边框看起来更协调
        path.lineCapStyle = .round // 让线段两端变成圆形，视觉更平滑
        path.lineJoinStyle = .round // 让转角处变成圆形
        path.stroke()
    }

    private func checkmarkRect(rect: CGRect) -> CGRect {
        let width = rect.width * checkmarkSize
        let height = rect.height * checkmarkSize
        return CGRect(x: (rect.width - width) / 2, y: (rect.height - height) / 2, width: width, height: height)
    }

    // MARK: - 触摸范围控制
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let hitTestInsets = UIEdgeInsets(top: -increasedTouchRadius, left: -increasedTouchRadius, bottom: -increasedTouchRadius, right: -increasedTouchRadius)
        let hitFrame = bounds.inset(by: hitTestInsets)
        return hitFrame.contains(point)
    }
}
