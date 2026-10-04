//
//  PTSplitViewController.swift
//  PooTools
//

import UIKit

// English: A scene-owned adaptive UIKit container for iPhone, iPad, and resizable windows.
// Español: Un contenedor UIKit adaptativo y perteneciente a la escena para iPhone, iPad y ventanas redimensionables.
// 中文：面向 iPhone、iPad 和可调整窗口的场景级自适应 UIKit 容器。
@MainActor
open class PTSplitViewController: UISplitViewController, PTAdaptiveNavigationContainer {
    public private(set) var configuration: PTSplitConfiguration
    private var storedInspectorViewController: UIViewController?

    public var primaryViewController: UIViewController? {
        viewController(for: PTSplitColumn.primary)
    }

    public var supplementaryViewController: UIViewController? {
        viewController(for: PTSplitColumn.supplementary)
    }

    public var secondaryViewController: UIViewController? {
        viewController(for: PTSplitColumn.secondary)
    }

    public var compactViewController: UIViewController? {
        viewController(for: PTSplitColumn.compact)
    }

    public var inspectorViewController: UIViewController? {
        storedInspectorViewController
    }

    // English: Use the actual collapsed state or horizontal size class instead of the device idiom.
    // Español: Usa el estado colapsado real o la clase de tamaño horizontal en lugar del tipo de dispositivo.
    // 中文：依据真实折叠状态或水平尺寸类别判断紧凑展示，不判断设备类型。
    public var isCompactPresentation: Bool {
        isCollapsed || traitCollection.horizontalSizeClass == .compact
    }

    // English: Automatic and router-driven presentation share the currently visible navigation stack.
    // Español: La presentación automática y la del router comparten la pila de navegación visible actual.
    // 中文：自动展示和 Router 展示统一使用当前真实可见的导航栈。
    public var activeNavigationController: UINavigationController? {
        if isCompactPresentation {
            if let compact = navigationController(for: .compact) {
                return compact
            }

            for controller in viewControllers.reversed() {
                if let navigationController = navigationController(from: controller) {
                    return navigationController
                }
            }

            return navigationController(for: .primary)
                ?? navigationController(for: .supplementary)
                ?? navigationController(for: .secondary)
        }

        return navigationController(for: .secondary)
            ?? navigationController(for: .supplementary)
            ?? navigationController(for: .primary)
    }

    public init(configuration: PTSplitConfiguration = PTSplitConfiguration()) {
        self.configuration = configuration
        super.init(style: configuration.style.splitStyle)
        apply(configuration: configuration)
    }

    public required init?(coder: NSCoder) {
        configuration = PTSplitConfiguration()
        super.init(coder: coder)
        apply(configuration: configuration)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        apply(configuration: configuration)
    }

    public func update(configuration: PTSplitConfiguration) {
        self.configuration = configuration
        apply(configuration: configuration)
    }

    public func setPrimary(_ viewController: UIViewController?) {
        super.setViewController(wrapped(viewController, for: .primary), for: .primary)
    }

    public func setSupplementary(_ viewController: UIViewController?) {
        super.setViewController(wrapped(viewController, for: .supplementary), for: .supplementary)
    }

    public func setSecondary(_ viewController: UIViewController?) {
        super.setViewController(wrapped(viewController, for: .secondary), for: .secondary)
    }

    public func setCompact(_ viewController: UIViewController?) {
        super.setViewController(wrapped(viewController, for: .compact), for: .compact)
    }

    public func setInspector(_ viewController: UIViewController?) {
        storedInspectorViewController = viewController
        applyInspectorMode()
        if viewController == nil {
            hideInspector(animated: false)
        }
    }

    public func setViewController(_ viewController: UIViewController?, for column: PTSplitColumn) {
        switch column {
        case .primary:
            setPrimary(viewController)
        case .supplementary:
            setSupplementary(viewController)
        case .secondary:
            setSecondary(viewController)
        case .compact:
            setCompact(viewController)
        case .inspector:
            setInspector(viewController)
        }
    }

