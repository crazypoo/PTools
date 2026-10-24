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
private final class PTNativeNavigationItemView: UIView {
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
private final class PTNavigationDelegateProxy: NSObject, UINavigationControllerDelegate {
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

@MainActor
public final class PTNavigationBarManager:NSObject {
    
    public static let shared = PTNavigationBarManager()
    
    // English: Public initialization allows one manager instance per scene; shared remains a compatibility convenience.
    // Español: La inicialización pública permite una instancia por escena; shared sigue siendo una comodidad compatible.
    // 中文：公开初始化支持按场景创建实例，shared 继续作为兼容便捷入口。
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidDisconnect(_:)),
                                               name: UIScene.didDisconnectNotification,
                                               object: nil)
        // English: Re-render custom navigation surfaces when Reduce Transparency changes.
        // Español: Vuelve a renderizar las superficies de navegación cuando cambia Reducir transparencia.
        // 中文：当“降低透明度”设置变化时重新渲染自定义导航栏表面。
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accessibilityAppearanceDidChange),
                                               name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func sceneDidDisconnect(_ notification: Notification) {
        guard let scene = notification.object as? UIWindowScene else { return }
        let sceneID = scene.session.persistentIdentifier
        navigationContextsBySceneID.removeValue(forKey: sceneID)
    }

    @objc private func accessibilityAppearanceDidChange() {
        let keyEnumerator = containerMap.keyEnumerator()
        while let navigationController = keyEnumerator.nextObject() as? UINavigationController,
              let container = containerMap.object(forKey: navigationController) {
            container.rerenderCurrentStyle()
        }
    }
    
    private var titleLabel:Bool = false

    // 每个导航栈独立保存样式，避免多个导航控制器互相覆盖状态。
    private final class NavigationStyleBox: NSObject {
        let style: PTNavigationBarStyle

        init(style: PTNavigationBarStyle) {
            self.style = style
        }
    }

    // 每个导航栈独立保存 TabBar 转场回调，兼容旧的全局回调入口。
    private final class TabBarHandlerBox: NSObject {
        let handler: (UINavigationController, UIViewController, Bool, UIViewControllerTransitionCoordinator?) -> Void

        init(handler: @escaping (UINavigationController, UIViewController, Bool, UIViewControllerTransitionCoordinator?) -> Void) {
            self.handler = handler
        }
    }

    // English: Keep transition progress with its navigation stack so simultaneous scenes cannot overwrite each other.
    // Español: Conserva el progreso de la transición con su pila de navegación para que escenas simultáneas no se sobrescriban.
    // 中文：将转场进度绑定到对应导航栈，避免多个场景同时转场时互相覆盖。
    private final class NavigationTransitionState: NSObject {
        weak var coordinator: UIViewControllerTransitionCoordinator?
        weak var container: PTNavigationBarContainer?

        init(coordinator: UIViewControllerTransitionCoordinator,
             container: PTNavigationBarContainer) {
            self.coordinator = coordinator
            self.container = container
        }
    }

    // English: Keep renderer state weakly keyed per navigation controller and scene.
    // Español: Conserva el estado del renderizador por controlador y escena usando claves débiles.
    // 中文：按导航控制器和场景保存渲染器状态，并使用弱引用键。
    private final class NavigationRendererStateBox: NSObject {
        var mode: PTNavigationRendererMode

        init(mode: PTNavigationRendererMode) {
            self.mode = mode
        }
    }

    // English: Remember only native items created by PTools so host-owned UIKit items survive renderer changes.
    // Español: Recuerda solo los elementos nativos creados por PTools para conservar los elementos UIKit del host.
    // 中文：只记录 PTools 创建的原生项，渲染器切换时保留宿主自己的 UIKit 项。
    private final class NativeNavigationOwnershipBox: NSObject {
        // English: Keep the controller whose navigation item owns the tracked UIKit wrappers.
        // Español: Conserva el controlador cuyo elemento de navegación posee los wrappers UIKit registrados.
        // 中文：记录当前拥有这些 UIKit wrapper 的页面控制器。
        weak var viewController: UIViewController?
        var leftItems: [UIBarButtonItem] = []
        var rightItems: [UIBarButtonItem] = []
        var leadingGroups: [UIBarButtonItemGroup] = []
        var trailingGroups: [UIBarButtonItemGroup] = []
        // English: Restore host items that were temporarily folded into a PTools-owned adaptive group.
        // Español: Restaura los elementos del host que se agruparon temporalmente dentro de un grupo adaptativo de PTools.
        // 中文：恢复临时并入 PTools 自适应分组的宿主按钮。
        var leadingGroupHostItems: [UIBarButtonItem] = []
        var trailingGroupHostItems: [UIBarButtonItem] = []
        // English: Keep a host-owned pinned trailing group so the renderer can restore it after a Duo transition.
        // Español: Conserva el grupo trailing fijado del host para restaurarlo después de una transición de Duo.
        // 中文：记录宿主原有的 pinned trailing group，Duo 渲染器切换后恢复它。
        var hostPinnedTrailingGroup: UIBarButtonItemGroup?
        var pinnedTrailingGroup: UIBarButtonItemGroup?
        weak var titleView: UIView?
        var title: String?
        var backAction: UIAction?
    }

    // English: Isolate reconciliation re-entry, pending reasons, and diagnostic signatures per navigation stack.
    // Español: Aísla la reentrada, las razones pendientes y las firmas de diagnóstico por pila de navegación.
    // 中文：按导航栈隔离收敛重入、待处理原因和诊断签名。
    private final class NavigationReconciliationStateBox: NSObject {
        var isReconciling = false
        var pendingReason: PTNavigationReconciliationReason?
        var generation: UInt64 = 0
        var lastGeometrySignature: String?
        var lastDiagnosticSignature: String?
        var pendingReconciliationScheduled = false
    }

    // English: Keep the currently visible controller per scene while retaining the legacy active-stack pointers.
    // Español: Conserva el controlador visible por escena y mantiene los punteros heredados de la pila activa.
    // 中文：按场景保存当前可见控制器，同时保留旧的活动导航栈指针。
    private final class NavigationContextBox: NSObject {
        weak var navigationController: UINavigationController?
        weak var viewController: UIViewController?

        init(navigationController: UINavigationController,
             viewController: UIViewController?) {
            self.navigationController = navigationController
            self.viewController = viewController
        }
    }
    
    // ❗ 核心：按 VC 存储
    private var itemCache = NSMapTable<UIViewController, PTNavBarItem>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var containerMap = NSMapTable<UINavigationController, PTNavigationBarContainer>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var styleCache = NSMapTable<UINavigationController, NavigationStyleBox>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var tabBarHandlerCache = NSMapTable<UINavigationController, TabBarHandlerBox>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var delegateProxyMap = NSMapTable<UINavigationController, PTNavigationDelegateProxy>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var rendererStateMap = NSMapTable<UINavigationController, NavigationRendererStateBox>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var nativeOwnershipMap = NSMapTable<UINavigationController, NativeNavigationOwnershipBox>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var reconciliationStateMap = NSMapTable<UINavigationController, NavigationReconciliationStateBox>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    
    private weak var currentVC: UIViewController?
    weak var currentNav: UINavigationController?
    
    private var displayLink: CADisplayLink?
    private var transitionStates = NSMapTable<UINavigationController, NavigationTransitionState>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var navigationContextsBySceneID: [String: NavigationContextBox] = [:]
    
    public var tabBarHandler: ((UINavigationController, UIViewController, Bool, UIViewControllerTransitionCoordinator?) -> Void)?

    // English: Let UIKit own vertical navigation bars when the stack requests the system renderer.
    // Español: Deja que UIKit controle la barra de navegación vertical cuando la pila solicita el renderizador del sistema.
    // 中文：当导航栈使用系统渲染器时，让 UIKit 独占垂直导航栏。
    private func usesNativeVerticalBar(_ nav: UINavigationController) -> Bool {
        let policy = (nav as? PTBaseNavControl)?.adaptiveBarPresentationPolicy
            ?? PTAppBaseConfig.share.adaptiveBarPresentationPolicy
        guard policy == .automatic || policy == .preferSystemAdaptive else { return false }
        guard #available(iOS 27.1, *), nav.isViewLoaded else { return false }
        let edge = nav.view.traitCollection.verticalBarEdge
        return edge == .leading || edge == .trailing
    }

    // English: Expose the renderer ownership decision to scroll-view adapters without duplicating Duo checks.
    // Español: Expone la decisión del propietario del renderizador a los adaptadores de scroll sin duplicar comprobaciones de Duo.
    // 中文：向滚动视图适配层提供 Bar 所有权判断，避免重复实现 Duo 检测。
    func isSystemVerticalBarOwned(by navigationController: UINavigationController?) -> Bool {
        guard let navigationController else { return false }
        return usesNativeVerticalBar(navigationController)
    }

    private func setCustomContainer(_ container: PTNavigationBarContainer?, visible: Bool) {
        container?.isHidden = !visible
        container?.isUserInteractionEnabled = visible
    }

    private func navigationOwnership(for navigationController: UINavigationController) -> NativeNavigationOwnershipBox {
        if let ownership = nativeOwnershipMap.object(forKey: navigationController) {
            return ownership
        }
        let ownership = NativeNavigationOwnershipBox()
        nativeOwnershipMap.setObject(ownership, forKey: navigationController)
        return ownership
    }

    // English: Mark PTools items as visible in both horizontal and iPhone Duo vertical bars.
    // Español: Marca los elementos de PTools como visibles en barras horizontales y verticales de iPhone Duo.
    // 中文：让 PTools 按钮在普通横向导航栏和 iPhone Duo 垂直导航栏中都保持可见。
    private func makeNativeBarButtonItem(contentView: UIView) -> UIBarButtonItem {
        let item = UIBarButtonItem(customView: PTNativeNavigationItemView(contentView: contentView))
        if #available(iOS 27.0, *) {
            item.visibilityPriority = .high
        }
        if #available(iOS 27.1, *) {
            item.axisBehavior = .verticalPreferred
        }
        return item
    }

    // English: Use UIKit item groups because iPhone Duo vertical bars do not reliably render the legacy arrays.
    // Español: Usa grupos de UIKit porque las barras verticales de iPhone Duo no siempre muestran las matrices antiguas.
    // 中文：iPhone Duo 垂直导航栏不稳定显示旧数组，因此统一使用 UIKit item group。
    private func installNativeLeadingItems(_ items: [UIBarButtonItem],
                                           existingItems: [UIBarButtonItem],
                                           existingGroups: [UIBarButtonItemGroup],
                                           on navigationItem: UINavigationItem,
                                           ownership: NativeNavigationOwnershipBox) {
        guard !items.isEmpty else {
            navigationItem.leadingItemGroups = existingGroups
            navigationItem.leftBarButtonItems = existingItems.isEmpty ? nil : existingItems
            return
        }

        var groups = existingGroups
        if !existingItems.isEmpty {
            groups.append(UIBarButtonItemGroup.fixedGroup(representativeItem: nil,
                                                           items: existingItems))
            ownership.leadingGroupHostItems = existingItems
        }
        let group = UIBarButtonItemGroup.fixedGroup(representativeItem: nil, items: items)
        group.alwaysAvailable = true
        ownership.leadingGroups = [group]
        navigationItem.leadingItemGroups = groups + [group]
        navigationItem.leftBarButtonItem = nil
        navigationItem.leftBarButtonItems = nil
        navigationItem.leftItemsSupplementBackButton = false
    }

    // English: Keep every custom trailing action in one system-managed group during layout changes.
    // Español: Mantiene todas las acciones trailing personalizadas en un grupo gestionado por el sistema durante los cambios de layout.
    // 中文：布局变化期间，将所有自定义右侧操作放入一个系统管理的分组。
    private func installNativeTrailingItems(_ items: [UIBarButtonItem],
                                            existingItems: [UIBarButtonItem],
                                            existingGroups: [UIBarButtonItemGroup],
                                            existingPinnedGroup: UIBarButtonItemGroup?,
                                            on navigationItem: UINavigationItem,
                                            ownership: NativeNavigationOwnershipBox) {
        guard !items.isEmpty else {
            navigationItem.trailingItemGroups = existingGroups
            navigationItem.rightBarButtonItems = existingItems.isEmpty ? nil : existingItems
            navigationItem.pinnedTrailingGroup = existingPinnedGroup
            return
        }

        var groups = existingGroups
        if !existingItems.isEmpty {
            groups.append(UIBarButtonItemGroup.fixedGroup(representativeItem: nil,
                                                           items: existingItems))
            ownership.trailingGroupHostItems = existingItems
        }
        let group = UIBarButtonItemGroup.fixedGroup(representativeItem: nil, items: items)
        group.alwaysAvailable = true
        ownership.trailingGroups = [group]
        ownership.hostPinnedTrailingGroup = existingPinnedGroup
        if existingPinnedGroup == nil {
            // English: Pin the framework group so critical trailing actions stay visible beside the Duo status region.
            // Español: Fija el grupo del framework para mantener visibles las acciones críticas junto al estado de Duo.
            // 中文：没有宿主 pinned group 时固定框架分组，避免关键右侧操作被 Duo 状态区域或溢出菜单吞掉。
            ownership.pinnedTrailingGroup = group
            navigationItem.pinnedTrailingGroup = group
            navigationItem.trailingItemGroups = groups
        } else {
            navigationItem.trailingItemGroups = groups + [group]
        }
        navigationItem.rightBarButtonItem = nil
        navigationItem.rightBarButtonItems = nil
    }

    private func reconciliationState(for navigationController: UINavigationController) -> NavigationReconciliationStateBox {
        if let state = reconciliationStateMap.object(forKey: navigationController) {
            return state
        }
        let state = NavigationReconciliationStateBox()
        reconciliationStateMap.setObject(state, forKey: navigationController)
        return state
    }

    private func detachOwnedNativeContent(from navigationItem: UINavigationItem,
                                          ownership: NativeNavigationOwnershipBox) {
        if let item = navigationItem.leftBarButtonItem,
           ownership.leftItems.contains(where: { $0 === item }) {
            navigationItem.leftBarButtonItem = nil
        }
        if let items = navigationItem.leftBarButtonItems {
            let retained = items.filter { item in
                !ownership.leftItems.contains(where: { $0 === item })
            }
            navigationItem.leftBarButtonItems = retained.isEmpty ? nil : retained
        }
        if let item = navigationItem.rightBarButtonItem,
           ownership.rightItems.contains(where: { $0 === item }) {
            navigationItem.rightBarButtonItem = nil
        }
        if let items = navigationItem.rightBarButtonItems {
            let retained = items.filter { item in
                !ownership.rightItems.contains(where: { $0 === item })
            }
            navigationItem.rightBarButtonItems = retained.isEmpty ? nil : retained
        }
        navigationItem.leadingItemGroups = navigationItem.leadingItemGroups.filter { group in
            !ownership.leadingGroups.contains(where: { $0 === group })
        }
        navigationItem.trailingItemGroups = navigationItem.trailingItemGroups.filter { group in
            !ownership.trailingGroups.contains(where: { $0 === group })
        }
        if !ownership.leadingGroupHostItems.isEmpty {
            var restoredItems = ownership.leadingGroupHostItems
            for item in navigationItem.leftBarButtonItems ?? [] where !restoredItems.contains(where: { $0 === item }) {
                restoredItems.append(item)
            }
            navigationItem.leftBarButtonItems = restoredItems
        }
        if !ownership.trailingGroupHostItems.isEmpty {
            var restoredItems = ownership.trailingGroupHostItems
            for item in navigationItem.rightBarButtonItems ?? [] where !restoredItems.contains(where: { $0 === item }) {
                restoredItems.append(item)
            }
            navigationItem.rightBarButtonItems = restoredItems
        }
        if let pinnedGroup = ownership.pinnedTrailingGroup,
           navigationItem.pinnedTrailingGroup === pinnedGroup {
            navigationItem.pinnedTrailingGroup = ownership.hostPinnedTrailingGroup
        }
        if let titleView = navigationItem.titleView, titleView === ownership.titleView {
            navigationItem.titleView = nil
        }
        if let ownedTitle = ownership.title, navigationItem.title == ownedTitle {
            navigationItem.title = nil
        }
        if let backAction = ownership.backAction, navigationItem.backAction === backAction {
            navigationItem.backAction = nil
        }
        ownership.leftItems.removeAll()
        ownership.rightItems.removeAll()
        ownership.leadingGroups.removeAll()
        ownership.trailingGroups.removeAll()
        ownership.leadingGroupHostItems.removeAll()
        ownership.trailingGroupHostItems.removeAll()
        ownership.hostPinnedTrailingGroup = nil
        ownership.pinnedTrailingGroup = nil
        ownership.titleView = nil
        ownership.title = nil
        ownership.backAction = nil
        ownership.viewController = nil
    }

    // English: Remove only framework-owned native items before the custom renderer becomes authoritative.
    // Español: Elimina solo los elementos nativos propios del framework antes de que mande el renderizador personalizado.
    // 中文：自定义渲染器接管前，只清理框架拥有的原生导航项。
    private func clearNativeNavigationItem(in navigationController: UINavigationController) {
        let ownership = navigationOwnership(for: navigationController)
        let ownedViewController = ownership.viewController
        if let ownedViewController {
            detachOwnedNativeContent(from: ownedViewController.navigationItem,
                                     ownership: ownership)
        }

        let visibleViewController = navigationController.visibleViewController ?? navigationController.topViewController
        guard let visibleViewController,
              visibleViewController !== ownedViewController else { return }
        detachOwnedNativeContent(from: visibleViewController.navigationItem,
                                 ownership: ownership)
    }

    private func rendererMode(for navigationController: UINavigationController) -> PTNavigationRendererMode? {
        rendererStateMap.object(forKey: navigationController)?.mode
    }

    private func setRendererMode(_ mode: PTNavigationRendererMode,
                                 for navigationController: UINavigationController) {
        if let state = rendererStateMap.object(forKey: navigationController) {
            state.mode = mode
        } else {
            rendererStateMap.setObject(NavigationRendererStateBox(mode: mode), forKey: navigationController)
        }
    }

    // English: Switch renderer ownership atomically so a resize cannot leave two bars interactive.
    // Español: Cambia la propiedad del renderizador de forma atómica para que un resize no deje dos barras interactivas.
    // 中文：原子切换渲染器所有权，避免尺寸变化期间两套导航栏同时可交互。
    private func transitionRendererIfNeeded(in navigationController: UINavigationController,
                                            useSystemRenderer: Bool) {
        let target: PTNavigationRendererMode = useSystemRenderer ? .systemVertical : .customHorizontal
        guard rendererMode(for: navigationController) != target else { return }

        setRendererMode(.transitioning, for: navigationController)
        if target == .systemVertical {
            if let container = containerMap.object(forKey: navigationController) {
                container.clearTitleLayout()
                setCustomContainer(container, visible: false)
            }
            applyAdaptiveSystemPolicy(to: navigationController)
        } else {
            clearNativeNavigationItem(in: navigationController)
            if let container = containerMap.object(forKey: navigationController) {
                setCustomContainer(container, visible: true)
            }
        }
        setRendererMode(target, for: navigationController)
    }

    // English: Choose the status-bar conversion that is actually inside the current window.
    // Español: Elige la conversión de la barra de estado que realmente queda dentro de la ventana actual.
    // 中文：选择实际落在当前窗口内的状态栏坐标转换结果。
    private func statusBarFrameInWindow(_ statusBarFrame: CGRect,
                                        window: UIWindow,
                                        scene: UIWindowScene) -> CGRect? {
        let candidates = [
            window.screen.coordinateSpace.convert(statusBarFrame, to: window),
            scene.coordinateSpace.convert(statusBarFrame, to: window)
        ]
        let bounds = window.bounds
        var best: (rect: CGRect, area: CGFloat, edgeDistance: CGFloat)?
        for candidate in candidates {
            guard candidate.origin.x.isFinite,
                  candidate.origin.y.isFinite,
                  candidate.width.isFinite,
                  candidate.height.isFinite,
                  !candidate.isNull,
                  !candidate.isEmpty else { continue }
            let clipped = candidate.intersection(bounds)
            guard !clipped.isNull, !clipped.isEmpty else { continue }
            let area = clipped.width * clipped.height
            let edgeDistance = min(
                min(abs(clipped.minX - bounds.minX), abs(clipped.maxX - bounds.maxX)),
                min(abs(clipped.minY - bounds.minY), abs(clipped.maxY - bounds.maxY))
            )
            if best == nil || area > best!.area ||
                (area == best!.area && edgeDistance < best!.edgeDistance) {
                best = (clipped, area, edgeDistance)
            }
        }
        return best?.rect
    }

    // English: Convert the current scene's status-bar frame into the navigation-bar host coordinates.
    // Español: Convierte el frame de la barra de estado de la escena actual a las coordenadas del host de navegación.
    // 中文：将当前 Scene 的状态栏 frame 转换到导航栏宿主坐标系。
    private func navigationExclusionRects(in nav: UINavigationController,
                                           navigationBar: UINavigationBar) -> (local: [CGRect],
                                                                               statusWindow: CGRect?,
                                                                               reservedWindow: [CGRect]) {
        guard let window = nav.viewIfLoaded?.window,
              let scene = window.windowScene else {
            return ([], nil, [])
        }

        var localRects: [CGRect] = []
        var statusWindowRect: CGRect?
        if let statusBarFrame = scene.statusBarManager?.statusBarFrame,
           statusBarFrame.width.isFinite,
           statusBarFrame.height.isFinite,
           statusBarFrame.width > 0,
           statusBarFrame.height > 0 {
            if let converted = statusBarFrameInWindow(statusBarFrame,
                                                      window: window,
                                                      scene: scene) {
                statusWindowRect = converted
                let local = window.convert(converted, to: navigationBar)
                if !local.isNull, !local.isEmpty {
                    localRects.append(local)
                }
            }
        }

        let context = PTAdaptiveBarLayoutContext.make(for: navigationBar)
        let reservedWindowRects = context.reservedRegions
            .filter { $0.isActive }
            .map { navigationBar.convert($0.frame, to: window) }
            .filter { !$0.isNull && !$0.isEmpty }
        localRects.append(contentsOf: context.reservedRegions
            .filter { $0.isActive }
            .map(\.frame)
            .filter { !$0.isNull && !$0.isEmpty })
        return (localRects, statusWindowRect, reservedWindowRects)
    }

    // English: Resolve the real UINavigationBar row in local coordinates before updating any child constraints.
    // Español: Resuelve la fila real de UINavigationBar en coordenadas locales antes de actualizar restricciones hijas.
    // 中文：先在 UINavigationBar 局部坐标中解析真实内容行，再更新子视图约束。
    private func refreshNavigationContentRow(in nav: UINavigationController,
                                             container: PTNavigationBarContainer,
                                             reason: PTNavigationReconciliationReason = .geometryRefresh,
                                             generation: UInt64 = 0,
                                             rendererTransition: String? = nil) {
        let navBar = nav.navigationBar
        let hostFrame = navBar.bounds
        let hostBounds = CGRect(origin: .zero, size: hostFrame.size)
        guard hostBounds.width > 0,
              hostBounds.height > 0,
              hostBounds.width.isFinite,
              hostBounds.height.isFinite else {
            navBar.setNeedsLayout()
            return
        }
        container.syncHostBounds(hostFrame)

        let safeInsets = UIEdgeInsets(top: max(0, navBar.safeAreaInsets.top),
                                      left: max(0, navBar.safeAreaInsets.left),
                                      bottom: max(0, navBar.safeAreaInsets.bottom),
                                      right: max(0, navBar.safeAreaInsets.right))
        let insetSafeRect = hostBounds.inset(by: safeInsets)
        let hostSafeRect = insetSafeRect.isEmpty ? hostBounds : insetSafeRect
        let exclusions = navigationExclusionRects(in: nav, navigationBar: navBar)
        let isLargeTitleExpanded = container.isLargeTitleExpandedForLayout
        let compactRowHeight = isLargeTitleExpanded
            ? compactNavigationRowHeight(in: navBar, container: container)
            : nil
        let observedSystemRowRect = isLargeTitleExpanded
            ? nil
            : observedNavigationContentRow(in: navBar, hostBounds: hostBounds)
        let fallbackRowRect: CGRect?
        if isLargeTitleExpanded, let compactRowHeight {
            fallbackRowRect = CGRect(x: hostSafeRect.minX,
                                     y: hostSafeRect.minY,
                                     width: hostSafeRect.width,
                                     height: compactRowHeight)
        } else {
            fallbackRowRect = hostSafeRect
        }
        let evidence: PTNavigationContentRowEvidence = observedSystemRowRect == nil ? .fallback : .observed
        let input = PTNavigationContentRowInput(
            hostBounds: hostBounds,
            hostSafeRect: hostSafeRect,
            observedSystemRowRect: observedSystemRowRect,
            fallbackRowRect: fallbackRowRect,
            exclusionRects: exclusions.local,
            evidence: evidence,
            isLargeTitleExpanded: isLargeTitleExpanded,
            compactRowHeight: compactRowHeight
        )
        guard let result = PTNavigationContentRowResolver.resolve(input) else {
            // English: Do not cache a zero frame while UIKit is between layout states.
            // Español: No guarda un frame cero mientras UIKit está entre estados de layout.
            // 中文：UIKit 尚未完成布局时不缓存零尺寸内容行。
            navBar.setNeedsLayout()
            return
        }

        if container.applyNavigationContentRow(result.contentRect, input: input) {
            refreshTitleLayout(in: nav, container: container)
        }
#if DEBUG
        dumpNavigationVerticalGeometryIfEnabled(nav: nav,
                                                container: container,
                                                reason: reason,
                                                generation: generation,
                                                statusWindowRect: exclusions.statusWindow,
                                                reservedWindowRects: exclusions.reservedWindow,
                                                rendererTransition: rendererTransition)
#endif
    }

    // English: Keep renderer transition evidence stable and free of application content.
    // Español: Mantiene estable la evidencia del cambio de renderizador sin incluir contenido de la aplicación.
    // 中文：保持渲染器切换证据稳定，且不包含业务内容。
    private func rendererTransitionDescription(from oldMode: PTNavigationRendererMode?,
                                                to newMode: PTNavigationRendererMode) -> String {
        "\(oldMode?.rawValue ?? "none")->\(newMode.rawValue)"
    }

    // English: Read the public layout-margin frame as an observation, never as a fixed system height.
    // Español: Lee el frame público de layoutMargins como observación, nunca como una altura fija del sistema.
    // 中文：读取公开的 layoutMargins frame 作为观测值，不把它当作固定系统高度。
    private func observedNavigationContentRow(in navigationBar: UINavigationBar,
                                              hostBounds: CGRect) -> CGRect? {
        let marginsFrame = navigationBar.layoutMarginsGuide.layoutFrame
        guard marginsFrame.origin.x.isFinite,
              marginsFrame.origin.y.isFinite,
              marginsFrame.width.isFinite,
              marginsFrame.height.isFinite,
              marginsFrame.height > 0,
              marginsFrame.height <= hostBounds.height else {
            return nil
        }
        return CGRect(x: hostBounds.minX,
                      y: marginsFrame.minY,
                      width: hostBounds.width,
                      height: marginsFrame.height)
    }

