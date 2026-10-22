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

    // English: Resolve the real UINavigationBar row in local coordinates before updating any child constraints.
    // Español: Resuelve la fila real de UINavigationBar en coordenadas locales antes de actualizar restricciones hijas.
    // 中文：先在 UINavigationBar 局部坐标中解析真实内容行，再更新子视图约束。
    private func refreshNavigationContentRow(in nav: UINavigationController,
                                             container: PTNavigationBarContainer) {
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
        let hostSafeRect = hostBounds.inset(by: safeInsets)
        let isLargeTitleExpanded = container.isLargeTitleExpandedForLayout
        let compactRowHeight = isLargeTitleExpanded
            ? compactNavigationRowHeight(in: navBar, container: container)
            : nil
        let input = PTNavigationContentRowInput(
            hostBounds: hostBounds,
            hostSafeRect: hostSafeRect,
            systemContentRect: isLargeTitleExpanded ? nil : hostSafeRect,
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
        dumpNavigationVerticalGeometryIfEnabled(nav: nav, container: container)
#endif
    }

#if DEBUG
    // English: Keep vertical geometry logging opt-in so normal debug builds have no extra output.
    // Español: Mantiene el registro geométrico optativo para no añadir salida en las compilaciones debug normales.
    // 中文：垂直几何日志默认关闭，避免普通 Debug 构建产生额外输出。
    private func dumpNavigationVerticalGeometryIfEnabled(nav: UINavigationController,
                                                         container: PTNavigationBarContainer) {
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
        PTNSLogConsole("""
        [PTNavY]
        bar=\(barRect) / safe=\(nav.navigationBar.safeAreaInsets)
        host=\(hostRect) / safe=\(container.safeAreaInsets)
        row=\(rowRect) / safe=\(container.topBarContainer.safeAreaInsets)
        left.midY=\(leftRect.midY)
        right.midY=\(rightRect.midY)
        title.midY=\(titleRect.midY)
        navSafe=\(nav.view.safeAreaInsets)
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

    // English: Refresh geometry without reinstalling the per-navigation-controller container.
    // Español: Actualiza la geometría sin reinstalar el contenedor propio del controlador de navegación.
    // 中文：只刷新几何，不重新安装每个导航控制器独立拥有的容器。
    func refreshGeometry(in nav: UINavigationController) {
        guard !usesNativeVerticalBar(nav),
              let container = containerMap.object(forKey: nav) else { return }
        refreshNavigationContentRow(in: nav, container: container)
    }
    
    public func installIfNeeded(in nav: UINavigationController) {
        if usesNativeVerticalBar(nav) {
            if let container = containerMap.object(forKey: nav) {
                container.clearTitleLayout()
                setCustomContainer(container, visible: false)
            }
            applyAdaptiveSystemPolicy(to: nav)
            return
        }
        if let existingContainer = containerMap.object(forKey: nav) {
            setCustomContainer(existingContainer, visible: true)
            
            if PTNavigationGlassCompatibility.requiresWorkaround {
                resetSystemNavBarAppearance(nav)
            }
            refreshNavigationContentRow(in: nav, container: existingContainer)
            return
        }

        let navBar = nav.navigationBar
        resetSystemNavBarAppearance(nav)
        
        let totalHeight = navBar.bounds.height
        
        // 往上扩展，打好地基
        let container = PTNavigationBarContainer(frame: CGRect(x: 0, y: 0, width: navBar.bounds.width, height: totalHeight))
        
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.bind(to: nav)

        // English: Let the manager refresh title geometry after the host changes size.
        // Español: Permite que el gestor actualice la geometría del título cuando cambia el tamaño del host.
        // 中文：宿主尺寸变化后，由 Manager 负责重新计算标题几何。
        container.titleLayoutUpdateHandler = { [weak self, weak nav, weak container] in
            guard let self, let nav, let container else { return }
            self.refreshTitleLayout(in: nav, container: container)
        }
                
        navBar.addSubview(container)
        navBar.sendSubviewToBack(container)
        containerMap.setObject(container, forKey: nav)
        refreshNavigationContentRow(in: nav, container: container)
    }
    
    public func apply(style: PTNavigationBarStyle, in nav: UINavigationController) {
        installIfNeeded(in: nav)
        rememberCurrent(nav, viewController: nav.topViewController)
        styleCache.setObject(NavigationStyleBox(style: style), forKey: nav)
        if usesNativeVerticalBar(nav) {
            applyAdaptiveSystemPolicy(to: nav)
            return
        }
        let container = containerMap.object(forKey: nav)
        container?.apply(style: style)
        if let container {
            refreshNavigationContentRow(in: nav, container: container)
        }
        
        resetSystemNavBarAppearance(nav)
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
        
        nav.navigationBar.subviews.forEach {
            if NSStringFromClass(type(of: $0)).contains("UIBarBackground") {
                $0.isHidden = true
                $0.isUserInteractionEnabled = false
                $0.alpha = 0
            }
        }

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
            apply(item: item)
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
            // English: Map the existing navigation item into UIKit instead of overlaying a second custom bar.
            // Español: Mapea el elemento de navegación existente a UIKit en lugar de superponer otra barra personalizada.
            // 中文：把现有导航项映射到 UIKit，避免叠加第二套自定义导航栏。
            applyNativeItem(item, in: navigationController, viewController: viewController)
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

        // 预设起点，准备动画
        container.prepareTransition(from: fromStyle, to: toStyle)
        // 🌟 判断这是否是导航栈的“根视图”（代表是新 Present 出来的）
        let isRoot = navigationController.viewControllers.first == viewController

        if isRoot {
            // 💡 这是 Present 出来的根视图！
            // 整个 NavController 正在被系统整体推上来（Slide Up）。
            container.apply(style: toStyle)
            self.apply(item: item, in: navigationController, viewController: viewController)
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
                // 兜底无动画情况
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

        apply(style: style, in: navigationController)
        // English: Prefer UIKit's didShow callback over a transient navigation-stack snapshot.
        // Español: Da prioridad al callback didShow de UIKit sobre una instantánea transitoria de la pila.
        // 中文：优先使用 UIKit 的 didShow 回调，避免被转场瞬间的导航栈快照覆盖。
        rememberCurrent(navigationController, viewController: viewController)
        let item = itemCache.object(forKey: viewController) ?? PTNavBarItem()
        apply(item: item, in: navigationController, viewController: viewController)
        refreshGeometry(in: navigationController)
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
        let isPresentedRoot = navigationController.viewControllers.first === viewController &&
            (navigationController.presentingViewController != nil ||
             viewController.presentingViewController != nil ||
             navigationController.isBeingPresented ||
             viewController.isBeingPresented)

        if isPresentedRoot, item.usesFrameworkDefaultBackAction, #available(iOS 16.0, *) {
            // English: A presented root has no natural stack back item, so expose UIKit's synthesized system back action.
            // Español: Una raíz presentada no tiene un elemento de retroceso natural de la pila; expone la acción de retroceso sintetizada por UIKit.
            // 中文：modal 根页面没有天然的栈返回项，因此使用 UIKit 合成的系统返回动作。
            navigationItem.leftBarButtonItems = nil
            navigationItem.leftBarButtonItem = nil
            navigationItem.leadingItemGroups = []
            navigationItem.leftItemsSupplementBackButton = false
            navigationItem.backAction = UIAction(title: "Back",
                                                 image: PTAppBaseConfig.share.viewControllerBackItemImage) { [weak viewController, weak navigationController] _ in
                if let baseViewController = viewController as? PTBaseViewController {
                    baseViewController.returnFrontVC()
                } else {
                    navigationController?.dismiss(animated: true)
                }
            }
            navigationItem.hidesBackButton = false
        } else {
            // English: Wrap custom views only when UIKit will actually display them, preserving the original container for renderer changes.
            // Español: Envuelve las vistas personalizadas solo cuando UIKit realmente las mostrará, conservando el contenedor original para cambios de renderizador.
            // 中文：仅在 UIKit 确实要显示自定义视图时创建 wrapper，保留原容器以支持渲染器切换。
            let leftBarButtonItems = item.leftView.map {
                UIBarButtonItem(customView: PTNativeNavigationItemView(contentView: $0))
            }

            if isPresentedRoot, !leftBarButtonItems.isEmpty, #available(iOS 16.0, *) {
            // English: Keep an explicitly supplied modal close button in the system leading group.
            // Español: Mantiene el botón de cierre modal explícito dentro del grupo leading del sistema.
            // 中文：将调用方显式提供的 modal 关闭按钮放入系统 leading group。
            navigationItem.backAction = nil
            navigationItem.leftBarButtonItems = nil
            navigationItem.leftBarButtonItem = nil
            navigationItem.leadingItemGroups = [
                UIBarButtonItemGroup.fixedGroup(representativeItem: nil,
                                                items: leftBarButtonItems)
            ]
            navigationItem.leftItemsSupplementBackButton = false
            navigationItem.hidesBackButton = true
            } else {
                navigationItem.backAction = nil
                navigationItem.leadingItemGroups = []
                navigationItem.leftBarButtonItems = leftBarButtonItems
            }
        }

        navigationItem.rightBarButtonItems = item.rightViews.map {
            UIBarButtonItem(customView: PTNativeNavigationItemView(contentView: $0))
        }

        if let titleView = item.titleView {
            navigationItem.title = nil
            navigationItem.titleView = titleView
        } else {
            navigationItem.titleView = nil
            navigationItem.title = item.navTitle.isEmpty ? viewController.title : item.navTitle
        }

        if let configurable = viewController as? PTNavigationConfigurable {
            navigationController.navigationBar.prefersLargeTitles = configurable.prefersLargeTitle()
            navigationItem.largeTitleDisplayMode = configurable.prefersLargeTitle() ? .always : .never
        }
        PTAdaptiveSystemBarBridge.apply(policy: (navigationController as? PTBaseNavControl)?.adaptiveBarPresentationPolicy
                                         ?? PTAppBaseConfig.share.adaptiveBarPresentationPolicy,
                                         to: navigationController)
    }

    private func clear() {
        setLeftView([])
        setRightViews([])
        setTitleView(nil)
    }
    
    public func restoreIfNeeded(for vc: UIViewController) {
        // ❗关键：只处理有 navigationController 的 VC
        let realVC = PTUtils.getCurrentVC(from: vc)
        guard let nav = realVC.navigationController else { return }
        rememberCurrent(nav, viewController: realVC)
        guard let item = itemCache.object(forKey: realVC),
                  item.isConfigured else {
            return
        }
        apply(style: item.barColorStyle, in: nav)
        apply(item: item, in: nav, viewController: realVC)
        
        // 🔥 关键：同步更新状态栏单例并通知系统刷新
        StatusBarManager.shared.update(with: item.barColorStyle)
        realVC.setNeedsStatusBarAppearanceUpdate()
        nav.setNeedsStatusBarAppearanceUpdate()
    }
    
    public func refreshCurrentNavBar() {
        guard let vc = currentVC,
              let nav = currentNav else { return }
        
        guard let item = itemCache.object(forKey: vc),
              item.isConfigured else { return }
        
        apply(style: item.barColorStyle, in: nav)
        apply(item: item)
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
    
    fileprivate func navOffset() -> CGFloat {
        let offsetHeight = (PTUtils.getCurrentVC()?.sheetViewController != nil) ? CGFloat.statusBarHeight() : 0
        return offsetHeight
    }
    
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
