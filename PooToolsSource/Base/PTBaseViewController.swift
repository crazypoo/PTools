//
//  PTBaseViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import AttributedString
import Photos
import SnapKit
import SafeSFSymbols

public typealias PTScreenShotImageHandle = (PTScreenShotActionType,UIImage) -> Void
public typealias PTScreenShotOnlyGetImageHandle = (UIImage?) -> Void

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
        if selectorName == "navigationController:willShowViewController:animated:" {
            return true
        }

        let isForwardedNavigationSelector: Bool
        switch selectorName {
        case "navigationController:didShowViewController:animated:",
             "navigationControllerSupportedInterfaceOrientations:",
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
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidDisconnect(_:)),
                                               name: UIScene.didDisconnectNotification,
                                               object: nil)
    }

    @objc private func sceneDidDisconnect(_ notification: Notification) {
        guard let scene = notification.object as? UIWindowScene else { return }
        let sceneID = scene.session.persistentIdentifier
        navigationContextsBySceneID.removeValue(forKey: sceneID)
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
        if let baseVC = viewController as? PTBaseViewController,
           !baseVC.allowControlNavBar() {
            return
        }
        
        installIfNeeded(in: navigationController)
        rememberCurrent(navigationController, viewController: viewController)
        resetSystemNavBarAppearance(navigationController)
        
        // 安全准备默认返回按钮数据（来自我们上一步的优化）
        if let baseVC = viewController as? PTBaseViewController {
            baseVC.prepareDefaultNavigationBarItem()
        }
        
        guard let container = containerMap.object(forKey: navigationController) else { return }
        
        let toStyle: PTNavigationBarStyle
        if let baseVC = viewController as? PTBaseViewController {
            toStyle = baseVC.preferredNavigationBarStyle()
            let item = self.item(for: viewController)
            item.barColorStyle = toStyle
        } else {
            toStyle = .default
        }

        StatusBarManager.shared.update(with: toStyle)
        
        let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from)
        let fromStyle = (fromVC as? PTBaseViewController)?.preferredNavigationBarStyle() ?? .transparent

        // 预设起点，准备动画
        container.prepareTransition(from: fromStyle, to: toStyle)
        let item = itemCache.object(forKey: viewController) ?? PTNavBarItem()

        // 🌟 判断这是否是导航栈的“根视图”（代表是新 Present 出来的）
        let isRoot = navigationController.viewControllers.first == viewController

        if isRoot {
            // 💡 这是 Present 出来的根视图！
            // 整个 NavController 正在被系统整体推上来（Slide Up）。
            container.apply(style: toStyle)
            self.apply(item: item)
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
                                          duration: context.transitionDuration,
                                          options: .transitionCrossDissolve,
                                          animations: {
                            self.apply(item: item)
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
                    UIView.animate(withDuration: 0.25) {
                        container.apply(style: toStyle)
                    }
                    UIView.transition(with: container.topBarContainer, duration: 0.25, options: .transitionCrossDissolve, animations: {
                        self.apply(item: item)
                    }, completion: { _ in
                        if let vc = viewController as? PTBaseViewController {
                            vc.setNeedsStatusBarAppearanceUpdate()
                        }
                    })
                } else {
                    container.apply(style: toStyle)
                    self.apply(item: item)
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
            if let vc = toVC as? PTBaseViewController {
                vc.setNeedsStatusBarAppearanceUpdate()
                vc.navigationController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    private func apply(item: PTNavBarItem) {
        setLeftView(item.leftView,spacing: item.leftItemSpacing)
        setRightViews(item.rightViews,spacing: item.rightItemSpacing)
        if let findTitleView = item.titleView {
            titleLabel = false
            setTitleView(findTitleView,fillSpace: item.titleViewFillSpace)
        } else if !item.navTitle.stringIsEmpty() {
            titleLabel = true
            let titleLabel = UILabel()
            titleLabel.font = PTAppBaseConfig.share.navTitleFont
            titleLabel.textColor = PTAppBaseConfig.share.navTitleTextColor
            titleLabel.numberOfLines = 1
            titleLabel.lineBreakMode = .byTruncatingTail // 👈 增加这句，确保过长显示为 ...
            titleLabel.text = item.navTitle
            titleLabel.textAlignment = .center
            titleLabel.clipsToBounds = true
            setTitleView(titleLabel,fillSpace: false)
        } else {
            titleLabel = false
            setTitleView(nil)
        }
        
        // ===== LargeTitle 逻辑（🔥重点）=====
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav),
              let vc = currentVC as? PTBaseViewController else { return }

        let isLarge = vc.prefersLargeTitle()
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
        apply(item: item)
        
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
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @MainActor @objc private func handleDisplayLink() {
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
}

extension PTNavigationBarManager {
    
    fileprivate func navOffset() -> CGFloat {
        let offsetHeight = (PTUtils.getCurrentVC()?.sheetViewController != nil) ? CGFloat.statusBarHeight() : 0
        return offsetHeight
    }
    
    public func setLeftView(_ views: [UIView],spacing:CGFloat = 8) {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
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
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
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
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
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

@objcMembers
@MainActor
open class PTBaseViewController: UIViewController {

    private var hidesBaseNavigationBarOnLoad = false
                   
    open func prefersLargeTitle() -> Bool {
        return false
    }
    
    open func allowControlNavBar() -> Bool {
        return true
    }
    
    open var pt_Title:String? {
        didSet {
            let item = PTNavigationBarManager.shared.item(for: self)
            item.navTitle = pt_Title ?? ""
            PTNavigationBarManager.shared.update(item: item, for: self)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .PTRotationOrientationDidChange, object: nil)
        PTNSLogConsole("[\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]===已被释放",levelType: PTLogMode,loggerType: .viewCycle)
    }
    
    // MARK: - 子类 override 以决定样式
    open func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.white)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PTNSLogConsole("加载==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .viewCycle)
        refreshNavigationBarIfNeeded()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTNSLogConsole("加载完==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .viewCycle)
        refreshNavigationBarIfNeeded()
    }
    
    open override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        PTNSLogConsole("离开==============================\(NSStringFromClass(type(of: self)))（\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())）",levelType: PTLogMode,loggerType: .viewCycle)
        if let presenting = presentingViewController {
            PTNavigationBarManager.shared.restoreIfNeeded(for: presenting)
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
        
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseConfigs()
        if let sheet = self.sheetViewController,let nav = sheet.childViewController as? UINavigationController {
            PTNavigationBarManager.shared.bind(to: nav)
        } else {
            if let nav = navigationController {
                PTNavigationBarManager.shared.bind(to: nav)
            }
        }

        if hidesBaseNavigationBarOnLoad {
            navigationController?.navigationBar.isHidden = true
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRotationOrientationChange(_:)),
            name: .PTRotationOrientationDidChange,
            object: nil
        )
    }
    
    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        PTNavigationBarManager.shared.restoreIfNeeded(for: self)
    }

    /// 只在页面没有转场时恢复一次导航栏状态，避免生命周期重复刷新。
    private func refreshNavigationBarIfNeeded() {
        guard transitionCoordinator == nil else { return }
        PTNavigationBarManager.shared.restoreIfNeeded(for: self)

        if let sheet = sheetViewController,
           let nav = sheet.childViewController as? UINavigationController {
            PTNavigationBarManager.shared.apply(style: preferredNavigationBarStyle(), in: nav)
        } else if let nav = navigationController {
            PTNavigationBarManager.shared.apply(style: preferredNavigationBarStyle(), in: nav)
        }
    }

    @objc private func handleRotationOrientationChange(_ notification: Notification) {
        guard let orientationMask = notification.object as? UIInterfaceOrientationMask else { return }
        viewControllerOrientation(orientationMask)
    }
    
    @MainActor open func prepareDefaultNavigationBarItem() {
        let item = PTNavigationBarManager.shared.item(for: self)
        item.barColorStyle = preferredNavigationBarStyle()
        
        // 此时 Navigation Stack 已经稳定，可以安全判断是否为第一层
        let isNotRoot = self.navigationController?.viewControllers.first != self
        let isModal = self.isBeingPresented ||
                          self.navigationController?.isBeingPresented == true ||
                          self.presentingViewController != nil ||
                          self.navigationController?.presentingViewController != nil ||
                          self.sheetViewController != nil
        
        if isNotRoot || isModal {
            pt_prefersTabBarHidden = true
            // 关键防护：仅当目前没有任何左侧按钮时，才加上默认的返回按钮，避免重复添加
            if item.leftView.isEmpty {
                let backBtn = baseBackButton()
                            
                backBtn.addActionHandlers { [weak self] _ in
                    self?.returnFrontVC()
                }
                
                self.setCustomBackButtonView(backBtn,size: backBtn.bounds.size)
            }
        }
    }
        
    private func setBaseBackButton() {
        let backBtn = baseBackButton()
        backBtn.addActionHandlers { seder in
            if self.navigationController?.viewControllers.first != self,let findFirst = self.navigationController?.viewControllers.first,let _ = findFirst.sheetViewController {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.viewDismiss()
            }
        }
        setCustomBackButtonView(backBtn)
    }

    private func baseBackButton() -> PTBaseButton {
        let backBtn = PTBaseButton(type: .custom)
        backBtn.setImage(PTAppBaseConfig.share.viewControllerBackItemImage, for: .normal)
        backBtn.bounds = CGRectMake(0, 0, PTAppBaseConfig.share.navBarButtonSize, PTAppBaseConfig.share.navBarButtonSize)
        return backBtn
    }
    
    fileprivate func updateStatusBar(_ style: PTNavigationBarStyle) {
        switch style {
        case .gradient:
            changeStatusBar(type: .Dark)
        case .solid(let color):
            setStatusBarStyle(color: color)
        case .transparent:
            setStatusBarStyle(color: (self.view.backgroundColor ?? PTAppBaseConfig.share.viewControllerBaseBackgroundColor))
        }
    }
    
    private func setStatusBarStyle(color:UIColor) {
        switch color.pt_colorTone() {
        case .dark:
            changeStatusBar(type: .Dark)
        case .light:
            changeStatusBar(type: .Light)
        case .normal:
            changeStatusBar(type: .Dark)
        case .clear:
            changeStatusBar(type: .Light)
        }
    }

    open func viewControllerOrientation(_ orientationMask: UIInterfaceOrientationMask) {}
    
    // English: Keep this deprecated wrapper for source compatibility; URL parsing belongs to the Foundation core.
    // Español: Conserva este wrapper obsoleto por compatibilidad; el análisis URL pertenece al núcleo Foundation.
    // 中文：保留此弃用包装器以兼容旧代码；URL 解析统一归属 Foundation 核心。
    @available(*, deprecated, message: "Use URL.pt_queryParameters or PTURLParser.queryParameters(from:)")
    public func parseURLParameters(url: URL) -> [String: String]? {
        PTURLParser.queryParameters(from: url)
    }
        
    // MARK: - 公共 API（子类/外部可调用）
    open func setCustomBackButton(image: UIImage?,
                                  backgroundColor: UIColor = .clear,
                                  size: CGSize = CGSize(width: 30, height: 30),
                                  leftPadding: CGFloat = 0,
                                  action: PTActionTask? = nil) {
        let backButton = PTBaseButton(type: .custom)
        if let img = image { backButton.setImage(img.withRenderingMode(.alwaysOriginal), for: .normal) }
        backButton.backgroundColor = backgroundColor
        backButton.frame = CGRect(origin: .zero, size: size)
        backButton.isUserInteractionEnabled = true
        backButton.addActionHandlers { sender in
            if let tapAction = action {
                tapAction()
            } else {
                self.backButtonTapped()
            }
        }
        backButton.viewCorner(radius: size.height / 2)
        let item = PTNavigationBarManager.shared.item(for: self)
        item.leftView = [backButton]
        item.leftItemSpacing = leftPadding
        PTNavigationBarManager.shared.update(item: item, for: self)
    }
    
    // 新增：直接传入任意自定义 view
    open func setCustomBackButtonView(_ customView: UIView,
                                      size: CGSize? = nil,
                                      action: PTActionTask? = nil) {
        // 容器 UIView
        let container = UIView()
        container.isUserInteractionEnabled = true
        container.clipsToBounds = true
        container.bounds = CGRect(origin: .zero, size: size ?? CGSize(width: PTAppBaseConfig.share.navBarButtonSize, height: PTAppBaseConfig.share.navBarButtonSize))
        // 加 customView
        container.addSubview(customView)
        customView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // 填满 container
        }
        
        // 点击事件
        if let action = action {
            let button = UIButton(type: .custom)
            container.addSubview(button)
            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            button.addActionHandlers { _ in
                action()
            }
        }
        
        let item = PTNavigationBarManager.shared.item(for: self)
        item.leftView = [container]
        
        PTNavigationBarManager.shared.update(item: item, for: self)
    }
    
    open func setLeftButtons(views:[UIView], buttonSpacing: CGFloat = 10) {
        guard !views.isEmpty else {
            let item = PTNavigationBarManager.shared.item(for: self)
            item.leftView = []
            PTNavigationBarManager.shared.update(item: item, for: self)
            return
        }
        let item = PTNavigationBarManager.shared.item(for: self)
        item.leftView = views
        item.leftItemSpacing = buttonSpacing
        PTNavigationBarManager.shared.update(item: item, for: self)
    }

    //MARK: 需要设置按钮Bounds
    open func setCustomRightButtons(buttons: [UIView], buttonSpacing: CGFloat = 10) {
        guard !buttons.isEmpty else {
            let item = PTNavigationBarManager.shared.item(for: self)
            item.rightViews = []
            PTNavigationBarManager.shared.update(item: item, for: self)
            return
        }
        let item = PTNavigationBarManager.shared.item(for: self)
        item.rightViews = buttons
        item.rightItemSpacing = buttonSpacing
        
        PTNavigationBarManager.shared.update(item: item, for: self)
    }

    open func setCustomTitleView(_ view: UIView? = nil, fillSpace: Bool = true) {
        let item = PTNavigationBarManager.shared.item(for: self)
        item.titleView = view
        item.titleViewFillSpace = fillSpace // 记录填满状态
        PTNavigationBarManager.shared.update(item: item, for: self)
    }

    // MARK: - 设置自定义导航栏背景
    open func updateNavigationBarBackground(scrollView: UIScrollView, changeOffset: CGFloat = 100, color: UIColor = .white) {
        let offset = scrollView.contentOffset.y
        let alpha = min(1, max(0, offset / changeOffset))
        
        PTNavigationBarManager.shared.setAlpha(alpha)
    }
    
    open func setNavigationBarBackgroundAlpha(clear:Bool = false) {
        PTNavigationBarManager.shared.setAlpha(clear ? 0 : 1)
    }

    // MARK: - 私有实现
    private func setupBaseConfigs() {
        // English: Configure scroll views locally; a base controller must not mutate UIKit's global appearance proxy.
        // Español: Configura los scroll views localmente; el controlador base no debe mutar el proxy global de apariencia de UIKit.
        // 中文：仅在具体列表上配置滚动视图，基类不再修改 UIKit 全局 appearance 代理。
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .left, .bottom, .right]
        definesPresentationContext = true
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        navigationController?.hidesBarsOnSwipe = PTAppBaseConfig.share.hidesBarsOnSwipe
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.baseTraitCollectionDidChange(style:self.traitCollection.userInterfaceStyle)
            self.setNeedsStatusBarAppearanceUpdate()
        }

    }
    
    @objc func backButtonTapped() {
        self.returnFrontVC()
    }
    
    public func safePushViewController(_ vc: UIViewController, animated: Bool = true) {
        guard let nav = self.navigationController else { return }
        if nav.transitionCoordinator != nil {
            PTNSLogConsole("拦截到重复跳转，已抛弃", levelType: PTLogMode, loggerType: .viewCycle)
            return
        }
        nav.pushViewController(vc, animated: animated)
    }
}

