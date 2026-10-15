//
//  TextFieldEffects.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 24/01/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif

extension String {
    /// 检查字符串是否不为空
    /// - Returns: 如果包含字符返回 true，如果是空字符串则返回 false
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

/// 一个自定义的 UITextField 基类，用于处理独特的文本输入状态和占位符显示动画。
/// ⚠️ 注意：这是一个抽象基类，不应该直接实例化。请通过创建它的子类来实现具体的视图绘制和动画逻辑。
// English: Shared input appearance keeps configuration and geometry consistent across every effect style.
// Español: La apariencia compartida mantiene coherentes la configuración y la geometría entre todos los estilos.
// 中文：共享输入外观让所有效果样式的配置和几何计算保持一致。
@MainActor
public struct PTInputAppearance {
    public var placeholderAtt: PTRichText?
    public var placeholderColorOverride: UIColor?
    public var placeholderFontOverride: UIFont?
    public var textAndPlaceholderSpace: CGFloat
    public var leadingSpace: CGFloat
    public var textEditingEdges: UIEdgeInsets

    public init(placeholderAtt: PTRichText? = nil,
                placeholderColorOverride: UIColor? = nil,
                placeholderFontOverride: UIFont? = nil,
                textAndPlaceholderSpace: CGFloat = 0,
                leadingSpace: CGFloat = 0,
                textEditingEdges: UIEdgeInsets = .zero) {
        self.placeholderAtt = placeholderAtt
        self.placeholderColorOverride = placeholderColorOverride
        self.placeholderFontOverride = placeholderFontOverride
        self.textAndPlaceholderSpace = max(0, textAndPlaceholderSpace)
        self.leadingSpace = max(0, leadingSpace)
        self.textEditingEdges = textEditingEdges
    }
}

// English: Fill only missing rich-text runs so explicit colors and fonts remain intact.
// Español: Completa solo los atributos ausentes para conservar los colores y fuentes explícitos.
// 中文：仅补全富文本中缺失的属性，保留每个 run 已明确设置的颜色和字体。
@MainActor
internal enum PTInputPlaceholderRenderer {
    static func attributedText(_ richText: PTRichText,
                               font: UIFont,
                               color: UIColor) -> NSAttributedString {
        let value = NSMutableAttributedString(attributedString: richText.value)
        guard value.length > 0 else { return value }

        value.enumerateAttributes(in: NSRange(location: 0, length: value.length), options: []) { attributes, range, _ in
            var additions: [NSAttributedString.Key: Any] = [:]
            if attributes[.font] == nil { additions[.font] = font }
            if attributes[.foregroundColor] == nil { additions[.foregroundColor] = color }
            if !additions.isEmpty { value.addAttributes(additions, range: range) }
        }
        return value
    }
}

@MainActor
open class TextFieldEffects: UITextField {
    
    /// 定义了输入框可以执行的动画类型
    public enum AnimationType: Int {
        /// 当输入框获得焦点或文本非空时触发的动画（进入输入状态）
        case textEntry
        /// 当输入框失去焦点且文本为空时触发的动画（恢复默认展示状态）
        case textDisplay
    }
    
    /// 动画完成后的回调闭包类型
    /// - Parameter type: 刚刚完成的动画类型
    public typealias AnimationCompletionHandler = (_ type: AnimationType) -> Void
    
    /// 自定义的占位符 Label，用于替代系统默认的占位符，以便子类对其进行动画处理
    public let placeholderLabel = UILabel()
    
    /// 动画完成时的回调属性
    open var animationCompletionHandler: AnimationCompletionHandler?

    // English: Report only active-state transitions; active means focused or containing text.
    // Español: Informa solo las transiciones de actividad; activo significa enfocado o con texto.
    // 中文：仅报告激活状态变化；激活表示获得焦点或当前包含文本。
    public typealias ActivityChangeHandler = @MainActor @Sendable (_ isActive: Bool) -> Void

    // English: External consumers can react to the shared active state without observing UIKit events.
    // Español: Los consumidores externos pueden reaccionar al estado activo común sin observar eventos de UIKit.
    // 中文：外部调用方无需监听 UIKit 事件即可响应统一的激活状态。
    open var activityChangeHandler: ActivityChangeHandler? {
        didSet {
            lastReportedActivity = nil
            notifyActivityIfNeeded()
        }
    }

    // English: The state is shared by every TextFieldEffects style and remains readable at any time.
    // Español: El estado es común a todos los estilos TextFieldEffects y siempre se puede consultar.
    // 中文：所有 TextFieldEffects 样式共享该状态，并且可以随时读取。
    public var isActive: Bool {
        isFirstResponder || !(text?.isEmpty ?? true)
    }

    /// 统一输入框外观配置；旧属性继续通过各样式保留。
    open var inputAppearance = PTInputAppearance() {
        didSet {
            refreshPlaceholderAppearance()
            invalidateInputLayout()
        }
    }

