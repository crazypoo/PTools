//
//  PTBaseTabBarViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/17/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

open class PTBaseTabBarViewController: UITabBarController {
    
    public var ptCustomBar = PTTabBarView()
    
    public var centerRaisedSet:Bool = false {
        didSet {
            guard accessoryContainerInstalled else { return }
            accessoryContainerView.snp.updateConstraints { make in
                make.bottom.equalTo(ptCustomBar.snp.top).offset(-(PTAppBaseConfig.share.tabBarAccessoryBottomSpacing + (centerRaisedSet ? PTAppBaseConfig.share.tabbarCenterButtonSize / 2 : 0)))
            }
        }
    }
    
    // 🌟 新增：全局挂载 Accessory 视图的容器
    public let accessoryContainerView = PTAccessoryContainerView()
    // 记录当前正在展示的子内容视图
    private var currentAccessoryContentView: UIView?
    // 🌟 新增：专门用于毛玻璃效果的背景视图
    private let accessoryBlurView = UIVisualEffectView()
    // 🌟 新增：顶部分割线（可选，增加精致感）
    private let topBorderLine = UIView()

    // 🌟 新增：记录 TabBar 是否因为 Push 到了子页面而被整体隐藏
    private var isTabBarGloballyHidden: Bool = false
    // 🌟 新增：记录当前的最小化状态和圆圈尺寸
    private var isTabBarMinimized: Bool = false
    private let minimizedCircleSize: CGFloat = PTAppBaseConfig.share.tabbarMiniSize
    
    // MARK: - ScrollView 监听相关属性
    
    /// 保存当前 KVO 监听对象，防止被释放
    private var scrollObservation: NSKeyValueObservation?
    private var scrollBindingTask: Task<Void, Never>?
    private var scrollUpdateTask: Task<Void, Never>?
    private var pendingScrollState: (distanceFromTop: CGFloat, offsetY: CGFloat)?
    private var accessoryContainerInstalled = false
    private var tabBarVisibilityGeneration = 0
    private var accessoryTransitionGeneration = 0
    private var isSynchronizingSelection = false
    
    /// 滑动状态回调：是否已经向下滑动、当前的 Y 轴偏移量
    public var didScrollStateChange: ((_ isScrolled: Bool, _ offsetY: CGFloat) -> Void)?

    open override var selectedIndex: Int {
        didSet {
            synchronizeCustomSelection()
        }
    }

    open override var selectedViewController: UIViewController? {
        didSet {
            synchronizeCustomSelection()
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncInitialTabBarState()
    }

    deinit {
        scrollBindingTask?.cancel()
        scrollUpdateTask?.cancel()
        scrollObservation?.invalidate()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         //如果想要类似iPad的展示形式需要在scene或者appdelegate上设置
         //tabBarController.mode = .tabSidebar
         */
        setupTabBar()
        setupAccessoryContainer() // 🌟 初始化容器

        registerNavigationControllers(from: viewControllers)
    }

    open override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        registerNavigationControllers(from: viewControllers)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 系统 TabBar 只作为 UITabBarController 的承载对象，不参与绘制。
        if !tabBar.isHidden {
            tabBar.isHidden = true
        }
        if !tabBar.frame.equalTo(.zero) {
            tabBar.frame = .zero
        }
    }
    
    // MARK: 设置UIViewController
    public func configViewController(viewController: UIViewController, title: String) -> PTBaseNavControl {
        let navigationController = PTBaseNavControl(rootViewController: viewController)
        return navigationController
    }
    
    private func setupTabBar() {
        tabBar.isHidden = false
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = true
        tabBar.alpha = 0
        
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        view.addSubview(ptCustomBar)
        ptCustomBar.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(CGFloat.kTabbarHeight_Total)
        }
        