extension PTBaseViewController: UIScrollViewDelegate {
    open func bindScrollView(_ scrollView: UIScrollView) {
        pt_prepareScrollViewForLargeTitle(scrollView, assignsDelegate: true)
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pt_updateLargeTitleTransition(for: scrollView)
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        pt_finishLargeTitleDrag(for: scrollView)
    }

    // English: Prepare large-title insets without changing the delegate when a wrapper owns it.
    // Español: Prepara los insets del título grande sin cambiar el delegate cuando un wrapper lo posee.
    // 中文：当包装器拥有 delegate 时，只准备大标题 inset，不改变 delegate 归属。
    func pt_prepareScrollViewForLargeTitle(_ scrollView: UIScrollView, assignsDelegate: Bool) {
        view.layoutIfNeeded()
        if assignsDelegate {
            scrollView.delegate = self
        }
        guard prefersLargeTitle() else { return }

        let topHeight = scrollView.frame.origin.y + PTAppBaseConfig.share.navLargeTitleBarHeight
        scrollView.contentInset.top = topHeight
        scrollView.verticalScrollIndicatorInsets.top = topHeight
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }

    // English: Reuse the same progress calculation for direct and wrapped scroll views.
    // Español: Reutiliza el mismo cálculo de progreso para scroll views directos y envueltos.
    // 中文：直接绑定和包装后的滚动视图统一使用同一套进度计算。
    func pt_updateLargeTitleTransition(for scrollView: UIScrollView) {
        guard prefersLargeTitle() else { return }

        let offset = scrollView.contentOffset.y
        let insetTop = scrollView.contentInset.top
        let progress = (offset + insetTop) / PTAppBaseConfig.share.navLargeTitleProgress
        PTNavigationBarManager.shared.updateScrollProgress(progress)
    }

