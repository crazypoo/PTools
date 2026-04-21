//
//  AkiraTextField.swift
//  TextFieldEffects
//
//  Created by Mihaela Miches on 5/31/15.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit

/**
 一个继承自 TextFieldEffects 的自定义输入框 (Akira 风格)。
 特效表现：当输入框获得焦点或有文字时，底部边框变粗，占位符向上悬浮并缩小。
 */
@IBDesignable open class AkiraTextField: TextFieldEffects {
    
    /// 定义边框的粗细状态 (激活时变粗，未激活时较细)
    private let borderSize: (active: CGFloat, inactive: CGFloat) = (2, 1)
    
    /// 负责绘制边框的图层
    private let borderLayer = CALayer()
    
    /// 输入文字的内边距偏移量
    private let textFieldInsets = CGPoint(x: 6, y: 0)
    
    /// 占位符文字的内边距偏移量
    private let placeholderInsets = CGPoint(x: 6, y: 0)
    
    // MARK: - IBInspectable 属性 (可在 Storyboard/XIB 中可视化修改)
    
    /**
     边框的颜色。
     默认值为 clear (透明)，请在属性检查器或代码中为其赋值。
     */
    @IBInspectable dynamic open var borderColor: UIColor? {
        didSet {
            updateBorder()
        }
    }
    
    /**
     占位符的文字颜色。
     默认值为黑色。
     */
    @IBInspectable dynamic open var placeholderColor: UIColor = .black {
        didSet {
            updatePlaceholder()
        }
    }
    
    /**
     占位符上浮后的缩放比例。
     相对于输入框原本字体大小的比例，默认值为 0.7 (即缩小到 70%)。
     */
    @IBInspectable dynamic open var placeholderFontScale: CGFloat = 0.7 {
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
    
    // MARK: - TextFieldEffects 基类方法实现
    
    override open func drawViewsForRect(_ rect: CGRect) {
        // 修复 Bug：防止在 draw 方法被多次调用时，重复添加子视图和子图层
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
        }
        if borderLayer.superlayer == nil {
            layer.addSublayer(borderLayer)
        }
        
        updateBorder()
        updatePlaceholder()
    }
    
    override open func animateViewsForTextEntry() {
        UIView.animate(withDuration: 0.3, animations: {
            self.updateBorder()
            self.updatePlaceholder()
            // 强制视图立即更新布局，以便在动画闭包中平滑过渡
            self.layoutIfNeeded()
        }, completion: { _ in
            self.animationCompletionHandler?(.textEntry)
        })
    }
    
    override open func animateViewsForTextDisplay() {
        UIView.animate(withDuration: 0.3, animations: {
            self.updateBorder()
            self.updatePlaceholder()
            self.layoutIfNeeded()
        }, completion: { _ in
            self.animationCompletionHandler?(.textDisplay)
        })
    }
    
    // MARK: - 私有更新逻辑 (Private)
    
    private func updatePlaceholder() {
        placeholderLabel.frame = placeholderRect(forBounds: bounds)
        placeholderLabel.text = placeholder
        placeholderLabel.font = placeholderFontFromFont(currentFont)
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.textAlignment = textAlignment
    }
    
    private func updateBorder() {
        borderLayer.frame = rectForBounds(bounds)
        // 修复 Bug：安全解包 text，防止崩溃
        let isTextNotEmpty = text?.isNotEmpty ?? false
        borderLayer.borderWidth = (isFirstResponder || isTextNotEmpty) ? borderSize.active : borderSize.inactive
        borderLayer.borderColor = borderColor?.cgColor
    }
    
    // MARK: - 辅助计算方法 (Helpers)
    
    /// 获取当前输入框的字体（安全解包，防止 font 为 nil 导致崩溃）
    private var currentFont: UIFont {
        return font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    /// 根据当前字体和缩放比例，计算上浮后占位符的字体
    private func placeholderFontFromFont(_ font: UIFont) -> UIFont {
        return UIFont(descriptor: font.fontDescriptor, size: font.pointSize * placeholderFontScale)
    }
    
    /// 计算占位符区域的高度
    private var placeholderHeight: CGFloat {
        return placeholderInsets.y + placeholderFontFromFont(currentFont).lineHeight
    }
    
    /// 计算边框图层应该所在的区域 (给顶部占位符腾出空间)
    private func rectForBounds(_ bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.origin.x,
            y: bounds.origin.y + placeholderHeight,
            width: bounds.size.width,
            height: bounds.size.height - placeholderHeight
        )
    }
    
    // MARK: - UITextField 边界区域重写 (Overrides)
    
    /// 返回占位符的绘制区域
    open override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let isTextNotEmpty = text?.isNotEmpty ?? false
        if isFirstResponder || isTextNotEmpty {
            // 输入中或有文字时，占位符上浮到顶部
            return CGRect(x: placeholderInsets.x, y: placeholderInsets.y, width: bounds.width, height: placeholderHeight)
        } else {
            // 默认状态下，占位符占据输入区域
            return textRect(forBounds: bounds)
        }
    }
    
    /// 返回处于编辑状态时的文本绘制区域
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
    
    /// 返回正常的文本绘制区域
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        // 将输入文本向下偏移，避免与上浮的占位符重叠
        return bounds.offsetBy(dx: textFieldInsets.x, dy: textFieldInsets.y + placeholderHeight / 2)
    }
}
