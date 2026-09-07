//
//  PTCustomerAlertViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

public typealias PTCustomerCustomerBlock = (_ alertCustomerView:UIView) -> Void

@objc public enum PTAlertAnimationType:Int {
    case Top
    case Bottom
    case Left
    case Right
    case Normal
}

@objcMembers
public class PTCustomBottomButtonModel: NSObject {
    public var titleName:String? = ""
    public var titleColor:UIColor? = UIColor.systemBlue
}

public class PTCustomerAlertController: PTAlertController {

    // English: Use one active scroll region at a time so adaptive layouts remain easy to reason about.
    // Español: Usa una sola región de desplazamiento activa para que los diseños adaptativos sean fáciles de mantener.
    // 中文：同一时间只启用一个滚动区域，保证自适应布局逻辑清晰且不产生嵌套滚动冲突。
    private enum ActionLayoutMode: Equatable {
        case fitted
        case scrollingActions
        case scrollingAll
    }

    // English: Keep compact actions horizontal only when their labels fit; otherwise use a readable vertical stack.
    // Español: Mantén las acciones compactas en horizontal solo cuando sus etiquetas quepan; si no, usa una pila vertical legible.
    // 中文：仅在按钮标题能够容纳时使用横向紧凑布局，否则切换为更易读的纵向布局。
    private enum CompactActionLayout: Equatable {
        case horizontal
        case vertical
    }

    // English: Cache only geometry inputs so repeated layout passes do not recreate constraints or controls.
    // Español: Guarda solo las entradas geométricas para que los pases de diseño repetidos no reconstruyan restricciones ni controles.
    // 中文：只缓存几何输入，避免重复布局时重新创建约束和控件。
    private struct AlertLayoutSignature: Equatable {
        let width: CGFloat
        let safeHeight: CGFloat
        let titleHeight: CGFloat
        let customerViewHeight: CGFloat
        let buttonCount: Int
        let rowHeight: CGFloat
        let compactLayout: CompactActionLayout
    }

    public var bottomButtonTapCallback:((_ title:String,_ index:Int) -> Void)? = nil
    public var backgroundTapCallback:((PTCustomerAlertController) -> Void)? = nil

    // English: Limit the alert surface like a system alert while preserving a safe fallback for invalid input.
    // Español: Limita la superficie de la alerta como una alerta del sistema y conserva un respaldo seguro para entradas no válidas.
    // 中文：将弹窗表面限制在接近系统弹窗的宽度，并为非法输入保留安全兜底。
    public var maximumContentWidth: CGFloat = 340 {
        didSet {
            if !maximumContentWidth.isFinite || maximumContentWidth <= 0 {
                maximumContentWidth = Self.defaultMaximumContentWidth
            }
            layoutSignature = nil
            viewIfLoaded?.setNeedsLayout()
        }
    }

    public var contentBackgroundColor: UIColor? {
        didSet {
            updateContentBackgroundIfLoaded()
        }
    }

    static let defaultMaximumContentWidth: CGFloat = 340

    // English: Use one width calculation for the controller and legacy convenience wrappers.
    // Español: Usa un único cálculo de ancho para el controlador y los wrappers de conveniencia heredados.
    // 中文：控制器和旧版便捷包装器统一使用同一个宽度计算方法。
    static func resolvedContentWidth(containerWidth: CGFloat,
                                     contentSpace: CGFloat,
                                     maximumWidth: CGFloat = defaultMaximumContentWidth) -> CGFloat {
        let safeContainerWidth = containerWidth.isFinite ? max(1, containerWidth) : 1
        let safeContentSpace = contentSpace.isFinite ? max(0, contentSpace) : 25
        let safeMaximumWidth = maximumWidth.isFinite && maximumWidth > 0
            ? maximumWidth
            : defaultMaximumContentWidth
        let widthWithMargins = max(1, safeContainerWidth - safeContentSpace * 2)
        return max(1, min(widthWithMargins, safeMaximumWidth))
    }