#if DEBUG
    // English: Keep vertical geometry logging opt-in so normal debug builds have no extra output.
    // Español: Mantiene el registro geométrico optativo para no añadir salida en las compilaciones debug normales.
    // 中文：垂直几何日志默认关闭，避免普通 Debug 构建产生额外输出。
    private func dumpNavigationVerticalGeometryIfEnabled(nav: UINavigationController,
                                                         container: PTNavigationBarContainer,
                                                         reason: PTNavigationReconciliationReason,
                                                         generation: UInt64,
                                                         statusWindowRect: CGRect?,
                                                         reservedWindowRects: [CGRect],
                                                         rendererTransition: String? = nil) {
        guard ProcessInfo.processInfo.environment["PTOOLS_NAVIGATION_GEOMETRY_DEBUG"] == "1",
              let window = nav.viewIfLoaded?.window else { return }

        func rect(_ view: UIView) -> CGRect {
            view.convert(view.bounds, to: window)
        }

        let barRect = rect(nav.navigationBar)
        let hostRect = rect(container)
        let rowRect = rect(container.topBarContainer)
        let leftRect = rect(container.leftContainer)
        let rightRect = rect(container.rightContainer)
        let titleRect = rect(container.titleContainer)
        let windowBounds = window.bounds
        let sceneID = nav.viewIfLoaded?.window?.windowScene?.session.persistentIdentifier ?? "none"
        let mode = rendererMode(for: nav)?.rawValue ?? "unset"
        let navigationViewBounds = nav.viewIfLoaded?.bounds ?? .zero
        let navigationViewSafeInsets = nav.viewIfLoaded?.safeAreaInsets ?? .zero
        let verticalBarEdge: String = {
            guard #available(iOS 27.1, *) else { return "unavailable" }
            guard let traitCollection = nav.viewIfLoaded?.traitCollection else { return "unavailable" }
            switch traitCollection.verticalBarEdge {
            case .leading:
                return "leading"
            case .trailing:
                return "trailing"
            default:
                return "unspecified"
            }
        }()
        let layoutContext = PTAdaptiveBarLayoutContext.make(for: nav.navigationBar)
        let reservedIntersections = reservedWindowRects.flatMap { reservedRect in
            [leftRect, titleRect, rightRect].compactMap { itemRect in
                let intersection = reservedRect.intersection(itemRect)
                return intersection.isNull || intersection.isEmpty ? nil : intersection
            }
        }
        let rowMidY = rowRect.midY
        let midYValues = [leftRect.midY, titleRect.midY, rightRect.midY]
        let maxMidYDelta = midYValues.map { abs($0 - rowMidY) }.max() ?? 0
        let itemRects = [leftRect, titleRect, rightRect]
        let statusIntersections = statusWindowRect.map { statusRect in
            itemRects.compactMap { itemRect -> CGRect? in
                let intersection = statusRect.intersection(itemRect)
                return intersection.isNull || intersection.isEmpty ? nil : intersection
            }
        } ?? []
        let navigationItem = nav.visibleViewController?.navigationItem
        let ownership = nativeOwnershipMap.object(forKey: nav)
        let customInHost = container.superview === nav.navigationBar
        let customPresented = !container.isHidden && container.alpha > 0.01 && container.isUserInteractionEnabled
        let detachedItem = rendererMode(for: nav) == .systemVertical && (navigationItem == nil || (!customPresented &&
            navigationItem?.titleView == nil &&
            navigationItem?.leftBarButtonItems?.isEmpty != false &&
            navigationItem?.rightBarButtonItems?.isEmpty != false &&
            navigationItem?.title?.isEmpty != false))
        let hasInvalidFrame = [barRect, hostRect, rowRect, leftRect, titleRect, rightRect]
            .contains { !$0.origin.x.isFinite || !$0.origin.y.isFinite || !$0.width.isFinite || !$0.height.isFinite }
        let hasAlignmentIssue = maxMidYDelta > 1.0
            || hasInvalidFrame
            || !windowBounds.contains(barRect)
            || !statusIntersections.isEmpty
            || !reservedIntersections.isEmpty
            || !customInHost
            || (!customPresented && rendererMode(for: nav) == .customHorizontal)
            || detachedItem
        guard hasAlignmentIssue else { return }
        let diagnosticSignature = [
            reason.rawValue,
            String(describing: windowBounds.integral),
            String(describing: barRect.integral),
            String(describing: rowRect.integral),
            String(describing: statusWindowRect?.integral ?? .null),
            String(describing: reservedWindowRects.map(\.integral)),
            rendererMode(for: nav)?.rawValue ?? "unset",
            rendererTransition ?? "none",
            String(customInHost),
            String(customPresented),
            String(describing: navigationItem?.leftBarButtonItems?.count ?? 0),
            String(describing: navigationItem?.rightBarButtonItems?.count ?? 0),
            String(describing: navigationItem?.titleView != nil),
            String(describing: generation)
        ].joined(separator: "|")
        let state = reconciliationState(for: nav)
        guard state.lastDiagnosticSignature != diagnosticSignature else { return }
        state.lastDiagnosticSignature = diagnosticSignature
        PTNSLogConsole("""
        [PTNavDuo]
        reason=\(reason.rawValue) / scene=\(sceneID) / generation=\(generation) / renderer=\(rendererTransition ?? mode)
        window=\(windowBounds)
        bar=\(barRect) / safe=\(nav.navigationBar.safeAreaInsets)
        navView.bounds=\(navigationViewBounds) / navView.safe=\(navigationViewSafeInsets)
        verticalBarEdge=\(verticalBarEdge)
        host=\(hostRect) / safe=\(container.safeAreaInsets)
        container.present=\(customPresented) / hidden=\(container.isHidden) / inHost=\(customInHost) / alpha=\(container.alpha)
        row=\(rowRect) / safe=\(container.topBarContainer.safeAreaInsets)
        left.midY=\(leftRect.midY)
        right.midY=\(rightRect.midY)
        title.midY=\(titleRect.midY)
        row.midY=\(rowMidY) / maxDelta=\(maxMidYDelta)
        row.evidence=\(container.lastContentRowInput?.evidence.rawValue ?? "none")
        title.hidden=\(container.titleContainer.isHidden) / title.superview=\(container.titleContainer.superview != nil)
        itemOwner=\(rendererMode(for: nav)?.rawValue ?? "none") / left=\(navigationItem?.leftBarButtonItems?.count ?? 0) / title=\(navigationItem?.titleView != nil || !(navigationItem?.title?.isEmpty ?? true)) / right=\(navigationItem?.rightBarButtonItems?.count ?? 0)
        statusBar.windowRect=\(statusWindowRect ?? .null) / statusCollision=\(!statusIntersections.isEmpty)
        reserved=\(layoutContext.reservedRegions)
        reservedWindow=\(reservedWindowRects)
        reservedIntersections=\(reservedIntersections)
        statusIntersections=\(statusIntersections) / ptoolsOwnedLeft=\(ownership?.leftItems.count ?? 0) / ptoolsOwnedRight=\(ownership?.rightItems.count ?? 0)
        """)
    }
