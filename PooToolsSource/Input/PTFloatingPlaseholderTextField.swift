//
//  PTFloatingPlaseholderTextField.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import Foundation
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif
#if SWIFT_PACKAGE
import ptools
#endif

public class PTFloatingPlaseholderConfig: NSObject {
    public var containerRadius: CGFloat = 0
    public var borderLayerColor: UIColor = .clear
    public var borderLayerFloatingColor: UIColor = .systemBlue
    public var borderLayerWidth: CGFloat = 1
    public var floatingPlaceholderColor: UIColor = .systemBlue
    public var normalPlaceholderColor: UIColor = .gray
    public var floatingPlaceholderFont: UIFont = .systemFont(ofSize: 12)
    public var normalPlaceholderFont: UIFont = .systemFont(ofSize: 16)
    public var textFont: UIFont = .systemFont(ofSize: 16)
    public var tinColor: UIColor = .systemBlue // 建议拼写修改为 tintColor
    public var clearMode: UITextField.ViewMode = .whileEditing
    public var textColor: UIColor = .black
    public var keyboardType: UIKeyboardType = .default
    public var isSecureTextEntry: Bool = false
    public var isMust: Bool = false
    
    public var insidePadding: CGFloat = 12
    public var placeholderPaddingOffset: CGFloat = 4
    public var placeholderWidthOffset: CGFloat = 8
    /// placeholder 上浮时距离 superview top 的偏移
    public var placeholderFloatingTopOffset: CGFloat = -8
    public var haveAction: Bool = false
    public var actionSize: CGSize = .zero
    public var actionNormal: Any?
    public var actionSelected: Any?
    public var actionSapcing: CGFloat = 8 // 建议拼写修改为 actionSpacing
    public var textAlignment: NSTextAlignment = .left    
}

// English: Describe the three stable interaction states of the composite field.
// Español: Describe los tres estados estables de interacción del campo compuesto.
// 中文：描述复合输入框的三种稳定交互状态。
public enum PTFloatingInputState: String, Sendable, Equatable {
    case idleEmpty
    case editing
    case idleWithText
}

@MainActor
public class PTFloatingPlaseholderTextField: UIView {

    // 【优化】避免使用 !，直接赋初始值，防止 init(coder:) 时崩溃
    private var viewConfig: PTFloatingPlaseholderConfig = PTFloatingPlaseholderConfig()
    private var placeholderString: String = ""
    
    // 【优化】记录上一次的 bounds，避免 layoutSubviews 中频繁且无效的重绘
    private var lastBounds: CGRect = .zero
    
    // 【优化】缓存富文本，避免每次动画都重新生成字符串（提升性能）
    private var cachedNormalAttString: PTRichText?
    private var cachedFloatingAttString: PTRichText?
    private var didSetupUI = false

    // English: Bridge the shared appearance into the composite field and its floating label.
    // Español: Conecta la apariencia compartida con el campo compuesto y su etiqueta flotante.
    // 中文：把统一外观配置桥接到复合输入框及其浮动标签。
    public var inputAppearance = PTInputAppearance() {
        didSet { applyInputAppearance() }
    }

    public var textAndPlaceholderSpace: CGFloat {
        get { inputAppearance.textAndPlaceholderSpace }
        set {
            var appearance = inputAppearance
            appearance.textAndPlaceholderSpace = max(0, newValue)
            inputAppearance = appearance
        }
    }

    @available(*, deprecated, message: "Use textAndPlaceholderSpace instead")
    public var textAndPlceholderSpace: CGFloat {
        get { textAndPlaceholderSpace }
        set { textAndPlaceholderSpace = newValue }
    }

    public var leadingSpace: CGFloat {
        get { inputAppearance.leadingSpace }
        set {
            var appearance = inputAppearance
            appearance.leadingSpace = max(0, newValue)
            inputAppearance = appearance
        }
    }
    
    public var inputedCallback: ((String) -> Void)?
    public var inputBegainCallback: PTActionTask?
    public var inputingCallback: ((String) -> Void)?
    public var actionTouchBlock: TouchedBlock?

