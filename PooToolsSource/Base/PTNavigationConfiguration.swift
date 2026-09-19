//
//  PTNavigationConfiguration.swift
//  PooTools
//
// English: Navigation configuration is a capability, not a base-class requirement.
// Español: La configuración de navegación es una capacidad, no un requisito de herencia.
// 中文：导航配置是一项能力，不应强制依赖基类继承。
//

import UIKit

// English: Any view controller can opt into the custom navigation renderer.
// Español: Cualquier controlador puede optar por el renderizador de navegación personalizado.
// 中文：任意控制器都可以选择接入自定义导航栏渲染器。
@MainActor
public protocol PTNavigationConfigurable: AnyObject {
    func preferredNavigationBarStyle() -> PTNavigationBarStyle
    func prefersLargeTitle() -> Bool
    func allowControlNavBar() -> Bool
}

// English: Defaults preserve the behavior of controllers that only need the capability marker.
// Español: Los valores predeterminados conservan el comportamiento de los controladores que solo necesitan marcar la capacidad.
// 中文：默认实现保持只需要能力标记的控制器原有行为。
@MainActor
public extension PTNavigationConfigurable {
    func preferredNavigationBarStyle() -> PTNavigationBarStyle { .solid(.white) }
    func prefersLargeTitle() -> Bool { false }
    func allowControlNavBar() -> Bool { true }
}

@MainActor
public extension PTNavigationBarManager {
    // English: Apply a configuration without requiring PTBaseViewController inheritance.
    // Español: Aplica una configuración sin exigir heredar de PTBaseViewController.
    // 中文：无需继承 PTBaseViewController 即可应用导航配置。
    func apply(configuration: any PTNavigationConfigurable,
               in navigationController: UINavigationController) {
        apply(style: configuration.preferredNavigationBarStyle(), in: navigationController)
    }
}