    // English: Leave the surface transparent while material is active and use an opaque dynamic fallback when transparency is reduced.
    // Español: Deja la superficie transparente mientras el material está activo y usa un respaldo dinámico opaco cuando se reduce la transparencia.
    // 中文：启用系统材质时保持表面透明；用户开启减弱透明度后，切换为不透明的动态系统背景。
    private var resolvedContentBackgroundColor: UIColor {
        if let contentBackgroundColor {
            return contentBackgroundColor
        }
        return UIAccessibility.isReduceTransparencyEnabled ? .secondarySystemBackground : .clear
    }

    fileprivate lazy var contentView:UIView = {
        let view = UIView()
        view.backgroundColor = resolvedContentBackgroundColor
        view.alpha = 0.0
        view.layer.cornerRadius = cornerSize
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()
    
    @PTClampedPropertyWrapper(range:0...15) fileprivate var cornerSize:CGFloat = 15
    
    fileprivate lazy var titleMessage:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.font = titleFont
        view.textColor = titleColor
        view.text = alertTitle
        view.adjustsFontForContentSizeCategory = true
        view.accessibilityTraits = .header
        return view
    }()
    
    fileprivate let alertTitle: String
    fileprivate let titleFont: UIFont
    fileprivate let titleColor: UIColor
    
    fileprivate lazy var customView:UIView = {
        let view = UIView()
        return view
    }()
    
    fileprivate let buttons: [String]
    fileprivate let buttonsColors: [UIColor]
    fileprivate var buttonModels = [PTCustomBottomButtonModel]()
    fileprivate var buttonsFont:UIFont = .appfont(size: 15)

    fileprivate var titleHeight:CGFloat = 0
    @PTClampedPropertyWrapper(range:25...100) fileprivate var contentSpace:CGFloat = 25
    let titleSpace:CGFloat = 10
    fileprivate var contentWidth: CGFloat = 0
    
    fileprivate var customerViewCallback:PTCustomerCustomerBlock? = nil
    fileprivate var customerViewHeight:CGFloat = 100
    // English: Keep one effect view for the whole surface so the blur or glass material is created only once.
    // Español: Mantén una sola vista de efecto para toda la superficie y crea el material de desenfoque o vidrio una sola vez.
    // 中文：整个弹窗只使用一个效果视图，避免为各个区域重复创建磨砂或玻璃材质。
    private lazy var surfaceEffectView: UIVisualEffectView = {
        let view = UIVisualEffectView(frame: .zero)
        view.isUserInteractionEnabled = true
        view.isAccessibilityElement = false
        return view
    }()
    private var traitChangeRegistration: (any UITraitChangeRegistration)?
    fileprivate var canTapBackground:Bool = false