    // English: Report the composite field's active state without exposing UIKit event wiring.
    // Español: Informa del estado activo del campo compuesto sin exponer el cableado de eventos de UIKit.
    // 中文：对外报告复合输入框的激活状态，不要求调用方自行监听 UIKit 事件。
    public typealias ActivityChangeHandler = @MainActor @Sendable (_ isActive: Bool) -> Void

    // English: Report the explicit idle/editing state so form owners can react without inspecting UIKit.
    // Español: Informa del estado idle/edición para que el formulario reaccione sin inspeccionar UIKit.
    // 中文：提供明确的空闲/编辑状态，让表单无需检查 UIKit 就能响应。
    public typealias StateChangeHandler = @MainActor @Sendable (_ state: PTFloatingInputState) -> Void

    // English: Report intrinsic-height changes after placeholder or text layout settles.
    // Español: Informa de los cambios de altura intrínseca después de estabilizar el layout del placeholder o texto.
    // 中文：在占位符或文本布局稳定后报告内容高度变化。
    public typealias HeightChangeHandler = @MainActor @Sendable (_ height: CGFloat) -> Void

    public var activityChangeHandler: ActivityChangeHandler? {
        didSet {
            lastReportedActivity = nil
            notifyActivityIfNeeded()
        }
    }

    public var stateChangeHandler: StateChangeHandler? {
        didSet {
            lastReportedInputState = nil
            notifyInputStateIfNeeded()
        }
    }

    public var heightChangeHandler: HeightChangeHandler? {
        didSet {
            lastReportedHeight = .nan
            notifyHeightIfNeeded()
        }
    }

    public var minimumHeight: CGFloat = 44 {
        didSet {
            minimumHeight = max(1, minimumHeight)
            invalidateIntrinsicContentSize()
            notifyHeightIfNeeded()
        }
    }

    public var isActive: Bool {
        textField.isFirstResponder || !(textField.text?.isEmpty ?? true)
    }

    public var inputState: PTFloatingInputState {
        if textField.isFirstResponder {
            return .editing
        }
        return (textField.text?.isEmpty ?? true) ? .idleEmpty : .idleWithText
    }

    private var lastReportedActivity: Bool?
    private var lastReportedInputState: PTFloatingInputState?
    private var lastReportedHeight: CGFloat = .nan

    public lazy var textField: UITextField = {
        let view = UITextField()
        view.borderStyle = .none
        view.tintColor = self.viewConfig.tinColor
        view.font = self.viewConfig.textFont
        view.clearButtonMode = self.viewConfig.clearMode
        view.textColor = self.viewConfig.textColor
        view.keyboardType = self.viewConfig.keyboardType
        view.isSecureTextEntry = self.viewConfig.isSecureTextEntry
        view.delegate = self
        return view
    }()
    
    public lazy var placeholderLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    public lazy var actionButton: UIButton = {
        let view = UIButton(type: .custom)
        if let normal = viewConfig.actionNormal {
            view.loadImage(contentData: normal, controlState: .normal)
        }
        if let selected = viewConfig.actionSelected {
            view.loadImage(contentData: selected, controlState: .selected)
        }
        view.isHidden = !viewConfig.haveAction
        // 【重要修复】添加 [weak self] 防止闭包引起的强引用循环
        view.addActionHandlers(handler: { [weak self] sender in
            self?.actionTouchBlock?(sender)
        })
        return view
    }()

    // English: Update the optional trailing action images without rebuilding the field.
    // Español: Actualiza las imágenes opcionales de la acción final sin reconstruir el campo.
    // 中文：不重建输入框，直接更新可选的尾部操作图片。
    public func updateActionImages(normal: Any?, selected: Any?) {
        viewConfig.actionNormal = normal
        viewConfig.actionSelected = selected
        actionButton.setImage(nil, for: .normal)
        actionButton.setImage(nil, for: .selected)

        if let normal {
            actionButton.loadImage(contentData: normal, controlState: .normal)
        }
        if let selected {
            actionButton.loadImage(contentData: selected, controlState: .selected)
        }
    }

    // English: Toggle the trailing action while keeping all content constraints valid.
    // Español: Activa o desactiva la acción final manteniendo válidas todas las restricciones del contenido.
    // 中文：切换尾部操作显示状态，并同步重建内容约束，避免约束仍指向旧布局。
    public func setActionVisible(_ visible: Bool) {
        guard viewConfig.haveAction != visible else {
            actionButton.isHidden = !visible
            return
        }

        viewConfig.haveAction = visible
        actionButton.isHidden = !visible
        remakeContentConstraints()
        invalidateIntrinsicContentSize()
        updateBorderPath()
        notifyHeightIfNeeded()
    }
    