#endif

#if DEBUG
    // English: Diagnose UIKit-owned navigation items using only public custom-view frames and scene-local exclusions.
    // Español: Diagnostica los elementos de UIKit usando solo frames públicos de vistas personalizadas y exclusiones de la escena.
    // 中文：仅使用公开 customView frame 和当前 Scene 排斥区诊断 UIKit 原生导航项。
    private func dumpNativeNavigationGeometryIfEnabled(nav: UINavigationController,
                                                       reason: PTNavigationReconciliationReason,
                                                       generation: UInt64,
                                                       previousMode: PTNavigationRendererMode?,
                                                       currentMode: PTNavigationRendererMode) {
        guard ProcessInfo.processInfo.environment["PTOOLS_NAVIGATION_GEOMETRY_DEBUG"] == "1",
              let window = nav.viewIfLoaded?.window else { return }

        let navigationItem = nav.visibleViewController?.navigationItem
        let item = nav.visibleViewController.map { item(for: $0) }
        let ownership = nativeOwnershipMap.object(forKey: nav)
        let exclusions = navigationExclusionRects(in: nav, navigationBar: nav.navigationBar)
        let barRect = nav.navigationBar.convert(nav.navigationBar.bounds, to: window)
        let container = containerMap.object(forKey: nav)

        func windowRect(for view: UIView?) -> CGRect? {
            guard let view,
                  view.window === window,
                  !view.bounds.isEmpty else { return nil }
            let converted = view.convert(view.bounds, to: window)
            return converted.isNull || converted.isEmpty ? nil : converted
        }

        let nativeViews = (navigationItem?.leftBarButtonItems ?? []) +
            (navigationItem?.rightBarButtonItems ?? []) +
            (navigationItem?.leadingItemGroups.flatMap(\.barButtonItems) ?? []) +
            (navigationItem?.trailingItemGroups.flatMap(\.barButtonItems) ?? []) +
            (navigationItem?.pinnedTrailingGroup?.barButtonItems ?? [])
        let itemRects = nativeViews.compactMap { windowRect(for: $0.customView) } +
            [windowRect(for: navigationItem?.titleView)].compactMap { $0 }
        let statusIntersections = exclusions.statusWindow.map { statusRect in
            itemRects.compactMap { itemRect in
                let intersection = statusRect.intersection(itemRect)
                return intersection.isNull || intersection.isEmpty ? nil : intersection
            }
        } ?? []
        let reservedIntersections = exclusions.reservedWindow.flatMap { reservedRect in
            itemRects.compactMap { itemRect in
                let intersection = reservedRect.intersection(itemRect)
                return intersection.isNull || intersection.isEmpty ? nil : intersection
            }
        }
        let itemAttached = item.map {
            isNativeItemAttached($0,
                                 navigationController: nav,
                                 viewController: nav.visibleViewController ?? nav)
        } ?? false
        let hasInvalidBar = !barRect.origin.x.isFinite ||
            !barRect.origin.y.isFinite ||
            !barRect.width.isFinite ||
            !barRect.height.isFinite ||
            barRect.isEmpty
        let hasIssue = hasInvalidBar ||
            (item?.isConfigured == true && !itemAttached) ||
            !statusIntersections.isEmpty ||
            !reservedIntersections.isEmpty
        guard hasIssue else { return }

        let signature = [
            reason.rawValue,
            String(describing: barRect.integral),
            String(describing: exclusions.statusWindow?.integral ?? .null),
            String(describing: exclusions.reservedWindow.map(\.integral)),
            previousMode?.rawValue ?? "none",
            currentMode.rawValue,
            String(itemAttached),
            String(describing: itemRects.map(\.integral)),
            String(describing: generation)
        ].joined(separator: "|")
        let state = reconciliationState(for: nav)
        guard state.lastDiagnosticSignature != signature else { return }
        state.lastDiagnosticSignature = signature

        let sceneID = window.windowScene?.session.persistentIdentifier ?? "none"
        PTNSLogConsole("""
        [PTNavDuo]
        reason=\(reason.rawValue) / scene=\(sceneID) / generation=\(generation) / renderer=\(previousMode?.rawValue ?? "none")->\(currentMode.rawValue)
        window=\(window.bounds) / window.safe=\(window.safeAreaInsets)
        nav.bounds=\(nav.viewIfLoaded?.bounds ?? .zero) / nav.safe=\(nav.viewIfLoaded?.safeAreaInsets ?? .zero)
        navBar.windowRect=\(barRect) / hidden=\(nav.navigationBar.isHidden)
        container.present=\(!(container?.isHidden ?? true)) / inHost=\(container?.superview === nav.navigationBar)
        itemOwner=systemVertical / attached=\(itemAttached) / left=\(navigationItem?.leftBarButtonItems?.count ?? 0) / title=\(navigationItem?.titleView != nil || !(navigationItem?.title?.isEmpty ?? true)) / right=\(navigationItem?.rightBarButtonItems?.count ?? 0)
        statusBar.windowRect=\(exclusions.statusWindow ?? .null) / statusCollision=\(!statusIntersections.isEmpty)
        reservedWindowRects=\(exclusions.reservedWindow) / reservedCollision=\(!reservedIntersections.isEmpty)
        itemRects=\(itemRects) / ptoolsOwnedLeft=\(ownership?.leftItems.count ?? 0) / ptoolsOwnedRight=\(ownership?.rightItems.count ?? 0)
        """)
    }
