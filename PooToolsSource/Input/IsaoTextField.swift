//
//  IsaoTextField.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 29/01/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit

/// 一个继承自 TextFieldEffects 的自定义输入框 (Isao 风格)。
/// 特效表现：底部边框在激活时变粗并改变颜色；占位符文字在状态切换时会有一个“向下隐藏再向上浮现”的动感切换动画。
@IBDesignable open class IsaoTextField: TextFieldEffects {
    
    // MARK: - 可视化属性 (IBInspectable)
    
    /// 输入框未激活（无内容且未获焦点）时的底部边框颜色。
    /// 此颜色也会被默认应用到未激活状态下的占位符文字上。
    @IBInspectable dynamic open var inactiveColor: UIColor? {
        didSet {
            updateBorder()
        }
    }
    
    /// 输入框激活（有内容或正在输入）时的底部边框颜色。
    @IBInspectable dynamic open var activeColor: UIColor? {
        didSet {
            updateBorder()
        }
    }
    
    /// 占位符字体的缩放比例。
    /// 决定了占位符标签相对于输入框文本字体大小的比例。默认为 0.7。
    @IBInspectable dynamic open var placeholderFontScale: CGFloat = 0.7 {
        didSet {
            updatePlaceholder()
        }
    }
    
    // MARK: - 属性重写
    
    override open var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override open var bounds: CGRect {
        didSet {
            updateBorder()
            updatePlaceholder()
        }
    }
    
    // MARK: - 私有配置参数
    
    /// 底部边框的厚度配置 (active: 激活状态厚度, inactive: 未激活状态厚度)
    private let borderThickness: (active: CGFloat, inactive: CGFloat) = (4, 2)
    private let placeholderInsets = CGPoint(x: 6, y: 6)
    private let textFieldInsets = CGPoint(x: 6, y: 6)
    
    /// 负责绘制底部边框的图层
    private let borderLayer = CALayer()
    
    // MARK: - TextFieldEffects 生命周期实现
    
    override open func drawViewsForRect(_ rect: CGRect) {
        let frame = CGRect(origin: .zero, size: CGSize(width: rect.size.width, height: rect.size.height))
        
        // 设置占位符的基础 frame 和字体
        placeholderLabel.frame = frame.insetBy(dx: placeholderInsets.x, dy: placeholderInsets.y)
        placeholderLabel.font = placeholderFontFromFont(currentFont)
        
        updateBorder()
        updatePlaceholder()
        
        // 安全检查：防止重复添加图层和视图导致内存泄漏和渲染异常
        if borderLayer.superlayer == nil {
            layer.addSublayer(borderLayer)
        }
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
        }
    }
    
    override open func animateViewsForTextEntry() {
        updateBorder()
        if let activeColor = activeColor {
            // 输入时，占位符执行动画并变为激活颜色
            performPlaceholderAnimationWithColor(activeColor)
        }
    }
    
    override open func animateViewsForTextDisplay() {
        updateBorder()
        if let inactiveColor = inactiveColor {
            // 结束输入时，占位符执行动画并恢复为未激活颜色
            performPlaceholderAnimationWithColor(inactiveColor)
        }
    }
    
    // MARK: - 私有方法 (Private)
    
    /// 安全获取当前字体，防止原生 font 属性为 nil 时引发崩溃
    private var currentFont: UIFont {
        return font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    /// 更新边框的位置、粗细和颜色
    private func updateBorder() {
        borderLayer.frame = rectForBorder(frame)
        borderLayer.backgroundColor = isFirstResponder ? activeColor?.cgColor : inactiveColor?.cgColor
    }
    
    /// 更新占位符的内容和布局
    private func updatePlaceholder() {
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = inactiveColor
        placeholderLabel.sizeToFit()
        layoutPlaceholderInTextRect()
        
        // 如果当前处于输入状态，立即触发激活特效
        if isFirstResponder {
            animateViewsForTextEntry()
        }
    }
    
    /// 根据设定的缩放比例计算占位符的字体大小
    private func placeholderFontFromFont(_ font: UIFont) -> UIFont {
        return UIFont(descriptor: font.fontDescriptor, size: font.pointSize * placeholderFontScale)
    }
    
    /// 计算底部边框所在的区域
    private func rectForBorder(_ bounds: CGRect) -> CGRect {
        var newRect: CGRect
        // 根据是否为第一响应者，动态调整边框所在的 Y 轴位置和高度
        if isFirstResponder {
            newRect = CGRect(x: 0, y: bounds.size.height - currentFont.lineHeight + textFieldInsets.y - borderThickness.active, width: bounds.size.width, height: borderThickness.active)
        } else {
            newRect = CGRect(x: 0, y: bounds.size.height - currentFont.lineHeight + textFieldInsets.y - borderThickness.inactive, width: bounds.size.width, height: borderThickness.inactive)
        }
        return newRect
    }
    
    /// 重新计算占位符在输入框内的坐标位置
    private func layoutPlaceholderInTextRect() {
        let textRect = self.textRect(forBounds: bounds)
        var originX = textRect.origin.x
        
        // 适配不同的文本对齐方式
        switch textAlignment {
        case .center:
            originX += textRect.size.width / 2 - placeholderLabel.bounds.width / 2
        case .right:
            originX += textRect.size.width - placeholderLabel.bounds.width
        default:
            break
        }
        
        placeholderLabel.frame = CGRect(x: originX, y: bounds.height - placeholderLabel.frame.height,
                                        width: placeholderLabel.frame.size.width, height: placeholderLabel.frame.size.height)
    }
    
    /// 占位符专属的核心动画逻辑：向下移动渐隐，再从上方弹回显示新颜色
    /// - Parameter color: 动画结束后占位符需要变成的目标颜色
    private func performPlaceholderAnimationWithColor(_ color: UIColor) {
        let yOffset: CGFloat = 4
        
        // 第一阶段动画：文字向下偏移并变得透明
        UIView.animate(withDuration: 0.15, animations: {
            self.placeholderLabel.transform = CGAffineTransform(translationX: 0, y: -yOffset)
            self.placeholderLabel.alpha = 0
        }) { _ in
            // 重置位置到正常的偏下方，准备执行第二阶段的弹回
            self.placeholderLabel.transform = .identity
            self.placeholderLabel.transform = CGAffineTransform(translationX: 0, y: yOffset)
            
            // 第二阶段动画：文字恢复原位，透明度变回 1，颜色切换
            UIView.animate(withDuration: 0.15, animations: {
                self.placeholderLabel.textColor = color
                self.placeholderLabel.transform = .identity
                self.placeholderLabel.alpha = 1
            }) { _ in
                // 通知基类动画完成
                self.animationCompletionHandler?(self.isFirstResponder ? .textEntry : .textDisplay)
            }
        }
    }
    
    // MARK: - UITextField 边界区域重写 (Overrides)
    
    /// 返回处于编辑状态时的文本绘制区域
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        let newBounds = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height - currentFont.lineHeight + textFieldInsets.y)
        return newBounds.insetBy(dx: textFieldInsets.x, dy: 0)
    }
    
    /// 返回正常的文本绘制区域
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let newBounds = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height - currentFont.lineHeight + textFieldInsets.y)
        return newBounds.insetBy(dx: textFieldInsets.x, dy: 0)
    }
}