    private let borderLayer = CAShapeLayer()

    /// true = placeholder 上浮（左上角）
    private var isFloating = false
        
    public init(config: PTFloatingPlaseholderConfig = PTFloatingPlaseholderConfig()) {
        self.viewConfig = config
        super.init(frame: .zero)
        setupUI()
        setupTraitObservation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupTraitObservation()
    }

    private func setupTraitObservation() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: PTFloatingPlaseholderTextField, previousTraitCollection: UITraitCollection) in
            // 只有当深浅色真正发生切换时，才会触发这个闭包
            view.updateBorderPath() // 因为 CGColor 不会自动随系统模式刷新，需要手动重绘
        }
    }

    private func setupUI() {
        layer.cornerRadius = viewConfig.containerRadius
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = viewConfig.borderLayerWidth
        layer.addSublayer(borderLayer)
        
        addSubviews([actionButton, placeholderLabel, textField])

        actionButton.snp.makeConstraints { make in
            make.size.equalTo(self.viewConfig.actionSize)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(self.viewConfig.insidePadding)
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(self.viewConfig.insidePadding + self.viewConfig.placeholderPaddingOffset)
            if self.viewConfig.haveAction {
                make.right.equalTo(self.actionButton.snp.left).offset(-self.viewConfig.actionSapcing)
            } else {
                make.right.equalToSuperview().inset(self.viewConfig.insidePadding)
            }
            make.centerY.equalToSuperview()
        }

        textField.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(self.viewConfig.insidePadding)
            if self.viewConfig.haveAction {
                make.right.equalTo(self.actionButton.snp.left).offset(-self.viewConfig.actionSapcing)
            } else {
                make.right.equalToSuperview().inset(self.viewConfig.insidePadding)
            }
            make.top.bottom.equalToSuperview().inset(self.viewConfig.floatingPlaceholderFont.pointSize / 2)
        }

        textField.addTarget(self, action: #selector(beginEdit), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(endEdit), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        
        // 初始调用一次绘制
        updateBorderPath()
        didSetupUI = true
        applyInputAppearance()
    }

    // English: Update only installed constraints so repeated configuration stays idempotent.
    // Español: Actualiza solo las restricciones instaladas para que la configuración repetida sea idempotente.
    // 中文：只更新已经安装的约束，让重复配置保持幂等。
    private func applyInputAppearance() {
        guard didSetupUI else { return }

        if let color = inputAppearance.placeholderColorOverride {
            viewConfig.normalPlaceholderColor = color
            viewConfig.floatingPlaceholderColor = color
        }
        if let font = inputAppearance.placeholderFontOverride {
            viewConfig.normalPlaceholderFont = font
            viewConfig.floatingPlaceholderFont = font
            textField.font = font
        }

        placeholderLabel.attributedText = nil
        setFloating(isFloating || !(textField.text ?? "").isEmpty, animated: false)
        updateInputConstraints()
        placeholderLabel.attributedText = resolvedPlaceholder(isNormal: !isFloating)?.value
        placeholderLabel.invalidateIntrinsicContentSize()
        invalidateIntrinsicContentSize()
        updateBorderPath()
        notifyActivityIfNeeded()
        notifyHeightIfNeeded()
    }

    private func updateInputConstraints() {
        let leading = max(0, inputAppearance.leadingSpace)
        let edges = inputAppearance.textEditingEdges
        let leftInset = max(0, viewConfig.insidePadding + leading + edges.left)
        let rightInset = max(0, viewConfig.insidePadding + edges.right)
        let topInset = max(0, viewConfig.floatingPlaceholderFont.pointSize / 2 + edges.top)
        let bottomInset = max(0, viewConfig.floatingPlaceholderFont.pointSize / 2 + edges.bottom)

        placeholderLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(leftInset + viewConfig.placeholderPaddingOffset)
            if !viewConfig.haveAction {
                make.right.equalToSuperview().inset(rightInset)
            }
        }
        textField.snp.updateConstraints { make in
            make.left.equalToSuperview().inset(leftInset)
            if !viewConfig.haveAction {
                make.right.equalToSuperview().inset(rightInset)
            }
            make.top.equalToSuperview().inset(topInset)
            make.bottom.equalToSuperview().inset(bottomInset)
        }
    }

    // English: Rebuild only the two content constraints that change when the action appears.
    // Español: Reconstruye solo las restricciones de contenido que cambian al mostrar la acción.
    // 中文：只重建尾部操作出现或隐藏时会变化的两组内容约束。
    private func remakeContentConstraints() {
        let leading = max(0, inputAppearance.leadingSpace)
        let edges = inputAppearance.textEditingEdges
        let leftInset = max(0, viewConfig.insidePadding + leading + edges.left)
        let rightInset = max(0, viewConfig.insidePadding + edges.right)
        let topInset = max(0, viewConfig.floatingPlaceholderFont.pointSize / 2 + edges.top)
        let bottomInset = max(0, viewConfig.floatingPlaceholderFont.pointSize / 2 + edges.bottom)

        placeholderLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(leftInset + viewConfig.placeholderPaddingOffset)
            if viewConfig.haveAction {
                make.right.equalTo(actionButton.snp.left).offset(-viewConfig.actionSapcing)
            } else {
                make.right.equalToSuperview().inset(rightInset)
            }
            if isFloating {
                make.top.equalToSuperview().offset(viewConfig.placeholderFloatingTopOffset)
            } else {
                make.centerY.equalToSuperview()
            }
        }

        textField.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(leftInset)
            if viewConfig.haveAction {
                make.right.equalTo(actionButton.snp.left).offset(-viewConfig.actionSapcing)
            } else {
                make.right.equalToSuperview().inset(rightInset)
            }
            make.top.equalToSuperview().inset(topInset)
            make.bottom.equalToSuperview().inset(bottomInset)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 【优化】只在尺寸真正改变时才重新计算边框路径，降低 CPU 消耗
        if bounds != lastBounds {
            lastBounds = bounds
            updateBorderPath()
        }
        notifyHeightIfNeeded()
    }

    // English: Measure the actual rich placeholder instead of guessing from one font line.
    // Español: Mide el placeholder enriquecido real en vez de estimarlo con una sola línea de fuente.
    // 中文：使用富文本占位符的实际测量高度，而不是只按单行字体高度估算。
    private func measuredPlaceholderHeight(for width: CGFloat) -> CGFloat {
        let safeWidth = max(1, width)
        guard let attributedText = placeholderLabel.attributedText,
              attributedText.length > 0 else {
            return max(viewConfig.normalPlaceholderFont.lineHeight,
                       viewConfig.floatingPlaceholderFont.lineHeight)
        }

        let rect = attributedText.boundingRect(with: CGSize(width: safeWidth,
                                                            height: .greatestFiniteMagnitude),
                                               options: [.usesLineFragmentOrigin, .usesFontLeading],
                                               context: nil)
        let measuredHeight = rect.height.isFinite ? rect.height : 0
        return max(1, ceil(measuredHeight))
    }

    // English: Keep the height calculation local to this view so the external constraint owner stays in control.
    // Español: Mantiene el cálculo de altura dentro de esta vista para que el propietario externo de las restricciones conserve el control.
    // 中文：高度计算只在控件内部完成，外部约束的所有权仍归调用方。
    private func calculatedIntrinsicHeight(for width: CGFloat) -> CGFloat {
        let edges = inputAppearance.textEditingEdges
        let horizontalInset = viewConfig.insidePadding
            + max(0, inputAppearance.leadingSpace)
            + max(0, edges.left)
            + max(0, edges.right)
        let actionInset = viewConfig.haveAction
            ? max(0, viewConfig.actionSize.width + viewConfig.actionSapcing)
            : 0
        let availableWidth = max(1, width - horizontalInset - actionInset)
        let labelHeight = measuredPlaceholderHeight(for: availableWidth)
        let textHeight = max(textField.font?.lineHeight ?? viewConfig.textFont.lineHeight,
                             viewConfig.normalPlaceholderFont.lineHeight)
        let textVerticalInsets = max(0, viewConfig.floatingPlaceholderFont.pointSize)
            + max(0, edges.top)
            + max(0, edges.bottom)

        let contentHeight: CGFloat
        if isFloating {
            let topAllowance = max(0, -viewConfig.placeholderFloatingTopOffset)
            contentHeight = topAllowance
                + labelHeight
                + max(0, inputAppearance.textAndPlaceholderSpace)
                + textHeight
                + textVerticalInsets
        } else {
            contentHeight = max(labelHeight, textHeight) + textVerticalInsets
        }

        return max(max(1, minimumHeight), ceil(contentHeight))
    }

    public override var intrinsicContentSize: CGSize {
        let width = bounds.width > 0 ? bounds.width : 240
        return CGSize(width: UIView.noIntrinsicMetric,
                      height: calculatedIntrinsicHeight(for: width))
    }

    private func notifyActivityIfNeeded() {
        let currentActivity = isActive
        if lastReportedActivity != currentActivity {
            lastReportedActivity = currentActivity
            activityChangeHandler?(currentActivity)
        }
        notifyInputStateIfNeeded()
    }

    private func notifyInputStateIfNeeded() {
        let currentState = inputState
        guard lastReportedInputState != currentState else { return }
        lastReportedInputState = currentState
        stateChangeHandler?(currentState)
    }

    private func notifyHeightIfNeeded() {
        guard heightChangeHandler != nil else { return }
        let width = bounds.width > 0 ? bounds.width : 240
        let height = calculatedIntrinsicHeight(for: width)
        guard height.isFinite,
              height <= CGFloat.greatestFiniteMagnitude,
              !lastReportedHeight.isFinite || abs(lastReportedHeight - height) > 0.5 else { return }
        lastReportedHeight = height
        heightChangeHandler?(height)
    }
    
    private func getPlaceholderAtt(mainString: String, isNormal: Bool) -> PTRichText {
        let plaseHolderFont = inputAppearance.placeholderFontOverride
            ?? (isNormal ? viewConfig.normalPlaceholderFont : viewConfig.floatingPlaceholderFont)
        let plaseHolderColor = inputAppearance.placeholderColorOverride
            ?? (isNormal ? viewConfig.normalPlaceholderColor : viewConfig.floatingPlaceholderColor)
        var placeholderAtt: PTRichText = """
                    \(wrap: .embedding("""
                    \(mainString,.foreground(plaseHolderColor),.font(plaseHolderFont),.paragraph(.alignment(viewConfig.textAlignment)))
                    """))
                    """
        if viewConfig.isMust {
            let placeholderLastAtt: PTRichText = """
                        \(wrap: .embedding("""
                        \(" *",.foreground(.systemRed),.font(plaseHolderFont),.paragraph(.alignment(viewConfig.textAlignment)))
                        """))
                        """
            placeholderAtt += placeholderLastAtt
        }
        return placeholderAtt
    }
    
    public func configure(placeholder: String, text: String? = nil) {
        self.placeholderString = placeholder
        
        // 生成并缓存两种状态下的富文本
        self.cachedNormalAttString = getPlaceholderAtt(mainString: placeholder, isNormal: true)
        self.cachedFloatingAttString = getPlaceholderAtt(mainString: placeholder, isNormal: false)
        
        placeholderLabel.attributedText = resolvedPlaceholder(isNormal: true)?.value
        textField.text = text

        let textIsNotEmpty = !(text ?? "").stringIsEmpty()
        setFloating(textIsNotEmpty, animated: false)
        invalidateIntrinsicContentSize()
        notifyActivityIfNeeded()
        notifyHeightIfNeeded()
    }

    // MARK: - Events
    @objc private func beginEdit() {
        setFloating(true, animated: true)
        notifyActivityIfNeeded()
        invalidateIntrinsicContentSize()
        notifyHeightIfNeeded()
    }

    @objc private func endEdit() {
        let textIsNotEmpty = !(textField.text ?? "").stringIsEmpty()
        setFloating(textIsNotEmpty, animated: true)
        notifyActivityIfNeeded()
        invalidateIntrinsicContentSize()
        notifyHeightIfNeeded()
    }

    @objc private func textChanged() {
        let textIsNotEmpty = !(textField.text ?? "").stringIsEmpty()
        setFloating(textIsNotEmpty, animated: true)
        notifyActivityIfNeeded()
        invalidateIntrinsicContentSize()
        notifyHeightIfNeeded()
    }

    // MARK: - Floating
    private func setFloating(_ float: Bool, animated: Bool) {
        // 如果状态没有变化，直接返回，避免多余动画
        if isFloating == float && placeholderLabel.attributedText != nil { return }
        isFloating = float

        placeholderLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(self.viewConfig.insidePadding + self.inputAppearance.leadingSpace + self.viewConfig.placeholderPaddingOffset)
            if self.viewConfig.haveAction {
                make.right.equalTo(self.actionButton.snp.left).offset(-self.viewConfig.actionSapcing)
            } else {
                make.right.equalToSuperview().inset(self.viewConfig.insidePadding)
            }
            if float {
                make.top.equalToSuperview().offset(self.viewConfig.placeholderFloatingTopOffset)
            } else {
                make.centerY.equalToSuperview()
            }
        }

        let animations = {
            // 【优化】直接使用预先缓存的字符串，不用重复计算
            self.placeholderLabel.attributedText = self.resolvedPlaceholder(isNormal: !float)?.value
            self.layoutIfNeeded()
            self.updateBorderPath()
            self.invalidateIntrinsicContentSize()
            self.notifyHeightIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: animations, completion: nil)
        } else {
            animations()
        }
    }

    // English: Prefer the caller's rich placeholder and keep generated state-specific fallbacks.
    // Español: Prefiere el marcador enriquecido del llamador y conserva los reemplazos por estado.
    // 中文：优先使用调用方富文本占位符，同时保留按状态生成的回退内容。
    private func resolvedPlaceholder(isNormal: Bool) -> PTRichText? {
        inputAppearance.placeholderAtt ?? (isNormal ? cachedNormalAttString : cachedFloatingAttString)
    }

    // MARK: - Border Path
    private func updateBorderPath() {
        let rect = bounds
        guard rect.width > 0 && rect.height > 0 else { return }

        let radius: CGFloat = viewConfig.containerRadius
        let labelWidth = placeholderLabel.intrinsicContentSize.width + viewConfig.placeholderWidthOffset
        let gapStartX = viewConfig.insidePadding + max(0, inputAppearance.leadingSpace)
        let gapEndX = gapStartX + labelWidth

        let path = UIBezierPath()
        path.move(to: CGPoint(x: radius, y: 0))

        if isFloating {
            borderLayer.strokeColor = viewConfig.borderLayerFloatingColor.cgColor
            path.addLine(to: CGPoint(x: gapStartX, y: 0))
            path.move(to: CGPoint(x: gapEndX, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        } else {
            borderLayer.strokeColor = viewConfig.borderLayerColor.cgColor
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        }

        path.addArc(withCenter: CGPoint(x: rect.width - radius, y: radius), radius: radius, startAngle: CGFloat(-Double.pi/2), endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
        path.addArc(withCenter: CGPoint(x: rect.width - radius, y: rect.height - radius), radius: radius, startAngle: 0, endAngle: CGFloat(Double.pi/2), clockwise: true)
        path.addLine(to: CGPoint(x: radius, y: rect.height))
        path.addArc(withCenter: CGPoint(x: radius, y: rect.height - radius), radius: radius, startAngle: CGFloat(Double.pi/2), endAngle: CGFloat(Double.pi), clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: CGFloat.pi, endAngle: CGFloat(3 * Double.pi / 2), clockwise: true)

        borderLayer.path = path.cgPath
    }
}

extension PTFloatingPlaseholderTextField: UITextFieldDelegate {
    
    // 【重要修复】修正了获取 UITextField 即将改变后的文本逻辑
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text,
           let textRange = Range(range, in: text) {
            // 正确替换范围内的字符，能够正确处理插入光标或删除(Backspace)字符的场景
            let newText = text.replacingCharacters(in: textRange, with: string)
            inputingCallback?(newText)
        }
        return true
    }

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        inputBegainCallback?()
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        inputedCallback?(textField.text ?? "")
    }
    
    // MARK: - 响应者链
    // MARK: - Cadena de respuesta
    // MARK: - Responder chain

    /// 1. 确保将外层视图的 第一响应者 状态，同步委托给内部真正的 textField
    public override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    @discardableResult
    public override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
}