        ptCustomBar.didSelectInsideIndex =  { [weak self] index in
            guard let self,
                  self.viewControllers?.indices.contains(index) == true else { return }

            if self.selectedIndex != index {
                self.isSynchronizingSelection = true
                self.selectedIndex = index
                self.isSynchronizingSelection = false
            }
            self.syncInitialTabBarState()
        }
    }
    
    // 🌟 新增：设置卡槽容器的初始布局
    private func setupAccessoryContainer() {
        view.addSubview(accessoryContainerView)
        accessoryContainerView.clipsToBounds = true
        accessoryContainerView.backgroundColor = .clear
        
        // 1. 配置毛玻璃材质 (与你的 CustomBar 保持视觉统一)
        if PTAppBaseConfig.share.tab26Mode {
            accessoryBlurView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            accessoryBlurView.effect = UIBlurEffect(style: .systemMaterial)
        }
        accessoryContainerView.addSubview(accessoryBlurView)
        accessoryBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 2. 添加顶部半透明高光线
        topBorderLine.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        accessoryContainerView.addSubview(topBorderLine)
        topBorderLine.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        // 3. 基础容器约束 (初始高度为 0)
        accessoryContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.tabbarBar26LRSpacing)
            make.bottom.equalTo(ptCustomBar.snp.top).offset(-(PTAppBaseConfig.share.tabBarAccessoryBottomSpacing + (centerRaisedSet ? PTAppBaseConfig.share.tabbarCenterButtonSize / 2 : 0)))
            make.height.equalTo(0)
        }
        accessoryContainerInstalled = true
    }

    open func configure(items: [PTTabBarItemConfig]) {
        let vcs = items.map { item -> UIViewController in
            return item.viewController
        }
        viewControllers = vcs
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.syncInitialTabBarState()
        }
    }

    private func registerNavigationControllers(from viewControllers: [UIViewController]?) {
        guard let viewControllers else { return }

        var registered = Set<ObjectIdentifier>()
        for viewController in viewControllers {
            for navigationController in navigationControllers(in: viewController) {
                guard registered.insert(ObjectIdentifier(navigationController)).inserted else { continue }

                let manager = PTNavigationBarManager.shared
                manager.bind(to: navigationController)
                manager.setTabBarHandler({ [weak self] nav, toVC, animated, coordinator in
                    guard let self, self.ownsNavigationController(nav) else { return }
                    self.handleTabBar(nav: nav, to: toVC, animated: animated, coordinator: coordinator)
                }, for: navigationController)
            }
        }
    }

    private func navigationControllers(in viewController: UIViewController) -> [UINavigationController] {
        if let navigationController = viewController as? UINavigationController {
            return [navigationController]
        }

        var result: [UINavigationController] = []
        if let sideMenu = viewController as? PTSideMenuControl,
           let contentViewController = sideMenu.contentViewController {
            result.append(contentsOf: navigationControllers(in: contentViewController))
        }

        for child in viewController.children {
            result.append(contentsOf: navigationControllers(in: child))
        }
        return result
    }

    private func ownsNavigationController(_ navigationController: UINavigationController) -> Bool {
        if navigationController.tabBarController === self {
            return true
        }

        return (viewControllers ?? []).contains { viewController in
            navigationControllers(in: viewController).contains { $0 === navigationController }
        }
    }
    
    private func handleTabBar(nav: UINavigationController,
                              to viewController: UIViewController,
                              animated: Bool,
                              coordinator: UIViewControllerTransitionCoordinator?) {
        
        // 👉 fallback（无动画）
        guard let coordinator else {
            updateTabBar(to: viewController, animated: animated)
            return
        }
        
        // 👉 动画同步（push / pop）
        coordinator.animate(alongsideTransition: { _ in
            // The transition coordinator owns the animation. Starting a nested
            // UIView animation here can leave the custom bar in a stale state.
            self.updateTabBar(to: viewController, animated: false)
        }, completion: { context in
            
            // ❗取消手势
            if context.isCancelled {
                if let fromVC = context.viewController(forKey: .from) {
                    self.updateTabBar(to: fromVC, animated: false)
                }
            } else {
                // ✅ 最终状态（popToRoot 关键）
                if let toVC = context.viewController(forKey: .to) {
                    self.updateTabBar(to: toVC, animated: false)
                }
            }
        })
    }
    
    private func syncInitialTabBarState() {
        guard let target = currentContentViewController() else { return }
        let targetVC = target
        // 🌟 核心补救：强制加载当前目标页面的 View，确保它的 viewDidLoad 立刻执行！
        targetVC.loadViewIfNeeded()

        updateTabBar(to: targetVC, animated: false)
    }

    private func currentContentViewController() -> UIViewController? {
        guard let selectedVC = selectedViewController else { return nil }

        return PTUtils.getCurrentVC(from: selectedVC)
    }

    private func synchronizeCustomSelection() {
        guard !isSynchronizingSelection,
              selectedIndex >= 0,
              selectedIndex < ptCustomBar.items.count else { return }

        isSynchronizingSelection = true
        ptCustomBar.synchronizeSelection(to: selectedIndex)
        isSynchronizingSelection = false

        if isViewLoaded {
            syncInitialTabBarState()
        }
    }
    
    // 🌟 新增：执行外层容器的形变动画
    private func updateTabBarMinimizeState(shouldMinimize: Bool, animated: Bool = true, force: Bool = false) {
        
        if isTabBarGloballyHidden && !force { return }
        
        let stateChanged = (isTabBarMinimized != shouldMinimize)
        guard force || stateChanged else { return }
        isTabBarMinimized = shouldMinimize
        
        if force || stateChanged {
            
            ptCustomBar.toggleMinimize(isMinimized: shouldMinimize, selectedIndex: selectedIndex)
            
            let normalHeight = CGFloat.kTabbarHeight_Total
            
            // 🌟 将更新约束的逻辑单独提取出来
            let updateConstraints = {
                self.ptCustomBar.snp.remakeConstraints { make in
                    if shouldMinimize {
                        let safeBottom = Gobal_device_info.isFaceIDCapable ? PTAppBaseConfig.share.tab26BottomSpacing : 16
                        make.left.equalToSuperview().offset(20)
                        make.bottom.equalToSuperview().offset(-safeBottom)
                        make.width.height.equalTo(self.minimizedCircleSize)
                    } else {
                        make.left.right.equalToSuperview()
                        make.bottom.equalToSuperview()
                        make.height.equalTo(normalHeight)
                    }
                }
            }
            
            if animated {
                // 有滑动动画时，先更新约束，再在动画块里强刷布局
                updateConstraints()
                UIView.animate(withDuration: 0.4,
                               delay: 0,
                               usingSpringWithDamping: 0.8,
                               initialSpringVelocity: 0.5,
                               options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
                               animations: {
                    self.view.layoutIfNeeded()
                    self.ptCustomBar.layoutIfNeeded()
                })
            } else {
                // 🌟 修复点 2：在无动画（例如 Push 转场）时，只更新约束方程！
                // 绝不调用 self.view.layoutIfNeeded()，让系统在下一个生命周期自然渲染，防止打断 B 界面的 ScrollView 布局！
                updateConstraints()
            }
        }
    }
}

