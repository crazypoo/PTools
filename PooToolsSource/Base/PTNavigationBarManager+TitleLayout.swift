import UIKit
import SnapKit

extension PTNavigationBarManager {

    public func setLeftView(_ views: [UIView], spacing: CGFloat = 8) {
        guard let nav = currentNav else { return }
        setLeftView(views, spacing: spacing, in: nav)
    }

    // English: Keep the explicit navigation controller overload private to avoid cross-stack updates.
    // Español: Mantiene privada la sobrecarga con navegación explícita para evitar actualizar otra pila.
    // 中文：显式传入导航控制器的重载保持私有，避免误更新其他导航栈。
    func setLeftView(_ views: [UIView], spacing: CGFloat, in nav: UINavigationController) {
        guard let container = containerMap.object(forKey: nav) else { return }
        // English: Reuse the same pre-reparenting measurement path as PTNavBar.
        // Español: Reutiliza la misma medición previa al cambio de supervista que PTNavBar.
        // 中文：复用 PTNavBar 使用的重新挂载前统一测量路径。
        let containerWidth = container.configureNavigationBarItems(views,
                                                                    in: container.leftContainer,
                                                                    spacing: spacing)
        container.leftContainerWidth = containerWidth
        
        container.leftContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(containerWidth)
        }
        refreshTitleLayout(in: nav, container: container)
    }
    
    public func setRightViews(_ views: [UIView], spacing: CGFloat = 8) {
        guard let nav = currentNav else { return }
        setRightViews(views, spacing: spacing, in: nav)
    }

    func setRightViews(_ views: [UIView], spacing: CGFloat, in nav: UINavigationController) {
        guard let container = containerMap.object(forKey: nav) else { return }
        // English: Keep right-side items on the same deterministic sizing path.
        // Español: Mantiene los elementos derechos en la misma ruta de tamaño determinista.
        // 中文：右侧按钮也使用同一套确定性尺寸布局。
        let containerWidth = container.configureNavigationBarItems(views,
                                                                    in: container.rightContainer,
                                                                    spacing: spacing)
        container.rightContainerWidth = containerWidth
        
        container.rightContainer.snp.remakeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(containerWidth)
        }
        refreshTitleLayout(in: nav, container: container)
    }
    
    public func setTitleView(_ view: UIView?, fillSpace: Bool = false) {
        guard let nav = currentNav else { return }
        setTitleView(view, fillSpace: fillSpace, in: nav)
    }

    func setTitleView(_ view: UIView?, fillSpace: Bool, in nav: UINavigationController) {
        guard let container = containerMap.object(forKey: nav) else { return }
        guard let view else {
            container.clearTitleLayout()
            return
        }

        // English: Reuse the existing title view and let one resolver-owned path update its geometry.
        // Español: Reutiliza la vista existente y deja que una única ruta propietaria del resolver actualice su geometría.
        // 中文：复用现有标题视图，并由 Resolver 唯一负责的路径更新几何约束。
        let existingView = container.titleContainer.subviews.first
        if existingView !== view {
            existingView?.snp.removeConstraints()
            existingView?.removeFromSuperview()
            view.snp.removeConstraints()
            view.removeFromSuperview()
            container.titleContainer.addSubview(view)
        }
        container.titleContainer.clipsToBounds = true
        container.titleContainer.isUserInteractionEnabled = true
        container.titleContainer.isHidden = false

        let mode: PTNavigationTitleLayoutMode = fillSpace ? .fillAvailable : .centerMeasured
        container.titleLayoutMode = mode
        applyTitleLayout(view: view, mode: mode, in: nav, container: container)
    }

    // English: Apply the shared title result and own all title-container constraints in this adapter.
    // Español: Aplica el resultado compartido y posee todas las restricciones del contenedor en este adaptador.
    // 中文：使用统一结果，并由当前适配器独占标题容器约束。
    func applyTitleLayout(view: UIView,
                                  mode: PTNavigationTitleLayoutMode,
                                  in navigationController: UINavigationController,
                                  container: PTNavigationBarContainer) {
        let visibleRect = container.navigationTitleVisibleRect()
        let layout = container.navigationTitleLayout(for: view,
                                                      mode: mode,
                                                      visibleRect: visibleRect,
                                                      availableHeight: visibleRect.height)
        let needsUpdate = container.titleLayoutSignature != layout.input ||
            container.titleLayoutView !== view
        container.titleLayoutMode = mode
        container.titleLayoutView = view

        guard needsUpdate else {
            container.titleContainer.isHidden = !layout.result.shouldDisplay
            return
        }

        container.titleLayoutSignature = layout.input
        if !layout.result.shouldDisplay {
            container.titleContainer.isHidden = true
            container.titleContainer.isUserInteractionEnabled = false
            container.titleContainer.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(0)
            }
            view.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            return
        }

        container.titleContainer.isHidden = false
        container.titleContainer.isUserInteractionEnabled = true
        let frame = layout.result.titleFrame
        container.titleContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(frame.minX)
            make.top.equalToSuperview().offset(frame.minY)
            make.width.equalTo(frame.width)
            make.height.equalTo(frame.height)
        }
        view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        _ = navigationController
    }

    // English: Recompute a title after button, safe-area, rotation, or split-pane geometry changes.
    // Español: Recalcula el título después de cambios de botones, área segura, rotación o panel dividido.
    // 中文：按钮、安全区、旋转或分屏几何变化后重新计算标题。
    func refreshTitleLayout(in navigationController: UINavigationController,
                                    container: PTNavigationBarContainer) {
        guard let view = container.titleLayoutView,
              let mode = container.titleLayoutMode else { return }
        applyTitleLayout(view: view,
                         mode: mode,
                         in: navigationController,
                         container: container)
    }
}
