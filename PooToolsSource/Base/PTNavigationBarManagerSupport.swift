//
//  PTNavigationBarManager.swift
//  PooTools
//
// English: Own the navigation-bar manager independently from the base view controller.
// Español: Mantiene el gestor de navegación independiente del controlador base.
// 中文：将导航栏管理器从基类控制器中独立出来。
//

import UIKit
import SnapKit

public enum PTScreenShotActionType {
    case Share,Feedback,Edit
}

@objc public enum VCStatusBarChangeStatusType : Int {
    case Dark,Light,Auto
}

public struct PTNavigationBarGeometry {

    /// 当前 Scene 的状态栏高度
    public let statusBarHeight: CGFloat

    /// 导航栏在 UIWindow 坐标系中的 CGRect
    public let navigationBarFrameInWindow: CGRect

    /// 导航栏本身高度
    public var navigationBarHeight: CGFloat {
        navigationBarFrameInWindow.height
    }

    /// 导航栏在 UIWindow 中的顶部位置
    public var navigationBarTopInWindow: CGFloat {
        navigationBarFrameInWindow.minY
    }

    /// 导航栏在 UIWindow 中的底部位置
    public var navigationBottomInWindow: CGFloat {
        navigationBarFrameInWindow.maxY
    }
}

@MainActor
enum PTNavigationGlassCompatibility {

    static var requiresWorkaround: Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion

        switch version.majorVersion {
        case 26:
            return true

        case 27:
            return version.minorVersion == 0

        default:
            return false
        }
    }
}

// English: Give UIKit-native bar-button custom views a stable intrinsic size.
// Español: Proporciona un tamaño intrínseco estable a las vistas personalizadas de los botones nativos de UIKit.
// 中文：为 UIKit 原生导航按钮的自定义视图提供稳定的固有尺寸。
@MainActor
final class PTNativeNavigationItemView: UIView {
    private let contentView: UIView
    private let preferredSize: CGSize

    init(contentView: UIView) {
        self.contentView = contentView
        let boundsSize = contentView.bounds.size
        let intrinsicSize = contentView.intrinsicContentSize
        let width = boundsSize.width > 0 ? boundsSize.width : intrinsicSize.width
        let height = boundsSize.height > 0 ? boundsSize.height : intrinsicSize.height
        self.preferredSize = CGSize(
            width: width > 0 && width.isFinite ? width : PTAppBaseConfig.share.navBarButtonSize,
            height: height > 0 && height.isFinite ? height : PTAppBaseConfig.share.navBarButtonSize
        )
        super.init(frame: CGRect(origin: .zero, size: self.preferredSize))
        isUserInteractionEnabled = contentView.isUserInteractionEnabled
        contentView.removeFromSuperview()
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override var intrinsicContentSize: CGSize {
        preferredSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
    }
}


@MainActor
public final class PTNavBarItem {
    public var isConfigured = false   // ✅ 新增
    // English: Track framework-generated back items so modal native bars can use UIKit's system back action.
    // Español: Identifica los elementos de retroceso creados por el framework para que las barras modales nativas usen la acción de UIKit.
    // 中文：标记框架生成的返回项，让原生 modal Bar 使用 UIKit 的系统返回动作。
    var usesFrameworkDefaultBackAction = false
    public var leftView: [UIView] = []
    public var leftItemSpacing:CGFloat = 0
    public var rightViews: [UIView] = []
    public var rightItemSpacing:CGFloat = 0
    public var titleView: UIView?
    // ✅ 新增：控制自定义 titleView 是否拉伸填满左右空间，默认开启
    public var titleViewFillSpace: Bool = true
    public var navTitle:String = ""
    public var barColorStyle:PTNavigationBarStyle = .transparent
}

// English: Keep renderer ownership decisions as pure values so lifecycle branches can be tested without UIKit.
// Español: Mantiene las decisiones de propiedad del renderizador como valores puros para probar el ciclo de vida sin UIKit.
// 中文：将渲染器所有权决策保持为纯值，便于脱离 UIKit 测试生命周期分支。
enum PTNavigationRendererMode: String, Equatable, Sendable {
    case customHorizontal
    case systemVertical
    case transitioning
}

// English: Describe only the facts needed to decide whether a navigation stack must be reconciled.
// Español: Describe solo los hechos necesarios para decidir si una pila debe reconciliarse.
// 中文：只描述判断导航栈是否需要重新收敛所需的事实。
struct PTNavigationRendererReconciliationInput: Equatable, Sendable {
    let currentMode: PTNavigationRendererMode?
    let targetMode: PTNavigationRendererMode
    let itemAttached: Bool
    let geometryChanged: Bool
    let transitionActive: Bool
}

enum PTNavigationRendererReconciliationDecision: Equatable, Sendable {
    case noOp
    case reconcile
    case deferUntilTransitionCompletes
}

enum PTNavigationRendererReconciliationPlanner {
    static func decision(for input: PTNavigationRendererReconciliationInput) -> PTNavigationRendererReconciliationDecision {
        if input.transitionActive {
            return .deferUntilTransitionCompletes
        }
        if input.currentMode != input.targetMode || !input.itemAttached || input.geometryChanged {
            return .reconcile
        }
        return .noOp
    }
}

enum PTNavigationReconciliationReason: String, Sendable {
    case initialInstall
    case traitChange
    case safeArea
    case viewDidLayout
    case sceneResize
    case willShow
    case didShow
    case styleUpdate
    case itemUpdate
    case restoration
    case geometryRefresh
    case transitionCompleted
}

// English: Multiplex navigation callbacks so the framework does not replace a host application's delegate.
// Español: Multiplexa los callbacks de navegación para que el framework no reemplace el delegate de la aplicación anfitriona.
// 中文：复用导航回调，避免框架覆盖宿主应用自己的 delegate。
final class PTNavigationDelegateProxy: NSObject, UINavigationControllerDelegate {
    weak var manager: PTNavigationBarManager?
    weak var hostDelegate: UINavigationControllerDelegate?