extension PTBaseTabBarViewController {
    private func updateTabBar(to viewController: UIViewController,
                              animated: Bool) {
        let hidden = viewController.pt_prefersTabBarHidden
        // 🌟 第一时间上锁，告诉全局：“我要进入二级页面了，谁也别动 TabBar 的约束！”
        isTabBarGloballyHidden = hidden
        
        if hidden {
            accessoryContainerView.isUserInteractionEnabled = false
        } else {
            accessoryContainerView.isHidden = false
            accessoryContainerView.isUserInteractionEnabled = true
        }

        // Reset only when necessary. Rebuilding constraints for every page
        // transition causes needless layout work and animation interruptions.
        if isTabBarMinimized {
            updateTabBarMinimizeState(shouldMinimize: false, animated: false, force: true)
        }
        setTabBar(hidden: hidden, animated: animated)
        
        // 2. 🌟 切换 AccessoryView 逻辑
        // 如果整体 TabBar 都要隐藏，Accessory 自然也要强制隐藏
        let targetAccessoryView = hidden ? nil : viewController.pt_tabBarAccessoryView
        switchAccessoryView(to: targetAccessoryView, animated: animated)

        // 🌟 新增：更新 TabBar 状态的同时，监听新页面的 ScrollView 滑动状态
        if hidden {
            cancelScrollObservation()
            PTNSLogConsole("拦截：TabBar 已隐藏，跳过 ScrollView 绑定")
        } else {
            // 只有 TabBar 需要显示时，才去绑定监听
            if PTAppBaseConfig.share.tabbarScrollEnabled {
                observeScrollView(in: viewController)
            } else {
                cancelScrollObservation()
                PTNSLogConsole("拦截：TabBar 已隐藏，跳过 ScrollView 绑定")
            }
        }
    }
    
