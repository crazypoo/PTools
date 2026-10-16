//
//  YoshikoTextField.swift
//  TextFieldEffects
//
//  Created by Keenan Cassidy on 01/10/2015.
//  Copyright © 2015 Raul Riera. All rights reserved.
//

import UIKit

// English: Import the rich-text contracts explicitly for standalone SwiftPM builds.
// Español: Importa explícitamente los contratos de texto enriquecido para las compilaciones SwiftPM independientes.
// 中文：独立 SwiftPM 编译时，显式导入富文本契约。
#if SWIFT_PACKAGE
import PToolsUIFoundation
#endif

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
        }
    }
    
    /// 未激活状态（无焦点且无内容）时的边框颜色。
    /// 默认值为透明 (clear color)。
    @IBInspectable dynamic open var inactiveBorderColor: UIColor = .clear {
        didSet {
            updateBorder()
            updateBackground()
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

    // English: Keep the floating placeholder color independent from the active border color; nil reuses placeholderColor.
    // Español: Mantiene independiente el color del placeholder flotante del borde activo; nil reutiliza placeholderColor.
    // 中文：让悬浮占位符颜色独立于激活边框颜色；为 nil 时沿用 placeholderColor。
    @IBInspectable dynamic open var activePlaceholderColor: UIColor? {
        didSet {
            updatePlaceholder()
        }
    }

    // English: Use a separate floating placeholder font; nil keeps the shared placeholder font and scale.
    // Español: Usa una fuente independiente para el placeholder flotante; nil conserva la fuente y escala compartidas.
    // 中文：为悬浮占位符提供独立字体；为 nil 时沿用共享占位符字体和缩放比例。
    open var activePlaceholderFont: UIFont? {
        didSet {
            updatePlaceholder()
        }
    }

    // English: Use a separate floating rich placeholder; nil falls back to the shared placeholderAtt.
    // Español: Usa un placeholder enriquecido independiente al flotar; nil vuelve a placeholderAtt.
    // 中文：为悬浮占位符提供独立富文本；为 nil 时回退到共享的 placeholderAtt。
    open var activePlaceholderAtt: PTRichText? {
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
        placeholderLabel.textAlignment = textAlignment

        let isActive = isFirstResponder || isTextNotEmpty
        let scale = isActive ? placeholderFontScale * 0.8 : placeholderFontScale
        let resolvedFont = activePlaceholderFont ??
            inputAppearance.placeholderFontOverride ??
            UIFont(descriptor: currentFont.fontDescriptor, size: max(1, currentFont.pointSize * scale))
        let resolvedColor = inputAppearance.placeholderColorOverride ??
            (isActive ? (activePlaceholderColor ?? placeholderColor) : placeholderColor)
        let resolvedRichText = isActive ? (activePlaceholderAtt ?? placeholderAtt) : placeholderAtt

        if let resolvedRichText {
            placeholderLabel.attributedText = PTInputPlaceholderRenderer.attributedText(resolvedRichText,
                                                                                         font: resolvedFont,
                                                                                         color: resolvedColor)
            placeholderLabel.text = nil
        } else {
            placeholderLabel.attributedText = nil
            placeholderLabel.text = isActive ? placeholder?.uppercased() : placeholder
            placeholderLabel.font = resolvedFont
            placeholderLabel.textColor = resolvedColor
        }

        placeholderLabel.frame = placeholderRect(forBounds: bounds)
    }

    // English: Refresh Yoshiko with its state-specific uppercase and border rules.
    // Español: Actualiza Yoshiko respetando sus reglas de mayúsculas y bordes por estado.
    // 中文：刷新 Yoshiko，同时保留按状态大写和边框规则。
    override open func refreshPlaceholderAppearance() {
        updatePlaceholder()
    }
    
    /// 计算边框图层所在的区域坐标 (让出顶部占位符悬浮的空间)
    private func rectForBounds(_ bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x,
                      y: bounds.origin.y + placeholderHeight,
                      width: bounds.size.width,
                      height: max(0, bounds.size.height - placeholderHeight))
    }

    // English: Reserve the measured placeholder height so a floating label is never clipped.
    // Español: Reserva la altura medida del placeholder para que la etiqueta flotante nunca se recorte.
    // 中文：根据占位符的实际测量高度预留空间，避免悬浮标签被裁剪。
    private var placeholderHeight: CGFloat {
        let fallbackHeight = placeHolderInsets.y + (placeholderLabel.font ?? currentFont).lineHeight
        guard bounds.width > 0 else { return fallbackHeight }

        let availableWidth = max(1, bounds.width - (placeHolderInsets.x * 2))
        let measuredHeight = placeholderLabel.sizeThatFits(CGSize(width: availableWidth,
                                                                   height: .greatestFiniteMagnitude)).height
        return max(fallbackHeight, measuredHeight + placeHolderInsets.y)
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
            return CGRect(x: placeHolderInsets.x,
                          y: placeHolderInsets.y,
                          width: max(0, bounds.width - (placeHolderInsets.x * 2)),
                          height: placeholderHeight)
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
        return applySharedTextRect(CGRect(x: textFieldInsets.x,
                                          y: placeholderHeight,
                                          width: max(0, bounds.width - (textFieldInsets.x * 2)),
                                          height: max(0, bounds.height - placeholderHeight)),
                                   bounds: bounds)
    }
    
    // MARK: - Interface Builder 支持
    
    /// 支持在 Storyboard 或 XIB 中实时预览时，确保占位符可见
    open override func prepareForInterfaceBuilder() {
        // English: Interface Builder may call this hook outside the main-actor context.
        // Español: Interface Builder puede llamar a este método fuera del contexto del actor principal.
        // 中文：Interface Builder 可能在非主 actor 上下文调用此方法。
        Task { @MainActor [weak self] in
            self?.placeholderLabel.alpha = 1
            self?.setNeedsLayout()
            self?.setNeedsDisplay()
        }
    }
}
