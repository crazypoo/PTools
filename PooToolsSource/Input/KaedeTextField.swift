//
//  KaedeTextField.swift
//  Swish
//
//  Created by Raúl Riera on 20/01/2015.
//  Copyright (c) 2015 com.raulriera.swishapp. All rights reserved.
//

import UIKit

/// 一个继承自 TextFieldEffects 的自定义输入框 (Kaede 风格)。
/// 特效表现：激活时，前景视图和占位符文字会以弹簧动效向一侧滑开，暴露出底部的输入区域。
@IBDesignable open class KaedeTextField: TextFieldEffects {
    
    // MARK: - 可视化属性 (IBInspectable)
    
    /// 占位符文字的颜色。
    /// 默认值为黑色 (在代码逻辑中如果不传则不改变默认颜色)。
    @IBInspectable dynamic open var placeholderColor: UIColor? {
        didSet {
            updatePlaceholder()
        }
    }
    
    /// 占位符的字体缩放比例。
    /// 相对于输入框真实字体的大小的比例，默认为 0.8。
    @IBInspectable dynamic open var placeholderFontScale: CGFloat = 0.8 {
        didSet {
            updatePlaceholder()
        }
    }
    
    /// 遮盖在输入框上方的前景视图颜色。
    /// 默认值为透明 (clear color)。
    @IBInspectable dynamic open var foregroundColor: UIColor? {
        didSet {
            updateForegroundColor()
        }
    }
    
    /// 占位符区域和输入区域的分割比例。
    /// 取值范围通常为 0.0 ~ 1.0。例如 0.6 表示输入区域占宽度的 60%，前景视图向外滑开 60%。
    @IBInspectable dynamic open var placeholderSplit: CGFloat = 0.6
    
    // MARK: - 原生属性重写
    
    override open var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override open var bounds: CGRect {
        didSet {
            // 当 bounds 发生变化时，重新布局视图
            drawViewsForRect(bounds)
        }
    }
    
    // MARK: - 私有配置参数
    
    /// 覆盖在输入框上面的前景视图
    private let foregroundView = UIView()
    /// 占位符文字的内边距
    private let placeholderInsets = CGPoint(x: 10, y: 5)
    /// 实际输入文本的内边距
    private let textFieldInsets = CGPoint(x: 10, y: 0)
        
    // MARK: - TextFieldEffects 生命周期实现

    override open func drawViewsForRect(_ rect: CGRect) {
        let frame = CGRect(origin: .zero, size: CGSize(width: rect.size.width, height: rect.size.height))
        
        // 布局前景视图
        foregroundView.frame = frame
        foregroundView.isUserInteractionEnabled = false // 确保前景不会阻挡用户的触摸事件
        
        // 布局占位符
        placeholderLabel.frame = frame.insetBy(dx: placeholderInsets.x, dy: placeholderInsets.y)
        placeholderLabel.font = placeholderFontFromFont(currentFont)
        
        updateForegroundColor()
        updatePlaceholder()
        
        // 如果当前正在输入或已经有文字，直接触发展开动画
        let isTextNotEmpty = text?.isNotEmpty ?? false
        if isTextNotEmpty || isFirstResponder {
            animateViewsForTextEntry()
        }
        
        // 安全检查：防止视图被重复添加
        if foregroundView.superview == nil {
            addSubview(foregroundView)
        }
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
        }
    }
    
    override open func animateViewsForTextEntry() {
        // 根据系统设定的语义内容属性，判断滑动方向 (兼容 RTL 从右到左的语言习惯，如阿拉伯语)
        let directionOverride: CGFloat = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft ? -1.0 : 1.0

        // 占位符文字滑开动画
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: .beginFromCurrentState, animations: {
            self.placeholderLabel.frame.origin = CGPoint(x: self.frame.size.width * (self.placeholderSplit + 0.05) * directionOverride, y: self.placeholderInsets.y)
        }, completion: nil)
        
        // 前景视图块滑开动画
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.5, options: .beginFromCurrentState, animations: {
            self.foregroundView.frame.origin = CGPoint(x: self.frame.size.width * self.placeholderSplit * directionOverride, y: 0)
        }, completion: { _ in
            self.animationCompletionHandler?(.textEntry)
        })
    }
    
    override open func animateViewsForTextDisplay() {
        // 只有当文本真正为空时，才执行闭合恢复的动画
        let isTextEmpty = text?.isEmpty ?? true
        if isTextEmpty {
            
            // 占位符文字恢复原位
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: .beginFromCurrentState, animations: {
                self.placeholderLabel.frame.origin = self.placeholderInsets
            }, completion: nil)
            
            // 前景视图块恢复原位覆盖
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2.0, options: .beginFromCurrentState, animations: {
                self.foregroundView.frame.origin = CGPoint.zero
            }, completion: { _ in
                self.animationCompletionHandler?(.textDisplay)
            })
        }
    }
    
    // MARK: - 内部私有方法 (Private)
    
    /// 安全获取当前字体，防止原生 font 为 nil 导致崩溃
    private var currentFont: UIFont {
        return font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    /// 更新前景视图颜色
    private func updateForegroundColor() {
        foregroundView.backgroundColor = foregroundColor
    }
    
    /// 更新占位符状态
    private func updatePlaceholder() {
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = placeholderColor
    }
    
    /// 计算缩放后的占位符字体
    private func placeholderFontFromFont(_ font: UIFont) -> UIFont {
       return UIFont(descriptor: font.fontDescriptor, size: font.pointSize * placeholderFontScale)
    }
    
    // MARK: - UITextField 边界区域重写 (Overrides)
        
    /// 返回处于编辑状态时的文本绘制区域
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        // 限制编辑区域的宽度为总体宽度的设定比例 (如 60%)
        var frame = CGRect(origin: bounds.origin, size: CGSize(width: bounds.size.width * placeholderSplit, height: bounds.size.height))

        // 适配 RTL 布局：如果方向是从右到左，则输入区域靠右放置
        if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
            frame.origin = CGPoint(x: bounds.size.width - frame.size.width, y: frame.origin.y)
        }

        return frame.insetBy(dx: textFieldInsets.x, dy: textFieldInsets.y)
    }
    
    /// 返回正常的文本绘制区域
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return editingRect(forBounds: bounds)
    }
}
