//
//  MinoruTextField.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 27/01/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit

/// 一个继承自 TextFieldEffects 的自定义输入框 (Minoru 风格)。
/// 特效表现：当输入框处于激活状态时，边框会出现伴随阴影的发光效果（颜色与输入文字颜色一致）。
@IBDesignable open class MinoruTextField: TextFieldEffects {
    
    // MARK: - 可视化属性 (IBInspectable)
    
    /// 占位符文字的颜色。
    /// 默认值为黑色。
    @IBInspectable dynamic open var placeholderColor: UIColor = .black {
        didSet {
            updatePlaceholder()
        }
    }
    
    /// 占位符上浮后的字体缩放比例。
    /// 相对于输入框原本字体大小的比例，默认为 0.65。
    @IBInspectable dynamic open var placeholderFontScale: CGFloat = 0.65 {
        didSet {
            updatePlaceholder()
        }
    }
    
    // MARK: - 原生属性重写
    
    /// 重写背景色，使其应用于我们自定义的 borderLayer 上，而不是原生的 UIView 背景
    override open var backgroundColor: UIColor? {
        set {
            backgroundLayerColor = newValue
            updateBorder() // 确保背景色改变时立即重绘更新
        }
        get {
            return backgroundLayerColor
        }
    }
    
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
    
    /// 激活时边框的粗细
    private let borderThickness: CGFloat = 1
    /// 占位符文字的内边距偏移量
    private let placeholderInsets = CGPoint(x: 6, y: 6)
    /// 实际输入文本的内边距偏移量
    private let textFieldInsets = CGPoint(x: 6, y: 6)
    
    /// 负责绘制带有阴影发光效果背景和边框的图层
    private let borderLayer = CALayer()
    /// 用于存储自定义背景色的私有变量
    private var backgroundLayerColor: UIColor?
    
    // MARK: - TextFieldEffects 生命周期实现
    
    override open func drawViewsForRect(_ rect: CGRect) {
        let frame = CGRect(origin: CGPoint.zero, size: rect.size)
        
        placeholderLabel.frame = frame.insetBy(dx: placeholderInsets.x, dy: placeholderInsets.y)
        placeholderLabel.font = placeholderFontFromFont(currentFont)
        
        updateBorder()
        updatePlaceholder()
        
        // 安全检查：防止在界面的生命周期内多次调用导致视图/图层重复叠加
        if borderLayer.superlayer == nil {
            layer.insertSublayer(borderLayer, at: 0) // 放在最底层作为背景
        }
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
        }
    }
    
    override open func animateViewsForTextEntry() {
        // 使用弹簧动画增加视觉的连贯性
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.6, options: .beginFromCurrentState, animations: {
            
            // 激活时，边框颜色和阴影颜色与当前的文字颜色（textColor）保持一致，产生发光效果
            self.borderLayer.borderColor = self.textColor?.cgColor
            self.borderLayer.shadowOffset = CGSize.zero
            self.borderLayer.borderWidth = self.borderThickness
            self.borderLayer.shadowColor = self.textColor?.cgColor
            self.borderLayer.shadowOpacity = 0.5
            self.borderLayer.shadowRadius = 1
            
        }, completion: { _ in
            self.animationCompletionHandler?(.textEntry)
        })
    }
    
    override open func animateViewsForTextDisplay() {
        // 安全判断：只有当文本确实为空时，才执行失去焦点的隐藏动画
        let isTextEmpty = text?.isEmpty ?? true
        
        if isTextEmpty {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.6, options: .beginFromCurrentState, animations: {

                // 失去焦点且无文字时，清除边框和阴影
                self.borderLayer.borderColor = nil
                self.borderLayer.shadowOffset = CGSize.zero
                self.borderLayer.borderWidth = 0
                self.borderLayer.shadowColor = nil
                self.borderLayer.shadowOpacity = 0
                self.borderLayer.shadowRadius = 0
                
            }, completion: { _ in
                self.animationCompletionHandler?(.textDisplay)
            })
        }
    }
    
    // MARK: - 内部私有方法 (Private)
    
    /// 安全获取当前字体，防止崩溃
    private var currentFont: UIFont {
        return font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    /// 更新边框的位置和背景色
    private func updateBorder() {
        borderLayer.frame = rectForBorder(frame)
        borderLayer.backgroundColor = backgroundLayerColor?.cgColor
    }
    
    /// 更新占位符状态
    private func updatePlaceholder() {
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.sizeToFit()
        layoutPlaceholderInTextRect()
        
        if isFirstResponder {
            animateViewsForTextEntry()
        }
    }
    
    /// 根据设定的缩放比例计算占位符字体大小
    private func placeholderFontFromFont(_ font: UIFont) -> UIFont {
        return UIFont(descriptor: font.fontDescriptor, size: font.pointSize * placeholderFontScale)
    }
    
    /// 计算边框图层所在的区域坐标
    private func rectForBorder(_ bounds: CGRect) -> CGRect {
        // 使用安全解包的 currentFont
        return CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height - currentFont.lineHeight + textFieldInsets.y)
    }
    
    /// 计算占位符的位置
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
        
        // Minoru 的占位符固定在下方
        placeholderLabel.frame = CGRect(x: originX, y: bounds.height - placeholderLabel.frame.height,
                                        width: placeholderLabel.frame.size.width, height: placeholderLabel.frame.size.height)
    }
    
    // MARK: - UITextField 边界区域重写 (Overrides)
        
    /// 返回处于编辑状态时的文本绘制区域
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        let newBounds = rectForBorder(bounds)
        return newBounds.insetBy(dx: textFieldInsets.x, dy: 0)
    }
    
    /// 返回正常的文本绘制区域
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let newBounds = rectForBorder(bounds)
        return newBounds.insetBy(dx: textFieldInsets.x, dy: 0)
    }
}
