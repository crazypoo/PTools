//
//  PTBaseTabBarViewController+Support.swift
//  PooTools
//
//  English: Shared visibility and accessory support for the custom tab bar.
//  Español: Soporte compartido de visibilidad y accesorios para el TabBar personalizado.
//  中文：自定义 TabBar 的可见性与附属视图通用支持。
//

import UIKit

@MainActor private var kPTTabBarHiddenKey: Void?
@MainActor private var kPTTabBarAccessoryViewKey: Void?

@MainActor
public protocol PTTabBarVisibilityProtocol {
    var pt_prefersTabBarHidden: Bool { get set }
    // English: A controller may provide the scroll view used for tab bar behavior.
    // Español: El controlador puede proporcionar el ScrollView usado por el comportamiento del TabBar.
    // 中文：控制器可以提供用于 TabBar 行为监听的 ScrollView。
    var pt_observedScrollView: UIScrollView? { get }
    // English: A controller may provide its own accessory view.
    // Español: El controlador puede proporcionar su propia vista accesoria.
    // 中文：控制器可以提供自己的附属视图。
    var pt_tabBarAccessoryView: UIView? { get set }
}

extension UIViewController: @MainActor PTTabBarVisibilityProtocol {
    public var pt_prefersTabBarHidden: Bool {
        get {
            return (objc_getAssociatedObject(self, &kPTTabBarHiddenKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &kPTTabBarHiddenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // English: The default keeps legacy controllers source-compatible.
    // Español: El valor predeterminado mantiene la compatibilidad de los controladores existentes.
    // 中文：默认实现用于保持旧控制器的源码兼容性。
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

            // English: Refresh only the active custom TabBar after the hierarchy settles.
            // Español: Actualiza solo el TabBar personalizado activo después de estabilizar la jerarquía.
            // 中文：等待层级稳定后只刷新当前激活的自定义 TabBar。
            var nextVC: UIViewController? = self
            while let current = nextVC {
                if let tabBarVC = current.tabBarController as? PTBaseTabBarViewController {
                    // English: Yield once so associated-object and controller updates finish first.
                    // Español: Cede una vez para que terminen primero las actualizaciones del controlador y del objeto asociado.
                    // 中文：主动让出一次执行权，确保控制器和关联对象更新先完成。
                    Task { @MainActor [weak tabBarVC] in
                        await Task.yield()
                        tabBarVC?.refreshCurrentAccessoryViewIfNeeded()
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

        // English: Hidden, transparent, or collapsed containers must not intercept touches.
        // Español: Los contenedores ocultos, transparentes o colapsados no deben interceptar toques.
        // 中文：隐藏、透明或高度收起的容器不能拦截触摸事件。
        if isHidden || alpha < 0.01 || frame.height < 5 {
            return nil
        }

        // English: An empty container must not become a transparent touch shield.
        // Español: Un contenedor vacío no debe convertirse en una barrera táctil transparente.
        // 中文：空容器不能变成透明的触摸屏障。
        return view === self ? nil : view
    }
}
