//
//  MadokaTextField.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 05/02/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit

/// 一个继承自 TextFieldEffects 的自定义输入框 (Madoka 风格)。
/// 特效表现：激活时，底部单线边框会顺着边缘绘制成一个完整的矩形外框，占位符文字通过平移和缩放滑出。
@IBDesignable open class MadokaTextField: TextFieldEffects {
    
    // MARK: - 可视化属性 (IBInspectable)
    
    /// 占位符文字的颜色。
    /// 默认值为黑色。
    @IBInspectable dynamic open var placeholderColor: UIColor = .black {
        didSet {
            updatePlaceholder()
        }
    }
    
    /// 边框的颜色。
    /// 应用于环绕输入框的边框线条。默认为透明 (clear color)。
    @IBInspectable dynamic open var borderColor: UIColor? {
        didSet {
            updateBorder()
        }
    }
    
    /// 占位符上浮后的字体缩放比例。
    /// 相对于输入框真实字体的大小的比例，默认为 0.65。
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
    
    /// 边框线条的粗细
    private let borderThickness: CGFloat = 1
    /// 占位符的内边距偏移量
    private let placeholderInsets = CGPoint(x: 6, y: 6)
    /// 实际输入文本的内边距偏移量
    private let textFieldInsets = CGPoint(x: 6, y: 6)
    
    /// 负责绘制动态外框的形状图层
    private let borderLayer = CAShapeLayer()
    private var backgroundLayerColor: UIColor?
    
    // MARK: - TextFieldEffects 生命周期实现
    
    override open func drawViewsForRect(_ rect: CGRect) {
        let frame = CGRect(origin: CGPoint.zero, size: rect.size)
        
        placeholderLabel.frame = frame.insetBy(dx: placeholderInsets.x, dy: placeholderInsets.y)
        placeholderLabel.font = placeholderFontFromFont(currentFont)
        
        updateBorder()
        updatePlaceholder()
        
        // 安全检查：防止在多次调用 draw 时重复添加图层和视图导致内存泄漏
        if borderLayer.superlayer == nil {
            layer.addSublayer(borderLayer)
        }
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
        }
    }
    
    override open func animateViewsForTextEntry() {
        // 动画：让边框的绘制终点变为 1（即画满整个矩形路径）
        borderLayer.strokeEnd = 1
        
        UIView.animate(withDuration: 0.3, animations: {
            // 设置平移和缩放矩阵组合：占位符向左移动，向下/外侧偏移，并且缩小
            let translate = CGAffineTransform(translationX: -self.placeholderInsets.x, y: self.placeholderLabel.bounds.height + (self.placeholderInsets.y * 2))
            let scale = CGAffineTransform(scaleX: 0.9, y: 0.9)
            
            self.placeholderLabel.transform = translate.concatenating(scale)
        }) { _ in
            self.animationCompletionHandler?(.textEntry)
        }
    }
    
    override open func animateViewsForTextDisplay() {
        let isTextEmpty = text?.isEmpty ?? true
        
        if isTextEmpty {
            // 恢复动画：边框回退到只绘制底部线段的百分比
            borderLayer.strokeEnd = percentageForBottomBorder()
            
            UIView.animate(withDuration: 0.3, animations: {
                // 占位符文字恢复初始状态
                self.placeholderLabel.transform = .identity
            }) { _ in
                self.animationCompletionHandler?(.textDisplay)
            }
        }
    }
    
    // MARK: - 内部私有方法 (Private)
    
    /// 安全获取当前字体
    private var currentFont: UIFont {
        return font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    /// 更新边框外观并绘制矩形路径
    private func updateBorder() {
        let rect = rectForBorder(bounds)
        let path = UIBezierPath()
        
        // 精心设计的路径绘制顺序：从左下角开始 -> 右下角 -> 右上角 -> 左上角 -> 回到左下角闭合
        // 这样保证第一笔画的是底部的那条线
        path.move(to: CGPoint(x: rect.origin.x + borderThickness, y: rect.height - borderThickness))
        path.addLine(to: CGPoint(x: rect.width - borderThickness, y: rect.height - borderThickness))
        path.addLine(to: CGPoint(x: rect.width - borderThickness, y: rect.origin.y + borderThickness))
        path.addLine(to: CGPoint(x: rect.origin.x + borderThickness, y: rect.origin.y + borderThickness))
        path.close()
        
        borderLayer.path = path.cgPath
        borderLayer.lineCap = .square
        borderLayer.lineWidth = borderThickness
        borderLayer.fillColor = nil // 内部不填充颜色
        borderLayer.strokeColor = borderColor?.cgColor
        
        // 如果当前是激活状态，则线条画满；否则只画到底部线段所占的百分比位置
        let isTextNotEmpty = text?.isNotEmpty ?? false
        borderLayer.strokeEnd = (isFirstResponder || isTextNotEmpty) ? 1 : percentageForBottomBorder()
    }
    
    /// 计算底部线条占整个矩形周长的百分比。
    /// 因为路径是从底部开始画的，strokeEnd 等于这个百分比时，刚好只显示底边。
    private func percentageForBottomBorder() -> CGFloat {
        let borderRect = rectForBorder(bounds)
        let sumOfSides = (borderRect.width * 2) + (borderRect.height * 2)
        // 计算宽度（底部线条长度）占总周长的比例
        return borderRect.width / sumOfSides
    }
    
    /// 更新占位符状态
    private func updatePlaceholder() {
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.sizeToFit()
        layoutPlaceholderInTextRect()
        
        let isTextNotEmpty = text?.isNotEmpty ?? false
        if isFirstResponder || isTextNotEmpty {
            animateViewsForTextEntry()
        }
    }
    
    /// 计算缩放后的占位符字体
    private func placeholderFontFromFont(_ font: UIFont) -> UIFont {
        return UIFont(descriptor: font.fontDescriptor, size: font.pointSize * placeholderFontScale)
    }
    
    /// 计算边框应当处于的位置 (为占位符等元素腾出空间)
    private func rectForBorder(_ bounds: CGRect) -> CGRect {
        // 使用安全解包的 currentFont
        return CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height - currentFont.lineHeight + textFieldInsets.y)
    }
    
    /// 布局占位符，使其正确显示在文本区域内
    private func layoutPlaceholderInTextRect() {
        // 布局前先重置变换，避免尺寸计算错误
        placeholderLabel.transform = CGAffineTransform.identity
        
        let textRect = self.textRect(forBounds: bounds)
        var originX = textRect.origin.x
        
        // 适配不同的对齐方式
        switch textAlignment {
        case .center:
            originX += textRect.size.width / 2 - placeholderLabel.bounds.width / 2
        case .right:
            originX += textRect.size.width - placeholderLabel.bounds.width
        default:
            break
        }
        
        placeholderLabel.frame = CGRect(x: originX, y: textRect.height - placeholderLabel.bounds.height - placeholderInsets.y,
                                        width: placeholderLabel.bounds.width, height: placeholderLabel.bounds.height)
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
