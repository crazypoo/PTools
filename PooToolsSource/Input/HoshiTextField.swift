//
//  HoshiTextField.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 24/01/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif // 依赖第三方或自定义的属性字符串库
import SnapKit        // 依赖 SnapKit 进行自动布局

// MARK: - HoshiTextField

/// 一个继承自 TextFieldEffects 的自定义输入框。
/// 特效表现：当处于输入状态时，底部边框颜色和粗细发生变化，占位符文字缩小并向上悬浮。
@IBDesignable open class HoshiTextField: TextFieldEffects {
    
    // MARK: - 可视化属性 (IBInspectable)
    
    /// 输入框未激活（无焦点且无内容）时的底部边框颜色。默认透明。
    @IBInspectable dynamic open var borderInactiveColor: UIColor? {
        didSet { updateBorder() }
    }
    
    /// 输入框激活（有焦点或有内容）时的底部边框颜色。默认透明。
    @IBInspectable dynamic open var borderActiveColor: UIColor? {
        didSet { updateBorder() }
    }
    
    /// 占位符文字颜色。默认为黑色。
    @IBInspectable dynamic open var placeholderColor: UIColor = .black {
        didSet { updatePlaceholder() }
    }
    
    /// 占位符悬浮时的字体缩放比例。默认为 0.65。
    @IBInspectable dynamic open var placeholderFontScale: CGFloat = 0.65 {
        didSet { updatePlaceholder() }
    }
    
    // MARK: - 属性覆盖与扩展
    
    override open var placeholder: String? {
        didSet { updatePlaceholder() }
    }
    
    override open var bounds: CGRect {
        didSet {
            updateBorder()
            updatePlaceholder()
        }
    }
    
    // MARK: - 私有属性配置
    
    private let borderThickness: (active: CGFloat, inactive: CGFloat) = (active: 2, inactive: 0.5)
    private let placeholderInsets = CGPoint(x: 0, y: 6)
    private let textFieldInsets = CGPoint(x: 0, y: 12)
    private let inactiveBorderLayer = CALayer()
    private let activeBorderLayer = CALayer()
    private var activePlaceholderPoint: CGPoint = CGPoint.zero
    
    // MARK: - TextFieldEffects 生命周期实现
    
    override open func drawViewsForRect(_ rect: CGRect) {
        let frame = CGRect(origin: CGPoint.zero, size: rect.size)
        
        placeholderLabel.frame = frame.insetBy(dx: placeholderInsets.x, dy: placeholderInsets.y)
        // 安全解包 font
        placeholderLabel.font = placeholderFontFromFont(currentFont)
        
        updateBorder()
        updatePlaceholder()
        
        // 防止重复添加图层和视图导致内存泄漏
        if inactiveBorderLayer.superlayer == nil {
            layer.addSublayer(inactiveBorderLayer)
        }
        if activeBorderLayer.superlayer == nil {
            layer.addSublayer(activeBorderLayer)
        }
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
        }
    }
    
    override open func animateViewsForTextEntry() {
        // 安全解包 text
        let isTextEmpty = text?.isEmpty ?? true
        
        if isTextEmpty {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: {
                self.placeholderLabel.frame.origin = CGPoint(x: 10, y: self.placeholderLabel.frame.origin.y)
                self.placeholderLabel.alpha = 0
            }, completion: { _ in
                self.animationCompletionHandler?(.textEntry)
            })
        }
    
        layoutPlaceholderInTextRect()
        placeholderLabel.frame.origin = activePlaceholderPoint

        UIView.animate(withDuration: 0.4, animations: {
            self.placeholderLabel.alpha = 1.0
        })

        activeBorderLayer.frame = rectForBorder(borderThickness.active, isFilled: true)
    }
    
    override open func animateViewsForTextDisplay() {
        let isTextEmpty = text?.isEmpty ?? true
        
        if isTextEmpty {
            UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: .beginFromCurrentState, animations: {
                self.layoutPlaceholderInTextRect()
                self.placeholderLabel.alpha = 1
            }, completion: { _ in
                self.animationCompletionHandler?(.textDisplay)
            })
            
            activeBorderLayer.frame = self.rectForBorder(self.borderThickness.active, isFilled: false)
            inactiveBorderLayer.frame = self.rectForBorder(self.borderThickness.inactive, isFilled: true)
        }
    }
    
    // MARK: - 内部私有方法
    
    private var currentFont: UIFont {
        return font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    }
    
    private func updateBorder() {
        inactiveBorderLayer.frame = rectForBorder(borderThickness.inactive, isFilled: !isFirstResponder)
        inactiveBorderLayer.backgroundColor = borderInactiveColor?.cgColor
        
        activeBorderLayer.frame = rectForBorder(borderThickness.active, isFilled: isFirstResponder)
        activeBorderLayer.backgroundColor = borderActiveColor?.cgColor
    }
    
    private func updatePlaceholder() {
        applyPlaceholder(to: placeholderLabel,
                         text: placeholder,
                         font: currentFont,
                         color: placeholderColor,
                         scale: placeholderFontScale)
        placeholderLabel.sizeToFit()
        layoutPlaceholderInTextRect()
        
        let isTextNotEmpty = text?.isNotEmpty ?? false
        if isFirstResponder || isTextNotEmpty {
            animateViewsForTextEntry()
        }
    }

    // English: Refresh Hoshi's floating label while preserving its two-border effect.
    // Español: Actualiza la etiqueta flotante de Hoshi y conserva su efecto de dos bordes.
    // 中文：刷新 Hoshi 浮动标签，同时保留双底边效果。
    override open func refreshPlaceholderAppearance() {
        updatePlaceholder()
    }
    
    private func placeholderFontFromFont(_ font: UIFont) -> UIFont {
        inputAppearance.placeholderFontOverride ?? UIFont(descriptor: font.fontDescriptor,
                                                           size: font.pointSize * placeholderFontScale)
    }
    
    private func rectForBorder(_ thickness: CGFloat, isFilled: Bool) -> CGRect {
        if isFilled {
            return CGRect(origin: CGPoint(x: 0, y: frame.height - thickness), size: CGSize(width: frame.width, height: thickness))
        } else {
            return CGRect(origin: CGPoint(x: 0, y: frame.height - thickness), size: CGSize(width: 0, height: thickness))
        }
    }
    
    private func layoutPlaceholderInTextRect() {
        let textRect = self.textRect(forBounds: bounds)
        var originX = textRect.origin.x
        
        switch self.textAlignment {
        case .center:
            originX += textRect.size.width / 2 - placeholderLabel.bounds.width / 2
        case .right:
            originX += textRect.size.width - placeholderLabel.bounds.width
        default:
            break
        }
        
        placeholderLabel.frame = CGRect(x: originX, y: textRect.height / 2, width: placeholderLabel.bounds.width, height: placeholderLabel.bounds.height)
        activePlaceholderPoint = CGPoint(x: placeholderLabel.frame.origin.x, y: placeholderLabel.frame.origin.y - placeholderLabel.frame.size.height - placeholderInsets.y)
    }
    
    // MARK: - UITextField 重写
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        applySharedTextRect(bounds.offsetBy(dx: textFieldInsets.x, dy: textFieldInsets.y), bounds: bounds)
    }
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        applySharedTextRect(bounds.offsetBy(dx: textFieldInsets.x, dy: textFieldInsets.y), bounds: bounds)
    }
}


