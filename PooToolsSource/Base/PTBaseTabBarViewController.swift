//
//  PTBaseTabBarViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/17/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

open class PTBaseTabBarViewController: UITabBarController {

    open override func viewDidLoad() {
        super.viewDidLoad()
        /*
        //如果想要类似iPad的展示形式需要在scene或者appdelegate上设置
        //tabBarController.mode = .tabSidebar
         */
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

    // MARK: 设置UIViewController
    public func configViewController(viewController: UIViewController, title: String) -> PTBaseNavControl {
        let navigationController = PTBaseNavControl(rootViewController: viewController)
        viewController.navigationItem.title = title
        return navigationController
    }
}

// MARK: - 新增代理方法
@available(iOS 18.0, *)
extension PTBaseTabBarViewController: UITabBarControllerDelegate {
    // MARK: Tab是否可以选中
    open func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
        return true
    }

    // MARK: 选中Tab
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
    open func tabBarController(_ tabBarController: UITabBarController, displayOrderDidChangeFor group: UITabGroup) {
        PTNSLogConsole(#function)
    }
}
