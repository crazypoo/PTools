import UIKit
import SnapKit

extension PTNavigationBarManager {
    func updateScrollProgress(_ progress: CGFloat) {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return }
        container.updateLargeTitle(progress: progress)
    }
    
    public func currentNavLargeTitleBarHeight() -> CGFloat {
        guard let nav = currentNav,
              let container = containerMap.object(forKey: nav) else { return 0 }
        container.layoutIfNeeded()
        return container.largeTitleContainer.frame.height
    }
    
    public func currentNavBarHeight() -> CGFloat {
        guard let _ = currentNav else { return 0 }
        
        let status = CGFloat.statusBarHeight()
        let navBar: CGFloat = CGFloat.kNavBarHeight
        
        return status + navBar + currentNavLargeTitleBarHeight()
    }

    // English: Expose the measured custom content-row height without changing the legacy total-height API.
    // Español: Expone la altura medida de la fila personalizada sin cambiar la API heredada de altura total.
    // 中文：提供实测自定义内容行高度，同时不改变旧的总高度 API 语义。
    public func currentNavigationContentHeight(in navigationController: UINavigationController? = nil) -> CGFloat {
        let nav = navigationController ?? currentNav
        guard let nav,
              let container = containerMap.object(forKey: nav) else { return 0 }
        refreshNavigationContentRow(in: nav, container: container)
        nav.navigationBar.layoutIfNeeded()
        container.layoutIfNeeded()
        return container.topBarContainer.bounds.height
    }

    // English: Convert the live navigation-bar bottom into a target view's coordinates instead of using a global estimate.
    // Español: Convierte el borde inferior real de la barra al sistema de coordenadas de la vista destino, sin usar una estimación global.
    // 中文：将实时导航栏底部转换到目标 View 坐标系，避免使用全局估算值。
    public func currentNavigationTopInset(in view: UIView,
                                          navigationController: UINavigationController? = nil) -> CGFloat {

        if let nav = navigationController ?? currentNav,
           let measured = measuredNavigationTopInset(in: view, navigationController: nav) {
            return measured
        }

        return max(0, view.safeAreaInsets.top)
    }
}