    public func setTabBar(hidden: Bool, animated: Bool) {
        tabBarVisibilityGeneration &+= 1
        let generation = tabBarVisibilityGeneration
        tabBar.isHidden = true
                
        let height = CGFloat.kTabbarHeight_Total

        let offsetY: CGFloat = hidden ? height : 0
        let transform = CGAffineTransform(translationX: 0, y: offsetY)
        
        // 🌟 修复点 2：双重保险的透明度
        let targetAlpha: CGFloat = hidden ? 0 : 1

        let updateState = {
            self.ptCustomBar.transform = transform
            self.ptCustomBar.alpha = targetAlpha
        }
        
        // 确保显示前，物理隐藏状态是打开的
        if !hidden {
            self.ptCustomBar.isHidden = false
            self.ptCustomBar.minimizedCenterView.isHidden = false
        }

        if animated {
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseInOut, .beginFromCurrentState],
                           animations: {
                updateState()
            }, completion: { [weak self] _ in
                guard let self, generation == self.tabBarVisibilityGeneration else { return }
                if hidden && self.isTabBarGloballyHidden {
                    self.ptCustomBar.isHidden = true
                }
            })
        } else {
            updateState()
            self.ptCustomBar.isHidden = hidden
        }
    }
    
    // 🌟 新增：执行 Accessory 视图的无缝插拔动画
    private func switchAccessoryView(to newContentView: UIView?, animated: Bool) {
        guard newContentView !== currentAccessoryContentView else {
            if isTabBarGloballyHidden {
                accessoryContainerView.isHidden = true
            } else if newContentView != nil {
                accessoryContainerView.isHidden = false
            }
            return
        }

        accessoryTransitionGeneration &+= 1
        let generation = accessoryTransitionGeneration
                
        let oldView = currentAccessoryContentView
        currentAccessoryContentView = newContentView
        
        // 1. 将新视图添加到卡槽顶层 (盖在 blurView 和 borderLine 上面)
        if let newView = newContentView {
            accessoryContainerView.addSubview(newView)
            newView.snp.remakeConstraints { make in
                // 顶部避开 0.5pt 的高光线
                make.top.equalToSuperview().offset(0.5)
                make.left.right.bottom.equalToSuperview()
            }
            if !isTabBarGloballyHidden {
                accessoryContainerView.isHidden = false
            }
        }
        
        // 2. 🌟 核心固化：直接读取全局统一配置的高度常量
        let standardHeight = PTAppBaseConfig.share.tabBarAccessoryHeight
        let targetHeight: CGFloat = (newContentView != nil) ? standardHeight : 0
        
        // 更新高度约束
        accessoryContainerView.snp.updateConstraints { make in
            make.height.equalTo(targetHeight)
        }
        accessoryContainerView.viewCorner(radius: standardHeight / 2)
        
        // 🌟 核心动作封装
        let updateUIBlock = {
            oldView?.alpha = 0
            newContentView?.alpha = 1
            // ⚠️ 局部刷新自身布局即可，绝不调用 self.view.layoutIfNeeded() 干扰 UINavigationController！
            self.accessoryContainerView.layoutIfNeeded()
        }

        let completionBlock = { [weak self] in
            guard let self, generation == self.accessoryTransitionGeneration else { return }

            // Remove every stale content view, not just the immediately
            // previous one. This also covers rapid A -> B -> C switches.
            self.accessoryContainerView.subviews
                .filter { $0 !== self.accessoryBlurView && $0 !== self.topBorderLine && $0 !== newContentView }
                .forEach { $0.removeFromSuperview() }

            // 🌟 闭环保护：如果收缩为 0，立刻彻底物理隐藏
            if targetHeight == 0 || self.isTabBarGloballyHidden {
                self.accessoryContainerView.isHidden = true
            } else {
                self.accessoryContainerView.isHidden = false
            }
        }
        
        // 3. 执行丝滑转场动画
        if animated {
            newContentView?.alpha = 0
            UIView.animate(withDuration: 0.25,delay: 0, options: [.curveEaseInOut], animations: {
                updateUIBlock()
            }) { _ in
                completionBlock()
            }
        } else {
            updateUIBlock()
            completionBlock()
        }
    }
}