#endif

    // English: Use the previous measured row first, then infer a compact row from the host and large-title area.
    // Español: Usa primero la fila medida anterior y luego infiere la fila compacta desde el host y el título grande.
    // 中文：优先复用上一次实测内容行，再根据宿主和大标题区域推导紧凑行。
    private func compactNavigationRowHeight(in navBar: UINavigationBar,
                                             container: PTNavigationBarContainer) -> CGFloat? {
        let hostHeight = navBar.bounds.height
        let previousHeight = container.lastAppliedContentRect.height
        if previousHeight.isFinite,
           previousHeight > 0,
           previousHeight < hostHeight - 0.5 {
            return previousHeight
        }

        let largeTitleHeight = max(container.largeTitleContentHeightForLayout,
                                   container.largeTitleHeight)
        let inferredHeight = hostHeight - largeTitleHeight
        if inferredHeight > 0, inferredHeight < hostHeight {
            return inferredHeight
        }

        // English: This is only a first-pass compatibility seed; the next host layout replaces it.
        // Español: Esta es solo una semilla de compatibilidad inicial; el siguiente layout del host la reemplaza.
        // 中文：这只是首次布局的兼容种子，下一次宿主布局会用实测值替换。
        let seed = min(hostHeight, CGFloat.kNavBarHeight)
        return seed > 0 ? seed : nil
    }

    private func ensureCustomContainer(in nav: UINavigationController) -> PTNavigationBarContainer? {
        let navBar = nav.navigationBar
        guard !navBar.bounds.isEmpty,
              navBar.bounds.width.isFinite,
              navBar.bounds.height.isFinite else {
            navBar.setNeedsLayout()
            return nil
        }
        if let existingContainer = containerMap.object(forKey: nav) {
            existingContainer.bind(to: nav)
            return existingContainer
        }

        resetSystemNavBarAppearance(nav)
        let container = PTNavigationBarContainer(frame: navBar.bounds)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.bind(to: nav)
        container.titleLayoutUpdateHandler = { [weak self, weak nav, weak container] in
            guard let self, let nav, let container else { return }
            self.refreshTitleLayout(in: nav, container: container)
        }
        navBar.addSubview(container)
        navBar.sendSubviewToBack(container)
        containerMap.setObject(container, forKey: nav)
        return container
    }

    private func navigationGeometrySignature(for nav: UINavigationController,
                                             container: PTNavigationBarContainer?) -> String {
        let window = nav.viewIfLoaded?.window
        let sceneID = window?.windowScene?.session.persistentIdentifier ?? "none"
        let windowDescription = window.map { "\($0.bounds.integral)|\($0.safeAreaInsets)" } ?? "none"
        let navigationDescription = "\(nav.viewIfLoaded?.bounds.integral ?? .zero)|\(nav.viewIfLoaded?.safeAreaInsets ?? .zero)"
        let bar = nav.navigationBar
        let barDescription = "\(bar.frame.integral)|\(bar.bounds.integral)|\(bar.safeAreaInsets)"
        let containerDescription = container.map { "\($0.frame.integral)|\($0.isHidden)|\($0.alpha)" } ?? "none"
        let edge: String = {
            guard #available(iOS 27.1, *) else { return "unavailable" }
            switch nav.viewIfLoaded?.traitCollection.verticalBarEdge {
            case .leading: return "leading"
            case .trailing: return "trailing"
            default: return "unspecified"
            }
        }()
        return [sceneID,
                windowDescription,
                navigationDescription,
                barDescription,
                containerDescription,
                edge,
                String(describing: ObjectIdentifier(nav.visibleViewController ?? nav))].joined(separator: "|")
    }

    private func isNativeItemAttached(_ item: PTNavBarItem,
                                      navigationController: UINavigationController,
                                      viewController: UIViewController) -> Bool {
        let navigationItem = viewController.navigationItem
        let ownership = navigationOwnership(for: navigationController)
        guard ownership.viewController === viewController else { return false }
        let leftAttached: Bool
        if item.leftView.isEmpty {
            leftAttached = ownership.leftItems.isEmpty && ownership.leadingGroups.isEmpty
        } else {
            leftAttached = item.leftView.count == ownership.leftItems.count &&
                ownership.leftItems.allSatisfy { owned in
                    navigationItem.leftBarButtonItems?.contains(where: { $0 === owned }) == true ||
                    navigationItem.leadingItemGroups.contains(where: { $0.barButtonItems.contains(where: { $0 === owned }) })
                }
        }
        let rightAttached: Bool
        if item.rightViews.isEmpty {
            rightAttached = ownership.rightItems.isEmpty &&
                ownership.trailingGroups.isEmpty &&
                ownership.pinnedTrailingGroup == nil
        } else {
            rightAttached = item.rightViews.count == ownership.rightItems.count &&
                ownership.rightItems.allSatisfy { owned in
                    navigationItem.rightBarButtonItems?.contains(where: { $0 === owned }) == true ||
                    navigationItem.trailingItemGroups.contains(where: { group in
                        group.barButtonItems.contains(where: { $0 === owned })
                    }) ||
                    navigationItem.pinnedTrailingGroup?.barButtonItems.contains(where: { $0 === owned }) == true
                }
        }
        let titleAttached: Bool
        if let titleView = item.titleView {
            titleAttached = navigationItem.titleView === titleView
        } else {
            let expectedTitle = item.navTitle.isEmpty ? viewController.title : item.navTitle
            titleAttached = ownership.titleView == nil &&
                (expectedTitle == nil || navigationItem.title == expectedTitle)
        }
        return leftAttached && rightAttached && titleAttached
    }

    private func isCustomItemAttached(_ item: PTNavBarItem,
                                      container: PTNavigationBarContainer,
                                      navigationController: UINavigationController) -> Bool {
        let leftAttached = container.leftContainer.arrangedSubviews.count == item.leftView.count &&
            zip(container.leftContainer.arrangedSubviews, item.leftView).allSatisfy { arrangedView, itemView in
                arrangedView === itemView
            }
        let rightAttached = container.rightContainer.arrangedSubviews.count == item.rightViews.count &&
            zip(container.rightContainer.arrangedSubviews, item.rightViews).allSatisfy { arrangedView, itemView in
                arrangedView === itemView
            }
        let titleAttached: Bool
        if let titleView = item.titleView {
            titleAttached = container.titleContainer.subviews.first === titleView
        } else {
            titleAttached = item.navTitle.isEmpty
                ? container.titleContainer.subviews.isEmpty
                : !container.titleContainer.subviews.isEmpty
        }
        return container.superview === navigationController.navigationBar &&
            !container.isHidden && leftAttached && rightAttached && titleAttached
    }

    // English: Reconcile renderer ownership, item attachment, and content-row geometry in one idempotent pass.
    // Español: Reconcilia la propiedad del renderizador, los elementos y la fila geométrica en una pasada idempotente.
    // 中文：在一次幂等流程中收敛渲染器所有权、导航项挂载和内容行几何。
    @discardableResult
    func reconcileNavigationBar(in nav: UINavigationController,
                               reason: PTNavigationReconciliationReason) -> Bool {
        let state = reconciliationState(for: nav)
        if state.isReconciling {
            state.pendingReason = reason
            return false
        }

        let transitionActive = transitionStates.object(forKey: nav)?.coordinator != nil ||
            nav.transitionCoordinator != nil
        if transitionActive && reason != .transitionCompleted && reason != .didShow {
            state.pendingReason = reason
            return false
        }

        state.isReconciling = true
        let previousMode = rendererMode(for: nav)
        defer {
            state.isReconciling = false
            if let pendingReason = state.pendingReason,
               pendingReason != reason,
               !state.pendingReconciliationScheduled {
                state.pendingReason = nil
                state.pendingReconciliationScheduled = true
                // English: Drain re-entrant layout callbacks on the next MainActor turn instead of recursing synchronously.
                // Español: Drena los callbacks de layout reentrantes en el siguiente turno de MainActor para evitar recursión síncrona.
                // 中文：将重入的布局回调延后到下一次 MainActor 执行，避免同步递归。
                Task { @MainActor [weak self, weak nav] in
                    guard let self, let nav else { return }
                    let pendingState = self.reconciliationState(for: nav)
                    pendingState.pendingReconciliationScheduled = false
                    _ = self.reconcileNavigationBar(in: nav, reason: pendingReason)
                }
            } else if state.pendingReason == reason {
                state.pendingReason = nil
            }
        }

        guard let viewController = nav.visibleViewController ?? nav.topViewController else {
            applyAdaptiveSystemPolicy(to: nav)
            return false
        }
        if let configurable = viewController as? PTNavigationConfigurable,
           !configurable.allowControlNavBar() {
            return false
        }
        if let baseViewController = viewController as? PTBaseViewController {
            baseViewController.prepareDefaultNavigationBarItem()
        }

        let item = itemCache.object(forKey: viewController) ?? item(for: viewController)
        let useSystemRenderer = usesNativeVerticalBar(nav)
        let targetMode: PTNavigationRendererMode = useSystemRenderer ? .systemVertical : .customHorizontal
        let existingContainer = containerMap.object(forKey: nav)
        let geometrySignature = navigationGeometrySignature(for: nav, container: existingContainer)
        let geometryChanged = state.lastGeometrySignature != geometrySignature
        let itemAttached = useSystemRenderer
            ? isNativeItemAttached(item, navigationController: nav, viewController: viewController)
            : (existingContainer.map {
                isCustomItemAttached(item, container: $0, navigationController: nav)
            } ?? false)
        let decision = PTNavigationRendererReconciliationPlanner.decision(for: PTNavigationRendererReconciliationInput(
            currentMode: rendererMode(for: nav),
            targetMode: targetMode,
            itemAttached: itemAttached,
            geometryChanged: geometryChanged,
            transitionActive: false
        ))
        guard decision == .reconcile else {
            if state.pendingReason == reason { state.pendingReason = nil }
            return true
        }

        state.generation &+= 1
        transitionRendererIfNeeded(in: nav, useSystemRenderer: useSystemRenderer)
        if useSystemRenderer {
            if let container = existingContainer {
                container.clearTitleLayout()
                setCustomContainer(container, visible: false)
            }
            applyNativeItem(item, in: nav, viewController: viewController)
            applyAdaptiveSystemPolicy(to: nav)
            setRendererMode(.systemVertical, for: nav)
#if DEBUG
            dumpNativeNavigationGeometryIfEnabled(nav: nav,
                                                  reason: reason,
                                                  generation: state.generation,
                                                  previousMode: previousMode,
                                                  currentMode: .systemVertical)
#endif
        } else {
            guard let container = ensureCustomContainer(in: nav) else {
                state.pendingReason = reason
                return false
            }
            clearNativeNavigationItem(in: nav)
            setCustomContainer(container, visible: true)
            if PTNavigationGlassCompatibility.requiresWorkaround {
                resetSystemNavBarAppearance(nav)
            }
            let style = item.isConfigured ? item.barColorStyle : (styleCache.object(forKey: nav)?.style ?? .default)
            container.apply(style: style)
            apply(item: item, in: nav, viewController: viewController)
            refreshNavigationContentRow(in: nav,
                                        container: container,
                                        reason: reason,
                                        generation: state.generation,
                                        rendererTransition: rendererTransitionDescription(from: previousMode,
                                                                                          to: .customHorizontal))
            setRendererMode(.customHorizontal, for: nav)
        }
        state.lastGeometrySignature = navigationGeometrySignature(for: nav,
                                                                   container: containerMap.object(forKey: nav))
        if state.pendingReason == reason { state.pendingReason = nil }
        rememberCurrent(nav, viewController: viewController)
        StatusBarManager.shared.update(with: item.barColorStyle)
        viewController.setNeedsStatusBarAppearanceUpdate()
        nav.setNeedsStatusBarAppearanceUpdate()
        return true
    }

    // English: Refresh geometry without reinstalling a second container or losing the current item owner.
    // Español: Actualiza la geometría sin instalar otro contenedor ni perder el propietario actual.
    // 中文：只刷新当前几何，不重复安装容器，也不丢失当前导航项所有权。
    func refreshGeometry(in nav: UINavigationController) {
        _ = reconcileNavigationBar(in: nav, reason: .geometryRefresh)
    }

    public func installIfNeeded(in nav: UINavigationController) {
        bind(to: nav)
        _ = reconcileNavigationBar(in: nav, reason: .initialInstall)
    }
    
    public func apply(style: PTNavigationBarStyle, in nav: UINavigationController) {
        styleCache.setObject(NavigationStyleBox(style: style), forKey: nav)
        if let viewController = nav.visibleViewController ?? nav.topViewController {
            let item = item(for: viewController)
            item.barColorStyle = style
        }
        _ = reconcileNavigationBar(in: nav, reason: .styleUpdate)
    }

    // English: Remember the active navigation stack for its scene without retaining either UIKit object.
    // Español: Recuerda la pila de navegación activa de su escena sin retener los objetos de UIKit.
    // 中文：按场景记录当前导航栈，且不强引用 UIKit 对象。
    private func rememberCurrent(_ navigationController: UINavigationController,
                                 viewController: UIViewController?) {
        currentNav = navigationController
        currentVC = viewController
        guard let scene = PTSceneContext.windowScene(for: navigationController)
                ?? PTSceneContext.windowScene(for: viewController) else { return }
        let sceneID = scene.session.persistentIdentifier
        navigationContextsBySceneID[sceneID] = NavigationContextBox(navigationController: navigationController,
                                                                       viewController: viewController)
    }

    // English: Update the active stack without replacing the stable controller during an interactive transition.
    // Español: Actualiza la pila activa sin reemplazar el controlador estable durante una transición interactiva.
    // 中文：只更新当前导航栈，不在交互式转场期间提前替换稳定的控制器。
    private func rememberNavigationController(_ navigationController: UINavigationController) {
        currentNav = navigationController
        guard let scene = PTSceneContext.windowScene(for: navigationController) else { return }
        let sceneID = scene.session.persistentIdentifier
        let currentSceneController = navigationContextsBySceneID[sceneID]?.viewController
        navigationContextsBySceneID[sceneID] = NavigationContextBox(navigationController: navigationController,
                                                                       viewController: currentSceneController)
    }

    // English: Expose a scene-scoped lookup for new callers while preserving existing global convenience APIs.
    // Español: Expone una búsqueda por escena para los nuevos llamadores y conserva las APIs globales existentes.
    // 中文：为新调用方提供按场景查询，同时保留现有全局便捷 API。
    public func currentNavigationController(in scene: UIWindowScene) -> UINavigationController? {
        let sceneID = scene.session.persistentIdentifier
        guard let context = navigationContextsBySceneID[sceneID],
              let navigationController = context.navigationController else {
            navigationContextsBySceneID.removeValue(forKey: sceneID)
            return nil
        }
        return navigationController
    }

    public func currentViewController(in scene: UIWindowScene) -> UIViewController? {
        let sceneID = scene.session.persistentIdentifier
        guard let context = navigationContextsBySceneID[sceneID],
              let viewController = context.viewController else {
            navigationContextsBySceneID.removeValue(forKey: sceneID)
            return nil
        }
        return viewController
    }
    
    private func resetSystemNavBarAppearance(_ nav: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil   // ❗关键（去 blur）
        // English: The custom container owns the full navigation background, including the status-bar area.
        // Español: El contenedor personalizado controla todo el fondo de navegación, incluida el área de la barra de estado.
        // 中文：自定义容器负责包含状态栏区域在内的完整导航背景。
        appearance.backgroundColor = .clear
        appearance.backgroundImage = nil
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        appearance.titleTextAttributes = [
            .font: PTAppBaseConfig.share.navTitleFont,
            .foregroundColor: PTAppBaseConfig.share.navTitleTextColor
        ]
        appearance.largeTitleTextAttributes = [
            .font: PTAppBaseConfig.share.navLargeTitleFont,
            .foregroundColor: PTAppBaseConfig.share.navTitleTextColor
        ]
        
        nav.navigationBar.compactScrollEdgeAppearance = appearance
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
        
        // 🔥 关键：关闭系统 blur
        // English: Clear both legacy and appearance-based UIKit surfaces so a clear style reveals the page below.
        // Español: Limpia las superficies UIKit antiguas y basadas en apariencia para que el estilo transparente muestre la página inferior.
        // 中文：同时清理 UIKit 旧式和 Appearance 背景，确保透明样式能够显示页面内容。
        nav.navigationBar.backgroundColor = .clear
        nav.navigationBar.barTintColor = .clear
        nav.navigationBar.isTranslucent = true
        
        // English: Keep the navigation-controller backing transparent so a clear style reveals the child view.
        // Español: Mantiene transparente el fondo del controlador de navegación para que un estilo claro muestre la vista hija.
        // 中文：保持导航控制器的底层背景透明，让 clear 样式能够显示子控制器内容。
        nav.view.backgroundColor = .clear
    }
    
    public func setAlpha(_ alpha: CGFloat) {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
        container.setBackgroundAlpha(alpha)
    }
    
    public func bind(to nav: UINavigationController) {
        if let proxy = delegateProxyMap.object(forKey: nav) {
            if nav.delegate !== proxy {
                if nav.delegate !== self {
                    proxy.hostDelegate = nav.delegate
                }
                nav.delegate = proxy
            }
            applyAdaptiveSystemPolicy(to: nav)
            return
        }

        let hostDelegate = nav.delegate === self ? nil : nav.delegate
        let proxy = PTNavigationDelegateProxy(manager: self, hostDelegate: hostDelegate)
        delegateProxyMap.setObject(proxy, forKey: nav)
        nav.delegate = proxy
        applyAdaptiveSystemPolicy(to: nav)
    }

    // English: Keep UIKit vertical-bar behavior aligned with the navigation stack policy.
    // Español: Mantiene el comportamiento de la barra vertical de UIKit alineado con la política de la pila.
    // 中文：让 UIKit 垂直 Bar 行为与当前导航栈策略保持一致。
    private func applyAdaptiveSystemPolicy(to nav: UINavigationController) {
        let policy = (nav as? PTBaseNavControl)?.adaptiveBarPresentationPolicy
            ?? PTAppBaseConfig.share.adaptiveBarPresentationPolicy
        PTAdaptiveSystemBarBridge.apply(policy: policy, to: nav)
    }

    func setTabBarHandler(_ handler: @escaping (UINavigationController, UIViewController, Bool, UIViewControllerTransitionCoordinator?) -> Void,
                          for nav: UINavigationController) {
        tabBarHandlerCache.setObject(TabBarHandlerBox(handler: handler), forKey: nav)
    }

    func removeTabBarHandler(for nav: UINavigationController) {
        tabBarHandlerCache.removeObject(forKey: nav)
    }
    
    public func item(for vc: UIViewController) -> PTNavBarItem {
        if let item = itemCache.object(forKey: vc) {
            return item
        }
        let newItem = PTNavBarItem()
        itemCache.setObject(newItem, forKey: vc)
        return newItem
    }

    public func update(item: PTNavBarItem, for vc: UIViewController) {
        item.isConfigured = true
        itemCache.setObject(item, forKey: vc)
        
        // 如果当前正在显示，立即刷新
        if vc === currentVC {
            if let nav = vc.navigationController {
                _ = reconcileNavigationBar(in: nav, reason: .itemUpdate)
            }
        }
    }
    
    /// 获取真实导航栏几何。
    /// - Returns: 未关联窗口、导航栏隐藏或无法有效测量时返回 nil。
    public func navigationGeometry(in navigationController: UINavigationController) -> PTNavigationBarGeometry? {

        guard navigationController.isViewLoaded,
              let window = navigationController.view.window,
              let scene = window.windowScene,
              !navigationController.isNavigationBarHidden,
              !usesNativeVerticalBar(navigationController) else {
            return nil
        }

        let bar = navigationController.navigationBar

        guard bar.window === window,
              !bar.isHidden,
              !bar.bounds.isEmpty else {
            return nil
        }

        let frame = bar.convert(bar.bounds,to: window)

        guard frame.minY.isFinite,
              frame.maxY.isFinite,
              frame.width.isFinite,
              frame.height.isFinite,
              frame.width > 0,
              frame.height > 0,
              frame.maxY > 0,
              frame.maxY <= window.bounds.height + 1 else {
            return nil
        }

        let statusHeight = scene.statusBarManager?.statusBarFrame.height ?? window.safeAreaInsets.top

        return PTNavigationBarGeometry(statusBarHeight: statusHeight, navigationBarFrameInWindow: frame)
    }
    
    public func measuredNavigationTopInset(in targetView: UIView, navigationController: UINavigationController) -> CGFloat? {

        let targetWindow =
            (targetView as? UIWindow) ?? targetView.window

        guard let targetWindow,
              navigationController.viewIfLoaded?.window
                  === targetWindow,
              navigationGeometry(
                  in: navigationController
              ) != nil else {
            return nil
        }

        let bar = navigationController.navigationBar

        let frame = bar.convert(bar.bounds, to: targetView)

        guard frame.maxY.isFinite else {
            return nil
        }
        return max(0, frame.maxY)
    }
    
    
    // MARK: - Navigation Controller Resolution
    /// 从指定 UIWindow 查找当前可见的导航控制器。
    /// 优先解析实际的 ViewController 层级，
    /// 避免 Scene 导航栈尚未完成登记时直接失败。
    func navigationControllerForTotalHeight(in window: UIWindow) -> UINavigationController? {

        // 1. 优先解析实际可见的控制器层级
        if let nav = Self.visibleNavigationController(
            from: window.rootViewController
        ), nav.viewIfLoaded?.window === window {
            return nav
        }

        // 2. 兼容 PTNavigationBarManager 已登记的 Scene
        if let scene = window.windowScene,
           let nav = currentNavigationController(in: scene),
           nav.viewIfLoaded?.window === window {
            return nav
        }

        return nil
    }

    /// 查找当前可见 UINavigationController
    private static func visibleNavigationController(from root: UIViewController?) -> UINavigationController? {

        var current = root
        var visited = Set<ObjectIdentifier>()

        while let controller = current {

            guard visited.insert(
                ObjectIdentifier(controller)
            ).inserted else {
                return nil
            }

            // 优先处理模态展示
            if let presented = controller.presentedViewController,
               !presented.isBeingDismissed {
                current = presented
                continue
            }

            // UITabBarController
            if let tab = controller as? UITabBarController {
                current = tab.selectedViewController
                continue
            }

            // UISplitViewController
            if let split = controller as? UISplitViewController {
                current = split.viewControllers.last
                continue
            }

            // UINavigationController
            if let nav = controller as? UINavigationController {

                // 导航页面内部可能继续 present
                if let presented = nav.visibleViewController?.presentedViewController, !presented.isBeingDismissed {
                    current = presented
                    continue
                }

                return nav
            }

            return controller.navigationController
        }

        return nil
    }

}

