//
//  JiroTextField.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 24/01/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit

/// 一个继承自 TextFieldEffects 的自定义输入框 (Jiro 风格)。
/// 特效表现：当输入框激活时，底部边框会像背景一样向上展开填充，同时占位符文字向上悬浮。
@IBDesignable open class JiroTextField: TextFieldEffects {
    
    // MARK: - 可视化属性 (IBInspectable)
    
    /// 边框（及展开后的背景）颜色。
    /// 默认值为透明 (clear color)，请在代码或 Storyboard 中设置具体颜色。
    @IBInspectable dynamic open var borderColor: UIColor? {
        didSet {
            updateBorder()
        }
    }
    
    /// 占位符的文字颜色。
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
    
    /// 未激活状态下，底部边框的厚度
    private let borderThickness: CGFloat = 2
    /// 占位符文字的内边距
    private let placeholderInsets = CGPoint(x: 8, y: 8)
    /// 实际输入文本的内边距
    private let textFieldInsets = CGPoint(x: 8, y: 12)
    
    /// 负责绘制底部边框和向上展开背景的图层
    private let borderLayer = CALayer()
    
    // MARK: - TextFieldEffects 生命周期实现
    
    override open func drawViewsForRect(_ rect: CGRect) {
        let frame = CGRect(origin: CGPoint.zero, size: rect.size)
        
        placeholderLabel.frame = frame.insetBy(dx: placeholderInsets.x, dy: placeholderInsets.y)
        placeholderLabel.font = placeholderFontFromFont(currentFont)
        
        updateBorder()
        updatePlaceholder()
        
        // 安全检查：防止在多次触发 draw 时重复添加图层和视图
        if borderLayer.superlayer == nil {
            layer.insertSublayer(borderLayer, at: 0)
        }
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
        }
    }
    
    override open func animateViewsForTextEntry() {
        // 重置边框图层的起始 Y 坐标，准备展开
        borderLayer.frame.origin = CGPoint(x: 0, y: currentFont.lineHeight)
        
        // 弹簧动画效果：边框向上拉伸填充，占位符上移
        UIView.animate(withDuration: 0.2, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: {
            
            self.placeholderLabel.frame.origin = CGPoint(x: self.placeholderInsets.x, y: self.borderLayer.frame.origin.y - self.placeholderLabel.bounds.height)
            self.borderLayer.frame = self.rectForBorder(self.borderThickness, isFilled: true)
            
        }, completion: { _ in
            self.animationCompletionHandler?(.textEntry)
        })
    }
    
    override open func animateViewsForTextDisplay() {
        // 安全解包 text，只有当文本真正为空时，才执行恢复初始状态的动画
        let isTextEmpty = text?.isEmpty ?? true
        
        if isTextEmpty {
            UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: .beginFromCurrentState, animations: {
                
                self.layoutPlaceholderInTextRect()
                self.placeholderLabel.alpha = 1
                
            }, completion: { _ in
                self.animationCompletionHandler?(.textDisplay)
            })
            
            // 边框恢复为底部的一条线
            borderLayer.frame = rectForBorder(borderThickness, isFilled: false)
        }
    }
    
    // MARK: - 内部私有方法 (Private)
    
    /// 安全获取当前字体，防止因 font 为 nil 导致崩溃
    private var currentFont: UIFont {
        return font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    /// 更新边框的外观
    private func updateBorder() {
        borderLayer.frame = rectForBorder(borderThickness, isFilled: false)
        borderLayer.backgroundColor = borderColor?.cgColor
    }
    
    /// 更新占位符的内容和状态
    private func updatePlaceholder() {
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.sizeToFit()
        layoutPlaceholderInTextRect()
        
        // 如果输入框有焦点或已经有文字，则直接展示输入状态的视图（展开边框）
        let isTextNotEmpty = text?.isNotEmpty ?? false
        if isFirstResponder || isTextNotEmpty {
            animateViewsForTextEntry()
        }
    }
    
    /// 计算缩放后的占位符字体
    private func placeholderFontFromFont(_ font: UIFont) -> UIFont {
        return UIFont(descriptor: font.fontDescriptor, size: font.pointSize * placeholderFontScale)
    }
    
    /// 计算边框或背景的坐标和大小
    /// - Parameters:
    ///   - thickness: 边框的厚度
    ///   - isFilled: 是否为填充状态 (展开状态)
    private func rectForBorder(_ thickness: CGFloat, isFilled: Bool) -> CGRect {
        if isFilled {
            // 展开时，图层占据大部分输入框的背景区域
            let safeLineHeight = placeholderLabel.font?.lineHeight ?? currentFont.lineHeight
            return CGRect(origin: CGPoint(x: 0, y: placeholderLabel.frame.origin.y + safeLineHeight),
                          size: CGSize(width: frame.width, height: frame.height))
        } else {
            // 默认时，图层只是底部的一条线
            return CGRect(origin: CGPoint(x: 0, y: frame.height - thickness),
                          size: CGSize(width: frame.width, height: thickness))
        }
    }
    
    /// 布局占位符，使其正确显示在文本区域内
    private func layoutPlaceholderInTextRect() {
        let isTextNotEmpty = text?.isNotEmpty ?? false
        if isTextNotEmpty {
            return
        }
        
        let textRect = self.textRect(forBounds: bounds)
        var originX = textRect.origin.x
        
        // 适配不同的文本对齐方式
        switch self.textAlignment {
        case .center:
            originX += textRect.size.width / 2 - placeholderLabel.bounds.width / 2
        case .right:
            originX += textRect.size.width - placeholderLabel.bounds.width
        default:
            break
        }
        
        placeholderLabel.frame = CGRect(x: originX, y: textRect.size.height / 2,
                                        width: placeholderLabel.frame.size.width, height: placeholderLabel.frame.size.height)
    }
    
    // MARK: - UITextField 边界区域重写 (Overrides)
    
    /// 返回处于编辑状态时的文本绘制区域，加入设定的偏移量
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.offsetBy(dx: textFieldInsets.x, dy: textFieldInsets.y)
    }
    
    /// 返回正常的文本绘制区域，加入设定的偏移量
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.offsetBy(dx: textFieldInsets.x, dy: textFieldInsets.y)
    }
}