    private let bodyScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = false
        return view
    }()

    private let bodyContentView = UIView()

    private let actionScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.showsVerticalScrollIndicator = true
        view.alwaysBounceVertical = false
        return view
    }()

    private let actionStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        view.spacing = 0
        return view
    }()

    private let compactActionView = UIView()
    private let compactActionStackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 0
        return view
    }()
    private let compactTopSeparatorView = UIView()
    private let compactDividerView = UIView()
    private var actionButtons = [UIButton]()
    private var actionButtonHeightConstraints = [Constraint]()
    private var actionSeparatorViews = [UIView]()
    private var compactHorizontalDividerConstraints = [Constraint]()
    private var compactVerticalDividerConstraints = [Constraint]()
    private var contentWidthConstraint: Constraint?
    private var contentHeightConstraint: Constraint?
    private var titleHeightConstraint: Constraint?
    private var customerViewHeightConstraint: Constraint?
    private var compactActionHeightConstraint: Constraint?
    private var actionViewportHeightConstraint: Constraint?
    private var layoutSignature: AlertLayoutSignature?
    private var actionLayoutMode: ActionLayoutMode = .fitted
    private var compactActionLayout: CompactActionLayout = .horizontal
    private var isHandlingAction = false

    private let minimumButtonRowHeight: CGFloat = 44
    private let separatorThickness: CGFloat = 1 / UIScreen.main.scale
    private let minimumAlertVerticalMargin: CGFloat = 16
    
    public init(title:String = "",
                titleFont:UIFont = .appfont(size: 15),
                titleColor:UIColor = .systemBlue,
                customerViewHeight:CGFloat = 100,
                customerViewCallback:PTCustomerCustomerBlock? = nil,
                buttons:[String],
                buttonsColors:[UIColor],
                buttonsFont:UIFont = .appfont(size: 15),
                cornerSize: CGFloat = 15,
                contentSpace:CGFloat = 25,
                canTapBackground:Bool = false) {
        self.alertTitle = title
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.buttons = buttons
        self.buttonsColors = buttonsColors
        self.buttonsFont = buttonsFont
        self.cornerSize = cornerSize
        self.contentSpace = contentSpace
        self.customerViewHeight = max(0, customerViewHeight)
        self.customerViewCallback = customerViewCallback
        self.canTapBackground = canTapBackground
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        contentWidth = Self.resolvedContentWidth(containerWidth: view.bounds.width,
                                                  contentSpace: contentSpace,
                                                  maximumWidth: maximumContentWidth)
        let haveTitle = !alertTitle.isEmpty
        titleHeight = haveTitle ? resolvedTitleHeight(for: contentWidth) : 0
        
        buttonModels = buttons.enumerated().map { index, title in
            let model = PTCustomBottomButtonModel()
            model.titleName = title
            model.titleColor = (index < buttonsColors.count) ? buttonsColors[index] : .systemBlue
            return model
        }
        
        view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00)

        view.addSubview(contentView)
        contentView.backgroundColor = resolvedContentBackgroundColor
        contentView.snp.makeConstraints { make in
            make.centerX.equalTo(view.safeAreaLayoutGuide.snp.centerX)
            make.centerY.equalTo(view.safeAreaLayoutGuide.snp.centerY)
            contentWidthConstraint = make.width.equalTo(contentWidth).constraint
            contentHeightConstraint = make.height.equalTo(1).constraint
        }

        contentView.addSubview(surfaceEffectView)
        surfaceEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        installSurfaceAppearanceObservers()
        updateSurfaceAppearance()
        
        if canTapBackground {
            let tap = UITapGestureRecognizer { _ in
                PTGCDManager.shared.runOnMain {
                    self.dismissSelf { [weak self = self] in
                        guard let self else { return }
                        PTGCDManager.shared.runOnMain {
                            self.backgroundTapCallback?(self)
                        }
                    }
                }
            }
            tap.cancelsTouchesInView = false
            tap.delegate = self
            view.addGestureRecognizer(tap)
        }

        configureContentHierarchy()
    }

    private func updateContentBackgroundIfLoaded() {
        guard isViewLoaded else { return }
        updateSurfaceAppearance()
    }

    // English: Reapply the surface when traits or accessibility settings change without rebuilding the alert hierarchy.
    // Español: Vuelve a aplicar la superficie cuando cambian los traits o la accesibilidad sin reconstruir la jerarquía de la alerta.
    // 中文：仅在 trait 或辅助功能设置变化时重新应用表面效果，不重建弹窗视图层级。
    private func updateSurfaceAppearance() {
        guard isViewLoaded else { return }

        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        contentView.backgroundColor = resolvedContentBackgroundColor

        guard contentBackgroundColor == nil, !reduceTransparency else {
            surfaceEffectView.effect = nil
            return
        }

        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .regular)
            glassEffect.isInteractive = false
            surfaceEffectView.effect = glassEffect
            return
        }
        #endif

        surfaceEffectView.effect = UIBlurEffect(style: .systemMaterial)
    }

    private func installSurfaceAppearanceObservers() {
        traitChangeRegistration = registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self
        ]) { [weak self] (_: PTCustomerAlertController, _: UITraitCollection) in
            self?.updateSurfaceAppearance()
            self?.layoutSignature = nil
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accessibilityAppearanceDidChange),
                                               name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accessibilityAppearanceDidChange),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }

    @objc private func accessibilityAppearanceDidChange() {
        updateSurfaceAppearance()
        layoutSignature = nil
        viewIfLoaded?.setNeedsLayout()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // English: Build the hierarchy once; later size changes only update constants and scroll modes.
    // Español: Construye la jerarquía una sola vez; los cambios de tamaño posteriores solo actualizan constantes y modos de desplazamiento.
    // 中文：只创建一次视图层级，后续尺寸变化仅更新约束常量和滚动模式。
    private func configureContentHierarchy() {
        // English: Put alert content inside the effect content view so system material stays behind the controls.
        // Español: Coloca el contenido de la alerta dentro de la vista de contenido del efecto para que el material quede detrás de los controles.
        // 中文：将弹窗内容放入效果视图的内容容器，确保系统材质位于控件下方。
        let surfaceContentView = surfaceEffectView.contentView
        surfaceContentView.addSubview(bodyScrollView)
        bodyScrollView.addSubview(bodyContentView)
        // English: Add every view before activating constraints so both anchors share the same hierarchy.
        // Español: Añade cada vista antes de activar las restricciones para que ambos anclajes compartan la misma jerarquía.
        // 中文：先将所有视图加入同一层级，再激活约束，确保约束两端拥有共同父视图。
        bodyContentView.addSubview(titleMessage)
        bodyContentView.addSubview(customView)

        bodyScrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        if buttons.count <= 2, !buttons.isEmpty {
            compactActionView.backgroundColor = .clear
            surfaceContentView.addSubview(compactActionView)
            compactActionView.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(bodyScrollView.snp.bottom)
            }

            compactTopSeparatorView.backgroundColor = .separator
            compactDividerView.backgroundColor = .separator
            compactActionView.addSubview(compactTopSeparatorView)
            compactActionView.addSubview(compactActionStackView)
            compactActionView.addSubview(compactDividerView)
            compactTopSeparatorView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(separatorThickness)
            }
            compactActionStackView.snp.makeConstraints { make in
                make.top.equalTo(compactTopSeparatorView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            compactActionView.snp.makeConstraints { make in
                compactActionHeightConstraint = make.height.equalTo(minimumButtonRowHeight + separatorThickness).constraint
            }
        } else {
            bodyScrollView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }

        bodyContentView.snp.makeConstraints { make in
            make.top.equalTo(bodyScrollView.contentLayoutGuide.snp.top)
            make.leading.equalTo(bodyScrollView.contentLayoutGuide.snp.leading)
            make.trailing.equalTo(bodyScrollView.contentLayoutGuide.snp.trailing)
            make.bottom.equalTo(bodyScrollView.contentLayoutGuide.snp.bottom)
            make.width.equalTo(bodyScrollView.frameLayoutGuide.snp.width)
        }
        titleMessage.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(titleSpace)
            titleHeightConstraint = make.height.equalTo(titleHeight).constraint
        }
        customView.snp.makeConstraints { make in
            make.top.equalTo(titleMessage.snp.bottom)
            make.leading.trailing.equalToSuperview()
            customerViewHeightConstraint = make.height.equalTo(customerViewHeight).constraint
        }

        if buttons.count > 2 {
            bodyContentView.addSubview(actionScrollView)
            actionScrollView.addSubview(actionStackView)

            actionScrollView.snp.makeConstraints { make in
                make.top.equalTo(customView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
                actionViewportHeightConstraint = make.height.equalTo(1).constraint
            }
            actionStackView.snp.makeConstraints { make in
                make.top.equalTo(actionScrollView.contentLayoutGuide.snp.top)
                make.leading.equalTo(actionScrollView.contentLayoutGuide.snp.leading)
                make.trailing.equalTo(actionScrollView.contentLayoutGuide.snp.trailing)
                make.bottom.equalTo(actionScrollView.contentLayoutGuide.snp.bottom)
                make.width.equalTo(actionScrollView.frameLayoutGuide.snp.width)
            }
            buttonModels.enumerated().forEach { index, model in
                let button = makeActionButton(model: model, index: index)
                actionButtons.append(button)
                actionStackView.addArrangedSubview(button)
                button.snp.makeConstraints { make in
                    actionButtonHeightConstraints.append(make.height.equalTo(minimumButtonRowHeight).constraint)
                }
                if index < buttonModels.count - 1 {
                    let separator = UIView()
                    separator.backgroundColor = .separator
                    actionStackView.addArrangedSubview(separator)
                    separator.snp.makeConstraints { make in
                        make.height.equalTo(separatorThickness)
                    }
                    actionSeparatorViews.append(separator)
                }
            }
        } else {
            customView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
            buttonModels.enumerated().forEach { index, model in
                let button = makeActionButton(model: model, index: index)
                actionButtons.append(button)
                compactActionStackView.addArrangedSubview(button)
                button.snp.makeConstraints { make in
                    actionButtonHeightConstraints.append(make.height.equalTo(minimumButtonRowHeight).constraint)
                }
            }

            if buttonModels.count == 2 {
                compactDividerView.isHidden = false
                compactHorizontalDividerConstraints = compactDividerView.snp.prepareConstraints { make in
                    make.width.equalTo(separatorThickness)
                    make.top.bottom.equalTo(compactActionStackView)
                    make.centerX.equalTo(compactActionStackView.snp.centerX)
                }
                compactVerticalDividerConstraints = compactDividerView.snp.prepareConstraints { make in
                    make.height.equalTo(separatorThickness)
                    make.leading.trailing.equalTo(compactActionStackView)
                    make.top.equalTo(actionButtons[0].snp.bottom).offset(-separatorThickness / 2)
                }
                compactHorizontalDividerConstraints.forEach { $0.activate() }
            } else {
                compactDividerView.isHidden = true
            }
        }

        customerViewCallback?(customView)
    }

    // English: Create every action with the same one-shot dismissal path and preserve the public index contract.
    // Español: Crea cada acción con la misma ruta de cierre de una sola ejecución y conserva el contrato público de índices.
    // 中文：所有按钮共用一次性关闭流程，同时保持公开回调的索引契约不变。
    private func makeActionButton(model: PTCustomBottomButtonModel, index: Int) -> UIButton {
        let title = model.titleName ?? ""
        let button = UIButton(type: .custom)
        button.titleLabel?.font = buttonsFont
        button.setTitleColor(model.titleColor, for: .normal)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.systemGray, for: .highlighted)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentHorizontalAlignment = .center
        button.accessibilityTraits = .button
        button.tag = 100 + index
        button.addAction(UIAction { [weak self] _ in
            self?.handleAction(title: title, index: index)
        }, for: .touchUpInside)
        return button
    }

    private func handleAction(title: String, index: Int) {
        guard !isHandlingAction else { return }
        isHandlingAction = true
        actionButtons.forEach { $0.isEnabled = false }
        dismissSelf { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.bottomButtonTapCallback?(title, index)
                self.bottomButtonTapCallback = nil
            }
        }
    }

    private func resolvedTitleHeight(for width: CGFloat) -> CGFloat {
        guard !alertTitle.isEmpty else { return 0 }
        let textWidth = max(1, width - titleSpace * 2)
        return max(44, titleMessage.sizeFor(width: textWidth).height + 10)
    }

    // English: Give action labels enough vertical room for Dynamic Type without changing the public button API.
    // Español: Da a las etiquetas de acción suficiente espacio vertical para Dynamic Type sin cambiar la API pública de botones.
    // 中文：为动态字体下的按钮标题提供足够高度，同时不改变公开按钮 API。
    private func resolvedButtonRowHeight() -> CGFloat {
        let lineHeight = buttonsFont.lineHeight.isFinite ? buttonsFont.lineHeight : minimumButtonRowHeight - 20
        return max(minimumButtonRowHeight, ceil(lineHeight + 20))
    }

    private func resolvedCompactActionLayout(for width: CGFloat) -> CompactActionLayout {
        guard buttons.count == 2 else { return .horizontal }
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            return .vertical
        }

        let buttonWidth = max(1, (width - separatorThickness) / 2)
        let availableTitleWidth = max(1, buttonWidth - 24)
        let titlesFit = buttons.allSatisfy { title in
            let measuredSize = (title as NSString).size(withAttributes: [.font: buttonsFont])
            return measuredSize.width <= availableTitleWidth
        }
        return titlesFit ? .horizontal : .vertical
    }

    private func compactActionHeight(for layout: CompactActionLayout, rowHeight: CGFloat) -> CGFloat {
        guard !buttons.isEmpty else { return 0 }
        let buttonHeight = CGFloat(buttons.count) * rowHeight
        let internalSeparators = layout == .vertical
            ? CGFloat(max(0, buttons.count - 1)) * separatorThickness
            : 0
        return separatorThickness + buttonHeight + internalSeparators
    }

    private func actionsContentHeight(rowHeight: CGFloat) -> CGFloat {
        let rows = CGFloat(buttons.count) * rowHeight
        let separators = CGFloat(max(0, buttons.count - 1)) * separatorThickness
        return rows + separators
    }

    // English: Switch only constraints that describe the compact divider; the view hierarchy stays unchanged.
    // Español: Cambia solo las restricciones que describen el separador compacto; la jerarquía de vistas permanece intacta.
    // 中文：只切换紧凑按钮分隔线的约束，视图层级保持不变。
    private func applyCompactActionLayout(_ layout: CompactActionLayout) {
        guard buttons.count == 2 else {
            compactActionStackView.axis = .horizontal
            compactActionStackView.spacing = 0
            compactDividerView.isHidden = true
            return
        }

        compactActionStackView.axis = layout == .horizontal ? .horizontal : .vertical
        // English: Reserve the separator's thickness in the vertical stack so button height constraints stay satisfiable.
        // Español: Reserva el grosor del separador en la pila vertical para que las restricciones de altura de los botones sigan siendo compatibles.
        // 中文：纵向堆叠时预留分隔线高度，确保按钮高度约束始终可满足。
        compactActionStackView.spacing = layout == .vertical ? separatorThickness : 0
        if layout == .horizontal {
            compactVerticalDividerConstraints.forEach { $0.deactivate() }
            compactHorizontalDividerConstraints.forEach { $0.activate() }
        } else {
            compactHorizontalDividerConstraints.forEach { $0.deactivate() }
            compactVerticalDividerConstraints.forEach { $0.activate() }
        }
        compactDividerView.isHidden = false
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAlertLayout()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateAlertLayout()
    }

    // English: Cap the surface to the safe area and select the smallest scrollable region that fits the content.
    // Español: Limita la superficie al área segura y selecciona la región desplazable más pequeña que acomoda el contenido.
    // 中文：将弹窗限制在安全区内，并选择能够容纳内容的最小滚动区域。
    private func updateAlertLayout() {
        guard contentWidthConstraint != nil, contentHeightConstraint != nil else { return }

        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame
        let availableWidth = safeAreaFrame.width > 0 ? safeAreaFrame.width : view.bounds.width
        let width = Self.resolvedContentWidth(containerWidth: min(max(1, view.bounds.width), max(1, availableWidth)),
                                               contentSpace: contentSpace,
                                               maximumWidth: maximumContentWidth)
        let safeHeight = safeAreaFrame.height > 0 ? safeAreaFrame.height : view.bounds.height
        guard safeHeight > 0 else { return }

        let maximumHeight = max(1, safeHeight - minimumAlertVerticalMargin * 2)
        let resolvedTitleHeight = resolvedTitleHeight(for: width)
        let fixedContentHeight = resolvedTitleHeight + customerViewHeight
        let rowHeight = resolvedButtonRowHeight()
        let compactLayout = resolvedCompactActionLayout(for: width)
        let verticalButtonsHeight = actionsContentHeight(rowHeight: rowHeight)
        let compactButtonsHeight = compactActionHeight(for: compactLayout, rowHeight: rowHeight)

        let mode: ActionLayoutMode
        let contentHeight: CGFloat
        let actionViewportHeight: CGFloat

        if buttons.count > 2 {
            let requiredHeight = fixedContentHeight + verticalButtonsHeight
            if requiredHeight <= maximumHeight {
                mode = .fitted
                contentHeight = requiredHeight
                actionViewportHeight = verticalButtonsHeight
            } else if fixedContentHeight + min(verticalButtonsHeight, rowHeight * 2) <= maximumHeight {
                mode = .scrollingActions
                contentHeight = maximumHeight
                actionViewportHeight = max(rowHeight, maximumHeight - fixedContentHeight)
            } else {
                mode = .scrollingAll
                contentHeight = maximumHeight
                actionViewportHeight = verticalButtonsHeight
            }
        } else {
            mode = .fitted
            contentHeight = max(1, min(fixedContentHeight + compactButtonsHeight, maximumHeight))
            actionViewportHeight = 0
        }

        let signature = AlertLayoutSignature(width: width,
                                             safeHeight: safeHeight,
                                             titleHeight: resolvedTitleHeight,
                                             customerViewHeight: customerViewHeight,
                                             buttonCount: buttons.count,
                                             rowHeight: rowHeight,
                                             compactLayout: compactLayout)
        guard signature != layoutSignature || mode != actionLayoutMode || compactLayout != self.compactActionLayout else { return }

        let modeChanged = mode != actionLayoutMode || compactLayout != self.compactActionLayout
        contentWidth = width
        titleHeight = resolvedTitleHeight
        contentWidthConstraint?.update(offset: width)
        contentHeightConstraint?.update(offset: contentHeight)
        titleHeightConstraint?.update(offset: resolvedTitleHeight)
        customerViewHeightConstraint?.update(offset: customerViewHeight)
        actionViewportHeightConstraint?.update(offset: actionViewportHeight)
        actionButtonHeightConstraints.forEach { $0.update(offset: rowHeight) }

        if buttons.count > 2 {
            bodyScrollView.isScrollEnabled = mode == .scrollingAll
            bodyScrollView.showsVerticalScrollIndicator = bodyScrollView.isScrollEnabled
            actionScrollView.isScrollEnabled = mode == .scrollingActions
            actionScrollView.showsVerticalScrollIndicator = actionScrollView.isScrollEnabled
        } else {
            let bodyViewportHeight = max(0, contentHeight - compactButtonsHeight)
            bodyScrollView.isScrollEnabled = fixedContentHeight > bodyViewportHeight + 0.5
            bodyScrollView.showsVerticalScrollIndicator = bodyScrollView.isScrollEnabled
        }

        if buttons.count <= 2, !buttons.isEmpty {
            applyCompactActionLayout(compactLayout)
            compactActionHeightConstraint?.update(offset: compactButtonsHeight)
        }

        if modeChanged {
            bodyScrollView.setContentOffset(.zero, animated: false)
            actionScrollView.setContentOffset(.zero, animated: false)
        }
        actionLayoutMode = mode
        compactActionLayout = compactLayout
        layoutSignature = signature
    }
    
}