extension PTNavigationBarManager {
    func updateScrollProgress(_ progress: CGFloat) {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
        container.updateLargeTitle(progress: progress)
    }
    
    public func currentNavLargeTitleBarHeight() -> CGFloat {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return 0 }
        container.layoutIfNeeded()
        return container.largeTitleContainer.frame.height
    }
    
    public func currentNavBarHeight() -> CGFloat {
        guard let _ = currentNav else { return 0 }
        
        let status = CGFloat.statusBarHeight()
        let navBar: CGFloat = CGFloat.kNavBarHeight
        
        return status + navBar + currentNavLargeTitleBarHeight()
    }

    // English: Expose the measured custom content-row height without changing the legacy total-height API.
    // Español: Expone la altura medida de la fila personalizada sin cambiar la API heredada de altura total.
    // 中文：提供实测自定义内容行高度，同时不改变旧的总高度 API 语义。
    public func currentNavigationContentHeight(in navigationController: UINavigationController? = nil) -> CGFloat {
        let nav = navigationController ?? currentNav
        guard let nav,
              let container = containerMap.object(forKey: nav) else { return 0 }
        refreshNavigationContentRow(in: nav, container: container)
        nav.navigationBar.layoutIfNeeded()
        container.layoutIfNeeded()
        return container.topBarContainer.bounds.height
    }

    // English: Convert the live navigation-bar bottom into a target view's coordinates instead of using a global estimate.
    // Español: Convierte el borde inferior real de la barra al sistema de coordenadas de la vista destino, sin usar una estimación global.
    // 中文：将实时导航栏底部转换到目标 View 坐标系，避免使用全局估算值。
    public func currentNavigationTopInset(in view: UIView,
                                          navigationController: UINavigationController? = nil) -> CGFloat {

        if let nav = navigationController ?? currentNav,
           let measured = measuredNavigationTopInset(in: view, navigationController: nav) {
            return measured
        }

        return max(0, view.safeAreaInsets.top)
    }
}