    // English: Preserve the existing overscroll snap behavior for wrapped lists.
    // Español: Conserva el ajuste existente del sobre desplazamiento para listas envueltas.
    // 中文：为包装后的列表保留原有的过度下拉回弹行为。
    func pt_finishLargeTitleDrag(for scrollView: UIScrollView) {
        guard prefersLargeTitle(), scrollView.contentOffset.y < -scrollView.contentInset.top else { return }

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseOut]) {
            scrollView.setContentOffset(
                CGPoint(x: 0, y: -scrollView.contentInset.top),
                animated: false
            )
        }
    }
}

/**
    抽出两个Controller同样用到的地方
 */
extension PTBaseViewController {
    @MainActor
    fileprivate struct AssociatedKeys {
        static var emptyViewConfigCallBack = 992
        static var screenShotActionCallBack = 991
        static var screenShotAlertCallBack = 990
        static var screenShotOnlyGetImageCallBack = 989
        static var floatingScreenSpace = 988
    }
    
    //MARK: 是否隱藏StatusBar
    ///是否隱藏StatusBar
    open override var prefersStatusBarHidden:Bool {
        StatusBarManager.shared.isHidden
    }
    
    //MARK: 設置StatusBar樣式
    ///設置StatusBar樣式
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        StatusBarManager.shared.style
    }
    
    //MARK: 設置StatusBar動畫
    ///設置StatusBar動畫
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        StatusBarManager.shared.animation
    }
            
    //MARK: 是否隱藏NavBar
    ///是否隱藏NavBar
    public convenience init(hideBaseNavBar: Bool) {
        self.init()
        hidesBaseNavigationBarOnLoad = hideBaseNavBar
    }
            
    //MARK: 動態更換StatusBar
    ///動態更換StatusBar
    open func changeStatusBar(type:VCStatusBarChangeStatusType) {
        switch type {
        case .Auto:
            StatusBarManager.shared.update(with: preferredNavigationBarStyle())
        case .Dark:
            StatusBarManager.shared.update(with: .gradient(colors: [UIColor.clear,UIColor.clear]))
        case .Light:
            StatusBarManager.shared.update(with: .transparent)
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    open func switchOrientation(isFullScreen:Bool) {
        
        PTAppWindowsDelegate.appDelegate()?.isFullScreen = isFullScreen
                
        setNeedsUpdateOfPrefersPointerLocked()
        guard let scence = view.window?.windowScene
                ?? PTSceneContext.activeWindow()?.windowScene else { return }
        let orientation:UIInterfaceOrientationMask = isFullScreen ? .landscape : .portrait
        let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
        scence.requestGeometryUpdate(geometryPreferencesIOS) { error in
            PTNSLogConsole("强制\(isFullScreen ? "横屏" : "竖屏")错误:\(error)",levelType: PTLogMode,loggerType: .viewCycle)
        }
    }
        
    open func baseTraitCollectionDidChange(style:UIUserInterfaceStyle) { }
    
    public func returnFrontVC(completion:PTActionTask? = nil) {
        if let presentingVC = self.presentingViewController {
            dismiss(animated: true, completion: {
                PTNavigationBarManager.shared.restoreIfNeeded(for: presentingVC)
                completion?()
            })
        } else if let nav = navigationController {
            nav.popViewController(animated: true) {
                completion?()
            }
        } else {
            completion?()
        }
#if POOTOOLS_DEBUG
        if UIApplication.shared.inferredEnvironment_PT != .appStore {
            SwizzleTool.swizzleDidAddSubview {
                // Configure console window.
                Task { @MainActor in
                    let lcm = LocalConsole.shared
                    if lcm.isVisiable {
                        if let maskView = lcm.maskView {
                            PTUtils.fetchWindow()?.bringSubviewToFront(maskView)
                        }
                        if let terminal = lcm.terminal {
                            PTUtils.fetchWindow()?.bringSubviewToFront(terminal)
                        }
                    }
                }
            }
        }
#endif
    }
    
    //MARK: 截图反馈注册
    ///截图反馈注册
    public func registerScreenShotService() {
        UIScreen.pt.detectScreenShot { type in
            guard type == .Normal else {
                PTGCDManager.shared.runOnMain {
                    self.screenShotHandle?(nil)
                }
                return
            }

            PTGCDManager.shared.delayOnMain(time: 1) {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

                guard let lastAsset = PHAsset.fetchAssets(with: .image, options: fetchOptions).firstObject,
                      lastAsset.mediaSubtypes == .photoScreenshot else {
                    self.screenShotHandle?(nil)
                    return
                }

                self.getImage(for: lastAsset) { image in
                    guard let image else {
                        PTGCDManager.shared.runOnMain {
                            self.screenShotHandle?(nil)
                        }
                        return
                    }

                    PTGCDManager.shared.runOnMain {
                        if let handler = self.screenShotHandle {
                            handler(image)
                        } else {
                            if self.screenFunc == nil {
                                self.screenFunc = PTBaseScreenShotAlert(screenShotImage: image) {
                                    PTGCDManager.shared.runOnMain {
                                        self.screenFunc = nil
                                    }
                                }
                                if let actionHandle = self.screenShotActionHandle {
                                    self.screenFunc?.actionHandle = actionHandle
                                }
                            } else {
                                self.screenShotHandle?(nil)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension PTBaseViewController {
    public var emptyDataViewConfig:PTEmptyDataViewConfig? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.emptyViewConfigCallBack, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.emptyViewConfigCallBack)
            guard let config = obj as? PTEmptyDataViewConfig else {
                return nil
            }
            return config
        }
    }
}

//MARK: 空数据的界面展示iOS17之后
extension PTBaseViewController {
    
    public func showEmptyView(task: PTActionTask? = nil) {
        // 使用 if let 解包更安全、更 Swift 风格
        if let config = emptyDataViewConfig {
            PTUnavailableManager.render(.empty, in: self, config: config, action: task)
        } else {
            assertionFailure("如果使用该功能,则须要设置emptyDataViewConfig")
        }
    }
    
    public func hideEmptyView(task: PTActionTask? = nil) {
        PTUnavailableManager.render(.content, in: self)
        task?()
    }
    
    public func emptyViewLoading() {
        PTUnavailableManager.render(.loading, in: self)
    }
}

//MARK: 界面截图后,提供分享以及反馈引导操作
extension PTBaseViewController {
        
    public var screenShotHandle:PTScreenShotOnlyGetImageHandle? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.screenShotOnlyGetImageCallBack, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.screenShotOnlyGetImageCallBack)
            guard let handle = obj as? PTScreenShotOnlyGetImageHandle else {
                return nil
            }
            return handle
        }
    }

    public var screenShotActionHandle:PTScreenShotImageHandle? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.screenShotActionCallBack, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.screenShotActionCallBack)
            guard let handle = obj as? PTScreenShotImageHandle else {
                return nil
            }
            return handle
        }
    }

    fileprivate var screenFunc:PTBaseScreenShotAlert? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.screenShotAlertCallBack, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.screenShotAlertCallBack)
            guard let handle = obj as? PTBaseScreenShotAlert else {
                return nil
            }
            return handle
        }
    }
        
    func getImage(for asset: PHAsset,finish:@escaping @Sendable (UIImage?) -> Void) {
        asset.convertLivePhotoToImage { result in
            finish(result)
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first else {
            return
        }
                
        let touchLocation = touch.location(in: view)
        if let scree = screenFunc {
            if !scree.frame.contains(touchLocation) {
                scree.dismissAlert()
            }
        }
    }
}

