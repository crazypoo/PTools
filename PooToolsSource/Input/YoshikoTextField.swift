//
//  YoshikoTextField.swift
//  TextFieldEffects
//
//  Created by Keenan Cassidy on 01/10/2015.
//  Copyright © 2015 Raul Riera. All rights reserved.
//

import UIKit

/// 一个继承自 TextFieldEffects 的自定义输入框 (Yoshiko 风格)。
/// 特效表现：拥有可自定义的粗边框和背景色。激活时，占位符文字会上浮、进一步缩小并自动转换为大写。
@IBDesignable open class YoshikoTextField: TextFieldEffects {
    
    // MARK: - 私有配置参数
    
    /// 负责绘制带有背景色和边框的底层图层
    private let borderLayer = CALayer()
    /// 实际输入文本的内边距偏移量
    private let textFieldInsets = CGPoint(x: 6, y: 0)
    /// 占位符文字的内边距偏移量
    private let placeHolderInsets = CGPoint(x: 6, y: 0)
    
    // MARK: - 可视化属性 (IBInspectable)
    
    /// 边框的粗细大小。
    /// 默认值为 2.0 point。
    @IBInspectable open var borderSize: CGFloat = 2.0 {
        didSet {
            updateBorder()
        }
    }
    
    /// 激活状态（有焦点或有内容）时的边框颜色。
    /// 默认值为透明 (clear color)。
    @IBInspectable dynamic open var activeBorderColor: UIColor = .clear {
        didSet {
            updateBorder()
            updateBackground()
            updatePlaceholder()
        }
    }
    
    /// 未激活状态（无焦点且无内容）时的边框颜色。
    /// 默认值为透明 (clear color)。
    @IBInspectable dynamic open var inactiveBorderColor: UIColor = .clear {
        didSet {
            updateBorder()
            updateBackground()
            updatePlaceholder()
        }
    }

    /// 激活状态（有焦点或有内容）时的背景颜色。
    /// 注意：当未激活时，背景颜色会回退到 `inactiveBorderColor` 的颜色。
    @IBInspectable dynamic open var activeBackgroundColor: UIColor = .clear {
        didSet {
            updateBackground()
        }
    }
    
    /// 占位符文字的初始颜色。
    /// 默认值为深灰色 (dark gray)。
    @IBInspectable dynamic open var placeholderColor: UIColor = .darkGray {
        didSet {
            updatePlaceholder()
        }
    }
    