extension PTNavigationBarManager: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                         willShow viewController: UIViewController,
                                         animated: Bool) {
        if let configurable = viewController as? PTNavigationConfigurable,
           !configurable.allowControlNavBar() {
            return
        }
        
        installIfNeeded(in: navigationController)
        rememberNavigationController(navigationController)
        refreshGeometry(in: navigationController)

        let toStyle: PTNavigationBarStyle
        if let configurable = viewController as? PTNavigationConfigurable {
            toStyle = configurable.preferredNavigationBarStyle()
            let item = self.item(for: viewController)
            item.barColorStyle = toStyle
        } else {
            toStyle = .default
        }

        // English: Prepare the default back item before either UIKit or the custom renderer reads the cached item.
        // Español: Prepara el elemento de retroceso predeterminado antes de que UIKit o el renderizador personalizado lean la caché.
        // 中文：在 UIKit 或自定义渲染器读取缓存项之前，先准备默认返回按钮。
        if let baseVC = viewController as? PTBaseViewController {
            baseVC.prepareDefaultNavigationBarItem()
        }
        let item = itemCache.object(forKey: viewController) ?? PTNavBarItem()

        if usesNativeVerticalBar(navigationController) {
            // English: Let the shared reconciliation pass decide when the final visible controller owns UIKit's bar.
            // Español: Deja que la reconciliación compartida decida cuándo el controlador visible final posee la barra de UIKit.
            // 中文：由统一收敛流程决定最终可见控制器何时接管 UIKit 导航栏。
            _ = reconcileNavigationBar(in: navigationController, reason: .willShow)
            StatusBarManager.shared.update(with: toStyle)
            if let handler = tabBarHandlerCache.object(forKey: navigationController)?.handler {
                handler(navigationController, viewController, animated, navigationController.transitionCoordinator)
            } else {
                tabBarHandler?(navigationController, viewController, animated, navigationController.transitionCoordinator)
            }
            return
        }

        resetSystemNavBarAppearance(navigationController)

        guard let container = containerMap.object(forKey: navigationController) else { return }

        StatusBarManager.shared.update(with: toStyle)
        
        let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from)
        let fromStyle = (fromVC as? PTNavigationConfigurable)?.preferredNavigationBarStyle() ?? .transparent

        // English: Mark the stack as transitioning before changing the visible item set.
        // Español: Marca la pila como en transición antes de cambiar sus elementos visibles.
        // 中文：切换可见导航项前，先将导航栈标记为转场中。
        setRendererMode(.transitioning, for: navigationController)

        // English: Seed the transition from the current style before UIKit starts moving views.
        // Español: Inicializa la transición desde el estilo actual antes de que UIKit mueva las vistas.
        // 中文：在 UIKit 移动视图前，先用当前样式设置转场起点。
        container.prepareTransition(from: fromStyle, to: toStyle)
        // 🌟 判断这是否是导航栈的“根视图”（代表是新 Present 出来的）
        let isRoot = navigationController.viewControllers.first == viewController

        if isRoot {
            // 💡 这是 Present 出来的根视图！
            // 整个 NavController 正在被系统整体推上来（Slide Up）。
            container.apply(style: toStyle)
            self.apply(item: item, in: navigationController, viewController: viewController)
            setRendererMode(.customHorizontal, for: navigationController)
            if let vc = viewController as? PTBaseViewController {
                vc.setNeedsStatusBarAppearanceUpdate()
            }
            stopTransition(for: navigationController)
        } else {
            // 💡 这是 Push / Pop 动作，正常执行我们完美的过渡动画
            let activeCoordinator = navigationController.transitionCoordinator ?? viewController.transitionCoordinator
            
            if let coordinator = activeCoordinator {
                setTransitionState(for: navigationController,
                                   coordinator: coordinator,
                                   container: container)
                
                if coordinator.isInteractive {
                    startDisplayLink()
                    coordinator.animate(alongsideTransition: { _ in
                    }, completion: { context in
                        self.stopTransition(for: navigationController)
                        self.finishTransition(context: context, container: container, fromStyle: fromStyle, toStyle: toStyle, fromVC: fromVC, toVC: viewController)
                    })
                } else {
                    coordinator.animate(alongsideTransition: { context in
                        container.updateTransition(progress: 1)
                        UIView.transition(with: container.topBarContainer,
                                          duration: PTUIAccessibility.animationDuration(context.transitionDuration),
                                          options: .transitionCrossDissolve,
                                          animations: {
                            self.apply(item: item, in: navigationController, viewController: viewController)
                        }, completion: nil)
                    }, completion: { context in
                        self.stopTransition(for: navigationController)
                        self.finishTransition(context: context, container: container, fromStyle: fromStyle, toStyle: toStyle, fromVC: fromVC, toVC: viewController)
                    })
                }
                
                coordinator.notifyWhenInteractionChanges { context in
                    if context.isCancelled {
                        StatusBarManager.shared.update(with: fromStyle)
                        fromVC?.setNeedsStatusBarAppearanceUpdate()
                        container.apply(style: fromStyle)
                    }
                }
            } else {
                stopTransition(for: navigationController)
                // English: Complete the no-coordinator path without leaving a transitioning renderer behind.
                // Español: Completa la ruta sin coordinador sin dejar el renderizador en transición.
                // 中文：无转场协调器时也要完成状态收敛，不能遗留 transitioning 状态。
                if animated {
                    UIView.animate(withDuration: PTUIAccessibility.animationDuration(0.25)) {
                        container.apply(style: toStyle)
                    }
                    UIView.transition(with: container.topBarContainer,
                                      duration: PTUIAccessibility.animationDuration(0.25),
                                      options: .transitionCrossDissolve,
                                      animations: {
                        self.apply(item: item, in: navigationController, viewController: viewController)
                    }, completion: { _ in
                        if let vc = viewController as? PTBaseViewController {
                            vc.setNeedsStatusBarAppearanceUpdate()
                        }
                    })
                } else {
                    container.apply(style: toStyle)
                    self.apply(item: item, in: navigationController, viewController: viewController)
                    if let vc = viewController as? PTBaseViewController {
                        vc.setNeedsStatusBarAppearanceUpdate()
                    }
                }
                setRendererMode(.customHorizontal, for: navigationController)
            }
        }

        if let handler = tabBarHandlerCache.object(forKey: navigationController)?.handler {
            handler(navigationController, viewController, animated, navigationController.transitionCoordinator)
        } else {
            tabBarHandler?(navigationController, viewController, animated, navigationController.transitionCoordinator)
        }

        let isPresentedRoot = usesNativeVerticalBar(navigationController) &&
            navigationController.viewControllers.first === viewController &&
            (navigationController.presentingViewController != nil ||
             viewController.presentingViewController != nil ||
             navigationController.isBeingPresented ||
             viewController.isBeingPresented)
        viewController.navigationItem.hidesBackButton = !(isPresentedRoot && item.usesFrameworkDefaultBackAction)
        viewController.title = nil
        viewController.navigationItem.titleView = nil
    }

    // English: Commit the final navigation-bar state from the controller UIKit actually displayed.
    // Español: Confirma el estado final de la barra usando el controlador que UIKit realmente mostró.
    // 中文：根据 UIKit 实际显示的控制器提交最终导航栏状态。
    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        if let configurable = viewController as? PTNavigationConfigurable,
           !configurable.allowControlNavBar() {
            return
        }

        stopTransition(for: navigationController)

        let style: PTNavigationBarStyle
        if let configurable = viewController as? PTNavigationConfigurable {
            style = configurable.preferredNavigationBarStyle()
            let item = item(for: viewController)
            item.barColorStyle = style
        } else {
            style = .default
        }

        // English: Prefer UIKit's didShow callback over a transient navigation-stack snapshot.
        // Español: Da prioridad al callback didShow de UIKit sobre una instantánea transitoria de la pila.
        // 中文：优先使用 UIKit 的 didShow 回调，避免被转场瞬间的导航栈快照覆盖。
        rememberCurrent(navigationController, viewController: viewController)
        _ = reconcileNavigationBar(in: navigationController, reason: .didShow)
        StatusBarManager.shared.update(with: style)
        viewController.setNeedsStatusBarAppearanceUpdate()
        navigationController.setNeedsStatusBarAppearanceUpdate()
    }
    
    // 🌟 新增的辅助方法：提取转场完成后的状态重置逻辑，保持代码清晰
    private func finishTransition(context: UIViewControllerTransitionCoordinatorContext,
                                  container: PTNavigationBarContainer,
                                  fromStyle: PTNavigationBarStyle,
                                  toStyle: PTNavigationBarStyle,
                                  fromVC: UIViewController?,
                                  toVC: UIViewController) {
        if context.isCancelled {
            StatusBarManager.shared.update(with: fromStyle)
            fromVC?.setNeedsStatusBarAppearanceUpdate()
            container.apply(style: fromStyle)
        } else {
            container.apply(style: toStyle)
            StatusBarManager.shared.update(with: toStyle)
            toVC.setNeedsStatusBarAppearanceUpdate()
            toVC.navigationController?.setNeedsStatusBarAppearanceUpdate()
        }
        if let navigationController = toVC.navigationController {
            setRendererMode(.customHorizontal, for: navigationController)
            _ = reconcileNavigationBar(in: navigationController, reason: .transitionCompleted)
        }
    }

    private func apply(item: PTNavBarItem) {
        guard let nav = currentNav, let vc = currentVC else { return }
        apply(item: item, in: nav, viewController: vc)
    }

    // English: Apply every item to the navigation controller that owns the transition callback.
    // Español: Aplica cada elemento al controlador de navegación dueño del callback de transición.
    // 中文：将整套导航栏项目应用到触发当前转场回调的导航控制器。
    private func apply(item: PTNavBarItem,
                       in navigationController: UINavigationController,
                       viewController: UIViewController) {
        if usesNativeVerticalBar(navigationController) {
            applyNativeItem(item, in: navigationController, viewController: viewController)
            return
        }

        if PTNavigationGlassCompatibility.requiresWorkaround {
            let navigationItem = viewController.navigationItem

            navigationItem.hidesBackButton = true

            // 仅清理已由 PTools 自定义视图接管的位置
            if !item.leftView.isEmpty {
                navigationItem.leftBarButtonItems = nil
                navigationItem.leadingItemGroups = []
            }

            if !item.rightViews.isEmpty {
                navigationItem.rightBarButtonItems = nil
                navigationItem.trailingItemGroups = []
            }
        }
        
        setLeftView(item.leftView, spacing: item.leftItemSpacing, in: navigationController)
        setRightViews(item.rightViews, spacing: item.rightItemSpacing, in: navigationController)
        if let findTitleView = item.titleView {
            titleLabel = false
            setTitleView(findTitleView, fillSpace: item.titleViewFillSpace, in: navigationController)
        } else if !item.navTitle.stringIsEmpty() {
            titleLabel = true
            let titleLabel = UILabel()
            PTUIAccessibility.applyDynamicType(to: titleLabel,
                                               font: PTAppBaseConfig.share.navTitleFont)
            titleLabel.textColor = PTAppBaseConfig.share.navTitleTextColor
            titleLabel.numberOfLines = 1
            titleLabel.lineBreakMode = .byTruncatingTail // 👈 增加这句，确保过长显示为 ...
            titleLabel.text = item.navTitle
            titleLabel.textAlignment = .center
            titleLabel.clipsToBounds = true
            setTitleView(titleLabel, fillSpace: false, in: navigationController)
        } else {
            titleLabel = false
            setTitleView(nil, fillSpace: false, in: navigationController)
        }
        
        // ===== LargeTitle 逻辑（🔥重点）=====
        guard let container = containerMap.object(forKey: navigationController),
              let configurable = viewController as? PTNavigationConfigurable else { return }

        let isLarge = configurable.prefersLargeTitle()
        let hasTitle = !item.navTitle.stringIsEmpty()

        if isLarge && hasTitle {
            container.setLargeTitleBackgroundVisible(true)
            
            container.largeTitleContainer.snp.updateConstraints { make in
                make.height.equalTo(container.largeTitleHeight)
            }
            
            container.largeTitleLabel.text = item.navTitle
            container.largeTitleLabel.isHidden = false
            
            container.largeTitleLabel.alpha = 1
            container.largeTitleLabel.transform = .identity
            
            container.titleContainer.alpha = 0

        } else {
            // ❗关键：彻底关闭 largeTitle
            container.setLargeTitleBackgroundVisible(false)
            
            container.largeTitleContainer.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            
            container.largeTitleLabel.text = nil
            container.largeTitleLabel.isHidden = true
            container.largeTitleLabel.alpha = 0
            container.largeTitleLabel.transform = .identity
            
            container.titleContainer.alpha = 1
        }

        container.rerenderCurrentStyle()
    }

    // English: Preserve the public navigation-item content when UIKit owns the vertical bar.
    // Español: Conserva el contenido público del elemento de navegación cuando UIKit controla la barra vertical.
    // 中文：当 UIKit 独占垂直导航栏时，继续保留公开导航项内容。
    private func applyNativeItem(_ item: PTNavBarItem,
                                 in navigationController: UINavigationController,
                                 viewController: UIViewController) {
        // English: Release the custom title owner before UIKit takes the same view for its native titleView.
        // Español: Libera el propietario del título personalizado antes de que UIKit use la misma vista nativa.
        // 中文：UIKit 接管原生 titleView 前，先释放自定义标题容器的布局所有权。
        containerMap.object(forKey: navigationController)?.clearTitleLayout()
        let navigationItem = viewController.navigationItem
        let ownership = navigationOwnership(for: navigationController)
        let previousOwner = ownership.viewController
        if let previousOwner, previousOwner !== viewController {
            detachOwnedNativeContent(from: previousOwner.navigationItem,
                                     ownership: ownership)
        }
        detachOwnedNativeContent(from: navigationItem, ownership: ownership)
        let existingLeftItems = navigationItem.leftBarButtonItems ??
            navigationItem.leftBarButtonItem.map { [$0] } ?? []
        let existingRightItems = navigationItem.rightBarButtonItems ??
            navigationItem.rightBarButtonItem.map { [$0] } ?? []
        let existingLeadingGroups = navigationItem.leadingItemGroups
        let existingTrailingGroups = navigationItem.trailingItemGroups
        let existingPinnedTrailingGroup = navigationItem.pinnedTrailingGroup
        let isPresentedRoot = navigationController.viewControllers.first === viewController &&
            (navigationController.presentingViewController != nil ||
             viewController.presentingViewController != nil ||
             navigationController.isBeingPresented ||
             viewController.isBeingPresented)

        if isPresentedRoot, item.usesFrameworkDefaultBackAction, #available(iOS 16.0, *) {
            // English: A presented root has no natural stack back item, so expose UIKit's synthesized system back action.
            // Español: Una raíz presentada no tiene un elemento de retroceso natural de la pila; expone la acción de retroceso sintetizada por UIKit.
            // 中文：modal 根页面没有天然的栈返回项，因此使用 UIKit 合成的系统返回动作。
            navigationItem.leftItemsSupplementBackButton = false
            let backAction = UIAction(title: "Back",
                                      image: PTAppBaseConfig.share.viewControllerBackItemImage) { [weak viewController, weak navigationController] _ in
                if let baseViewController = viewController as? PTBaseViewController {
                    baseViewController.returnFrontVC()
                } else {
                    navigationController?.dismiss(animated: true)
                }
            }
            navigationItem.backAction = backAction
            ownership.backAction = backAction
            navigationItem.hidesBackButton = false
        } else {
            // English: Wrap custom views only when UIKit will actually display them, preserving the original container for renderer changes.
            // Español: Envuelve las vistas personalizadas solo cuando UIKit realmente las mostrará, conservando el contenedor original para cambios de renderizador.
            // 中文：仅在 UIKit 确实要显示自定义视图时创建 wrapper，保留原容器以支持渲染器切换。
            let leftBarButtonItems = item.leftView.map { makeNativeBarButtonItem(contentView: $0) }
            ownership.leftItems = leftBarButtonItems

            if isPresentedRoot, !leftBarButtonItems.isEmpty {
                // English: Keep an explicitly supplied modal close button in the system leading group.
                // Español: Mantiene el botón de cierre modal explícito dentro del grupo leading del sistema.
                // 中文：将调用方显式提供的 modal 关闭按钮放入系统 leading group。
                installNativeLeadingItems(leftBarButtonItems,
                                          existingItems: existingLeftItems,
                                          existingGroups: existingLeadingGroups,
                                          on: navigationItem,
                                          ownership: ownership)
                navigationItem.hidesBackButton = true
            } else {
                installNativeLeadingItems(leftBarButtonItems,
                                          existingItems: existingLeftItems,
                                          existingGroups: existingLeadingGroups,
                                          on: navigationItem,
                                          ownership: ownership)
            }
        }

        let rightBarButtonItems = item.rightViews.map { makeNativeBarButtonItem(contentView: $0) }
        ownership.rightItems = rightBarButtonItems
        installNativeTrailingItems(rightBarButtonItems,
                                   existingItems: existingRightItems,
                                   existingGroups: existingTrailingGroups,
                                   existingPinnedGroup: existingPinnedTrailingGroup,
                                   on: navigationItem,
                                   ownership: ownership)

        if let titleView = item.titleView {
            navigationItem.title = nil
            navigationItem.titleView = titleView
            ownership.titleView = titleView
            ownership.title = nil
        } else {
            if navigationItem.titleView == nil || navigationItem.titleView === ownership.titleView {
                navigationItem.titleView = nil
            }
            let title = item.navTitle.isEmpty ? viewController.title : item.navTitle
            if item.isConfigured || !item.navTitle.isEmpty {
                navigationItem.title = title
                ownership.title = title
            }
        }

        if let configurable = viewController as? PTNavigationConfigurable {
            navigationController.navigationBar.prefersLargeTitles = configurable.prefersLargeTitle()
            navigationItem.largeTitleDisplayMode = configurable.prefersLargeTitle() ? .always : .never
        }
        PTAdaptiveSystemBarBridge.apply(policy: (navigationController as? PTBaseNavControl)?.adaptiveBarPresentationPolicy
                                         ?? PTAppBaseConfig.share.adaptiveBarPresentationPolicy,
                                         to: navigationController)
        ownership.viewController = viewController
    }

    private func clear() {
        setLeftView([])
        setRightViews([])
        setTitleView(nil)
    }
    
    public func restoreIfNeeded(for vc: UIViewController) {
        // English: Resolve only the navigation stack containing the supplied controller; never cross scenes through a global lookup.
        // Español: Resuelve solo la pila que contiene al controlador suministrado; nunca cruza escenas mediante una búsqueda global.
        // 中文：只解析传入控制器所属的导航栈，不通过全局查找跨 Scene 取页面。
        let nav: UINavigationController?
        if let navigationController = vc as? UINavigationController {
            nav = navigationController
        } else {
            nav = vc.navigationController
        }
        guard let nav,
              let realVC = nav.visibleViewController ?? nav.topViewController else { return }
        rememberCurrent(nav, viewController: realVC)
        guard let item = itemCache.object(forKey: realVC),
                  item.isConfigured else {
            return
        }
        _ = reconcileNavigationBar(in: nav, reason: .restoration)
        
        // English: Refresh status-bar appearance after the scene-local renderer has settled.
        // Español: Actualiza la apariencia de la barra de estado después de estabilizar el renderizador de la escena.
        // 中文：场景内渲染器收敛后，再刷新状态栏外观。
        StatusBarManager.shared.update(with: item.barColorStyle)
        realVC.setNeedsStatusBarAppearanceUpdate()
        nav.setNeedsStatusBarAppearanceUpdate()
    }
    
    public func refreshCurrentNavBar() {
        guard let vc = currentVC,
              let nav = currentNav else { return }
        
        guard let item = itemCache.object(forKey: vc),
              item.isConfigured else { return }
        
        _ = reconcileNavigationBar(in: nav, reason: .restoration)
    }
}

