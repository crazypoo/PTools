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

    public var inspectorViewController: UIViewController? {
        storedInspectorViewController
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

    public func setInspector(_ viewController: UIViewController?) {
        storedInspectorViewController = viewController
        if viewController == nil {
            dismiss(animated: false)
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
        case .inspector:
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
        case .inspector:
            setInspector(viewController)
            presentInspectorIfNeeded(animated: animated)
        case .navigationPush:
            push(viewController, animated: animated)
        case .automatic:
            if isCompactWidth {
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
        dismiss(animated: animated)
    }

    public func makeState(identifierFor: (UIViewController) -> String?) -> PTSplitState {
        PTSplitState(selectedPrimaryIdentifier: primaryViewController.flatMap { identifierFor($0) },
                     selectedSupplementaryIdentifier: supplementaryViewController.flatMap { identifierFor($0) },
                     selectedSecondaryIdentifier: secondaryViewController.flatMap { identifierFor($0) },
                     inspectorVisible: presentedViewController === storedInspectorViewController)
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
        if state.inspectorVisible {
            presentInspectorIfNeeded(animated: false)
        }
    }

    private var isCompactWidth: Bool {
        traitCollection.horizontalSizeClass == .compact
    }

    private func push(_ viewController: UIViewController, animated: Bool) {
        let navigationController = visibleNavigationController
        if let navigationController {
            navigationController.pushViewController(viewController, animated: animated)
        } else {
            setSecondary(viewController)
        }
    }

    private var visibleNavigationController: UINavigationController? {
        if let navigationController = secondaryViewController as? UINavigationController {
            return navigationController
        }
        if let navigationController = supplementaryViewController as? UINavigationController {
            return navigationController
        }
        return primaryViewController as? UINavigationController
    }

    private func presentInspectorIfNeeded(animated: Bool) {
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
        case .wrapAll:
            return column != .inspector
        }
    }

    private func apply(configuration: PTSplitConfiguration) {
        preferredDisplayMode = configuration.displayMode
        preferredSplitBehavior = configuration.splitBehavior
        preferredPrimaryColumnWidthFraction = validatedFraction(configuration.primaryWidthFraction)
        preferredSupplementaryColumnWidthFraction = validatedFraction(configuration.supplementaryWidthFraction)
        if configuration.automaticallyCollapseInCompactWidth {
            presentsWithGesture = true
        }
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