    /// 富文本占位符；设置为 nil 时回退到普通 placeholder。
    open var placeholderAtt: PTRichText? {
        get { inputAppearance.placeholderAtt }
        set {
            var appearance = inputAppearance
            appearance.placeholderAtt = newValue
            inputAppearance = appearance
        }
    }

    /// 显式占位符字体；未设置时由样式的缩放比例推导。
    open var placeholderFont: UIFont {
        get { inputAppearance.placeholderFontOverride ?? font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize) }
        set {
            var appearance = inputAppearance
            appearance.placeholderFontOverride = newValue
            inputAppearance = appearance
        }
    }

    open var textAndPlaceholderSpace: CGFloat {
        get { inputAppearance.textAndPlaceholderSpace }
        set {
            var appearance = inputAppearance
            appearance.textAndPlaceholderSpace = max(0, newValue)
            inputAppearance = appearance
        }
    }

    /// 兼容旧拼写，内部与正确拼写共用同一份值。
    @available(*, deprecated, message: "Use textAndPlaceholderSpace instead")
    open var textAndPlceholderSpace: CGFloat {
        get { textAndPlaceholderSpace }
        set { textAndPlaceholderSpace = newValue }
    }

    open var leadingSpace: CGFloat {
        get { inputAppearance.leadingSpace }
        set {
            var appearance = inputAppearance
            appearance.leadingSpace = max(0, newValue)
            inputAppearance = appearance
        }
    }

    /// 保留旧的 leftSpace 入口；对 TextFieldEffects 子类使用逻辑起始侧留白。
    open var leftSpace: CGFloat {
        get { leadingSpace }
        set { leadingSpace = newValue }
    }

    open var textEditingEdges: UIEdgeInsets {
        get { inputAppearance.textEditingEdges }
        set {
            var appearance = inputAppearance
            appearance.textEditingEdges = newValue
            inputAppearance = appearance
        }
    }
    
    // MARK: - 必须被子类重写的核心方法 (Abstract Methods)
    
    /// 创建并执行文本输入时的动画（例如：输入框聚焦时，占位符向上移动并缩小）。
    /// 未实现时保持安全空操作，避免复用或直接实例化触发运行时崩溃。
    open func animateViewsForTextEntry() {
    }
    
    /// 创建并执行结束文本输入时的动画（例如：输入框失去焦点且无文本时，占位符恢复原位）。
    /// 未实现时保持安全空操作。
    open func animateViewsForTextDisplay() {
    }
    
    /// 自定义绘制输入框的各种组件（例如绘制底部的下划线或边框）。
    /// - Parameter rect: 需要重绘的视图区域。
    /// 未实现时保持安全空操作。
    open func drawViewsForRect(_ rect: CGRect) {
    }
    
    /// 当输入框的边界 (bounds) 发生变化时更新视图。
    /// - Parameter bounds: 新的边界 CGRect。
    /// 未实现时保持安全空操作。
    open func updateViewsForBoundsChange(_ bounds: CGRect) {
    }

    /// 统一应用占位符并保留富文本 runs。
    open func applyPlaceholder(to label: UILabel,
                              text: String?,
                              font: UIFont,
                              color: UIColor,
                              scale: CGFloat = 1) {
        let resolvedFont = inputAppearance.placeholderFontOverride ?? UIFont(descriptor: font.fontDescriptor,
                                                                               size: max(1, font.pointSize * scale))
        let resolvedColor = inputAppearance.placeholderColorOverride ?? color
        if let richText = placeholderAtt {
            label.attributedText = PTInputPlaceholderRenderer.attributedText(richText,
                                                                               font: resolvedFont,
                                                                               color: resolvedColor)
            label.text = nil
        } else {
            label.attributedText = nil
            label.text = text
            label.font = resolvedFont
            label.textColor = resolvedColor
        }
    }

    // English: Let each visual style refresh its own placeholder label after shared configuration changes.
    // Español: Permite que cada estilo visual actualice su propia etiqueta tras cambiar la configuración compartida.
    // 中文：共享配置变化后，由各视觉样式刷新自己的占位符标签。
    open func refreshPlaceholderAppearance() {
    }

    /// 将样式自己的文本区域与统一的 RTL、边距配置合并。
    open func applySharedTextRect(_ styleRect: CGRect, bounds: CGRect) -> CGRect {
        var rect = styleRect.inset(by: textEditingEdges)
        rect.size.width = max(0, rect.size.width)
        rect.size.height = max(0, rect.size.height)

        let space = max(0, leadingSpace)
        guard space > 0, rect.width > 0 else { return rect }
        let isRTL = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        if isRTL {
            rect.size.width = max(0, rect.width - space)
        } else {
            rect.origin.x += space
            rect.size.width = max(0, rect.width - space)
        }
        return rect
    }