extension PTNavigationBarManager {
    // English: Store transition state by navigation controller so one scene cannot cancel another scene's display link.
    // Español: Guarda el estado de transición por controlador de navegación para que una escena no cancele el display link de otra.
    // 中文：按导航控制器保存转场状态，避免一个场景停止另一个场景的 display link。
    private func setTransitionState(for navigationController: UINavigationController,
                                    coordinator: UIViewControllerTransitionCoordinator,
                                    container: PTNavigationBarContainer) {
        transitionStates.setObject(NavigationTransitionState(coordinator: coordinator,
                                                              container: container),
                                               forKey: navigationController)
    }

    // English: Remove only the completed stack transition and stop the shared display link when no stack remains.
    // Español: Elimina solo la transición completada y detiene el display link compartido cuando no queda ninguna pila.
    // 中文：只移除已完成导航栈的转场，所有转场结束后才停止共享 display link。
    private func stopTransition(for navigationController: UINavigationController) {
        transitionStates.removeObject(forKey: navigationController)
        let hasRemainingTransitions = transitionStates.keyEnumerator().nextObject() != nil
        if !hasRemainingTransitions {
            stopDisplayLink()
        }
    }

    private func startDisplayLink() {
        guard displayLink == nil else { return }

        if PTUIAccessibility.reduceMotionEnabled {
            // English: Complete interactive navigation styling immediately when motion is reduced.
            // Español: Completa de inmediato el estilo de navegación interactivo cuando se reduce el movimiento.
            // 中文：开启减弱动态效果时，立即完成交互式导航栏样式更新。
            completeReducedMotionTransitions()
            return
        }

        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @MainActor @objc private func handleDisplayLink() {
        if PTUIAccessibility.reduceMotionEnabled {
            completeReducedMotionTransitions()
            return
        }

        var navigationControllers = [UINavigationController]()
        let keyEnumerator = transitionStates.keyEnumerator()
        while let navigationController = keyEnumerator.nextObject() as? UINavigationController {
            navigationControllers.append(navigationController)
        }

        for navigationController in navigationControllers {
            guard let state = transitionStates.object(forKey: navigationController),
                  let coordinator = state.coordinator,
                  let container = state.container else {
                transitionStates.removeObject(forKey: navigationController)
                continue
            }
            container.updateTransition(progress: coordinator.percentComplete)
        }

        if transitionStates.keyEnumerator().nextObject() == nil {
            stopDisplayLink()
        }
    }

    private func completeReducedMotionTransitions() {
        let keyEnumerator = transitionStates.keyEnumerator()
        while let navigationController = keyEnumerator.nextObject() as? UINavigationController {
            guard let state = transitionStates.object(forKey: navigationController),
                  let container = state.container else {
                continue
            }
            container.updateTransition(progress: 1)
        }
        stopDisplayLink()
    }
}

extension PTNavigationBarManager {

