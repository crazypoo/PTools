import UIKit
import QuartzCore

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

    func stopDisplayLink() {
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

    func completeReducedMotionTransitions() {
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

