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

private var kPTTabBarHiddenKey: Void?
private var kPTTabBarAccessoryViewKey: Void?

public protocol PTTabBarVisibilityProtocol {
    var pt_prefersTabBarHidden: Bool { get set }
    // 🌟 新增：允许控制器主动抛出需要监听的 ScrollView
    var pt_observedScrollView: UIScrollView? { get }
    // 🌟 新增：允许控制器挂载专属的 AccessoryView
    var pt_tabBarAccessoryView: UIView? { get set }
}

extension UIViewController: PTTabBarVisibilityProtocol {
    public var pt_prefersTabBarHidden: Bool {
        get {
            return (objc_getAssociatedObject(self, &kPTTabBarHiddenKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &kPTTabBarHiddenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 🌟 新增默认实现：默认不指定，保证旧代码不报错
    @objc open var pt_observedScrollView: UIScrollView? {
        return nil
    }
    
    public var pt_tabBarAccessoryView: UIView? {
        get {
            return objc_getAssociatedObject(self, &kPTTabBarAccessoryViewKey) as? UIView
        }
        set {
            let oldValue = pt_tabBarAccessoryView
            guard oldValue !== newValue else { return }
            
            objc_setAssociatedObject(self, &kPTTabBarAccessoryViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // 🌟 响应式修复：如果当前控制器正在被展示，立刻通知 TabBarController 更新容器
            // 遍历寻找外层的自定义 TabBar 容器
            var nextVC: UIViewController? = self
            while let current = nextVC {
                if let tabBarVC = current.tabBarController as? PTBaseTabBarViewController {
                    // 确保赋值的控制器属于当前选中的链路，防止后台 Tab 乱刷新当前界面
                    // 延迟一帧等待关联对象彻底稳固
                    DispatchQueue.main.async {
                        tabBarVC.refreshCurrentAccessoryViewIfNeeded()
                    }
                    break
                }
                nextVC = current.parent
            }
        }
    }
}

public class PTAccessoryContainerView: UIView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        // 1. 如果自身被隐藏、透明度极低，或者高度几乎为 0，绝对不拦截任何点击
        if self.isHidden || self.alpha < 0.01 || self.frame.height < 5 {
            return nil
        }
        
        // 2. 只有当确实点击到了内部实际内容时，才进行响应
        return view
    }
}

open class PTBaseTabBarViewController: UITabBarController {
    
    public var ptCustomBar = PTTabBarView()
    
    public var centerRaisedSet:Bool = false {
        didSet {
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
    
    /// 滑动状态回调：是否已经向下滑动、当前的 Y 轴偏移量
    public var didScrollStateChange: ((_ isScrolled: Bool, _ offsetY: CGFloat) -> Void)?
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncInitialTabBarState()
        
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         //如果想要类似iPad的展示形式需要在scene或者appdelegate上设置
         //tabBarController.mode = .tabSidebar
         */
        setupTabBar()
        setupAccessoryContainer() // 🌟 初始化容器

        PTNavigationBarManager.shared.tabBarHandler = { [weak self] nav, toVC, animated, coordinator in
            guard let self = self else { return }
            // 🌟 修复点 1：升级拦截逻辑，支持深度查找嵌套的 NavigationController
            guard let vcs = self.viewControllers else { return }
            
            let isOurNav = vcs.contains { vc in
                // 情况 A：Tab 的根控制器直接就是这个 nav
                if vc === nav { return true }
                
                // 情况 B：Tab 的根控制器是侧边栏，nav 被包裹在里面
                if let sideMenu = vc as? PTSideMenuControl {
                    return sideMenu.contentViewController === nav || sideMenu.navigationController === nav
                }
                
                return false
            }
            
            // 双重保险：或者是原生系统层级判定属于我们
            let belongsToUs = isOurNav || (nav.tabBarController === self)
            
            guard belongsToUs else {
                PTNSLogConsole("拦截：外部的 nav 触发路由，不处理 TabBar")
                return
            }
            
            self.handleTabBar(nav: nav, to: toVC, animated: animated, coordinator: coordinator)
        }
                
        didScrollStateChange = { [weak self] isScrolled,offsetY in
            guard let self = self else { return }
            if PTAppBaseConfig.share.tabbarScrollEnabled {
                // 增加一点偏移量阈值 (例如 20)，防止用户刚碰一下屏幕就触发
                let shouldMinimize = isScrolled && offsetY > PTAppBaseConfig.share.tabbarScrollOffset
                self.updateTabBarMinimizeState(shouldMinimize: shouldMinimize)
            }
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tabBar.isHidden = true   // ✅ 重新加回来（但只做隐藏，不参与动画）
        tabBar.frame = .zero   // ❗彻底干掉系统 tabBar
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
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
        
        view.addSubview(ptCustomBar)
        ptCustomBar.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(CGFloat.kTabbarHeight_Total)
        }
        
        ptCustomBar.didSelectInsideIndex =  { _ in
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
            make.bottom.equalTo(ptCustomBar.snp.top).offset(-PTAppBaseConfig.share.tabBarAccessoryBottomSpacing)
            make.height.equalTo(0)
        }
    }

    open func configure(items: [PTTabBarItemConfig]) {
        let vcs = items.map { item -> UIViewController in
            return item.viewController
        }
        viewControllers = vcs
        DispatchQueue.main.async {
            self.syncInitialTabBarState()
        }
    }
    
    private func handleTabBar(nav: UINavigationController,
                              to viewController: UIViewController,
                              animated: Bool,
                              coordinator: UIViewControllerTransitionCoordinator?) {
        
        // 👉 fallback（无动画）
        guard let coordinator else {
            updateTabBar(for: nav, to: viewController, animated: animated)
            return
        }
        
        // 👉 动画同步（push / pop）
        coordinator.animate(alongsideTransition: { _ in
            self.updateTabBar(for: nav, to: viewController, animated: animated)
        }, completion: { context in
            
            // ❗取消手势
            if context.isCancelled {
                if let fromVC = context.viewController(forKey: .from) {
                    self.updateTabBar(for: nav, to: fromVC, animated: false)
                }
            } else {
                // ✅ 最终状态（popToRoot 关键）
                if let toVC = context.viewController(forKey: .to) {
                    self.updateTabBar(for: nav, to: toVC, animated: false)
                }
            }
        })
    }
    
    private func syncInitialTabBarState() {
        guard let selectedVC = selectedViewController else { return }
        
        var targetVC: UIViewController = selectedVC
        var targetNav: UINavigationController? = selectedVC.navigationController
        
        if let sideMenu = selectedVC as? PTSideMenuControl {
            targetVC = sideMenu.contentViewController ?? sideMenu
            targetNav = sideMenu.navigationController
        }
        
        if let nav = targetVC as? UINavigationController {
            targetNav = nav
            if let topVC = nav.topViewController {
                targetVC = topVC
            }
        }
        
        // 🌟 核心补救：强制加载当前目标页面的 View，确保它的 viewDidLoad 立刻执行！
        targetVC.loadViewIfNeeded()
        
        updateTabBar(for: targetNav, to: targetVC, animated: false)
    }
    
    // 🌟 新增：执行外层容器的形变动画
    private func updateTabBarMinimizeState(shouldMinimize: Bool, animated: Bool = true, force: Bool = false) {
        
        if isTabBarGloballyHidden && !force { return }
        
        let stateChanged = (isTabBarMinimized != shouldMinimize)
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

@available(iOS 18.0, *)
extension PTBaseTabBarViewController {
    // MARK: 设置Tab
    public func configTab(_ viewController: UIViewController,
                          title: String,
                          image: UIImage,
                          identifier: String,
                          badgeValue: String? = nil) -> UITab {
        
        let tab = UITab(title: title, image: image, identifier: identifier) { tab in
            // 角标
            tab.badgeValue = badgeValue
            // 关联对象
            tab.userInfo = identifier
            // 返回显示的UIViewController
            return self.configViewController(viewController: viewController, title: title)
        }
        // Tab内容的显示方式
        tab.preferredPlacement = .sidebarOnly
        return tab
    }

    // MARK: 设置UITabGroup
    public func configTabGroup(_ viewController: UIViewController,
                               title: String,
                               image: UIImage,
                               identifier: String,
                               tabs:[UITab],
                               badgeValue: String? = nil) -> UITabGroup {
        // UITabGroup
        let tabGroup = UITabGroup(title: title, image: image, identifier: identifier) { _ in
            // 返回显示的UIViewController
            return self.configViewController(viewController: viewController, title: title)
        }
        // 可以添加多个Tab，siderBar时肯定会显示，tabBar时根据Tab的preferredPlacement取值决定
        tabGroup.children.append(contentsOf: tabs)
        return tabGroup
    }
}

// MARK: - 新增代理方法
extension PTBaseTabBarViewController: UITabBarControllerDelegate {
    // MARK: Tab是否可以选中
    @available(iOS 18.0, *)
    open func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
        return true
    }

    // MARK: 选中Tab
    @available(iOS 18.0, *)
    open func tabBarController(_ tabBarController: UITabBarController, didSelectTab selectedTab: UITab, previousTab: UITab?) {
        PTNSLogConsole(previousTab?.title ?? "", selectedTab.title)
    }

    // MARK: 开始编辑
    open func tabBarControllerWillBeginEditing(_ tabBarController: UITabBarController) {
        PTNSLogConsole(#function)
    }

    // MARK: 结束编辑
    open func tabBarControllerDidEndEditing(_ tabBarController: UITabBarController) {
        PTNSLogConsole(#function)
    }

    // MARK: UITabGroup中的顺序发生变化
    @available(iOS 18.0, *)
    open func tabBarController(_ tabBarController: UITabBarController, displayOrderDidChangeFor group: UITabGroup) {
        PTNSLogConsole(#function)
    }
}

extension PTBaseTabBarViewController {
    private func updateTabBar(for navigationController: UINavigationController?,
                              to viewController: UIViewController,
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

        // 🌟 修复 1：每次切换页面或 Tab 时，强制重置为展开状态
        updateTabBarMinimizeState(shouldMinimize: false,animated: false,force: true)
        setTabBar(hidden: hidden, animated: animated)
        
        // 2. 🌟 切换 AccessoryView 逻辑
        // 如果整体 TabBar 都要隐藏，Accessory 自然也要强制隐藏
        let targetAccessoryView = hidden ? nil : viewController.pt_tabBarAccessoryView
        switchAccessoryView(to: targetAccessoryView, animated: animated)

        // 🌟 新增：更新 TabBar 状态的同时，监听新页面的 ScrollView 滑动状态
        if hidden {
            scrollObservation?.invalidate()
            scrollObservation = nil
            PTNSLogConsole("拦截：TabBar 已隐藏，跳过 ScrollView 绑定")
        } else {
            // 只有 TabBar 需要显示时，才去绑定监听
            if PTAppBaseConfig.share.tabbarScrollEnabled {
                observeScrollView(in: viewController)
            } else {
                scrollObservation?.invalidate()
                scrollObservation = nil
                PTNSLogConsole("拦截：TabBar 已隐藏，跳过 ScrollView 绑定")
            }
        }
    }
    
    public func setTabBar(hidden: Bool, animated: Bool) {
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
            }, completion: { _ in
                if hidden {
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
            }
            return
        }
                
        let oldView = currentAccessoryContentView
        currentAccessoryContentView = newContentView
        
        let removeOldBlock = {
            oldView?.removeFromSuperview()
        }
        
        // 1. 将新视图添加到卡槽顶层 (盖在 blurView 和 borderLine 上面)
        if let newView = newContentView {
            // 确保业务视图自身背景透明，否则会遮挡毛玻璃！
            newView.backgroundColor = .clear
            
            accessoryContainerView.addSubview(newView)
            newView.snp.remakeConstraints { make in
                // 顶部避开 0.5pt 的高光线
                make.top.equalToSuperview().offset(0.5)
                make.left.right.bottom.equalToSuperview()
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

        let completionBlock = {
            removeOldBlock()
            oldView?.alpha = 1
            // 🌟 闭环保护：如果收缩为 0，立刻彻底物理隐藏
            if targetHeight == 0 || self.isTabBarGloballyHidden {
                self.accessoryContainerView.isHidden = true
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
        if let scrollView = view as? UIScrollView,
           scrollView.isScrollEnabled,
           scrollView.contentSize.height > 0 || scrollView.alwaysBounceVertical {
            return scrollView
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
        // 先清理旧的
        scrollObservation?.invalidate()
        scrollObservation = nil
        
        viewController.loadViewIfNeeded()
        // 🌟 延迟一点点，确保控制器的子视图都已经 addSubView 完毕
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
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

            
            self.scrollObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, change in
                guard let self = self, let offset = change.newValue else { return }
                
                let isScrolled = offset.y > -scrollView.adjustedContentInset.top
                self.didScrollStateChange?(isScrolled, offset.y)
            }
        }
    }
}

extension PTBaseTabBarViewController {
    // 🌟 修复处 2：新增暴露给协议调用的即时刷新接口
    public func refreshCurrentAccessoryViewIfNeeded() {
        // 重新推导当前顶层 VC
        guard let selectedVC = selectedViewController else { return }
        var targetVC: UIViewController = selectedVC
        
        if let sideMenu = selectedVC as? PTSideMenuControl {
            targetVC = sideMenu.contentViewController ?? sideMenu
        }
        if let nav = targetVC as? UINavigationController, let topVC = nav.topViewController {
            targetVC = topVC
        }
        
        // 只有当全局没有隐藏 TabBar 时，才去主动切换卡槽内容
        if !isTabBarGloballyHidden {
            switchAccessoryView(to: targetVC.pt_tabBarAccessoryView, animated: true)
        }
    }
}