    public func setLeftView(_ views: [UIView], spacing: CGFloat = 8) {
        guard let nav = currentNav else { return }
        setLeftView(views, spacing: spacing, in: nav)
    }

    // English: Keep the explicit navigation controller overload private to avoid cross-stack updates.
    // Español: Mantiene privada la sobrecarga con navegación explícita para evitar actualizar otra pila.
    // 中文：显式传入导航控制器的重载保持私有，避免误更新其他导航栈。
    private func setLeftView(_ views: [UIView], spacing: CGFloat, in nav: UINavigationController) {
        guard let container = containerMap.object(forKey: nav) else { return }
        // English: Reuse the same pre-reparenting measurement path as PTNavBar.
        // Español: Reutiliza la misma medición previa al cambio de supervista que PTNavBar.
        // 中文：复用 PTNavBar 使用的重新挂载前统一测量路径。
        let containerWidth = container.configureNavigationBarItems(views,
                                                                    in: container.leftContainer,
                                                                    spacing: spacing)
        container.leftContainerWidth = containerWidth
        
        container.leftContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(containerWidth)
        }
        refreshTitleLayout(in: nav, container: container)
    }
    
    public func setRightViews(_ views: [UIView], spacing: CGFloat = 8) {
        guard let nav = currentNav else { return }
        setRightViews(views, spacing: spacing, in: nav)
    }

    private func setRightViews(_ views: [UIView], spacing: CGFloat, in nav: UINavigationController) {
        guard let container = containerMap.object(forKey: nav) else { return }
        // English: Keep right-side items on the same deterministic sizing path.
        // Español: Mantiene los elementos derechos en la misma ruta de tamaño determinista.
        // 中文：右侧按钮也使用同一套确定性尺寸布局。
        let containerWidth = container.configureNavigationBarItems(views,
                                                                    in: container.rightContainer,
                                                                    spacing: spacing)
        container.rightContainerWidth = containerWidth
        
        container.rightContainer.snp.remakeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(containerWidth)
        }
        refreshTitleLayout(in: nav, container: container)
    }
    
    public func setTitleView(_ view: UIView?, fillSpace: Bool = false) {
        guard let nav = currentNav else { return }
        setTitleView(view, fillSpace: fillSpace, in: nav)
    }

    private func setTitleView(_ view: UIView?, fillSpace: Bool, in nav: UINavigationController) {
        guard let container = containerMap.object(forKey: nav) else { return }
        guard let view else {
            container.clearTitleLayout()
            return
        }

        // English: Reuse the existing title view and let one resolver-owned path update its geometry.
        // Español: Reutiliza la vista existente y deja que una única ruta propietaria del resolver actualice su geometría.
        // 中文：复用现有标题视图，并由 Resolver 唯一负责的路径更新几何约束。
        let existingView = container.titleContainer.subviews.first
        if existingView !== view {
            existingView?.snp.removeConstraints()
            existingView?.removeFromSuperview()
            view.snp.removeConstraints()
            view.removeFromSuperview()
            container.titleContainer.addSubview(view)
        }
        container.titleContainer.clipsToBounds = true
        container.titleContainer.isUserInteractionEnabled = true
        container.titleContainer.isHidden = false

        let mode: PTNavigationTitleLayoutMode = fillSpace ? .fillAvailable : .centerMeasured
        container.titleLayoutMode = mode
        applyTitleLayout(view: view, mode: mode, in: nav, container: container)
    }

    // English: Apply the shared title result and own all title-container constraints in this adapter.
    // Español: Aplica el resultado compartido y posee todas las restricciones del contenedor en este adaptador.
    // 中文：使用统一结果，并由当前适配器独占标题容器约束。
    private func applyTitleLayout(view: UIView,
                                  mode: PTNavigationTitleLayoutMode,
                                  in navigationController: UINavigationController,
                                  container: PTNavigationBarContainer) {
        let visibleRect = container.navigationTitleVisibleRect()
        let layout = container.navigationTitleLayout(for: view,
                                                      mode: mode,
                                                      visibleRect: visibleRect,
                                                      availableHeight: visibleRect.height)
        let needsUpdate = container.titleLayoutSignature != layout.input ||
            container.titleLayoutView !== view
        container.titleLayoutMode = mode
        container.titleLayoutView = view

        guard needsUpdate else {
            container.titleContainer.isHidden = !layout.result.shouldDisplay
            return
        }

        container.titleLayoutSignature = layout.input
        if !layout.result.shouldDisplay {
            container.titleContainer.isHidden = true
            container.titleContainer.isUserInteractionEnabled = false
            container.titleContainer.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(0)
            }
            view.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            return
        }

        container.titleContainer.isHidden = false
        container.titleContainer.isUserInteractionEnabled = true
        let frame = layout.result.titleFrame
        container.titleContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(frame.minX)
            make.top.equalToSuperview().offset(frame.minY)
            make.width.equalTo(frame.width)
            make.height.equalTo(frame.height)
        }
        view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        _ = navigationController
    }

    // English: Recompute a title after button, safe-area, rotation, or split-pane geometry changes.
    // Español: Recalcula el título después de cambios de botones, área segura, rotación o panel dividido.
    // 中文：按钮、安全区、旋转或分屏几何变化后重新计算标题。
    private func refreshTitleLayout(in navigationController: UINavigationController,
                                    container: PTNavigationBarContainer) {
        guard let view = container.titleLayoutView,
              let mode = container.titleLayoutMode else { return }
        applyTitleLayout(view: view,
                         mode: mode,
                         in: navigationController,
                         container: container)
    }
}