extension PTBaseTabBarViewController {
    // MARK: - ScrollView 监听逻辑
        
    /// 在给定的 View 层级中递归寻找第一个 UIScrollView
    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            let verticalContentHeight = scrollView.contentSize.height
                + scrollView.adjustedContentInset.top
                + scrollView.adjustedContentInset.bottom
            let canScrollVertically = scrollView.alwaysBounceVertical
                || verticalContentHeight > scrollView.bounds.height + 1
            if scrollView.isScrollEnabled && canScrollVertically {
                return scrollView
            }
        }
        
        for subview in view.subviews {
            if let found = findScrollView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    /// 为指定的 ViewController 绑定滑动监听
    private func observeScrollView(in viewController: UIViewController) {
        cancelScrollObservation()
        
        viewController.loadViewIfNeeded()
        // 让新页面先完成一轮布局，同时保留页面切换时的取消能力。
        scrollBindingTask = Task { @MainActor [weak self, weak viewController] in
            await Task.yield()
            guard !Task.isCancelled,
                  let self,
                  let viewController,
                  !self.isTabBarGloballyHidden,
                  self.currentContentViewController() === viewController else { return }

            // 1. 优先获取 VC 主动指定的 ScrollView
            let targetScrollView = viewController.pt_observedScrollView ?? self.findScrollView(in: viewController.view)
                        
            guard let scrollView = targetScrollView else {
                // 如果真的没有 ScrollView，说明这是一个纯静态页面
                PTNSLogConsole("⚠️ 当前页面没有找到可监听的 ScrollView: \(viewController)")
                // 此时也可以主动抛出一个初始状态给外部，告诉它“没有滑动”
                self.didScrollStateChange?(false, 0)
                return
            }
            
            PTNSLogConsole("✅ 成功绑定 ScrollView 监听: \(viewController)")

            
            let adjustedTopInset = scrollView.adjustedContentInset.top
            self.scrollObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, change in
                guard let offsetY = change.newValue?.y else { return }
                let distanceFromTop = offsetY + adjustedTopInset
                Task { @MainActor [weak self] in
                    self?.enqueueScrollUpdate(distanceFromTop: distanceFromTop, offsetY: offsetY)
                }
            }

            let initialOffsetY = scrollView.contentOffset.y
            let initialDistanceFromTop = initialOffsetY + adjustedTopInset
            self.updateTabBarMinimizeState(shouldMinimize: initialDistanceFromTop > PTAppBaseConfig.share.tabbarScrollOffset, animated: false)
            self.didScrollStateChange?(initialDistanceFromTop > 0, initialOffsetY)
        }
    }

    private func cancelScrollObservation() {
        scrollBindingTask?.cancel()
        scrollBindingTask = nil
        scrollUpdateTask?.cancel()
        scrollUpdateTask = nil
        pendingScrollState = nil
        scrollObservation?.invalidate()
        scrollObservation = nil
    }

    private func enqueueScrollUpdate(distanceFromTop: CGFloat, offsetY: CGFloat) {
        guard !isTabBarGloballyHidden else { return }

        pendingScrollState = (distanceFromTop: distanceFromTop, offsetY: offsetY)
        guard scrollUpdateTask == nil else { return }

        scrollUpdateTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, !Task.isCancelled else { return }

            let state = self.pendingScrollState
            self.pendingScrollState = nil
            self.scrollUpdateTask = nil

            guard let state, !self.isTabBarGloballyHidden else { return }

            let shouldMinimize = state.distanceFromTop > PTAppBaseConfig.share.tabbarScrollOffset
            self.updateTabBarMinimizeState(shouldMinimize: shouldMinimize)
            self.didScrollStateChange?(state.distanceFromTop > 0, state.offsetY)
        }
    }
}

extension PTBaseTabBarViewController {
    // 🌟 修复处 2：新增暴露给协议调用的即时刷新接口
    public func refreshCurrentAccessoryViewIfNeeded() {
        guard let targetVC = currentContentViewController() else { return }
        // 只有当全局没有隐藏 TabBar 时，才去主动切换卡槽内容
        if !isTabBarGloballyHidden {
            switchAccessoryView(to: targetVC.pt_tabBarAccessoryView, animated: true)
        }
    }
}
