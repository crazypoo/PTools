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


@MainActor
public final class PTNavBarItem {
    public var isConfigured = false   // ✅ 新增
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
    
    public func installIfNeeded(in nav: UINavigationController) {
        if containerMap.object(forKey: nav) != nil { return }

        let navBar = nav.navigationBar
        resetSystemNavBarAppearance(nav)
        
        let totalHeight = navBar.bounds.height
        
        // 往上扩展，打好地基
        let container = PTNavigationBarContainer(frame: CGRect(x: 0, y: 0, width: navBar.bounds.width, height: totalHeight))
        
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.bind(to: nav)
                
        navBar.addSubview(container)
        navBar.sendSubviewToBack(container)
        containerMap.setObject(container, forKey: nav)
    }
    
    public func apply(style: PTNavigationBarStyle, in nav: UINavigationController) {
        installIfNeeded(in: nav)
        rememberCurrent(nav, viewController: nav.topViewController)
        styleCache.setObject(NavigationStyleBox(style: style), forKey: nav)
        let container = containerMap.object(forKey: nav)
        container?.apply(style: style)
        
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
        resetSystemNavBarAppearance(nav)
    }
    
    public func bind(to nav: UINavigationController) {
        if let proxy = delegateProxyMap.object(forKey: nav) {
            if nav.delegate !== proxy {
                if nav.delegate !== self {
                    proxy.hostDelegate = nav.delegate
                }
                nav.delegate = proxy
            }
            return
        }

        let hostDelegate = nav.delegate === self ? nil : nav.delegate
        let proxy = PTNavigationDelegateProxy(manager: self, hostDelegate: hostDelegate)
        delegateProxyMap.setObject(proxy, forKey: nav)
        nav.delegate = proxy
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
        resetSystemNavBarAppearance(navigationController)
        
        // 安全准备默认返回按钮数据（来自我们上一步的优化）
        if let baseVC = viewController as? PTBaseViewController {
            baseVC.prepareDefaultNavigationBarItem()
        }
        
        guard let container = containerMap.object(forKey: navigationController) else { return }
        
        let toStyle: PTNavigationBarStyle
        if let configurable = viewController as? PTNavigationConfigurable {
            toStyle = configurable.preferredNavigationBarStyle()
            let item = self.item(for: viewController)
            item.barColorStyle = toStyle
        } else {
            toStyle = .default
        }

        StatusBarManager.shared.update(with: toStyle)
        
        let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from)
        let fromStyle = (fromVC as? PTNavigationConfigurable)?.preferredNavigationBarStyle() ?? .transparent

        // 预设起点，准备动画
        container.prepareTransition(from: fromStyle, to: toStyle)
        let item = itemCache.object(forKey: viewController) ?? PTNavBarItem()

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

        viewController.navigationItem.hidesBackButton = true
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
        container.leftContainer.spacing = spacing
        container.leftContainer.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        container.leftContainer.isHidden = true
        var containerWidth: CGFloat = 0

        guard !views.isEmpty else {
            container.leftContainerWidth = 0 // 👈 记录宽度为 0
            container.leftContainer.snp.remakeConstraints { make in
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(0)
            }
            return
        }
        
        container.leftContainer.isHidden = false
        views.forEach { value in
            container.leftContainer.addArrangedSubview(value)
            value.snp.remakeConstraints { make in
                make.size.equalTo(value.bounds.size)
            }
            containerWidth += value.bounds.size.width
        }
        containerWidth += CGFloat(views.count - 1) * spacing
        
        container.leftContainerWidth = containerWidth // 👈 记录真实宽度
        
        container.leftContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(containerWidth)
        }
    }
    
    public func setRightViews(_ views: [UIView], spacing: CGFloat = 8) {
        guard let nav = currentNav else { return }
        setRightViews(views, spacing: spacing, in: nav)
    }

    private func setRightViews(_ views: [UIView], spacing: CGFloat, in nav: UINavigationController) {
        guard let container = containerMap.object(forKey: nav) else { return }
        container.rightContainer.spacing = spacing
        container.rightContainer.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        container.rightContainer.isHidden = true
        var containerWidth: CGFloat = 0
                
        guard !views.isEmpty else {
            container.rightContainerWidth = 0 // 👈 记录宽度为 0
            container.rightContainer.snp.remakeConstraints { make in
                make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(0)
            }
            return
        }
        
        container.rightContainer.isHidden = false
        views.forEach { value in
            container.rightContainer.addArrangedSubview(value)
            value.snp.remakeConstraints { make in
                make.size.equalTo(value.bounds.size)
            }
            containerWidth += value.bounds.size.width
        }
        containerWidth += CGFloat(views.count - 1) * spacing
        
        container.rightContainerWidth = containerWidth // 👈 记录真实宽度
        
        container.rightContainer.snp.remakeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(containerWidth)
        }
    }
    
    public func setTitleView(_ view: UIView?, fillSpace: Bool = false) {
        guard let nav = currentNav else { return }
        setTitleView(view, fillSpace: fillSpace, in: nav)
    }

    private func setTitleView(_ view: UIView?, fillSpace: Bool, in nav: UINavigationController) {
        guard let container = containerMap.object(forKey: nav) else { return }
        container.titleContainer.subviews.forEach { $0.removeFromSuperview() }
        container.titleContainer.isHidden = true
        guard let view else { return }
        // 🛠️ 终极防遮挡核心 物理裁剪，不允许超长文字渲染到容器外部
        container.titleContainer.clipsToBounds = true
        container.titleContainer.isHidden = false
        container.titleContainer.addSubview(view)

        // 🌟🌟🌟 核心逻辑：分别计算真实的左右物理边界 🌟🌟🌟
        // 如果该边有按钮：边界 = 基础边距 + 按钮总宽度 + 标题间距
        // 如果该边没按钮：边界 = 仅仅保留基础的安全边距（不浪费一丝多余空间）
        let leftSpace = container.leftContainerWidth > 0
            ? (PTAppBaseConfig.share.defaultViewSpace + container.leftContainerWidth + PTAppBaseConfig.share.navContainerSpacing)
            : PTAppBaseConfig.share.defaultViewSpace
        
        let rightSpace = container.rightContainerWidth > 0
            ? (PTAppBaseConfig.share.defaultViewSpace + container.rightContainerWidth + PTAppBaseConfig.share.navContainerSpacing)
            : PTAppBaseConfig.share.defaultViewSpace

        container.titleContainer.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            // 注意：这里保留了你代码里的 self.navOffset()
            make.top.equalToSuperview()
            // ✅ 根据模式应用不同的约束策略
            if fillSpace {
                // 🔥 填满模式：直接等于左右物理边界，强制拉伸（非常适合搜索框等自定义 View）
                make.left.equalToSuperview().offset(leftSpace)
                make.right.equalToSuperview().offset(-rightSpace)
            } else {
                // 📝 文本居中模式：保持绝对居中，仅在超长时用 greaterThanOrEqualTo 限制（适合普通文字标题）
                make.centerX.equalToSuperview().priority(900)
                make.left.greaterThanOrEqualToSuperview().offset(leftSpace)
                make.right.lessThanOrEqualToSuperview().offset(-rightSpace)
            }
        }
        
        view.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            if self.titleLabel {
                make.top.bottom.equalToSuperview()
            } else {
                make.height.equalTo(view.bounds.size.height)
                make.centerY.equalToSuperview()
            }
        }
    }
}