    /// 占位符的字体缩放比例基准值。
    /// 决定了占位符相对于输入框原生字体大小的比例。默认为 0.7。
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
            updatePlaceholder()
            updateBorder()
            updateBackground()
        }
    }

    // MARK: - 内部私有方法 (Private)
    
    /// 安全获取当前字体，防止原生 font 为 nil 时引发崩溃
    private var currentFont: UIFont {
        return font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    /// 判断当前是否有文本内容
    private var isTextNotEmpty: Bool {
        return text?.isNotEmpty ?? false
    }

    /// 更新边框的位置、粗细和颜色
    private func updateBorder() {
        borderLayer.frame = rectForBounds(bounds)
        borderLayer.borderWidth = borderSize
        // 激活状态时使用 activeBorderColor，否则使用 inactiveBorderColor
        borderLayer.borderColor = (isFirstResponder || isTextNotEmpty) ? activeBorderColor.cgColor : inactiveBorderColor.cgColor
    }

    /// 更新输入框底部的背景颜色
    private func updateBackground() {
        if isFirstResponder || isTextNotEmpty {
            borderLayer.backgroundColor = activeBackgroundColor.cgColor
        } else {
            borderLayer.backgroundColor = inactiveBorderColor.cgColor
        }
    }

    /// 更新占位符的文字、字体、对齐方式及颜色
    private func updatePlaceholder() {
        placeholderLabel.frame = placeholderRect(forBounds: bounds)
        placeholderLabel.textAlignment = textAlignment

        if isFirstResponder || isTextNotEmpty {
            // 修复 Bug：正确使用传入的 percentageOfOriginalSize 进行二次缩放计算
            placeholderLabel.font = placeholderFontFromFont(font: currentFont, percentageOfOriginalSize: placeholderFontScale * 0.8)
            placeholderLabel.text = placeholder?.uppercased() // 激活时转为大写
            placeholderLabel.textColor = activeBorderColor
        } else {
            placeholderLabel.font = placeholderFontFromFont(font: currentFont, percentageOfOriginalSize: placeholderFontScale)
            placeholderLabel.text = placeholder
            placeholderLabel.textColor = placeholderColor
        }
    }
    
    /// 修复 Bug 后的字体缩放计算方法
    private func placeholderFontFromFont(font: UIFont, percentageOfOriginalSize: CGFloat) -> UIFont {
        return UIFont(descriptor: font.fontDescriptor, size: font.pointSize * percentageOfOriginalSize)
    }

    /// 计算边框图层所在的区域坐标 (让出顶部占位符悬浮的空间)
    private func rectForBounds(_ bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x, y: bounds.origin.y + placeholderHeight, width: bounds.size.width, height: bounds.size.height - placeholderHeight)
    }

    /// 计算占位符区域的高度
    private var placeholderHeight: CGFloat {
        return placeHolderInsets.y + placeholderFontFromFont(font: currentFont, percentageOfOriginalSize: placeholderFontScale).lineHeight
    }
    
    /// 核心动画逻辑封装：处理状态切换时的视图过渡动画
    private func animateViews() {
        UIView.animate(withDuration: 0.2, animations: {
            // 防止在状态切换时占位符出现不自然的“闪烁”
            let isTextEmpty = self.text?.isEmpty ?? true
            if isTextEmpty {
                self.placeholderLabel.alpha = 0
            }
            
            self.placeholderLabel.frame = self.placeholderRect(forBounds: self.bounds)
            
        }) { _ in
            // 第一阶段动画完成后，更新占位符的最终状态（字体、文字大小写等）
            self.updatePlaceholder()
            
            // 第二阶段动画：透明度恢复，更新边框和背景色
            UIView.animate(withDuration: 0.3, animations: {
                self.placeholderLabel.alpha = 1
                self.updateBorder()
                self.updateBackground()
            }, completion: { _ in
                self.animationCompletionHandler?(self.isFirstResponder ? .textEntry : .textDisplay)
            })
        }
    }
    
    // MARK: - TextFieldEffects 生命周期实现
    
    override open func animateViewsForTextEntry() {
        animateViews()
    }
    
    override open func animateViewsForTextDisplay() {
        animateViews()
    }
    
    override open func drawViewsForRect(_ rect: CGRect) {
        updatePlaceholder()
        updateBorder()
        updateBackground()
        
        // 安全检查：防止视图和图层在多次重绘时被重复添加
        if borderLayer.superlayer == nil {
            layer.insertSublayer(borderLayer, at: 0)
        }
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
        }
    }
    
    // MARK: - UITextField 边界区域重写 (Overrides)
    
    /// 返回占位符的绘制区域
    open override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        if isFirstResponder || isTextNotEmpty {
            // 激活状态下，占位符上浮至预设的顶部内边距位置
            return CGRect(x: placeHolderInsets.x, y: placeHolderInsets.y, width: bounds.width, height: placeholderHeight)
        } else {
            // 未激活状态下，占位符处于正常文本位置
            return textRect(forBounds: bounds)
        }
    }
    
    /// 返回处于编辑状态时的文本绘制区域
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
    
    /// 返回正常的文本绘制区域
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        // 让出顶部的高度，保证输入的文本不会和上浮的占位符重叠
        return CGRect(x: textFieldInsets.x,
                      y: placeholderHeight,
                      width: bounds.width - (textFieldInsets.x * 2),
                      height: bounds.height - placeholderHeight)
    }
    
    // MARK: - Interface Builder 支持
    
    /// 支持在 Storyboard 或 XIB 中实时预览时，确保占位符可见
    open override func prepareForInterfaceBuilder() {
        placeholderLabel.alpha = 1
    }
}
