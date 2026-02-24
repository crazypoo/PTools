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

public protocol PTTabBarVisibilityProtocol {
    var pt_prefersTabBarHidden: Bool { get }
}


extension UIViewController: PTTabBarVisibilityProtocol {
    @objc public var pt_prefersTabBarHidden: Bool { false }
}

open class PTBaseTabBarViewController: UITabBarController {

    public var ptCustomBar = PTTabBarView()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
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
    
    // MARK: 设置UIViewController
    public func configViewController(viewController: UIViewController, title: String) -> PTBaseNavControl {
        let navigationController = PTBaseNavControl(rootViewController: viewController)
        return navigationController
    }
    
    private func setupTabBar() {
        tabBar.isHidden = true

        view.addSubview(ptCustomBar)
        ptCustomBar.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(CGFloat.kTabbarHeight_Total)
        }
    }
    
    open func configure(items: [PTTabBarItemConfig]) {
        let vcs = items.map { item -> UIViewController in
            if let nav = item.viewController as? UINavigationController {
                nav.delegate = self
            } else if let side = item.viewController as? PTSideMenuControl,let findNav = side.contentViewController as? UINavigationController {
                findNav.delegate = self
            }
            return item.viewController
        }
        viewControllers = vcs
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

extension PTBaseTabBarViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let isRoot = navigationController.viewControllers.count == 1
        setTabBar(hidden: !isRoot, animated: animated)
    }
    
    private func setTabBar(hidden: Bool, animated: Bool) {

        let height = ptCustomBar.currentBarLayoutStyle == .normal ? CGFloat.kTabbarHeight_Total : (CGFloat.kTabbarHeight_Total + ptCustomBar.centerButtonSize / 2)

        let animations = {
            self.ptCustomBar.transform = hidden
                ? CGAffineTransform(translationX: 0, y: height)
                : .identity
        }

        if animated {
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseInOut],
                           animations: animations)
        } else {
            animations()
        }
    }
}
