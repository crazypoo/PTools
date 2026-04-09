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
}

open class PTBaseTabBarViewController: UITabBarController {

    public var ptCustomBar = PTTabBarView()
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncInitialTabBarState()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        PTNavigationBarManager.shared.tabBarHandler = { [weak self] nav, toVC, animated, coordinator in
            self?.handleTabBar(nav: nav, to: toVC, animated: animated, coordinator: coordinator)
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
        guard let nav = selectedViewController as? UINavigationController,
              let topVC = nav.topViewController else { return }
        
        updateTabBar(for: nav, to: topVC, animated: false)
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
            self.tabBar.isHidden = false   // ❗始终 false（靠 transform 控制）
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