    public func viewController(for column: PTSplitColumn) -> UIViewController? {
        switch column {
        case .primary:
            return super.viewController(for: UISplitViewController.Column.primary)
        case .supplementary:
            return super.viewController(for: UISplitViewController.Column.supplementary)
        case .secondary:
            return super.viewController(for: UISplitViewController.Column.secondary)
        case .compact:
            return super.viewController(for: UISplitViewController.Column.compact)
        case .inspector:
            if #available(iOS 26.0, *), usesNativeInspector {
                return super.viewController(for: .inspector) ?? storedInspectorViewController
            }
            return storedInspectorViewController
        }
    }

    public func show(_ viewController: UIViewController,
                     target: PTSplitPresentationTarget = .automatic,
                     animated: Bool = true) {
        switch target {
        case .primary:
            setPrimary(viewController)
        case .supplementary:
            setSupplementary(viewController)
        case .secondary:
            setSecondary(viewController)
        case .compact:
            setCompact(viewController)
        case .inspector:
            setInspector(viewController)
            presentInspectorIfNeeded(animated: animated)
        case .navigationPush:
            push(viewController, animated: animated)
        case .automatic:
            if isCompactPresentation {
                push(viewController, animated: animated)
            } else {
                setSecondary(viewController)
            }
        }
    }

    // English: Router uses the Core protocol for the default adaptive destination.
    // Español: Router usa el protocolo de Core para el destino adaptativo predeterminado.
    // 中文：Router 通过 Core 协议使用默认的自适应目标。
    public func pt_showAdaptive(_ viewController: UIViewController) {
        show(viewController, target: .automatic)
    }

    public func pt_showAdaptive(_ viewController: UIViewController,
                                destination: PTSplitPresentationTarget) {
        show(viewController, target: destination)
    }

    public func showInspector(animated: Bool = true) {
        guard storedInspectorViewController != nil else { return }
        presentInspectorIfNeeded(animated: animated)
    }

    public func hideInspector(animated: Bool = true) {
        if #available(iOS 26.0, *), usesNativeInspector {
            hide(.inspector)
        } else if presentedViewController === storedInspectorViewController {
            dismiss(animated: animated)
        }
    }

    public func makeState(identifierFor: (UIViewController) -> String?) -> PTSplitState {
        PTSplitState(selectedPrimaryIdentifier: primaryViewController.flatMap { identifierFor($0) },
                     selectedSupplementaryIdentifier: supplementaryViewController.flatMap { identifierFor($0) },
                     selectedSecondaryIdentifier: secondaryViewController.flatMap { identifierFor($0) },
                     selectedCompactIdentifier: compactViewController.flatMap { identifierFor($0) },
                     inspectorVisible: isInspectorVisible)
    }

    public func restore(state: PTSplitState,
                        resolve: (String) -> UIViewController?) {
        if let identifier = state.selectedPrimaryIdentifier {
            setPrimary(resolve(identifier))
        }
        if let identifier = state.selectedSupplementaryIdentifier {
            setSupplementary(resolve(identifier))
        }
        if let identifier = state.selectedSecondaryIdentifier {
            setSecondary(resolve(identifier))
        }
        if let identifier = state.selectedCompactIdentifier {
            setCompact(resolve(identifier))
        }
        if state.inspectorVisible {
            presentInspectorIfNeeded(animated: false)
        }
    }

    private func push(_ viewController: UIViewController, animated: Bool) {
        if let navigationController = activeNavigationController {
            navigationController.pushViewController(viewController, animated: animated)
            return
        }

        // English: Never silently drop a push when a caller supplied an unwrapped column.
        // Español: Nunca descarta silenciosamente un push cuando el llamador proporcionó una columna sin envolver.
        // 中文：调用方未提供导航包装时，也不能静默丢弃 push 请求。
        if isCompactPresentation {
            if let compactViewController,
               !(compactViewController is UINavigationController) {
                compactViewController.show(viewController, sender: nil)
            } else {
                setCompact(viewController)
            }
        } else {
            setSecondary(viewController)
        }
    }

    public func navigationController(for column: PTSplitColumn) -> UINavigationController? {
        guard let viewController = viewController(for: column) else { return nil }
        return navigationController(from: viewController)
    }

    private func presentInspectorIfNeeded(animated: Bool) {
        guard storedInspectorViewController != nil else { return }
        if #available(iOS 26.0, *), usesNativeInspector {
            show(.inspector)
            return
        }

        guard let inspector = storedInspectorViewController,
              presentedViewController == nil else { return }
        inspector.modalPresentationStyle = .pageSheet
        present(inspector, animated: animated)
    }

    private func wrapped(_ viewController: UIViewController?, for column: PTSplitColumn) -> UIViewController? {
        guard let viewController else { return nil }
        guard shouldWrap(column: column), !(viewController is UINavigationController) else {
            return viewController
        }
        return PTBaseNavControl(rootViewController: viewController)
    }

    private func shouldWrap(column: PTSplitColumn) -> Bool {
        switch configuration.navigationPolicy {
        case .none, .custom:
            return false
        case .wrapPrimary:
            return column == .primary
        case .wrapSecondary:
            return column == .secondary
        case .wrapCompact:
            return column == .compact
        case .wrapAll:
            return column != .inspector
        }
    }

    private func apply(configuration: PTSplitConfiguration) {
        preferredDisplayMode = configuration.displayMode
        preferredSplitBehavior = configuration.splitBehavior
        preferredPrimaryColumnWidthFraction = validatedFraction(configuration.primaryWidthFraction)
        preferredSupplementaryColumnWidthFraction = validatedFraction(configuration.supplementaryWidthFraction)
        presentsWithGesture = configuration.automaticallyCollapseInCompactWidth
        applyInspectorMode()
    }

    private var usesNativeInspector: Bool {
        switch configuration.inspectorMode {
        case .sheet:
            return false
        case .automatic, .nativeWhenAvailable:
            return true
        }
    }

    private var isInspectorVisible: Bool {
        if #available(iOS 26.0, *), usesNativeInspector {
            return isShowing(.inspector)
        }
        return presentedViewController === storedInspectorViewController
    }

    private func applyInspectorMode() {
        guard #available(iOS 26.0, *) else { return }
        if usesNativeInspector {
            super.setViewController(storedInspectorViewController, for: .inspector)
        } else {
            super.setViewController(nil, for: .inspector)
        }
    }

    private func navigationController(from viewController: UIViewController) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        if let navigationController = viewController.navigationController {
            return navigationController
        }
        for child in viewController.children.reversed() {
            if let navigationController = navigationController(from: child) {
                return navigationController
            }
        }
        return nil
    }

    private func validatedFraction(_ value: CGFloat?) -> CGFloat {
        guard let value, value.isFinite else { return 0 }
        return min(max(value, 0.1), 0.9)
    }
}

extension PTSplitViewController: UISplitViewControllerDelegate { }

private extension PTSplitConfiguration.Style {
    var splitStyle: UISplitViewController.Style {
        switch self {
        case .doubleColumn:
            return .doubleColumn
        case .tripleColumn:
            return .tripleColumn
        }
    }
}