    open func invalidateInputLayout() {
        setNeedsLayout()
        setNeedsDisplay()
    }
    
    // MARK: - UITextField 默认行为重写
    
    /// 重写系统的 draw 方法以接入自定义的绘制逻辑
    override open func draw(_ rect: CGRect) {
        guard rect.width > 0, rect.height > 0 else { return }
        drawViewsForRect(rect)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        if renderedBounds != bounds {
            renderedBounds = bounds
            drawViewsForRect(bounds)
            updateViewsForBoundsChange(bounds)
        }
    }
    
    /// 重写绘制占位符的方法
    override open func drawPlaceholder(in rect: CGRect) {
        // 刻意留空：阻止系统绘制默认的占位符，因为我们要使用自定义的 `placeholderLabel`
    }
    
    /// 监听程序化修改 text 属性的动作
    override open var text: String? {
        didSet {
            // 延迟到布局/绘制阶段更新，避免控件尚未安装图层时触发动画。
            invalidateInputLayout()
            notifyActivityIfNeeded()
        }
    }

    // English: Keep programmatic attributed text changes on the same safe invalidation path.
    // Español: Mantiene los cambios programáticos de texto enriquecido en el mismo flujo seguro de invalidación.
    // 中文：让程序化富文本变化也进入同一条安全的布局刷新路径。
    override open var attributedText: NSAttributedString? {
        didSet {
            invalidateInputLayout()
            notifyActivityIfNeeded()
        }
    }
    
    // MARK: - 生命周期与编辑事件
    
    /// 当视图被添加到父视图或从父视图移除时调用
    override open func willMove(toSuperview newSuperview: UIView!) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            installEditingTargetsIfNeeded()
        } else {
            removeEditingTargets()
        }
    }

    // English: UIControl targets are owned by this field and can be removed exactly without touching external observers.
    // Español: Los objetivos de UIControl pertenecen a este campo y se eliminan exactamente sin tocar observadores externos.
    // 中文：编辑事件改用控件自身的 target 管理，移除时不会误删外部观察者。
    private func installEditingTargetsIfNeeded() {
        guard !isEditingTargetsInstalled else { return }
        addTarget(self, action: #selector(handleEditingDidBegin), for: .editingDidBegin)
        addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEnd)
        addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
        isEditingTargetsInstalled = true
    }

    // English: Removing only the three owned targets keeps reuse and repeated superview moves idempotent.
    // Español: Elimina solo los tres objetivos propios para que la reutilización y los movimientos sean idempotentes.
    // 中文：只移除这三个自有 target，保证复用和重复进出父视图都是幂等的。
    private func removeEditingTargets() {
        guard isEditingTargetsInstalled else { return }
        removeTarget(self, action: #selector(handleEditingDidBegin), for: .editingDidBegin)
        removeTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEnd)
        removeTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
        isEditingTargetsInstalled = false
    }

    @objc private func handleEditingDidBegin(_ sender: UITextField) {
        textFieldDidBeginEditing()
    }

    @objc private func handleEditingDidEnd(_ sender: UITextField) {
        textFieldDidEndEditing()
    }

    @objc private func handleEditingChanged(_ sender: UITextField) {
        notifyActivityIfNeeded()
    }
    
    /// 触发条件：输入框开始编辑（获得焦点）
    @objc open func textFieldDidBeginEditing() {
        notifyActivityIfNeeded()
        animateViewsForTextEntry()
    }
    
    /// 触发条件：输入框结束编辑（失去焦点）
    @objc open func textFieldDidEndEditing() {
        notifyActivityIfNeeded()
        animateViewsForTextDisplay()
    }

    private func notifyActivityIfNeeded() {
        let currentActivity = isActive
        guard currentActivity != lastReportedActivity else { return }
        lastReportedActivity = currentActivity
        activityChangeHandler?(currentActivity)
    }
    
    // MARK: - Interface Builder 支持
    
    /// 让自定义视图可以在 Xcode 的 Storyboard / XIB 中实时预览渲染结果
    override open func prepareForInterfaceBuilder() {
        // English: Interface Builder may invoke this hook outside the main-actor context.
        // Español: Interface Builder puede invocar este método fuera del contexto del actor principal.
        // 中文：Interface Builder 可能在非主 actor 上下文调用此方法。
        Task { @MainActor [weak self] in
            self?.setNeedsLayout()
            self?.setNeedsDisplay()
        }
    }

    private var isEditingTargetsInstalled = false
    private var lastReportedActivity: Bool?
    private var renderedBounds = CGRect.null

    deinit {
        // English: UIKit releases control-event targets with the text field.
        // Español: UIKit libera los objetivos de eventos junto con el campo de texto.
        // 中文：UIKit 会随文本框一起释放控件事件 target。
    }
}
