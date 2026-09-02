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

    // English: Cache only geometry inputs so repeated layout passes do not recreate constraints or controls.
    // Español: Guarda solo las entradas geométricas para que los pases de diseño repetidos no reconstruyan restricciones ni controles.
    // 中文：只缓存几何输入，避免重复布局时重新创建约束和控件。
    private struct AlertLayoutSignature: Equatable {
        let width: CGFloat
        let safeHeight: CGFloat
        let titleHeight: CGFloat
        let customerViewHeight: CGFloat
        let buttonCount: Int
    }

    public var bottomButtonTapCallback:((_ title:String,_ index:Int) -> Void)? = nil
    public var backgroundTapCallback:((PTCustomerAlertController) -> Void)? = nil
    public var contentBackgroundColor: UIColor? {
        didSet {
            updateContentBackgroundIfLoaded()
        }
    }

    // English: Keep the default alert surface dynamic and translucent so the system material remains visible.
    // Español: Mantén la superficie predeterminada dinámica y translúcida para conservar el material del sistema.
    // 中文：默认弹窗表面使用动态半透明颜色，确保系统磨砂材质始终可见。
    private var resolvedContentBackgroundColor: UIColor {
        contentBackgroundColor ?? UIColor.ptPresentationMaterialSurface
    }

    fileprivate lazy var contentView:UIView = {
        let view = UIView()
        view.backgroundColor = resolvedContentBackgroundColor
        view.alpha = 0.0
        view.layer.cornerRadius = cornerSize
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
    private lazy var blur:SSBlurView = {
        let view = SSBlurView(frame: .zero)
        view.style = .systemMaterial
        view.animationDuration = 0.01
        view.enable(animated: false)
        return view
    }()
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
    private var actionButtons = [UIButton]()
    private var contentWidthConstraint: NSLayoutConstraint?
    private var contentHeightConstraint: NSLayoutConstraint?
    private var titleHeightConstraint: NSLayoutConstraint?
    private var customerViewHeightConstraint: NSLayoutConstraint?
    private var actionViewportHeightConstraint: NSLayoutConstraint?
    private var layoutSignature: AlertLayoutSignature?
    private var actionLayoutMode: ActionLayoutMode = .fitted
    private var isHandlingAction = false

    private let buttonRowHeight: CGFloat = 44
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

        contentWidth = max(1, view.bounds.width - contentSpace * 2)
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
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: contentWidth)
        contentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 1)
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            contentWidthConstraint!,
            contentHeightConstraint!
        ])
        
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

        contentView.addSubview(blur)
        blur.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: contentView.topAnchor),
            blur.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        configureContentHierarchy()
    }

    private func updateContentBackgroundIfLoaded() {
        guard isViewLoaded else { return }
        contentView.backgroundColor = resolvedContentBackgroundColor
    }
    
    // English: Build the hierarchy once; later size changes only update constants and scroll modes.
    // Español: Construye la jerarquía una sola vez; los cambios de tamaño posteriores solo actualizan constantes y modos de desplazamiento.
    // 中文：只创建一次视图层级，后续尺寸变化仅更新约束常量和滚动模式。
    private func configureContentHierarchy() {
        bodyScrollView.translatesAutoresizingMaskIntoConstraints = false
        bodyContentView.translatesAutoresizingMaskIntoConstraints = false
        titleMessage.translatesAutoresizingMaskIntoConstraints = false
        customView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(bodyScrollView)
        bodyScrollView.addSubview(bodyContentView)

        var bodyBottomConstraint: NSLayoutConstraint
        NSLayoutConstraint.activate([
            bodyScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bodyScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bodyScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        if buttons.count <= 2, !buttons.isEmpty {
            compactActionView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(compactActionView)
            bodyBottomConstraint = bodyScrollView.bottomAnchor.constraint(equalTo: compactActionView.topAnchor)
            NSLayoutConstraint.activate([
                compactActionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                compactActionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                compactActionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                compactActionView.heightAnchor.constraint(equalToConstant: buttonRowHeight),
                bodyBottomConstraint
            ])
        } else {
            bodyBottomConstraint = bodyScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            bodyBottomConstraint.isActive = true
        }

        NSLayoutConstraint.activate([
            bodyContentView.topAnchor.constraint(equalTo: bodyScrollView.contentLayoutGuide.topAnchor),
            bodyContentView.leadingAnchor.constraint(equalTo: bodyScrollView.contentLayoutGuide.leadingAnchor),
            bodyContentView.trailingAnchor.constraint(equalTo: bodyScrollView.contentLayoutGuide.trailingAnchor),
            bodyContentView.bottomAnchor.constraint(equalTo: bodyScrollView.contentLayoutGuide.bottomAnchor),
            bodyContentView.widthAnchor.constraint(equalTo: bodyScrollView.frameLayoutGuide.widthAnchor),
            titleMessage.topAnchor.constraint(equalTo: bodyContentView.topAnchor),
            titleMessage.leadingAnchor.constraint(equalTo: bodyContentView.leadingAnchor, constant: titleSpace),
            titleMessage.trailingAnchor.constraint(equalTo: bodyContentView.trailingAnchor, constant: -titleSpace),
            customView.topAnchor.constraint(equalTo: titleMessage.bottomAnchor),
            customView.leadingAnchor.constraint(equalTo: bodyContentView.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: bodyContentView.trailingAnchor)
        ])

        titleHeightConstraint = titleMessage.heightAnchor.constraint(equalToConstant: titleHeight)
        titleHeightConstraint?.isActive = true
        customerViewHeightConstraint = customView.heightAnchor.constraint(equalToConstant: customerViewHeight)
        customerViewHeightConstraint?.isActive = true

        if buttons.count > 2 {
            actionScrollView.translatesAutoresizingMaskIntoConstraints = false
            actionStackView.translatesAutoresizingMaskIntoConstraints = false
            bodyContentView.addSubview(actionScrollView)
            actionScrollView.addSubview(actionStackView)

            NSLayoutConstraint.activate([
                actionScrollView.topAnchor.constraint(equalTo: customView.bottomAnchor),
                actionScrollView.leadingAnchor.constraint(equalTo: bodyContentView.leadingAnchor),
                actionScrollView.trailingAnchor.constraint(equalTo: bodyContentView.trailingAnchor),
                actionScrollView.bottomAnchor.constraint(equalTo: bodyContentView.bottomAnchor),
                actionStackView.topAnchor.constraint(equalTo: actionScrollView.contentLayoutGuide.topAnchor),
                actionStackView.leadingAnchor.constraint(equalTo: actionScrollView.contentLayoutGuide.leadingAnchor),
                actionStackView.trailingAnchor.constraint(equalTo: actionScrollView.contentLayoutGuide.trailingAnchor),
                actionStackView.bottomAnchor.constraint(equalTo: actionScrollView.contentLayoutGuide.bottomAnchor),
                actionStackView.widthAnchor.constraint(equalTo: actionScrollView.frameLayoutGuide.widthAnchor)
            ])

            actionViewportHeightConstraint = actionScrollView.heightAnchor.constraint(equalToConstant: 1)
            actionViewportHeightConstraint?.isActive = true
            buttonModels.enumerated().forEach { index, model in
                let button = makeActionButton(model: model, index: index)
                actionButtons.append(button)
                actionStackView.addArrangedSubview(button)
                button.heightAnchor.constraint(equalToConstant: buttonRowHeight).isActive = true
            }
        } else {
            let customBottomConstraint = customView.bottomAnchor.constraint(equalTo: bodyContentView.bottomAnchor)
            customBottomConstraint.isActive = true
            buttonModels.enumerated().forEach { index, model in
                let button = makeActionButton(model: model, index: index)
                actionButtons.append(button)
                compactActionView.addSubview(button)
                button.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    button.topAnchor.constraint(equalTo: compactActionView.topAnchor),
                    button.bottomAnchor.constraint(equalTo: compactActionView.bottomAnchor)
                ])
                if index == 0 {
                    button.leadingAnchor.constraint(equalTo: compactActionView.leadingAnchor).isActive = true
                } else {
                    button.leadingAnchor.constraint(equalTo: actionButtons[index - 1].trailingAnchor).isActive = true
                }
                if index == buttonModels.count - 1 {
                    button.trailingAnchor.constraint(equalTo: compactActionView.trailingAnchor).isActive = true
                }
                button.widthAnchor.constraint(equalTo: compactActionView.widthAnchor,
                                              multiplier: 1 / CGFloat(buttonModels.count)).isActive = true
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
        button.contentHorizontalAlignment = .center
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

        let width = max(1, view.bounds.width - contentSpace * 2)
        let safeHeight = max(view.safeAreaLayoutGuide.layoutFrame.height, view.bounds.height)
        guard safeHeight > 0 else { return }

        let maximumHeight = max(1, safeHeight - minimumAlertVerticalMargin * 2)
        let resolvedTitleHeight = resolvedTitleHeight(for: width)
        let fixedContentHeight = resolvedTitleHeight + customerViewHeight
        let verticalButtonsHeight = CGFloat(buttons.count) * buttonRowHeight
        let compactButtonsHeight = buttons.isEmpty ? 0 : buttonRowHeight

        let mode: ActionLayoutMode
        let contentHeight: CGFloat
        let actionViewportHeight: CGFloat

        if buttons.count > 2 {
            let requiredHeight = fixedContentHeight + verticalButtonsHeight
            if requiredHeight <= maximumHeight {
                mode = .fitted
                contentHeight = requiredHeight
                actionViewportHeight = verticalButtonsHeight
            } else if fixedContentHeight + min(verticalButtonsHeight, buttonRowHeight * 2) <= maximumHeight {
                mode = .scrollingActions
                contentHeight = maximumHeight
                actionViewportHeight = max(buttonRowHeight, maximumHeight - fixedContentHeight)
            } else {
                mode = .scrollingAll
                contentHeight = maximumHeight
                actionViewportHeight = verticalButtonsHeight
            }
        } else {
            mode = .fitted
            contentHeight = min(fixedContentHeight + compactButtonsHeight, maximumHeight)
            actionViewportHeight = 0
        }

        let signature = AlertLayoutSignature(width: width,
                                             safeHeight: safeHeight,
                                             titleHeight: resolvedTitleHeight,
                                             customerViewHeight: customerViewHeight,
                                             buttonCount: buttons.count)
        guard signature != layoutSignature || mode != actionLayoutMode else { return }

        let modeChanged = mode != actionLayoutMode
        contentWidth = width
        titleHeight = resolvedTitleHeight
        contentWidthConstraint?.constant = width
        contentHeightConstraint?.constant = contentHeight
        titleHeightConstraint?.constant = resolvedTitleHeight
        customerViewHeightConstraint?.constant = customerViewHeight
        actionViewportHeightConstraint?.constant = actionViewportHeight

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

        if modeChanged {
            bodyScrollView.setContentOffset(.zero, animated: false)
            actionScrollView.setContentOffset(.zero, animated: false)
        }
        actionLayoutMode = mode
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
        UIView.animate(withDuration: config.showAlertDuration) {
            self.view.backgroundColor = UIColor.DevMaskColor
            self.contentView.alpha = 1.0
        }
        contentView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        UIView.animate(withDuration: 0.35, delay: 0.0, options: UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(7 << 16)), animations: {
            self.contentView.transform = CGAffineTransform.identity
        }) { _ in
            completion?()
        }
    }
    
    public override func dismissAnimation(completion: PTActionTask?) {
        UIView.animate(withDuration: config.hideAlertDuration, animations: {
            self.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00)
            self.contentView.alpha = 0.0
        }) { _ in
            completion?()
        }
    }
}
