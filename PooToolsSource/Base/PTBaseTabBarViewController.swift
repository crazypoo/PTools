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

public protocol PTTabBarVisibilityProtocol {
    var pt_prefersTabBarHidden: Bool { get set }
    // 🌟 新增：允许控制器主动抛出需要监听的 ScrollView
    var pt_observedScrollView: UIScrollView? { get }
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
}

open class PTBaseTabBarViewController: UITabBarController {

    public var ptCustomBar = PTTabBarView()
    
    // 🌟 新增：记录当前的最小化状态和圆圈尺寸
    private var isTabBarMinimized: Bool = false
    private let minimizedCircleSize: CGFloat = 56.0

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
        
        PTNavigationBarManager.shared.tabBarHandler = { [weak self] nav, toVC, animated, coordinator in
            guard let self = self else { return }
            // 🌟 修复点 1：只拦截属于当前 TabBarController 的导航栈
            // 这样可以防止 present 出来的新 NavigationController 误触发 TabBar 的显示逻辑
            guard let vcs = self.viewControllers, vcs.contains(nav) else {
                return
            }
            self.handleTabBar(nav: nav, to: toVC, animated: animated, coordinator: coordinator)
        }
        
        /*
        //如果想要类似iPad的展示形式需要在scene或者appdelegate上设置
        //tabBarController.mode = .tabSidebar
         */
        setupTabBar()
        if #available(iOS 26.0, *) {
            // iOS26新增，向下滚动时，只显示第一个与UISearchTab的图标，中间显示辅助UITabAccessory
            self.tabBarMinimizeBehavior = .onScrollDown
        }
        
        ptCustomBar.didSelectIndex = { _ in
            self.syncInitialTabBarState()
        }
        
        didScrollStateChange = { [weak self] isScrolled,offsetY in
            guard let self = self else { return }
            // 增加一点偏移量阈值 (例如 20)，防止用户刚碰一下屏幕就触发
            let shouldMinimize = isScrolled && offsetY > 20
            self.updateTabBarMinimizeState(shouldMinimize: shouldMinimize)
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
        switch selectedViewController {
        case let vc as PTSideMenuControl:
            switch vc.contentViewController {
            case let nav as UINavigationController:
                guard let topVC = nav.topViewController else { return }
                updateTabBar(for: nav, to: topVC, animated: false)
            default:
                guard let nav = vc.navigationController else { return }
                updateTabBar(for: nav, to: vc, animated: false)
            }
        default:
            guard let nav = selectedViewController as? UINavigationController,
                  let topVC = nav.topViewController else { return }
            updateTabBar(for: nav, to: topVC, animated: false)
        }
    }
    
    // 🌟 新增：执行外层容器的形变动画
    private func updateTabBarMinimizeState(shouldMinimize: Bool) {
        // 防止重复执行相同的动画
        guard isTabBarMinimized != shouldMinimize else { return }
        isTabBarMinimized = shouldMinimize

        // 1. 通知 TabBarView 切换内部的 UI 状态（隐藏 StackView，仅显示当前 Icon）
        ptCustomBar.toggleMinimize(isMinimized: shouldMinimize, selectedIndex: selectedIndex)

        // 2. 计算原本状态下的高度
        let normalHeight = CGFloat.kTabbarHeight_Total

        // 3. 使用带有弹簧效果的优美动画，改变 ptCustomBar 的外层约束
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseInOut, .allowUserInteraction]) {

            self.ptCustomBar.snp.remakeConstraints { make in
                if shouldMinimize {
                    // 变为圆形并停靠在左下角
                    let safeBottom = Gobal_device_info.isFaceIDCapable ? PTAppBaseConfig.share.tab26BottomSpacing : 16
                    make.left.equalToSuperview().offset(PTAppBaseConfig.share.defaultViewSpace)
                    make.bottom.equalToSuperview().offset(-safeBottom)
                    make.width.height.equalTo(self.minimizedCircleSize)
                } else {
                    // 恢复铺满底部
                    make.left.right.equalToSuperview()
                    make.bottom.equalToSuperview()
                    make.height.equalTo(normalHeight)
                }
            }

            // 强制刷新布局以产生过渡动画
            self.view.layoutIfNeeded()
            self.ptCustomBar.layoutIfNeeded()
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
    private func updateTabBar(for navigationController: UINavigationController,
                              to viewController: UIViewController,
                              animated: Bool) {
        
        let hidden = viewController.pt_prefersTabBarHidden
        setTabBar(hidden: hidden, animated: animated)
        
        // 🌟 新增：更新 TabBar 状态的同时，监听新页面的 ScrollView 滑动状态
        observeScrollView(in: viewController)
    }
    
    public func setTabBar(hidden: Bool, animated: Bool) {
        tabBar.isHidden = true
        let height = ptCustomBar.currentBarLayoutStyle == .normal
        ? CGFloat.kTabbarHeight_Total
        : (CGFloat.kTabbarHeight_Total + ptCustomBar.centerButtonSize / 2)

        let transform = hidden
            ? CGAffineTransform(translationX: 0, y: height)
            : .identity

        let updateHiddenState = {
            self.tabBar.isHidden = true   // ❗始终 false（靠 transform 控制）
            self.ptCustomBar.isHidden = false
        }

        if animated {
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseInOut]) {
                updateHiddenState()
                self.ptCustomBar.transform = transform
            }
        } else {
            updateHiddenState()
            self.ptCustomBar.transform = transform
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

            
            self.scrollObservation = scrollView.observe(\.contentOffset, options: [.initial,.new]) { [weak self] scrollView, change in
                guard let self = self, let offset = change.newValue else { return }
                
                let isScrolled = offset.y > -scrollView.adjustedContentInset.top
                self.didScrollStateChange?(isScrolled, offset.y)
            }
        }
    }
}