extension PTBaseViewController {
    @MainActor
    public func currentPresentToSheet(vc:UIViewController,overlayColor:UIColor = UIColor(white: 0, alpha: 0.25), sizes: [PTSheetSize] = [.intrinsic], options: PTSheetOptions? = nil) {
        UIViewController.currentPresentToSheet(vc: vc,overlayColor: overlayColor,sizes: sizes,options: options)
    }
}

//MARK: ScreenShot的小控件
fileprivate class PTBaseScreenShotAlert:UIView {
                
    let ItemWidth:CGFloat = 88
    let ItemHeight:CGFloat = 164
    
    var dismissTask:PTActionTask?
    
    var actionHandle:PTScreenShotImageHandle?
    
    private var AnimationValue:CGFloat {
        ItemWidth + PTAppBaseConfig.share.defaultViewSpace
    }
    
    private lazy var closeButton : UIButton = {
        let view = UIButton(type: .close)
        view.addActionHandlers { sender in
            self.dismissAlert()
        }
        return view
    }()
    
    lazy var shareImageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var feedback:PTLayoutButton = {
        let view = self.viewLayoutBtnSet(title: "PT Screen feedback".localized(), image: PTAppBaseConfig.share.screenShotFeedback)
        view.addActionHandlers { sender in
            if let image = self.shareImageView.image {
                self.actionHandle?(.Feedback,image)
                self.dismissAlert()
            }
        }
        return view
    }()
    
    private lazy var share:PTLayoutButton = {
        let view = self.viewLayoutBtnSet(title: "PT Screen share".localized(), image: PTAppBaseConfig.share.screenShotShare)
        view.addActionHandlers { _ in
            if let image = self.shareImageView.image {
                self.actionHandle?(.Share,image)
                self.dismissAlert()
            }
        }
        return view
    }()

    private lazy var line:UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()

    init(screenShotImage:UIImage,dismiss: PTActionTask? = nil) {
        super.init(frame: CGRect(x: CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace - ItemWidth, y: CGFloat.kSCREEN_HEIGHT - CGFloat.kTabbarHeight_Total - ItemHeight - 15 - CGFloat.kNavBarHeight_Total, width: ItemWidth, height: ItemHeight))
        backgroundColor = .DevMaskColor
        
        dismissTask = dismiss
        
        addSubviews([closeButton,feedback,line,share,shareImageView])
        closeButton.snp.makeConstraints { make in
            make.right.top.equalToSuperview().inset(5)
            make.width.height.equalTo(15)
        }
        
        feedback.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.bottom.equalToSuperview()
            make.height.equalTo(24)
        }
        
        line.snp.makeConstraints { make in
            make.left.right.equalTo(self.feedback)
            make.height.equalTo(1)
            make.top.equalTo(self.feedback.snp.top)
        }
        
        share.snp.makeConstraints { make in
            make.left.right.height.equalTo(self.feedback)
            make.bottom.equalTo(self.line.snp.top)
        }
        
        shareImageView.image = screenShotImage
        shareImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(5)
            make.top.equalTo(closeButton.snp.bottom).offset(5)
            make.bottom.equalTo(self.share.snp.top).offset(-5)
        }
        
        PTUtils.getCurrentVC()?.view.addSubview(self)
        showAlert()
        
        Task { @MainActor in
            self.viewCorner(radius: 5,borderWidth: 0,borderColor: .clear)
            self.shareImageView.viewCorner(radius: 5)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showAlert() {
        PTAnimationFunction.animationIn(animationView: self, animationType: .Right, transformValue: AnimationValue)
    }
    
    func dismissAlert() {
        PTAnimationFunction.animationOut(animationView: self, animationType: .Right, toValue: AnimationValue, animation: {
            Task { @MainActor in
                self.alpha = 0
            }
        }) { ok in
            Task { @MainActor in
                self.removeFromSuperview()
                self.dismissTask?()
            }
        }
    }
    
    func viewLayoutBtnSet(title:String,image:Any) -> PTLayoutButton {
        let view = PTLayoutButton()
        view.layoutStyle = .leftImageRightTitle
        view.midSpacing = 5
        view.imageSize = CGSize(width: 15, height: 15)
        view.normalTitleFont = .appfont(size: 13)
        view.normalTitle = title
        view.normalTitleColor = .white
        view.layoutLoadImage(contentData: image)
        return view
    }
}
