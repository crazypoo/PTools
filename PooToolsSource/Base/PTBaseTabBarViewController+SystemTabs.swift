//
//  PTBaseTabBarViewController+SystemTabs.swift
//  PooTools
//
//  English: iOS 18 system Tab and TabGroup compatibility adapters.
//  Español: Adaptadores compatibles para Tab y TabGroup del sistema en iOS 18.
//  中文：iOS 18 系统 Tab 与 TabGroup 的兼容适配入口。
//

import UIKit

@available(iOS 18.0, *)
extension PTBaseTabBarViewController {
    // English: Build a system Tab while preserving the existing navigation wrapper.
    // Español: Construye un Tab del sistema conservando el envoltorio de navegación existente.
    // 中文：在保留现有导航包装器的同时创建系统 Tab。
    public func configTab(_ viewController: UIViewController,
                          title: String,
                          image: UIImage,
                          identifier: String,
                          badgeValue: String? = nil) -> UITab {
        let tab = UITab(title: title, image: image, identifier: identifier) { tab in
            tab.badgeValue = badgeValue
            tab.userInfo = identifier
            return self.configViewController(viewController: viewController, title: title)
        }
        tab.preferredPlacement = .sidebarOnly
        return tab
    }

    // English: Build a system TabGroup from the existing view-controller wrapper.
    // Español: Construye un TabGroup del sistema a partir del envoltorio de controlador existente.
    // 中文：基于现有控制器包装器创建系统 TabGroup。
    public func configTabGroup(_ viewController: UIViewController,
                               title: String,
                               image: UIImage,
                               identifier: String,
                               tabs: [UITab],
                               badgeValue: String? = nil) -> UITabGroup {
        let tabGroup = UITabGroup(title: title, image: image, identifier: identifier) { _ in
            return self.configViewController(viewController: viewController, title: title)
        }
        tabGroup.badgeValue = badgeValue
        tabGroup.children.append(contentsOf: tabs)
        return tabGroup
    }
}

// English: Keep the delegate hooks source-compatible with the existing controller.
// Español: Mantiene la compatibilidad de código de los hooks de delegado existentes.
// 中文：保留现有控制器的代理钩子源码兼容性。
extension PTBaseTabBarViewController: UITabBarControllerDelegate {
    // English: Allow the selected system Tab to be changed.
    // Español: Permite cambiar el Tab del sistema seleccionado.
    // 中文：允许切换选中的系统 Tab。
    @available(iOS 18.0, *)
    open func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
        return true
    }

    // English: Observe selection changes without changing the public behavior.
    // Español: Observa los cambios de selección sin cambiar el comportamiento público.
    // 中文：监听选择变化且不改变现有公开行为。
    @available(iOS 18.0, *)
    open func tabBarController(_ tabBarController: UITabBarController, didSelectTab selectedTab: UITab, previousTab: UITab?) {
        PTNSLogConsole(previousTab?.title ?? "", selectedTab.title)
    }

    // English: Observe the beginning of system Tab editing.
    // Español: Observa el inicio de la edición de los Tabs del sistema.
    // 中文：监听系统 Tab 编辑开始。
    open func tabBarControllerWillBeginEditing(_ tabBarController: UITabBarController) {
        PTNSLogConsole(#function)
    }

    // English: Observe the end of system Tab editing.
    // Español: Observa el final de la edición de los Tabs del sistema.
    // 中文：监听系统 Tab 编辑结束。
    open func tabBarControllerDidEndEditing(_ tabBarController: UITabBarController) {
        PTNSLogConsole(#function)
    }

    // English: Observe system TabGroup display-order changes.
    // Español: Observa los cambios de orden de visualización del TabGroup del sistema.
    // 中文：监听系统 TabGroup 显示顺序变化。
    @available(iOS 18.0, *)
    open func tabBarController(_ tabBarController: UITabBarController, displayOrderDidChangeFor group: UITabGroup) {
        PTNSLogConsole(#function)
    }
}