// MARK: - PTHoshiTextField

/// 直接继承自 UITextField，利用 SnapKit 约束实现类似功能的输入框，支持左侧留白设定。
@MainActor
open class PTHoshiTextField: UITextField {
    
    private let floatingLabel: UILabel = UILabel()

    // English: Keep the standalone Hoshi variant on the same appearance contract as TextFieldEffects.
    // Español: Mantiene la variante Hoshi independiente en el mismo contrato de apariencia que TextFieldEffects.
    // 中文：让独立 Hoshi 变体也遵循 TextFieldEffects 的统一外观契约。
    open var inputAppearance = PTInputAppearance() {
        didSet { applyInputAppearance() }
    }
    
    // MARK: - 公开属性配置
    
    override open var placeholder: String? {
        didSet { updatePlaceholder() }
    }
    
    dynamic open var placeholderAtt: PTRichText? {
        didSet { updatePlaceholder() }
    }
    
    dynamic open var placeholderColor: UIColor = .black {
        didSet { updatePlaceholder() }
    }
    
    dynamic open var placeholderFont: UIFont = UIFont.systemFont(ofSize: 12) {
        didSet { updatePlaceholder() }
    }
    
    /// 输入文本与悬浮占位符之间的距离
    open var textAndPlaceholderSpace: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }

    /// 兼容旧拼写，内部与正确拼写共用同一份值。
    @available(*, deprecated, message: "Use textAndPlaceholderSpace instead")
    open var textAndPlceholderSpace: CGFloat {
        get { textAndPlaceholderSpace }
        set { textAndPlaceholderSpace = newValue }
    }

    open var leadingSpace: CGFloat {
        get { leftSpace ?? 0 }
        set { leftSpace = newValue }
    }
    
    /// 左侧留白距离
    open var leftSpace: CGFloat? {
        didSet {
            leftSpaceView.frame.size = CGSize(width: leftSpace ?? 0, height: bounds.height)
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
    
    /// 文本编辑区域的自定义内边距
    open var textEditingEdges: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    // 使用懒加载并安全使用 leftSpace
    private lazy var leftSpaceView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: leftSpace ?? 0, height: self.frame.size.height)
        return view
    }()

    private func applyInputAppearance() {
        placeholderAtt = inputAppearance.placeholderAtt
        if let value = inputAppearance.placeholderColorOverride { placeholderColor = value }
        if let value = inputAppearance.placeholderFontOverride { placeholderFont = value }
        textAndPlaceholderSpace = inputAppearance.textAndPlaceholderSpace
        leftSpace = inputAppearance.leadingSpace > 0 ? inputAppearance.leadingSpace : nil
        textEditingEdges = inputAppearance.textEditingEdges
        setNeedsLayout()
    }
    
    // MARK: - 初始化
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // English: Expose the frame initializer so callers do not select UIKit's iOS 27 primaryAction overload.
    // Español: Expone el inicializador por frame para evitar que las llamadas elijan la sobrecarga primaryAction de UIKit en iOS 27.
    // 中文：公开 frame 初始化方法，避免调用方在 iOS 27 误选 UIKit 的 primaryAction 重载。
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        addTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
        
        floatingLabel.textColor = self.placeholderColor
        floatingLabel.font = self.placeholderFont
        floatingLabel.alpha = 0
        
        addSubview(floatingLabel)
        
        let labelHeight = floatingLabel.font.pointSize + 5
        floatingLabel.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalToSuperview().inset(self.leftSpace ?? 0)
            make.top.equalToSuperview().inset((self.bounds.height - labelHeight) / 2)
            make.height.equalTo(labelHeight)
        }
    }

    // MARK: - 交互事件响应
    
    @objc private func textFieldDidChange() {
        updateFloatingLabel(animated: true)
    }

    @objc private func textFieldDidBeginEditing() {
        updateFloatingLabel(animated: true)
    }

    @objc private func textFieldDidEndEditing() {
        updateFloatingLabel(animated: true)
    }

    // MARK: - 核心动画与布局逻辑
    
    private func updateFloatingLabel(animated: Bool) {
        let isTextEmpty = text?.isEmpty ?? true
        let shouldFloat = !isTextEmpty || isFirstResponder

        let animations = {
            let labelHeight = self.floatingLabel.font.pointSize + 5
            self.floatingLabel.alpha = shouldFloat ? 1 : 0
            
            self.floatingLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(shouldFloat ? self.setTextAndPlaceHolderTop() : (self.bounds.height - labelHeight) / 2)
                make.left.equalToSuperview().inset(self.leftSpace ?? 0)
            }
            // 触发布局更新
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: animations)
        } else {
            animations()
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        if let space = leftSpace, space > 0 {
            leftSpaceView.frame = CGRect(x: 0, y: 0, width: space, height: bounds.height)
            if leftView == nil || leftView === leftSpaceView {
                leftView = leftSpaceView
                leftViewMode = .always
            }
        } else if leftView === leftSpaceView {
            leftView = nil
            leftViewMode = .never
        }
        
        let labelHeight = self.floatingLabel.font.pointSize + 5
        let isTextEmpty = text?.isEmpty ?? true
        
        if !isTextEmpty || isFirstResponder {
            floatingLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(self.setTextAndPlaceHolderTop())
                make.left.equalToSuperview().inset(self.leftSpace ?? 0)
            }
            floatingLabel.alpha = !isTextEmpty ? 1 : 0
        } else {
            floatingLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset((self.bounds.height - labelHeight) / 2)
                make.left.equalToSuperview().inset(self.leftSpace ?? 0)
            }
            floatingLabel.alpha = 0
        }
    }
    
    private func updatePlaceholder() {
        if let placeholderAtt = placeholderAtt {
            floatingLabel.attributedText = PTInputPlaceholderRenderer.attributedText(placeholderAtt,
                                                                                       font: placeholderFont,
                                                                                       color: placeholderColor)
            floatingLabel.text = nil
            attributedPlaceholder = floatingLabel.attributedText
        } else {
            floatingLabel.attributedText = nil
            floatingLabel.text = placeholder
            floatingLabel.font = placeholderFont
            floatingLabel.textColor = placeholderColor
            attributedPlaceholder = nil
        }
        floatingLabel.sizeToFit()
    }
    
    private func setTextAndPlaceHolderTop() -> CGFloat {
        let currentFont = self.font ?? UIFont.systemFont(ofSize: 14)
        let fontToTopHeight = (self.bounds.height - currentFont.pointSize) / 2
        var lessSpace: CGFloat = 0

        if let placeholderAtt = placeholderAtt {
            lessSpace = fontToTopHeight - (placeholderAtt.value.largestFontSize() + 5)
        } else {
            lessSpace = fontToTopHeight - (self.floatingLabel.font.pointSize + 5)
        }
        
        if lessSpace < 0 {
            lessSpace = 0
        } else {
            if (lessSpace - textAndPlaceholderSpace) < 0 {
                lessSpace = 0
            } else {
                lessSpace -= textAndPlaceholderSpace
            }
        }
        return lessSpace
    }
    
    // MARK: - UITextField 边界区域重写（精简冗余判断）
    
    /// 获取经过简化的内边距 Rect
    private func calculatedRect(forBounds bounds: CGRect) -> CGRect {
        // English: Keep the text origin stable while the first character is entered.
        // Español: Mantiene estable el origen del texto al introducir el primer carácter.
        // 中文：输入第一个字符时保持文本起点稳定，避免水平方向跳动。
        return bounds.inset(by: textEditingEdges)
    }

    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        return calculatedRect(forBounds: bounds)
    }

    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return calculatedRect(forBounds: bounds)
    }

    open override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return calculatedRect(forBounds: bounds)
    }
}
