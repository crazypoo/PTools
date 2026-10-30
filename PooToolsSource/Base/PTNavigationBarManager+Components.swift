import UIKit
import SnapKit

extension PTNavigationBarManager {
    // English: Store transition state by navigation controller so one scene cannot cancel another scene's display link.
    // Español: Guarda el estado de transición por controlador de navegación para que una escena no cancele el display link de otra.
    // 中文：按导航控制器保存转场状态，避免一个场景停止另一个场景的 display link。
    func setTransitionState(for navigationController: UINavigationController,
                                    coordinator: UIViewControllerTransitionCoordinator,
                                    container: PTNavigationBarContainer) {
        transitionStates.setObject(NavigationTransitionState(coordinator: coordinator,
                                                              container: container),
                                               forKey: navigationController)
    }

    // English: Remove only the completed stack transition and stop the shared display link when no stack remains.
    // Español: Elimina solo la transición completada y detiene el display link compartido cuando no queda ninguna pila.
    // 中文：只移除已完成导航栈的转场，所有转场结束后才停止共享 display link。
    func stopTransition(for navigationController: UINavigationController) {
        transitionStates.removeObject(forKey: navigationController)
        let hasRemainingTransitions = transitionStates.keyEnumerator().nextObject() != nil
        if !hasRemainingTransitions {
            stopDisplayLink()
        }
    }

    func startDisplayLink() {
        guard displayLink == nil else { return }

        if PTUIAccessibility.reduceMotionEnabled {
            // English: Complete interactive navigation styling immediately when motion is reduced.
            // Español: Completa de inmediato el estilo de navegación interactivo cuando se reduce el movimiento.
            // 中文：开启减弱动态效果时，立即完成交互式导航栏样式更新。
            completeReducedMotionTransitions()
            return
        }

        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @MainActor @objc func handleDisplayLink() {
        if PTUIAccessibility.reduceMotionEnabled {
            completeReducedMotionTransitions()
            return
        }

        var navigationControllers = [UINavigationController]()
        let keyEnumerator = transitionStates.keyEnumerator()
        while let navigationController = keyEnumerator.nextObject() as? UINavigationController {
            navigationControllers.append(navigationController)
        }

        for navigationController in navigationControllers {
            guard let state = transitionStates.object(forKey: navigationController),
                  let coordinator = state.coordinator,
                  let container = state.container else {
                transitionStates.removeObject(forKey: navigationController)
                continue
            }
            container.updateTransition(progress: coordinator.percentComplete)
        }

        if transitionStates.keyEnumerator().nextObject() == nil {
            stopDisplayLink()
        }
    }

    private func completeReducedMotionTransitions() {
        let keyEnumerator = transitionStates.keyEnumerator()
        while let navigationController = keyEnumerator.nextObject() as? UINavigationController {
            guard let state = transitionStates.object(forKey: navigationController),
                  let container = state.container else {
                continue
            }
            container.updateTransition(progress: 1)
        }
        stopDisplayLink()
    }
}

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
    private func applyTitleLayout(view: UIView,
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