extension PTCustomerAlertController {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldReceive touch: UITouch) -> Bool {
        touch.view === view
    }
}

extension PTCustomerAlertController {
    public override func showAnimation(completion: PTActionTask?) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let duration = max(0, config.showAlertDuration)
        let showAnimations = {
            self.view.backgroundColor = UIColor.DevMaskColor
            self.contentView.alpha = 1.0
            if !reduceMotion {
                self.contentView.transform = .identity
            }
        }

        contentView.transform = reduceMotion
            ? .identity
            : CGAffineTransform(scaleX: 0.94, y: 0.94)

        let finish: (Bool) -> Void = { _ in
            let accessibilityTarget: Any? = !self.alertTitle.isEmpty ? self.titleMessage : self.actionButtons.first
            if self.view.window != nil, let accessibilityTarget {
                UIAccessibility.post(notification: .screenChanged, argument: accessibilityTarget)
            }
            completion?()
        }

        if reduceMotion {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut],
                           animations: showAnimations,
                           completion: finish)
        } else {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.92,
                           initialSpringVelocity: 0,
                           options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut],
                           animations: showAnimations,
                           completion: finish)
        }
    }
    
    public override func dismissAnimation(completion: PTActionTask?) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let duration = max(0, config.hideAlertDuration)
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseIn],
                       animations: {
            self.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00)
            self.contentView.alpha = 0.0
            if !reduceMotion {
                self.contentView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            }
        }) { _ in
            completion?()
        }
    }
}
