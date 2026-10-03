// PTRouterNavigator.swift
// English: Owns the UI side effects of a resolved route and keeps PTRouter focused on parsing and compatibility.
// Español: Gestiona los efectos de UI de una ruta resuelta y mantiene PTRouter centrado en el análisis y la compatibilidad.
// 中文：负责已解析路由的 UI 副作用，让 PTRouter 专注于解析和兼容入口。

import UIKit

@MainActor
internal enum PTRouterNavigator {

    // English: Perform the resolved navigation on MainActor after the legacy wrapper has queued it.
    // Español: Ejecuta la navegación resuelta en MainActor después de que el envoltorio heredado la programe.
    // 中文：由旧兼容包装器排队后，在 MainActor 上执行已经解析好的跳转。
    static func navigate(jumpType: PTJumpType,
                         viewController: UIViewController,
                         queries: [String: Any]) {
        if let action = PTRouter.shareInstance.customJumpAction {
            action(jumpType, viewController)
            return
        }

        switch jumpType {
        case .modal:
            let presentationStyle = UIModalPresentationStyle(rawValue: queries["PTRouterPStyleKey"] as? Int ?? 0) ?? .fullScreen
            let transitionStyle = UIModalTransitionStyle(rawValue: queries["PTRouterTStyleKey"] as? Int ?? 0) ?? .coverVertical
            let needsNavigationController = queries["PTRouterWrapInNavKey"] as? Bool ?? false

            if needsNavigationController {
                let navigationClass = queries["PTRouterNavOverrideKey"] as? UINavigationController.Type
                    ?? PTRouter.shareInstance.customNavClass
                let navigationController = navigationClass.init(rootViewController: viewController)
                PTUtils.modal(navigationController,
                              presentationStyle: presentationStyle,
                              transitionStyle: transitionStyle)
            } else {
                PTUtils.modal(viewController,
                              presentationStyle: presentationStyle,
                              transitionStyle: transitionStyle)
            }
        case .push:
            PTUtils.push(viewController)
        case .popToTaget:
            PTUtils.popToVC(ofType: type(of: viewController))
        case .windowNavRoot:
            PTUtils.pusbWindowNavRoot(viewController)
        case .modalDismissBeforePush:
            PTUtils.modalDismissBeforePush(viewController)
        case .showTab:
            showTabBar(queries: queries)
        }
    }

    // English: Switch tabs only after the current navigation stack has returned to its root.
    // Español: Cambia de pestaña después de que la pila de navegación actual vuelva a su raíz.
    // 中文：先将当前导航栈返回根页面，再切换 Tab，避免层级状态竞争。
    private static func showTabBar(queries: [String: Any]) {
        let selectedIndex = PTRouter.processParameter(queries[PTRouterTabBarSelecIndex] ?? 0) ?? 0
        guard let tabBarController = AppWindows?.rootViewController as? UITabBarController,
              let navigationController = PTUtils.getTopViewController(nil)?.navigationController else {
            return
        }

        navigationController.popToRootViewController(animated: false)
        PTGCDManager.shared.delayOnMain(time: 0.05) {
            switch tabBarController {
            case let customTabBarController as PTBaseTabBarViewController:
                customTabBarController.ptCustomBar.select(selectedIndex)
            default:
                tabBarController.selectedIndex = selectedIndex
            }

            PTUtils.getTopViewController(nil)?.navigationController?.popToRootViewController(animated: false)
        }
    }
}