    init(manager: PTNavigationBarManager,
         hostDelegate: UINavigationControllerDelegate?) {
        self.manager = manager
        self.hostDelegate = hostDelegate
        super.init()
    }

    @MainActor
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        manager?.navigationController(navigationController,
                                      willShow: viewController,
                                      animated: animated)
        hostDelegate?.navigationController?(navigationController,
                                             willShow: viewController,
                                             animated: animated)
    }

    @MainActor
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        manager?.navigationController(navigationController,
                                      didShow: viewController,
                                      animated: animated)
        hostDelegate?.navigationController?(navigationController,
                                             didShow: viewController,
                                             animated: animated)
    }

    @MainActor
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        hostDelegate?.navigationControllerSupportedInterfaceOrientations?(navigationController) ?? .all
    }

    @MainActor
    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        hostDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(navigationController) ?? .portrait
    }

    @MainActor
    func navigationController(_ navigationController: UINavigationController,
                              interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        hostDelegate?.navigationController?(navigationController,
                                             interactionControllerFor: animationController)
    }

    @MainActor
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        hostDelegate?.navigationController?(navigationController,
                                             animationControllerFor: operation,
                                             from: fromVC,
                                             to: toVC)
    }

    // English: Forward the remaining UIKit delegate callbacks explicitly to keep actor isolation type-safe.
    // Español: Reenvía explícitamente los demás callbacks del delegate de UIKit para mantener segura la aislación del actor.
    // 中文：显式转发其余 UIKit delegate 回调，避免破坏 actor 隔离。
    nonisolated override func responds(to aSelector: Selector) -> Bool {
        let selectorName = NSStringFromSelector(aSelector)
        if selectorName == "navigationController:willShowViewController:animated:"
            || selectorName == "navigationController:didShowViewController:animated:" {
            return true
        }

        let isForwardedNavigationSelector: Bool
        switch selectorName {
        case "navigationControllerSupportedInterfaceOrientations:",
             "navigationControllerPreferredInterfaceOrientationForPresentation:",
             "navigationController:interactionControllerForAnimationController:",
             "navigationController:animationControllerForOperation:fromViewController:toViewController:":
            isForwardedNavigationSelector = true
        default:
            isForwardedNavigationSelector = false
        }

        guard isForwardedNavigationSelector else {
            return super.responds(to: aSelector)
        }
        guard Thread.isMainThread else { return false }
        return MainActor.assumeIsolated { [weak self] in
            self?.hostDelegate?.responds(to: aSelector) ?? false
        }
    }
}
